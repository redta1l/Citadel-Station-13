
//This is the lowest supported version, anything below this is completely obsolete and the entire savefile will be wiped.
#define SAVEFILE_VERSION_MIN	18

//This is the current version, anything below this will attempt to update (if it's not obsolete)
//	You do not need to raise this if you are adding new values that have sane defaults.
//	Only raise this value when changing the meaning/format/name/layout of an existing value
//	where you would want the updater procs below to run
#define SAVEFILE_VERSION_MAX	33

/*
SAVEFILE UPDATING/VERSIONING - 'Simplified', or rather, more coder-friendly ~Carn
	This proc checks if the current directory of the savefile S needs updating
	It is to be used by the load_character and load_preferences procs.
	(S.cd=="/" is preferences, S.cd=="/character[integer]" is a character slot, etc)

	if the current directory's version is below SAVEFILE_VERSION_MIN it will simply wipe everything in that directory
	(if we're at root "/" then it'll just wipe the entire savefile, for instance.)

	if its version is below SAVEFILE_VERSION_MAX but above the minimum, it will load data but later call the
	respective update_preferences() or update_character() proc.
	Those procs allow coders to specify format changes so users do not lose their setups and have to redo them again.

	Failing all that, the standard sanity checks are performed. They simply check the data is suitable, reverting to
	initial() values if necessary.
*/
/datum/preferences/proc/savefile_needs_update(savefile/S)
	var/savefile_version
	S["version"] >> savefile_version

	if(savefile_version < SAVEFILE_VERSION_MIN)
		S.dir.Cut()
		return -2
	if(savefile_version < SAVEFILE_VERSION_MAX)
		return savefile_version
	return -1

//should these procs get fairly long
//just increase SAVEFILE_VERSION_MIN so it's not as far behind
//SAVEFILE_VERSION_MAX and then delete any obsolete if clauses
//from these procs.
//This only really meant to avoid annoying frequent players
//if your savefile is 3 months out of date, then 'tough shit'.

/datum/preferences/proc/update_preferences(current_version, savefile/S)
	if(current_version < 32)	//If you remove this, remove force_reset_keybindings() too.
		addtimer(CALLBACK(src, .proc/force_reset_keybindings), 30)	//No mob available when this is run, timer allows user choice.

/datum/preferences/proc/update_character(current_version, savefile/S)
	if(current_version < 19)
		pda_style = "mono"
	if(current_version < 20)
		pda_color = "#808000"
	if((current_version < 21) && features["meat_type"] && (features["meat_type"] == null))
		features["meat_type"] = "Mammalian"
	if(current_version < 22)

		job_preferences = list() //It loaded null from nonexistant savefile field.

		var/job_civilian_high = 0
		var/job_civilian_med = 0
		var/job_civilian_low = 0

		var/job_medsci_high = 0
		var/job_medsci_med = 0
		var/job_medsci_low = 0

		var/job_engsec_high = 0
		var/job_engsec_med = 0
		var/job_engsec_low = 0

		S["job_civilian_high"]	>> job_civilian_high
		S["job_civilian_med"]	>> job_civilian_med
		S["job_civilian_low"]	>> job_civilian_low
		S["job_medsci_high"]	>> job_medsci_high
		S["job_medsci_med"]		>> job_medsci_med
		S["job_medsci_low"]		>> job_medsci_low
		S["job_engsec_high"]	>> job_engsec_high
		S["job_engsec_med"]		>> job_engsec_med
		S["job_engsec_low"]		>> job_engsec_low

		//Can't use SSjob here since this happens right away on login
		for(var/job in subtypesof(/datum/job))
			var/datum/job/J = job
			var/new_value
			var/fval = initial(J.flag)
			switch(initial(J.department_flag))
				if(CIVILIAN)
					if(job_civilian_high & fval)
						new_value = JP_HIGH
					else if(job_civilian_med & fval)
						new_value = JP_MEDIUM
					else if(job_civilian_low & fval)
						new_value = JP_LOW
				if(MEDSCI)
					if(job_medsci_high & fval)
						new_value = JP_HIGH
					else if(job_medsci_med & fval)
						new_value = JP_MEDIUM
					else if(job_medsci_low & fval)
						new_value = JP_LOW
				if(ENGSEC)
					if(job_engsec_high & fval)
						new_value = JP_HIGH
					else if(job_engsec_med & fval)
						new_value = JP_MEDIUM
					else if(job_engsec_low & fval)
						new_value = JP_LOW
			if(new_value)
				job_preferences["[initial(J.title)]"] = new_value
	else if(current_version < 23) // we are fixing a gamebreaking bug.
		job_preferences = list() //It loaded null from nonexistant savefile field.

	if(current_version < 25)
		var/digi
		S["feature_lizard_legs"] >> digi
		if(digi == "Digitigrade Legs")
			WRITE_FILE(S["feature_lizard_legs"], "Digitigrade")

	if(current_version < 26)
		var/vr_path = "data/player_saves/[parent.ckey[1]]/[parent.ckey]/vore/character[default_slot].json"
		if(fexists(vr_path))
			var/list/json_from_file = json_decode(file2text(vr_path))
			if(json_from_file)
				if(json_from_file["digestable"])
					ENABLE_BITFIELD(vore_flags,DIGESTABLE)
				if(json_from_file["devourable"])
					ENABLE_BITFIELD(vore_flags,DEVOURABLE)
				if(json_from_file["feeding"])
					ENABLE_BITFIELD(vore_flags,FEEDING)
				if(json_from_file["lickable"])
					ENABLE_BITFIELD(vore_flags,LICKABLE)
				belly_prefs = json_from_file["belly_prefs"]
				vore_taste = json_from_file["vore_taste"]

		for(var/V in all_quirks) // quirk migration
			switch(V)
				if("Acute hepatic pharmacokinesis")
					DISABLE_BITFIELD(cit_toggles, PENIS_ENLARGEMENT)
					DISABLE_BITFIELD(cit_toggles, BREAST_ENLARGEMENT)
					ENABLE_BITFIELD(cit_toggles,FORCED_FEM)
					ENABLE_BITFIELD(cit_toggles,FORCED_MASC)
					all_quirks -= V
				if("Crocin Immunity")
					ENABLE_BITFIELD(cit_toggles,NO_APHRO)
					all_quirks -= V
				if("Buns of Steel")
					ENABLE_BITFIELD(cit_toggles,NO_ASS_SLAP)
					all_quirks -= V

		if(features["meat_type"] == "Inesct")
			features["meat_type"] = "Insect"

	if(current_version < 27)
		var/tennis
		S["feature_balls_shape"] >> tennis
		if(tennis == "Hidden")
			features["balls_visibility"] = GEN_VISIBLE_NEVER

	if(current_version < 28)
		var/hockey
		S["feature_cock_shape"] >> hockey
		var/list/malformed_hockeys = list("Taur, Flared" = "Flared", "Taur, Knotted" = "Knotted", "Taur, Tapered" = "Tapered")
		if(malformed_hockeys[hockey])
			features["cock_shape"] = malformed_hockeys[hockey]
			features["cock_taur"] = TRUE

	if(current_version < 29)
		var/digestable
		var/devourable
		var/feeding
		var/lickable
		S["digestable"]						>> digestable
		S["devourable"]						>> devourable
		S["feeding"]						>> feeding
		S["lickable"]						>> lickable
		if(digestable)
			ENABLE_BITFIELD(vore_flags,DIGESTABLE)
		if(devourable)
			ENABLE_BITFIELD(vore_flags,DEVOURABLE)
		if(feeding)
			ENABLE_BITFIELD(vore_flags,FEEDING)
		if(lickable)
			ENABLE_BITFIELD(vore_flags,LICKABLE)

	if(current_version < 30)
		switch(features["taur"])
			if("Husky", "Lab", "Shepherd", "Fox", "Wolf")
				features["taur"] = "Canine"
			if("Panther", "Tiger")
				features["taur"] = "Feline"
			if("Cow")
				features["taur"] = "Cow (Spotted)"

	if(current_version < 31)
		S["wing_color"]			>> features["wings_color"]
		S["horn_color"]			>> features["horns_color"]

	if(current_version < 33)
		features["flavor_text"] = html_encode(features["flavor_text"])
		features["silicon_flavor_text"] = html_encode(features["silicon_flavor_text"])
		features["ooc_notes"] = html_encode(features["ooc_notes"])

/datum/preferences/proc/load_path(ckey,filename="preferences.sav")
	if(!ckey)
		return
	path = "data/player_saves/[ckey[1]]/[ckey]/[filename]"

/datum/preferences/proc/load_preferences()
	if(!path)
		return 0
	if(world.time < loadprefcooldown)
		if(istype(parent))
			to_chat(parent, "<span class='warning'>You're attempting to load your preferences a little too fast. Wait half a second, then try again.</span>")
		return 0
	loadprefcooldown = world.time + PREF_SAVELOAD_COOLDOWN
	if(!fexists(path))
		return 0

	var/savefile/S = new /savefile(path)
	if(!S)
		return 0
	S.cd = "/"

	var/needs_update = savefile_needs_update(S)
	if(needs_update == -2)		//fatal, can't load any data
		return 0

	//general preferences
	S["ooccolor"]			>> ooccolor
	S["lastchangelog"]		>> lastchangelog
	S["UI_style"]			>> UI_style
	S["hotkeys"]			>> hotkeys
	S["chat_on_map"]		>> chat_on_map
	S["max_chat_length"]	>> max_chat_length
	S["see_chat_non_mob"] 	>> see_chat_non_mob
	S["tgui_fancy"]			>> tgui_fancy
	S["tgui_lock"]			>> tgui_lock
	S["buttons_locked"]		>> buttons_locked
	S["windowflash"]		>> windowflashing
	S["be_special"] 		>> be_special


	S["default_slot"]		>> default_slot
	S["chat_toggles"]		>> chat_toggles
	S["toggles"]			>> toggles
	S["ghost_form"]			>> ghost_form
	S["ghost_orbit"]		>> ghost_orbit
	S["ghost_accs"]			>> ghost_accs
	S["ghost_others"]		>> ghost_others
	S["preferred_map"]		>> preferred_map
	S["ignoring"]			>> ignoring
	S["ghost_hud"]			>> ghost_hud
	S["inquisitive_ghost"]	>> inquisitive_ghost
	S["uses_glasses_colour"]>> uses_glasses_colour
	S["clientfps"]			>> clientfps
	S["parallax"]			>> parallax
	S["ambientocclusion"]	>> ambientocclusion
	S["auto_fit_viewport"]	>> auto_fit_viewport
	S["hud_toggle_flash"]	>> hud_toggle_flash
	S["hud_toggle_color"]	>> hud_toggle_color
	S["menuoptions"]		>> menuoptions
	S["enable_tips"]		>> enable_tips
	S["tip_delay"]			>> tip_delay
	S["pda_style"]			>> pda_style
	S["pda_color"]			>> pda_color
	S["pda_skin"]			>> pda_skin

	// Custom hotkeys
	S["key_bindings"]		>> key_bindings
	S["modless_key_bindings"]		>> modless_key_bindings

	//citadel code
	S["arousable"]			>> arousable
	S["screenshake"]		>> screenshake
	S["damagescreenshake"]	>> damagescreenshake
	S["widescreenpref"]		>> widescreenpref
	S["autostand"]			>> autostand
	S["cit_toggles"]		>> cit_toggles
	S["preferred_chaos"]	>> preferred_chaos
	S["auto_ooc"]			>> auto_ooc
	S["no_tetris_storage"]		>> no_tetris_storage


	//try to fix any outdated data if necessary
	if(needs_update >= 0)
		update_preferences(needs_update, S)		//needs_update = savefile_version if we need an update (positive integer)

	//Sanitize
	ooccolor		= sanitize_ooccolor(sanitize_hexcolor(ooccolor, 6, 1, initial(ooccolor)))
	lastchangelog	= sanitize_text(lastchangelog, initial(lastchangelog))
	UI_style		= sanitize_inlist(UI_style, GLOB.available_ui_styles, GLOB.available_ui_styles[1])
	hotkeys			= sanitize_integer(hotkeys, 0, 1, initial(hotkeys))
	chat_on_map		= sanitize_integer(chat_on_map, 0, 1, initial(chat_on_map))
	max_chat_length = sanitize_integer(max_chat_length, 1, CHAT_MESSAGE_MAX_LENGTH, initial(max_chat_length))
	see_chat_non_mob	= sanitize_integer(see_chat_non_mob, 0, 1, initial(see_chat_non_mob))
	tgui_fancy		= sanitize_integer(tgui_fancy, 0, 1, initial(tgui_fancy))
	tgui_lock		= sanitize_integer(tgui_lock, 0, 1, initial(tgui_lock))
	buttons_locked	= sanitize_integer(buttons_locked, 0, 1, initial(buttons_locked))
	windowflashing		= sanitize_integer(windowflashing, 0, 1, initial(windowflashing))
	default_slot	= sanitize_integer(default_slot, 1, max_save_slots, initial(default_slot))
	toggles			= sanitize_integer(toggles, 0, 16777215, initial(toggles))
	clientfps		= sanitize_integer(clientfps, 0, 1000, 0)
	parallax		= sanitize_integer(parallax, PARALLAX_INSANE, PARALLAX_DISABLE, null)
	ambientocclusion	= sanitize_integer(ambientocclusion, 0, 1, initial(ambientocclusion))
	auto_fit_viewport	= sanitize_integer(auto_fit_viewport, 0, 1, initial(auto_fit_viewport))
	hud_toggle_flash = sanitize_integer(hud_toggle_flash, 0, 1, initial(hud_toggle_flash))
	hud_toggle_color = sanitize_hexcolor(hud_toggle_color, 6, 1, initial(hud_toggle_color))
	ghost_form		= sanitize_inlist(ghost_form, GLOB.ghost_forms, initial(ghost_form))
	ghost_orbit 	= sanitize_inlist(ghost_orbit, GLOB.ghost_orbits, initial(ghost_orbit))
	ghost_accs		= sanitize_inlist(ghost_accs, GLOB.ghost_accs_options, GHOST_ACCS_DEFAULT_OPTION)
	ghost_others	= sanitize_inlist(ghost_others, GLOB.ghost_others_options, GHOST_OTHERS_DEFAULT_OPTION)
	menuoptions		= SANITIZE_LIST(menuoptions)
	be_special		= SANITIZE_LIST(be_special)
	pda_style		= sanitize_inlist(pda_style, GLOB.pda_styles, initial(pda_style))
	pda_color		= sanitize_hexcolor(pda_color, 6, 1, initial(pda_color))
	pda_skin		= sanitize_inlist(pda_skin, GLOB.pda_reskins, PDA_SKIN_ALT)
	screenshake			= sanitize_integer(screenshake, 0, 800, initial(screenshake))
	damagescreenshake	= sanitize_integer(damagescreenshake, 0, 2, initial(damagescreenshake))
	widescreenpref		= sanitize_integer(widescreenpref, 0, 1, initial(widescreenpref))
	autostand			= sanitize_integer(autostand, 0, 1, initial(autostand))
	cit_toggles			= sanitize_integer(cit_toggles, 0, 16777215, initial(cit_toggles))
	auto_ooc			= sanitize_integer(auto_ooc, 0, 1, initial(auto_ooc))
	no_tetris_storage		= sanitize_integer(no_tetris_storage, 0, 1, initial(no_tetris_storage))
	key_bindings 			= sanitize_islist(key_bindings, list())
	modless_key_bindings 	= sanitize_islist(modless_key_bindings, list())

	verify_keybindings_valid()		// one of these days this will runtime and you'll be glad that i put it in a different proc so no one gets their saves wiped
	sanitize_speech_and_tongue()

	return 1

/datum/preferences/proc/verify_keybindings_valid()
	// Sanitize the actual keybinds to make sure they exist.
	for(var/key in key_bindings)
		if(!islist(key_bindings[key]))
			key_bindings -= key
		var/list/binds = key_bindings[key]
		for(var/bind in binds)
			if(!GLOB.keybindings_by_name[bind])
				binds -= bind
		if(!length(binds))
			key_bindings -= key
	// End
	// I hate copypaste but let's do it again but for modless ones
	for(var/key in modless_key_bindings)
		var/bindname = modless_key_bindings[key]
		if(!GLOB.keybindings_by_name[bindname])
			modless_key_bindings -= key

/datum/preferences/proc/sanitize_speech_and_tongue()
	if(!(custom_speech_verb in GLOB.speech_verbs))
		custom_speech_verb = GLOB.speech_verbs[1]
	if(!(custom_tongue in GLOB.roundstart_tongues))
		custom_tongue = GLOB.roundstart_tongues[1]

/datum/preferences/proc/save_preferences()
	if(!path)
		return 0
	if(world.time < saveprefcooldown)
		if(istype(parent))
			to_chat(parent, "<span class='warning'>You're attempting to save your preferences a little too fast. Wait half a second, then try again.</span>")
		return 0
	saveprefcooldown = world.time + PREF_SAVELOAD_COOLDOWN
	var/savefile/S = new /savefile(path)
	if(!S)
		return 0
	S.cd = "/"

	WRITE_FILE(S["version"] , SAVEFILE_VERSION_MAX)		//updates (or failing that the sanity checks) will ensure data is not invalid at load. Assume up-to-date

	//general preferences
	WRITE_FILE(S["ooccolor"], ooccolor)
	WRITE_FILE(S["lastchangelog"], lastchangelog)
	WRITE_FILE(S["UI_style"], UI_style)
	WRITE_FILE(S["hotkeys"], hotkeys)
	WRITE_FILE(S["chat_on_map"], chat_on_map)
	WRITE_FILE(S["max_chat_length"], max_chat_length)
	WRITE_FILE(S["see_chat_non_mob"], see_chat_non_mob)
	WRITE_FILE(S["tgui_fancy"], tgui_fancy)
	WRITE_FILE(S["tgui_lock"], tgui_lock)
	WRITE_FILE(S["buttons_locked"], buttons_locked)
	WRITE_FILE(S["windowflash"], windowflashing)
	WRITE_FILE(S["be_special"], be_special)
	WRITE_FILE(S["default_slot"], default_slot)
	WRITE_FILE(S["toggles"], toggles)
	WRITE_FILE(S["chat_toggles"], chat_toggles)
	WRITE_FILE(S["ghost_form"], ghost_form)
	WRITE_FILE(S["ghost_orbit"], ghost_orbit)
	WRITE_FILE(S["ghost_accs"], ghost_accs)
	WRITE_FILE(S["ghost_others"], ghost_others)
	WRITE_FILE(S["preferred_map"], preferred_map)
	WRITE_FILE(S["ignoring"], ignoring)
	WRITE_FILE(S["ghost_hud"], ghost_hud)
	WRITE_FILE(S["inquisitive_ghost"], inquisitive_ghost)
	WRITE_FILE(S["uses_glasses_colour"], uses_glasses_colour)
	WRITE_FILE(S["clientfps"], clientfps)
	WRITE_FILE(S["parallax"], parallax)
	WRITE_FILE(S["ambientocclusion"], ambientocclusion)
	WRITE_FILE(S["auto_fit_viewport"], auto_fit_viewport)
	WRITE_FILE(S["hud_toggle_flash"], hud_toggle_flash)
	WRITE_FILE(S["hud_toggle_color"], hud_toggle_color)
	WRITE_FILE(S["menuoptions"], menuoptions)
	WRITE_FILE(S["enable_tips"], enable_tips)
	WRITE_FILE(S["tip_delay"], tip_delay)
	WRITE_FILE(S["pda_style"], pda_style)
	WRITE_FILE(S["pda_color"], pda_color)
	WRITE_FILE(S["pda_skin"], pda_skin)
	WRITE_FILE(S["key_bindings"], key_bindings)
	WRITE_FILE(S["modless_key_bindings"], modless_key_bindings)

	//citadel code
	WRITE_FILE(S["screenshake"], screenshake)
	WRITE_FILE(S["damagescreenshake"], damagescreenshake)
	WRITE_FILE(S["arousable"], arousable)
	WRITE_FILE(S["widescreenpref"], widescreenpref)
	WRITE_FIL
