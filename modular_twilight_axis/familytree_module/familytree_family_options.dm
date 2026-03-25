/datum/family_options

/datum/family_options/ui_state(mob/user)
	return GLOB.always_state

/datum/family_options/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FamilySettingsPanel")
		ui.open()
	return TRUE

/datum/family_options/ui_data(mob/user)
	var/list/data = list()

	var/datum/preferences/P = user?.client?.prefs
	if(!P)
		data["familySettings"] = list()
		data["availableSpecies"] = list()
		return data

	P.familytree_module_load_character()

	data["familySettings"] = list(
		"familyType" = _family_to_ui(P.family),
		"genderPreference" = _gender_to_ui(P.gender_choice_pref),
		"speciesPreferenceMode" = P.species_preference_mode ? P.species_preference_mode : "ANY",
		"preferredSpeciesTypes" = islist(P.preferred_species_types) ? P.preferred_species_types.Copy() : list(),
		"preferredSpeciesAnatomy" = P.preferred_species_anatomy,
		"favoriteName" = istext(P.setspouse) ? P.setspouse : "",
		"age" = P.age,
		"polygamyMode" = P.polygamy_mode,
		"desiredRelativeRole" = P.desired_relative_role,
		"allowLowStatusMarriage" = P.allow_low_status_marriage
	)

	var/list/species_names = list()
	for(var/species_name in familytree_module_get_selectable_species())
		species_names += species_name
	data["availableSpecies"] = species_names

	return data

/datum/family_options/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui?.user
	var/datum/preferences/P = user?.client?.prefs
	if(!P)
		return FALSE

	switch(action)
		if("save")
			var/new_family = _ui_to_family(params["familyType"])

			if(new_family == FAMILY_FULL && P.age == AGE_ADULT)
				to_chat(user, span_warning("Вы слишком молоды, чтобы быть родителем."))
				return TRUE

			P.family = new_family
			P.gender_choice_pref = _ui_to_gender(params["genderPreference"])
			P.species_preference_mode = istext(params["speciesPreferenceMode"]) ? params["speciesPreferenceMode"] : "ANY"

			var/list/new_species_types = list()
			if(islist(params["preferredSpeciesTypes"]))
				for(var/entry in params["preferredSpeciesTypes"])
					if(istext(entry))
						new_species_types += entry

			P.preferred_species_types = new_species_types
			P.preferred_species_anatomy = text2num("[params["preferredSpeciesAnatomy"]]")
			P.setspouse = istext(params["favoriteName"]) ? params["favoriteName"] : ""
			P.polygamy_mode = text2num("[params["polygamyMode"]]")
			P.desired_relative_role = text2num("[params["desiredRelativeRole"]]")
			P.allow_low_status_marriage = text2num("[params["allowLowStatusMarriage"]]")

			P.familytree_module_sanitize_character()
			P.familytree_module_save_character()

			SStgui.update_uis(src)
			return TRUE

	return FALSE

/datum/family_options/proc/_family_to_ui(val)
	switch(val)
		if(FAMILY_PARTIAL) return "member"
		if(FAMILY_NEWLYWED) return "couple"
		if(FAMILY_FULL) return "parent"
	return "none"

/datum/family_options/proc/_gender_to_ui(val)
	switch(val)
		if(SAME_GENDER) return "same"
		if(DIFFERENT_GENDER) return "opposite"
	return "any"

/datum/family_options/proc/_ui_to_family(val)
	switch(val)
		if("member") return FAMILY_PARTIAL
		if("couple") return FAMILY_NEWLYWED
		if("parent") return FAMILY_FULL
	return FAMILY_NONE

/datum/family_options/proc/_ui_to_gender(val)
	switch(val)
		if("same") return SAME_GENDER
		if("opposite") return DIFFERENT_GENDER
	return ANY_GENDER
