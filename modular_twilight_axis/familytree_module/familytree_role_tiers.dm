#define ROLE_TIER_NONE 0
#define ROLE_TIER_HIGH 1
#define ROLE_TIER_LOW 2

/datum/controller/subsystem/familytree
	// Nobility and ducal family
	var/list/high_tier_nobility_types = list(
		/datum/job/roguetown/lord,
		/datum/job/roguetown/lady,
		/datum/job/roguetown/exlady,
		/datum/job/roguetown/prince,
		/datum/job/roguetown/hand,
		/datum/job/roguetown/suitor,
	)

	// Church and inquisition
	var/list/high_tier_church_types = list(
		/datum/job/roguetown/priest,
		/datum/job/roguetown/templar,
		/datum/job/roguetown/monk,
		/datum/job/roguetown/druid,
		/datum/job/roguetown/keeper,
		/datum/job/roguetown/sexton,
		/datum/job/roguetown/martyr,
		/datum/job/roguetown/inquisitor,
		/datum/job/roguetown/orthodoxist,
		/datum/job/roguetown/absolver,
	)

	// Town military and garrison
	var/list/high_tier_military_types = list(
		/datum/job/roguetown/knight,
		/datum/job/roguetown/marshal,
		/datum/job/roguetown/sergeant,
		/datum/job/roguetown/watchman,
		/datum/job/roguetown/warden,
		/datum/job/roguetown/manorguard,
	)

	// Key town professions (courtiers and administration)
	var/list/high_tier_town_types = list(
		/datum/job/roguetown/seneschal,
		/datum/job/roguetown/councillor,
		/datum/job/roguetown/magician,
		/datum/job/roguetown/guildmaster,
		/datum/job/roguetown/adventurer/courtagent,
	)

	// Criminal and outlaw roles
	var/list/low_tier_job_types = list(
		/datum/job/roguetown/wretch,
		/datum/job/roguetown/bandit,
		/datum/job/roguetown/assassin,
		/datum/job/roguetown/lunatic,
		/datum/job/roguetown/vagabond,
	)

	// Fallback title list for advclass-based roles without own job datums
	var/list/low_tier_job_titles = list(
		"Beggar",
		"Excommunicado",
		"Thug",
		"Doomsayer",
	)

/proc/familytree_get_role_tier(mob/living/carbon/human/H)
	if(!H)
		return ROLE_TIER_NONE

	if(SSfamilytree.is_human_job_of_type(H, SSfamilytree.high_tier_nobility_types))
		return ROLE_TIER_HIGH

	if(SSfamilytree.is_human_job_of_type(H, SSfamilytree.high_tier_church_types))
		return ROLE_TIER_HIGH

	if(SSfamilytree.is_human_job_of_type(H, SSfamilytree.high_tier_military_types))
		return ROLE_TIER_HIGH

	if(SSfamilytree.is_human_job_of_type(H, SSfamilytree.high_tier_town_types))
		return ROLE_TIER_HIGH

	if(SSfamilytree.is_human_job_of_type(H, SSfamilytree.low_tier_job_types))
		return ROLE_TIER_LOW

	if(SSfamilytree.is_human_job_in_list(H, SSfamilytree.low_tier_job_titles))
		return ROLE_TIER_LOW

	return ROLE_TIER_NONE

/proc/familytree_role_tiers_compatible(mob/living/carbon/human/A, mob/living/carbon/human/B)
	if(SSfamilytree.xylix_roulette_active)
		return TRUE

	var/tier_a = familytree_get_role_tier(A)
	var/tier_b = familytree_get_role_tier(B)

	if(tier_a <= ROLE_TIER_LOW && tier_b <= ROLE_TIER_LOW)
		return TRUE
	if(tier_a == ROLE_TIER_NONE && tier_b == ROLE_TIER_NONE)
		return TRUE

	if((tier_a == ROLE_TIER_LOW && tier_b == ROLE_TIER_HIGH) || (tier_a == ROLE_TIER_HIGH && tier_b == ROLE_TIER_LOW))
		var/datum/heritage/house = A.family_datum || B.family_datum
		if(house && is_elite_family(house))
			return FALSE

		var/mob/living/carbon/human/leader = house?.house_leader?.person || house?.founder?.person
		if(leader && (leader == A || leader == B))
			return leader.allow_low_status_marriage

		return A.allow_low_status_marriage || B.allow_low_status_marriage

	return TRUE

/proc/is_elite_family(datum/heritage/house)
	if(!house || house.members.len < 2)
		return FALSE

	var/high_count = 0
	for(var/datum/family_member/member as anything in house.members)
		if(member.person && familytree_get_role_tier(member.person) == ROLE_TIER_HIGH)
			high_count++
			if(high_count >= 2)
				return TRUE
	return FALSE
