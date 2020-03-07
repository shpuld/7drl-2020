
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
const int MAX_LIGHTS = 160;
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


// #define CSQC_TEST
void() run_cl_unit_tests =
{
	print("Running  CSQC unit tests...\n");
	// Add tests here
	print("Tests complete!\n");
};

float(float isnew) enemylisten =
{
	setsize(self, '-20 -20 0', '20 20 50');
	self.is_enemy = TRUE;
	
	if (self.solid != SOLID_NOT)
		add_light(self.origin + '0 0 48', '0.2 0.1 0.1', 7);
	
	return TRUE;
};

float(float isnew) cratelisten =
{
	setsize(self, '-24 -24 0', '24 24 50');
	self.is_enemy = 2;
	add_light(self.origin + '0 8 24', '0.1 0.4 0.1', 6);
	return TRUE;
};

float(float isnew) ammolisten =
{
	add_light(self.origin + '0 0 8', '0.3 0.3 0.1', 5);
	return TRUE;
};

float(float isnew) medkitlisten =
{
	add_light(self.origin + '0 0 8', '0.15 0.2 0.3', 5);
	return TRUE;
};

float(float isnew) powermodlisten =
{
	float intensity = sin(time * 2.5)*0.3 + 1.2;
	add_light(self.origin + '0 0 0', [0.4 * intensity, 0.25 * intensity, 0.1 * intensity], 6 * intensity);
	return TRUE;
};

float(float isnew) ladderlisten =
{
	float intensity = sin(time * 4) + 0.4;
	add_light(self.origin + '0 32 0', [intensity, 0.1 * intensity, 0.1 * intensity], 12 * intensity);
	return TRUE;
};

float explosion_time;
float(float isnew) machinelisten =
{
	float intensity = sin(time * 4) + 0.4;
	add_light(self.origin + '0 0 32', [intensity, 0.1 * intensity, 0.1 * intensity], 12 * intensity);
	setsize(self, '-24 -24 0', '24 24 50');
	self.is_enemy = 2;
	
	if (time > explosion_time && victorytime)
	{
		spawn_ring(self.origin + '0 0 80' + randomvec() * 40, '0.8 0.5 0.2' + randomvec() * 0.2, 1 + random() * 4);
		explosion_time = time + 0.05 + random() * 0.3;
		sound(self, CHAN_WEAPON, "sounds/t75.wav", 1, 0.4, 80 + random() * 30);
	}
	return TRUE;
};

.int lighti;
float(float isnew) lightlisten =
{
	if (isnew && !self.lighti)
	{
		vector colorbase;
		if (self.frame == 0) colorbase =
			current_level >= LEVEL_HECK ? '0.5 0.4 0.3' :
			current_level >= LEVEL_RUST ? '0.3 0.4 0.2' :
			current_level >= LEVEL_INSIDE ? '0.3 0.4 0.4' :
			'0.2 0.5 0.4';
		else colorbase =
			current_level >= LEVEL_HECK ? '0.5 0.4 0.3' :
			current_level >= LEVEL_RUST ? '0.3 0.4 0.2' :
			current_level >= LEVEL_INSIDE ? '0.3 0.15 0.1' :
			'0.1 0.3 0.2'; 
		
		float radius = self.frame == 0 ? 33 + random() * 15 : 18 + random() * 6;
		add_static_light(self.origin, 0.8 * colorbase + randomvec() * 0.07, radius);
	}
	
	if (current_level < LEVEL_INSIDE)
	{
		if (self.frame == 0) add_light(self.origin, '0.2 0.2 0.2', 5 + 2*sin(time*50));
		return TRUE;
	}
	self.modelindex = 0;
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
	deltalisten("models/zombiegunner.iqm", enemylisten, 0);
	deltalisten("models/hellgunner.iqm", enemylisten, 0);
	deltalisten("models/icegunner.iqm", enemylisten, 0);
	deltalisten("models/greengunner.iqm", enemylisten, 0);
	deltalisten("models/zombieberserker.iqm", enemylisten, 0);
	deltalisten("models/iceberserker.iqm", enemylisten, 0);
	deltalisten("models/hellberserker.iqm", enemylisten, 0);
	deltalisten("models/greenberserker.iqm", enemylisten, 0);
	deltalisten("models/crate.iqm", cratelisten, 0);
	deltalisten("models/ladderdown.iqm", ladderlisten, 0);
	deltalisten("models/machine.iqm", machinelisten, 0);
	deltalisten("models/power_mod.iqm", powermodlisten, 0);
	deltalisten("models/bullets_ammo.iqm", ammolisten, 0);
	deltalisten("models/medkit.iqm", medkitlisten, 0);
	deltalisten("models/glowstick.iqm", lightlisten, 0);
	
	registercommand("reload");
	registercommand("swap");
	registercommand("toggleinventory");
	registercommand("dropgun");
	
	exittime = entertime = -10;
	
	#ifdef CSQC_TEST
	run_cl_unit_tests();
	#endif
};

void() CSQC_WorldLoaded =
{
	/*
	for (int i = 0; i < MAX_LIGHTS; i++)
	{
		add_static_light([MAP_ORIGIN_x + random() * 64 * 32, MAP_ORIGIN_y + random() * 64 * 48, 50], [random() * 0.1 + 0.2, random() * 0.1 + 0.2, random() * 0.2 + 0.2], 10 + random() * 28);
	}
	*/
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

vector overlayofs;
// CALLED EVERY CLIENT RENDER FRAME

float oneshot_ambient_time;
float oneshot_wind_time;

void(float width, float height, float menushown) CSQC_UpdateView =
{
	if (cvar("r_clear") != 8) cvar_set("r_clear", "8");
	//clear and update our global screen resolution vars
	g_width = width;
	g_height = height;
	current_level = getstatf(STAT_LEVEL);
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
	
	if (time > oneshot_ambient_time)
	{
		if (current_level < LEVEL_INSIDE)
			sound(world, CHAN_AUTO, "sounds/oneshotwind.wav", 1.0, 0, 90 + random() * 20);
		else
			sound(world, CHAN_AUTO, sprintf("sounds/oneshot%.0f.wav", 1 + rint(random())), 0.6, 0);
		oneshot_ambient_time = time + 8 + random() * 12;
	}
	
	if (time > oneshot_wind_time && current_level < LEVEL_INSIDE)
	{
		sound(world, CHAN_AUTO, sprintf("sounds/wind%.0f.wav", 1 + floor(random() * 4)), 1.0, 0, 110 + random() * 20);
		oneshot_wind_time = time + 1.5 + random() * 1.5;
	}
	
	if (time > oneshot_wind_time && current_level >= LEVEL_INSIDE)
	{
		sound(world, CHAN_AUTO, sprintf("sounds/wind%.0f.wav", 1 + floor(random() * 4)), 0.4, 0, 60 + random() * 20);
		oneshot_wind_time = time + 2.5 + random() * 2.0;
	}


	//autoadd entities received from servers for drawing	
	addentities(MASK_ENGINE);

	if (csqc_mapgeom)
	{
		float row = max(rint((campos_y - MAP_ORIGIN_y) / BLOCK_SIZE_y) - 8, 0);
		draw_map_geom(csqc_mapgeom, row, 16);
	}
	
	float level = campos_x > 7000 ? LEVEL_INSIDE : current_level;
	string texture = level >= LEVEL_HECK ? "ash" :
		level >= LEVEL_RUST ? "fog2" :
		level >= LEVEL_INSIDE ? "fog" :
		"snowfall";
		
	vector overlaydelta =
		level >= LEVEL_HECK ? [frametime * 0.1, frametime * -0.4] :
		level >= LEVEL_RUST ? [frametime * 0.15, frametime * -0.2] :
		level >= LEVEL_INSIDE ? [frametime * 0.15, frametime * -0.1] :
		[frametime * (0.9 + 0.15*sin(time*5)), frametime * (1.2 + 0.04*sin(time*7))];
	
	R_BeginPolygon(texture);
	
	overlayofs += overlaydelta;
	vector camofs = [campos_x, campos_y] * 0.008;
	vector ofs = overlayofs + camofs;

	R_PolygonVertex(campos + '-160 -160 -200', ofs + [0, 0], '1 1 1', 1);
	R_PolygonVertex(campos + '-160 160 -200', ofs + [0, 4], '1 1 1', 1);
	R_PolygonVertex(campos + '160 160 -200', ofs + [4, 4], '1 1 1', 1);
	R_PolygonVertex(campos + '160 -160 -200', ofs + [4, 0], '1 1 1', 1);
	
	R_EndPolygon();
	
	ofs = overlayofs + camofs * 0.75;
	R_PolygonVertex(campos + '-160 -160 -200', ofs + [0, 0], '1 1 1', 1);
	R_PolygonVertex(campos + '-160 160 -200', ofs + [0, 6], '1 1 1', 1);
	R_PolygonVertex(campos + '160 160 -200', ofs + [6, 6], '1 1 1', 1);
	R_PolygonVertex(campos + '160 -160 -200', ofs + [6, 0], '1 1 1', 1);
	
	R_EndPolygon();
	
	//does what you think it does
	renderscene();
	drawpic([0, 0], "lights_postproc", [width, height], [0.25, 0.25, 0.25], 1, 0);
	
	
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
		case "dropgun":
			drop_item(active_weapon);
			// if (inv_item_id[!active_weapon]) swap_weapon();
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
	add_light(self.origin, self.colormod * self.alpha, 60 * self.alpha);
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
	ring.angles_y = random()*360;
	setmodel(ring, "models/ring.iqm");
}

float() enemy_projectile_predraw =
{
	if (light_pass) return PREDRAW_AUTOADD;

	vector startpos = self.origin;
	vector endpos = self.origin + self.velocity * frametime;
	self.angles += self.avelocity * frametime;
	switch (self.type)
	{
		case EPT_MELEE:
			other = player;
			tracebox(startpos, self.mins, self.maxs, endpos, MOVE_OTHERONLY, self);
			self.alpha -= frametime * 3;
			break;
		case EPT_CANNON:
			traceline(startpos, endpos, 0, self);
			add_light(self.origin + normalize(self.velocity)*32, '0.4 0.2 0.1', 24);
			break;
		case EPT_GREEN:
			traceline(startpos, endpos, 0, self);
			add_light(self.origin + normalize(self.velocity)*32, '0.2 0.4 0.1', 16);
			break;
		default:
			traceline(startpos, endpos, 0, self);
			add_light(self.origin + normalize(self.velocity)*16, '0.3 0.1 0.1', 8);
			break;
	}
	
	if (!trace_startsolid)
		setorigin(self, trace_endpos);
	
	if (trace_fraction < 1 || trace_startsolid)
	{
		float defmod = get_effect_level(IEF_DEFENSE, active_weapon);
		if (trace_ent == player) sendevent("took_damage", "ff", max(3, floor(self.dmg * (1 - defmod * 0.075))), self.owner.entnum);
		
		switch (self.type)
		{
			case EPT_MELEE:
				spawn_ring(self.origin, '0.3 0.3 0.3', 0.7);
				break;
			case EPT_CANNON:
				spawn_ring(self.origin, '0.5 0.3 0.2', 1.2);
				break;
			case EPT_GREEN:
				spawn_ring(self.origin, '0.3 0.6 0.2', 0.9);
				break;
			default:
				spawn_ring(self.origin, '0.4 0.3 0.2', 0.7);
				break;
		}
		remove_glowent(self);
		remove(self);
		
		return PREDRAW_NEXT;
	}
	return PREDRAW_AUTOADD;
}

void() remove_enemy_projectile =
{
	remove_glowent(self);
	remove(self);
}

void(vector pos, vector vel, float proj_type, float owner_entnum, float target) spawn_enemy_projectile =
{
	if (target == player_localentnum) 
	{
		vel = player.origin - pos;
		vel_z = 0;
		vel = normalize(vel);
	}
	entity proj = spawn();
	setorigin(proj, pos);
	proj.solid = SOLID_NOT;
	proj.predraw = enemy_projectile_predraw;
	proj.drawmask = MASK_ENGINE;
	proj.velocity = vel;
	proj.angles = vectoangles(vel);
	proj.think = remove_enemy_projectile;
	proj.owner = findfloat(world, entnum, owner_entnum);
	proj.type = proj_type;
	proj.alpha = 1;
	proj.effects = EF_FULLBRIGHT;
	make_glowent(proj);
	
	switch (proj_type)
	{
		case EPT_MELEE:
			setmodel(proj, "models/melee_proj.iqm");
			setsize(proj, '-16 -16 0', '16 16 8');
			proj.dmg = 20 + floor(random() * 15);
			proj.nextthink = time + 0.25;
			proj.velocity *= 220;
			proj.avelocity = '0 360 0';
			proj.scale = 1.25;
			break;
		case EPT_MELEE_STRONG:
			setmodel(proj, "models/melee_proj.iqm");
			setsize(proj, '-20 -20 0', '20 20 8');
			proj.dmg = 30 + floor(random() * 15);
			proj.nextthink = time + 0.25;
			proj.velocity *= 210;
			proj.avelocity = '0 360 0';
			proj.scale = 1.25;
			break;
		case EPT_BULLET:
			setmodel(proj, "models/bullet.iqm");
			setsize(proj, '0 0 0', '0 0 0');
			proj.dmg = 13 + floor(random() * 6);
			proj.nextthink = time + 1;
			proj.velocity *= 720;
			spawn_ring(proj.origin, '0.4 0.3 0.2', 0.7);
			sound(proj, CHAN_AUTO, "sounds/ShotSMGEQOther.wav", 0.9, 0.8);
			break;
		case EPT_CANNON:
			setmodel(proj, "models/bullet.iqm");
			proj.scale = 2;
			setsize(proj, '0 0 0', '0 0 0');
			proj.dmg = 23 + floor(random() * 6);
			proj.nextthink = time + 1;
			proj.velocity *= 850;
			spawn_ring(proj.origin, '0.7 0.3 0.2', 0.9);
			sound(proj, CHAN_AUTO, "sounds/ShotSMGEQOther.wav", 1.0, 0.8, 70);
			sound(proj, CHAN_AUTO, "sounds/ShotSMGEQ.wav", 0.8, 0.8, 90);
			break;
		case EPT_GREEN:
			setmodel(proj, "models/slime.iqm");
			proj.scale = 1;
			setsize(proj, '0 0 0', '0 0 0');
			proj.dmg = 23 + floor(random() * 6);
			proj.nextthink = time + 1;
			proj.velocity *= 800;
			spawn_ring(proj.origin, '0.5 0.8 0.3', 0.9);
			sound(proj, CHAN_AUTO, "sounds/ShotSMGEQOther.wav", 1.0, 0.8, 70);
			sound(proj, CHAN_AUTO, "sounds/ShotSMGEQ.wav", 0.8, 0.8, 90);
			break;
		default:
			setmodel(proj, "models/ring.iqm");
			setsize(proj, '0 0 0', '0 0 0');
			proj.dmg = 10;
			proj.nextthink = time + 1;
			proj.velocity *= 300;
			break;
	}
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
			sound(self, CHAN_AUTO, "sounds/reloadbegin.wav", 0.8, 0, 120);
			int index = readbyte();
			float id = readbyte();
			inv_item_id[index] = id;
			inv_item_effect[index] = readbyte();
			inv_item_ammo[index] = readbyte();
			float mags = readbyte();
			if (index < 2)
			{
				// shared ammo between the guns
				if (inv_item_id[!index] == id)
					weapon_mags[id] += mags;
				else
					weapon_mags[id] = mags;
			}
			break;
		case EV_GIVE_AMMO:
			sound(self, CHAN_AUTO, "sounds/reloadbegin.wav", 0.8, 0, 110);
			type = readbyte();
			int amount = readbyte();
			weapon_mags[type] = min(10, weapon_mags[type] + amount);
			break;
		case EV_BOX_BREAK:
			pos = readvector();
			// spawn effect for box breaking here
			// light + particles
			pointsound(pos, "sounds/meleehit-old2.wav", 1, 0.2);
			spawn_ring(pos, '0.6 0.5 0.4', 1);
			break;
		case EV_CLEAR_MAP:
			clear_csqc_map();
			clear_static_lights();
			break;
		case EV_ENEMY_PROJECTILE:
			type = readbyte();
			float owner = readshort();
			target = readshort();
			pos = readvector();
			vel = readvector();
			spawn_enemy_projectile(pos, vel, type, owner, target);
			break;
		case EV_ENTER_LEVEL:
			sound(world, CHAN_AUTO, "sounds/ladderdown.wav", 0.9, 0);
			entertime = time;
			break;
		case EV_EXIT_LEVEL:
			sound(world, CHAN_AUTO, "sounds/ladderdown.wav", 0.9, 0);
			exittime = time;
			break;
		case EV_VICTORY:
			victorytime = time;
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
