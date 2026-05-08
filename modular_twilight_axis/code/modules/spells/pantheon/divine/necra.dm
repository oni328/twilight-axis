#define TRANQUILITY_SHROUD_DURATION 12 MINUTES
#define TRANQUILITY_SHROUD_APPLY_TIME 2 SECONDS
#define TRANQUILITY_SHROUD_FORGET_RANGE 12
#define TRANQUILITY_SHROUD_AI_TARGET_SIGNAL "mob_ai_target_check"
#define TRANQUILITY_SHROUD_FILTER "tranquility_shroud_glow"
#define TRANQUILITY_SHROUD_REMOVAL_AGGRESSION "aggression"
#define TRANQUILITY_SHROUD_REMOVAL_UNDEAD_ATTACK "undead_attack"

/obj/effect/proc_holder/spell/targeted/touch/shroud_of_tranquility
	name = "Shroud of Tranquility"
	desc = "Draw a graveward hush over a living soul, causing lesser undead to forget them until violence or time tears the blessing away."
	overlay_icon = 'modular_twilight_axis/icons/mob/actions/necra_shroud.dmi'
	overlay_state = "shroud_tranquility"
	action_icon = 'modular_twilight_axis/icons/mob/actions/necra_shroud.dmi'
	action_icon_state = "shroud_tranquility"
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/whiteflame.ogg'
	associated_skill = /datum/skill/magic/holy
	releasedrain = 5
	recharge_time = 30 SECONDS
	miracle = TRUE
	devotion_cost = 15
	hand_path = /obj/item/melee/touch_attack/tranquility_shroud
	drawmessage = "A pale, quiet light gathers around my hand. A hush settles over my palm."
	dropmessage = "The hush slips from my hand."

/obj/item/melee/touch_attack/tranquility_shroud
	name = "tranquil shroud"
	desc = "A quiet holy stillness gathered around the hand."
	icon = 'modular_twilight_axis/icons/mob/actions/necra_shroud.dmi'
	icon_state = "shroud_tranquility"
	item_state = "justicei"
	possible_item_intents = list(/datum/intent/use)
	on_use_sound = 'sound/magic/whiteflame.ogg'
	force = 0
	damtype = BURN
	wdefense = 0

/obj/item/melee/touch_attack/tranquility_shroud/pre_attack(atom/target, mob/living/user, params)
	if(QDELETED(src) || QDELETED(user))
		return TRUE
	if(!isliving(target))
		to_chat(user, span_warning("The hush finds no living name to cover."))
		return TRUE
	if(get_dist(user, target) > 1)
		to_chat(user, span_warning("I must be beside [target] to draw the shroud over them."))
		return TRUE

	var/mob/living/living_target = target
	if(QDELETED(living_target) || living_target.stat != CONSCIOUS)
		to_chat(user, span_warning("The shroud will only settle over the living and wakeful."))
		return TRUE
	if((living_target.mob_biotypes & MOB_UNDEAD) || living_target.mind?.has_antag_datum(/datum/antagonist/zombie))
		to_chat(user, span_warning("The shroud recoils; the dead have no living breath to veil."))
		return TRUE
	if(living_target.has_tranquility_shroud())
		to_chat(user, span_notice("[living_target] is already held in a solemn stillness."))
		return TRUE

	user.visible_message(span_notice("[user] raises a pale, quiet hand toward [living_target]."), span_notice("I begin drawing a tranquil shroud over [living_target]."))
	if(living_target != user)
		to_chat(living_target, span_notice("A pale, quiet light gathers close to me."))

	if(!do_after(user, TRANQUILITY_SHROUD_APPLY_TIME, target = living_target))
		return TRUE
	if(QDELETED(src) || QDELETED(user) || QDELETED(living_target))
		return TRUE
	if(get_dist(user, living_target) > 1 || living_target.stat != CONSCIOUS)
		to_chat(user, span_warning("The shroud slips away before it can settle."))
		return TRUE
	if((living_target.mob_biotypes & MOB_UNDEAD) || living_target.mind?.has_antag_datum(/datum/antagonist/zombie))
		to_chat(user, span_warning("The shroud recoils; the dead have no living breath to veil."))
		return TRUE
	if(living_target.has_tranquility_shroud())
		to_chat(user, span_notice("[living_target] is already held in a solemn stillness."))
		return TRUE

	var/datum/status_effect/tranquility_shroud/shroud = living_target.apply_status_effect(/datum/status_effect/tranquility_shroud, user, user.get_skill_level(/datum/skill/magic/holy))
	if(!shroud)
		to_chat(user, span_warning("The shroud fails to settle."))
		return TRUE

	playsound(get_turf(living_target), on_use_sound, 50, TRUE)
	user.visible_message(span_notice("[user] traces a quiet sign over [living_target]."), span_notice("I draw a tranquil shroud over [living_target]."))
	to_chat(living_target, span_notice("A solemn stillness settles over me, as if the dead briefly forget my name."))
	qdel(src)
	return TRUE

/datum/status_effect/tranquility_shroud
	id = "tranquility_shroud"
	alert_type = /atom/movable/screen/alert/status_effect/buff/tranquility_shroud
	duration = TRANQUILITY_SHROUD_DURATION
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	var/outline_colour = "#a0a0a0"
	var/removal_reason
	var/holy_skill = 0
	var/datum/weakref/caster_ref

/datum/status_effect/tranquility_shroud/on_creation(mob/living/new_owner, mob/living/caster, caster_holy_skill)
	if(caster)
		caster_ref = WEAKREF(caster)
	holy_skill = caster_holy_skill || 0
	return ..()

/datum/status_effect/tranquility_shroud/on_apply()
	if(!owner || QDELETED(owner) || owner.stat != CONSCIOUS || (owner.mob_biotypes & MOB_UNDEAD) || owner.mind?.has_antag_datum(/datum/antagonist/zombie))
		return FALSE
	owner.AddElement(/datum/element/tranquility_shroud)
	if(!owner.get_filter(TRANQUILITY_SHROUD_FILTER))
		owner.add_filter(TRANQUILITY_SHROUD_FILTER, 2, list("type" = "outline", "color" = outline_colour, "alpha" = 120, "size" = 2))
	return TRUE

/datum/status_effect/tranquility_shroud/on_remove()
	if(owner && !QDELETED(owner))
		owner.RemoveElement(/datum/element/tranquility_shroud)
		owner.remove_filter(TRANQUILITY_SHROUD_FILTER)
		if(removal_reason == TRANQUILITY_SHROUD_REMOVAL_AGGRESSION || removal_reason == TRANQUILITY_SHROUD_REMOVAL_UNDEAD_ATTACK)
			to_chat(owner, span_warning("The tranquil shroud tears away. The dead remember me."))
		else
			to_chat(owner, span_notice("The solemn stillness around me fades."))
	return ..()

/datum/status_effect/tranquility_shroud/proc/dispel(reason, mob/living/undead_source)
	if(QDELETED(src))
		return
	removal_reason = reason
	if(reason == TRANQUILITY_SHROUD_REMOVAL_UNDEAD_ATTACK)
		on_shroud_broken_by_undead(undead_source)
	qdel(src)

/datum/status_effect/tranquility_shroud/proc/on_shroud_broken_by_undead(mob/living/undead_source)
	// TODO: Apprentice+ scaling hook for a mild holy debuff once boss/resistance rules are settled.
	return

/atom/movable/screen/alert/status_effect/buff/tranquility_shroud
	name = "Shroud of Tranquility"
	desc = "A solemn stillness lingers over me. Lesser dead may briefly forget my name."
	icon = 'modular_twilight_axis/icons/mob/actions/necra_shroud.dmi'
	icon_state = "shroud_tranquility"

/datum/element/tranquility_shroud

/datum/element/tranquility_shroud/Attach(datum/target)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE

	var/mob/living/owner = target
	RegisterSignal(owner, TRANQUILITY_SHROUD_AI_TARGET_SIGNAL, PROC_REF(on_ai_target_check))
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_owner_item_attack))
	RegisterSignal(owner, COMSIG_HUMAN_EARLY_UNARMED_ATTACK, PROC_REF(on_owner_unarmed_attack))
	RegisterSignal(owner, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_owner_ranged_attack))
	RegisterSignal(owner, COMSIG_ATOM_ATTACKBY, PROC_REF(on_owner_attackby))
	RegisterSignals(owner, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW), PROC_REF(on_owner_attack_generic))
	RegisterSignal(owner, COMSIG_ATOM_ATTACK_ANIMAL, PROC_REF(on_owner_attack_npc))
	RegisterSignal(owner, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_owner_bullet_act))
	RegisterSignal(owner, COMSIG_ATOM_HITBY, PROC_REF(on_owner_hitby))
	owner.tranquility_shroud_hide_from_nearby_undead()

/datum/element/tranquility_shroud/Detach(datum/source, ...)
	UnregisterSignal(source, list(
		TRANQUILITY_SHROUD_AI_TARGET_SIGNAL,
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_HUMAN_EARLY_UNARMED_ATTACK,
		COMSIG_MOB_ATTACK_RANGED,
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_ATTACK_HAND,
		COMSIG_ATOM_ATTACK_PAW,
		COMSIG_ATOM_ATTACK_ANIMAL,
		COMSIG_ATOM_BULLET_ACT,
		COMSIG_ATOM_HITBY,
	))
	return ..()

/datum/element/tranquility_shroud/proc/on_ai_target_check(mob/living/source, mob/living/attacker)
	SIGNAL_HANDLER
	if(attacker?.is_lesser_npc_undead())
		return TRUE

/datum/element/tranquility_shroud/proc/should_break_from_outgoing_aggression(mob/living/source, atom/target, obj/item/weapon)
	if(QDELETED(source) || !isliving(target) || target == source)
		return FALSE
	if(weapon?.force)
		return TRUE
	if(source.used_intent?.type == INTENT_HELP)
		return FALSE
	return TRUE

/datum/element/tranquility_shroud/proc/break_from_incoming_attack(atom/target, atom/attacker)
	if(!isliving(target))
		return
	var/mob/living/living_target = target
	var/mob/living/undead_attacker
	if(isliving(attacker))
		var/mob/living/living_attacker = attacker
		if(living_attacker.mob_biotypes & MOB_UNDEAD)
			undead_attacker = living_attacker
	living_target.remove_tranquility_shroud(undead_attacker ? TRANQUILITY_SHROUD_REMOVAL_UNDEAD_ATTACK : TRANQUILITY_SHROUD_REMOVAL_AGGRESSION, undead_attacker)

/datum/element/tranquility_shroud/proc/on_owner_item_attack(mob/living/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(should_break_from_outgoing_aggression(source, target, weapon))
		source.remove_tranquility_shroud(TRANQUILITY_SHROUD_REMOVAL_AGGRESSION)

/datum/element/tranquility_shroud/proc/on_owner_unarmed_attack(mob/living/source, atom/target, proximity)
	SIGNAL_HANDLER
	if(!proximity)
		return
	if(should_break_from_outgoing_aggression(source, target, null))
		source.remove_tranquility_shroud(TRANQUILITY_SHROUD_REMOVAL_AGGRESSION)

/datum/element/tranquility_shroud/proc/on_owner_ranged_attack(mob/living/source, atom/target, params)
	SIGNAL_HANDLER
	if(should_break_from_outgoing_aggression(source, target, null))
		source.remove_tranquility_shroud(TRANQUILITY_SHROUD_REMOVAL_AGGRESSION)

/datum/element/tranquility_shroud/proc/on_owner_attackby(atom/target, obj/item/weapon, mob/attacker, list/modifiers)
	SIGNAL_HANDLER
	break_from_incoming_attack(target, attacker)

/datum/element/tranquility_shroud/proc/on_owner_attack_generic(atom/target, mob/living/attacker, list/modifiers)
	SIGNAL_HANDLER
	break_from_incoming_attack(target, attacker)

/datum/element/tranquility_shroud/proc/on_owner_attack_npc(atom/target, mob/living/attacker)
	SIGNAL_HANDLER
	break_from_incoming_attack(target, attacker)

/datum/element/tranquility_shroud/proc/on_owner_bullet_act(atom/target, obj/projectile/hit_projectile)
	SIGNAL_HANDLER
	if(!hit_projectile)
		return
	break_from_incoming_attack(target, hit_projectile.firer)

/datum/element/tranquility_shroud/proc/on_owner_hitby(atom/target, atom/movable/hit_atom, skipcatch = FALSE, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!hit_atom)
		return
	var/atom/attacker
	if(isitem(hit_atom))
		var/obj/item/hit_item = hit_atom
		attacker = hit_item.thrownby
	break_from_incoming_attack(target, attacker)

/mob/living/proc/has_tranquility_shroud()
	return !!has_status_effect(/datum/status_effect/tranquility_shroud)

/mob/living/proc/remove_tranquility_shroud(reason = null, mob/living/undead_source = null)
	var/datum/status_effect/tranquility_shroud/shroud = has_status_effect(/datum/status_effect/tranquility_shroud)
	if(!shroud)
		return FALSE
	shroud.dispel(reason, undead_source)
	return TRUE

/mob/living/proc/is_lesser_npc_undead()
	if(!(mob_biotypes & MOB_UNDEAD))
		return FALSE
	if(client || ckey)
		return FALSE
	if(stat == DEAD)
		return FALSE
	if(is_player_raised_undead())
		return FALSE
	if(istype(src, /mob/living/simple_animal/hostile/boss))
		return FALSE
	if(istype(src, /mob/living/carbon/human/species/skeleton/npc/special))
		return FALSE
	if(threat_point >= THREAT_ELITE)
		return FALSE
	if(!ai_controller && !istype(src, /mob/living/simple_animal/hostile))
		return FALSE
	return TRUE

/mob/living/proc/can_undead_see_target(mob/living/target)
	if(!target || QDELETED(target))
		return TRUE
	if(!target.has_tranquility_shroud())
		return TRUE
	return !is_lesser_npc_undead()

/mob/living/proc/tranquility_shroud_hide_from_nearby_undead()
	for(var/mob/living/undead in viewers(TRANQUILITY_SHROUD_FORGET_RANGE, src))
		if(!undead.can_undead_see_target(src))
			undead.forget_tranquility_shrouded_target(src)

/mob/living/proc/forget_tranquility_shrouded_target(mob/living/target)
	if(!target || can_undead_see_target(target))
		return
	if(ai_controller)
		if(ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET] == target)
			ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		if(ai_controller.blackboard[BB_HIGHEST_THREAT_MOB] == target)
			ai_controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
		var/list/aggro_table = ai_controller.blackboard[BB_MOB_AGGRO_TABLE]
		if(aggro_table && aggro_table[target])
			aggro_table -= target
		ai_controller.CancelActions()
	var/mob/living/simple_animal/hostile/hostile_mob = src
	if(istype(hostile_mob) && hostile_mob.target == target)
		hostile_mob.LoseTarget()

#undef TRANQUILITY_SHROUD_DURATION
#undef TRANQUILITY_SHROUD_APPLY_TIME
#undef TRANQUILITY_SHROUD_FORGET_RANGE
#undef TRANQUILITY_SHROUD_AI_TARGET_SIGNAL
#undef TRANQUILITY_SHROUD_FILTER
#undef TRANQUILITY_SHROUD_REMOVAL_AGGRESSION
#undef TRANQUILITY_SHROUD_REMOVAL_UNDEAD_ATTACK
