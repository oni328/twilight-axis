// Title prefixes that may be prepended to real_name
GLOBAL_LIST_INIT(familytree_title_prefixes, list(
	"Lord ", "Lady ", "Ser ", "Dame ",
	"Sir ", "Brother ", "Sister ",
	"Father ", "Mother ",
	"King ", "Queen ", "Prince ", "Princess ",
))

/proc/familytree_strip_title(name)
	if(!istext(name) || !length(name))
		return name
	for(var/prefix in GLOB.familytree_title_prefixes)
		if(findtext(name, prefix, 1, length(prefix) + 1))
			return copytext(name, length(prefix) + 1)
	return name

/proc/familytree_names_match(name_a, name_b)
	if(!istext(name_a) || !istext(name_b))
		return FALSE
	if(name_a == name_b)
		return TRUE
	return familytree_strip_title(name_a) == familytree_strip_title(name_b)

/proc/pronoun_preference_matches(preference, same_pronouns)
	if(!preference)
		preference = ANY_GENDER

	switch(preference)
		if(ANY_GENDER)
			return TRUE
		if(SAME_GENDER)
			return same_pronouns
		if(DIFFERENT_GENDER)
			return !same_pronouns

	return FALSE

/proc/pronouns_compatible(mob/living/carbon/human/A, mob/living/carbon/human/B)
	if(!A || !B)
		return FALSE

	var/pref_a = A.gender_choice_pref || ANY_GENDER
	var/pref_b = B.gender_choice_pref || ANY_GENDER
	var/same_pronouns = (A.pronouns == B.pronouns)

	return pronoun_preference_matches(pref_a, same_pronouns) && pronoun_preference_matches(pref_b, same_pronouns)

/datum/controller/subsystem/familytree/proc/SpeciesCompatible(mob/living/carbon/human/A, mob/living/carbon/human/B)
	return !GetSpeciesCompatibilityFailureReason(A, B)

/datum/controller/subsystem/familytree/proc/GetSpeciesCompatibilityFailureReason(mob/living/carbon/human/A, mob/living/carbon/human/B)
	if(!A || !B)
		return "missing mob"

	// Isolated group: gnolls and goblins can match with each other but not with outsiders
	var/a_isolated = is_isolated(A)
	var/b_isolated = is_isolated(B)
	if(a_isolated || b_isolated)
		if(!a_isolated || !b_isolated)
			return "isolated group mismatch"

	if(xylix_roulette_active)
		return null

	var/datum/preferences/PA = A.client?.prefs
	var/datum/preferences/PB = B.client?.prefs

	var/typeA = A.dna.species.type
	var/typeB = B.dna.species.type
	var/list/pref_types_a = get_preference_species_type_list(PA)
	var/list/pref_types_b = get_preference_species_type_list(PB)

	if(PA)
		switch(PA.species_preference_mode)
			if("ANY")
				;
			if("SAME_TYPE")
				if(typeA != typeB)
					return "species mismatch"
			if("SPECIFIC_TYPE")
				if(!(typeB in pref_types_a))
					return "species mismatch"

	if(PB)
		switch(PB.species_preference_mode)
			if("ANY")
				;
			if("SAME_TYPE")
				if(typeA != typeB)
					return "species mismatch"
			if("SPECIFIC_TYPE")
				if(!(typeA in pref_types_b))
					return "species mismatch"

	if(PA)
		if(!AnatomyCompatible(PA.preferred_species_anatomy, B))
			return "anatomy mismatch"

	if(PB)
		if(!AnatomyCompatible(PB.preferred_species_anatomy, A))
			return "anatomy mismatch"

	return null

/datum/controller/subsystem/familytree/proc/AnatomyCompatible(pref, mob/living/carbon/human/target)
	switch(pref)
		if(0)
			return TRUE
		if(1)
			return target.getorganslot(ORGAN_SLOT_PENIS) != null
		if(2)
			return target.getorganslot(ORGAN_SLOT_VAGINA) != null
	return TRUE
