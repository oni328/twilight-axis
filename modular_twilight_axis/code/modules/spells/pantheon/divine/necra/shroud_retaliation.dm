#define TRANQUILITY_SHROUD_RETALIATION_FIRE_STACKS 6
#define TRANQUILITY_SHROUD_RETALIATION_DURATION 5 SECONDS
#define TRANQUILITY_SHROUD_RETALIATION_SLOWDOWN 4
#define MOVESPEED_ID_TRANQUILITY_SHROUD_RETALIATION "tranquility_shroud_retaliation"

/datum/status_effect/tranquility_shroud/proc/on_shroud_broken_by_undead(mob/living/undead_source)
	if(retaliation_used)
		return
	if(shroud_tier < CLERIC_T1)
		return
	if(QDELETED(undead_source) || undead_source.stat == DEAD)
		return
	if(!isliving(undead_source))
		return
	retaliation_used = TRUE
	playsound(get_turf(undead_source), 'sound/magic/whiteflame.ogg', 60, TRUE)
	new /obj/effect/temp_visual/explosion(get_turf(undead_source))
	undead_source.adjust_fire_stacks(TRANQUILITY_SHROUD_RETALIATION_FIRE_STACKS, /datum/status_effect/fire_handler/fire_stacks/divine)
	undead_source.apply_status_effect(/datum/status_effect/tranquility_shroud_retaliation)
	if(owner && !QDELETED(owner))
		to_chat(owner, span_notice("Защита Некры вспыхивает огнём, окутывая обидчика."))
		owner.visible_message(span_warning("[owner] окутывает [undead_source] вспышкой холодного огня!"))

/datum/status_effect/tranquility_shroud_retaliation
	id = "tranquility_shroud_retaliation"
	duration = TRANQUILITY_SHROUD_RETALIATION_DURATION
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null

/datum/status_effect/tranquility_shroud_retaliation/on_apply()
	if(!isliving(owner) || QDELETED(owner))
		return FALSE
	owner.add_movespeed_modifier(MOVESPEED_ID_TRANQUILITY_SHROUD_RETALIATION, multiplicative_slowdown = TRANQUILITY_SHROUD_RETALIATION_SLOWDOWN)
	return TRUE

/datum/status_effect/tranquility_shroud_retaliation/on_remove()
	if(owner && !QDELETED(owner))
		owner.remove_movespeed_modifier(MOVESPEED_ID_TRANQUILITY_SHROUD_RETALIATION)
	return ..()
