# Study tools

## `analyse_export.py`

Turns the game's exported JSON files into the tables and tests the competition
report needs. Standard library only — no `pip install`, no `numpy`, no `scipy`.

```powershell
# 1. Check the tool itself is sound. Does not touch real data.
python tools/study/analyse_export.py --selftest

# 2. Analyse a folder of exports.
python tools/study/analyse_export.py --in D:\study --out D:\study\analysis

# 3. Or name files individually.
python tools/study/analyse_export.py --file A-01.json --file A-02.json
```

### What it writes

| File | Contents |
| --- | --- |
| `report.md` | the narrative: who was usable, the overall change, the tests, the per-topic table, and a short "what may be said" section |
| `per_student.csv` | one row per usable student: before, after, change, case code, export time |
| `topics.csv` | one row per topic pair with the exact McNemar test |
| `excluded.csv` | every file that could not be used, and the reason |

### Rejected files are reported, not dropped

A file is rejected — and listed with the reason — when it is unreadable, is not
JSON, is not a *Fluke Free Kitchen* export, has an unsupported
`format_version`, has only one of the two sittings, or carries a case code that
another file already used. A repeated code is a signal that one student exported
twice or a teacher reused a code; that is a decision for a person, so the tool
refuses to average it away.

### It will not invent a result

Point it at an empty folder and it exits with code 2 and the message *"Nothing
has been analysed, and no result is reported"*. It does not print a zero, and it
does not impute a missing "after" sitting.

### The statistics, and why they are implemented by hand

The tool has to run on a school laptop, so it cannot depend on `scipy`. Every
function is therefore written out and pinned in `--selftest` against reference
values:

| Function | Checked against |
| --- | --- |
| `mcnemar_exact` | b=10, c=2 → 158/4096 |
| `wilcoxon_signed_rank` (exact) | n=10 all-positive → p = 2/1024; n=4 → 0.125 |
| `wilcoxon_signed_rank` (normal) | n=10, no ties → p ≈ 0.00506 |
| tie correction | all ten tied → variance must be 75.625, not 48.125 |
| `_betai`, `t_two_sided_p` | 5 % critical values of t at df = 4 and df = 10 |
| `paired_t` | differences 1..5 → t = 4.2426, p = 0.0132355 |
| `normal_two_sided_p` | p = 0.05 at z = 1.95996 |

The tie-clearing case earns its own test on purpose: it is the classic Wilcoxon
mistake (dividing the whole sum by 48 instead of only the tie term), and this
implementation had that bug until the test was written.

`--selftest` also runs the whole pipeline on twelve **fabricated** records in a
temporary folder, deliberately broken so that the topic table contains both
gains and losses, and asserts that two malformed files are rejected without
crashing. Those records are made up by the script in `_synthetic_records()`.
They are not data, they are not a pilot, and they say nothing about any student.
The folder is a `TemporaryDirectory` and is deleted on exit.

### Reporting rules the tool enforces by what it prints

- the sample size travels with every number;
- the change is in **items out of six**, never as a percentage;
- the per-topic table is presented before any headline;
- the narrative says, on its own page, that this measures recall of scenarios on
  the same day and is **not** behaviour change.

None of those are stylistic. The rubric gives marks for reporting data honestly,
and a six-item quiz cannot support a percentage claim.
