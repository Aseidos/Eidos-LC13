#define STATUS_EFFECT_SMOKED /datum/status_effect/smoked

/mob/living/simple_animal/hostile/abnormality/memorial
	name = "Memorial of a War without Reason"
	desc = "A heavily corroded combat helmet surrounded by a sea of bullet casings. A photo depicting a strangely familiar child sits gently on top of it."
	icon = 'ModularTegustation/Teguicons/48x48.dmi'
	icon_state = "memorial"
	maxHealth = 1000
	health = 1000
	threat_level = ALEPH_LEVEL // It spawns a harder steel dusk or it puts a high-level agent out of commission for a while
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(0, 0, 0, 30, 45),
		ABNORMALITY_WORK_INSIGHT = list(0, 0, 0, 30, 45),
		ABNORMALITY_WORK_ATTACHMENT = list(35, 35, 40, 50, 60),
		ABNORMALITY_WORK_REPRESSION = -100, // It REALLY wants to tell its story
		"Reminiscing" = 984,
	)
	work_damage_amount = 20 // Heavy white damage, work rates are very good for an ALEPH.
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gloom // Gloom or lust, both would fit.
	start_qliphoth = 3 // There is NO way to rise it's qli counter other than letting it breach or sending someone to the trenches.

	/* ego_list = list(
		/datum/ego_datum/weapon/raison d'etre,
		/datum/ego_datum/weapon/raison d'etat,
		/datum/ego_datum/armor/raison d'etre
		) */
//	gift_type = /datum/ego_gifts/memorial
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	observation_prompt = "You spent your youth living with your grandfather in a rundown apartment. <br>\
		As a veteran of old wars, he was always happy to regale you with many tales from battles in which he had fought. <br>\
		You were soon filled with dreams of bravery and heroism that consumed your every waking hour, driving you forward. <br>\
		Many years later, you found yourself becoming one of the many soldiers marching through alleyways filled with smoke. <br>\
		As you walk the seemingly endless path your squadron was directed to, one question suddenly appears in your tired mind. <br>\
		Why did you enlist?"
	observation_choices = list(
		"Because there is no other option" = list(TRUE, "You had grown up since then, coming to realize what the world is truly like. <br>\
			Nevertheless you fight...you must fight to protect all the smiles waiting for you back home. <br>\
			Suddenly, gunshots ring in the air. <br>\
			Your grip tightens around your weapon <br>\
			Hell descends upon you."),
		"Because it's what is right" = list(FALSE, "You fight on the side of order and justice. <br>\
			Against viciousness and barbarity. <br>\
			Suddenly, gunshots ring in the air. <br>\
			You perk up, waiting for orders that will never come. <br>\
			Hell descends upon you."),
	)
	var/death_counter = 0
	var/meltdown_cooldown_time = 90 SECONDS
	var/meltdown_cooldown
	var/imminent_enlistment = FALSE
	var/enlisted = FALSE
	var/invaded = FALSE
	var/mob/living/carbon/human/conscript
	var/mob/living/carbon/human/witness

	//SFX
	var/datum/looping_sound/memorial_raid_alarm/raid_alarm
	var/alarm = FALSE
	var/playrange = 40

	//Lots of stuff I am prolly gonna delete later
	var/spawn_amount = 3
	var/boss_amount = 4
	var/grunt_amount = 4
	var/list/ordeal_mobs = list()

/mob/living/simple_animal/hostile/abnormality/memorial/Initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death)) // Waiter waiter, more death sensitive abnos please.
	raid_alarm = new(list(src), FALSE)

/mob/living/simple_animal/hostile/abnormality/memorial/PostSpawn()
	..()
	for(var/turf/open/M in range(1, src)) // Fill the cell with bullet casings (water for now)
		M.TerraformTurf(/turf/open/water/deep/obsessing_water, flags = CHANGETURF_INHERIT_AIR)

// Work Mechanics
/mob/living/simple_animal/hostile/abnormality/memorial/WorkChance(mob/living/carbon/human/user, chance)
	if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) >= 105)
		var/newchance = chance + 10 // Very forgiving to those with high temperance, but maybe do not connect with the abno too much m'kay?
		return newchance
	return chance

/mob/living/simple_animal/hostile/abnormality/memorial/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	if(user.sanity_lost) // You poor thing, your mind is still too frail.
		user.gib() // Remember to change this later.
		return

	if(get_attribute_level(user, JUSTICE_ATTRIBUTE) < 100)
		datum_reference.qliphoth_change(-1) // The abnormality has judged your character and found it lacking.

	if(work_type == "Reminiscing") // Time for grandpa war story, immersive edition.
		if(imminent_enlistment)
			//Yoink(user) // To the trenches you go.
			return
		if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) >= 140 && get_attribute_level(user, JUSTICE_ATTRIBUTE) >= 130)
			witness = user // You gotta experience the mistakes of the past to learn from them.
			to_chat(user, span_warning("You are deemed fit to carry the burden of the past."))
			//Yoink(user) // To the (even worse) trenches you go.
			return
	return

// Qliphoth Interactions (It goes from death sensitive to time sensitive)
/mob/living/simple_animal/hostile/abnormality/memorial/Life() // TODO: Making the basic breach stuff work properly
	. = ..()
	if(datum_reference.qliphoth_meter == 1 && !imminent_enlistment) // People died....THIS IS JUST LIKE THE WAR, WE NEED MORE CONSCRIPTS.
		imminent_enlistment = TRUE
		raid_alarm.start()
		alarm = TRUE
		meltdown_cooldown = world.time + meltdown_cooldown_time
		warning()

	if(meltdown_cooldown < world.time && imminent_enlistment) // If nobody goes to war, then war will go to them.
		datum_reference.qliphoth_change(-1)
		imminent_enlistment = FALSE

	if(!invaded && !datum_reference.qliphoth_meter) // 0 Qliphoth, engaging domain expansion: Trenches of Suffocating Smoke.
		invasion()
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 5 SECONDS, "Forget us not.", 1 SECONDS, "black", "yellow", "left", "CENTER,BOTTOM+2")
		sound_to_playing_players_on_level('sound/effects/ordeals/steel_start.ogg', 50, zlevel = z)
		addtimer(CALLBACK(src, PROC_REF(stopPlaying)), 10 SECONDS)
		SSweather.run_weather(/datum/weather/smoke)

/mob/living/simple_animal/hostile/abnormality/memorial/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(!IsContained()) // We are already at war, it's natural that people are dying.
		return FALSE
	if(!ishuman(died)) // Who cares about some stupid peccatula
		return FALSE
	if(died.z != z) // Who cares about some stupid manager
		return FALSE
	if(!died.mind) // Who cares about some stupid catatonic
		return FALSE
	if (datum_reference.qliphoth_meter > 1) // If we are calling for conscripts we do not care about deaths no more.
		death_counter += 1
	if(death_counter >= 2) // Waiter waiter, more "if" chains.
		death_counter = 0
		datum_reference.qliphoth_change(-1)
	return TRUE

/mob/living/simple_animal/hostile/abnormality/memorial/proc/stopPlaying() // We (sadly) cannot blast our player's ears forever.
	for(var/mob/living/carbon/human/H in livinginrange(playrange, src))
		H.stop_sound_channel(CHANNEL_MEMORIAL)
	if(alarm)
		raid_alarm.stop()
		alarm = FALSE
	if(!invaded)
		SSweather.end_weather(/datum/weather/smoke)

//Breach
/mob/living/simple_animal/hostile/abnormality/memorial/funpet()
	if(alarm && !datum_reference.qliphoth_meter)
		stopPlaying()
		datum_reference.qliphoth_change(3)
		return

/mob/living/simple_animal/hostile/abnormality/memorial/proc/warning() //A bunch of messages for various occasions
	if(datum_reference.qliphoth_meter > 0)
		for(var/mob/living/carbon/human/H in livinginrange(playrange, src))
			to_chat(H, span_warning("The abnormalities seem restless..."))
		return

	for(var/mob/living/carbon/human/H in livinginrange(playrange, src))
		to_chat(H, span_warning("Shadows move in the corners of your vision, hidden by the smoke."))

// This is literally just copying the ordeal mobspawn code
/mob/living/simple_animal/hostile/abnormality/memorial/proc/invasion()
	invaded = TRUE // Obviously
	var/boss_type = list(/mob/living/simple_animal/hostile/ordeal/steel_dusk, /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon, /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying)
	var/boss_player_mod = round(GLOB.clients.len * 0.045)
	var/grunt_player_mod = round(GLOB.clients.len * 0.015)
	var/list/available_locs = GLOB.xeno_spawn.Copy()
	for(var/i = 1 to round(boss_amount + boss_player_mod))
		var/turf/T = pick(available_locs)
		if(available_locs.len > 1)
			available_locs -= T
		for(var/Y in boss_type)
			var/mob/living/simple_animal/hostile/ordeal/C = new Y(T)
			ordeal_mobs += C
		spawngrunts(T, (grunt_amount + grunt_player_mod))

/mob/living/simple_animal/hostile/abnormality/memorial/proc/spawngrunts(turf/T, spawn_amount = 4)
	var/list/deployment_area = DeploymentZone(T, TRUE) //deployable areas.
	var/spawntype = /mob/living/simple_animal/hostile/ordeal/steel_dawn //default to grunttype if there is no list.
	for(var/i = 1 to spawn_amount) //spawn boys on one of each turf.
		var/turf/deploy_spot = T //spot grunt will be deployed
		if(LAZYLEN(deployment_area)) //if list is empty just deploy them ontop of boss. Sorry boss.
			deploy_spot = pick_n_take(deployment_area)
		var/mob/living/simple_animal/hostile/ordeal/M = new spawntype (deploy_spot)
		ordeal_mobs += M

/mob/living/simple_animal/hostile/abnormality/memorial/proc/DeploymentZone(turf/T, no_center = FALSE)
	var/list/deploymentzone = list()
	var/list/turf/nearby_turfs = RANGE_TURFS(1,T)
	if(no_center)
		nearby_turfs -= get_turf(T)
	for(var/turf/freearea in nearby_turfs)
		if(!freearea.is_blocked_turf(exclude_mobs = TRUE) && !(islava(freearea) || ischasm(freearea)))
			deploymentzone += freearea
	return deploymentzone

/datum/weather/smoke // Ah...back into where we belong.
	name = "Suffocating Smoke"
	immunity_type = "fog"
	desc = "Air saturated with unnatural smoke. You can hear faint voices in the darkness"
	telegraph_message = span_warning("Thick smoke starts filling the air.")
	telegraph_duration = 50
	telegraph_overlay = "light_ash"
	weather_message = span_userdanger("<i>The stygian smoke engulfs you whole.</i>")
	weather_overlay = "suffocating_smoke"
	weather_duration_lower = 1500
	weather_duration_upper = 3000
	perpetual = TRUE //should make it last forever
	end_duration = 100
	end_message = span_boldannounce("The smoke starts dissapearing, together with the echoes of the past.")
	end_overlay = "light_ash"
	area_type = /area
	target_trait = ZTRAIT_STATION

/datum/weather/smoke/weather_act(mob/living/carbon/human/L)
	if(!ishuman(L) || L.stat == DEAD)
		return
	if(prob(25))
		for(var/turf/open/T in view(2, L))
			if(locate(/obj/structure) in T || locate(/mob/living) in T) // Let's hope this works, remember to test this later.
				continue
			if(prob(25))
				var/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/ambusher = new(T)
				ambusher.name = "smokey memory"
				ambusher.icon = 'icons/effects/effects.dmi'
				ambusher.icon_state = "curse"
		to_chat(L, span_userdanger("It's an ambush!!"))
	if(L.has_status_effect(STATUS_EFFECT_SMOKED))
		return
	L.apply_status_effect(STATUS_EFFECT_SMOKED)

/datum/weather/smoke/end()
	..()
	for(var/mob/living/carbon/human/L in GLOB.player_list)
		L.remove_status_effect(STATUS_EFFECT_SMOKED)

/datum/status_effect/smoked
	id = "smoked"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/smoked

/datum/status_effect/smoked/on_apply()
	owner.become_nearsighted(STATUS_EFFECT_TRAIT)
	ADD_TRAIT(owner, TRAIT_UNKNOWN, STATUS_EFFECT_TRAIT)
	return ..()

/datum/status_effect/smoked/on_remove()
	owner.cure_nearsighted(STATUS_EFFECT_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_UNKNOWN, STATUS_EFFECT_TRAIT)
	return ..()

/atom/movable/screen/alert/status_effect/smoked
	name = "Suffocating Smoke"
	desc = "The War...did it ever end?"
	icon = 'ModularTegustation/Teguicons/status_sprites.dmi'
	icon_state = "foggy"

#undef STATUS_EFFECT_SMOKED

