/proc/familytree_can_officiate_wedding(mob/living/carbon/human/priest, mob/living/carbon/human/bride, mob/living/carbon/human/groom)
	if(!priest || !bride || !groom)
		return FALSE

	if(!priest.mind)
		return FALSE

	var/datum/job/priest_job = SSfamilytree.get_familytree_job(priest)
	if(!priest_job)
		return FALSE

	if(!familytree_is_clergy(priest_job))
		return FALSE

	var/datum/patron/priest_patron = priest.patron
	var/datum/patron/bride_patron = bride.patron
	var/datum/patron/groom_patron = groom.patron

	if(!priest_patron || istype(priest_patron, /datum/patron/godless))
		return FALSE

	var/priest_rank = familytree_get_clergy_rank(priest)
	var/bride_rank = familytree_get_social_rank(bride)
	var/groom_rank = familytree_get_social_rank(groom)

	if(!familytree_rank_can_marry_rank(priest_rank, bride_rank))
		return FALSE
	if(!familytree_rank_can_marry_rank(priest_rank, groom_rank))
		return FALSE

	if(familytree_patron_matches(priest_patron, bride_patron) || familytree_patron_matches(priest_patron, groom_patron))
		return TRUE

	return FALSE

/proc/familytree_is_clergy(datum/job/job)
	if(!job)
		return FALSE
	return SSfamilytree.is_job_of_type(job, SSfamilytree.clergy_job_types)

/datum/controller/subsystem/familytree
	var/list/clergy_job_types = list(
		/datum/job/roguetown/priest,
		/datum/job/roguetown/templar,
		/datum/job/roguetown/monk,
		/datum/job/roguetown/sexton,
		/datum/job/roguetown/keeper,
		/datum/job/roguetown/martyr,
		/datum/job/roguetown/druid,
	)

	var/list/high_clergy_job_types = list(
		/datum/job/roguetown/priest,
	)

	var/list/mid_clergy_job_types = list(
		/datum/job/roguetown/templar,
		/datum/job/roguetown/druid,
	)

/proc/familytree_patron_matches(datum/patron/priest_p, datum/patron/person_p)
	if(!priest_p || !person_p)
		return FALSE

	if(istype(person_p, /datum/patron/godless))
		return TRUE

	if(priest_p.type == person_p.type)
		return TRUE

	if(istype(priest_p, /datum/patron/divine/undivided))
		return istype(person_p, /datum/patron/divine)

	if(istype(person_p, /datum/patron/divine/undivided))
		return istype(priest_p, /datum/patron/divine)

	return FALSE

#define SOCIAL_RANK_LOW 1
#define SOCIAL_RANK_MID 2
#define SOCIAL_RANK_HIGH 3

/proc/familytree_get_clergy_rank(mob/living/carbon/human/priest)
	var/datum/job/job = SSfamilytree.get_familytree_job(priest)
	if(!job)
		return SOCIAL_RANK_LOW

	if(SSfamilytree.is_job_of_type(job, SSfamilytree.high_clergy_job_types))
		return SOCIAL_RANK_HIGH
	if(SSfamilytree.is_job_of_type(job, SSfamilytree.mid_clergy_job_types))
		return SOCIAL_RANK_MID

	return SOCIAL_RANK_LOW

/proc/familytree_get_social_rank(mob/living/carbon/human/H)
	if(familytree_get_estate(H) == ESTATE_NOBLE)
		return SOCIAL_RANK_HIGH

	var/tier = familytree_get_role_tier(H)
	if(tier == ROLE_TIER_LOW)
		return SOCIAL_RANK_LOW

	return SOCIAL_RANK_MID

/proc/familytree_rank_can_marry_rank(priest_rank, person_rank)
	if(priest_rank >= person_rank)
		return TRUE
	return FALSE

/proc/familytree_perform_wedding(mob/living/carbon/human/priest, mob/living/carbon/human/person1, mob/living/carbon/human/person2)
	if(!familytree_can_officiate_wedding(priest, person1, person2))
		return FALSE

	var/datum/heritage/family = person1.MarryTo(person2)
	if(!family)
		return FALSE

	var/announcement = "[priest.real_name] has united [person1.real_name] and [person2.real_name] in holy matrimony!"
	for(var/mob/living/carbon/human/M in view(7, priest))
		to_chat(M, span_love(announcement))

	SSfamilytree.on_family_formed(family)

	return TRUE

/proc/familytree_ritual_adopt(mob/living/carbon/human/parent, mob/living/carbon/human/child)
	if(!parent || !child)
		return FALSE
	if(!parent.family_datum)
		return FALSE
	if(child.family_datum == parent.family_datum)
		return FALSE

	var/datum/family_member/parent_member = parent.family_member_datum
	if(!parent_member)
		return FALSE

	parent.family_datum.AddToFamily(child, parent_member, null, TRUE)
	return TRUE

/proc/familytree_vampire_bind(mob/living/carbon/human/sire, mob/living/carbon/human/progeny)
	if(!sire || !progeny)
		return FALSE

	if(!sire.family_datum)
		var/datum/heritage/new_family = new /datum/heritage(sire, null)
		sire.family_datum = new_family
		SSfamilytree.families += new_family

	sire.family_datum.AddToFamily(progeny, sire.family_member_datum, null, TRUE)
	return TRUE
