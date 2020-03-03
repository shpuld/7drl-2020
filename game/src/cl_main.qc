
void() CSQC_Ent_Remove =
{
	remove(self);
};

void() CSQC_Shutdown =
{
};

struct light_t {
	vector pos;
	vector col;
	float radius;
};

// MOVE THE FOLLOWING STUFF TO CL_EFFECTS or something

entity glowent;
const int MAX_GLOWENTS = 128;
entity glowents[MAX_GLOWENTS];
int num_glowents;
.int glowent_index;

void(entity e) make_glowent =
{
	if (e.glowent_index != 0) return;

	for (int i = 1; i < MAX_GLOWENTS; i++)
	{
		if (glowents[i] == world)
		{
			glowents[i] = e;
			e.glowent_index = i;
			break;
		}
	}
}

void(entity e) remove_glowent =
{
	glowents[e.glowent_index] = world;
	e.glowent_index = 0;
}

void() update_glowents =
{
	for (int i = 1; i < MAX_GLOWENTS; i++)
	{
		if (glowents[i])
		{
			float draw = PREDRAW_AUTOADD;
			if (glowents[i].predraw)
			{
				entity oldself = self;
				self = glowents[i];
				draw = glowents[i].predraw();
				self = oldself;
			}
			if (draw == PREDRAW_AUTOADD) addentity(glowents[i]);
		}
	}
}

entity lightent;
int num_lights;
const int MAX_LIGHTS = 128;
light_t lights[MAX_LIGHTS];
light_t static_lights[MAX_LIGHTS];

void(light_t * light) draw_light =
{
	lightent.origin = light->pos;
	lightent.scale = light->radius;
	lightent.colormod = light->col;
	lightent.angles_z = sin((light->pos.x + light->pos.y) * 0.002 + time * 0.25) * 50;
	addentity(lightent);
};

void() update_lights =
{
	lightent.angles = camang;
	lightent.angles_x *= -1;
	for (int i = 0; i < num_lights; i++)
	{
		draw_light(&(lights[i]));
	}
	num_lights = 0;
};

void(vector pos, vector col, float radius) add_light =
{
	if (num_lights >= MAX_LIGHTS) return;
	vector max_dist_from_camera = [1000, 800];
	if (fabs(pos.y - campos_y) > max_dist_from_camera_y) return;
	if (fabs(pos.x - campos_x) > max_dist_from_camera_x) return;
	
	lights[num_lights].pos = pos;
	lights[num_lights].col = col;
	lights[num_lights].radius = radius;
	num_lights++;
};

void() update_static_lights =
{
	vector max_dist_from_camera = [1000, 800];
	for (int i = 0; i < MAX_LIGHTS; i++)
	{
		if (static_lights[i].radius <= 0.1) continue;
		if (fabs(static_lights[i].pos.y - campos_y) > max_dist_from_camera_y) continue;
		if (fabs(static_lights[i].pos.x - campos_x) > max_dist_from_camera_x) continue;
		draw_light(&(static_lights[i]));
	}
};

void(vector pos, vector col, float radius) add_static_light =
{
	for (int i = 0; i < MAX_LIGHTS; i++)
	{
		if (static_lights[i].radius > 0) continue;
		static_lights[i].pos = pos;
		static_lights[i].col = col;
		static_lights[i].radius = radius;
		return;
	}
};

void(int i) remove_static_light =
{
	static_lights[i].pos = '0 0 0';
	static_lights[i].col = '0 0 0';
	static_lights[i].radius = 0;
};

void() clear_static_lights =
{
	memfill8(static_lights, 0, sizeof(light_t) * MAX_LIGHTS);
};

void() init_lights =
{
	lightent = spawn();
	setmodel(lightent, "models/light.iqm");
};

// END LIGHTS


#define CSQC_TEST
void() run_cl_unit_tests =
{
	print("Running  CSQC unit tests...\n");
	// Add tests here
	print("Tests complete!\n");
};

float(float isnew) enemylisten =
{
	setsize(self, '-24 -24 0', '24 24 50');
	self.is_enemy = TRUE;
	
	return TRUE;
};

float(float isnew) cratelisten =
{
	setsize(self, '-24 -24 0', '24 24 50');
	self.is_enemy = TRUE;
	add_light(self.origin + '0 8 24', '0.1 0.4 0.1', 6);
	return TRUE;
};

float(float isnew) ladderlisten =
{
	float intensity = sin(time * 4) + 0.4;
	add_light(self.origin + '0 32 0', [intensity, 0.1 * intensity, 0.1 * intensity], 12 * intensity);
	return TRUE;
};

void(float apiver, string enginename, float enginever) CSQC_Init =
{
	precache_everything();
	
	init_lights();
	init_csqc_map();
	blocks_loaded = 0;
	block_loading_done = FALSE;
	
	muzzleflash = spawn();
	setmodel(muzzleflash, "models/muzzleflash.iqm");
	gunmodel = spawn();
	precache_model("models/smg.iqm");
	setmodel(gunmodel, "models/smg.iqm");
	
	deltalisten("models/crawler.iqm", enemylisten, 0);
	deltalisten("models/crate.iqm", cratelisten, 0);
	deltalisten("models/ladderdown.iqm", ladderlisten, 0);
	
	registercommand("reload");
	registercommand("swap");
	registercommand("toggleinventory");
	
	#ifdef CSQC_TEST
	run_cl_unit_tests();
	#endif
};

void() CSQC_WorldLoaded =
{
	for (int i = 0; i < MAX_LIGHTS; i++)
	{
		add_static_light([MAP_ORIGIN_x + random() * 64 * 32, MAP_ORIGIN_y + random() * 64 * 48, 50], [random() * 0.5, random() * 0.5, random() * 0.5], 10 + random() * 28);
	}
};

void(float isnew) CSQC_Ent_Update =
{
	// printf("csqc ent update %f\n", isnew);
	float enttype = readbyte();
	switch (enttype)
	{
	case ENT_TILEBLOCK: block_update(isnew);
		break;
	case ENT_PLAYER: player_update(isnew);
		break;
	default:
		break;
	}
};

void() set_camera =
{
	campos = newcampos; // getproperty(VF_ORIGIN);
	camang = getproperty(VF_ANGLES);
	
	add_light(campos, '0.25 0.25 0.25', 35);

	aim_normalized = crosshair_pos - [g_width/2, g_height/2];
	aim_normalized /= g_height/2;
	campos += '0 0 700' + [aim_normalized_x * 100, aim_normalized_y * -100, 0];
	camang = '90 90 0';
	
	// camera shake
	campos += [sin(time*40) * 4, cos(time*50) * 4] * camshake;
	camshake = max(0, camshake - frametime * 8);
	
	setproperty(VF_ORIGIN, campos);
	setproperty(VF_ANGLES, camang);
	setproperty(VF_AFOV, 60);	
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
	if (cvar("r_clear") != 8) cvar_set("r_clear", "8");
	//clear and update our global screen resolution vars
	g_width = width;
	g_height = height;
	
	if (player) predict_player();
	
	// testing post proc for lighting
	vector pixelsize = (vector)getproperty(VF_SCREENPSIZE);
	float lightrenderscale = 0.5;
	
	setproperty(VF_RT_DESTCOLOUR, "lightsbuf", -1, pixelsize * lightrenderscale); // set render target to $rt:lightsbuf
	
	light_pass = TRUE;
	
	clearscene();
	set_camera();

	setproperty(VF_SIZE, pixelsize * lightrenderscale);
	// setproperty(VF_RT_DEPTH, "depth", 6, pixelsize);
	drawfill([0, 0], pixelsize * lightrenderscale, '0 0 0', 1, 0);
	
	add_light('300 200 50', '1 0.5 0.25', 20);
	add_light('250 700 50', '1 0.75 0.75', 30);
	add_light('450 500 50', '1 1 1', 10);
	
	setproperty(VF_DRAWWORLD, 0);
	update_lights();
	update_static_lights();
	update_glowents();
	renderscene();
	
	light_pass = FALSE;
	
	drawfill([0, 0], [0, 0], [1, 1, 1], 0, 0); // hack
	
	setproperty(VF_RT_DESTCOLOUR, ""); // set render target back to screen
	// setproperty(VF_RT_DEPTH, "");
	clearscene();
	// setproperty(VF_DRAWWORLD, 0);
	set_camera();
	//disable quake status bar and quake crosshair
	setproperty(VF_DRAWENGINESBAR, 0);	
	setproperty(VF_DRAWCROSSHAIR, 0);

	// drawfill([0, 0], [0, 0], [0, 0, 0], 1, 0); // black background

	//autoadd entities received from servers for drawing	
	addentities(MASK_ENGINE);

	if (csqc_mapgeom)
	{
		float row = max(rint((campos_y - MAP_ORIGIN_y) / BLOCK_SIZE_y) - 6, 0);
		draw_map_geom(csqc_mapgeom, row, 12);
	}
	
	//does what you think it does
	renderscene();
	drawpic([0, 0], "lights_postproc", [width, height], [0.25, 0.25, 0.25], 1, 0);
	
	float ch_size = 4;
	drawfill(crosshair_pos - [ch_size/2, ch_size/2], [ch_size, ch_size], '1 1 1', 0.5, 1);
	
	
	if (player && FALSE)
	{
		drawstring('0 180 0', sprintf("accel %v", accel_g), '16 16 0', '1 1 1', 1, 0);
		drawstring('0 200 0', sprintf("vel %v", player.velocity), '16 16 0', '1 1 1', 1, 0);
	}
	
	draw_hud();
	sui_begin(g_width, g_height);
	
	draw_sui();
	
	sui_end();
};

float(string cmd) CSQC_ConsoleCommand =
{
	tokenize(cmd);
	switch(argv(0))
	{
		case "reload":
			reload_with(active_weapon);
			return TRUE;
		case "swap":
			swap_weapon();
			return TRUE;
		case "toggleinventory":
			inventory_active = !inventory_active;
			return TRUE;
		default:
			return FALSE;
	}
	return TRUE;
};

float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	// sui_input_event(evtype, scanx, chary, devid);
	switch(evtype)
	{
	case IE_KEYDOWN:
		// big hack
		if (inventory_active && scanx == K_MOUSE1)
		{
			_sui_mouse1_down();
			return TRUE;
		}
		return FALSE;
	case IE_KEYUP:
		// big hack
		if (inventory_active && scanx == K_MOUSE1)
		{
			_sui_mouse1_up();
			return TRUE;
		}
		return FALSE;
	case IE_MOUSEDELTA:
		float sens = cvar("sensitivity");
		crosshair_pos_x += scanx * sens;
		crosshair_pos_y += chary * sens;
		crosshair_pos_x = bound(0, crosshair_pos_x, g_width);
		crosshair_pos_y = bound(0, crosshair_pos_y, g_height);
		
		// this is big hack
		if (inventory_active)
		{
			_sui_mouse_move(crosshair_pos);
			return TRUE;
		}
		return FALSE;
	case IE_MOUSEABS:
		cursor_pos_x = scanx;
		cursor_pos_y = chary;
		return FALSE;
	}
	return FALSE;
};

float() ring_predraw =
{
	if (light_pass) return PREDRAW_AUTOADD;

	self.scale += frametime * 4;
	self.frame1time += frametime * 1;
	self.alpha -= frametime * 2;
	add_light(self.origin, self.colormod * self.alpha, 48 * self.alpha);
	if (self.alpha < 0.01)
	{
		remove(self);
		remove_glowent(self);
		return PREDRAW_NEXT;
	}
	
	return PREDRAW_AUTOADD;
}

void(vector pos, vector color, float size) spawn_ring =
{
	entity ring = spawn();
	ring.drawmask = MASK_ENGINE;
	ring.predraw = ring_predraw;
	make_glowent(ring);
	setorigin(ring, pos);
	ring.colormod = color;
	ring.scale = size;
	ring.alpha = 0.5;
	setmodel(ring, "models/ring.iqm");
}

void() CSQC_Parse_Event =
{
	float first = readbyte();
	vector pos, vel, norm;
	float type, projid, playerid, target;
	switch(first) {
		case EV_SPAWN_PROJECTILE:
			pos = readvector();
			vel = readvector();
			type = readbyte();
			projid = readbyte();
			playerid = readshort();
			if (playerid != player_localentnum)
			{
				entity proj = spawn_projectile(pos, vel, type);
				proj.owner_entnum = playerid;
				proj.id = projid;
			}
			break;
		case EV_PROJECTILE_HIT:
			pos = readvector();
			norm = readvector();
			projid = readbyte();
			playerid = readshort();
			target = readshort();
			entity hitent = findfloat(world, entnum, target);
			if (playerid != player_localentnum)
			{
				projectile_hit(pos, norm, projid, playerid, hitent);
			}
			break;
		case EV_SET_INVENTORY:
			int index = readbyte();
			inv_item_id[index] = readbyte();
			inv_item_effect[index] = readbyte();
			inv_item_ammo[index] = readbyte();
			break;
		case EV_GIVE_AMMO:
			type = readbyte();
			int amount = readbyte();
			if (type == 0) ammo_bullets += amount;
			if (type == 1) ammo_shells += amount;
			if (type == 2) ammo_cells += amount;
			break;
		case EV_BOX_BREAK:
			pos = readvector();
			// spawn effect for box breaking here
			// light + particles
			spawn_ring(pos, '0.6 0.5 0.4', 1);
			break;
		case EV_CLEAR_MAP:
			clear_csqc_map();
			break;
		default:
			printf("No action for byte %f\n", first);
			break;
	}
};


float(string key, string val) find_player_id =
{
	for (int currentindex = 0; currentindex < maxclients; currentindex++)
	{
		if (getplayerkeyvalue(currentindex, key) == val) return currentindex;
	}
	return -1;
}

void(string printmsg, float printlvl) CSQC_Parse_Print =
{
	print(printmsg);
};
