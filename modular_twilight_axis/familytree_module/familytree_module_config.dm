// === FAMILYTREE MODULE ===
// #include "modular_twilight_axis\familytree_module\familytree_module_config.dm"
//
// --- FILE MAP ---
// familytree_vars.dm              - var declarations (preferences, mob, human)
// familytree_prefs.dm             - savefile load/save/sanitize, species lists
// familytree_mob_procs.dm         - MarryTo, verbs, known families, UI toggles
// familytree_royal_job_hooks.dm   - special_check_latejoin for lady/suitor
// familytree_display.dm           - TGUI display panel datum
// familytree_curses.dm            - family_curse datum, status effects
// familytree_member.dm            - family_member: parents/children/spouses, traversal
// familytree_member_terms.dm      - gendered terms (father/mother/son/daughter...)
// familytree_member_relations.dm  - GetRelationshipTo, siblings, cousins, in-laws
// familytree_heritage_core.dm     - heritage datum: house, members, marriage, species calc, UI
// familytree_family_options.dm    - TGUI settings panel backend (ui_data/ui_act)
// familytree_subsystem_compat.dm  - pronouns/species/anatomy compatibility checks
// familytree_subsystem_jobs.dm    - job helpers, age checks, validation
// familytree_subsystem_core.dm    - SSfamilytree: init, signals, lifecycle, queue
// familytree_subsystem_royal.dm   - royal partner jobs, lineage generation
// familytree_subsystem_matching.dm- AssignToHouse/Family/NewlyWed matching
// familytree_estates.dm           - estates (noble/commoner), compatibility filter
// familytree_role_tiers.dm        - social role tiers (high/low), overlap filter
// familytree_storytellers.dm      - storyteller influence (Astrata/Eora/Baotha/Psydon/Ravox/Noc/Dendor), karma
// familytree_polygamy.dm          - polygamy: flags, lore checks (Baotha/drow)
// familytree_rituals.dm           - priest wedding, adoption, vampire binding
// familytree_holy_verbs.dm        - holy skill spells: establish bond (3+), divorce (5+), bypass (6), divine wrath
// familytree_relative_search.dm   - desired family role (sibling/parent/child/uncle/spouse)
// familytree_confirmation.dm   - family assignment confirmation + setspouse timeout
// familytree_notifications.dm  - family head departure notifications
// familytree_noble_dynasty.dm  - nobles in ruling family (TRAIT_NOBLE)
// familytree_enigma.dm        - DLC: enigma roles integration into tier system
//
// TGUI: tgui/packages/tgui/interfaces/FamilySettingsPanel.tsx
//       tgui/packages/tgui/interfaces/FamilyDisplayPanel.tsx
// Assets: relations.dmi

#define FAMILYTREE_DEBUG_LOGGING //UNDEFINE IT FOR THE LOCAL TESTING

#ifndef FAMILY_NONE
#define FAMILY_NONE 1
#define FAMILYTREE_MODULE_DEFINED_FAMILY_NONE
#endif

#ifndef FAMILY_PARTIAL
#define FAMILY_PARTIAL 2
#define FAMILYTREE_MODULE_DEFINED_FAMILY_PARTIAL
#endif

#define FAMILY_NEWLYWED 4

#ifndef FAMILY_FULL
#define FAMILY_FULL 3
#define FAMILYTREE_MODULE_DEFINED_FAMILY_FULL
#endif

#define ANY_GENDER 1
#define SAME_GENDER 2
#define DIFFERENT_GENDER 3

#define FAMILY_FATHER "Father"
#define FAMILY_MOTHER "Mother"
#define FAMILY_PROGENY "Progeny"
#define FAMILY_OMMER "Parents Sibling"
#define FAMILY_INLAW "In Law"

#define POLYGAMY_DISABLED 0
#define POLYGAMY_ALLOW_MULTIPLE 1
#define POLYGAMY_ALLOW_BE_SECOND 2
#define POLYGAMY_ALLOW_BOTH 3

#define RELATIVE_ANY 0
#define RELATIVE_SIBLING 1
#define RELATIVE_PARENT 2
#define RELATIVE_CHILD 3
#define RELATIVE_UNCLE_AUNT 4
#define RELATIVE_SPOUSE 5

#include "familytree_vars.dm"
#include "familytree_prefs.dm"
#include "familytree_mob_procs.dm"
#include "familytree_royal_job_hooks.dm"
#include "familytree_display.dm"
#include "familytree_curses.dm"
#include "familytree_member.dm"
#include "familytree_member_terms.dm"
#include "familytree_member_relations.dm"
#include "familytree_heritage_core.dm"
#include "familytree_family_options.dm"
#include "familytree_subsystem_compat.dm"
#include "familytree_subsystem_jobs.dm"
#include "familytree_subsystem_core.dm"
#include "familytree_subsystem_royal.dm"
#include "familytree_subsystem_matching.dm"
#include "familytree_estates.dm"
#include "familytree_role_tiers.dm"
#include "familytree_storytellers.dm"
#include "familytree_polygamy.dm"
#include "familytree_rituals.dm"
#include "familytree_holy_verbs.dm"
#include "familytree_relative_search.dm"
#include "familytree_enigma.dm"
#include "familytree_confirmation.dm"
#include "familytree_notifications.dm"
#include "familytree_noble_dynasty.dm"
#include "familytree_debug.dm"
