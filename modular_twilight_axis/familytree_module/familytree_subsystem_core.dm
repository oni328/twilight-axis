SUBSYSTEM_DEF(familytree)
	name = "familytree"
	flags = SS_NO_FIRE
	lazy_load = FALSE

	var/datum/heritage/ruling_family
	var/list/families = list()
	var/list/viable_spouses = list()
	var/list/banned_species_types = list(
		/datum/species/goblinp,
		/datum/species/gnoll,
		/datum/species/construct,
		)
	var/list/banned_antag_types = list(
		/datum/antagonist/zombie,
		/datum/antagonist/skeleton,
		/datum/antagonist/lich,
		/datum/antagonist/werewolf,
		/datum/antagonist/unbound_death_knight,
		)
	var/list/preset_family_species = list()
	var/list/royal_partner_job_baselines = list()
	var/mob/living/carbon/human/current_royal_partner_owner
	var/current_royal_partner_mode = "closed"
	var/list/current_royal_partner_snapshot = list()

	var/list/intimacy_pairs = list()
	var/xylix_roulette_active = FALSE

/datum/controller/subsystem/familytree/Initialize()
	ruling_family = new /datum/heritage(null, "Royal", /datum/species/human/northern)
	preset_family_species = build_preset_family_species()
	ensure_royal_partner_job_baselines()
	reset_royal_partner_jobs()
	for(var/pioneer_household in preset_family_species)
		for(var/I = 1 to 2)
			var/datum/heritage/family = new /datum/heritage
			family.dominant_race = pioneer_household
			families += family
	check_xylix_roulette()
	load_enigma_roles()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))
	for(var/mob/living/carbon/human/H in GLOB.mob_list)
		register_human(H)
	return ..()

/datum/controller/subsystem/familytree/proc/build_preset_family_species() as /list
	. = familytree_module_get_selectable_species_types()

/datum/controller/subsystem/familytree/proc/check_xylix_roulette()
	var/datum/storyteller/current = SSgamemode?.current_storyteller
	if(!current)
		return FALSE
	if(!istype(current, /datum/storyteller/xylix))
		return FALSE
	xylix_roulette_active = TRUE
	return TRUE

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
	RegisterSignal(H, COMSIG_MOB_LOGOUT, PROC_REF(on_human_logout))
	RegisterSignal(H, COMSIG_MOB_DEATH, PROC_REF(on_human_death))
	RegisterSignal(H, COMSIG_LIVING_REVIVE, PROC_REF(on_human_revive))
	RegisterSignal(H, COMSIG_JOB_RECEIVED, PROC_REF(on_human_job_received))
	RegisterSignal(H, COMSIG_SEX_CLIMAX, PROC_REF(on_human_climax))

/datum/controller/subsystem/familytree/proc/stop_tracking_human(mob/living/carbon/human/H, reason = "unspecified")
	if(!H || !H.familytree_module_signal_bound)
		return
	H.familytree_module_signal_bound = FALSE
	UnregisterSignal(H, list(COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT, COMSIG_MOB_DEATH, COMSIG_LIVING_REVIVE, COMSIG_JOB_RECEIVED, COMSIG_SEX_CLIMAX))

/datum/controller/subsystem/familytree/proc/on_human_login(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	try_queue_assignment(H)

/datum/controller/subsystem/familytree/proc/on_human_logout(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if(H)
		viable_spouses -= H

/datum/controller/subsystem/familytree/proc/on_human_death(mob/living/carbon/human/H, gibbed)
	SIGNAL_HANDLER
	pause_familytree_human(H, "death")

/datum/controller/subsystem/familytree/proc/on_human_revive(mob/living/carbon/human/H, full_heal, admin_revive)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(run_revive_recheck), H, full_heal, admin_revive, 1), 2)

/datum/controller/subsystem/familytree/proc/run_revive_recheck(mob/living/carbon/human/H, full_heal, admin_revive, attempt)
	if(!H || QDELETED(H))
		return
	var/block_reason = get_familytree_runtime_block_reason(H, TRUE)
	if(block_reason == "dead")
		if(attempt < 5)
			addtimer(CALLBACK(src, PROC_REF(run_revive_recheck), H, full_heal, admin_revive, attempt + 1), 2)
		return
	try_queue_assignment(H)

/datum/controller/subsystem/familytree/proc/on_human_job_received(mob/living/carbon/human/H, rank)
	SIGNAL_HANDLER
	try_queue_assignment(H)

/datum/controller/subsystem/familytree/proc/on_human_climax(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	on_intimacy_event(H)

/datum/controller/subsystem/familytree/proc/try_queue_assignment(mob/living/carbon/human/H)
	if(!H || QDELETED(H) || istype(H, /mob/living/carbon/human/dummy))
		return
	var/unsubscribe_reason = get_familytree_unsubscribe_reason(H)
	if(unsubscribe_reason)
		unsubscribe_familytree_human(H, unsubscribe_reason)
		return
	if(H.stat == DEAD)
		return
	if(!H.client)
		return

	var/datum/job/job = get_familytree_job(H)
	var/datum/preferences/P = H.client?.prefs
	if(P && is_royal_monarch_job(job) && !current_royal_partner_owner)
		P.familytree_module_load_character()
		refresh_royal_partner_jobs(H, P)

	if(H.family_datum)
		stop_tracking_human(H, "family already assigned")
		return

	if(H.familytree_assignment_scheduled)
		return

	if(H in viable_spouses)
		return

	if(!P)
		return

	P.familytree_module_load_character()
	H.familytree_pref = P.family
	H.gender_choice_pref = P.gender_choice_pref
	H.setspouse = P.setspouse
	H.polygamy_mode = P.polygamy_mode
	H.desired_relative_role = P.desired_relative_role
	H.allow_low_status_marriage = P.allow_low_status_marriage
	if(is_royal_suitor_job(job))
		stop_tracking_human(H, "royal suitor bypasses familytree assignment")
		return

	var/royal_status = get_royal_status(H)
	if(royal_status)
		H.familytree_assignment_scheduled = TRUE
		addtimer(CALLBACK(src, PROC_REF(run_royal_assignment), H, royal_status), get_royal_delay(H) SECONDS)
		return

	if(H.familytree_pref != FAMILY_NONE)
		H.familytree_assignment_scheduled = TRUE
		var/timer = rand(1, 30) + 10
		addtimer(CALLBACK(src, PROC_REF(run_local_assignment), H, H.familytree_pref), timer SECONDS)
		return

	if(H.client && (H.mind?.assigned_role || H.job))
		stop_tracking_human(H, "familytree disabled for this character")

/datum/controller/subsystem/familytree/proc/run_local_assignment(mob/living/carbon/human/H, status)
	if(!H || QDELETED(H))
		return
	var/block_reason = get_familytree_runtime_block_reason(H, TRUE)
	if(block_reason == "dead")
		pause_familytree_human(H, "local assignment deferred: dead")
		return
	if(block_reason == "no client")
		H.familytree_assignment_scheduled = FALSE
		return
	if(block_reason)
		unsubscribe_familytree_human(H, "local assignment aborted: [block_reason]")
		return
	if(H.family_datum)
		H.familytree_assignment_scheduled = FALSE
		stop_tracking_human(H, "local assignment skipped; family already assigned")
		return
	H.familytree_assignment_scheduled = FALSE
	AddLocal(H, status)

/datum/controller/subsystem/familytree/proc/run_royal_assignment(mob/living/carbon/human/H, status)
	if(!H || QDELETED(H))
		return
	var/block_reason = get_familytree_runtime_block_reason(H, TRUE)
	if(block_reason == "dead")
		pause_familytree_human(H, "royal assignment deferred: dead")
		return
	if(block_reason == "no client")
		H.familytree_assignment_scheduled = FALSE
		return
	if(block_reason)
		unsubscribe_familytree_human(H, "royal assignment aborted: [block_reason]")
		return
	if(H.family_datum)
		H.familytree_assignment_scheduled = FALSE
		stop_tracking_human(H, "royal assignment skipped; family already assigned")
		return
	H.familytree_assignment_scheduled = FALSE
	AddRoyal(H, status)
