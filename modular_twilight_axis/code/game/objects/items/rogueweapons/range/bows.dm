/datum/special_intent/bow_doubleshot
	name = "Двойной выстрел"
	desc = "Моментально выпускает вторую стрелу из колчана вслед за первой."
	use_clickloc = TRUE
	respect_adjacency = FALSE
	range = 14
	delay = 0
	use_doafter = 1 SECONDS
	cooldown = 15 SECONDS
	stamcost = 25
	custom_skill = /datum/skill/combat/bows
	var/atom/actual_target

/datum/special_intent/bow_doubleshot/deploy(mob/living/user, atom/parent, atom/target)
	actual_target = target
	return ..()

/datum/special_intent/bow_doubleshot/process_attack()
	var/obj/item/gun/ballistic/revolver/grenadelauncher/bow/B = iparent
	if(!istype(B))
		return
	if(!B.chambered)
		to_chat(howner, span_warning("Сначала нужно вложить первую стрелу!"))
		return

	to_chat(howner, span_warning("Вы готовитесь выпустить две стрелы подряд..."))
	playsound(howner, pick('sound/combat/Ranged/bow-draw-01.ogg'), 100, FALSE)

	if(!_do_after())
		return

	var/atom/target_atom = actual_target
	

	var/old_charge = 0
	if(howner.client)
		old_charge = howner.client.chargedprog
		howner.client.chargedprog = 100 

	B.process_fire(target_atom, howner)

	if(howner.client)
		howner.client.chargedprog = old_charge


	addtimer(CALLBACK(src, PROC_REF(fire_second_arrow), B, target_atom), 2)
	apply_cooldown(cooldown)

/datum/special_intent/bow_doubleshot/proc/fire_second_arrow(obj/item/gun/ballistic/revolver/grenadelauncher/bow/B, atom/target_atom)
	if(!howner || howner.stat || howner.incapacitated()) 
		return
	if(!B || B.loc != howner) 
		return

	var/obj/item/ammo_casing/caseless/rogue/found_arrow
	var/obj/item/quiver/used_quiver
	
	for(var/obj/item/quiver/Q in howner.contents)
		if(length(Q.arrows))
			found_arrow = Q.pick_ammo(/obj/item/ammo_casing/caseless/rogue/arrow)
			if(found_arrow)
				used_quiver = Q
				break

	if(!found_arrow || !used_quiver)
		to_chat(howner, span_warning("В колчане не оказалось стрелы для второго выстрела!"))
		return

	used_quiver.arrows -= found_arrow
	used_quiver.update_icon()

	B.chambered = found_arrow
	found_arrow.forceMove(B)

	var/old_charge = 0
	if(howner.client)
		old_charge = howner.client.chargedprog
		howner.client.chargedprog = 100

	B.process_fire(target_atom, howner)

	if(howner.client)
		howner.client.chargedprog = old_charge

/datum/special_intent/bow_longshot
	name = "Дальнобойный выстрел"
	desc = "Тщательное прицеливание. Чем дальше цель, тем больше урон."
	use_clickloc = TRUE
	respect_adjacency = FALSE
	range = 25
	delay = 0
	use_doafter = 1.5 SECONDS
	cooldown = 20 SECONDS
	stamcost = 30
	custom_skill = /datum/skill/combat/bows
	var/atom/actual_target 

/datum/special_intent/bow_longshot/deploy(mob/living/user, atom/parent, atom/target)
	actual_target = target
	return ..()

/datum/special_intent/bow_longshot/process_attack()
	var/obj/item/gun/ballistic/revolver/grenadelauncher/bow/B = iparent
	if(!istype(B))
		return
	if(!B.chambered)
		to_chat(howner, span_warning("Сначала нужно вложить стрелу!"))
		return

	to_chat(howner, span_warning("Вы тщательно прицеливаетесь вдаль..."))
	playsound(howner, pick('sound/combat/Ranged/bow-draw-01.ogg'), 100, FALSE)

	if(!_do_after())
		return

	var/atom/target_atom = actual_target 
	var/dist = get_dist(howner, target_atom)
	

	var/dmg_mult = 1.0 + (min(dist, 25) * 0.2)

	var/old_charge = 0
	var/old_damfactor = B.damfactor
	
	if(howner.client)
		old_charge = howner.client.chargedprog
		howner.client.chargedprog = 100 


	var/obj/projectile/proj = B.chambered.BB
	if(istype(proj))
		proj.range = 30 
		proj.max_range = 30 


	B.damfactor *= dmg_mult


	B.process_fire(target_atom, howner)


	if(howner.client)
		howner.client.chargedprog = old_charge
	B.damfactor = old_damfactor

	apply_cooldown(cooldown)
