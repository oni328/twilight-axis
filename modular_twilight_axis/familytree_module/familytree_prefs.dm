/proc/familytree_module_get_selectable_species() as /list
	if(!GLOB.roundstart_races.len)
		generate_selectable_species()

	var/list/species_names = list()
	for(var/species_name in GLOB.roundstart_races)
		if(!istext(species_name))
			continue
		var/species_type = GLOB.species_list[species_name]
		if(!ispath(species_type, /datum/species))
			continue
		species_names += species_name

	if(!species_names.len)
		species_names += "Humen"

	return species_names

/proc/familytree_module_get_selectable_species_types() as /list
	var/list/species_types = list()
	for(var/species_name in familytree_module_get_selectable_species())
		var/species_type = GLOB.species_list[species_name]
		if(!ispath(species_type, /datum/species))
			continue
		if(species_type in species_types)
			continue
		species_types += species_type

	if(!species_types.len)
		species_types += /datum/species/human/northern

	return species_types

/datum/preferences/proc/familytree_module_get_slot(slot)
	if(!slot)
		slot = loaded_slot || default_slot
	return sanitize_integer(slot, 1, max_save_slots, initial(default_slot))

/datum/preferences/proc/familytree_module_get_cd(slot)
	slot = familytree_module_get_slot(slot)
	return "/familytree_module/character[slot]"

/datum/preferences/proc/familytree_module_reset_character()
	family = initial(family)
	setspouse = initial(setspouse)
	gender_choice_pref = initial(gender_choice_pref)
	species_preference_mode = initial(species_preference_mode)
	preferred_species_types = list()
	preferred_species_anatomy = initial(preferred_species_anatomy)
	polygamy_mode = initial(polygamy_mode)
	desired_relative_role = initial(desired_relative_role)
	allow_low_status_marriage = initial(allow_low_status_marriage)

/datum/preferences/proc/familytree_module_sanitize_character()
	family = sanitize_integer(family, FAMILY_NONE, FAMILY_NEWLYWED, FAMILY_NONE)
	gender_choice_pref = sanitize_integer(gender_choice_pref, ANY_GENDER, DIFFERENT_GENDER, ANY_GENDER)
	species_preference_mode = sanitize_text(species_preference_mode, "ANY")

	if(!(species_preference_mode in list("ANY", "SAME_TYPE", "SPECIFIC_TYPE")))
		species_preference_mode = "ANY"

	var/list/valid_species = familytree_module_get_selectable_species()
	var/list/sanitized_species = list()

	if(islist(preferred_species_types))
		for(var/entry in preferred_species_types)
			if(!istext(entry))
				continue
			if(!(entry in valid_species))
				continue
			if(entry in sanitized_species)
				continue
			sanitized_species += entry

	preferred_species_types = sanitized_species

	if(species_preference_mode == "SPECIFIC_TYPE")
		if(!preferred_species_types.len)
			species_preference_mode = "ANY"
	else
		preferred_species_types = list()

	preferred_species_anatomy = text2num("[preferred_species_anatomy]")
	if(!(preferred_species_anatomy in list(0, 1, 2)))
		preferred_species_anatomy = 0

	if(!istext(setspouse))
		setspouse = ""
	else
		setspouse = copytext(setspouse, 1, 65)

	polygamy_mode = sanitize_integer(polygamy_mode, POLYGAMY_DISABLED, POLYGAMY_ALLOW_BOTH, POLYGAMY_DISABLED)
	desired_relative_role = sanitize_integer(desired_relative_role, RELATIVE_ANY, RELATIVE_SPOUSE, RELATIVE_ANY)
	allow_low_status_marriage = sanitize_integer(allow_low_status_marriage, 0, 1, 0)
	allow_relatives_in_family = sanitize_integer(allow_relatives_in_family, 0, 1, TRUE)

/datum/preferences/proc/familytree_module_has_enabled_customizer_entry(entry_type)
	validate_customizer_entries()
	var/datum/customizer_entry/entry = get_customizer_entry_of_type(entry_type)
	return entry && !entry.disabled

/datum/preferences/proc/familytree_module_has_penis()
	return familytree_module_has_enabled_customizer_entry(/datum/customizer_entry/organ/penis)

/datum/preferences/proc/familytree_module_has_vagina()
	return familytree_module_has_enabled_customizer_entry(/datum/customizer_entry/organ/vagina)

/datum/preferences/proc/familytree_module_load_character(slot, force = FALSE)
	slot = familytree_module_get_slot(slot)
	if(!force && (familytree_module_loaded_path == path) && (familytree_module_loaded_slot == slot))
		return TRUE

	familytree_module_reset_character()

	if(path && fexists(path))
		var/savefile/S = new /savefile(path)
		if(S)
			S.cd = familytree_module_get_cd(slot)
			S["family"] >> family
			S["gender_choice_pref"] >> gender_choice_pref
			S["setspouse"] >> setspouse
			S["species_preference_mode"] >> species_preference_mode
			S["preferred_species_types"] >> preferred_species_types
			S["preferred_species_anatomy"] >> preferred_species_anatomy
			S["polygamy_mode"] >> polygamy_mode
			S["desired_relative_role"] >> desired_relative_role
			S["allow_low_status_marriage"] >> allow_low_status_marriage
			S["allow_relatives_in_family"] >> allow_relatives_in_family

	familytree_module_sanitize_character()
	familytree_module_loaded_slot = slot
	familytree_module_loaded_path = path
	return TRUE

/datum/preferences/proc/familytree_module_save_character(slot)
	if(!path)
		return FALSE

	slot = familytree_module_get_slot(slot)
	familytree_module_sanitize_character()

	var/savefile/S = new /savefile(path)
	if(!S)
		return FALSE

	S.cd = familytree_module_get_cd(slot)
	WRITE_FILE(S["family"], family)
	WRITE_FILE(S["gender_choice_pref"], gender_choice_pref)
	WRITE_FILE(S["setspouse"], setspouse)
	WRITE_FILE(S["species_preference_mode"], species_preference_mode)
	WRITE_FILE(S["preferred_species_types"], preferred_species_types)
	WRITE_FILE(S["preferred_species_anatomy"], preferred_species_anatomy)
	WRITE_FILE(S["polygamy_mode"], polygamy_mode)
	WRITE_FILE(S["desired_relative_role"], desired_relative_role)
	WRITE_FILE(S["allow_low_status_marriage"], allow_low_status_marriage)
	WRITE_FILE(S["allow_relatives_in_family"], allow_relatives_in_family)

	familytree_module_loaded_slot = slot
	familytree_module_loaded_path = path
	return TRUE
