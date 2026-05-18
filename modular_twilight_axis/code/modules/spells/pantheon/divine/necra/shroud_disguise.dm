/datum/status_effect/tranquility_shroud/proc/uses_deadite_mask()
	return mask_active && shroud_mode == TRANQUILITY_SHROUD_MODE_DEADITE

/datum/status_effect/tranquility_shroud/proc/uses_vampire_mask()
	return mask_active && shroud_mode == TRANQUILITY_SHROUD_MODE_VAMPIRE

/datum/status_effect/tranquility_shroud/proc/apply_shroud_disguise()
	if(QDELETED(owner) || !mask_active)
		return
	grant_undead_faction()
	if(uses_deadite_mask())
		grant_deadite_traits()
	if(ishuman(owner) && (uses_deadite_mask() || uses_vampire_mask()))
		apply_skin_disguise()

/datum/status_effect/tranquility_shroud/proc/remove_shroud_disguise()
	if(granted_undead_faction)
		release_undead_faction()
	if(granted_norun_trait)
		release_norun_trait()
	if(granted_zombie_immune_trait)
		release_zombie_immune_trait()
	if(granted_rotman_trait)
		release_rotman_trait()
	if(granted_zombie_speech_trait)
		release_zombie_speech_trait()
	if(ishuman(owner))
		restore_skin_appearance()

/datum/status_effect/tranquility_shroud/proc/grant_undead_faction()
	if(QDELETED(owner) || granted_undead_faction)
		return
	if(!owner.faction)
		owner.faction = list()
	if(FACTION_UNDEAD in owner.faction)
		return
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

/datum/status_effect/tranquility_shroud/proc/grant_deadite_traits()
	grant_norun_trait()
	grant_zombie_immune_trait()
	grant_rotman_trait()
	grant_zombie_speech_trait()

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

/datum/status_effect/tranquility_shroud/proc/grant_zombie_immune_trait()
	if(QDELETED(owner) || granted_zombie_immune_trait)
		return
	if(!HAS_TRAIT_FROM(owner, TRAIT_ZOMBIE_IMMUNE, TRANQUILITY_SHROUD_TRAIT_SOURCE))
		ADD_TRAIT(owner, TRAIT_ZOMBIE_IMMUNE, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_zombie_immune_trait = TRUE

/datum/status_effect/tranquility_shroud/proc/release_zombie_immune_trait()
	if(!granted_zombie_immune_trait)
		return
	if(owner && !QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_ZOMBIE_IMMUNE, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_zombie_immune_trait = FALSE

/datum/status_effect/tranquility_shroud/proc/grant_rotman_trait()
	if(QDELETED(owner) || granted_rotman_trait)
		return
	if(!HAS_TRAIT_FROM(owner, TRAIT_ROTMAN, TRANQUILITY_SHROUD_TRAIT_SOURCE))
		ADD_TRAIT(owner, TRAIT_ROTMAN, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_rotman_trait = TRUE

/datum/status_effect/tranquility_shroud/proc/release_rotman_trait()
	if(!granted_rotman_trait)
		return
	if(owner && !QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_ROTMAN, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_rotman_trait = FALSE

/datum/status_effect/tranquility_shroud/proc/grant_zombie_speech_trait()
	if(QDELETED(owner) || granted_zombie_speech_trait)
		return
	if(!HAS_TRAIT_FROM(owner, TRAIT_ZOMBIE_SPEECH, TRANQUILITY_SHROUD_TRAIT_SOURCE))
		ADD_TRAIT(owner, TRAIT_ZOMBIE_SPEECH, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_zombie_speech_trait = TRUE

/datum/status_effect/tranquility_shroud/proc/release_zombie_speech_trait()
	if(!granted_zombie_speech_trait)
		return
	if(owner && !QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_ZOMBIE_SPEECH, TRANQUILITY_SHROUD_TRAIT_SOURCE)
	granted_zombie_speech_trait = FALSE

/datum/status_effect/tranquility_shroud/proc/apply_skin_disguise()
	var/mob/living/carbon/human/H = owner
	if(!H || cached_appearance)
		return
	cached_appearance = list(
		"skin_tone" = H.skin_tone,
		"original_skin_tone" = H.original_skin_tone,
	)
	if(uses_vampire_mask())
		H.original_skin_tone = H.skin_tone
		H.skin_tone = TRANQUILITY_SHROUD_VAMPIRE_SKIN
		to_chat(H, span_notice("My skin grows pale and cold, like a newly turned vampire."))
		H.update_body()
		return
	if(uses_deadite_mask())
		H.original_skin_tone = H.skin_tone
		H.skin_tone = TRANQUILITY_SHROUD_DEADITE_SKIN
		to_chat(H, span_notice("My skin takes on a greenish, zombie pallor."))
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
		vampire_sunlit = FALSE
		return
	if(QDELETED(owner) || owner.stat == DEAD)
		vampire_sunlit = FALSE
		return
	if(GLOB.tod != "day")
		if(vampire_sunlit)
			to_chat(owner, span_notice("The scorching gaze of the Sun-Tyrant burns me no more."))
		vampire_sunlit = FALSE
		return
	if(!ishuman(owner))
		vampire_sunlit = FALSE
		return
	var/mob/living/carbon/human/H = owner
	if(H.advsetup || !isturf(H.loc))
		vampire_sunlit = FALSE
		return
	var/turf/loc_turf = H.loc
	if(!loc_turf.can_see_sky())
		if(vampire_sunlit)
			to_chat(H, span_notice("The scorching gaze of the Sun-Tyrant burns me no more."))
		vampire_sunlit = FALSE
		return
	if(HAS_TRAIT(H, TRAIT_WEATHER_PROTECTED))
		if(!vampire_sunlit)
			to_chat(H, span_danger("I am shielded from the Sun-Tyrant's scorn."))
		vampire_sunlit = TRUE
		return
	if(!vampire_sunlit)
		to_chat(H, span_danger("The sunlight burns my flesh!"))
	vampire_sunlit = TRUE
	H.fire_act(1, TRANQUILITY_SHROUD_SUN_BURN_DAMAGE)
	if(H.on_fire)
		addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/carbon, freak_out)), 0, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/carbon/human/proc/is_face_concealed_for_shroud()
	if(wear_mask && (wear_mask.flags_inv & HIDEFACE))
		return TRUE
	if(head && (head.flags_inv & HIDEFACE))
		return TRUE
	if(wear_neck && (wear_neck.flags_inv & HIDEFACE))
		return TRUE
	return FALSE
