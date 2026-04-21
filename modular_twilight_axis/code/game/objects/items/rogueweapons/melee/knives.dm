/datum/intent/dagger/chop/necra
	damfactor = 1.2
	intent_intdamage_factor = 1.35 // I HAVE NO PICK BUT I MUST KILL
	swingdelay = 10
	clickcd = 10
	penfactor = 30

/datum/intent/dagger/cut/dendor // me like cut
	damfactor = 1.1
	clickcd = 8

/datum/intent/dagger/thrust/dendor // me no like stab
	damfactor = 0.8

/datum/intent/dagger/thrust/pick/abyssor
	damfactor = 1.2

/datum/intent/dagger/thrust/malum // hits slower but harder slight DPM buff
	damfactor = 1.3
	clickcd = 10

/obj/item/rogueweapon/huntingknife/idagger/steel/devilsknife
	name ="devilsknife"
	desc = "More a sickle than a knife. It is said that Xylix once won these in a game of chance against an archdevil. These are simple reproductions, with jingling bells attached to the blades."
	icon_state = "devilsknife"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	force = 22 // 10% - This is a 8 clickCD weapon
	max_integrity = 200

/obj/item/rogueweapon/huntingknife/throwingknife/steel/noc
	name = "twilight fang"
	desc = "Large tossblade meant for both fighting and throwing. Perfect for striking from the shadows of Noc."
	item_state = "bone_dagger"
	possible_item_intents = list(/datum/intent/dagger/thrust, /datum/intent/dagger/cut, /datum/intent/dagger/thrust/pick, /datum/intent/dagger/sucker_punch)
	force = 21
	throwforce = 28
	throw_speed = 4
	max_integrity = 200
	armor_penetration = 40
	icon_state = "noc_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	embedding = list("embedded_pain_multiplier" = 4, "embed_chance" = 30, "embedded_fall_chance" = 5)

/obj/item/rogueweapon/huntingknife/idagger/steel/astrata
	name ="dawnbringer"
	desc = "A blade forged in the name of Astrata herself. It glistens under the light reminding your foes what is coming."
	icon_state = "astrata_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	force = 22
	max_integrity = 200

/obj/item/rogueweapon/huntingknife/idagger/steel/parrying/eora
	name = "misericorde"
	icon_state = "eora_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	force = 10
	throwforce = 10
	desc = "A parrying dagger created to be used in the free hand and deliver mercy to the foes you've bested."
	sheathe_icon = "spdagger"
	wdefense = 9 // Eoran rapier has 8 def so I had to bump it to 9 in order to parry with a dagger
	max_integrity = 200

/obj/item/rogueweapon/huntingknife/idagger/steel/ravox
	name ="echo of triumph"
	desc = "Once, it was a greatsword wielded by the chosen of Ravox. After centuries of battles, the blade finally broke. However, the remaining pieces were reforged into a dagger that reminds battles of the past."
	icon_state = "ravox_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	force = 22
	max_integrity = 200

/obj/item/rogueweapon/huntingknife/idagger/steel/abyssor
	name ="darkwater ripper"
	desc = "Fierce dagger quenched in the abyssal depths. If you listen closely, you can hear the clashing of waves during high tide."
	icon_state = "abyssor_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	possible_item_intents = list(/datum/intent/dagger/thrust, /datum/intent/dagger/cut, /datum/intent/dagger/thrust/pick/abyssor, /datum/intent/dagger/sucker_punch)
	force = 22
	max_integrity = 200

/obj/item/rogueweapon/huntingknife/idagger/steel/dendor
	name ="maddening thorn"
	desc = "Simple yet wickedly sharp blade fixed to the handle grown whole. The hilt is covered by tiny prickly thorns that slowly madden the wielder."
	icon_state = "dendor_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	possible_item_intents = list(/datum/intent/dagger/thrust/dendor, /datum/intent/dagger/cut/dendor, /datum/intent/dagger/thrust/pick, /datum/intent/dagger/sucker_punch)
	force = 22
	max_integrity = 200

/obj/item/rogueweapon/huntingknife/idagger/steel/malum
	name ="embertongue"
	desc = "Wavy flamelike blade forged in the name of Malum himself."
	icon_state = "malum_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	possible_item_intents = list(/datum/intent/dagger/thrust/malum, /datum/intent/dagger/cut, /datum/intent/dagger/thrust/pick, /datum/intent/dagger/sucker_punch)
	force = 22
	wdefense = 2
	max_integrity = 200

/obj/item/rogueweapon/huntingknife/idagger/steel/necra
	name ="osteotome"
	desc = "A macabre cleaver. The hilt is made from a humen spine reinforced with a steel tang."
	icon_state = "necra_dagger"
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	possible_item_intents = list(/datum/intent/dagger/cut, /datum/intent/dagger/chop/necra) // chop chop chop
	force = 23
	max_integrity = 200
	smeltresult = /obj/item/ingot/silver
	is_silver = TRUE

/obj/item/rogueweapon/huntingknife/idagger/steel/necra/ComponentInitialize()
	AddComponent(\
		/datum/component/silverbless,\
		pre_blessed = BLESSING_TENNITE,\
		silver_type = SILVER_TENNITE,\
		added_force = 0,\
		added_blade_int = 50,\
		added_int = 50,\
		added_def = 2,\
	)

/obj/item/rogueweapon/huntingknife/idagger/steel/baotha
	name = "змеиное жало"
	desc = "Искуссно выполненный клинок, кажется предназначенный для скрытых убийств. На его лезвии заметны подтёки какой-то пузырящейся субстанции."
	icon = 'modular_twilight_axis/icons/roguetown/weapons/32.dmi'
	icon_state = "baotha_knife1"
	max_blade_int = 300
	throwforce = 40
	force = 25
	wdefense = 4

/obj/item/rogueweapon/huntingknife/idagger/steel/baotha/Initialize()
	. = ..()
	icon_state = "baotha_knife1"
	AddComponent(/datum/component/cursed_item, TRAIT_CRACKHEAD, "KNIFE")

/obj/item/rogueweapon/huntingknife/idagger/steel/baotha/attack_self(var/mob/living/carbon/human/user)
	if(user.patron.type == /datum/patron/inhumen/baotha)
		if(do_after(user, 10, target = src))
			var/obj/item/clothing/ring/baotha/S = new/obj/item/clothing/ring/baotha(get_turf(src.loc))
			if(user.is_holding(src))
				user.dropItemToGround(src)
				user.put_in_hands(S)
			qdel(src)
			playsound(user, pick('sound/magic/magic_nulled.ogg'), 20, TRUE)
		else
			to_chat(user, "<span class='notice'>I losing concentration!</span>")

/obj/item/rogueweapon/huntingknife/idagger/steel/baotha/pre_attack(mob/living/carbon/human/target, mob/living/user = usr, params)
	if(!istype(target))
		return FALSE
	var/list/drugs = list(/datum/reagent/ozium,
						/datum/reagent/moondust,
						/datum/reagent/corps_dust,
						/datum/reagent/smartium)
	var/random_drug = pick(drugs)
	target.reagents.add_reagent(random_drug, 2)
	return FALSE
