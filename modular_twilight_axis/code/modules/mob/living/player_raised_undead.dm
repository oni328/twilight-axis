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

/mob/living/proc/ta_mark_player_raised_undead(mob/living/raiser)
	if(!raiser)
		return FALSE
	if(raiser.mind?.current)
		summoner = raiser.mind.current.real_name
	else
		summoner = raiser.name
	return TRUE
