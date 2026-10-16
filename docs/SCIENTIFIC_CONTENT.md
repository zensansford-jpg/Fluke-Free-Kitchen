# Scientific Content — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Last content review:** 2026-10-16
**Applies to:** `scripts/data/lesson_data.gd` (`LessonDB`), `scripts/data/quiz_data.gd`
(`QuizDB`), `scripts/data/level_data.gd` (`LevelDB`), `scripts/data/assessment_data.gd`
(`AssessmentDB`)

This document records **every health claim the game makes**, the lesson that carries it, and
the source that supports it. It exists so that a teacher, a judge or a health professional can
check the content without reading GDScript.

The game does not generate health text at run time. Gameplay asks `Education` for a lesson id
and receives text that is stored in the content database; `Education.validate_database()`
refuses to start quietly if a lesson cites an unknown source or a source outside the approved
agency / peer-reviewed allowlist, so a content error surfaces during development instead of in
front of a student.

---

## 1. The six things that are kept separate

Liver fluke (*Opisthorchis viverrini*) prevention is easy to muddle. The game deliberately keeps
these six ideas apart, because merging them produces wrong advice:

| # | Idea | What the game says | What it does **not** say |
|---|------|--------------------|--------------------------|
| 1 | **Transmission** | You are infected by **eating raw or undercooked freshwater fish** that contain the parasite's larval stage (metacercariae). | It never says water, soil, air or sea fish transmit the infection. |
| 2 | **Food safety** | Cook the fish through; keep raw fish away from food that will not be cooked again; wash hands, boards, knives. | It never says one temperature or one timer is a universal guarantee. |
| 3 | **Sanitation** | Safe toilets and proper wastewater handling keep parasite eggs out of the water where snails and fish live. | It never says a dirty pipe is itself full of flukes, or that one toilet fixes a village overnight. |
| 4 | **Screening** | Screening is carried out and explained by a health worker or doctor. | It never offers a home diagnosis or a self-interpreted test. |
| 5 | **Treatment** | Praziquantel is a prescription medicine given under medical supervision. It clears an existing infection but does not replace prevention. | It never suggests buying deworming tablets casually, or that treatment makes raw fish safe. |
| 6 | **Bile duct cancer** | Long-lasting infection is a **major risk factor**; *O. viverrini* infection is classified by IARC as carcinogenic to humans (Group 1). | It never says infection equals cancer, and never gives a personal risk percentage. |

---

## 2. Lesson-by-lesson content and evidence

Sources are cited by the key used in `LessonDB.sources()`; see `docs/REFERENCES.md` for the full
citations and the verification log. `status` is **verified** (the source text was opened and the
claim checked against it) or **listed** (a well-known agency page still to be re-checked by hand).
As of 2026-10-16 **every source is `verified`**; the column is kept so the history stays visible.

### Level 1 — Clean Kitchen Challenge (ภารกิจครัวสะอาด)

| Lesson | Claim taught | Evidence | Sources | Status |
|--------|--------------|----------|---------|--------|
| `clean_hands` | Wash hands with soap and clean running water before touching food, and again after raw fish; drying matters. | General food-hygiene guidance: "keep clean" (WHO Five Keys, verbatim). | `who_five_keys`, `cdc_about_liver_flukes` | **verified** |
| `clean_surfaces` | Clean the board and counter before cooking, and again after raw fish touches them. | General food-hygiene guidance ("keep clean"). | `who_five_keys` | **verified** |
| `clean_utensils` | A knife or board that touched raw fish can carry larvae to whatever it touches next; wash with soap before reuse. | Cross-contamination principle in "separate raw and cooked". | `who_five_keys` | **verified** |
| `separate_raw` | Juices from raw fish can carry larvae onto food that will not be cooked again; use separate boards, knives and plates. | "Separate raw and cooked" is one of the WHO Five Keys to Safer Food; CDC confirms raw/undercooked freshwater-fish transmission. | `who_five_keys`, `cdc_about_opisthorchis` | **verified** |

**Myth corrected at this level:** `same_board_ok` — one board for raw fish and cooked food is fine.

### Level 2 — Safe Cooking Challenge (ภารกิจปรุงอาหารปลอดภัย)

| Lesson | Claim taught | Evidence | Sources | Status |
|--------|--------------|----------|---------|--------|
| `freshwater_fish_risk` | People become infected by eating raw or undercooked **freshwater** fish containing metacercariae. **Not every fish is infected**, and the larvae cannot be seen. Marine fish are not part of this life cycle. | WHO describes infection by eating raw fish that harbour the larvae, and the freshwater-snail → fish life cycle; CDC describes the same transmission route. | `cdc_about_opisthorchis`, `who_foodborne_trematodes` | **verified** |
| `cook_thoroughly` | Cook the fish until the inside is fully cooked. CDC gives an internal temperature of at least 145 °F (about 63 °C). Heat kills the larvae. There is no single temperature-and-time that suits every dish. | CDC states 145 °F (~63 °C) internal. Independently, a controlled experiment found boiling **or** microwaving (400 or 800 W) for **at least 5 minutes** killed *O. viverrini* metacercariae, confirmed by hamster infectivity. | `cdc_clinical_opisthorchis`, `sripan_2017_killing` | **verified** |
| `no_substitute` | Squeezing lime, salting or short pickling does **not** make raw fish safe. Only cooking it through — or freezing under the studied conditions — kills the larvae. | A study of 636 at-risk people in north-east Thailand found that those who believed lime or red ants in *koi pla*, or white whiskey, killed the parasite were **41 % more likely** to be infected (ARR 1.41; 95 % CI 1.03–1.94). Experiments found metacercariae still infective after short fermentation, and refrigeration at 4 °C for up to 72 h did not kill them; freezing at **−20 °C for 48 h** did. The Thai DDC states that lime, chilli, pickling and alcohol cannot kill the larvae. | `sornpom_2023_misconceptions`, `sripan_2017_killing`, `senasri_2024_pla_som`, `ddc_thailand` | **verified** |

**Myths corrected at this level:** `lime_kills`, `pickling_safe`, `all_fish_infected`, `temp_magic_number`.

> **Why the game does not simply say "cook it to 70 °C for 10 minutes".**
> No single temperature-and-time applies to every fish, every cut and every cooking method, and
> the studies tested particular regimes (boiling/microwaving ≥ 5 min; −20 °C ≥ 48 h). The
> interaction therefore teaches the *principle* — cook it through, keep it at a safe internal
> temperature — and cites CDC's 145 °F guideline rather than inventing a universal rule.

### Level 3 — Village Prevention Challenge (ภารกิจป้องกันระดับหมู่บ้าน)

| Lesson | Claim taught | Evidence | Sources | Status |
|--------|--------------|----------|---------|--------|
| `fluke_lifecycle` | Eggs leave the body in faeces and reach water; they develop in snails, form cysts in freshwater fish, and the cycle repeats when people eat those fish raw. | WHO describes this life cycle, with a freshwater snail as first intermediate host. | `who_foodborne_trematodes`, `cdc_about_liver_flukes` | **verified** |
| `sanitation_cycle` | Open defecation lets eggs reach water; safe latrines and proper wastewater handling keep them out. Community habits matter as much as buildings. | WHO: improved sanitation and food hygiene reduce transmission; preventive chemotherapy alone is insufficient. The Thai DDC calls for hygienic toilets to keep eggs out of natural water. | `who_foodborne_trematodes`, `ddc_thailand` | **verified** |
| `cancer_link` | Long-lasting infection is a major risk factor for bile duct cancer; **not everyone who is infected develops cancer**. | IARC Vol. 100B: "Chronic infection with *Opisthorchis viverrini* is carcinogenic to humans (Group 1)". The infection is the classified hazard, not a promise of cancer; CDC notes only a small percentage of infected people develop complications. | `iarc_opisthorchis_group1`, `sripa_2012_tumorigenic` | **verified** |
| `screening` | Screening is done by health workers, often with a stool test or ultrasound; a professional interprets the result. | The Thai DDC describes health-worker-led screening of at-risk populations and confirms medicine is given only after a positive stool test. CDC describes stool and imaging diagnosis. CDC adds that routine screening is *not* advised for an asymptomatic person whose only risk factor is travel — the lesson is about at-risk populations, not travel-based self-testing. | `ddc_thailand`, `cdc_clinical_opisthorchis` | **verified** |
| `treatment_praziquantel` | Infection can be treated with medicine, usually praziquantel, given under medical supervision. It is not a substitute for prevention — reinfection is possible. | CDC describes praziquantel as the treatment of choice and that infection can last years; WHO gives the praziquantel regimen and notes high reinfection rates without prevention. | `cdc_clinical_opisthorchis`, `who_foodborne_trematodes` | **verified** |
| `community_action` | Prevention works best when everyone takes part: safe cooking at home, clean water, safe toilets and community health checks. | WHO recommends information, education, improved sanitation and One Health collaboration. The Thai DDC frames prevention as a shared, community-level effort. | `who_foodborne_trematodes`, `ddc_thailand` | **verified** |

**Myths corrected at this level:** `dirty_pipe_flukes`, `one_toilet_fixes_all`,
`infection_means_cancer`, `medicine_replaces_prevention`.

---

## 3. What the game deliberately does **not** claim

These omissions are intentional and are part of the content quality:

1. **No universal safe temperature or cooking duration is invented.** The game repeats CDC's
   145 °F internal guideline and reports the laboratory regimes that were actually tested,
   labelled as such.
2. **Not all fish are infected.** The game says "some freshwater fish may carry larvae" and
   "you cannot see them", not "all fish are full of flukes".
3. **Infection is not cancer.** The classification is about risk, and the game states plainly
   that most infected people do not develop cancer.
4. **A dirty pipe is not a fluke reservoir.** The transmission route runs through faeces →
   water → snail → fish → people, which the game shows step by step.
5. **One toilet does not end transmission instantly.** Sanitation is shown as a cycle that a
   community changes over time.
6. **Medicine does not replace prevention.** Praziquantel treats an existing infection; it does
   not protect against the next one.
7. **No incidence, prevalence or improvement figures are quoted** except the one effect size
   that comes straight from a published abstract (ARR 1.41), which is attributed to that study.
8. **No study has been run on this game.** The game itself says so on the assessment screen:
   it reports that no classroom trial has been conducted, so no learning gain can be claimed.

---

## 4. How the content is enforced in code

* `LessonDB` is content, not code: each lesson stores `title`, a `simple` tier and a `detail`
  tier, in Thai and English, plus its `sources`.
* `Education` (autoload) validates the database at startup: every lesson must cite a known
  source inside the approved allowlist, every lesson must have text in both languages, and
  every misconception must point at a real lesson.
* `LevelDB` steps name a `lesson` id and, where a myth is being corrected, a `corrects` list.
  A step never contains free-text health advice.
* `AssessmentDB` holds the optional before/after instrument; it stores no results and makes no
  claim about learning.
* `docs/REFERENCES.md` lists every source with its verification status, the claim it supports and
  the log of when and how it was checked.

---

## 5. Review status

* Content reviewed against sources: **2026-10-16**.
* All eleven sources in `LessonDB.sources()` are now **verified** — the source text was opened and
  the claim checked against it. `docs/REFERENCES.md` §6 logs how each of the seven previously
  `listed` sources was checked.
* Two citations were corrected in the process: the CDC *About Opisthorchis* URL (the earlier path
  did not exist) and the Thai DDC citation (the home page was replaced with the dated press
  release of 15 July 2026).
* The `screening` lesson was checked against CDC's statement that routine screening is not
  recommended for an asymptomatic person whose only risk factor is travel; the lesson describes
  health-worker-led screening of at-risk populations in Thailand, supported by the DDC source, and
  does not tell players to request testing because of travel alone.
* If a source is later found to say something different, the lesson text must change — not the
  citation. The rule for this project is: **the source wins.**
