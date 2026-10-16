# Competition report — working set (ชุดรายงานการแข่งขัน)

**Drafted:** 2026-10-16 · **Project:** *Fluke Free Kitchen* (ครัวปลอดพยาธิ) · **Version:** 2.0.0

This folder holds the written competition deliverables for the *Fluke Free Fighters* competition
(สถาบันวิจัยมะเร็งท่อน้ำดี มหาวิทยาลัยขอนแก่น, ประกาศที่ 4/2569). The chapters are written in Thai,
which is the competition's language, to the announcement's format:

* A4 paper, **TH SarabunPSK 16 pt**;
* main text (chapters 1–5) **≤ 20 pages**; references and appendices within the limits the
  announcement sets (confirm the exact numbers on the announcement before printing — this project
  reads them as **references ≤ 15 pages** and **appendix ≤ 5 pages**).

Read this file first: it says what each file is, how the chapters fit the page budget, and — most
importantly — **what is still missing and must not be faked**.

## Files

| File | What it is | Status |
|------|------------|--------|
| `README.md` | this guide | — |
| `00_abstract_and_proposal.md` | บทคัดย่อ (abstract), ข้อเสนอโครงการ (proposal) และบทสรุปผู้บริหาร (project summary) | drafted |
| `ch1_introduction.md` | บทที่ 1 บทนำ | drafted |
| `ch2_background.md` | บทที่ 2 เอกสารและงานวิจัยที่เกี่ยวข้อง | drafted |
| `ch3_method.md` | บทที่ 3 วิธีดำเนินการ | drafted |
| `ch4_results.md` | บทที่ 4 ผลการศึกษา | drafted — **software results are real; the learning-outcome study has not been run** |
| `ch5_discussion.md` | บทที่ 5 สรุปและอภิปรายผล | drafted |
| `references.md` | เอกสารอ้างอิง (numbered, matches `docs/REFERENCES.md`) | ready |
| `video_script.md` | script/storyboard for the ≤ 7-minute presentation video | drafted |
| `board_layout.md` | plan for the 150 cm display board | drafted |
| `logbook.md` | โครงการ/บันทึกการทำงาน (logbook) — a scored deliverable | drafted |

## Page budget (main text ≤ 20 pages)

| Chapter | Target pages |
|---------|-------------|
| 1 บทนำ | ~3 |
| 2 เอกสารและงานวิจัยที่เกี่ยวข้อง | ~4 |
| 3 วิธีดำเนินการ | ~5 |
| 4 ผลการศึกษา | ~4 |
| 5 สรุปและอภิปรายผล | ~4 |
| **รวม** | **~20** |

The Markdown here is the source of truth for wording. To produce the word-processor file: paste
each chapter into Word/WPS, set the style to TH SarabunPSK 16 pt, single line spacing, A4 margins,
and headings in TH SarabunPSK bold. Screenshots referenced in Chapter 4 are produced by
`tests/visual_capture.tscn` and the responsive checker (see `docs/RESPONSIVE.md` and
`docs/EXPORTS.md` for the exact commands and where the images land).

## The one rule for Chapter 4 and Chapter 5

The competition requires that **Chapter 4 report prevention-behaviour evidence** and **Chapter 5
discuss it**. This project has **not** run a study: there are no participants, no ethics approval
and no data. Therefore:

* Chapter 4 reports the **real** results (the game, its tests, its exports, its source
  verification) and states plainly, in its own section, that **no learning or behaviour data has
  been collected**.
* Chapter 5 discusses what the software evidence does and does not support, and gives the study
  design that will produce the missing data.
* Neither chapter quotes an improvement percentage, a participant count, or a learning outcome,
  because none exists.

When the study is eventually run (see `docs/STUDY_PROTOCOL.md`), insert the results into the marked
placeholders in `ch4_results.md` §4.5 and write the corresponding discussion in `ch5_discussion.md`
§5.3. **Do not** replace the placeholders with plausible-looking numbers.

## Before submission — checklist

1. Paste chapters into the word processor; force the font, margins and page limits.
2. Insert real screenshots (not mock-ups).
3. Fill in the team's names, school, advisor and the logbook dates from real work.
4. Add the study results **only if the study was actually run** with prior ethics approval.
5. Re-check the reference URLs (`docs/REFERENCES.md` §5) and the citation style.
6. Record the video and build the board to `video_script.md` and `board_layout.md`.
