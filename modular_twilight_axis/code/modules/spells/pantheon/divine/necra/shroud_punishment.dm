/mob/living/carbon/human
	var/tranquility_shroud_offenses = 0

/mob/living/proc/break_tranquility_shroud_and_anger_necra(reason)
	if(QDELETED(src) || stat == DEAD)
		return FALSE
	if(!remove_tranquility_shroud(TRANQUILITY_SHROUD_REMOVAL_NECRA_ANGER))
		return FALSE
	playsound(get_turf(src), TRANQUILITY_SHROUD_ANGER_SOUND, 80, TRUE)
	to_chat(src, span_userdanger("Ваши действия прогневили Некру. Вы чувствуете ледяной озноб и взгляд, устремленный на вас из темноты."))
	addtimer(CALLBACK(src, PROC_REF(tranquility_shroud_anger_nearby_undead)), 0)
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/carbon/human, tranquility_shroud_punishment_summon), reason), 0)
	return TRUE

/mob/living/proc/tranquility_shroud_anger_nearby_undead()
	if(QDELETED(src) || stat == DEAD)
		return FALSE
	var/angered_any = FALSE
	for(var/mob/living/undead in viewers(TRANQUILITY_SHROUD_ANGER_RANGE, src))
		if(undead == src)
			continue
		if(undead.tranquility_shroud_force_undead_aggro(src))
			angered_any = TRUE
	return angered_any

/mob/living/proc/tranquility_shroud_force_undead_aggro(mob/living/target)
	if(!target || QDELETED(target) || target.stat == DEAD || !tranquility_shroud_is_valid_anger_undead())
		return FALSE
	if(ai_controller)
		var/list/aggro_table = ai_controller.blackboard[BB_MOB_AGGRO_TABLE]
		if(!aggro_table)
			aggro_table = list()
			ai_controller.blackboard[BB_MOB_AGGRO_TABLE] = aggro_table
		aggro_table[target] = max(aggro_table[target] || 0, TRANQUILITY_SHROUD_ANGER_THREAT)
		ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
		ai_controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, target)
		ai_controller.set_ai_status(AI_STATUS_ON)
		ai_controller.CancelActions()
	var/datum/component/ai_aggro_system/aggro = GetComponent(/datum/component/ai_aggro_system)
	if(aggro)
		aggro.add_threat_to_mob(target, TRANQUILITY_SHROUD_ANGER_THREAT)
	var/mob/living/simple_animal/hostile/hostile_mob = src
	if(istype(hostile_mob))
		hostile_mob.GiveTarget(target)
	return TRUE

/mob/living/carbon/human/proc/tranquility_shroud_has_company()
	for(var/mob/living/carbon/human/buddy in viewers(TRANQUILITY_SHROUD_ANGER_RANGE, src))
		if(buddy == src)
			continue
		if(buddy.has_tranquility_shroud())
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/tranquility_shroud_punishment_summon(reason)
	if(QDELETED(src) || stat == DEAD)
		return FALSE
	tranquility_shroud_offenses++
	if(tranquility_shroud_has_company())
		to_chat(src, span_userdanger("Тёмные сады Некры отверзают зев — три скелета лезут из земли, чтобы забрать вас и ваших спутников."))
		tranquility_shroud_summon_skeletons(3)
		return TRUE
	if(tranquility_shroud_offenses <= 1)
		return FALSE
	var/skeleton_count = tranquility_shroud_offenses - 1
	to_chat(src, span_userdanger("Земля стонет. Из неё восстают порождения садов Некры, чтобы утянуть вас прочь."))
	tranquility_shroud_summon_skeletons(skeleton_count)
	return TRUE

/mob/living/carbon/human/proc/tranquility_shroud_summon_skeletons(count)
	if(count <= 0)
		return
	var/list/turf/candidates = list()
	for(var/turf/open/T in range(3, src))
		if(T.density)
			continue
		if(T == get_turf(src))
			continue
		candidates += T
	for(var/i in 1 to count)
		var/turf/spawn_turf = length(candidates) ? pick_n_take(candidates) : get_turf(src)
		if(!spawn_turf)
			break
		new /obj/effect/temp_visual/gib_animation(spawn_turf, "gibbed-h")
		var/mob/living/simple_animal/hostile/rogue/skeleton/grasper = new(spawn_turf, null, FALSE, TRUE)
		grasper.faction = list(FACTION_CABAL)
		if(grasper.ai_controller)
			grasper.ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, src)
			grasper.ai_controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, src)
			grasper.ai_controller.set_ai_status(AI_STATUS_ON)
		grasper.GiveTarget(src)

/obj/structure/closet/dirthole/closed/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/rogueweapon/shovel) && isliving(user))
		var/mob/living/living_user = user
		if(living_user.used_intent?.type == /datum/intent/shovelscoop && living_user.has_tranquility_shroud())
			living_user.break_tranquility_shroud_and_anger_necra("grave")
	return ..()
