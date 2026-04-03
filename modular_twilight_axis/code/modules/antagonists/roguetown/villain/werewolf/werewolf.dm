/obj/item/rogueweapon/werewolf_claw/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(!proximity_flag || !ishuman(target) || !ishuman(user))
		return
	
	var/mob/living/carbon/human/H_target = target
	var/mob/living/carbon/human/H_user = user

	if(H_target.mind && H_target.mind.has_antag_datum(/datum/antagonist/werewolf))
		return
	
	if(!user.mind || !user.mind.has_antag_datum(/datum/antagonist/werewolf))
		return

	var/infected_successfully = FALSE
	for(var/obj/item/bodypart/BP in H_target.bodyparts)
		for(var/datum/wound/W in BP.wounds)
			if(istype(W, /datum/wound/artery))
				infected_successfully = TRUE
				break
			
			if(istype(W, /datum/wound/dynamic/slash)|| istype(W, /datum/wound/dynamic/bite))
				if(prob(15))
					infected_successfully = TRUE
					break
		
		if(infected_successfully)
			break

	if(infected_successfully)
		var/datum/antagonist/werewolf/wolfy = H_target.werewolf_check()
		if(wolfy)
			to_chat(H_user, span_boldnotice("My essence has taken root in [H_target]! I have successfully infected them."))

			to_chat(H_target, span_userdanger("I feel horrible... REALLY horrible..."))
			H_target.vomit(1, blood = TRUE)
			H_target.emote("scream")
			H_target.Knockdown(20)
