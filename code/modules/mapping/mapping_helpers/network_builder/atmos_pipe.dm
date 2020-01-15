#define NO_KNOT 0
#define KNOT_AUTO 1
#define KNOT_FORCED 2

/// Automatically places pipes on init based on any pipes connecting to it and adjacent helpers. Only supports cardinals.
/obj/effect/network_builder/atmos_pipe
	name = "atmos pipe autobuilder"
	icon_state = "atmospipebuilder"

	/// Layer to put our pipes on
	var/pipe_layer = PIPING_LAYER_DEFAULT

	/// Color to set our pipes to
	var/pipe_color

	/// Whether or not pipes we make are visible
	var/visible_pipes = FALSE

	/// set var to true to not del on lateload
	var/custom_spawned = FALSE

	color = null

	/// what directions we know pipes are in
	var/list/pipe_directions

/obj/effect/network_builder/atmos_pipe/Initialize(mapload)
	. = ..()
	if(!mapload)
		if(GLOB.Debug2)
			custom_spawned = TRUE
			return INITIALIZE_HINT_NORMAL
		else
			return INITIALIZE_HINT_QDEL
	if(locate(/obj/structure/cable) in loc)
		stack_trace("WARNING: Power cable helpers should NOT be ontop of existing cables"!)
		return INITIALIZE_HINT_QDEL
	return INITIALIZE_HINT_LATELOAD

/// How this works: On LateInitialize, detect all directions that this should be applicable to, and do what it needs to do, and then inform all network builders in said directions that it's been around since it won't be around afterwards.
/obj/effect/network_builder/atmos_pipe/LateInitialize()
	if(locate(type) in src)
		if(!custom_spawned)
			stack_trace("WARNING: Duplicate helper of [type] detected at [COORD(src)]")
		qdel(src)
	scan_directions()
	if(!custom_spawned)
		qdel(src)
/obj/effect/network_builder/atmos_pipe/check_duplicates()
	var/obj/effect/network_builder/atmos_pipe/other = locate() in loc
	if(other)
		return other
	for(var/obj/machinery/atmospherics/A in loc)
		if(A.pipe_flags & PIPING_ALL_LAYER)
			if(
		return

/// Scans directions, sets network_directions to have every direction that we can link to. If there's another power cable builder detected, make sure they know we're here by adding us to their cable directions list before we're deleted.
/obj/effect/network_builder/atmos_pipe/scan_directions()
	var/turf/T
	for(var/i in GLOB.cardinal)
		if(i in network_directions)
			continue				//we're already set, that means another builder set us.
		T = get_step(loc, i)
		if(!T)
			continue
		var/obj/effect/network_builder/atmos_pipe/other = locate() in T
		if(other)
			network_directions += i
			LAZYADD(other.network_directions, turn(i, 180))
			continue
		for(var/obj/structure/cable/C in T)
			if(C.d1 == turn(i, 180) || C.d2 == turn(i, 180))
				network_directions += i
				continue
	return network_directions

/// Directions should only ever have cardinals.
/obj/effect/network_builder/atmos_pipe/build_network(list/directions = pipe_directions)
	if(!length(directions) <= 1)
		return

/obj/effect/network_builder/atmos_pipe/proc/spawn_wires(list/directions)
	if(!length(directions))
		return
	else if(length(directions) == 1)
		var/knot = (knot == KNOT_FORCED) || ((knot == KNOT_AUTO) && should_auto_knot())
		if(knot)
			var/dir = directions[1]
			new /obj/structure/cable(loc, cable_color, NONE, directions[1])
	else
		if(knot == KNOT_FORCED)
			for(var/d in directions)
				new /obj/structure/cable(loc, cable_color, NONE, d)
		else
			var/knot = (knot == KNOT_FORCED) || ((knot == KNOT_AUTO) && should_auto_knot())
			var/dirs = length(directions)
			for(var/i in dirs)
				var/li = i - 1
				if(li < 1)
					li = dirs + li
				new /obj/structure/cable(loc, cable_color, directions[i], directions[li])
				if(knot)
					new /obj/structure/cable(loc, cable_color, NONE, directions[i])
					knot = FALSE

/obj/effect/network_builder/atmos_pipe/distro
	name = "distro line autobuilder"
	piping_layer = PIPING_LAYER_MIN
	pixel_x = -PIPING_LAYER_P_X
	pixel_y = -PIPING_LAYER_P_Y
	pipe_color = rgb(130,43,255)
	color = rgb(130,43,255)

/obj/effect/network_builder/atmos_pipe/scrubbers
	name = "scrubbers line autobuilder"
	piping_layer = PIPING_LAYER_MAX
	pixel_x = PIPING_LAYER_P_X
	pixel_y = PIPING_LAYER_P_Y
	pipe_color = rgb(255,0,0)
	color = rgb(255,0,0)
