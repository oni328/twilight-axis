#define TRANQUILITY_SHROUD_DURATION 12 MINUTES
#define TRANQUILITY_SHROUD_APPLY_TIME 2 SECONDS
#define TRANQUILITY_SHROUD_FORGET_RANGE 12
#define TRANQUILITY_SHROUD_ANGER_RANGE 5
#define TRANQUILITY_SHROUD_FILTER "tranquility_shroud_glow"
#define TRANQUILITY_SHROUD_EXPENSIVE_ITEM_VALUE 30
#define TRANQUILITY_SHROUD_ANGER_THREAT 1000
#define TRANQUILITY_SHROUD_ANGER_SOUND 'sound/vo/mobs/skel/skeleton_laugh.ogg'
#define TRANQUILITY_SHROUD_REMOVAL_AGGRESSION "aggression"
#define TRANQUILITY_SHROUD_REMOVAL_UNDEAD_ATTACK "undead_attack"
#define TRANQUILITY_SHROUD_REMOVAL_NECRA_ANGER "necra_anger"
#define TRANQUILITY_SHROUD_TRAIT_SOURCE "tranquility_shroud"
#define TRANQUILITY_SHROUD_DEADITE_SKIN "78a060"
#define TRANQUILITY_SHROUD_VAMPIRE_SKIN "c9d3de"
#define TRANQUILITY_SHROUD_SUN_BURN_DAMAGE 3

/datum/action/cooldown/spell/touch/shroud_of_tranquility
	name = "Shroud of Tranquility"
	desc = "Draw a graveward hush over a living soul, causing lesser undead to forget them until violence, sacrilege, or time tears the blessing away."

	background_icon = 'icons/mob/actions/genericmiracles.dmi'
	button_icon = 'icons/mob/screen_alert.dmi'
	button_icon_state = "rotted_body"

	draw_message = span_notice("A pale, quiet light gathers around my hand. A hush settles over my palm.")
	drop_message = span_notice("The hush slips from my hand.")

	hand_path = /obj/item/melee/new_touch_attack/tranquility_shroud
	can_cast_on_self = TRUE
	ignore_armor_penalty = TRUE

	primary_resource_type = SPELL_COST_DEVOTION
	primary_resource_cost = SPELLCOST_MIRACLE_MINOR

	secondary_resource_type = SPELL_COST_STAMINA
	secondary_resource_cost = SPELLCOST_CANTRIP

	associated_stat = null
	associated_skill = /datum/skill/magic/holy
	spell_tier = CLERIC_T0
	spell_impact_intensity = SPELL_IMPACT_NONE

	point_cost = 0
	required_items = list(/obj/item/clothing/neck/roguetown/psicross)
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z
	cooldown_time = 30 SECONDS
	attunement_school = null
	sound = 'sound/magic/whiteflame.ogg'

/datum/action/cooldown/spell/touch/shroud_of_tranquility/on_hand_deleted(datum/source)
	remove_hand(null, FALSE)

/datum/action/cooldown/spell/touch/shroud_of_tranquility/on_hand_dropped(datum/source, mob/living/dropper)
	remove_hand(dropper, FALSE)

/datum/action/cooldown/spell/touch/shroud_of_tranquility/cast(mob/living/carbon/cast_on)
	if(!QDELETED(attached_hand) && (attached_hand in cast_on.held_items))
		remove_hand(cast_on, FALSE)
		return FALSE
	return ..()

/datum/action/cooldown/spell/touch/shroud_of_tranquility/cast_on_hand_hit(obj/item/melee/new_touch_attack/hand, atom/victim, mob/living/carbon/caster, list/modifiers)
	if(QDELETED(hand) || QDELETED(caster))
		return FALSE
	if(!isliving(victim))
		to_chat(caster, span_warning("The hush finds no living name to cover."))
		return FALSE
	if(get_dist(caster, victim) > 1)
		to_chat(caster, span_warning("I must be beside [victim] to draw the shroud over them."))
		return FALSE

	var/mob/living/living_target = victim
	if(QDELETED(living_target) || living_target.stat != CONSCIOUS)
		to_chat(caster, span_warning("The shroud will only settle over the living and wakeful."))
		return FALSE
	if((living_target.mob_biotypes & MOB_UNDEAD) || living_target.mind?.has_antag_datum(/datum/antagonist/zombie))
		to_chat(caster, span_warning("The shroud recoils; the dead have no living breath to veil."))
		return FALSE
	if(living_target.has_tranquility_shroud())
		to_chat(caster, span_notice("[living_target] is already held in a solemn stillness."))
		return FALSE

	caster.visible_message(span_notice("[caster] raises a pale, quiet hand toward [living_target]."), span_notice("I begin drawing a tranquil shroud over [living_target]."))
	if(living_target != caster)
		to_chat(living_target, span_notice("A pale, quiet light gathers close to me."))

	if(!do_after(caster, TRANQUILITY_SHROUD_APPLY_TIME, target = living_target))
		return FALSE
	if(QDELETED(hand) || QDELETED(caster) || QDELETED(living_target))
		return FALSE
	if(get_dist(caster, living_target) > 1 || living_target.stat != CONSCIOUS)
		to_chat(caster, span_warning("The shroud slips away before it can settle."))
		return FALSE
	if((living_target.mob_biotypes & MOB_UNDEAD) || living_target.mind?.has_antag_datum(/datum/antagonist/zombie))
		to_chat(caster, span_warning("The shroud recoils; the dead have no living breath to veil."))
		return FALSE
	if(living_target.has_tranquility_shroud())
		to_chat(caster, span_notice("[living_target] is already held in a solemn stillness."))
		return FALSE

	var/applied_shroud_tier = spell_tier
	if(ishuman(caster))
		var/mob/living/carbon/human/human_caster = caster
		applied_shroud_tier = max(applied_shroud_tier, human_caster.devotion?.level || CLERIC_T0)
	var/datum/status_effect/tranquility_shroud/shroud = living_target.apply_status_effect(/datum/status_effect/tranquility_shroud, caster, caster.get_skill_level(/datum/skill/magic/holy), applied_shroud_tier)
	if(!shroud)
		to_chat(caster, span_warning("The shroud fails to settle."))
		return FALSE

	playsound(get_turf(living_target), sound, 50, TRUE)
	caster.visible_message(span_notice("[caster] traces a quiet sign over [living_target]."), span_notice("I draw a tranquil shroud over [living_target]."))
	to_chat(living_target, span_notice("A solemn stillness settles over me, as if the dead briefly forget my name."))
	hand.remove_hand_with_no_refund(caster)
	return TRUE

/obj/item/melee/new_touch_attack/tranquility_shroud
	name = "tranquil shroud"
	desc = "A quiet holy stillness gathered around the hand."
	possible_item_intents = list(/datum/intent/use)
	icon = 'icons/mob/screen_alert.dmi'
	icon_state = "rotted_body"
	associated_skill = /datum/skill/magic/holy
	experimental_inhand = FALSE
	w_class = WEIGHT_CLASS_TINY

/obj/item/melee/new_touch_attack/tranquility_shroud/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!proximity)
		return
	var/datum/action/cooldown/spell/touch/shroud_of_tranquility/spell = spell_which_made_us?.resolve()
	if(spell)
		spell.cast_on_hand_hit(src, target, user)

/datum/status_effect/tranquility_shroud
	id = "tranquility_shroud"
	alert_type = /atom/movable/screen/alert/status_effect/buff/tranquility_shroud
	duration = TRANQUILITY_SHROUD_DURATION
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	var/outline_colour = "#a0a0a0"
	var/removal_reason
	var/holy_skill = 0
	var/shroud_tier = CLERIC_T0
	var/datum/weakref/caster_ref
	var/retaliation_used = FALSE
	var/list/cached_appearance
	var/granted_undead_faction = FALSE
	var/granted_norun_trait = FALSE

/datum/status_effect/tranquility_shroud/on_creation(mob/living/new_owner, mob/living/caster, caster_holy_skill, applied_shroud_tier = CLERIC_T0)
	if(caster)
		caster_ref = WEAKREF(caster)
	holy_skill = caster_holy_skill || 0
	shroud_tier = applied_shroud_tier
	return ..()

/datum/status_effect/tranquility_shroud/on_apply()
	if(!owner || QDELETED(owner) || owner.stat != CONSCIOUS || (owner.mob_biotypes & MOB_UNDEAD) || owner.mind?.has_antag_datum(/datum/antagonist/zombie))
		return FALSE
	owner.AddElement(/datum/element/tranquility_shroud)
	if(!owner.get_filter(TRANQUILITY_SHROUD_FILTER))
		owner.add_filter(TRANQUILITY_SHROUD_FILTER, 2, list("type" = "outline", "color" = outline_colour, "alpha" = 120, "size" = 2))
	apply_shroud_disguise()
	return TRUE

/datum/status_effect/tranquility_shroud/on_remove()
	if(owner && !QDELETED(owner))
		remove_shroud_disguise()
		owner.RemoveElement(/datum/element/tranquility_shroud)
		owner.remove_filter(TRANQUILITY_SHROUD_FILTER)
		if(removal_reason == TRANQUILITY_SHROUD_REMOVAL_AGGRESSION || removal_reason == TRANQUILITY_SHROUD_REMOVAL_UNDEAD_ATTACK || removal_reason == TRANQUILITY_SHROUD_REMOVAL_NECRA_ANGER)
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

/atom/movable/screen/alert/status_effect/buff/tranquility_shroud
	name = "Shroud of Tranquility"
	desc = "A solemn stillness lingers over me. Lesser dead may briefly forget my name."
	icon_state = "rotted_body"

/datum/element/tranquility_shroud

/datum/element/tranquility_shroud/Attach(datum/target)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE

	var/mob/living/owner = target
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_owner_item_attack))
	RegisterSignal(owner, COMSIG_HUMAN_EARLY_UNARMED_ATTACK, PROC_REF(on_owner_unarmed_attack))
	RegisterSignal(owner, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_owner_ranged_attack))
	RegisterSignal(owner, COMSIG_ATOM_ATTACKBY, PROC_REF(on_owner_attackby))
	RegisterSignals(owner, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW), PROC_REF(on_owner_attack_generic))
	RegisterSignal(owner, COMSIG_ATOM_ATTACK_ANIMAL, PROC_REF(on_owner_attack_npc))
	RegisterSignal(owner, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_owner_bullet_act))
	RegisterSignal(owner, COMSIG_ATOM_HITBY, PROC_REF(on_owner_hitby))
	RegisterSignal(owner, COMSIG_ATOM_ENTERED, PROC_REF(on_owner_entered_by_atom))
	RegisterSignal(owner, COMSIG_HUMAN_LIFE, PROC_REF(on_owner_life))
	RegisterSignal(owner, COMSIG_MOB_BEFORE_SPELL_CAST, PROC_REF(on_owner_cast_spell))
	RegisterSignal(owner, "mob_ai_target_check", PROC_REF(on_owner_ai_target_check))
	owner.tranquility_shroud_hide_from_nearby_undead()

/datum/element/tranquility_shroud/Detach(datum/source, ...)
	UnregisterSignal(source, list(
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_HUMAN_EARLY_UNARMED_ATTACK,
		COMSIG_MOB_ATTACK_RANGED,
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_ATTACK_HAND,
		COMSIG_ATOM_ATTACK_PAW,
		COMSIG_ATOM_ATTACK_ANIMAL,
		COMSIG_ATOM_BULLET_ACT,
		COMSIG_ATOM_HITBY,
		COMSIG_ATOM_ENTERED,
		COMSIG_HUMAN_LIFE,
		COMSIG_MOB_BEFORE_SPELL_CAST,
		"mob_ai_target_check",
	))
	return ..()

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

/datum/element/tranquility_shroud/proc/on_owner_cast_spell(mob/living/source, datum/action/cooldown/spell/spell, atom/cast_on)
	SIGNAL_HANDLER
	if(QDELETED(source))
		return
	if(istype(spell, /datum/action/cooldown/spell/touch/shroud_of_tranquility))
		return
	source.remove_tranquility_shroud(TRANQUILITY_SHROUD_REMOVAL_AGGRESSION)

/datum/element/tranquility_shroud/proc/on_owner_ai_target_check(mob/living/source, mob/living/checker)
	SIGNAL_HANDLER
	if(!isliving(source) || !isliving(checker))
		return FALSE
	if(!checker.can_undead_see_target(source))
		return TRUE
	return FALSE

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

/datum/element/tranquility_shroud/proc/on_owner_entered_by_atom(mob/living/source, atom/movable/entered, atom/old_loc)
	SIGNAL_HANDLER
	if(QDELETED(source) || !isitem(entered) || !isturf(old_loc))
		return
	var/obj/item/picked_item = entered
	if(!picked_item.is_expensive_for_tranquility_shroud())
		return
	if(tranquility_shroud_turf_has_player_corpse(old_loc, source))
		return
	if(!source.tranquility_shroud_has_nearby_protected_undead())
		return
	source.break_tranquility_shroud_and_anger_necra("theft")

/proc/tranquility_shroud_turf_has_player_corpse(turf/T, mob/exclude)
	if(!isturf(T))
		return FALSE
	for(var/mob/living/carbon/human/H in T.contents)
		if(H == exclude)
			continue
		if(H.stat != DEAD)
			continue
		if(H.ckey || H.mind || H.client)
			return TRUE
	return FALSE

/datum/element/tranquility_shroud/proc/on_owner_life(mob/living/carbon/human/source)
	SIGNAL_HANDLER
	if(!ishuman(source) || QDELETED(source) || source.stat == DEAD)
		return
	var/datum/status_effect/tranquility_shroud/shroud = source.has_status_effect(/datum/status_effect/tranquility_shroud)
	if(!shroud)
		return
	shroud.process_sun_burn()

/mob/living/proc/has_tranquility_shroud()
	return !!has_status_effect(/datum/status_effect/tranquility_shroud)

/mob/living/proc/remove_tranquility_shroud(reason = null, mob/living/undead_source = null)
	var/datum/status_effect/tranquility_shroud/shroud = has_status_effect(/datum/status_effect/tranquility_shroud)
	if(!shroud)
		return FALSE
	shroud.dispel(reason, undead_source)
	return TRUE

/mob/living/proc/is_player_raised_undead()
	if(summoner)
		return TRUE
	if(faction)
		if(FACTION_CABAL in faction)
			return TRUE
		for(var/faction_name as anything in faction)
			if(istext(faction_name) && findtext(faction_name, "_faction"))
				return TRUE
	return FALSE

/mob/living/proc/tranquility_shroud_is_player_controlled()
	return !!(client || ckey || mind?.key)

/mob/living/proc/tranquility_shroud_has_undead_faction()
	if(!faction)
		return FALSE
	var/static/list/undead_factions = list(
		FACTION_UNDEAD,
		FACTION_DUNDEAD,
		FACTION_LICH,
		FACTION_ZOMBIE,
		FACTION_SKELETON,
		FACTION_REVENANTS,
	)
	return !!length(faction & undead_factions)

/mob/living/proc/tranquility_shroud_is_npc_undead_faction()
	if(stat == DEAD)
		return FALSE
	if(tranquility_shroud_is_player_controlled())
		return FALSE
	if(is_player_raised_undead())
		return FALSE
	return tranquility_shroud_has_undead_faction()

/mob/living/proc/tranquility_shroud_has_deadite_mask()
	var/datum/status_effect/tranquility_shroud/shroud = has_status_effect(/datum/status_effect/tranquility_shroud)
	return shroud?.uses_deadite_mask()

/mob/living/proc/tranquility_shroud_has_vampire_mask()
	var/datum/status_effect/tranquility_shroud/shroud = has_status_effect(/datum/status_effect/tranquility_shroud)
	return shroud?.uses_vampire_mask()

/mob/living/proc/tranquility_shroud_undead_examine_text(mob/examiner)
	var/datum/status_effect/tranquility_shroud/shroud = has_status_effect(/datum/status_effect/tranquility_shroud)
	if(!shroud || !isliving(examiner))
		return null
	var/mob/living/living_examiner = examiner
	if(shroud.uses_vampire_mask() && living_examiner.mind?.has_antag_datum(/datum/antagonist/vampire))
		return span_boldnotice("Низший вампир. Из мелкого ответвления, недавно обращённый.")
	if(shroud.uses_deadite_mask() && (living_examiner.mob_biotypes & MOB_UNDEAD))
		return span_boldnotice("Another deadite.")
	return null

/mob/living/get_villain_text(mob/examiner)
	. = ..()
	var/shroud_text = tranquility_shroud_undead_examine_text(examiner)
	if(!shroud_text)
		return .
	if(.)
		. += "<br>"
	. += shroud_text

/mob/living/proc/tranquility_shroud_respects_deadites()
	if(!tranquility_shroud_is_npc_undead_faction())
		return FALSE
	var/mob/living/simple_animal/hostile/hostile_mob = src
	if(istype(hostile_mob) && hostile_mob.attack_same)
		return FALSE
	var/datum/targetting_datum/basic/ignore_faction/ignore_faction_targeting = ai_controller?.blackboard[BB_TARGETTING_DATUM]
	if(istype(ignore_faction_targeting))
		return FALSE
	return TRUE

/mob/living/proc/tranquility_shroud_respects_vampire_mask()
	return !!mind?.has_antag_datum(/datum/antagonist/vampire)

/mob/living/proc/tranquility_shroud_has_nearby_protected_undead()
	for(var/mob/living/witness in range(TRANQUILITY_SHROUD_ANGER_RANGE, src))
		if(witness == src)
			continue
		if(!witness.tranquility_shroud_is_undead_witness())
			continue
		return TRUE
	return FALSE

/mob/living/proc/tranquility_shroud_is_undead_witness()
	return tranquility_shroud_is_npc_undead_faction()

/mob/living/proc/is_lesser_npc_undead()
	if(!tranquility_shroud_is_npc_undead_faction())
		return FALSE
	if(istype(src, /mob/living/simple_animal/hostile/boss))
		return FALSE
	if(threat_point >= THREAT_ELITE)
		return FALSE
	if(!ai_controller && !istype(src, /mob/living/simple_animal/hostile))
		return FALSE
	return TRUE

/mob/living/proc/tranquility_shroud_is_valid_anger_undead()
	if(is_lesser_npc_undead())
		return TRUE
	if(!tranquility_shroud_respects_deadites())
		return FALSE
	if(istype(src, /mob/living/simple_animal/hostile/boss))
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
	if(target.tranquility_shroud_has_vampire_mask() && tranquility_shroud_respects_vampire_mask())
		return FALSE
	if(target.tranquility_shroud_has_deadite_mask() && tranquility_shroud_respects_deadites())
		return FALSE
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

/obj/item/proc/is_expensive_for_tranquility_shroud()
	return get_real_price() > TRANQUILITY_SHROUD_EXPENSIVE_ITEM_VALUE
