/datum/family_member
	var/tmp/mob/living/carbon/human/person
	var/datum/heritage/family
	var/list/parents = list()
	var/list/children = list()
	var/list/spouses = list()
	var/list/former_spouses = list()
	var/adoption_status = FALSE
	var/generation = 0
	var/tmp/recalculating_generation = FALSE
	var/mutable_appearance/cloned_look

/datum/family_member/New(mob/living/carbon/human/new_person, datum/heritage/new_family)
	person = new_person
	family = new_family
	person?.family_member_datum = src
	var/old_dir = person?.dir
	var/old_invisibility = person?.invisibility
	person?.invisibility = 0
	person?.dir = SOUTH
	cloned_look = new_person?.appearance
	person?.dir = old_dir
	person?.invisibility = old_invisibility

/datum/family_member/proc/AddParent(datum/family_member/parent, skip_reciprocal = FALSE)
	if(!parent || (parent in parents))
		return FALSE
	if(parents.len >= 2)
		return FALSE

	if(IsAncestorOf(parent))
		return FALSE

	parents += parent

	if(!skip_reciprocal && !(src in parent.children))
		parent.AddChild(src, TRUE)

	RecalculateGeneration()
	return TRUE

/datum/family_member/proc/RemoveParent(datum/family_member/parent, skip_reciprocal = FALSE)
	if(!parent || !(parent in parents))
		return FALSE

	parents -= parent

	if(!skip_reciprocal && (src in parent.children))
		parent.RemoveChild(src, TRUE)

	RecalculateGeneration()
	return TRUE

/datum/family_member/proc/AddChild(datum/family_member/child, skip_reciprocal = FALSE)
	if(!child || (child in children))
		return FALSE

	if(IsDescendantOf(child))
		return FALSE

	children += child

	if(!skip_reciprocal && !(src in child.parents))
		child.AddParent(src, TRUE)

	child.RecalculateGeneration()
	return TRUE

/datum/family_member/proc/RemoveChild(datum/family_member/child, skip_reciprocal = FALSE)
	if(!child || !(child in children))
		return FALSE

	children -= child

	if(!skip_reciprocal && (src in child.parents))
		child.RemoveParent(src, TRUE)

	child.RecalculateGeneration()
	return TRUE

/datum/family_member/proc/AddSpouse(datum/family_member/spouse, skip_reciprocal = FALSE)
	if(!spouse || (spouse in spouses))
		return FALSE

	spouses += spouse
	person.spouse_mob = spouse.person

	if(!skip_reciprocal && !(src in spouse.spouses))
		spouse.AddSpouse(src, TRUE)

	HandleBiologicalChildren(spouse)
	return TRUE

/datum/family_member/proc/RemoveSpouse(datum/family_member/spouse, divorce = FALSE, skip_reciprocal = FALSE)
	if(!spouse || !(spouse in spouses))
		return FALSE

	spouses -= spouse

	if(!skip_reciprocal && (src in spouse.spouses))
		spouse.RemoveSpouse(src, divorce, TRUE)

	if(divorce)
		if(!(spouse in former_spouses))
			former_spouses += spouse
		if(!skip_reciprocal && !(src in spouse.former_spouses))
			spouse.former_spouses += src

	return TRUE

/datum/family_member/proc/IsAncestorOf(datum/family_member/other)
	if(!other || other == src)
		return FALSE

	var/list/checked = list(src)
	var/list/to_check = children.Copy()

	while(to_check.len)
		var/datum/family_member/current = to_check[1]
		to_check -= current

		if(current == other)
			return TRUE

		if(!(current in checked))
			checked += current
			to_check += current.children

	return FALSE

/datum/family_member/proc/IsDescendantOf(datum/family_member/other)
	if(!other || other == src)
		return FALSE

	var/list/checked = list(src)
	var/list/to_check = parents.Copy()

	while(to_check.len)
		var/datum/family_member/current = to_check[1]
		to_check -= current

		if(current == other)
			return TRUE

		if(!(current in checked))
			checked += current
			to_check += current.parents

	return FALSE

/datum/family_member/proc/HandleBiologicalChildren(datum/family_member/spouse)
	for(var/datum/family_member/child as anything in children)
		if(child in spouse.children)
			if(family.SpeciesCalculation(child.person, person, spouse.person))
				child.adoption_status = FALSE
				child.person?.MixDNA(person, spouse.person, override = TRUE)

/datum/family_member/proc/RecalculateGeneration()
	if(recalculating_generation)
		return
	recalculating_generation = TRUE

	if(!parents.len)
		generation = 0
	else
		var/max_parent_gen = -1
		for(var/datum/family_member/parent as anything in parents)
			if(parent.generation > max_parent_gen)
				max_parent_gen = parent.generation
		generation = max_parent_gen + 1

	recalculating_generation = FALSE

	for(var/datum/family_member/child as anything in children)
		if(!child.recalculating_generation)
			child.RecalculateGeneration()
