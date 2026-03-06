/obj/item/clothing/head/roguetown/bucklehat/gunslinger
	name = "gunslinger's hat"

/obj/item/clothing/head/roguetown/duelhat/gunslinger
	name = "dragoon's hat"

/obj/item/clothing/head/roguetown/helmet/tricorn/grenzel
	name = "reichsmarine tricorn"
	desc = "Grenzelhoft rules the waves of ten seas. Often worn by crewmen and officers of the Imperial Navy, this hat also features a metallic cap, enhancing its protective properties."
	max_integrity = ARMOR_INT_HELMET_LEATHER
	body_parts_covered = HEAD|HAIR|EARS
	prevent_crits = PREVENT_CRITS_MOST
	armor = ARMOR_SPELLSINGER

/obj/item/clothing/head/roguetown/inqcap
	name = "inquisitorial cap"
	desc = "A crisply tailored leather cap, edged with subtle piping and fitted with a small hidden steel plate. Less ornate than the ceremonial slouch, it prioritizes discipline and practicality while still carrying the unmistakable mark of the Holy Otavan Inquisition. </br>'Keep your gaze on the duty at hand, not the heavens above.'"
	icon = 'modular_twilight_axis/firearms/icons/obj_head.dmi'
	mob_overlay_icon = 'modular_twilight_axis/firearms/icons/onmob_head.dmi'
	icon_state = "inqcap"
	item_state = "inqcap"
	max_integrity = 200
	armor = ARMOR_SPELLSINGER
	body_parts_covered = HEAD|HAIR|EARS
	prevent_crits = PREVENT_CRITS_MOST
	sewrepair = TRUE
	resistance_flags = FIRE_PROOF

/obj/item/clothing/head/roguetown/inqsack
	name = "sack hood"
	icon = 'modular_twilight_axis/firearms/icons/obj_head.dmi'
	mob_overlay_icon = 'modular_twilight_axis/firearms/icons/onmob_head.dmi'
	icon_state = "inqsack"
	item_state = "inqsack"
	blocksound = SOFTHIT
	break_sound = 'sound/foley/cloth_rip.ogg'
	drop_sound = 'sound/foley/dropsound/cloth_drop.ogg'
	max_integrity = 200
	prevent_crits = list(BCLASS_BLUNT)
	slot_flags = ITEM_SLOT_HEAD|ITEM_SLOT_MASK
	flags_inv = HIDEFACE|HIDESNOUT|HIDEHAIR|HIDEEARS
	body_parts_covered = FACE|HEAD
	armor = ARMOR_PADDED 
	sewrepair = TRUE
	resistance_flags = FIRE_PROOF
