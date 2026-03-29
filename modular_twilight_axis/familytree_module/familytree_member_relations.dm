/datum/family_member/proc/GetRelationshipTo(datum/family_member/other)
	if(!other || other == src)
		return null

	if(other in parents)
		if(adoption_status)
			return "adoptive [other.GetParentTerm()]"
		return other.GetParentTerm()
	if(other in children)
		if(other.adoption_status)
			return "adopted [other.GetChildTerm()]"
		return other.GetChildTerm()
	if(other in spouses)
		return other.GetSpouseTerm()

	if(AreSiblings(other))
		return other.GetSiblingTerm()

	var/grandparent_rel = GetGrandparentRelation(other)
	if(grandparent_rel)
		return grandparent_rel

	var/grandchild_rel = GetGrandchildRelation(other)
	if(grandchild_rel)
		return grandchild_rel

	var/aunt_uncle_rel = GetAuntUncleRelation(other)
	if(aunt_uncle_rel)
		return aunt_uncle_rel

	var/niece_nephew_rel = GetNieceNephewRelation(other)
	if(niece_nephew_rel)
		return niece_nephew_rel

	var/cousin_rel = GetCousinRelation(other)
	if(cousin_rel)
		return cousin_rel

	var/great_rel = GetGreatRelation(other)
	if(great_rel)
		return great_rel

	var/inlaw_rel = GetInLawRelation(other)
	if(inlaw_rel)
		return inlaw_rel

	return "distant relative"

/datum/family_member/proc/GetInLawRelation(datum/family_member/other)
	for(var/datum/family_member/spouse as anything in spouses)
		if(other in spouse.parents)
			return other.GetParentInLawTerm()
		if(other in spouse.children)
			return other.GetChildInLawTerm()
		if(spouse.AreSiblings(other))
			return other.GetSiblingInLawTerm()

		for(var/datum/family_member/spouse_parent as anything in spouse.parents)
			if(other in spouse_parent.parents)
				return other.GetGrandparentInLawTerm()

	for(var/datum/family_member/member as anything in family.members)
		if(AreSiblings(member) && (other in member.spouses))
			return other.GetSiblingInLawTerm()

	for(var/datum/family_member/child as anything in children)
		if(other in child.spouses)
			return other.GetChildInLawTerm()

	return null

/datum/family_member/proc/AreSiblings(datum/family_member/other)
	if(!other || other == src)
		return FALSE
	if(!parents.len || !other.parents.len)
		return FALSE

	for(var/datum/family_member/my_parent as anything in parents)
		if(my_parent in other.parents)
			return TRUE
	return FALSE

/datum/family_member/proc/GetAuntUncleRelation(datum/family_member/other)
	for(var/datum/family_member/parent as anything in parents)
		if(other.AreSiblings(parent) && other != parent)
			return other.GetAuntUncleTerm()
	return null

/datum/family_member/proc/GetNieceNephewRelation(datum/family_member/other)
	for(var/datum/family_member/sibling as anything in family.members)
		if(AreSiblings(sibling) && (sibling != src) && (other in sibling.children))
			return other.GetNieceNephewTerm()
	return null


/datum/family_member/proc/GetGrandparentRelation(datum/family_member/other)
	for(var/datum/family_member/parent as anything in parents)
		if(other in parent.parents)
			return other.GetGrandparentTerm()
	return null

/datum/family_member/proc/GetGrandchildRelation(datum/family_member/other)
	for(var/datum/family_member/child as anything in children)
		if(other in child.children)
			return other.GetGrandchildTerm()
	return null


/datum/family_member/proc/GetCousinRelation(datum/family_member/other)
	for(var/datum/family_member/my_parent as anything in parents)
		for(var/datum/family_member/their_parent as anything in other.parents)
			if(my_parent.AreSiblings(their_parent))
				return "cousin"

	return null


/datum/family_member/proc/GetGreatRelation(datum/family_member/other)
	for(var/datum/family_member/parent as anything in parents)
		for(var/datum/family_member/grandparent as anything in parent.parents)
			if(other in grandparent.parents)
				return other.GetGreatGrandparentTerm()

	for(var/datum/family_member/child as anything in children)
		for(var/datum/family_member/grandchild as anything in child.children)
			if(other in grandchild.children)
				return other.GetGreatGrandchildTerm()

	return null
