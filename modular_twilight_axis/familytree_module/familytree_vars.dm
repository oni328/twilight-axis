/datum/preferences
	var/setspouse = ""
	var/datum/family_options/family_options
	var/gender_choice_pref = ANY_GENDER
	var/species_preference_mode = "ANY"
	var/list/preferred_species_types = list()
	var/preferred_species_anatomy = 0
	var/desired_relative_role = RELATIVE_ANY
	var/allow_low_status_marriage = FALSE
	var/tmp/familytree_module_loaded_slot
	var/tmp/familytree_module_loaded_path
	var/allow_relatives_in_family = TRUE

/mob/living/carbon/human
	var/family_UI = TRUE
	var/mob/living/carbon/spouse_mob
	var/image/spouse_indicator
	var/setspouse
	var/gender_choice_pref = ANY_GENDER
	var/familytree_pref = FAMILY_NONE
	var/datum/heritage/family_datum
	var/datum/family_member/family_member_datum
	var/desired_relative_role = RELATIVE_ANY
	var/allow_low_status_marriage = FALSE
	var/tmp/familytree_module_signal_bound = FALSE
	var/tmp/familytree_assignment_scheduled = FALSE
	var/tmp/familytree_opted_out = FALSE
	var/tmp/familytree_setspouse_timeout_offered = FALSE
	var/tmp/familytree_setspouse_retries = 0
	var/allow_relatives_in_family = TRUE