/datum/controller/subsystem/familytree/proc/find_job_by_type(job_type)
	if(!job_type)
		return null

	for(var/datum/job/candidate as anything in SSjob.occupations)
		if(candidate.type == job_type)
			return candidate

	for(var/datum/job/candidate as anything in SSjob.occupations)
		if(istype(candidate, job_type))
			return candidate

	return null

/datum/controller/subsystem/familytree/proc/resolve_job_datum(role_or_job)
	if(istype(role_or_job, /datum/job))
		return role_or_job
	if(!role_or_job)
		return null

	var/datum/job/job = SSjob.GetJob(role_or_job)
	if(job)
		return job

	var/role_text = "[role_or_job]"
	for(var/datum/job/candidate as anything in SSjob.occupations)
		if(candidate.title == role_text || candidate.display_title == role_text || candidate.f_title == role_text)
			return candidate

	return null

/datum/controller/subsystem/familytree/proc/get_familytree_job(mob/living/carbon/human/H)
	if(!H)
		return null

	var/datum/job/job = resolve_job_datum(H.mind?.assigned_role)
	if(job)
		return job

	return resolve_job_datum(H.job)

/datum/controller/subsystem/familytree/proc/is_banned_species(mob/living/carbon/human/H)
	if(!H?.dna?.species)
		return FALSE
	for(var/species_type in banned_species_types)
		if(istype(H.dna.species, species_type))
			return TRUE
	return FALSE

/datum/controller/subsystem/familytree/proc/is_banned_antag(mob/living/carbon/human/H)
	var/datum/mind/mind = H?.mind
	if(!mind)
		return FALSE
	for(var/antag_type in banned_antag_types)
		if(mind.has_antag_datum(antag_type))
			return TRUE
	return FALSE

/datum/controller/subsystem/familytree/proc/is_familytree_wildshape(mob/living/carbon/human/H)
	return istype(H, /mob/living/carbon/human/species/wildshape)

/datum/controller/subsystem/familytree/proc/get_familytree_unsubscribe_reason(mob/living/carbon/human/H)
	if(!H)
		return "null human"
	if(QDELETED(H))
		return "qdeleted"
	if(istype(H, /mob/living/carbon/human/dummy))
		return "dummy mob"
	if(is_familytree_wildshape(H))
		return "wildshape form"
	if(is_banned_species(H))
		return "banned species"
	if(is_banned_antag(H))
		return "banned antag"
	return null

/datum/controller/subsystem/familytree/proc/get_familytree_runtime_block_reason(mob/living/carbon/human/H, require_client = FALSE)
	var/reason = get_familytree_unsubscribe_reason(H)
	if(reason)
		return reason
	if(H.stat == DEAD)
		return "dead"
	if(require_client && !H.client)
		return "no client"
	return null

/datum/controller/subsystem/familytree/proc/pause_familytree_human(mob/living/carbon/human/H, reason)
	if(!H)
		return
	viable_spouses -= H
	H.familytree_assignment_scheduled = FALSE

/datum/controller/subsystem/familytree/proc/unsubscribe_familytree_human(mob/living/carbon/human/H, reason)
	if(!H)
		return
	viable_spouses -= H
	H.familytree_assignment_scheduled = FALSE
	stop_tracking_human(H, reason)

/datum/controller/subsystem/familytree/proc/is_job_of_type(datum/job/job, list/type_list)
	if(!job || !type_list)
		return FALSE
	for(var/job_type in type_list)
		if(istype(job, job_type))
			return TRUE
	return FALSE

/datum/controller/subsystem/familytree/proc/is_human_job_of_type(mob/living/carbon/human/H, list/type_list)
	if(!H || !type_list)
		return FALSE
	var/datum/job/job = get_familytree_job(H)
	if(!job)
		return FALSE
	return is_job_of_type(job, type_list)

/datum/controller/subsystem/familytree/proc/is_human_job_in_list(mob/living/carbon/human/H, list/title_list)
	if(!H || !title_list)
		return FALSE

	var/datum/job/job = get_familytree_job(H)
	if(job)
		if(job.title in title_list)
			return TRUE
		if(job.display_title && (job.display_title in title_list))
			return TRUE
		if(job.f_title && (job.f_title in title_list))
			return TRUE

	var/mind_role = H.mind?.assigned_role
	if(istext(mind_role) && (mind_role in title_list))
		return TRUE
	if(istext(H.job) && (H.job in title_list))
		return TRUE

	return FALSE

/datum/controller/subsystem/familytree/proc/is_royal_monarch_job(datum/job/job)
	return istype(job, /datum/job/roguetown/lord)

/datum/controller/subsystem/familytree/proc/is_royal_consort_job(datum/job/job)
	return istype(job, /datum/job/roguetown/lady)

/datum/controller/subsystem/familytree/proc/is_royal_suitor_job(datum/job/job)
	return istype(job, /datum/job/roguetown/suitor)

/datum/controller/subsystem/familytree/proc/is_royal_progeny_job(datum/job/job)
	return istype(job, /datum/job/roguetown/prince)

/datum/controller/subsystem/familytree/proc/is_royal_hand_job(datum/job/job)
	return istype(job, /datum/job/roguetown/hand)

/datum/controller/subsystem/familytree/proc/get_royal_status(mob/living/carbon/human/H)
	var/datum/job/job = get_familytree_job(H)
	if(is_royal_monarch_job(job) || is_royal_consort_job(job))
		return H.familytree_get_parental_style() == "feminine" ? FAMILY_MOTHER : FAMILY_FATHER
	if(is_royal_progeny_job(job))
		return FAMILY_PROGENY
	if(is_royal_hand_job(job))
		return FAMILY_OMMER
	return null

/datum/controller/subsystem/familytree/proc/get_royal_delay(mob/living/carbon/human/H)
	var/datum/job/job = get_familytree_job(H)
	if(is_royal_monarch_job(job))
		return 41
	if(is_royal_consort_job(job))
		return 43
	if(is_royal_progeny_job(job) || is_royal_hand_job(job))
		return 45
	return 45

/datum/controller/subsystem/familytree/proc/GetAgeValue(age_string)
	switch(age_string)
		if(AGE_ADULT)
			return 1
		if(AGE_MIDDLEAGED)
			return 2
		if(AGE_OLD)
			return 3
		else
			return 1

/datum/controller/subsystem/familytree/proc/CanBeParentOf(mob/living/carbon/human/parent, mob/living/carbon/human/child)
	var/parent_age = parent.age
	var/child_age = child.age
	if(parent_age == AGE_ADULT)
		return FALSE
	if(parent_age == AGE_MIDDLEAGED && child_age == AGE_ADULT)
		return TRUE
	if(parent_age == AGE_OLD && child_age != AGE_OLD)
		return TRUE
	return FALSE

/datum/controller/subsystem/familytree/proc/CanBeSiblings(age1, age2)
	if(age1 == age2)
		return TRUE

	var/age1_value = GetAgeValue(age1)
	var/age2_value = GetAgeValue(age2)

	if(abs(age1_value - age2_value) <= 1)
		return TRUE

	return FALSE

/datum/controller/subsystem/familytree/proc/WouldCreateAgeConflict(datum/heritage/house, mob/living/carbon/human/person)
	if(!house.members.len)
		return FALSE
	for(var/datum/family_member/member as anything in house.members)
		if(!member.person)
			continue

		for(var/datum/family_member/child as anything in member.children)
			if(child.person && !CanBeParentOf(person, child.person))
				return TRUE

		for(var/datum/family_member/parent as anything in member.parents)
			if(parent.person && !CanBeParentOf(parent.person, person))
				return TRUE

	return FALSE

/datum/controller/subsystem/familytree/proc/DetermineAppropriateRole(datum/heritage/house, mob/living/carbon/human/person, adopted = FALSE)
	var/list/potential_parents = list()
	for(var/datum/family_member/member as anything in house.members)
		if(member.person && CanBeParentOf(member.person, person))
			potential_parents += member

	if(potential_parents.len)
		return "child"

	for(var/datum/family_member/member as anything in house.members)
		if(member.person && CanBeSiblings(member.person.age, person.age))
			return "sibling"

	var/can_parent_someone = FALSE
	for(var/datum/family_member/member as anything in house.members)
		if(member.person && CanBeParentOf(person, member.person))
			can_parent_someone = TRUE
			break

	if(can_parent_someone)
		return "parent"

	return "sibling"

/datum/controller/subsystem/familytree/proc/ValidateAllFamilies()
	if(ruling_family && ruling_family.members.len)
		ValidateFamily(ruling_family)
	for(var/datum/heritage/family as anything in families)
		if(family.members.len)
			ValidateFamily(family)

/datum/controller/subsystem/familytree/proc/ValidateFamily(datum/heritage/family)
	for(var/datum/family_member/member as anything in family.members)
		if(!member.person)
			family.members -= member
			continue

		for(var/datum/family_member/parent as anything in member.parents)
			if(!parent.person || !(member in parent.children))
				member.parents -= parent
				if(parent.person)
					parent.children -= member

		for(var/datum/family_member/child as anything in member.children)
			if(!child.person || !(member in child.parents))
				member.children -= child
				if(child.person)
					child.parents -= member
