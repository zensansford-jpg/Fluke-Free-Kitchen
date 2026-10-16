# Learning Objectives — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Version:** 2.0.0 · **Reviewed:** 2026-10-16

This document states what a player is expected to be able to do after each challenge, and how
the game records that they did it. It is written so a teacher can align the game with a lesson
plan, and so a judge can see the link between the interactive actions and the health content.

---

## 1. Design principles that shape the objectives

1. **Every new action is demonstrated before it is asked for.** A step that introduces a gesture
   (tap, drag, swipe, hold, choose, order, checklist) plays a demonstration first. The player is
   never asked to perform something they have not seen.
2. **Nothing is scored on speed.** There is no timer and no penalty for taking time. Points come
   from doing an action correctly, from getting food-safety decisions right first time, and from
   answering knowledge questions.
3. **A wrong answer teaches and allows a retry.** Wrong answers show a short explanation and the
   player continues. Nothing shames the player and nothing is permanently blocked.
4. **Education cannot be skipped for credit.** Each challenge ends with at least one **required**
   knowledge question. A level does not count as passed — no stars — until the required question
   has been answered correctly.
5. **Two reading tiers per lesson.** Every lesson carries a `simple` tier (one or two short
   sentences) and a `detail` tier (the fuller explanation, opened on request). One build can
   therefore serve primary, lower-secondary and upper-secondary students.
6. **A high score is not proof of learning.** The star rating measures activity accuracy and
   completion. It is deliberately kept separate from the knowledge journal, which records which
   lessons and questions the player actually engaged with.

---

## 2. Level 1 — Clean Kitchen Challenge (ภารกิจครัวสะอาด)

**Learner-facing goal:** learn why clean hands, utensils and work surfaces matter, and how
separating raw food from ready-to-eat food stops contamination.

| # | Objective (learner can…) | Lesson | Activity in the game | Assessment pair |
|---|--------------------------|--------|----------------------|-----------------|
| 1.1 | **Choose** the correct way to wash hands before preparing food | `clean_hands` | Step `wash_hands` — tap the best option out of three | `pre_1`/`post_1` (transmission) |
| 1.2 | **Wash** a work surface until it is clean | `clean_surfaces` | Step `clean_board` — swipe across the board until 85 % covered | — |
| 1.3 | **Select** clean utensils rather than a raw-fish board | `clean_utensils` | Step `choose_utensils` — tap the correct board and knife | — |
| 1.4 | **Separate** raw fish from ready-to-eat food and place each item correctly | `separate_raw` | Step `separate_food` — drag four items to the right tray | — |
| 1.5 | **Correct** a cross-contamination mistake and explain why "it looks clean" is not enough | `separate_raw` | Step `spot_mistake` — choose the safer of three responses | — |

**Misconception corrected:** `same_board_ok` (one board for raw fish and cooked food is fine).
**Required knowledge question:** `q_l1_separate`. **Optional:** `q_l1_hands`.

---

## 3. Level 2 — Safe Cooking Challenge (ภารกิจปรุงอาหารปลอดภัย)

**Learner-facing goal:** understand that eating raw or undercooked freshwater fish can pass on
liver flukes, how fish should be cooked, and why lime, salt and pickling are not substitutes.

| # | Objective (learner can…) | Lesson | Activity in the game | Assessment pair |
|---|--------------------------|--------|----------------------|-----------------|
| 2.1 | **Identify** which ingredient must be cooked thoroughly, and recognise that not every fish is infected | `freshwater_fish_risk` | Step `identify_fish` — tap the freshwater fish out of four ingredients | `pre_1`/`post_1` |
| 2.2 | **Prepare** raw fish on a separate board from ready-to-eat food | `clean_surfaces` | Step `prep_board` — drag the fish to the raw-fish board | — |
| 2.3 | **Heat** the pan before cooking | — | Step `heat_pan` — press and hold until the progress ring fills | — |
| 2.4 | **Cook** the fish to a safe internal temperature and hold it there, understanding that no single time-and-temperature fits every dish | `cook_thoroughly` | Step `cook_fish` — hold until 63 °C and keep it there for 5 seconds | `pre_3`/`post_3` |
| 2.5 | **Reject** the lime/salt/pickling shortcut and choose thorough cooking instead | `no_substitute` | Step `lime_or_cook` — choose the safer of three responses | `pre_2`/`post_2` |

**Misconceptions corrected:** `lime_kills`, `pickling_safe`, `all_fish_infected`,
`temp_magic_number`.
**Required knowledge question:** `q_l2_cook`. **Optional:** `q_l2_lime`.

---

## 4. Level 3 — Village Prevention Challenge (ภารกิจป้องกันระดับหมู่บ้าน)

**Learner-facing goal:** review food-handling situations, correct a sanitation mistake, and
learn how liver fluke infection relates to bile duct cancer, screening and treatment.

| # | Objective (learner can…) | Lesson | Activity in the game | Assessment pair |
|---|--------------------------|--------|----------------------|-----------------|
| 3.1 | **Identify** the practice that lets parasite eggs reach the water | `sanitation_cycle` | Step `find_sanitation_problem` — tap the correct option out of three | `pre_4`/`post_4` |
| 3.2 | **Decide** where household wastewater should go | `sanitation_cycle` | Step `wastewater_choice` — choose the safer of three options | `pre_4`/`post_4` |
| 3.3 | **Order** the parasite's life cycle from egg to human infection | `fluke_lifecycle` | Step `order_lifecycle` — arrange five steps in sequence | `pre_1`/`post_1` |
| 3.4 | **State** who decides on and explains screening | `screening` | Step `screening_statement` — tap the correct statement | — |
| 3.5 | **State** the correct role of treatment and that it does not replace prevention | `treatment_praziquantel` | Step `treatment_statement` — tap the correct statement | `pre_6`/`post_6` |
| 3.6 | **Select** every prevention action from a mixed list | `community_action` | Step `prevention_checklist` — tick the correct actions, leave the myths | `pre_5`/`post_5` |

**Misconceptions corrected:** `dirty_pipe_flukes`, `one_toilet_fixes_all`,
`infection_means_cancer`, `medicine_replaces_prevention`.
**Required knowledge question:** `q_l3_cancer`. **Optional:** `q_l3_treatment`.

---

## 5. Progression across the three challenges

The challenges are ordered so that the level of thinking rises:

| Level | Focus | Typical thinking |
|-------|-------|------------------|
| 1 | **Knowledge and routine** — do the safe action | recall, apply a rule, recognise a mistake |
| 2 | **Application and judgement** — choose the safe action when a shortcut is offered | apply, compare options, reject a plausible myth |
| 3 | **Analysis and community thinking** — trace the cycle and place one action in a wider system | order, evaluate statements, decide who is responsible |

Levels unlock in order (`l1 → l2 → l3`), so the required knowledge question of a level is always
answered before the next challenge opens.

---

## 6. What the game records as evidence

The game keeps a learning record (`SaveData.learning`, owned by the `Learning` autoload):
activities completed, lessons covered, misconceptions corrected, and each knowledge question's
outcome and number of attempts. It also keeps per-level stars, best score, attempts, completion
and best accuracy in the save file. The **recipe journal** makes the lessons re-readable at any
time, so the education is a place the player can return to, not a single pass-or-fail event.

This is evidence of **engagement and activity**, not of learning. Whether the game changes what
a student believes or does is precisely what the research plan (`docs/RESEARCH_PLAN.md`) is set
up to measure — and it has not been measured yet.

---

## 7. Honest limits

* The star rating rewards accuracy and completion; it is **not** a validated measure of
  knowledge. A player can reach three stars and still hold a misconception.
* The optional before/after instrument (`AssessmentDB`) is built and playable but **no study has
  been run**. The game states this on the assessment screen, in the player's own language, and
  the project makes no claim of measured learning gain.
* Each level carries 5–6 short steps (1–3 minutes of play). The objectives above describe what
  one session is designed to teach; retention needs the follow-up and community elements that
  the research plan describes, not the game alone.
