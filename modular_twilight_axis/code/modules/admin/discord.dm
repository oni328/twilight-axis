/datum/config_entry/string/admin_bans_channel
	default = null

/datum/config_entry/string/admin_notes_channel
	default = null

/// Отправляет средствами TGS сообщение о блокировке игрока или его ролей.
/world/proc/TgsAnnounceBan(player_ckey, admin_ckey, duration, time_message, roles, reason, severity, applies_to_admins)
	if(!TgsAvailable())
		return

	var/admin_bans_channel = CONFIG_GET(string/admin_bans_channel)

	if(!admin_bans_channel)
		return

	var/severity_dict = list(
		"high" = "высокая",
		"medium" = "средняя",
		"minor" = "малая",
		"none" = "none",
	)

	var/is_role_ban = roles[1] != "Server"

	var/title = is_role_ban ? "Бан ролей!" : "Бан!"
	var/description = "Игрок теряет возможность играть на сервере."

	if(is_role_ban)
		description = "Игрок теряет указанные роли:\n"
		for(var/role_name in roles)
			description += "- [role_name]\n"

	description += "\n"

	var/localized_severity = severity_dict[lowertext(severity)]
	if(localized_severity != "none")
		description += "**Тяжесть наказания:** [localized_severity]\n"

	description += "**Срок наказания:** [duration ? time_message : "*НАВСЕГДА*"]"

	if(applies_to_admins)
		description += "\n*Применено к администратору*"

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = title
	embed.description = description
	embed.colour = "#ed8796"
	embed.footer = new(GLOB.rogue_round_id)

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[player_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_admin_ckey = new(
		"Администратор", "`[admin_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_reason = new(
		"Причина", "[reason]"
	)

	field_player_ckey.is_inline = TRUE
	field_admin_ckey.is_inline = TRUE
	field_reason.is_inline = FALSE

	embed.fields = list(
		field_player_ckey,
		field_admin_ckey,
		field_reason,
	)

	send2chat(
		message,
		admin_bans_channel
	)

/// Отправляет средствами TGS сообщение в дискорд об изменении PQ игрока.
/world/proc/TgsAnnouncePQChanges(value, player_ckey, admin_ckey, reason)
	if(!TgsAvailable())
		return

	var/admin_notes_channel = CONFIG_GET(string/admin_notes_channel)

	if(!admin_notes_channel)
		return

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = "Изменение PQ!"
	embed.description = "```diff\n[value > 0 ? "+[value]" : "-[value]"]\n```"
	embed.colour = value > 0 ? "#a6da95" : "#ed8796"
	embed.footer = new(GLOB.rogue_round_id)

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[player_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_admin_ckey = new(
		"Администратор", "`[admin_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_reason = new(
		"Причина", "[reason]"
	)

	field_player_ckey.is_inline = TRUE
	field_admin_ckey.is_inline = TRUE
	field_reason.is_inline = FALSE

	embed.fields = list(
		field_player_ckey,
		field_admin_ckey,
		field_reason,
	)

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	send2chat(
		message,
		admin_notes_channel
	)
