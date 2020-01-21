//Custom areas for planerdstation

/area/awaymission/planetstation
	name = "Do not use this"

/area/awaymission/planetstation/outside
	name = "Planetstation outside"
	requires_power = TRUE
	always_unpowered = TRUE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	power_light = FALSE
	power_equip = FALSE
	power_environ = FALSE
	valid_territory = FALSE
	outdoors = TRUE
	//ambientsounds = SPACE
	blob_allowed = FALSE //Eating up space doesn't count for victory as a blob.