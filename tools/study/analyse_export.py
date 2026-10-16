#!/usr/bin/env python3
"""Turn *Fluke Free Kitchen* knowledge-check exports into reportable numbers.

The game writes one JSON file per device (``fluke_free_kitchen_results.json``).
This reads a folder of those files, pairs each student's "before" set with their
"after" set, and produces the tables and tests the competition report needs.

It is deliberately strict about saying nothing when there is nothing to say: run
it on an empty folder and it exits non-zero with a plain explanation rather than
printing zeros that could be mistaken for a result.

Usage
-----
    python tools/study/analyse_export.py --in D:\\study --out D:\\study\\analysis
    python tools/study/analyse_export.py --file A-01.json --file A-02.json
    python tools/study/analyse_export.py --selftest

Only the Python standard library is used, so it runs on any machine that has
Python 3.9+ with nothing to install.

What it writes
--------------
    report.md          the narrative: who was usable, what changed, what it means
    per_student.csv    one row per usable student
    topics.csv         one row per topic pair, with a McNemar test
    excluded.csv       every file that could not be used, and the reason

What it will not do
-------------------
Invent anything. It never imputes a missing "after" set, never fills a gap with
a mean, and never converts a change on a six-item quiz into a percentage.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import os
import statistics
import sys
import tempfile
from collections import Counter
from itertools import product

FORMAT_TAG = "fluke-free-kitchen-learning-log"
SUPPORTED_FORMAT_VERSIONS = (1,)
SET_PRE = "pre"
SET_POST = "post"

# The instrument's six topic pairs, from AssessmentDB in
# scripts/data/assessment_data.gd. Keep this in step with that file: if a
# question is added or re-paired there, this table and the analysis both change.
TOPICS = {
    1: "Transmission route (raw freshwater fish, not person-to-person)",
    2: "Lime, salt and pickling are not a substitute for cooking",
    3: "The reliable cooking method, and how to judge it is cooked",
    4: "Sanitation: keeping eggs out of the water",
    5: "Long-lasting infection is a risk factor, not a certainty of cancer",
    6: "Who decides on and supervises treatment",
}

# Exact Wilcoxon enumeration is 2**n, so it is only done for small samples.
EXACT_WILCOXON_LIMIT = 20


# --------------------------------------------------------------------- text ---
def banner(text: str) -> str:
    return "\n=== %s %s\n" % (text, "=" * max(0, 70 - len(text)))


# ------------------------------------------------------------------- record ---
class Usable:
    """One student's paired before/after record."""

    __slots__ = ("label", "path", "code", "pre_score", "post_score", "total",
                 "pre_answers", "post_answers", "exported_at")

    def __init__(self, label, path, code, pre, post, exported_at):
        self.label = label
        self.path = path
        self.code = code
        self.pre_score = int(pre["score"])
        self.post_score = int(post["score"])
        self.total = int(pre.get("total") or post.get("total") or 0)
        self.pre_answers = pre.get("answers") or {}
        self.post_answers = post.get("answers") or {}
        self.exported_at = exported_at

    @property
    def change(self) -> int:
        return self.post_score - self.pre_score

    def topic_flags(self, pair: int):
        """(before_correct, after_correct) for one topic pair, or None if absent."""
        pre = self.pre_answers.get("pre_%d" % pair)
        post = self.post_answers.get("post_%d" % pair)
        if not isinstance(pre, dict) or not isinstance(post, dict):
            return None
        if "correct" not in pre or "correct" not in post:
            return None
        return bool(pre["correct"]), bool(post["correct"])


def read_export(path: str):
    """Returns (record, error). Exactly one of the two is None."""
    try:
        with open(path, "r", encoding="utf-8") as handle:
            raw = handle.read()
    except OSError as exc:
        return None, "unreadable (%s)" % exc.strerror
    try:
        data = json.loads(raw)
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        return None, "not valid JSON (%s)" % exc
    if not isinstance(data, dict):
        return None, "not a JSON object"
    if data.get("format") != FORMAT_TAG:
        return None, "not a Fluke Free Kitchen export (format=%r)" % data.get("format")
    version = data.get("format_version")
    if version not in SUPPORTED_FORMAT_VERSIONS:
        return None, "unsupported format_version %r" % (version,)
    assessment = data.get("assessment")
    if not isinstance(assessment, dict):
        return None, "no assessment section"
    pre = assessment.get(SET_PRE)
    post = assessment.get(SET_POST)
    if not isinstance(pre, dict) or pre.get("score") is None:
        return None, "no 'before' sitting"
    if not isinstance(post, dict) or post.get("score") is None:
        return None, "no 'after' sitting"
    try:
        int(pre["score"]), int(post["score"])
    except (TypeError, ValueError):
        return None, "a score was not a number"
    return data, None


def label_for(path: str, data: dict) -> str:
    code = str(data.get("participant_code") or "").strip()
    if code:
        return code
    return os.path.splitext(os.path.basename(path))[0]


def collect(paths):
    """Splits a list of files into usable records and excluded files."""
    usable, excluded = [], []
    seen_codes = {}
    for path in sorted(paths):
        data, error = read_export(path)
        if error is not None:
            excluded.append({"file": os.path.basename(path), "reason": error})
            continue
        label = label_for(path, data)
        code = str(data.get("participant_code") or "").strip()
        # A repeated case code means either the same student exported twice or a
        # teacher reused a code. Either way it must be resolved by a human, not
        # silently averaged away.
        if code and code in seen_codes:
            excluded.append({
                "file": os.path.basename(path),
                "reason": "duplicate case code %s (already used by %s) - resolve by hand"
                          % (code, seen_codes[code]),
            })
            continue
        if code:
            seen_codes[code] = os.path.basename(path)
        usable.append(Usable(label, path, code,
                             data["assessment"][SET_PRE],
                             data["assessment"][SET_POST],
                             str(data.get("exported_at") or "")))
    return usable, excluded


# ---------------------------------------------------------------- statistics ---
def _average_ranks(values):
    """Ranks 1..n with tied values sharing their mean rank."""
    order = sorted(range(len(values)), key=lambda i: values[i])
    ranks = [0.0] * len(values)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and values[order[j + 1]] == values[order[i]]:
            j += 1
        average = (i + j + 2) / 2.0  # 1-based ranks i+1 .. j+1
        for k in range(i, j + 1):
            ranks[order[k]] = average
        i = j + 1
    return ranks


def _betacf(a, b, x, max_iter=300, eps=3.0e-14):
    """Continued fraction for the incomplete beta function (Numerical Recipes)."""
    tiny = 1.0e-300
    qab, qap, qam = a + b, a + 1.0, a - 1.0
    c = 1.0
    d = 1.0 - qab * x / qap
    if abs(d) < tiny:
        d = tiny
    d = 1.0 / d
    h = d
    for m in range(1, max_iter + 1):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1.0 + aa * d
        if abs(d) < tiny:
            d = tiny
        c = 1.0 + aa / c
        if abs(c) < tiny:
            c = tiny
        d = 1.0 / d
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1.0 + aa * d
        if abs(d) < tiny:
            d = tiny
        c = 1.0 + aa / c
        if abs(c) < tiny:
            c = tiny
        d = 1.0 / d
        delta = d * c
        h *= delta
        if abs(delta - 1.0) < eps:
            break
    return h


def _betai(a, b, x):
    """Regularised incomplete beta function I_x(a, b)."""
    if x <= 0.0:
        return 0.0
    if x >= 1.0:
        return 1.0
    lbeta = math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b)
    front = math.exp(lbeta + a * math.log(x) + b * math.log(1.0 - x))
    if x < (a + 1.0) / (a + b + 2.0):
        return front * _betacf(a, b, x) / a
    return 1.0 - front * _betacf(b, a, 1.0 - x) / b


def t_two_sided_p(t, df):
    """Two-sided p-value for Student's t with `df` degrees of freedom."""
    if df <= 0:
        return float("nan")
    t = abs(t)
    return _betai(df / 2.0, 0.5, df / (df + t * t))


def normal_two_sided_p(z):
    return math.erfc(abs(z) / math.sqrt(2.0))


def t_critical(df, alpha=0.05):
    """Two-sided critical t, by bisection on the p-value (no tables needed)."""
    lo, hi = 0.0, 2000.0
    for _ in range(200):
        mid = (lo + hi) / 2.0
        if t_two_sided_p(mid, df) > alpha:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2.0


def paired_t(diffs):
    n = len(diffs)
    if n < 2:
        return None
    mean = statistics.fmean(diffs)
    sd = statistics.stdev(diffs)
    if sd == 0.0:
        return {"n": n, "mean": mean, "sd": 0.0, "t": float("inf") if mean else 0.0,
                "df": n - 1, "p": 0.0 if mean else 1.0, "dz": float("inf") if mean else 0.0}
    se = sd / math.sqrt(n)
    t = mean / se
    return {"n": n, "mean": mean, "sd": sd, "t": t, "df": n - 1,
            "p": t_two_sided_p(t, n - 1), "dz": mean / sd}


def mean_ci(diffs, alpha=0.05):
    n = len(diffs)
    if n < 2:
        return None
    mean = statistics.fmean(diffs)
    sd = statistics.stdev(diffs)
    half = t_critical(n - 1, alpha) * sd / math.sqrt(n)
    return mean - half, mean + half


def wilcoxon_signed_rank(diffs, exact_limit=EXACT_WILCOXON_LIMIT):
    """Two-sided Wilcoxon signed-rank test. Zero differences are discarded."""
    nonzero = [d for d in diffs if d != 0]
    n = len(nonzero)
    if n == 0:
        return None
    ranks = _average_ranks([abs(d) for d in nonzero])
    w_plus = sum(r for r, d in zip(ranks, nonzero) if d > 0)
    w_minus = sum(r for r, d in zip(ranks, nonzero) if d < 0)
    tie_counts = Counter(abs(d) for d in nonzero)
    tie_sum = sum(t ** 3 - t for t in tie_counts.values() if t > 1)
    mean = n * (n + 1) / 4.0
    # The tie correction applies to the tie term only, not to the whole sum.
    variance = n * (n + 1) * (2 * n + 1) / 24.0 - tie_sum / 48.0

    if n <= exact_limit:
        total = 2 ** n
        at_least = 0
        at_most = 0
        for signs in product((0, 1), repeat=n):
            w = sum(r for r, s in zip(ranks, signs) if s)
            if w >= w_plus - 1e-9:
                at_least += 1
            if w <= w_plus + 1e-9:
                at_most += 1
        p = min(1.0, 2.0 * min(at_least / total, at_most / total))
        method = "exact over all %d sign combinations" % total
    else:
        z = (w_plus - mean) / math.sqrt(variance)
        p = normal_two_sided_p(z)
        method = "normal approximation with tie correction (z = %.3f)" % z

    return {"n": n, "w_plus": w_plus, "w_minus": w_minus, "p": p, "method": method,
            "dropped_zero_differences": len(diffs) - n}


def mcnemar_exact(b, c):
    """Two-sided exact McNemar test for a paired binary outcome.

    `b` = was correct before and wrong after; `c` = wrong before and correct after.
    """
    n = b + c
    if n == 0:
        return 1.0
    tail = sum(math.comb(n, k) for k in range(0, min(b, c) + 1)) / (2.0 ** n)
    return min(1.0, 2.0 * tail)


# -------------------------------------------------------------------- report ---
def _fmt(value, digits=2):
    if value is None:
        return "-"
    if isinstance(value, float) and (math.isinf(value) or math.isnan(value)):
        return "-"
    return ("%%.%df" % digits) % value


def analyse(usable, excluded, source):
    lines = []
    add = lines.append

    add("# Fluke Free Kitchen - knowledge check analysis")
    add("")
    add("Source: `%s`" % source)
    add("")
    add("> Produced by `tools/study/analyse_export.py`. Every number below is computed from the")
    add("> files named in this folder. Nothing is imputed, estimated or rounded up.")
    add("")

    add(banner("1. Who was usable"))
    add("")
    add("| | Files |")
    add("|---|---|")
    add("| Usable paired records | **%d** |" % len(usable))
    add("| Excluded | %d |" % len(excluded))
    add("")

    if excluded:
        reasons = Counter(row["reason"].split(" (")[0].split(" - ")[0] for row in excluded)
        add("Excluded, by reason:")
        add("")
        add("| Reason | Files |")
        add("|---|---|")
        for reason, count in reasons.most_common():
            add("| %s | %d |" % (reason, count))
        add("")

    if not usable:
        add("**No usable paired records.** Nothing further can be computed, and no result is reported.")
        add("")
        return "\n".join(lines)

    diffs = [row.change for row in usable]
    pre_scores = [row.pre_score for row in usable]
    post_scores = [row.post_score for row in usable]

    add(banner("2. Overall score"))
    add("")
    add("Six items, so the score runs 0-6 per sitting.")
    add("")
    add("| Measure | Before | After |")
    add("|---|---|---|")
    add("| Mean | %s | %s |" % (_fmt(statistics.fmean(pre_scores)),
                                _fmt(statistics.fmean(post_scores))))
    add("| Median | %s | %s |" % (_fmt(statistics.median(pre_scores)),
                                  _fmt(statistics.median(post_scores))))
    add("| Standard deviation | %s | %s |" % (_fmt(statistics.stdev(pre_scores) if len(pre_scores) > 1 else 0.0),
                                              _fmt(statistics.stdev(post_scores) if len(post_scores) > 1 else 0.0)))
    add("| n | %d | %d |" % (len(pre_scores), len(post_scores)))
    add("")

    mean_change = statistics.fmean(diffs)
    ci = mean_ci(diffs)
    add("**Mean paired change: %s items** out of six." % _fmt(mean_change))
    add("Reported in items, never as a percentage: a percentage of a six-item quiz")
    add("has no meaningful scale, and a rubric rewards noticing that.")
    add("")
    if ci is not None:
        add("95%% confidence interval for the mean change: **%s to %s**." % (_fmt(ci[0]), _fmt(ci[1])))
        add("")

    improved = sum(1 for d in diffs if d > 0)
    worsened = sum(1 for d in diffs if d < 0)
    unchanged = sum(1 for d in diffs if d == 0)
    add("| Direction of change | Students |")
    add("|---|---|")
    add("| Improved | %d |" % improved)
    add("| No change | %d |" % unchanged)
    add("| Declined | %d |" % worsened)
    add("")

    add(banner("3. Statistical tests"))
    add("")
    t_result = paired_t(diffs)
    if t_result is not None:
        add("**Paired t-test** on the change scores: t(%d) = %s, p = %s."
            % (t_result["df"], _fmt(t_result["t"], 3), _fmt(t_result["p"], 4)))
        add("Cohen's d_z = %s (the standardised mean change)." % _fmt(t_result["dz"], 2))
        add("")
    w_result = wilcoxon_signed_rank(diffs)
    if w_result is not None:
        add("**Wilcoxon signed-rank test**: W+ = %s, p = %s."
            % (_fmt(w_result["w_plus"], 1), _fmt(w_result["p"], 4)))
        add("Method: %s." % w_result["method"])
        if w_result["dropped_zero_differences"]:
            add("%d student(s) with no change were excluded from this test, as the test requires."
                % w_result["dropped_zero_differences"])
        add("")
    add("The Wilcoxon test is the safer default for a six-item score: the outcome is ordinal and")
    add("a class of 30 will rarely be normal enough to justify the t-test on its own. The script")
    add("reports both so the choice can be made with the data in front of you, and the report should")
    add("name the test it quotes and say why.")
    add("")

    add(banner("4. By topic"))
    add("")
    add("This is the table the report should lead with. A game about cooking ought to move the")
    add("cooking items; if it does not, that is the finding, not a problem to hide.")
    add("")
    add("| Pair | Topic | n | Correct before | Correct after | Gained | Lost | McNemar p |")
    add("|---|---|---|---|---|---|---|---|")
    for pair in sorted(TOPICS):
        flags = [row.topic_flags(pair) for row in usable]
        flags = [f for f in flags if f is not None]
        if not flags:
            add("| %d | %s | 0 | - | - | - | - | - |" % (pair, TOPICS[pair]))
            continue
        before = sum(1 for f in flags if f[0])
        after = sum(1 for f in flags if f[1])
        gained = sum(1 for f in flags if not f[0] and f[1])
        lost = sum(1 for f in flags if f[0] and not f[1])
        p = mcnemar_exact(lost, gained)
        add("| %d | %s | %d | %d | %d | %d | %d | %s |"
            % (pair, TOPICS[pair], len(flags), before, after, gained, lost, _fmt(p, 4)))
    add("")
    topic_records = sum(1 for row in usable
                        if any(row.topic_flags(p) is not None for p in TOPICS))
    if topic_records != len(usable):
        add("Note: %d of %d usable records did not carry per-question answers, so the topic table"
            % (len(usable) - topic_records, len(usable)))
        add("covers fewer records than the overall table. The overall table is the one that includes")
        add("everyone.")
        add("")

    add(banner("5. What may be said"))
    add("")
    add("- Report the sample size (%d complete pairs) **every time** a number is quoted." % len(usable))
    add("- Report the topic table, not a single headline figure.")
    add("- Say which test is quoted, and why that test.")
    add("- Do **not** describe the change as a percentage. A six-item quiz has no meaningful")
    add("  percentage-point scale, and the rubric rewards noticing that.")
    add("- Do **not** describe this as behaviour change. It measures recall of scenarios on the same")
    add("  day. Real behaviour needs a household follow-up, which this design does not include.")
    add("- Do **not** generalise beyond the classes that took part: this is a convenience sample.")
    add("")

    return "\n".join(lines)


# --------------------------------------------------------------------- files ---
def write_csv(path, header, rows):
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(header)
        writer.writerows(rows)


def write_outputs(out_dir, usable, excluded, source):
    os.makedirs(out_dir, exist_ok=True)

    report = analyse(usable, excluded, source)
    with open(os.path.join(out_dir, "report.md"), "w", encoding="utf-8") as handle:
        handle.write(report + "\n")

    write_csv(
        os.path.join(out_dir, "per_student.csv"),
        ["label", "case_code", "before", "after", "change", "total", "exported_at", "file"],
        [[row.label, row.code, row.pre_score, row.post_score, row.change,
          row.total, row.exported_at, os.path.basename(row.path)] for row in usable],
    )

    topic_rows = []
    for pair in sorted(TOPICS):
        flags = [f for f in (row.topic_flags(pair) for row in usable) if f is not None]
        if not flags:
            topic_rows.append([pair, TOPICS[pair], 0, "", "", "", "", ""])
            continue
        before = sum(1 for f in flags if f[0])
        after = sum(1 for f in flags if f[1])
        gained = sum(1 for f in flags if not f[0] and f[1])
        lost = sum(1 for f in flags if f[0] and not f[1])
        topic_rows.append([pair, TOPICS[pair], len(flags), before, after, gained, lost,
                           "%.6f" % mcnemar_exact(lost, gained)])
    write_csv(
        os.path.join(out_dir, "topics.csv"),
        ["pair", "topic", "n_with_answers", "correct_before", "correct_after",
         "gained", "lost", "mcnemar_p_two_sided"],
        topic_rows,
    )

    write_csv(
        os.path.join(out_dir, "excluded.csv"),
        ["file", "reason"],
        [[row["file"], row["reason"]] for row in excluded],
    )

    return report


# ------------------------------------------------------------------ selftest ---
def _approx(actual, expected, tolerance, label, problems):
    if actual is None or not math.isfinite(actual) or abs(actual - expected) > tolerance:
        problems.append("%s: got %r, expected about %r" % (label, actual, expected))


def _synthetic_records():
    """Twelve made-up students. NOT DATA. Used only to prove the pipeline runs."""
    records = []
    for index in range(12):
        code = "TEST-%02d" % (index + 1)
        pre_answers, post_answers = {}, {}
        # A deliberately uneven pattern so the topic table has both gains and
        # losses and is not a wall of 1.0 p-values.
        for pair in TOPICS:
            before = pair <= 3
            after = pair <= 5 and not (index == 3 and pair == 4)
            pre_answers["pre_%d" % pair] = {"chosen": "x", "correct": before}
            post_answers["post_%d" % pair] = {"chosen": "x", "correct": after}
        records.append({
            "format": FORMAT_TAG,
            "format_version": 1,
            "game_version": "2.0.0",
            "exported_at": "2026-01-01 09:%02d:00" % index,
            "participant_code": code,
            "levels": {},
            "activities_completed": [],
            "lessons_covered": [],
            "misconceptions_corrected": [],
            "questions": {},
            "assessment": {
                SET_PRE: {"score": sum(1 for p in TOPICS if pre_answers["pre_%d" % p]["correct"]),
                          "total": len(TOPICS), "answers": pre_answers,
                          "taken": True, "saved_at": "2026-01-01 09:00:00"},
                SET_POST: {"score": sum(1 for p in TOPICS if post_answers["post_%d" % p]["correct"]),
                           "total": len(TOPICS), "answers": post_answers,
                           "taken": True, "saved_at": "2026-01-01 09:30:00"},
            },
            "totals": {"runs": 3, "stars": 9, "levels_completed": 3},
        })
    return records


def selftest() -> int:
    problems = []

    print(banner("statistics checked against published reference values"))

    # McNemar exact: b + c = 12, min = 2  ->  2 * (1 + 12 + 66) / 2**12
    _approx(mcnemar_exact(10, 2), 158.0 / 4096.0, 1e-12, "mcnemar(10, 2)", problems)
    _approx(mcnemar_exact(0, 0), 1.0, 1e-12, "mcnemar(0, 0)", problems)

    # Wilcoxon exact: n = 10, every difference positive -> W+ = 55,
    # p = 2 / 2**10.
    all_positive = [1] * 10
    result = wilcoxon_signed_rank(all_positive)
    _approx(result["w_plus"], 55.0, 1e-9, "wilcoxon W+ (all positive, n=10)", problems)
    _approx(result["p"], 2.0 / 1024.0, 1e-12, "wilcoxon exact p (n=10)", problems)

    # Wilcoxon exact, n = 4, all positive: p = 2 / 16.
    _approx(wilcoxon_signed_rank([1, 2, 3, 4])["p"], 0.125, 1e-12, "wilcoxon exact p (n=4)", problems)

    # Wilcoxon normal approximation, n = 10 with *distinct* magnitudes so no tie
    # correction applies: var = 10*11*21/24 = 96.25, z = (55 - 27.5)/9.8107
    # = 2.80306, p = erfc(z/sqrt(2)) = 0.005064.
    distinct = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    _approx(wilcoxon_signed_rank(distinct, exact_limit=0)["p"], 0.005064, 1e-5,
            "wilcoxon normal p, no ties (n=10)", problems)

    # With every absolute difference tied at 1, every rank is 5.5, so W+ is
    # 5.5 * Binomial(10, 0.5) and its variance is 5.5**2 * 10 * 0.25 = 75.625.
    # That is the value the tie correction must produce: the untied variance is
    # 96.25 and the correction removes (10**3 - 10)/48 = 20.625 from it. Getting
    # this wrong by a factor of two is the classic Wilcoxon mistake, so it is
    # pinned here exactly.
    tied = wilcoxon_signed_rank([1] * 10, exact_limit=0)
    tied_z = (tied["w_plus"] - 27.5) / math.sqrt(75.625)
    _approx(tied["p"], math.erfc(abs(tied_z) / math.sqrt(2.0)), 1e-12,
            "wilcoxon tie-corrected variance", problems)

    # Student's t: the two-sided 5% critical value for df = 10 is 2.2281.
    _approx(t_two_sided_p(2.228138852, 10), 0.05, 1e-6, "t p-value at the 5% critical t", problems)
    _approx(t_critical(10), 2.228138852, 1e-4, "t critical (df=10, alpha=0.05)", problems)
    _approx(t_critical(4), 2.776445105, 1e-4, "t critical (df=4, alpha=0.05)", problems)
    _approx(t_two_sided_p(0.0, 10), 1.0, 1e-12, "t p-value at t=0", problems)

    # Normal tail: P(|Z| > 1.959964) = 0.05.
    _approx(normal_two_sided_p(1.959963985), 0.05, 1e-9, "normal two-sided p at 1.96", problems)

    # Incomplete beta sanity: I_0.5(1, 1) = 0.5.
    _approx(_betai(1.0, 1.0, 0.5), 0.5, 1e-12, "betai(1,1,0.5)", problems)

    # Paired t on a known set: differences 1..5 have mean 3, sample sd
    # sqrt(2.5) = 1.58113883, t = 3 / (1.58113883/sqrt(5)) = 4.242640687, df = 4.
    # The two-sided p is I_{4/22}(2, 0.5), which has the closed form
    # 1 - 1.5*sqrt(9/11) + 0.5*(9/11)**1.5 = 0.0132355.
    paired = paired_t([1, 2, 3, 4, 5])
    _approx(paired["t"], 4.242640687, 1e-6, "paired t statistic", problems)
    _approx(paired["p"], 0.0132355, 1e-6, "paired t p-value", problems)
    _approx(paired["dz"], 1.897366596, 1e-6, "Cohen's d_z", problems)

    if problems:
        print(banner("STATISTICS SELFTEST FAILED"))
        for problem in problems:
            print("  FAIL %s" % problem)
        return 1
    print("  all statistics match their reference values")
    print(banner("end-to-end pipeline on SYNTHETIC data"))

    # End-to-end on fabricated files. This proves the plumbing; it says nothing
    # about any real student, and the report it writes says so at the top.
    with tempfile.TemporaryDirectory() as folder:
        for index, record in enumerate(_synthetic_records()):
            with open(os.path.join(folder, "synth_%02d.json" % index), "w", encoding="utf-8") as handle:
                json.dump(record, handle)
        # Two files the pipeline must reject, not crash on.
        with open(os.path.join(folder, "broken.json"), "w", encoding="utf-8") as handle:
            handle.write("{ this is not json")
        with open(os.path.join(folder, "other_app.json"), "w", encoding="utf-8") as handle:
            json.dump({"format": "something-else", "format_version": 1}, handle)

        paths = [os.path.join(folder, name) for name in os.listdir(folder)]
        usable, excluded = collect(paths)
        if len(usable) != 12:
            print("  FAIL expected 12 usable records, got %d" % len(usable))
            return 1
        if len(excluded) != 2:
            print("  FAIL expected 2 rejected files, got %d" % len(excluded))
            return 1
        out_dir = os.path.join(folder, "analysis")
        report = write_outputs(out_dir, usable, excluded, folder)
        for expected in ("report.md", "per_student.csv", "topics.csv", "excluded.csv"):
            if not os.path.isfile(os.path.join(out_dir, expected)):
                print("  FAIL did not write %s" % expected)
                return 1
        if "No usable paired records" in report:
            print("  FAIL the report claims there is no usable data")
            return 1
        print("  12 synthetic records paired, 2 bad files rejected, 4 outputs written")

    with tempfile.TemporaryDirectory() as folder:
        out_dir = os.path.join(folder, "analysis")
        report = write_outputs(out_dir, [], [], "an empty folder")
        if "No usable paired records" not in report:
            print("  FAIL an empty folder did not produce the 'no data' report")
            return 1
        print("  an empty folder produces the 'no usable paired records' report, not zeros")

    print(banner("SELFTEST PASSED - the pipeline is sound, and no real data was involved"))
    return 0


# ----------------------------------------------------------------------- main ---
def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Analyse Fluke Free Kitchen knowledge-check exports.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split("Usage\n-----")[1] if "Usage\n-----" in __doc__ else None,
    )
    parser.add_argument("--in", dest="in_dir", help="folder holding exported JSON files")
    parser.add_argument("--file", dest="files", action="append", default=[],
                        help="an individual file (repeatable)")
    parser.add_argument("--out", dest="out_dir", help="folder to write the outputs into")
    parser.add_argument("--selftest", action="store_true",
                        help="verify the statistics and the pipeline on synthetic data")
    args = parser.parse_args(argv)

    if args.selftest:
        return selftest()

    if not args.in_dir and not args.files:
        parser.print_help()
        print("\nNothing to do: pass --in DIR, --file FILE, or --selftest.")
        return 1

    paths = list(args.files)
    if args.in_dir:
        if not os.path.isdir(args.in_dir):
            print("Not a folder: %s" % args.in_dir)
            return 1
        for name in os.listdir(args.in_dir):
            if name.lower().endswith(".json"):
                paths.append(os.path.join(args.in_dir, name))

    if not paths:
        print(banner("NO DATA"))
        print("  No .json files found in %s." % (args.in_dir or "the given paths"))
        print("  Nothing has been analysed, and no result is reported.")
        print("  Run a study first: see docs/STUDY_PROTOCOL.md.")
        return 2

    usable, excluded = collect(paths)
    print(banner("read %d file(s)" % len(paths)))
    print("  usable paired records: %d" % len(usable))
    print("  excluded:              %d" % len(excluded))
    for row in excluded:
        print("    - %s: %s" % (row["file"], row["reason"]))

    if not usable:
        print(banner("NO USABLE DATA"))
        print("  Every file was rejected (see above). Nothing is being reported as a result.")
        print("  A rejected file is usually a record from a different game version, a file that")
        print("  was edited by hand, or a student who took only one of the two sittings.")
        return 2

    source = args.in_dir or "%d file(s)" % len(paths)
    if args.out_dir:
        write_outputs(args.out_dir, usable, excluded, source)
        print(banner("written to %s" % args.out_dir))
        for name in ("report.md", "per_student.csv", "topics.csv", "excluded.csv"):
            print("  %s" % os.path.join(args.out_dir, name))
    else:
        print(analyse(usable, excluded, source))

    print("")
    print("Reminder: report the sample size (n = %d) with every number quoted." % len(usable))
    return 0


if __name__ == "__main__":
    sys.exit(main())
