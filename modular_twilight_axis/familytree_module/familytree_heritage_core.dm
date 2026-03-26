/datum/heritage
	var/housename
	var/datum/species/dominant_species
	var/datum/species/dominant_race
	var/list/members = list()
	var/list/family_icons = list()
	var/datum/family_member/founder

	var/list/family_curses = list()
	var/list/curse_history = list()

/datum/heritage/proc/AddFamilyCurse(datum/family_curse/curse_type, severity, mob/curser)
	var/datum/family_curse/new_curse = new curse_type()
	new_curse.curse_type = curse_type
	new_curse.severity = severity
	new_curse.cursed_by = WEAKREF(curser)
	new_curse.when_cursed = world.time

	family_curses += new_curse

	curse_history += "The [housename] family was cursed with [new_curse.name] by [curser]"

	ApplyCurseEffects(new_curse)

	return new_curse

/datum/heritage/proc/ApplyCurseEffects(datum/family_curse/curse)
	for(var/datum/family_member/F as anything in members)
		if(F.person)
			for(var/effect in curse.curse_effects)
				F.person.apply_status_effect(effect)

/datum/heritage/proc/InheritCurses(datum/family_member/child)
	for(var/datum/family_curse/curse as anything in family_curses)
		if(curse.inherited)
			for(var/effect in curse.curse_effects)
				child.person?.apply_status_effect(effect)


/datum/heritage/proc/TransferToFamily(mob/living/carbon/human/person, relationship_type)
	var/datum/family_member/member = CreateFamilyMember(person)
	if(!member)
		return FALSE

	switch(relationship_type)
		if(FAMILY_INLAW)
			member.adoption_status = FALSE
		if(FAMILY_FATHER, FAMILY_MOTHER)
			pass()

	to_chat(person, span_notice("You have joined the [housename] family as [relationship_type]."))
	return member

/datum/heritage/proc/ConductWedding(datum/family_member/bride, datum/family_member/groom, mob/living/carbon/human/officiant)
	if(!bride || !groom || !officiant)
		return FALSE

	if(!MarryMembers(bride, groom))
		return FALSE

	var/announcement = "[bride.person?.real_name] and [groom.person?.real_name] have been wed in the [housename] family!"

	for(var/datum/family_member/member as anything in members)
		if(member.person && member.person?.client)
			to_chat(member.person, span_love(announcement))

	bride.HandleBiologicalChildren(groom)

	return TRUE

/datum/heritage/New(mob/living/carbon/human/founder_person, new_name, majority_species)
	if(founder_person)
		founder = CreateFamilyMember(founder_person)
		founder.generation = 0

		if(!new_name)
			housename = SurnameFormatting(founder_person)
		else
			housename = new_name

		dominant_species = majority_species
		dominant_race = founder_person?.dna?.species?.name
		if(!majority_species)
			dominant_species = founder_person?.dna?.species?.type

/datum/heritage/proc/CreateFamilyMember(mob/living/carbon/human/person)
	if(!ishuman(person))
		return null

	for(var/datum/family_member/existing as anything in members)
		if(existing.person == person)
			return existing

	var/datum/family_member/new_member = new(person, src)
	members += new_member
	person?.family_datum = src

	AddFamilyIcon(person)
	LateJoinAddToUI(person)

	return new_member

/datum/heritage/proc/AddToFamily(mob/living/carbon/human/person, datum/family_member/parent1, datum/family_member/parent2, adopt = FALSE)
	var/datum/family_member/new_member = CreateFamilyMember(person)
	if(!new_member)
		return FALSE

	new_member.adoption_status = adopt

	if(parent1)
		new_member.AddParent(parent1)
	if(parent2)
		new_member.AddParent(parent2)

	if(!adopt && parent1 && parent2)
		if(SpeciesCalculation(person, parent1.person, parent2.person))
			person?.MixDNA(parent1.person, parent2.person, override = TRUE)
		else
			new_member.adoption_status = TRUE
	else if(!adopt)
		var/datum/family_member/known_parent = parent1 ? parent1 : parent2
		if(known_parent && !SingleParentSpeciesCalculation(person, known_parent.person))
			new_member.adoption_status = TRUE

	to_chat(person, span_notice("You have been added to the [housename] family."))
	InheritCurses(new_member)
	return new_member

/datum/heritage/proc/MarryMembers(datum/family_member/person1, datum/family_member/person2)
	if(!person1 || !person2)
		return FALSE

	if(person2 in person1.spouses)
		return FALSE

	person1.AddSpouse(person2)

	if(person1.person && person2.person)
		pass()

	to_chat(person1.person, span_love("You are now married to [person2.person?.real_name]!"))
	to_chat(person2.person, span_love("You are now married to [person1.person?.real_name]!"))

	return TRUE

/datum/heritage/proc/GetFamilyMember(mob/living/carbon/human/person)
	for(var/datum/family_member/member as anything in members)
		if(member.person == person)
			return member
	return null

/datum/heritage/proc/ReturnRelation(mob/living/carbon/human/lookee, mob/living/carbon/human/looker)
	if(lookee == looker)
		return null

	var/datum/family_member/looker_member = GetFamilyMember(looker)
	var/datum/family_member/lookee_member = GetFamilyMember(lookee)

	if(!looker_member || !lookee_member)
		return null

	var/relationship = looker_member.GetRelationshipTo(lookee_member)
	if(!relationship)
		return null

	var/p_They = lookee.p_they(TRUE)
	var/p_are = lookee.p_are()
	var/relationship_text = "[p_They] [p_are] my [relationship]"

	if(lookee_member.adoption_status && (relationship in list("son", "daughter", "child")))
		relationship_text += " (adopted)"

	return span_love(span_bold("[relationship_text]."))

/datum/heritage/proc/GetDisplayHouseTitle()
	var/household = trim("[housename]")
	if(!household)
		return "Nameless House"
	return "THE [uppertext(household)] HOUSE"

/datum/heritage/proc/GetRelationColor(relation_text)
	switch(relation_text)
		if("father", "mother", "parent")
			return "#4169E1"
		if("son", "daughter", "child")
			return "#32CD32"
		if("brother", "sister", "sibling")
			return "#FFD700"
		if("husband", "wife", "spouse")
			return "#FF69B4"
	return "#9370DB"

/datum/heritage/proc/BuildFamilyDisplayEntry(datum/family_member/checker_member, datum/family_member/member)
	if(!member?.person)
		return null

	var/relation_text = ""
	if(checker_member)
		relation_text = checker_member.GetRelationshipTo(member)

	var/list/details = list()
	if(member.adoption_status)
		details += "Adopted"
	if(member.spouses.len)
		var/list/spouse_names = list()
		for(var/datum/family_member/spouse as anything in member.spouses)
			if(spouse.person?.real_name)
				spouse_names += spouse.person.real_name
		if(spouse_names.len)
			details += "Married to: [jointext(spouse_names, ", ")]"

	return list(
		"name" = member.person.real_name,
		"label" = relation_text ? uppertext(relation_text) : null,
		"details" = details,
		"accentColor" = GetRelationColor(relation_text),
	)

/datum/heritage/proc/OpenCursePanel(mob/living/carbon/human/user)
	if(!user || !family_curses.len)
		return FALSE

	var/datum/familytree_display_panel/panel = new(
		user,
		"Family Modifier Details",
		GetDisplayHouseTitle(),
		"No family modifiers are active.",
	)

	var/list/entries = list()
	for(var/datum/family_curse/curse as anything in family_curses)
		var/list/details = list()
		if(curse.description)
			details += curse.description
		if(curse.cursed_by)
			var/mob/curser = curse.cursed_by.resolve()
			if(curser?.real_name)
				details += "[curse.blessing ? "Blessed" : "Cursed"] by: [curser.real_name]"
		details += "Severity: [curse.severity]/3"
		details += "Time cursed: [DisplayTimeText(world.time - curse.when_cursed)] ago"

		entries += list(list(
			"name" = curse.name,
			"label" = curse.blessing ? "BLESSING" : "CURSE",
			"details" = details,
			"accentColor" = curse.blessing ? "#4CAF50" : "#C62828",
		))

	panel.add_section("Current Modifiers", entries)
	panel.ui_interact(user)
	return TRUE

/datum/heritage/proc/GetMemberForPerson(mob/living/carbon/human/P)
	for(var/datum/family_member/member as anything in members)
		if(member.person == P)
			return member
	return null

/datum/heritage/proc/GetGenerationName(generation)
	switch(generation)
		if(0)
			return "Founders"
		if(1)
			return "First Generation"
		if(2)
			return "Second Generation"
		if(3)
			return "Third Generation"
		if(4)
			return "Fourth Generation"
		else
			return "Generation [generation]"

/datum/heritage/proc/ListFamily(mob/living/carbon/human/checker)
	if(!checker)
		return FALSE
	if(!members.len)
		return FALSE

	var/datum/familytree_display_panel/panel = new(
		checker,
		GetDisplayHouseTitle(),
		"",
		"No family members found.",
	)

	var/datum/family_member/checker_member = GetMemberForPerson(checker)
	var/list/by_generation = list()
	var/list/generation_order = list()

	for(var/datum/family_member/member as anything in members)
		var/gen_key = "[member.generation]"
		if(!by_generation[gen_key])
			by_generation[gen_key] = list()
			generation_order += member.generation
		by_generation[gen_key] += member

	generation_order = sortList(generation_order, GLOBAL_PROC_REF(cmp_numeric_asc))

	for(var/generation as anything in generation_order)
		var/list/entries = list()
		for(var/datum/family_member/member as anything in by_generation["[generation]"])
			var/list/entry = BuildFamilyDisplayEntry(checker_member, member)
			if(entry)
				entries += list(entry)
		panel.add_section(GetGenerationName(generation), entries)

	panel.ui_interact(checker)
	return TRUE

/datum/heritage/proc/SpeciesCalculation(mob/living/carbon/human/child, mob/living/carbon/human/parent1, mob/living/carbon/human/parent2)
	var/child_species_type = child.dna?.species?.type
	var/parent1_species_type = parent1.dna?.species?.type
	var/parent2_species_type = parent2.dna?.species?.type

	if(!child_species_type || !parent1_species_type || !parent2_species_type)
		return FALSE

	if(child_species_type == parent1_species_type && child_species_type == parent2_species_type)
		return TRUE

	if((parent1_species_type == /datum/species/tieberian) || (parent2_species_type == /datum/species/tieberian))
		return child_species_type == /datum/species/tieberian

	var/parent1_is_human = (parent1_species_type == /datum/species/human/northern)
	var/parent2_is_human = (parent2_species_type == /datum/species/human/northern)
	var/parent1_is_elf = ispath(parent1_species_type, /datum/species/elf)
	var/parent2_is_elf = ispath(parent2_species_type, /datum/species/elf)
	if((parent1_is_human && parent2_is_elf) || (parent2_is_human && parent1_is_elf))
		return child_species_type == /datum/species/human/halfelf

	var/parent1_is_orcish = ispath(parent1_species_type, /datum/species/orc)
	var/parent2_is_orcish = ispath(parent2_species_type, /datum/species/orc)
	var/parent1_is_halforc = (parent1_species_type == /datum/species/halforc)
	var/parent2_is_halforc = (parent2_species_type == /datum/species/halforc)
	if((parent1_is_human && (parent2_is_orcish || parent2_is_halforc)) || (parent2_is_human && (parent1_is_orcish || parent1_is_halforc)))
		return child_species_type == /datum/species/halforc

	if(parent1_is_elf && parent2_is_elf && ispath(child_species_type, /datum/species/elf))
		return TRUE

	return FALSE

/datum/heritage/proc/SingleParentSpeciesCalculation(mob/living/carbon/human/child, mob/living/carbon/human/parent)
	var/child_species_type = child.dna?.species?.type
	var/parent_species_type = parent.dna?.species?.type

	if(!child_species_type || !parent_species_type)
		return FALSE

	if(child_species_type == parent_species_type)
		return TRUE

	var/parent_is_human = (parent_species_type == /datum/species/human/northern)
	var/parent_is_elf = ispath(parent_species_type, /datum/species/elf)
	var/parent_is_orcish = ispath(parent_species_type, /datum/species/orc) || (parent_species_type == /datum/species/halforc)

	if(child_species_type == /datum/species/tieberian)
		return parent_species_type == /datum/species/tieberian

	if(child_species_type == /datum/species/human/halfelf)
		return parent_is_human || parent_is_elf || parent_species_type == /datum/species/human/halfelf

	if(child_species_type == /datum/species/halforc)
		return parent_is_human || parent_is_orcish

	if(ispath(child_species_type, /datum/species/elf))
		return parent_is_elf

	return FALSE

/datum/heritage/proc/SurnameFormatting(mob/living/carbon/human/person)
	var/surname2use
	var/index = findtext(person?.real_name, " ")
	person?.original_name = person?.real_name
	if(!index)
		surname2use = person?.dna?.species?.random_surname()
	else
		if(findtext(person?.real_name, " of ") || findtext(person?.real_name, " the "))
			surname2use = person?.dna?.species?.random_surname()
		else
			surname2use = copytext(person?.real_name, index)
	return surname2use

/datum/heritage/proc/ApplyUI(mob/living/carbon/human/iconer, toggle_true = FALSE)
	if(!iconer.client)
		return FALSE
	for(var/mob/living/carbon/human/H as anything in family_icons)
		if(toggle_true)
			iconer.client.images.Remove(family_icons[H])
			continue
		if(!H || H == iconer)
			continue
		iconer.client.images.Add(family_icons[H])

/datum/heritage/proc/LateJoinAddToUI(mob/living/carbon/human/new_fam)
	for(var/datum/family_member/member as anything in members)
		var/mob/living/carbon/human/H = member.person
		if(H && H.family_UI && H.client && H != new_fam)
			if(new_fam in family_icons)
				H.client.images.Add(family_icons[new_fam])

/datum/heritage/proc/AddFamilyIcon(mob/living/carbon/human/famicon)
	var/datum/family_member/member = GetFamilyMember(famicon)
	if(!member)
		return FALSE

	var/icon_state = member.adoption_status ? "adopted" : "related"
	var/image/I = new('modular_twilight_axis/familytree_module/relations.dmi', loc = famicon, icon_state = icon_state)

	if(famicon in family_icons)
		family_icons.Remove(famicon)
	family_icons[famicon] = I

	return TRUE
