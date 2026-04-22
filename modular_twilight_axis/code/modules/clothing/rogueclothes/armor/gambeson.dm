/obj/item/clothing/suit/roguetown/armor/gambeson/steward
	name = "steward tailcoat"
	desc = "A thick, pristine leather tailcoat adorned with polished bronze buttons."
	sleeved = 'modular_twilight_axis/icons/roguetown/clothing/special/onmob/noble.dmi'
	icon_state = "stewardtailcoat"
	item_state = "stewardtailcoat"
	icon = 'modular_twilight_axis/icons/roguetown/clothing/special/noble.dmi'
	mob_overlay_icon = 'modular_twilight_axis/icons/roguetown/clothing/special/onmob/noble.dmi'

/obj/item/clothing/suit/roguetown/armor/regenerating/baotha
	name = "masquerade"
	desc = "writhing rags, woven from mutilated human faces, in constant agony intertwined with narcotic ecstasy. They say the previous owner of this item has gone missing, but where?.. And whos saying that?.."
	slot_flags = ITEM_SLOT_SHIRT|ITEM_SLOT_ARMOR
	icon = 'modular_twilight_axis/icons/roguetown/clothing/shirts.dmi'
	mob_overlay_icon = 'modular_twilight_axis/icons/roguetown/clothing/onmob/shirts.dmi'
	icon_state = "skinrobe"
	item_state = "skinrobe"
	body_parts_covered = FULL_BODY
	body_parts_inherent = FULL_BODY
	salvage_result = /obj/item/reagent_containers/lux
	max_integrity = ARMOR_INT_CHEST_PLATE_BRIGANDINE + 200
	armor = ARMOR_BRIGANDINE
	allowed_race = NON_DWARVEN_RACE_TYPES
	auto_repair_mode = TRUE
	relative_repair_interval = 15 SECONDS
	interrupt_damount = 15
	var/realname
	var/realdesc
	var/realstate
	var/realicon
	var/realmob

/obj/item/clothing/suit/roguetown/armor/regenerating/baotha/Initialize()
	.=..()
	realname = name
	realdesc = desc
	realstate = icon_state
	realicon = icon
	realmob = mob_overlay_icon
	AddComponent(/datum/component/cursed_item, TRAIT_CRACKHEAD, "CLOTH")

/obj/item/clothing/suit/roguetown/armor/regenerating/baotha/examine(var/mob/living/carbon/human/user)
	. = ..()
	if(iscarbon(user))
		var/mob/living/carbon/c = user
		if(user.patron.type == /datum/patron/inhumen/baotha)
			. += ("This creature is a small gift from my patron, and I can make it take any form I desire.")

/obj/item/clothing/suit/roguetown/armor/regenerating/baotha/attack_right(var/mob/living/carbon/human/user)
	if(user.patron.type == /datum/patron/inhumen/baotha)
		var/mimicry = list("shirt", "formal silks", "rags", "tunic", "dress", "silky dress", "undervestments", "royal gown", "white foreign shirt", "silk shirt", "fancy coat", "low cut tunic", "pristine dress", "gilded dress shirt", "Undo")
		var/mimicry_choise = input("Variants:", "camouflage") as anything in mimicry
		switch(mimicry_choise)
			if("shirt")
				name = "shirt"
				desc = "Modest and humble. It lets you walk around in public with your dignity intact."
				icon_state = "undershirt"
				mimic()
			if("formal silks")
				name = "formal silks"
				desc = "Modest and humble. It lets you walk around in public with your dignity intact."
				icon_state = "puritan_shirt"
				mimic()
			if("rags")
				name = "rags"
				desc = "From rags to... nope, still rags."
				icon_state = "rags"
				mimic()
			if("tunic")
				name = "tunic"
				desc = "Modest and fashionable, with the right colors."
				icon_state = "tunic"
				mimic()
			if("dress")
				name = "dress"
				desc = "A simple dress worn by women and the bold."
				icon_state = "dress"
				mimic()
			if("silky dress")
				name = "silky dress"
				desc = "Despite not actually being made of silk, the legendary expertise needed to sew this puts the quality on par."
				icon_state = "silkydress"
				mimic()
			if("undervestments")
				name = "undervestments"
				desc = "A soft garment designed to prevent chafing from wearing heavy robes all dae and night."
				icon_state = "priestunder"
				mimic()
			if("royal gown")
				name = "royal gown"
				desc = "An elaborate ball gown, a favoured fashion of queens and elevated nobility in Enigma."
				icon_state = "royaldress"
				mimic()
			if("white foreign shirt")
				name = "white foreign shirt"
				desc = "A shirt typically used by foreign gangs."
				icon_state = "eastshirt1"
				mimic()
			if("silk shirt")
				name = "silk shirt"
				desc = "A sleeveless shirt woven from glossy material."
				icon_state = "webs"
				mimic()
			if("fancy coat")
				name = "fancy coat"
				desc = "A fancy tunic and coat combo. How elegant."
				icon_state = "noblecoat"
				mimic()
			if("low cut tunic")
				name = "low cut tunic"
				desc = "A tunic exposing much of the neck and... shoulders?! How scandalous..."
				icon_state = "lowcut"
				mimic()
			if("pristine dress")
				name = "pristine dress"
				desc = "A flowy, intricate dress made by the finest tailors in the land for the monarch's children."
				icon_state = "princess"
			if("gilded dress shirt")
				name = "gilded dress shirt"
				desc = "A gold-embroidered dress shirt specially tailored for the monarch's children."
				icon_state = "prince"
			if("Undo")
				name = realname
				desc = realdesc
				icon = realicon
				icon_state = realstate
				mob_overlay_icon = realmob
				if(icon_state != realstate)
					armor = ARMOR_BRIGANDINE
					AddComponent(/datum/component/cursed_item, TRAIT_CRACKHEAD, "CLOTH")
		if(icon_state != realstate)
			armor = ARMOR_PADDED
			qdel(GetComponent(/datum/component/cursed_item))
		playsound(user, pick('sound/magic/magic_nulled.ogg'), 20, TRUE)

/obj/item/clothing/suit/roguetown/armor/regenerating/baotha/proc/mimic()
	icon = 'icons/roguetown/clothing/shirts.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/shirts.dmi'
