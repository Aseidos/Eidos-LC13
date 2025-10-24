/obj/item/debugtoollines
	name = "debug tool for lines"
	icon = 'icons/obj/black_silence_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/black_silence_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/black_silence_righthand.dmi'
	icon_state = "gloves"
	var/range_offset = 0
	var/thickmaxxing = 1

/obj/item/debugtoollines/equipped(mob/user, slot)
	. = ..()
	if(!user)
		return
	RegisterSignal(user, COMSIG_MOB_SHIFTCLICKON, PROC_REF(normalline))
	RegisterSignal(user, COMSIG_MOB_MIDDLECLICKON, PROC_REF(coolerline))
	RegisterSignal(user, COMSIG_MOB_ALTCLICKON, PROC_REF(coolerthickline))

/obj/item/debugtoollines/Destroy(mob/user)
	UnregisterSignal(user, COMSIG_MOB_SHIFTCLICKON)
	UnregisterSignal(user, COMSIG_MOB_MIDDLECLICKON)
	RegisterSignal(user, COMSIG_MOB_ALTCLICKON)
	return ..()

/obj/item/debugtoollines/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_SHIFTCLICKON)
	UnregisterSignal(user, COMSIG_MOB_MIDDLECLICKON)
	RegisterSignal(user, COMSIG_MOB_ALTCLICKON)

/obj/item/debugtoollines/proc/normalline(mob/living/user, atom/target)
	var/turf/initial = get_turf(user)
	var/turf/end = get_turf(target)
	for(var/turf/mlem in getline(initial, end))
		new /obj/effect/temp_visual/BoD(mlem)

/obj/item/debugtoollines/proc/coolerline(mob/living/user, atom/target)
	var/turf/initial = get_turf(user)
	var/turf/end = get_turf(target)
	for(var/turf/mlem in coolergetline(initial, end, range_offset))
		if(locate(/obj/effect/temp_visual/BoD) in mlem)
			new /obj/effect/temp_visual/burrowing_warning(mlem)
		new /obj/effect/temp_visual/BoD(mlem)

/obj/item/debugtoollines/proc/coolerthickline(mob/living/user, atom/target)
	var/turf/initial = get_turf(user)
	var/turf/end = get_turf(target)
	for(var/turf/mlem in get_thick_line_with_collision(initial, end, range_offset, thickmaxxing))
		new /obj/effect/temp_visual/BoD(mlem)

#define CANNOT_MOVE		(1<<0)
#define CANNOT_ACT		(1<<1)

#define COUNTER			(1<<0)
#define DASH			(1<<1)
#define DRAW_SWORD		(1<<2)
#define SLAY			(1<<3)
#define PARALYZER		(1<<4)
#define OVERTHROW		(1<<5)
#define BLADE_DANCE		(1<<6)
#define BONE_CLAIMING	(1<<7)

#define WIDESLASH_BORDER_TURFS 		(((wide_slash_angle/90) * (2**wide_slash_range)))


/mob/living/simple_animal/hostile/distortion/kim
	name = "Wonhanui-Angma" // Rough romanization of 원망의 악마.
	desc = "A humanoid shrouded in darkness full of intent to kill."
	icon = 'ModularLobotomy/_Lobotomyicons/distorted_Kim.dmi'
	icon_state = "Kim"
	icon_living = "Kim"
	icon_dead = "Kim"
	faction = list("hostile")
	maxHealth = 6000
	health = 6000
	base_pixel_x = -17
	pixel_x = -17
	melee_damage_lower = 35
	melee_damage_upper = 55
	target_switch_resistance = 100 // Kim likes one on one fights. It is not eager to switch targets.
	rapid_melee = 2
	attack_verb_continuous = "slices"
	attack_verb_simple = "slice"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	death_sound = 'sound/effects/limbus_death.ogg'
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 0.5)
	move_to_delay = 2
	ranged = TRUE

	//Variables important for distortions
	//The EGO worn by the egoist
	ego_list = list(
		/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_admin,
		/obj/item/clothing/head/rice_hat,
		/obj/item/ego_weapon/city/bladelineage
		)
	//The egoist's name, if specified. Otherwise picks a random name.
	egoist_names = list("Mentor Kim")
	//The mob's gender, which will be inherited by the egoist. Can be left unspecified for a random pick.
	gender = MALE
	//Loot on death; distortions should be valuable targets in general.
	loot = list(/obj/item/ego_weapon/city/bladelineage, /obj/item/clothing/head/rice_hat) // Remind me to make a special subtype of the Hwando for Kim.
	/// Prolonged exposure to a monolith will convert the distortion into an abnormality. Both Kim and KoD failed to protect what they wanted to protect and both also cling to their pride (As a swordsman for kim, as a knight for KoD)
	monolith_abnormality = /mob/living/simple_animal/hostile/abnormality/despair_knight
	egoist_attributes = 130

	var/manifesting
	var/blade_fiend = FALSE

	var/movement_flags = FALSE
	var/attack_flag = FALSE
	var/growing_resentment = 0 // Basically poise, it limits what moves Kim can use.
	var/mob/living/carbon/human/duel_partner

	var/dash_time = 0.2 SECONDS
	var/dash_damage = 80

	var/draw_sword_slashes = 2

	var/slash_damage = 100
	var/slash_min_delay = 0.3 SECONDS

	var/wide_slash_angle = 180 // If this gets changed, it gets wonky QUICK. If you NEED to change it, please let it be a multiple of 90.
	var/wide_slash_range = 2
	var/wide_slash_delay = 0.3 SECONDS

	var/circular_slash_delay = 0.2 SECONDS
	var/circular_slash_range = 3

	var/paralyzer_thickness = 1
	var/paralyzer_extra_range = 2
	var/paralyzer_slash_delay = 0.2 SECONDS

	var/debug


/mob/living/simple_animal/hostile/distortion/kim/Initialize(mapload)
	. = ..()
	WEAKREF(src)

/mob/living/simple_animal/hostile/distortion/kim/Login()
	. = ..()
	to_chat(src, "<h1>There is no such thing as honor in this city.</h1>")

/mob/living/simple_animal/hostile/distortion/kim/death()
	if(manifesting)
		movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
		notransform = TRUE
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/distortion/kim/Move()
	if(movement_flags & (CANNOT_MOVE | CANNOT_ACT))
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/distortion/kim/bullet_act(obj/projectile/P)
	if(prob(50) || (attack_flag & COUNTER))
		visible_message(span_warning("[src] skillfully deflects [P] with their blade!"))
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/distortion/kim/adjustHealth(forced)
	. = ..()
	if(!duel_partner && (health <= (maxHealth * 0.2)))
		PrepareDuelPhase()

/mob/living/simple_animal/hostile/distortion/kim/AICanContinue(list/possible_targets)
	if(movement_flags & CANNOT_ACT || attack_flag)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/distortion/kim/AttackingTarget(atom/attacked_target)
	if(movement_flags & CANNOT_ACT)
		return FALSE
	if(prob(growing_resentment))
		return Dash(attacked_target, TRUE)
	. = ..()

/mob/living/simple_animal/hostile/distortion/kim/OpenFire(atom/A)
/* 	var/angel = round(Get_Angle(get_turf(src), get_turf(A)), 1)
	say("[angel]") */
	if(attack_flag || movement_flags & CANNOT_ACT || get_dist(src, A) <= 1)
		return
	Dash(A, TRUE)

/* /mob/living/simple_animal/hostile/distortion/kim/Found(atom/A)
	switch(attack_flag)
		if(DASH) // After an independent dash, target literally the first dude that you can detect and attack.
			if(CanAttack(A))
				return TRUE
		else
			return */

/mob/living/simple_animal/hostile/distortion/kim/proc/AdjustResentment(amount)
	growing_resentment = clamp(growing_resentment += amount, 0, 100)


// Dashing to a target. "independent_dash" means that the dash was not made inside any complex move (TRUE), therefore its free to do a follow-up attack.
/mob/living/simple_animal/hostile/distortion/kim/proc/Dash(atom/dash_target, independent_dash)
	if(movement_flags & (CANNOT_ACT | CANNOT_MOVE)) // Why are you dashing while rooted, nerd.
		return FALSE
	var/list/DashLine = get_line_with_collision(get_turf(src), get_turf(dash_target), rand(1, 2))
	var/DashLineDist = length(DashLine)
	if(!DashLineDist)
		return FALSE
	movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
	attack_flag |= DASH
	// I find this quite annoying, if I am being honest. Nevertheless its the only way I found for the thick line to not get messed up on collision.
	var/turf/DashFinalTurf = DashLine[DashLineDist]
	if(blade_fiend)
		DashLine = get_thick_line_with_collision(get_turf(src), DashFinalTurf, FALSE, 1)
	for(var/turf/T in DashLine)
		if(!locate(/obj/effect/temp_visual/blade_warning/dangerous) in T)
			new /obj/effect/temp_visual/blade_warning/dangerous(T, dash_time, weak_reference)
	addtimer(CALLBACK(src, PROC_REF(DashMove), DashFinalTurf, independent_dash), (dash_time))

/mob/living/simple_animal/hostile/distortion/kim/proc/DashMove(turf/target_turf, independent_dash)
	var/turf/my_turf = get_turf(src)
	my_turf.Beam(target_turf, "1-full", time = 2)
	forceMove(target_turf)
	EndDash(independent_dash)

/mob/living/simple_animal/hostile/distortion/kim/proc/EndDash(independent_dash)
	attack_flag &= ~DASH
	if(!independent_dash)
		return
	movement_flags &= ~(CANNOT_ACT | CANNOT_MOVE)
	switch(growing_resentment)
		if(0 to INFINITY)
			// FindTarget()
			switch(get_dist(target, src))
				if(0 to 1)
					DrawSword()
				if(2 to 3)
					addtimer(CALLBACK(src, PROC_REF(Paralyzer)), 2)
/* 		if(51 to 100)
			FindTarget()
			switch(get_dist(target, src))
				if(0 to 1)
					Slay()
				if(2 to 3)
					Overthrow()
		else
			SLEEP_CHECK_DEATH(0.5) */


// Complex (anime) moveset.
// Every complex move is a composite of "primitive" moves mixed and matched together.
/mob/living/simple_animal/hostile/distortion/kim/proc/DrawSword(atom/attack_target)
	if(!attack_target)
		attack_target = target
	if(movement_flags & (CANNOT_ACT) || QDELETED(target))
		return FALSE
	movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
	attack_flag |= DRAW_SWORD
	var/draw_sword_delay = slash_min_delay + wide_slash_delay
	say("DRAW SWORD!!")
	WideSlash(target)
	for(var/i in 1 to (draw_sword_slashes - 1))
		face_atom(attack_target)
		addtimer(CALLBACK(src, PROC_REF(WideSlash), attack_target, -1**i), (i * draw_sword_delay))
	addtimer(CALLBACK(src, PROC_REF(PostAttack)), ((draw_sword_delay * draw_sword_slashes)))

/mob/living/simple_animal/hostile/distortion/kim/proc/Slay(atom/attack_target) // TODO: Make slay have an actual identity.
	if(!attack_target)
		attack_target = target
	if(movement_flags & (CANNOT_ACT) || QDELETED(attack_target))
		return FALSE
	movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
	attack_flag |= SLAY
	say("SLAY!!")
	CircularSlash(attack_target)
	addtimer(CALLBACK(src, PROC_REF(PostAttack)), 1 SECONDS)

/mob/living/simple_animal/hostile/distortion/kim/proc/Paralyzer(atom/attack_target)
	if(!attack_target)
		attack_target = target
	if(movement_flags & (CANNOT_ACT) || QDELETED(attack_target))
		return FALSE
	movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
	attack_flag |= PARALYZER
	say("PARALYZER!!")
	var/turf/turftarget = get_turf(attack_target)
	var/possible_turfs_around = turftarget.reachableAdjacentTurfs()
	if(!length(possible_turfs_around))
		PostAttack()
		return
	var/turf/aroundturf = pick(possible_turfs_around)
	DashMove(aroundturf)
	face_atom(attack_target)
	LineSlash(attack_target, paralyzer_extra_range, paralyzer_slash_delay, paralyzer_thickness)
	addtimer(CALLBACK(src, PROC_REF(PostAttack)), (slash_min_delay + paralyzer_slash_delay))

/mob/living/simple_animal/hostile/distortion/kim/proc/Overthrow(atom/attack_target)
	if(!attack_target)
		attack_target = target
	face_atom(attack_target)
	if(movement_flags & (CANNOT_ACT | CANNOT_MOVE) || QDELETED(target))
		return FALSE
	movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
	attack_flag |= OVERTHROW
	say("OVERTHROW!!")
	addtimer(CALLBACK(src, PROC_REF(PostAttack)), 1 SECONDS)

// Unpowered counterattack.
/mob/living/simple_animal/hostile/distortion/kim/proc/BladeDance(atom/attack_target)
	if(!attack_target)
		attack_target = target
	face_atom(attack_target)
	if(movement_flags & (CANNOT_ACT | CANNOT_MOVE) || QDELETED(target))
		return FALSE
	movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
	attack_flag |= BLADE_DANCE
	say("BLADE DANCE!!")
	addtimer(CALLBACK(src, PROC_REF(PostAttack)), 1 SECONDS)

 // Oh god oh fuck you messed up big time (Powered counterattack).
/mob/living/simple_animal/hostile/distortion/kim/proc/ClaimBones(atom/attack_target)
	if(!attack_target)
		attack_target = target
	face_atom(attack_target)
	if(movement_flags & (CANNOT_ACT | CANNOT_MOVE) || QDELETED(target))
		return FALSE
	movement_flags |= (CANNOT_ACT | CANNOT_MOVE)
	attack_flag |= BONE_CLAIMING
	say("TO CLAIM THEIR BONES!!")
	addtimer(CALLBACK(src, PROC_REF(PostAttack)), 1 SECONDS)

/mob/living/simple_animal/hostile/distortion/kim/proc/PostAttack()
	movement_flags &= ~(CANNOT_ACT | CANNOT_MOVE)
	attack_flag = FALSE
	return

/mob/living/simple_animal/hostile/distortion/kim/proc/PrepareDuelPhase()
	say("D-D-D-DUEL!!")
	return

// Primitive Moveset

/mob/living/simple_animal/hostile/distortion/kim/proc/WideSlash(atom/attack_target, rotation_dir = 1)
	face_atom(attack_target)
	var/turf/self = get_turf(src)
	var/angle = round((Get_Angle(self, get_turf(attack_target)) + 360), 45)
	angle -= (wide_slash_angle/2) * rotation_dir
	var/lines = WIDESLASH_BORDER_TURFS
	for(var/slashcount in 1 to (lines - 1))
		angle += (wide_slash_angle / lines) * rotation_dir
		var/turf/angled_turf = get_turf_in_angle(angle, self, wide_slash_range)
		// new /obj/effect/temp_visual/small_smoke/second(angled_turf)
		addtimer(CALLBACK(src, PROC_REF(LineSlash), angled_turf), ((wide_slash_delay * slashcount)/(lines - 1)))

/mob/living/simple_animal/hostile/distortion/kim/proc/CircularSlash(rotation_dir = 1, spin_count)
	var/turf/self = get_turf(src)
	var/angle = 720
	var/lines = (2**(circular_slash_range + 2))
	for(var/slashcount in 1 to (lines - 1))
		angle += ((720 / lines) * rotation_dir)
		var/turf/angled_turf = get_turf_in_angle(angle, self, wide_slash_range)
		// new /obj/effect/temp_visual/small_smoke/second(angled_turf)
		addtimer(CALLBACK(src, PROC_REF(LineSlash), angled_turf), ((circular_slash_delay * slashcount)/(lines - 1)))

/mob/living/simple_animal/hostile/distortion/kim/proc/LineSlash(atom/attack_target, range_offset, time_offset, thickness)
	var/list/line = get_line_with_collision(src, attack_target, range_offset)
	if(thickness)
		var/index = (length(line) - 1)
		if(index > 0)
			var/turf/second_to_last_turf = line[index]
			line |= get_thick_line_with_collision(src, second_to_last_turf, FALSE, thickness)
	for(var/turf/slashturf in line)
		if(locate(/obj/effect/temp_visual/blade_warning/dangerous) in slashturf)
			continue
		new /obj/effect/temp_visual/blade_warning/dangerous(slashturf, slash_min_delay + time_offset, weak_reference)

/mob/living/simple_animal/hostile/distortion/kim/proc/Slash(attack_target)
	if(attack_target)
		for(var/mob/living/fool as anything in attack_target) // We are trusting that attack target is a list of only mobs.
			SpecialSlash(fool)
			var/image/slasheffect = image('icons/effects/effects.dmi', fool, "slash", fool.layer + 0.1, EAST)
			flick_overlay(slasheffect, GLOB.clients, 4)
			QDEL_IN(slasheffect, 5)
			fool.deal_damage(slash_damage, RED_DAMAGE)
		return

/mob/living/simple_animal/hostile/distortion/kim/proc/SpecialSlash(attack_target)
	AdjustResentment(5)
	return


/obj/effect/temp_visual/blade_warning
	name = "ominous aura"
	desc = "the air crackles with resentment"
	icon_state = "blade_warning"

/obj/effect/temp_visual/blade_warning/Initialize(loc, _duration)
	duration = _duration
	. = ..()

/obj/effect/temp_visual/blade_warning/dangerous/Initialize(loc, _duration, _reference)
	weak_reference = _reference
	. = ..()

/obj/effect/temp_visual/blade_warning/dangerous/Destroy()
	if(locate(/mob/living) in loc)
		var/fools = list()
		for(var/mob/living/slashed in loc)
			if(istype(slashed, /mob/living/simple_animal/hostile/distortion/kim))
				continue
			fools += slashed
		var/mob/living/simple_animal/hostile/distortion/kim/the_swordler = weak_reference.resolve()
		if(istype(the_swordler))
			the_swordler.Slash(fools)
	. = ..()

