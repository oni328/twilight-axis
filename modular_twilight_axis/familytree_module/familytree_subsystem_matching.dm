/datum/controller/subsystem/familytree/proc/AddLocal(mob/living/carbon/human/H, status)
	if(!H || !status || istype(H, /mob/living/carbon/human/dummy))
		return
	var/block_reason = get_familytree_runtime_block_reason(H, TRUE)
	if(block_reason == "dead")
		pause_familytree_human(H, "local assignment blocked: dead")
		return
	if(block_reason == "no client")
		return
	if(block_reason)
		unsubscribe_familytree_human(H, "local assignment blocked: [block_reason]")
		return
	if(get_royal_status(H))
		stop_tracking_human(H, "local assignment skipped; handled by royal flow")
		return
	if(is_royal_suitor_job(get_familytree_job(H)))
		stop_tracking_human(H, "local assignment skipped; suitor job")
		return

	if(H.setspouse && length(H.setspouse))
		var/favorite_result = TryAssignToFavorite(H, status)
		if(favorite_result == "assigned")
			stop_tracking_human(H, "assigned via favorite")
			return
		if(favorite_result == "waiting")
			H.familytree_assignment_scheduled = TRUE
			addtimer(CALLBACK(src, PROC_REF(run_local_assignment), H, status), 60 SECONDS)
			return

	if(H.desired_relative_role != RELATIVE_ANY)
		AssignWithDesiredRole(H)
		if(H.family_datum || H.spouse_mob)
			stop_tracking_human(H, "assigned via desired relative role")
			return
	switch(status)
		if(FAMILY_PARTIAL)
			AssignToHouse(H)
			stop_tracking_human(H, H.family_datum ? "assigned to house" : "house assignment completed without family")

		if(FAMILY_NEWLYWED)
			AssignNewlyWed(H)
			if(H.spouse_mob || H.family_datum)
				stop_tracking_human(H, "newlywed flow matched spouse")

		if(FAMILY_FULL)
			if(H.virginity)
				stop_tracking_human(H, "full family flow skipped; virginity gate")
				return
			AssignToFamily(H)
			stop_tracking_human(H, H.family_datum ? "assigned to family" : "family assignment completed without family")

/datum/controller/subsystem/familytree/proc/TryAssignToFavorite(mob/living/carbon/human/H, status)
	if(!H?.setspouse || !length(H.setspouse))
		return "skip"

	var/mob/living/carbon/human/favorite = FindFavoriteMob(H)
	if(!favorite)
		return "waiting"

	if(favorite.setspouse && length(favorite.setspouse))
		if(!familytree_names_match(favorite.setspouse, H.real_name))
			return "waiting"

	if(favorite.family_datum)
		var/datum/heritage/house = favorite.family_datum
		house.AddToFamily(H, favorite.family_member_datum, null, FALSE)
		if(status == FAMILY_NEWLYWED || status == FAMILY_FULL)
			if(H.family_member_datum && favorite.family_member_datum)
				house.MarryMembers(H.family_member_datum, favorite.family_member_datum)
		return "assigned"

	if(status == FAMILY_NEWLYWED || status == FAMILY_FULL)
		H.MarryTo(favorite)
		viable_spouses -= favorite
		viable_spouses -= H
		return "assigned"

	return "waiting"

/datum/controller/subsystem/familytree/proc/FindFavoriteMob(mob/living/carbon/human/H)
	if(!H?.setspouse)
		return null

	for(var/datum/heritage/house as anything in families)
		for(var/datum/family_member/member as anything in house.members)
			if(member.person && familytree_names_match(member.person.real_name, H.setspouse))
				return member.person

	for(var/mob/living/carbon/human/candidate as anything in viable_spouses)
		if(candidate == H)
			continue
		if(familytree_names_match(candidate.real_name, H.setspouse))
			return candidate

	for(var/mob/living/carbon/human/candidate in GLOB.alive_mob_list)
		if(candidate == H)
			continue
		if(!candidate.client || candidate.stat == DEAD)
			continue
		if(familytree_names_match(candidate.real_name, H.setspouse))
			return candidate

	return null

/datum/controller/subsystem/familytree/proc/AssignToHouse(mob/living/carbon/human/H)
	if(!H)
		return

	var/our_race = H.dna.species.name
	var/adopted = FALSE
	var/datum/heritage/chosen_house
	var/list/low_priority_houses = list()
	var/list/high_priority_houses = list()

	for(var/datum/heritage/house as anything in families)
		if(house.housename && house.members.len >= 1 && house.members.len < 6)
			high_priority_houses += house
		else
			low_priority_houses += house

	if(!chosen_house)
		for(var/datum/heritage/house as anything in high_priority_houses)
			if(house.dominant_race.name == our_race && house.members.len < 4)
				if(!WouldCreateAgeConflict(house, H))
					chosen_house = house
					break
			if(prob(20) && house.members.len <= 8)
				if(!WouldCreateAgeConflict(house, H))
					chosen_house = house
					adopted = TRUE
					break

	if(!chosen_house)
		for(var/datum/heritage/house as anything in low_priority_houses)
			if(house.dominant_race.name == our_race)
				if(!WouldCreateAgeConflict(house, H))
					chosen_house = house
					break

	if(chosen_house)
		AddPersonToHouse(chosen_house, H, adopted)

/datum/controller/subsystem/familytree/proc/AddPersonToHouse(datum/heritage/house, mob/living/carbon/human/person, adopted = FALSE)
	var/role = DetermineAppropriateRole(house, person, adopted)

	switch(role)
		if("child")
			var/list/potential_parents = list()
			for(var/datum/family_member/member as anything in house.members)
				if(member.person && CanBeParentOf(member.person, person))
					potential_parents += member

			var/datum/family_member/parent1
			var/datum/family_member/parent2
			var/datum/family_member/single_parent
			var/found_pair = FALSE

			for(var/i = 1 to potential_parents.len)
				var/datum/family_member/candidate1 = potential_parents[i]
				if(!candidate1?.person)
					continue

				if(!single_parent && house.SingleParentSpeciesCalculation(person, candidate1.person))
					single_parent = candidate1

				for(var/j = i + 1 to potential_parents.len)
					var/datum/family_member/candidate2 = potential_parents[j]
					if(!candidate2?.person)
						continue
					if(house.SpeciesCalculation(person, candidate1.person, candidate2.person))
						parent1 = candidate1
						parent2 = candidate2
						found_pair = TRUE
						break

				if(found_pair)
					break

			if(!found_pair && single_parent)
				parent1 = single_parent
				parent2 = null

			if(!parent1)
				parent1 = potential_parents.len > 0 ? potential_parents[1] : null
			if(!parent2 && !single_parent)
				parent2 = potential_parents.len > 1 ? potential_parents[2] : null

			house.AddToFamily(person, parent1, parent2, adopted)

		if("sibling")
			for(var/datum/family_member/member as anything in house.members)
				if(member.person && CanBeSiblings(member.person.age, person.age))
					var/datum/family_member/parent1 = member.parents.len > 0 ? member.parents[1] : null
					var/datum/family_member/parent2 = member.parents.len > 1 ? member.parents[2] : null
					house.AddToFamily(person, parent1, parent2, adopted)
					break

		if("parent")
			var/datum/family_member/new_member = house.CreateFamilyMember(person)
			if(!house.founder)
				house.founder = new_member
				new_member.generation = 0
			if(!house.housename)
				house.housename = house.SurnameFormatting(person)

/datum/controller/subsystem/familytree/proc/AssignToFamily(mob/living/carbon/human/H)
	if(!H)
		return
	var/our_race = H.dna.species.name
	var/list/eligible_houses = list()

	for(var/datum/heritage/house as anything in families)
		if(house.dominant_race.name != our_race)
			continue

		var/has_single_adult = FALSE
		for(var/datum/family_member/member as anything in house.members)
			if(member.person && !member.spouses.len)
				if(!member.person.setspouse || familytree_names_match(member.person.setspouse, H.real_name))
					if(!pronouns_compatible(H, member.person))
						continue
					if(GetSpeciesCompatibilityFailureReason(H, member.person))
						continue
					if(!familytree_estates_compatible(H, member.person))
						continue
					if(!familytree_role_tiers_compatible(H, member.person))
						continue
					if(member.person.familytree_pref == FAMILY_PARTIAL)
						continue
					has_single_adult = TRUE
					eligible_houses += house
					break

		if(!has_single_adult && !house.housename)
			eligible_houses += house

	if(!eligible_houses.len)
		return

	for(var/datum/heritage/house as anything in eligible_houses)
		for(var/datum/family_member/member as anything in house.members)
			if(member.person && !member.spouses.len)
				if(!member.person.setspouse || familytree_names_match(member.person.setspouse, H.real_name))
					if(pronouns_compatible(H, member.person) && SpeciesCompatible(H, member.person) && familytree_estates_compatible(H, member.person) && familytree_role_tiers_compatible(H, member.person))
						var/datum/family_member/new_member = house.CreateFamilyMember(H)
						if(new_member)
							house.MarryMembers(new_member, member)
							return

		if(!house.housename)
			var/datum/family_member/new_member = house.CreateFamilyMember(H)
			if(new_member)
				house.founder = new_member
				new_member.generation = 0
				house.housename = house.SurnameFormatting(H)
				return


/datum/controller/subsystem/familytree/proc/AssignNewlyWed(mob/living/carbon/human/H)
	if(!H)
		return
	var/block_reason = get_familytree_runtime_block_reason(H, TRUE)
	if(block_reason == "dead")
		pause_familytree_human(H, "newlywed blocked: dead")
		return
	if(block_reason == "no client")
		viable_spouses -= H
		return
	if(block_reason)
		unsubscribe_familytree_human(H, "newlywed blocked: [block_reason]")
		return
	if(!(H in viable_spouses))
		viable_spouses += H

	var/list/potential_matches = list()

	for(var/mob/living/carbon/human/potential_spouse as anything in viable_spouses)
		if(!potential_spouse || potential_spouse == H)
			continue
		if(potential_spouse.spouse_mob)
			continue
		var/potential_block_reason = get_familytree_runtime_block_reason(potential_spouse, TRUE)
		if(potential_block_reason == "dead")
			pause_familytree_human(potential_spouse, "removed from newlywed pool: dead")
			continue
		if(potential_block_reason == "no client")
			viable_spouses -= potential_spouse
			continue
		if(potential_block_reason)
			unsubscribe_familytree_human(potential_spouse, "removed from newlywed pool: [potential_block_reason]")
			continue
		if(!pronouns_compatible(H, potential_spouse))
			continue
		var/species_failure_reason = GetSpeciesCompatibilityFailureReason(H, potential_spouse)
		if(species_failure_reason)
			continue
		if(!familytree_estates_compatible(H, potential_spouse))
			continue
		if(!familytree_role_tiers_compatible(H, potential_spouse))
			continue
		if(potential_spouse.setspouse && length(potential_spouse.setspouse))
			if(!familytree_names_match(potential_spouse.setspouse, H.real_name))
				continue
		var/priority = 0
		if(familytree_names_match(potential_spouse.setspouse, H.real_name))
			priority = 1

		potential_matches += list(list(potential_spouse, priority))

	if(potential_matches.len)
		var/best_priority = -1
		var/list/best_matches = list()

		for(var/list/match_data in potential_matches)
			var/match_priority = match_data[2]
			if(match_priority > best_priority)
				best_priority = match_priority
				best_matches = list(match_data[1])
			else if(match_priority == best_priority)
				best_matches += match_data[1]

		if(best_matches.len)
			var/mob/living/carbon/human/chosen_spouse = pick(best_matches)
			viable_spouses -= chosen_spouse
			viable_spouses -= H
			H.MarryTo(chosen_spouse)

/datum/controller/subsystem/familytree/proc/AssignAuntUncle(mob/living/carbon/human/H)
	var/base_species = H.dna.species.name
	var/datum/heritage/chosen_house

	for(var/datum/heritage/house as anything in families)
		if(house.dominant_race.name != base_species)
			continue
		if(!house.housename || house.members.len < 2)
			continue

		var/has_children = FALSE
		for(var/datum/family_member/member as anything in house.members)
			if(member.children.len > 0)
				has_children = TRUE
				break

		if(has_children && !WouldCreateAgeConflict(house, H))
			chosen_house = house
			break

	if(chosen_house)
		var/datum/family_member/new_member = chosen_house.CreateFamilyMember(H)
		if(new_member)
			for(var/datum/family_member/member as anything in chosen_house.members)
				if(member.children.len > 0 && CanBeSiblings(H.age, member.person.age))
					for(var/datum/family_member/grandparent as anything in member.parents)
						new_member.AddParent(grandparent)
					break
