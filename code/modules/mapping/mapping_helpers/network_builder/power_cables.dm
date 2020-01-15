#define NO_KNOT 0
#define KNOT_AUTO 1
#define KNOT_FORCED 2

/// Builds networks like power cables/atmos lines/etc. ONLY supports CARDINALS.
/obj/effect/network_builder/power_cable
	icon_state = "powerlinebuilder"

	/// Whether or not we forcefully make a knot
	var/knot = NO_KNOT

	/// cable color as from GLOB.cable_colors
	var/cable_color = "red"


	color = "ff0000"

	/// what directions we know cables are in
	var/list/cable_directions

/obj/effect/network_builder/power_cable/Initialize(mapload)
	. = ..()
	if(!mapload)
		return GLOB.Debug2? INITIALIZE_HINT_NORMAL : INITIALIZE_HINT_QDEL
	if(locate(/obj/structure/cable) in loc)
		stack_trace("WARNING: Power cable helpers should NOT be ontop of existing cables"!)
		return INITIALIZE_HINT_QDEL
	return INITIALIZE_HINT_LATELOAD

/// How this works: On LateInitialize, detect all directions that this should be applicable to, and do what it needs to do, and then inform all network builders in said directions that it's been around since it won't be around afterwards.
/obj/effect/network_builder/power_cable/LateInitialize()
	if(locate(type) in src)
		if(!custom_spawned)
			stack_trace("WARNING: Duplicate helper of [type] detected at [COORD(src)]")
		qdel(src)
	scan_directions()
	if(!custom_spawned)
		qdel(src)

/// Scans directions, sets cable_directions to have every direction that we can link to. If there's another power cable builder detected, make sure they know we're here by adding us to their cable directions list before we're deleted.
/obj/effect/network_builder/power_cable/proc/scan_directions()
	for(var/i in GLOB.cardinal)
		if(i in cable_directions)
			continue				//we're already set, that means another builder set us.

/// Directions should only ever have cardinals.
/obj/effect/network_builder/power_cable/proc/spawn_wires(list/directions)
	if(!length(directions))mob
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
					new /obj/structure/cable(loc, cable_color, NONE, directinos[i])

/obj/effect/network_builder/power_cable/proc/should_auto_knot()
	return (locate(/obj/machinery/terminal) in loc)

/obj/effect/network_buidler/power_cable/knot
	icon_state = "powerlinebuilderknot"
	knot = KNOT_FORCED

/obj/effect/network_builder/power_cable/auto
	icon_state = "powerlinebuilderauto"
	knot = KNOT_AUTO

#define AUTODEF_COLOR(hex, enum) \
/obj/effect/network_builder/power_cable/##enum \
	color = #hex \
	cable_color = #enum \
/obj/effect/network_builder/power_cable/knot/##enum \
	color = #hex \
	cable_color = #enum \
/obj/effect/network_builder/power_cable/auto/##enum \
	color = #hex \
	cable_color = #enum

AUTODEF_COLOR("#ff0000", "red")
AUTODEF_COLOR("#ffffff", "white")
AUTODEF_COLOR("#00ffff", "cyan")
AUTODEF_COLOR("#ff8000", "orange")
AUTODEF_COLOR("#ff3cc8", "pink")
AUTODEF_COLOR("#1919c8", "blue")
AUTODEF_COLOR("#00aa00", "green")
AUTODEF_COLOR("#ffff00", "yellow")

#undef AUTODEF_COLOR
