# Health Content and Sources

This document is the review record for every health claim in *River Dash: Safe Feast
Run*. It exists so that a reviewer, teacher or health worker can check each statement
back to a primary public-health source without reading any GDScript.

**The single rule the project follows: no gameplay code is allowed to state a health
fact of its own.** Every health message is an entry in
`scripts/data/education_data.gd` (`class_name EduDB`) and is displayed verbatim, with
its citation, by the `Education` autoload
(`autoload/education_manager.gd`).

---

## 1. Review record

| Field | Value |
| --- | --- |
| Content review date (all URLs opened and verified) | **2026-10-15** |
| Review status of the database | **14 / 14 entries `reviewed`; 0 `needs_review`** |
| Language coverage | English (primary) + Thai for the 8 core topics, both checkpoint messages, cross-contamination, `not_all_fish` and `latrine_builder`; anything without Thai falls back to English |
| Permitted source hosts (enforced in code) | `who.int`, `cdc.gov`, `ncbi.nlm.nih.gov`, `pmc.ncbi.nlm.nih.gov`, `ddc.moph.go.th` |
| Enforcement | `education_manager.gd → validate_database()`, asserted by `tests/smoke_test.tscn` |

`validate_database()` fails the smoke test if any entry is missing a field, cites an
unknown source key, cites a non-`https` URL, cites a host outside the approved list, or
carries an invalid review status. **No invented citations are possible without failing
the test suite.**

---

## 2. Source registry

Eleven sources are registered in `EduDB.SOURCES`. All were opened and confirmed live on
2026-10-15.

| Key | Title | URL | Cited by |
| --- | --- | --- | --- |
| `who_trematodes` | WHO — Foodborne trematode infections (fact sheet) | https://www.who.int/news-room/fact-sheets/detail/foodborne-trematode-infections | `raw_fish` |
| `who_topic_trematodes` | WHO — Foodborne trematode infections (health topic) | https://www.who.int/health-topics/foodborne-trematode-infections | *(verified reference, not currently cited by an entry)* |
| `who_thailand_cca` | WHO — Thailand uses integrated ecosystems health approach to beat cancer-causing disease (news, 14 Dec 2017) | https://www.who.int/news/item/14-12-2017-thailand-uses-integrated-ecosystems-health-approach-to-beat-cancer-causing-disease | `long_term_health`, `community_action` |
| `who_five_keys` | WHO — Five keys to safer food manual | https://www.who.int/publications/i/item/9789241594639 | `pickling_salting`, `prevention_safe_prep`, `cross_contamination`, `cooking_thorough` |
| `who_sanitation` | WHO — Sanitation (fact sheet) | https://www.who.int/news-room/fact-sheets/detail/sanitation | `sanitation_cycle`, `latrine_builder` |
| `cdc_about_flukes` | CDC — About Liver Flukes | https://www.cdc.gov/liver-flukes/about/index.html | `transmission_lifecycle` |
| `cdc_opisthorchis` | CDC — About Opisthorchis | https://www.cdc.gov/liver-flukes/opisthorchis/index.html | `not_all_fish` |
| `cdc_dpdx` | CDC DPDx — Opisthorchiasis (laboratory identification) | https://www.cdc.gov/dpdx/opisthorchiasis/index.html | `early_assessment`, `clinic_screening` |
| `statpearls` | StatPearls (NCBI Bookshelf) — *Clonorchiasis and Opisthorchiasis* | https://www.ncbi.nlm.nih.gov/books/NBK532892/ | `treatment_praziquantel` |
| `pmc_review` | *Clonorchiasis and opisthorchiasis: epidemiology, transmission, clinical features, diagnosis and treatment* (peer-reviewed, PMC) | https://pmc.ncbi.nlm.nih.gov/articles/PMC10938900/ | *(verified reference, not currently cited by an entry)* |
| `ddc_thailand` | Thailand Department of Disease Control — โรคพยาธิใบไม้ตับ (liver fluke) | https://ddc.moph.go.th/ | *(verified reference, not currently cited by an entry)* |

The three uncited sources are kept deliberately: they are the references a future Thai
localisation pass should cite first, and `ddc_thailand` is the intended citation for
any Thai-language national-guidance wording that is added later.

---

## 3. The eight myth-buster topics

These are the misconceptions the game is designed to correct. Each one is a database
entry; the "myth" column is *not* shown to the player, the entry headline is.

| # | Entry id | The myth to correct | The correction shown in-game | Source |
| --- | --- | --- | --- | --- |
| 1 | `not_all_fish` | "All freshwater fish are infected / fish and fishing families are dirty." | Risk depends on species, catch location, parasite species and how the food is prepared. The game shows raw fish as a *hazard to cook*, not as a dirty thing. | `cdc_opisthorchis` |
| 2 | `pickling_salting` | "Sour, salted or fermented fish is safe because the acid/salt kills everything." | Traditional pickling, fermenting or salting may not reliably destroy liver fluke larvae; use methods that are validated by food-safety guidance. | `who_five_keys` |
| 3 | `transmission_lifecycle` | "You can catch it from another person, or from ordinary untreated drinking water." | Infection is typically acquired by eating infected raw or inadequately cooked fish; the life cycle involves freshwater snails. It is not spread by casual contact between people. | `cdc_about_flukes` |
| 4 | `cross_contamination` | "Only the fish itself matters." | A board, knife or hand used for raw fish can move parasites and germs onto vegetables or cooked food that will not be heated again. | `who_five_keys` |
| 5 | `cooking_thorough` | "A single temperature guarantees safety for every species and cooking method." | Heat the fish all the way through; the in-game gauge is an abstraction that teaches the idea, *not* a laboratory-validated guarantee. | `who_five_keys` |
| 6 | `sanitation_cycle` | "Dirty water/pipe water is automatically full of liver flukes." | Contamination reaching freshwater sustains the life cycle; good toilets and wastewater management interrupt the route at the source. A dirty pipe does not mean flukes. | `who_sanitation` |
| 7 | `latrine_builder` | "One toilet instantly removes every egg from the village." | A hygienic latrine moves the situation in the right direction; fewer eggs reaching freshwater means less infection over time, together with cooking and screening. | `who_sanitation` |
| 8 | `treatment_praziquantel` | "You can (or should) just take a deworming tablet yourself." | Praziquantel is used to treat opisthorchiasis, but diagnosis and treatment should be guided by qualified healthcare professionals. | `statpearls` |

Two further entries support the myth-busters around diagnosis:

| Entry id | Purpose | Source |
| --- | --- | --- |
| `early_assessment` | A health professional assesses exposure, symptoms and appropriate testing. Stool examination may be used, but results need proper interpretation (light infections can be missed; some fluke eggs look similar). | `cdc_dpdx` |
| `clinic_screening` | Screening is a conversation, not a verdict. A stool test is one piece of information interpreted with your history, not a personal label. | `cdc_dpdx` |

---

## 4. Complete entry inventory

`EduDB.entries()` — 14 entries. "Triggers" are the gameplay events that can surface the
entry.

| Entry id | Topic | Trigger(s) | Source | Status |
| --- | --- | --- | --- | --- |
| `raw_fish` | raw fish | `obstacle_raw_fish`, manual | `who_trematodes` | reviewed |
| `pickling_salting` | preservation | `obstacle_raw_fish`, manual | `who_five_keys` | reviewed |
| `prevention_safe_prep` | prevention | `obstacle_raw_fish`, `powerup_cooking`, manual | `who_five_keys` | reviewed |
| `transmission_lifecycle` | transmission | `obstacle_wastewater`, manual | `cdc_about_flukes` | reviewed |
| `early_assessment` | assessment | `clinic_checkpoint`, manual | `cdc_dpdx` | reviewed |
| `treatment_praziquantel` | treatment | `powerup_treatment`, `clinic_checkpoint`, manual | `statpearls` | reviewed |
| `long_term_health` | long-term health | `kitchen_checkpoint`, manual | `who_thailand_cca` | reviewed |
| `sanitation_cycle` | sanitation | `obstacle_wastewater`, `powerup_shield`, `latrine_event`, manual | `who_sanitation` | reviewed |
| `cross_contamination` | kitchen hygiene | `obstacle_cutting_board`, manual | `who_five_keys` | reviewed |
| `cooking_thorough` | cooking | `kitchen_checkpoint`, manual | `who_five_keys` | reviewed |
| `clinic_screening` | screening | `clinic_checkpoint`, manual | `cdc_dpdx` | reviewed |
| `latrine_builder` | sanitation | `latrine_event`, manual | `who_sanitation` | reviewed |
| `not_all_fish` | raw fish | `obstacle_raw_fish`, manual | `cdc_opisthorchis` | reviewed |
| `community_action` | prevention | `run_end`, manual | `who_thailand_cca` | reviewed |

All 14 can be listed in-game from the main menu via **Health Facts**, which renders each
entry with its headline, body, extended note, source title, source URL, last-reviewed
date and review status.

---

## 5. Accuracy rules the content follows

1. **Not all fish are infected.** Stated explicitly in `raw_fish` and `not_all_fish`;
   the game never implies that fish, markets or fishing families are unclean.
2. **No universal single-temperature guarantee.** `cooking_thorough` says outright that
   the mini-game gauge is a game abstraction, not a validated guarantee for every
   species, cut or cooking method.
3. **A dirty pipe is not automatically full of flukes.** `sanitation_cycle` states that
   a dirty pipe is not the mechanism; faecal contamination reaching freshwater is.
4. **One toilet does not instantly remove every egg.** `latrine_builder` says so
   directly.
5. **Treatment is medically supervised only.** `treatment_praziquantel` never suggests
   self-medication.
6. **No risk to individuals from other people.** `transmission_lifecycle` states you
   cannot get it from another person and cannot get it from untreated drinking water.
7. **No fear framing.** The failure state is a 3-point *safety buffer* running out, not
   illness or death. Losing ends a run; the message on the game-over screen is a
   prevention takeaway (`community_action`).

### The clinic checkpoint specifically

The Village Health Centre checkpoint is framed as a **screening conversation**:

* a nurse asks about how you have been feeling and how you prepare fish,
* the nurse *may suggest* a simple **stool test** done at the clinic,
* the panel states plainly that **only a health professional can diagnose an
  infection** and that this "is a chat to help you decide to get checked — it is not a
  diagnosis."

It **never** mentions or depicts an X-ray, and it **never** renders a fictional personal
diagnosis or a fake test result. The wording was written to sit on top of the vetted
`clinic_checkpoint` entries (`early_assessment`, `cooking_thorough`, `clinic_screening`,
`treatment_praziquantel`, `long_term_health`), which are shown alongside the nurse's
lines.

---

## 6. How to change or add content

1. Add or edit the entry in `scripts/data/education_data.gd`.
2. If a new source is needed, add it to `EduDB.SOURCES` with a `title` and a full
   `https://` URL on an approved host.
3. Set `"status"` to `EduDB.REVIEWED` only after a human has read the source.
4. Run the smoke test — it will reject unknown sources, non-https URLs, unapproved
   hosts and malformed Thai blocks:

   ```powershell
   & "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe" --headless `
       --path "C:\Users\ASUS\river-dash-safe-feast-run" res://tests/smoke_test.tscn
   ```

5. Update `EduDB.REVIEW_DATE` if the URLs were re-verified, and update the tables in
   this document.

> **Note on `REVIEW_DATE`.** It records the date the project last *opened and checked*
> each URL, not a claim that the underlying guidance is immutable. WHO and CDC pages do
> change; re-verify before reusing this content outside the game.
