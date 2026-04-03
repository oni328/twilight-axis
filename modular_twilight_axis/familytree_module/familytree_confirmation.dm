/datum/controller/subsystem/familytree/proc/offer_setspouse_reset(mob/living/carbon/human/H, status)
	if(!H?.client)
		return
	var/result = tgui_alert(H, "Вы уже 30 минут ожидаете фаворита '[H.setspouse]', но он не найден.\n\nХотите сбросить предпочтение по нику и искать пару по текущим настройкам?", "Семейная система", list("Да, сбросить", "Нет, продолжить ждать"))

	if(!H || QDELETED(H))
		return

	if(result == "Да, сбросить")
		ftlog("SETSPOUSE RESET: [H.real_name] cleared setspouse '[H.setspouse]'")
		H.setspouse = ""
		H.familytree_assignment_scheduled = FALSE
		run_local_assignment(H, status)
	else
		ftlog("SETSPOUSE KEEP: [H.real_name] continues waiting for '[H.setspouse]'")
		H.familytree_assignment_scheduled = TRUE
		addtimer(CALLBACK(src, PROC_REF(run_local_assignment), H, status), 60 SECONDS)

#define MUTUAL_CONFIRM_TIMEOUT 60 SECONDS
#define CONFIRM_PENDING 0
#define CONFIRM_ACCEPTED 1
#define CONFIRM_REJECTED 2
#define CONFIRM_TIMEOUT 3

/datum/family_confirm_session
	var/mob/living/carbon/human/person_a
	var/mob/living/carbon/human/person_b
	var/datum/callback/on_both_accept
	var/confirm_type
	var/result_a = CONFIRM_PENDING
	var/result_b = CONFIRM_PENDING
	var/resolved = FALSE
	var/timerid

/datum/family_confirm_session/New(mob/living/carbon/human/a, mob/living/carbon/human/b, datum/callback/cb, ctype)
	person_a = a
	person_b = b
	on_both_accept = cb
	confirm_type = ctype

/datum/family_confirm_session/Destroy()
	if(timerid)
		deltimer(timerid)
	person_a = null
	person_b = null
	on_both_accept = null
	return ..()

/datum/family_confirm_session/proc/check_resolution()
	if(resolved)
		return

	if(result_a == CONFIRM_REJECTED || result_a == CONFIRM_TIMEOUT || result_b == CONFIRM_REJECTED || result_b == CONFIRM_TIMEOUT)
		resolved = TRUE
		if(timerid)
			deltimer(timerid)
		if(result_a == CONFIRM_REJECTED || result_a == CONFIRM_TIMEOUT)
			handle_refusal(person_a, person_b)
		if(result_b == CONFIRM_REJECTED || result_b == CONFIRM_TIMEOUT)
			handle_refusal(person_b, person_a)
		if(result_a != CONFIRM_REJECTED && result_a != CONFIRM_TIMEOUT)
			notify_cancelled(person_a)
		if(result_b != CONFIRM_REJECTED && result_b != CONFIRM_TIMEOUT)
			notify_cancelled(person_b)
		qdel(src)
		return

	if(result_a == CONFIRM_PENDING || result_b == CONFIRM_PENDING)
		return

	resolved = TRUE
	if(timerid)
		deltimer(timerid)

	if(result_a == CONFIRM_ACCEPTED && result_b == CONFIRM_ACCEPTED)
		SSfamilytree.ftlog("MUTUAL CONFIRM: both accepted type=[confirm_type] a=[person_a?.real_name] b=[person_b?.real_name]")
		on_both_accept?.Invoke()

	qdel(src)

/datum/family_confirm_session/proc/handle_refusal(mob/living/carbon/human/refuser, mob/living/carbon/human/other)
	if(!refuser || QDELETED(refuser))
		return
	var/reason = "declined"
	if((refuser == person_a ? result_a : result_b) == CONFIRM_TIMEOUT)
		reason = "timeout"
	SSfamilytree.ftlog("MUTUAL CONFIRM: [refuser.real_name] [reason] type=[confirm_type]")
	refuser.familytree_opted_out = TRUE
	SSfamilytree.unsubscribe_familytree_human(refuser, "player [reason] [confirm_type]")
	to_chat(refuser, span_warning("Вы отказались от участия в семейной системе на этот раунд."))

/datum/family_confirm_session/proc/force_timeout()
	if(resolved)
		return
	if(result_a == CONFIRM_PENDING)
		result_a = CONFIRM_TIMEOUT
	if(result_b == CONFIRM_PENDING)
		result_b = CONFIRM_TIMEOUT
	check_resolution()

/datum/family_confirm_session/proc/notify_cancelled(mob/living/carbon/human/person)
	if(!person || QDELETED(person))
		return
	SSfamilytree.ftlog("MUTUAL CONFIRM: [person.real_name] cancelled (other side refused) type=[confirm_type]")
	to_chat(person, span_warning("Другая сторона отказалась от вступления в семью. Ваш запрос отменён. Система попробует найти вам новую пару."))
	if(!person.familytree_opted_out && !person.family_datum && !person.spouse_mob && person.familytree_pref && person.familytree_pref != FAMILY_NONE)
		person.familytree_assignment_scheduled = TRUE
		addtimer(CALLBACK(SSfamilytree, TYPE_PROC_REF(/datum/controller/subsystem/familytree, run_local_assignment), person, person.familytree_pref), 10 SECONDS)

/datum/controller/subsystem/familytree/proc/request_family_confirmation(mob/living/carbon/human/H, datum/callback/on_accept, confirm_type = "family")
	if(H?.familytree_opted_out)
		ftlog("CONFIRM SKIP: [H?.real_name] opted out")
		return
	if(!H?.client)
		on_accept.Invoke()
		return
	INVOKE_ASYNC(src, PROC_REF(do_solo_confirmation), H, on_accept, confirm_type)

/datum/controller/subsystem/familytree/proc/do_solo_confirmation(mob/living/carbon/human/H, datum/callback/on_accept, confirm_type)
	if(!H?.client)
		on_accept.Invoke()
		return

	to_chat(H, span_love("Система нашла для вас семью!"))

	var/result = tgui_alert(H, "Вам нашли пару!\n\nХотите продолжить?\n\nЕсли вы не сделаете выбор — он будет засчитан как отказ.\nОтказавшись, вы потеряете возможность найти семью в этом раунде.", "Семейная система", list("Да", "Нет"), 60 SECONDS)

	if(!H || QDELETED(H))
		return

	if(result == "Да")
		ftlog("CONFIRM ACCEPT: [H.real_name] type=[confirm_type]")
		on_accept.Invoke()
	else
		ftlog("CONFIRM REJECT: [H.real_name] type=[confirm_type] result=[result || "timeout"]")
		to_chat(H, span_warning("Вы отказались от участия в семейной системе на этот раунд."))
		H.familytree_opted_out = TRUE
		unsubscribe_familytree_human(H, "player declined [confirm_type]")

/datum/controller/subsystem/familytree/proc/request_mutual_confirmation(mob/living/carbon/human/person_a, mob/living/carbon/human/person_b, datum/callback/on_both_accept, confirm_type = "family")
	if(person_a?.familytree_opted_out || person_b?.familytree_opted_out)
		ftlog("MUTUAL SKIP: opted out a=[person_a?.real_name] b=[person_b?.real_name]")
		return

	if(!person_a?.client && !person_b?.client)
		on_both_accept.Invoke()
		return
	if(!person_a?.client)
		INVOKE_ASYNC(src, PROC_REF(do_solo_confirmation), person_b, on_both_accept, confirm_type)
		return
	if(!person_b?.client)
		INVOKE_ASYNC(src, PROC_REF(do_solo_confirmation), person_a, on_both_accept, confirm_type)
		return

	var/datum/family_confirm_session/session = new(person_a, person_b, on_both_accept, confirm_type)
	session.timerid = addtimer(CALLBACK(session, TYPE_PROC_REF(/datum/family_confirm_session, force_timeout)), MUTUAL_CONFIRM_TIMEOUT, TIMER_STOPPABLE)

	ftlog("MUTUAL CONFIRM: started type=[confirm_type] a=[person_a.real_name] b=[person_b.real_name]")

	INVOKE_ASYNC(src, PROC_REF(do_mutual_ask), session, person_a, TRUE)
	INVOKE_ASYNC(src, PROC_REF(do_mutual_ask), session, person_b, FALSE)

/datum/controller/subsystem/familytree/proc/do_mutual_ask(datum/family_confirm_session/session, mob/living/carbon/human/person, is_person_a)
	if(!person?.client || session.resolved)
		return

	to_chat(person, span_love("Система нашла для вас семью!"))

	var/result = tgui_alert(person, "Вам нашли пару!\n\nХотите продолжить?\n\nЕсли вы не сделаете выбор — он будет засчитан как отказ.\nОтказавшись, вы потеряете возможность найти семью в этом раунде.", "Семейная система", list("Да", "Нет"), 60 SECONDS)

	if(session.resolved)
		return

	var/accepted = (result == "Да")

	if(is_person_a)
		session.result_a = accepted ? CONFIRM_ACCEPTED : CONFIRM_REJECTED
	else
		session.result_b = accepted ? CONFIRM_ACCEPTED : CONFIRM_REJECTED

	session.check_resolution()
