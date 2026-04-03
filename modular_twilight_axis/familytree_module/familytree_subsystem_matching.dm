/datum/controller/subsystem/familytree/proc/AddLocal(mob/living/carbon/human/H, status)
	ftlog("AddLocal: [H?.real_name] ([H?.ckey]) status=[status]")
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
		ftlog("AddLocal SKIP: [H.real_name] royal flow")
		stop_tracking_human(H, "local assignment skipped; handled by royal flow")
		return
	if(is_royal_suitor_job(get_familytree_job(H)))
		ftlog("AddLocal SKIP: [H.real_name] suitor job")
		stop_tracking_human(H, "local assignment skipped; suitor job")
		return

	if(H.setspouse && length(H.setspouse))
		ftlog("AddLocal: [H.real_name] has favorite=[H.setspouse], trying favorite assign (retry #[H.familytree_setspouse_retries])")
		var/favorite_result = TryAssignToFavorite(H, status)
		if(favorite_result == "assigned")
			stop_tracking_human(H, "assigned via favorite")
			return
		if(favorite_result == "waiting")
			H.familytree_setspouse_retries++
			if(H.familytree_setspouse_retries >= 30 && !H.familytree_setspouse_timeout_offered)
				H.familytree_setspouse_timeout_offered = TRUE
				ftlog("AddLocal: [H.real_name] setspouse timeout reached (30 retries), offering reset")
				INVOKE_ASYNC(src, PROC_REF(offer_setspouse_reset), H, status)
				return
			ftlog("AddLocal: [H.real_name] favorite not found, waiting 60s")
			H.familytree_assignment_scheduled = TRUE
			addtimer(CALLBACK(src, PROC_REF(run_local_assignment), H, status), 60 SECONDS)
			return

	if(try_assign_noble_to_dynasty(H))
		return

	if(H.desired_relative_role != RELATIVE_ANY)
		ftlog("AddLocal: [H.real_name] desired_role=[H.desired_relative_role], trying role assign")
		AssignWithDesiredRole(H)
		if(H.family_datum || H.spouse_mob)
			ftlog("AddLocal: [H.real_name] assigned via desired role")
			stop_tracking_human(H, "assigned via desired relative role")
			return

	switch(status)
		if(FAMILY_PARTIAL)
			if(HasSuitableHouseForRelative(H))
				ftlog("AddLocal: [H.real_name] -> AssignToHouse (pending confirm)")
				request_family_confirmation(H, CALLBACK(src, PROC_REF(do_assign_house), H), "house")
			else
				ftlog("AddLocal: [H.real_name] → NO suitable house, trying to form sibling house")
				TryFormSiblingHouseFromPartial(H)

		if(FAMILY_NEWLYWED)
			ftlog("AddLocal: [H.real_name] -> FindNewlyWedMatch")
			INVOKE_ASYNC(src, PROC_REF(find_and_confirm_newlywed), H)

		if(FAMILY_FULL)
			if(H.virginity)
				ftlog("AddLocal: [H.real_name] SKIP: virginity gate")
				stop_tracking_human(H, "full family flow skipped; virginity gate")
				return
			ftlog("AddLocal: [H.real_name] -> FindFamilyMatch")
			INVOKE_ASYNC(src, PROC_REF(find_and_confirm_family), H)

/datum/controller/subsystem/familytree/proc/do_assign_house(mob/living/carbon/human/H)
	if(!H || QDELETED(H) || H.family_datum)
		return
	ftlog("do_assign_house: [H.real_name] confirmed, calling AssignToHouse")
	AssignToHouse(H)
	if(H.family_datum)
		to_chat(H, span_love("Вы успешно присоединились к семье!"))
		stop_tracking_human(H, "assigned to house")
	else
		to_chat(H, span_warning("Не удалось присоединиться к семье."))
		ftlog("do_assign_house: [H.real_name] continue working. Has family = NO")

/datum/controller/subsystem/familytree/proc/find_and_confirm_newlywed(mob/living/carbon/human/H)
	if(!H || QDELETED(H) || H.spouse_mob)
		return
	var/mob/living/carbon/human/spouse = FindNewlyWedMatch(H)
	if(!spouse)
		ftlog("AddLocal: [H.real_name] newlywed no match found")
		return
	ftlog("AddLocal: [H.real_name] newlywed match=[spouse.real_name], requesting mutual confirm")
	request_mutual_confirmation(H, spouse, CALLBACK(src, PROC_REF(do_execute_newlywed), H, spouse), "spouse")

/datum/controller/subsystem/familytree/proc/do_execute_newlywed(mob/living/carbon/human/H, mob/living/carbon/human/spouse)
	if(!H || QDELETED(H) || H.spouse_mob)
		return
	if(!spouse || QDELETED(spouse) || spouse.spouse_mob)
		return
	ftlog("AddLocal: [H.real_name] + [spouse.real_name] -> MarryTo (both confirmed)")
	viable_spouses -= H
	viable_spouses -= spouse
	H.MarryTo(spouse)
	stop_tracking_human(H, "newlywed flow matched spouse")
	stop_tracking_human(spouse, "newlywed flow matched spouse")

/datum/controller/subsystem/familytree/proc/find_and_confirm_family(mob/living/carbon/human/H)
	if(!H || QDELETED(H) || H.family_datum)
		return
	var/list/match = FindFamilyMatch(H)
	if(!match)
		ftlog("AddLocal: [H.real_name] family no match found, creating new house")
		var/datum/heritage/new_house = new /datum/heritage(H, null)
		families += new_house
		ftlog("AddLocal: [H.real_name] founded new house '[new_house.housename]'")
		stop_tracking_human(H, "founded new house (no match)")
		return
	var/datum/heritage/house = match[1]
	var/datum/family_member/partner_member = match[2]
	var/mob/living/carbon/human/partner = partner_member?.person
	if(!partner)
		return
	ftlog("AddLocal: [H.real_name] family match=[partner.real_name] in house=[house.housename], requesting mutual confirm")
	request_mutual_confirmation(H, partner, CALLBACK(src, PROC_REF(do_execute_family), H, house, partner_member), "family")

/datum/controller/subsystem/familytree/proc/do_execute_family(mob/living/carbon/human/H, datum/heritage/house, datum/family_member/partner_member)
	if(!H || QDELETED(H) || H.family_datum)
		return
	if(!house || !partner_member?.person)
		return
	if(partner_member.spouses.len)
		return
	ftlog("AddLocal: [H.real_name] -> AssignToFamily in house=[house.housename] (both confirmed)")
	var/datum/family_member/new_member = house.CreateFamilyMember(H)
	if(new_member)
		house.MarryMembers(new_member, partner_member)
	stop_tracking_human(H, H.family_datum ? "assigned to family" : "family assignment failed")

/datum/controller/subsystem/familytree/proc/TryAssignToFavorite(mob/living/carbon/human/H, status)
	if(!H?.setspouse || !length(H.setspouse))
		ftlog("TryFavorite SKIP: [H?.real_name] no setspouse")
		return "skip"

	ftlog("TryFavorite: [H.real_name] looking for '[H.setspouse]'")
	var/mob/living/carbon/human/favorite = FindFavoriteMob(H)

	if(!favorite)
		ftlog("TryFavorite: [H.real_name] favorite NOT FOUND, waiting")
		return "waiting"

	ftlog("TryFavorite: [H.real_name] found favorite=[favorite.real_name] ([favorite.ckey])")

	if(favorite.setspouse && length(favorite.setspouse))
		if(!familytree_names_match(favorite.setspouse, H.real_name))
			return "waiting"

	var/mutual_sibling = (H.desired_relative_role == RELATIVE_SIBLING && favorite.desired_relative_role == RELATIVE_SIBLING)

	if(mutual_sibling)
		ftlog("TryFavorite: [H.real_name] + [favorite.real_name] mutual sibling -> mutual confirm")
		request_mutual_confirmation(H, favorite, CALLBACK(src, PROC_REF(do_form_sibling_house), H, favorite), "sibling_house")
		return "assigned"

	if(favorite.family_datum)
		var/datum/heritage/house = favorite.family_datum
		if(status == FAMILY_NEWLYWED || status == FAMILY_FULL)
			var/datum/family_member/new_member = house.CreateFamilyMember(H)
			if(new_member && favorite.family_member_datum)
				if(favorite.family_member_datum.spouses.len)
					var/datum/family_member/old_dummy = favorite.family_member_datum.spouses[1]
					if(old_dummy?.person && istype(old_dummy.person, /mob/living/carbon/human/dummy))
						favorite.family_member_datum.RemoveSpouse(old_dummy)
						house.members -= old_dummy
						qdel(old_dummy.person)
						qdel(old_dummy)
				new_member.generation = favorite.family_member_datum.generation
				house.MarryMembers(H.family_member_datum, favorite.family_member_datum)
		else
			house.CreateFamilyMember(H)
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
		if(candidate.familytree_pref == FAMILY_NONE)
			continue
		if(familytree_names_match(candidate.real_name, H.setspouse))
			return candidate

	return null

/datum/controller/subsystem/familytree/proc/AssignToHouse(mob/living/carbon/human/H)
	if(!H)
		return
	ftlog("AssignToHouse START: [H.real_name] race=[H.dna?.species?.name] isolated=[is_isolated(H)] pref=[H.familytree_pref]")

	var/our_race = H.dna.species.name
	var/we_are_isolated = is_isolated(H)

	var/list/candidates = list()

	for(var/datum/heritage/house as anything in families)
		if(house.closed)
			continue
		if(!house.housename || house.housename == "no name")
			continue
		if(!house_race_compatible(house, our_race, we_are_isolated))
			continue
		if(WouldCreateAgeConflict(house, H))
			continue
		if(house.members.len < 1)
			continue

		candidates += house

	if(candidates.len)
		var/datum/heritage/chosen_house = pick(candidates)
		ftlog("AssignToHouse: [H.real_name] → JOINED existing house '[chosen_house.housename || "no name"]' (members=[chosen_house.members.len])")
		AddPersonToHouse(chosen_house, H, FALSE)
		stop_tracking_human(H, "assigned to house")
	else
		ftlog("AssignToHouse: [H.real_name] → NO suitable existing house found. Staying without family.")

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
	ftlog("AssignToFamily: [H.real_name] species=[H.dna?.species?.name] isolated=[is_isolated(H)]")
	var/our_race = H.dna.species.name
	var/our_isolated = is_isolated(H)
	var/list/eligible_houses = list()

	for(var/datum/heritage/house as anything in families)
		if(house.closed)
			continue
		if(!house_race_compatible(house, our_race, our_isolated))
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

	ftlog("AssignToFamily: [H.real_name] eligible_houses=[eligible_houses.len]")
	if(!eligible_houses.len)
		ftlog("AssignToFamily: [H.real_name] no eligible houses, creating new")
		var/datum/heritage/new_house = new /datum/heritage(H, null)
		families += new_house
		ftlog("AssignToFamily: [H.real_name] founded new house '[new_house.housename]'")
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


/datum/controller/subsystem/familytree/proc/FindNewlyWedMatch(mob/living/carbon/human/H)
	if(!H)
		return null
	var/block_reason = get_familytree_runtime_block_reason(H, TRUE)
	if(block_reason)
		return null
	if(!(H in viable_spouses))
		viable_spouses += H

	var/list/potential_matches = list()
	for(var/mob/living/carbon/human/candidate as anything in viable_spouses)
		if(!candidate || candidate == H || candidate.spouse_mob)
			continue
		if(candidate.familytree_opted_out)
			continue
		var/cand_block = get_familytree_runtime_block_reason(candidate, TRUE)
		if(cand_block)
			continue
		if(!pronouns_compatible(H, candidate))
			continue
		if(GetSpeciesCompatibilityFailureReason(H, candidate))
			continue
		if(!familytree_estates_compatible(H, candidate))
			continue
		if(!familytree_role_tiers_compatible(H, candidate))
			continue
		if(candidate.setspouse && length(candidate.setspouse))
			if(!familytree_names_match(candidate.setspouse, H.real_name))
				continue
		var/priority = 0
		if(familytree_names_match(candidate.setspouse, H.real_name))
			priority = 1
		potential_matches += list(list(candidate, priority))

	if(!potential_matches.len)
		return null

	var/best_priority = -1
	var/list/best_matches = list()
	for(var/list/match_data in potential_matches)
		var/match_priority = match_data[2]
		if(match_priority > best_priority)
			best_priority = match_priority
			best_matches = list(match_data[1])
		else if(match_priority == best_priority)
			best_matches += match_data[1]

	if(!best_matches.len)
		return null
	return pick(best_matches)

/datum/controller/subsystem/familytree/proc/FindFamilyMatch(mob/living/carbon/human/H)
	if(!H)
		return null
	var/our_race = H.dna.species.name
	var/our_isolated = is_isolated(H)

	for(var/datum/heritage/house as anything in families)
		if(house.closed)
			continue
		if(!house_race_compatible(house, our_race, our_isolated))
			continue
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
					if(member.person.familytree_opted_out)
						continue
					return list(house, member)
	return null

/datum/controller/subsystem/familytree/proc/AssignNewlyWed(mob/living/carbon/human/H)
	if(!H)
		return
	ftlog("AssignNewlyWed: [H.real_name] species=[H.dna?.species?.name] viable_spouses=[viable_spouses.len]")
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

	ftlog("AssignNewlyWed: [H.real_name] potential_matches=[potential_matches.len]")
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
			ftlog("AssignNewlyWed: [H.real_name] MARRIED to [chosen_spouse.real_name]")
			viable_spouses -= chosen_spouse
			viable_spouses -= H
			H.MarryTo(chosen_spouse)
	else
		ftlog("AssignNewlyWed: [H.real_name] no matches, staying in viable_spouses")

/datum/controller/subsystem/familytree/proc/AssignAuntUncle(mob/living/carbon/human/H)
	var/base_species = H.dna.species.name
	var/base_isolated = is_isolated(H)
	var/datum/heritage/chosen_house

	for(var/datum/heritage/house as anything in families)
		if(house.closed)
			continue
		if(!house_race_compatible(house, base_species, base_isolated))
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

/datum/controller/subsystem/familytree/proc/do_form_sibling_house(mob/living/carbon/human/initiator, mob/living/carbon/human/partner)
	if(!initiator || QDELETED(initiator) || initiator.family_datum)
		return
	if(!partner || QDELETED(partner) || partner.family_datum)
		return

	var/datum/heritage/new_house = new /datum/heritage(initiator, null)
	new_house.closed = TRUE
	new_house.house_leader = new_house.founder
	families += new_house

	var/datum/family_member/partner_member = new_house.CreateFamilyMember(partner)
	if(partner_member)
		partner_member.generation = 0

	ftlog("SIBLING HOUSE: [initiator.real_name] + [partner.real_name] formed closed house '[new_house.housename]', leader=[initiator.real_name]")
	on_family_formed(new_house)

	to_chat(initiator, span_love("Вы основали дом [new_house.housename]!"))
	to_chat(partner, span_love("Вы вступили в дом [new_house.housename]."))

	stop_tracking_human(initiator, "formed sibling house")
	stop_tracking_human(partner, "joined sibling house")

	ask_open_sibling_house(initiator, new_house)

/datum/controller/subsystem/familytree/proc/ask_open_sibling_house(mob/living/carbon/human/leader, datum/heritage/house)
	if(!leader?.client)
		return
	INVOKE_ASYNC(src, PROC_REF(do_ask_open_sibling_house), leader, house)

/datum/controller/subsystem/familytree/proc/do_ask_open_sibling_house(mob/living/carbon/human/leader, datum/heritage/house)
	if(!leader?.client)
		return

	var/result = tgui_alert(leader, "Открыть дом [house.housename] для вступления родственников?", "Дом [house.housename]", list("Да", "Нет"))

	if(!leader || QDELETED(leader))
		return
	if(!house)
		return

	if(result == "Да")
		house.closed = FALSE
		ftlog("SIBLING HOUSE: [leader.real_name] opened house '[house.housename]' for relatives")
		to_chat(leader, span_notice("Дом [house.housename] открыт для родственников."))
	else
		ftlog("SIBLING HOUSE: [leader.real_name] kept house '[house.housename]' closed")
		to_chat(leader, span_notice("Дом [house.housename] останется закрытым. Вступить можно только через обряд жреца."))

/datum/controller/subsystem/familytree/proc/HasSuitableHouseForRelative(mob/living/carbon/human/H)
	if(!H)
		return FALSE

	var/our_race = H.dna.species.name
	var/we_are_isolated = is_isolated(H)

	for(var/datum/heritage/house as anything in families)
		if(house.closed)
			continue
		if(!house.housename || house.housename == "no name")
			continue
		if(!house_race_compatible(house, our_race, we_are_isolated))
			continue
		if(WouldCreateAgeConflict(house, H))
			continue
		if(house.members.len >= 1)
			return TRUE

	return FALSE

/datum/controller/subsystem/familytree/proc/TryFormSiblingHouseFromPartial(mob/living/carbon/human/H)
	if(!H || H.family_datum)
		return

	for(var/mob/living/carbon/human/candidate as anything in GLOB.alive_mob_list)
		if(candidate == H || !candidate.client || candidate.stat == DEAD || candidate.familytree_pref != FAMILY_PARTIAL || candidate.family_datum)
			continue
		if(!pronouns_compatible(H, candidate))
			continue
		if(GetSpeciesCompatibilityFailureReason(H, candidate))
			continue
		if(!familytree_estates_compatible(H, candidate))
			continue
		if(!familytree_role_tiers_compatible(H, candidate))
			continue
		if(!CanBeSiblings(H.age, candidate.age))
			continue

		ftlog("TryFormSiblingHouseFromPartial: [H.real_name] + [candidate.real_name] → forming sibling house")
		request_mutual_confirmation(H, candidate, CALLBACK(src, PROC_REF(do_form_sibling_house), H, candidate), "sibling_house")
		return

	ftlog("TryFormSiblingHouseFromPartial: [H.real_name] → no mutual sibling found")