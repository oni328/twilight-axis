/*
* The familytree subsystem is supposed to be a way to
* assist RP by setting people up as related roundstart.
* This relation can be based on role (IE king and prince
* being father and son) or random chance.
*
* Updated to work with the new multi-generational heritage system
* Fixed to properly handle string age constants
*/

SUBSYSTEM_DEF(familytree)
	name = "familytree"
	flags = SS_NO_FIRE
	lazy_load = FALSE

	/*
	* The family that kings, queens, and princes
	* are automatically placed into. Has no other
	* real function.
	*/
	var/datum/heritage/ruling_family
	/*
	* The other major houses of Rockhill.
	* Id say think Shrouded Isle families but
	* smaller.
	*/
	var/list/families = list()
	/*
	* Bachalors and Bachalorettes
	*/
	var/list/viable_spouses = list()
	//These jobs are excluded from AddLocal() outside of the dedicated royal path.
	var/list/excluded_jobs = list(
		"Wretch",
		"Bandit",
		"Absolver",
		"Orthodoxist",
		"Inquisitor",
		)
	var/list/nomarry_jobs = list(
		"Nightswain",
		"Churchling",
		"Acolyte",
		"Templar",
		"Martyr",
		"Priest",
		)
	//This creates 2 families for each race roundstart so that siblings dont fail to be added to a family.
	var/list/preset_family_species = list()
	var/list/royal_partner_job_baselines = list()
	var/mob/living/carbon/human/current_royal_partner_owner
	var/current_royal_partner_mode = "closed"
	var/list/current_royal_partner_snapshot = list()

/datum/controller/subsystem/familytree/Initialize()
	ruling_family = new /datum/heritage(null, "Royal", /datum/species/human/northern)
	preset_family_species = build_preset_family_species()
	ensure_royal_partner_job_baselines()
	reset_royal_partner_jobs()
	//Blank starter families that we can customize for players.
	for(var/pioneer_household in preset_family_species)
		for(var/I = 1 to 2)
			var/datum/heritage/family = new /datum/heritage
			family.dominant_race = pioneer_household
			families += family
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))
	for(var/mob/living/carbon/human/H in GLOB.mob_list)
		register_human(H)
	return ..()

/datum/controller/subsystem/familytree/proc/build_preset_family_species() as /list
	. = familytree_module_get_selectable_species_types()

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

/datum/controller/subsystem/familytree/proc/ensure_royal_partner_job_baselines()
	if(royal_partner_job_baselines.len)
		return TRUE

	var/datum/job/consort_job = find_job_by_type(/datum/job/roguetown/lady)
	var/datum/job/suitor_job = find_job_by_type(/datum/job/roguetown/suitor)

	if(consort_job)
		royal_partner_job_baselines["consort"] = list(
			"allowed_races" = islist(consort_job.allowed_races) ? consort_job.allowed_races.Copy() : list(),
			"allowed_sexes" = islist(consort_job.allowed_sexes) ? consort_job.allowed_sexes.Copy() : list(),
			"total_positions" = consort_job.total_positions,
			"spawn_positions" = consort_job.spawn_positions,
		)

	if(suitor_job)
		royal_partner_job_baselines["suitor"] = list(
			"allowed_races" = islist(suitor_job.allowed_races) ? suitor_job.allowed_races.Copy() : list(),
			"allowed_sexes" = islist(suitor_job.allowed_sexes) ? suitor_job.allowed_sexes.Copy() : list(),
			"total_positions" = suitor_job.total_positions,
			"spawn_positions" = suitor_job.spawn_positions,
		)

	return royal_partner_job_baselines.len >= 2

/datum/controller/subsystem/familytree/proc/get_royal_partner_mode_from_preferences(datum/preferences/P)
	if(!P)
		return "closed"

	switch(P.family)
		if(FAMILY_NEWLYWED)
			return "consort"
		if(FAMILY_PARTIAL, FAMILY_FULL)
			return "suitor"

	return "closed"

/datum/controller/subsystem/familytree/proc/get_royal_partner_allowed_races(mob/living/carbon/human/duke, datum/preferences/P, list/default_races) as /list
	var/list/allowed_races = islist(default_races) ? default_races.Copy() : list()
	if(!P)
		return allowed_races

	var/duke_species_type = duke?.client?.prefs?.pref_species?.type
	if(!ispath(duke_species_type, /datum/species))
		duke_species_type = duke?.dna?.species?.type

	switch(P.species_preference_mode)
		if("SAME_TYPE")
			if(ispath(duke_species_type, /datum/species))
				return list(duke_species_type)
		if("SPECIFIC_TYPE")
			var/species_type = P.preferred_species_type
			if(istext(species_type))
				species_type = GLOB.species_list[species_type]
			if(ispath(species_type, /datum/species))
				return list(species_type)

	return allowed_races

/datum/controller/subsystem/familytree/proc/get_royal_partner_allowed_sexes(mob/living/carbon/human/duke, datum/preferences/P, list/default_sexes) as /list
	var/list/allowed_sexes = islist(default_sexes) ? default_sexes.Copy() : list()
	if(!P)
		return allowed_sexes

	var/duke_body_type = duke?.client?.prefs?.gender
	if(duke_body_type != MALE && duke_body_type != FEMALE)
		duke_body_type = duke?.gender

	switch(P.gender_choice_pref)
		if(SAME_GENDER)
			if(duke_body_type == MALE || duke_body_type == FEMALE)
				return list(duke_body_type)
		if(DIFFERENT_GENDER)
			if(duke_body_type == MALE)
				return list(FEMALE)
			if(duke_body_type == FEMALE)
				return list(MALE)

	return allowed_sexes

/datum/controller/subsystem/familytree/proc/apply_royal_partner_job_state(job_key, enabled, open_slots = 0, list/allowed_races, list/allowed_sexes)
	if(!ensure_royal_partner_job_baselines())
		return FALSE

	var/datum/job/job = null
	switch(job_key)
		if("consort")
			job = find_job_by_type(/datum/job/roguetown/lady)
		if("suitor")
			job = find_job_by_type(/datum/job/roguetown/suitor)

	var/list/baseline = royal_partner_job_baselines[job_key]
	if(!job || !baseline)
		return FALSE

	var/list/baseline_allowed_races = baseline["allowed_races"]
	var/list/baseline_allowed_sexes = baseline["allowed_sexes"]
	job.allowed_races = islist(baseline_allowed_races) ? baseline_allowed_races.Copy() : list()
	job.allowed_sexes = islist(baseline_allowed_sexes) ? baseline_allowed_sexes.Copy() : list()
	job.total_positions = baseline["total_positions"]
	job.spawn_positions = baseline["spawn_positions"]

	if(enabled)
		job.allowed_races = islist(allowed_races) ? allowed_races.Copy() : list()
		job.allowed_sexes = islist(allowed_sexes) ? allowed_sexes.Copy() : list()
		job.total_positions = open_slots
		job.spawn_positions = open_slots
	else
		job.total_positions = 0
		job.spawn_positions = 0

	return TRUE

/datum/controller/subsystem/familytree/proc/reset_royal_partner_jobs()
	current_royal_partner_owner = null
	current_royal_partner_mode = "closed"
	current_royal_partner_snapshot = list()

	apply_royal_partner_job_state("consort", FALSE)
	apply_royal_partner_job_state("suitor", FALSE)

/datum/controller/subsystem/familytree/proc/refresh_royal_partner_jobs(mob/living/carbon/human/duke, datum/preferences/P)
	if(!duke?.client)
		return FALSE

	if(!ensure_royal_partner_job_baselines())
		return FALSE

	if(!P)
		P = duke.client.prefs
	if(!P)
		return FALSE

	if(current_royal_partner_owner == duke && current_royal_partner_snapshot.len)
		return TRUE

	if(current_royal_partner_owner && current_royal_partner_owner != duke)
		return FALSE

	P.familytree_module_load_character()

	var/mode = get_royal_partner_mode_from_preferences(P)
	var/list/consort_baseline = royal_partner_job_baselines["consort"]
	var/list/suitor_baseline = royal_partner_job_baselines["suitor"]
	if(!consort_baseline || !suitor_baseline)
		return FALSE

	var/list/consort_allowed_races = get_royal_partner_allowed_races(duke, P, consort_baseline["allowed_races"])
	var/list/consort_allowed_sexes = get_royal_partner_allowed_sexes(duke, P, consort_baseline["allowed_sexes"])
	var/list/suitor_allowed_races = get_royal_partner_allowed_races(duke, P, suitor_baseline["allowed_races"])
	var/list/suitor_allowed_sexes = get_royal_partner_allowed_sexes(duke, P, suitor_baseline["allowed_sexes"])

	switch(mode)
		if("consort")
			apply_royal_partner_job_state("consort", TRUE, 1, consort_allowed_races, consort_allowed_sexes)
			apply_royal_partner_job_state("suitor", FALSE)
		if("suitor")
			apply_royal_partner_job_state("consort", FALSE)
			apply_royal_partner_job_state("suitor", TRUE, 2, suitor_allowed_races, suitor_allowed_sexes)
		else
			apply_royal_partner_job_state("consort", FALSE)
			apply_royal_partner_job_state("suitor", FALSE)

	current_royal_partner_owner = duke
	current_royal_partner_mode = mode
	current_royal_partner_snapshot = list(
		"family" = P.family,
		"duke_gender" = duke.client?.prefs?.gender,
		"duke_pronouns" = duke.client?.prefs?.pronouns,
		"duke_species_type" = duke.client?.prefs?.pref_species?.type,
		"gender_choice_pref" = P.gender_choice_pref,
		"species_preference_mode" = P.species_preference_mode,
		"preferred_species_type" = P.preferred_species_type,
		"preferred_species_anatomy" = P.preferred_species_anatomy,
		"setspouse" = P.setspouse,
	)
	return TRUE

/datum/controller/subsystem/familytree/proc/get_royal_partner_job_key(role_or_job)
	var/datum/job/job = resolve_job_datum(role_or_job)
	if(is_royal_consort_job(job))
		return "consort"
	if(is_royal_suitor_job(job))
		return "suitor"
	return null

/datum/controller/subsystem/familytree/proc/royal_partner_species_match(datum/preferences/P)
	if(!P)
		return FALSE

	var/species_type = P.pref_species?.type
	if(!ispath(species_type, /datum/species))
		return FALSE

	var/preference_mode = current_royal_partner_snapshot["species_preference_mode"]
	var/preferred_species_type = current_royal_partner_snapshot["preferred_species_type"]
	var/duke_species_type = current_royal_partner_snapshot["duke_species_type"]

	if(istext(preferred_species_type))
		preferred_species_type = GLOB.species_list[preferred_species_type]

	switch(preference_mode)
		if("SAME_TYPE")
			return species_type == duke_species_type
		if("SPECIFIC_TYPE")
			return species_type == preferred_species_type

	return TRUE

/datum/controller/subsystem/familytree/proc/royal_partner_gender_match(datum/preferences/P)
	if(!P)
		return FALSE

	var/gender_pref = current_royal_partner_snapshot["gender_choice_pref"]
	if(!gender_pref || gender_pref == ANY_GENDER)
		return TRUE

	var/duke_pronouns = current_royal_partner_snapshot["duke_pronouns"]
	var/candidate_pronouns = P.pronouns
	if(!isnull(duke_pronouns) && !isnull(candidate_pronouns))
		if(gender_pref == SAME_GENDER)
			return duke_pronouns == candidate_pronouns
		if(gender_pref == DIFFERENT_GENDER)
			return duke_pronouns != candidate_pronouns

	var/duke_gender = current_royal_partner_snapshot["duke_gender"]
	var/candidate_gender = P.gender
	if(gender_pref == SAME_GENDER)
		return duke_gender == candidate_gender
	if(gender_pref == DIFFERENT_GENDER)
		return duke_gender != candidate_gender

	return TRUE

/datum/controller/subsystem/familytree/proc/royal_partner_anatomy_match(datum/preferences/P)
	if(!P)
		return FALSE

	var/anatomy_pref = current_royal_partner_snapshot["preferred_species_anatomy"]
	switch(anatomy_pref)
		if(0)
			return TRUE
		if(1)
			return P.familytree_module_has_penis()
		if(2)
			return P.familytree_module_has_vagina()

	return TRUE

/datum/controller/subsystem/familytree/proc/royal_partner_name_match(datum/preferences/P)
	if(!P)
		return FALSE

	var/required_name = current_royal_partner_snapshot["setspouse"]
	if(!istext(required_name) || !length(required_name))
		return TRUE

	return P.real_name == required_name

/datum/controller/subsystem/familytree/proc/royal_partner_candidate_allowed(client/C, role_or_job)
	if(!C?.prefs || !current_royal_partner_owner || !current_royal_partner_snapshot.len)
		return FALSE

	var/job_key = get_royal_partner_job_key(role_or_job)
	if(!job_key || current_royal_partner_mode != job_key)
		return FALSE

	var/datum/preferences/P = C.prefs
	if(!royal_partner_species_match(P))
		return FALSE
	if(!royal_partner_gender_match(P))
		return FALSE
	if(!royal_partner_anatomy_match(P))
		return FALSE
	if(job_key == "consort" && !royal_partner_name_match(P))
		return FALSE

	return TRUE

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

/datum/controller/subsystem/familytree/proc/is_familytree_antagonist(mob/living/carbon/human/H)
	var/datum/mind/mind = H?.mind
	if(!mind)
		return FALSE
	if(mind.special_role)
		return TRUE
	return !!mind.has_antag_datum(/datum/antagonist)

/datum/controller/subsystem/familytree/proc/ignore_familytree_antagonist(mob/living/carbon/human/H)
	if(!H)
		return
	viable_spouses -= H
	H.familytree_assignment_scheduled = FALSE
	stop_tracking_human(H)

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

/datum/controller/subsystem/familytree/proc/on_mob_created(datum/controller/subsystem/processing/dcs/source, mob/new_mob)
	SIGNAL_HANDLER
	if(!ishuman(new_mob) || QDELETED(new_mob) || istype(new_mob, /mob/living/carbon/human/dummy))
		return
	var/mob/living/carbon/human/H = new_mob
	register_human(H)
	try_queue_assignment(H)

/datum/controller/subsystem/familytree/proc/register_human(mob/living/carbon/human/H)
	if(!H || istype(H, /mob/living/carbon/human/dummy) || H.familytree_module_signal_bound)
		return
	H.familytree_module_signal_bound = TRUE
	RegisterSignal(H, COMSIG_MOB_LOGIN, PROC_REF(on_human_login))
	RegisterSignal(H, COMSIG_JOB_RECEIVED, PROC_REF(on_human_job_received))

/datum/controller/subsystem/familytree/proc/stop_tracking_human(mob/living/carbon/human/H)
	if(!H || !H.familytree_module_signal_bound)
		return
	H.familytree_module_signal_bound = FALSE
	UnregisterSignal(H, list(COMSIG_MOB_LOGIN, COMSIG_JOB_RECEIVED))

/datum/controller/subsystem/familytree/proc/on_human_login(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	try_queue_assignment(H)

/datum/controller/subsystem/familytree/proc/on_human_job_received(mob/living/carbon/human/H, rank)
	SIGNAL_HANDLER
	try_queue_assignment(H)

/datum/controller/subsystem/familytree/proc/try_queue_assignment(mob/living/carbon/human/H)
	if(!H || QDELETED(H) || istype(H, /mob/living/carbon/human/dummy))
		return
	if(is_familytree_antagonist(H))
		ignore_familytree_antagonist(H)
		return

	var/datum/job/job = get_familytree_job(H)
	var/datum/preferences/P = H.client?.prefs
	if(P && is_royal_monarch_job(job) && !current_royal_partner_owner)
		P.familytree_module_load_character()
		refresh_royal_partner_jobs(H, P)

	if(H.familytree_assignment_scheduled || H.family_datum)
		if(H?.family_datum)
			stop_tracking_human(H)
		return

	if(!P)
		return

	P.familytree_module_load_character()
	H.familytree_pref = P.family
	H.gender_choice_pref = P.gender_choice_pref
	H.setspouse = P.setspouse

	if(is_royal_suitor_job(job))
		stop_tracking_human(H)
		return

	var/royal_status = get_royal_status(H)
	if(royal_status)
		H.familytree_assignment_scheduled = TRUE
		stop_tracking_human(H)
		addtimer(CALLBACK(src, PROC_REF(run_royal_assignment), H, royal_status), get_royal_delay(H) SECONDS)
		return

	if(H.familytree_pref != FAMILY_NONE)
		H.familytree_assignment_scheduled = TRUE
		stop_tracking_human(H)
		var/timer = rand(1, 30) + 10
		addtimer(CALLBACK(src, PROC_REF(run_local_assignment), H, H.familytree_pref), timer SECONDS)
		return

	if(H.client && (H.mind?.assigned_role || H.job))
		stop_tracking_human(H)

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

/datum/controller/subsystem/familytree/proc/run_local_assignment(mob/living/carbon/human/H, status)
	if(!H || QDELETED(H) || H.family_datum || is_familytree_antagonist(H))
		return
	AddLocal(H, status)

/datum/controller/subsystem/familytree/proc/run_royal_assignment(mob/living/carbon/human/H, status)
	if(!H || QDELETED(H) || H.family_datum || is_familytree_antagonist(H))
		return
	AddRoyal(H, status)

/datum/controller/subsystem/familytree/proc/GetAgeValue(age_string)
	// Convert age string to numeric value for comparison
	switch(age_string)
		if(AGE_ADULT)
			return 1
		if(AGE_MIDDLEAGED)
			return 2
		if(AGE_OLD)
			return 3
		else
			return 1 // Default to adult

/datum/controller/subsystem/familytree/proc/WouldCreateAgeConflict(datum/heritage/house, mob/living/carbon/human/person)
	if(!house.members.len)
		return FALSE
	// Check against existing family members for age conflicts
	for(var/datum/family_member/member as anything in house.members)
		if(!member.person)
			continue

		// Check if person is too young to be parent of existing children
		for(var/datum/family_member/child as anything in member.children)
			if(child.person && !CanBeParentOf(person, child.person))
				return TRUE

		// Check if person is too old to be child of existing parents
		for(var/datum/family_member/parent as anything in member.parents)
			if(parent.person && !CanBeParentOf(parent.person, person))
				return TRUE

	return FALSE

/datum/controller/subsystem/familytree/proc/CanBeParentOf(mob/living/carbon/human/parent, mob/living/carbon/human/child)
	var/parent_age = parent.age
	var/child_age = child.age
	if(!child.setspouse || child.setspouse == parent.real_name)
		if(parent_age == AGE_ADULT)
			return FALSE
		if(parent_age == AGE_MIDDLEAGED && child_age == AGE_ADULT)
			return TRUE
		if(parent_age == AGE_OLD && child_age != AGE_OLD)
			return TRUE

	return FALSE

/datum/controller/subsystem/familytree/proc/CanBeSiblings(age1, age2)
	// Siblings can be same age category or adjacent categories
	if(age1 == age2)
		return TRUE

	var/age1_value = GetAgeValue(age1)
	var/age2_value = GetAgeValue(age2)

	// Allow siblings to be within 1 age category of each other
	if(abs(age1_value - age2_value) <= 1)
		return TRUE

	return FALSE

/datum/controller/subsystem/familytree/proc/DetermineAppropriateRole(datum/heritage/house, mob/living/carbon/human/person, adopted = FALSE)
	// Look for potential parents (older members who could be parents)
	var/list/potential_parents = list()
	for(var/datum/family_member/member as anything in house.members)
		if(member.person && CanBeParentOf(member.person, person))
			potential_parents += member

	// If we have potential parents, make this person a child
	if(potential_parents.len)
		return "child"

	// Look for potential siblings (similar age)
	for(var/datum/family_member/member as anything in house.members)
		if(member.person && CanBeSiblings(member.person.age, person.age))
			return "sibling"

	// Default to founder/parent role
	return "parent"

/datum/controller/subsystem/familytree/proc/AddLocal(mob/living/carbon/human/H, status)
	if(!H || !status || istype(H, /mob/living/carbon/human/dummy))
		return
	if(is_familytree_antagonist(H))
		ignore_familytree_antagonist(H)
		return
	// Royals are handled by the dedicated royal flow.
	if(get_royal_status(H))
		return
	if(is_royal_suitor_job(get_familytree_job(H)))
		return
	if(is_human_job_in_list(H, excluded_jobs))
		return
	if(is_human_job_in_list(H, nomarry_jobs))
		if(status != FAMILY_NONE)
			AssignToHouse(H)
			return
	switch(status)
		if(FAMILY_PARTIAL)
			AssignToHouse(H)

		if(FAMILY_NEWLYWED)
			AssignNewlyWed(H)

		if(FAMILY_FULL)
			if(H.virginity)
				return
			AssignToFamily(H)

/datum/controller/subsystem/familytree/proc/AddRoyal(mob/living/carbon/human/H, status)
	if(!H || is_familytree_antagonist(H))
		ignore_familytree_antagonist(H)
		return
	if(!ruling_family.housename)
		ruling_family.housename = " Royal"
	var/datum/family_member/member = ruling_family.CreateFamilyMember(H)
	if(!member)
		return

	// If this is the first royal, generate a historical lineage
	if(!ruling_family.founder)
		GenerateRoyalLineage(member, status)
		H.ShowFamilyUI(TRUE)
		return

	// Handle adding new royals to existing family
	switch(status)
		if(FAMILY_FATHER, FAMILY_MOTHER)
			// If there's already a monarch, make them spouses
			var/datum/family_member/existing_monarch = GetCurrentMonarch()
			member.generation = 12
			if(existing_monarch)
				ruling_family.MarryMembers(existing_monarch, member)

		if(FAMILY_PROGENY)  // Prince/Princess
			// Children of the current monarch
			var/datum/family_member/monarch = GetCurrentMonarch()
			if(monarch)
				member.generation = monarch.generation + 1
				member.AddParent(monarch)
				// Add other parent if monarch has spouse
				if(monarch.spouses.len)
					member.AddParent(monarch.spouses[1])

		if(FAMILY_OMMER)  // Hand - sibling or cousin of monarch
			CreateBranchFamily(member)

	H.ShowFamilyUI(TRUE)

/datum/controller/subsystem/familytree/proc/GetCurrentMonarch()
	// Find the monarch at generation 12 (current ruling generation)
	for(var/datum/family_member/member as anything in ruling_family.members)
		if(member.generation == 12 && is_royal_monarch_job(get_familytree_job(member.person)))
			return member
	return null

/datum/controller/subsystem/familytree/proc/CreateBranchFamily(datum/family_member/hand_member)
	var/datum/family_member/monarch = GetCurrentMonarch()
	if(!monarch)
		return

	hand_member.generation = monarch.generation

	// Make the hand a sibling of the monarch (so uncle/aunt to any princes/princesses)
	if(monarch.parents.len)
		var/datum/family_member/monarch_parent = monarch.parents[1]
		var/datum/family_member/monarch_parent_second = monarch.parents[2]
		if(monarch_parent)
			hand_member.AddParent(monarch_parent)
		if(monarch_parent_second)
			hand_member.AddParent(monarch_parent_second)

		// Create a spouse for the hand
		var/mob/living/carbon/human/dummy/spouse = new()
		spouse.age = hand_member.person.age
		if(hand_member.person.titles_pref == TITLES_F)
			spouse.gender = MALE
		else if(hand_member.person.titles_pref == TITLES_M)
			spouse.gender = FEMALE
		else
			spouse.gender = hand_member.person.pronouns == HE_HIM ? FEMALE : MALE
		spouse.real_name = GenerateRoyalName(spouse.gender, hand_member.generation)
		var/datum/family_member/hand_spouse = ruling_family.CreateFamilyMember(spouse)
		hand_spouse.generation = hand_member.generation
		ruling_family.MarryMembers(hand_member, hand_spouse)

/datum/controller/subsystem/familytree/proc/GenerateRoyalLineage(datum/family_member/current_royal, status)
	if(!current_royal?.person)
		return

	// Set as current generation
	ruling_family.founder = current_royal
	current_royal.generation = 12  // Start at generation 12 to leave room for ancestors

	// Update ruling family's species based on first member
	ruling_family.dominant_species = current_royal.person.dna.species.type

	// Generate ancestors
	var/datum/family_member/current_ancestor = current_royal
	var/list/age_progression = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_OLD)

	for(var/i = current_royal.generation - 1; i >= 6; i--)  // Generate 6 generations of ancestors
		// Create parent
		var/mob/living/carbon/human/dummy/ancestor = new()
		ancestor.age = age_progression[min(current_royal.generation - i, age_progression.len)]
		ancestor.gender = prob(50) ? MALE : FEMALE
		ancestor.real_name = GenerateRoyalName(ancestor.gender, i)
		set_species_type(ancestor, ruling_family.dominant_species)
		var/datum/family_member/parent = ruling_family.CreateFamilyMember(ancestor)
		parent.generation = i

		// Create spouse for parent
		var/mob/living/carbon/human/dummy/spouse = new()
		spouse.age = ancestor.age
		spouse.gender = ancestor.gender == MALE ? FEMALE : MALE
		spouse.real_name = GenerateRoyalName(spouse.gender, i)
		set_species_type(spouse, ruling_family.dominant_species)
		var/datum/family_member/parent_spouse = ruling_family.CreateFamilyMember(spouse)
		parent_spouse.generation = i

		// Connect family members
		ruling_family.MarryMembers(parent, parent_spouse)
		current_ancestor.AddParent(parent)
		current_ancestor.AddParent(parent_spouse)

		// Add 0-1 siblings with 30% chance (for branch families later)
		if(prob(30))
			var/mob/living/carbon/human/dummy/sibling = new()
			sibling.age = ancestor.age
			sibling.gender = prob(50) ? MALE : FEMALE
			sibling.real_name = GenerateRoyalName(sibling.gender, i + 1)
			set_species_type(sibling, ruling_family.dominant_species)
			var/datum/family_member/sibling_member = ruling_family.CreateFamilyMember(sibling)
			sibling_member.generation = i + 1
			sibling_member.AddParent(parent)
			sibling_member.AddParent(parent_spouse)

		current_ancestor = parent

/datum/controller/subsystem/familytree/proc/set_species_type(mob/living/carbon/human/H, species_type)
	if(!H || !species_type)
		return

	var/datum/species/S = new species_type
	H.set_species(S)
	H.dna.species = S

/datum/controller/subsystem/familytree/proc/GenerateRoyalName(gender, generation)
	var/list/male_names = list(
		"King" = list("Otto", "Arnulf", "Ludwig", "Henri", "Louis", "Francois"),
		"Prince" = list("Karl", "Konrad", "Heinrich", "Raoul", "Hugues")
	)
	var/list/female_names = list(
		"Queen" = list("Hildegard", "Freya", "Helga", "Jeanne", "Adeline"),
		"Princess" = list("Karoline", "Hedwig", "Anneliese", "Elise")
	)

	var/title
	var/list/names
	if(gender == MALE)
		title = generation > 2 ? "King" : "Prince"
		names = male_names[title]
	else
		title = generation > 2 ? "Queen" : "Princess"
		names = female_names[title]

	var/list/roman_numerals = list("I", "II", "III", "IV", "V")
	return "[title] [pick(names)] [pick(roman_numerals)]"

/datum/controller/subsystem/familytree/proc/AssignToHouse(mob/living/carbon/human/H)
	if(!H)
		return

	var/our_race = H.dna.species.name
	var/adopted = FALSE
	var/datum/heritage/chosen_house
	var/list/low_priority_houses = list()
	var/list/high_priority_houses = list()

	if(H.setspouse)
		for(var/datum/heritage/house as anything in families)
			for(var/datum/family_member/M as anything in house.members)
				if(M.person && M.person.real_name == H.setspouse)
					if(!SpeciesCompatible(H, M.person))
						continue
					chosen_house = house

	// Prioritize houses with existing members but not too many
	for(var/datum/heritage/house as anything in families)
		if(house.housename && house.members.len >= 1 && house.members.len < 6)
			high_priority_houses += house
		else
			low_priority_houses += house

	// Try high priority houses first
	if(!chosen_house)
		for(var/datum/heritage/house as anything in high_priority_houses)
			if(house.dominant_race.name == our_race && house.members.len < 4)
				if(!WouldCreateAgeConflict(house, H))
					chosen_house = house
					break
		// Small chance for adoption into different species family
			if(prob(20) && house.members.len <= 8)
				if(!WouldCreateAgeConflict(house, H))
					chosen_house = house
					adopted = TRUE
					break

	// Try low priority houses if no high priority match
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
			// Find suitable parents
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
			// Find a sibling and share their parents
			for(var/datum/family_member/member as anything in house.members)
				if(member.person && CanBeSiblings(member.person.age, person.age))
					var/datum/family_member/parent1 = member.parents.len > 0 ? member.parents[1] : null
					var/datum/family_member/parent2 = member.parents.len > 1 ? member.parents[2] : null
					house.AddToFamily(person, parent1, parent2, adopted)
					break

		if("parent")
			// Add as founder/parent
			var/datum/family_member/new_member = house.CreateFamilyMember(person)
			if(!house.founder)
				house.founder = new_member
				new_member.generation = 0
			if(!house.housename)
				house.housename = house.SurnameFormatting(person)


/// Human Helper proc to check gender choice based on pronouns

/mob/living/carbon/human/proc/pronouns_match(mob/living/carbon/human/H, mob/living/carbon/human/other)
	if(!H.gender_choice_pref)
		H.gender_choice_pref = ANY_GENDER
	if(!other.gender_choice_pref)
		other.gender_choice_pref = ANY_GENDER
	var/our_gender = H.pronouns
	var/other_gender = other.pronouns
	if(H.gender_choice_pref == ANY_GENDER && other.gender_choice_pref == ANY_GENDER)
		return TRUE
	if(H.gender_choice_pref == ANY_GENDER)
		if(other.gender_choice_pref == SAME_GENDER)
			return our_gender == other_gender
		if(other.gender_choice_pref == DIFFERENT_GENDER)
			return our_gender != other_gender
		return TRUE
	if(other.gender_choice_pref == ANY_GENDER)
		if(H.gender_choice_pref == SAME_GENDER)
			return our_gender == other_gender
		if(H.gender_choice_pref == DIFFERENT_GENDER)
			return our_gender != other_gender
		return TRUE
	if(H.gender_choice_pref == SAME_GENDER)
		return our_gender == other_gender
	if(H.gender_choice_pref == DIFFERENT_GENDER)
		return our_gender != other_gender

	return FALSE
/datum/controller/subsystem/familytree/proc/AssignToFamily(mob/living/carbon/human/H)
	if(!H)
		return
	var/our_race = H.dna.species.name
	var/list/eligible_houses = list()

	// Find houses that need a spouse
	for(var/datum/heritage/house as anything in families)
		if(house.dominant_race.name != our_race)
			continue

		// Check if there's a potential spouse
		var/has_single_adult = FALSE
		for(var/datum/family_member/member as anything in house.members)
			if(member.person && !member.spouses.len)
				// Check setspouse compatibility
				if(H.setspouse && member.person.real_name == H.setspouse)
					eligible_houses.Insert(1, house) // High priority
					has_single_adult = TRUE
					break
				else if(!H.setspouse)

					if(!member.person.setspouse || member.person.setspouse == H.real_name)
						var/ok_gender_H = H.pronouns_match(H, member.person)
						var/ok_gender_M = member.person.pronouns_match(member.person, H)
						if(!ok_gender_H || !ok_gender_M)
							continue
						if(!SpeciesCompatible(H, member.person))
							continue
						if(member.person.familytree_pref == FAMILY_PARTIAL)
							continue
						if(is_human_job_in_list(member.person, nomarry_jobs))
							continue


		if(!has_single_adult && !house.housename)
			eligible_houses += house // Empty house for founding

	// Try to assign to a house
	for(var/datum/heritage/house as anything in eligible_houses)
		// Find a spouse
		for(var/datum/family_member/member as anything in house.members)
			if(member.person && !member.spouses.len)
				// Check compatibility
				var/compatible = FALSE
				if(H.setspouse && member.person.real_name == H.setspouse)
					compatible = TRUE
				else if(!H.setspouse)
					if(!member.person.setspouse || member.person.setspouse == H.real_name)
						// Pronouns matching according to Gender Preference
						var/ok_gender_H = H.pronouns_match(H, member.person)
						var/ok_gender_M = member.person.pronouns_match(member.person, H)

						if(ok_gender_H && ok_gender_M)
							compatible = TRUE

				if(compatible)
					var/datum/family_member/new_member = house.CreateFamilyMember(H)
					if(new_member)
						house.MarryMembers(new_member, member)
						return

		// Or found a new house
		if(!house.housename)
			var/datum/family_member/new_member = house.CreateFamilyMember(H)
			if(new_member)
				house.founder = new_member
				new_member.generation = 0
				house.housename = house.SurnameFormatting(H)
				return


/datum/controller/subsystem/familytree/proc/AssignNewlyWed(mob/living/carbon/human/H)
	if(!H || is_familytree_antagonist(H))
		ignore_familytree_antagonist(H)
		return
	viable_spouses += H
	var/list/potential_matches = list()

	for(var/mob/living/carbon/human/potential_spouse as anything in viable_spouses)
		if(!potential_spouse || potential_spouse == H || potential_spouse.spouse_mob)
			continue
		if(is_familytree_antagonist(potential_spouse))
			viable_spouses -= potential_spouse
			continue
		// Check if they are mutually setspouse
		var/mutual_setspouse = (H.setspouse == potential_spouse.real_name) && (potential_spouse.setspouse == H.real_name)
		if(!mutual_setspouse)
			if(!H.pronouns_match(H, potential_spouse) || !potential_spouse.pronouns_match(potential_spouse, H))
				continue // skip if gender preferences incompatible
			if(!SpeciesCompatible(H, potential_spouse))
				continue
		// Check setspouse compatibility
		var/priority = 0
		if(mutual_setspouse)
			priority = 3 // Perfect match
		else if(potential_spouse.setspouse == H.real_name)
			priority = 1 // Decent match
		else if(!H.setspouse && !potential_spouse.setspouse)
			priority = 0 // Random match
		else
			continue // Incompatible

		potential_matches += list(list(potential_spouse, priority))

	// Sort by priority and pick best match
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

	// Find houses with established families that could use an aunt/uncle
	for(var/datum/heritage/house as anything in families)
		if(house.dominant_race.name != base_species)
			continue
		if(!house.housename || house.members.len < 2)
			continue

		// Check if there are children who could use an aunt/uncle
		var/has_children = FALSE
		for(var/datum/family_member/member as anything in house.members)
			if(member.children.len > 0)
				has_children = TRUE
				break

		if(has_children && !WouldCreateAgeConflict(house, H))
			chosen_house = house
			break

	if(chosen_house)
		// Add as sibling to one of the parents
		var/datum/family_member/new_member = chosen_house.CreateFamilyMember(H)
		if(new_member)
			// Find a parent to be sibling to
			for(var/datum/family_member/member as anything in chosen_house.members)
				if(member.children.len > 0 && CanBeSiblings(H.age, member.person.age))
					// Share the same parents as this member
					for(var/datum/family_member/grandparent as anything in member.parents)
						new_member.AddParent(grandparent)
					break

/datum/controller/subsystem/familytree/proc/ValidateAllFamilies()
	if(ruling_family && ruling_family.members.len)
		ValidateFamily(ruling_family)
	for(var/datum/heritage/family as anything in families)
		if(family.members.len)
			ValidateFamily(family)

/datum/controller/subsystem/familytree/proc/ValidateFamily(datum/heritage/family)
	// Clean up any broken references
	for(var/datum/family_member/member as anything in family.members)
		if(!member.person)
			family.members -= member
			continue

		// Validate parent relationships
		for(var/datum/family_member/parent as anything in member.parents)
			if(!parent.person || !(member in parent.children))
				member.parents -= parent
				if(parent.person)
					parent.children -= member

		// Validate child relationships
		for(var/datum/family_member/child as anything in member.children)
			if(!child.person || !(member in child.parents))
				member.children -= child
				if(child.person)
					child.parents -= member

/datum/controller/subsystem/familytree/proc/SpeciesCompatible(mob/living/carbon/human/A, mob/living/carbon/human/B)
	if(!A || !B)
		return FALSE

	var/datum/preferences/PA = A.client?.prefs
	var/datum/preferences/PB = B.client?.prefs

	var/typeA = A.dna.species.type
	var/typeB = B.dna.species.type
	var/type_pref_a = PA?.preferred_species_type
	var/type_pref_b = PB?.preferred_species_type

	if(istext(type_pref_a))
		type_pref_a = GLOB.species_list[type_pref_a]
	if(istext(type_pref_b))
		type_pref_b = GLOB.species_list[type_pref_b]


	if(PA)
		switch(PA.species_preference_mode)
			if("ANY")
			if("SAME_TYPE")
				if(typeA != typeB)
					return FALSE
			if("SPECIFIC_TYPE")
				if(typeB != type_pref_a)
					return FALSE

	if(PB)
		switch(PB.species_preference_mode)
			if("ANY")
			if("SAME_TYPE")
				if(typeA != typeB)
					return FALSE
			if("SPECIFIC_TYPE")
				if(typeA != type_pref_b)
					return FALSE

	if(PA)
		if(!AnatomyCompatible(PA.preferred_species_anatomy, B))
			return FALSE

	if(PB)
		if(!AnatomyCompatible(PB.preferred_species_anatomy, A))
			return FALSE

	return TRUE

/datum/controller/subsystem/familytree/proc/AnatomyCompatible(pref, mob/living/carbon/human/target)
	switch(pref)
		if(0)
			return TRUE
		if(1) // man
			return target.getorganslot(ORGAN_SLOT_PENIS) != null
		if(2) // wo-man
			return target.getorganslot(ORGAN_SLOT_VAGINA) != null
	return TRUE
