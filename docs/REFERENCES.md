# References — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Compiled:** 2026-10-16
**Review rule for this project:** every health claim in the game must trace to a source below.
If a source turns out to say something different, the *game text* changes. A citation is never
adjusted to fit a claim, and no citation is invented.

Every reference here is used by at least one lesson in `scripts/data/lesson_data.gd`. As of
2026-10-16 **all eleven are marked `verified`**: each was opened and the claim in the game was
checked against the source's own words. Earlier drafts marked seven of them **listed** because the
publisher's site could not be reached from the build environment; those were re-opened on
2026-10-16 and promoted (see §6 for the verification log). The `status` field is the same one
stored in `LessonDB.sources()` and validated at startup by `Education.validate_database()`.

---

## 1. Status key

| Status | Meaning |
|--------|---------|
| **verified** | The source text (page, abstract or monograph) was opened and the claim in the game was checked against it on the date shown. |
| **listed** | A well-known agency or peer-reviewed source that supports the claim, but which must still be re-opened by hand before submission. |

At the time of writing no reference is left at **listed**.

---

## 2. Reference list

### Public-health agencies

**[1] World Health Organization.** *Foodborne trematode infections* (fact sheet). Geneva: WHO.
<https://www.who.int/news-room/fact-sheets/detail/foodborne-trematode-infections>
Accessed 2026-10-16. **Status: verified.**
Supports: infection by eating raw fish/crustaceans/vegetables that harbour the larvae; the
snail → fish life cycle; that prevention is by cooking thoroughly, food hygiene and improved
sanitation; that preventive chemotherapy alone is insufficient; the praziquantel regimen.
Used by: `freshwater_fish_risk`, `fluke_lifecycle`, `sanitation_cycle`, `community_action`.

**[2] US Centers for Disease Control and Prevention.** *Clinical Overview of Opisthorchis
(liver flukes)*. Atlanta: CDC, updated 24 June 2024.
<https://www.cdc.gov/liver-flukes/hcp/clinical-overview-opisthorchis/index.html>
Accessed 2026-10-16. **Status: verified.**
Supports: cooking fish to an internal temperature of at least **145 °F (about 63 °C)**;
freezing as an additional measure; praziquantel as the treatment of choice; that people cannot
get *Opisthorchis* from another person or from untreated drinking water; and that only a small
percentage of infected people develop complications such as CCA.
Used by: `cook_thoroughly`, `screening`, `treatment_praziquantel`.
**Screening nuance:** the same page says routine screening is **not** recommended for an
asymptomatic person whose only risk factor is travel. The game's `screening` lesson therefore
describes health-worker-led screening of **at-risk populations in Thailand**, which is supported
by reference [6], and does not tell players to request testing on the basis of travel alone.

**[3] US Centers for Disease Control and Prevention.** *About Opisthorchis (liver flukes)*.
Atlanta: CDC, updated 6 September 2024.
<https://www.cdc.gov/liver-flukes/opisthorchis/index.html>
Accessed 2026-10-16. **Status: verified.**
Supports: transmission by eating raw or undercooked freshwater fish.
Used by: `separate_raw`, `freshwater_fish_risk`.
**Correction:** earlier drafts cited `.../liver-flukes/about/opisthorchis/index.html`, which is
not the page that exists; the live path is `.../liver-flukes/opisthorchis/index.html`.

**[4] US Centers for Disease Control and Prevention.** *About Liver Flukes*.
Atlanta: CDC, updated 6 September 2024.
<https://www.cdc.gov/liver-flukes/about/index.html>
Accessed 2026-10-16. **Status: verified.**
Supports, verbatim: "There are two families of liver flukes that cause disease in humans:
Opisthorchiidae (which includes species of *Clonorchis* and *Opisthorchis*) and Fasciolidae
(which includes species of *Fasciola*)."
Used by: `clean_hands`, `fluke_lifecycle`.

**[5] World Health Organization.** *Five keys to safer food* (manual). Geneva: WHO, 2006.
ISBN 978-92-4-159463-9.
<https://www.who.int/publications/i/item/9789241594639>
Accessed 2026-10-16. **Status: verified.**
Supports, verbatim — the five core messages are: "keep clean; separate raw and cooked; cook
thoroughly; keep food at safe temperatures; and use safe water and raw materials."
Used by: `clean_hands`, `clean_surfaces`, `clean_utensils`, `separate_raw`.

**[6] Department of Disease Control, Ministry of Public Health, Thailand.** Press release,
15 July 2026: *กรมควบคุมโรค แถลงข่าว เผยผลตรวจยืนยันพยาธิใบไม้ตับ พร้อมย้ำ "กินสุก ปรุงสุก
เลี่ยงปลาน้ำจืดดิบ" ป้องกันมะเร็งท่อน้ำดี* (Eat cooked, cook thoroughly, avoid raw freshwater
fish, to prevent bile duct cancer).
<https://ddc.moph.go.th/brc/news.php?news=58817&deptcode=brc>
Accessed 2026-10-16. **Status: verified.**
Supports, in Thai: five prevention steps — (1) eat cooked food, especially all freshwater fish;
(2) avoid raw or undercooked freshwater fish; (3) choose standard-made *pla ra* and cook it before
eating; (4) people who regularly eat raw fish or live in risk areas should be screened as advised
by health staff; (5) if confirmed infected, get treated and followed up, and avoid returning to
risk. It also states plainly that lime, chilli, pickling or alcohol **cannot** kill the larvae and
that cooking with heat is the only safe method; recommends separate boards and knives for raw and
cooked food; and notes that deworming medicine is given only after a positive stool test.
Used by: `sanitation_cycle`, `screening`, `community_action`.
**Replaces:** earlier drafts cited the DDC home page (`https://ddc.moph.go.th/`); this specific,
dated press release is now the citation.

### Cancer agency

**[7] International Agency for Research on Cancer (IARC), World Health Organization.**
*IARC Monographs on the Evaluation of Carcinogenic Risks to Humans, Volume 100B: Biological
Agents* — monograph "*Opisthorchis viverrini* and *Clonorchis sinensis*", §5 Evaluation.
Lyon: IARC, 2012. ISBN 978-92-832-1319-2.
<https://publications.iarc.who.int/Book-And-Report-Series/Iarc-Monographs-On-The-Identification-Of-Carcinogenic-Hazards-To-Humans/Biological-Agents-2012>
Accessed 2026-10-16. **Status: verified.**
Supports, verbatim from the monograph PDF: "Chronic infection with *Opisthorchis viverrini* is
carcinogenic to humans (Group 1)." The same Evaluation section states there is "sufficient
evidence in humans for the carcinogenicity of chronic infection with *Opisthorchis viverrini*"
and that chronic infection "causes cholangiocarcinoma". Volume 100B also confirms the 1994
Volume 61 classification.
Used by: `cancer_link`.
Note: the classified hazard is the **infection**, not a certainty of cancer in an individual.

### Peer-reviewed studies

**[8] Sripa B, Brindley PJ, Mulvenna J, Laha T, Smout MJ, Mairiang E, Bethony JM, Loukas A.**
The tumorigenic liver fluke *Opisthorchis viverrini* — multiple pathways to cancer.
*Trends in Parasitology.* 2012;28(10):395–407. doi:10.1016/j.pt.2012.07.006. PMID 22947297.
PMCID PMC3682777. **Status: verified.**
Supports: the mechanisms linking chronic *O. viverrini* infection to bile duct cancer. The
indexed abstract (read via Europe PMC on 2026-10-16) describes *O. viverrini* and *Clonorchis
sinensis* as risk factors for cholangiocarcinoma and reviews progression from infection through
chronic opisthorchiasis and advanced periductal fibrosis to cholangiocarcinogenesis.
Used by: `cancer_link`.

**[9] Sripan P, Boonmars T, Songsri J, Aukkanimart R, Sriraj P, Rattanasuwan P, Boueroy P,
Suwannatrai A, Aunpromma S, Khuntikeo N, Loilome W, Namwat N, Yongvanit P, PhyoWai A,
Khueangchaingkhwang S, Zhilang W, Pumhirunroj B, Artchayasawat A, Boonjaraspinyo S.**
Simplified techniques for killing the carcinogenic *Opisthorchis viverrini* metacercariae in
cyprinid fish. *Asian Pacific Journal of Cancer Prevention.* 2017;18(6):1507–1511.
doi:10.22034/APJCP.2017.18.6.1507. PMID 28669159. PMCID PMC6373821. **Status: verified.**
Supports: boiling or microwaving (400 or 800 W) for **at least 5 minutes** killed the
metacercariae; freezing at **−20 °C for 48 h** killed them in fish of all sizes; refrigeration
at 4 °C for up to 72 h did not.
Used by: `cook_thoroughly`, `no_substitute`.

**[10] Sornpom J, Suwannatrai AT, Suwannatrai K, Kelly M, Thinkhamrop K.**
Influence of misconceptions and inappropriate eating behaviors on *Opisthorchis viverrini*
infection among at-risk populations undergoing cholangiocarcinoma screening in Northeastern
Thailand. *Parasitology Research.* 2023;122(12):3131–3138. doi:10.1007/s00436-023-08003-1.
PMID 37855971. **Status: verified.**
Supports: among 636 respondents, belief that lime or red ants in *koi pla*, or white whiskey,
killed the parasite was associated with a higher risk of infection (ARR 1.41; 95 % CI
1.03–1.94).
Used by: `no_substitute`.

**[11] Senasri N, Chumnanka N, Talkul W.** Temperature and preparation time intervals on
survival of *Opisthorchis viverrini* metacercariae in pickled fish (*pla-som*).
*International Journal of Food Science.* 2024;2024:4817012. doi:10.1155/2024/4817012.
PMID 39564079. PMCID PMC11576085. **Status: verified.**
Supports: storing infected fish at **−20 °C for 48 h or longer** gave a 0.00 % recovery rate of
metacercariae, while storage at 2, 4, 8 °C or room temperature did not.
Used by: `no_substitute`.

---

## 3. Lesson → source map

| Lesson id | Level | Sources |
|-----------|-------|---------|
| `clean_hands` | l1 | [5] WHO Five Keys, [4] CDC About Liver Flukes |
| `clean_surfaces` | l1 | [5] WHO Five Keys |
| `clean_utensils` | l1 | [5] WHO Five Keys |
| `separate_raw` | l1 | [5] WHO Five Keys, [3] CDC About Opisthorchis |
| `freshwater_fish_risk` | l2, l3 | [3] CDC About Opisthorchis, [1] WHO fact sheet |
| `cook_thoroughly` | l2 | [2] CDC Clinical Overview, [9] Sripan 2017 |
| `no_substitute` | l2 | [10] Sornpom 2023, [9] Sripan 2017, [11] Senasri 2024 |
| `fluke_lifecycle` | l3 | [1] WHO fact sheet, [4] CDC About Liver Flukes |
| `sanitation_cycle` | l3 | [1] WHO fact sheet, [6] Thai DDC |
| `cancer_link` | l3 | [7] IARC Vol. 100B, [8] Sripa 2012 |
| `screening` | l3 | [6] Thai DDC, [2] CDC Clinical Overview |
| `treatment_praziquantel` | l3 | [2] CDC Clinical Overview, [1] WHO fact sheet |
| `community_action` | l3 | [1] WHO fact sheet, [6] Thai DDC |

---

## 4. Where these appear in the game

* **Lesson cards:** after the interactive step that teaches them, the card shows the `simple`
  tier and a citation line built from the source's publisher and title
  (`Education.citation_line()`), with the fuller `detail` tier behind a "read more" control.
* **Knowledge journal:** every lesson the player has covered can be re-read, with its sources.
* **About & sources overlay** (main menu): the full list is available inside the game.

---

## 5. Submission note

The competition report's reference list must be re-formatted to the required citation style
(the report uses a numbered style, as above) and kept **within the report's page limit**
(the announcement allows up to 15 pages for references and appendices combined with the main
text capped at 20 pages; confirm the exact limit in the announcement before submission).

Before submission, **open every URL above once more and confirm it still resolves to the same
content**, since agency pages move and are re-dated. The claims themselves no longer need
re-checking: each was checked against the source's own words on 2026-10-16.

---

## 6. Verification log (2026-10-16)

The seven sources below were previously marked **listed** because the publisher's site could not
be reached from the build environment. On 2026-10-16 each was opened and the relevant text read;
all are now **verified**.

| Ref | Source | What was checked | How |
|-----|--------|------------------|-----|
| [2] | CDC Clinical Overview of Opisthorchis | 145 °F (about 63 °C); praziquantel; no person-to-person or waterborne route; screening-not-for-travel-only nuance | Page fetched and read |
| [3] | CDC About Opisthorchis | raw/undercooked freshwater fish transmission; correct URL | Page fetched and read |
| [4] | CDC About Liver Flukes | Opisthorchiidae includes *Opisthorchis* and *Clonorchis* | Page fetched and read |
| [5] | WHO Five Keys to Safer Food | the five core messages, verbatim | Page fetched and read |
| [6] | Thai DDC press release (15 July 2026) | five prevention steps; lime/chilli/pickling/alcohol do not kill larvae; screening and treatment rules | Thai page fetched and read |
| [7] | IARC Monographs Vol. 100B, §5 | "Chronic infection with *Opisthorchis viverrini* is carcinogenic to humans (Group 1)" | Monograph PDF downloaded and its text searched |
| [8] | Sripa 2012 (Trends in Parasitology) | *O. viverrini* / *C. sinensis* as cholangiocarcinoma risk factors; progression schema | Indexed record + abstract read via Europe PMC |

The four sources already at **verified** before this date were [1] WHO fact sheet, [9] Sripan
2017, [10] Sornpom 2023 and [11] Senasri 2024. No reference is left at **listed**.
