/datum/status_effect/tranquility_shroud/proc/uses_deadite_mask()
	return shroud_tier >= CLERIC_T1

/datum/status_effect/tranquility_shroud/proc/uses_vampire_mask()
	return shroud_tier >= CLERIC_T2

/datum/status_effect/tranquility_shroud/proc/apply_shroud_disguise()
	if(QDELETED(owner))
		return
	if(uses_deadite_mask() || uses_vampire_mask())
		grant_undead_faction()
	if(uses_deadite_mask() && !uses_vampire_mask())
		grant_norun_trait()
	if(ishuman(owner))
		apply_skin_disguise()

/datum/status_effect/tranquility_shroud/proc/remove_shroud_disguise()
	if(granted_undead_faction)
		release_undead_faction()
	if(granted_norun_trait)
		release_norun_trait()
	if(ishuman(owner))
		restore_skin_appearance()

/datum/status_effect/tranquility_shroud/proc/grant_undead_faction()
	if(QDELETED(owner) || granted_undead_faction)
		return
	if(!(FACTION_UNDEAD in owner.faction))
		owner.faction += FACTION_UNDEAD
	granted_undead_faction = TRUE
	owner.notify_faction_change()

/datum/status_effect/tranquility_shroud/proc/release_undead_faction()
	if(!granted_undead_faction)
		return
	if(owner && !QDELETED(owner))
		owner.faction -= FACTION_UNDEAD
		owner.notify_faction_change()
	granted_undead_faction = FALSE

/datum/status_effect/tranquility_shroud/proc/grant_norun_trait()
	if(QDELETED(owner) || granted_norun_trait)
		return
	if(!HAS_TRAIT_FROM(owner, TRAIT_NORUN, TRANQUILITY_SHROUD_TRAIT_SOURCE))
		ADD_TRAIT(owner, TRAIT_NORUN, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_norun_trait = TRUE

/datum/status_effect/tranquility_shroud/proc/release_norun_trait()
	if(!granted_norun_trait)
		return
	if(owner && !QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_NORUN, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_norun_trait = FALSE

/datum/status_effect/tranquility_shroud/proc/apply_skin_disguise()
	var/mob/living/carbon/human/H = owner
	if(!H)
		return
	cached_appearance = list(
		"skin_tone" = H.skin_tone,
		"original_skin_tone" = H.original_skin_tone,
	)
	if(uses_vampire_mask())
		H.original_skin_tone = H.skin_tone
		H.skin_tone = TRANQUILITY_SHROUD_VAMPIRE_SKIN
		to_chat(H, span_notice("Моя кожа становится бледной и холодной, как у недавно обращённого."))
		H.update_body()
		return
	if(uses_deadite_mask())
		H.original_skin_tone = H.skin_tone
		H.skin_tone = TRANQUILITY_SHROUD_DEADITE_SKIN
		to_chat(H, span_notice("Кожа покрывается зеленоватым, мертвенным оттенком, как у дедайта."))
		H.update_body()

/datum/status_effect/tranquility_shroud/proc/restore_skin_appearance()
	var/mob/living/carbon/human/H = owner
	if(!H || !cached_appearance)
		cached_appearance = null
		return
	H.skin_tone = cached_appearance["skin_tone"]
	H.original_skin_tone = cached_appearance["original_skin_tone"]
	cached_appearance = null
	if(!QDELETED(H))
		H.update_body()

/datum/status_effect/tranquility_shroud/proc/process_sun_burn()
	if(!uses_vampire_mask())
		return
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	if(GLOB.tod != "day")
		return
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(!isturf(H.loc))
		return
	var/turf/loc_turf = H.loc
	if(!loc_turf.can_see_sky())
		return
	if(H.is_face_concealed_for_shroud())
		return
	to_chat(H, span_danger("Солнечный свет жжёт мою бледную кожу!"))
	H.fire_act(1, TRANQUILITY_SHROUD_SUN_BURN_DAMAGE)

/mob/living/carbon/human/proc/is_face_concealed_for_shroud()
	if(wear_mask && (wear_mask.flags_inv & HIDEFACE))
		return TRUE
	if(head && (head.flags_inv & HIDEFACE))
		return TRUE
	if(wear_neck && (wear_neck.flags_inv & HIDEFACE))
		return TRUE
	return FALSE
