/datum/controller/subsystem/familytree/proc/AssignWithDesiredRole(mob/living/carbon/human/H)
	if(!H)
		return

	var/desired = H.desired_relative_role

	switch(desired)
		if(RELATIVE_SIBLING)
			AssignAsSibling(H)
		if(RELATIVE_PARENT)
			AssignAsParent(H)
		if(RELATIVE_CHILD)
			AssignToHouse(H)
		if(RELATIVE_UNCLE_AUNT)
			AssignAuntUncle(H)
		if(RELATIVE_SPOUSE)
			if(H.familytree_pref == FAMILY_NEWLYWED)
				AssignNewlyWed(H)
			else
				AssignToFamily(H)
		else
			AssignToHouse(H)

/datum/controller/subsystem/familytree/proc/AssignAsSibling(mob/living/carbon/human/H)
	if(!H)
		return

	var/our_race = H.dna.species.name
	var/our_isolated = is_isolated(H)

	for(var/datum/heritage/house as anything in families)
		if(!house.housename || !house.members.len)
			continue
		if(!house_race_compatible(house, our_race, our_isolated))
			continue

		for(var/datum/family_member/member as anything in house.members)
			if(!member.person)
				continue
			if(!CanBeSiblings(member.person.age, H.age))
				continue
			if(!familytree_estates_compatible(H, member.person))
				continue
			if(!familytree_role_tiers_compatible(H, member.person))
				continue

			var/datum/family_member/parent1 = member.parents.len > 0 ? member.parents[1] : null
			var/datum/family_member/parent2 = member.parents.len > 1 ? member.parents[2] : null
			house.AddToFamily(H, parent1, parent2, FALSE)
			return

	AssignToHouse(H)

/datum/controller/subsystem/familytree/proc/AssignAsParent(mob/living/carbon/human/H)
	if(!H)
		return

	var/our_race = H.dna.species.name
	var/our_isolated = is_isolated(H)

	for(var/datum/heritage/house as anything in families)
		if(!house.housename || !house.members.len)
			continue
		if(!house_race_compatible(house, our_race, our_isolated))
			continue

		for(var/datum/family_member/member as anything in house.members)
			if(!member.person)
				continue
			if(!CanBeParentOf(H, member.person))
				continue
			if(member.parents.len >= 2)
				continue

			var/datum/family_member/new_member = house.CreateFamilyMember(H)
			if(new_member)
				member.AddParent(new_member)
				return

	var/datum/heritage/empty_house
	for(var/datum/heritage/house as anything in families)
		if(!house.housename && house_race_compatible(house, our_race, our_isolated))
			empty_house = house
			break

	if(empty_house)
		var/datum/family_member/new_member = empty_house.CreateFamilyMember(H)
		if(new_member)
			empty_house.founder = new_member
			new_member.generation = 0
			empty_house.housename = empty_house.SurnameFormatting(H)
