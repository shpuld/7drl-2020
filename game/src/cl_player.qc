
void(entity e) make_glowent;
void(entity e) remove_glowent;
void(vector pos, vector col, float radius) add_light;


const float FRAME_IDLE = 0;
const float FRAME_RUN = 1;
const float FRAME_MELEE = 2;
const float FRAME_RELOAD = 3;
const float FRAME_SWAP = 4;

const float MELEE_SLOWDOWN = 0.2;

entity muzzleflash;
entity gunmodel;

float() muzzleflash_predraw =
{
	if (self.alpha < 0) return PREDRAW_NEXT;

	if (light_pass)
	{
		makevectors(player.angles);
    	setorigin(self, player.origin + '0 0 45' + v_forward * 28 + v_right * 6);
    	self.angles_y = player.angles_y;
		return PREDRAW_AUTOADD;
	}
	
	makevectors(player.angles);
	setorigin(self, player.origin + '0 0 45' + v_forward * 28 + v_right * 6);
	self.angles_y = player.angles_y;
	
	self.alpha -= frametime * 19;
	self.frame1time += frametime * 1.25;
	
	add_light(self.origin + v_forward * 30, '0.7 0.4 0.1' * self.alpha, self.alpha * 45);
	
	if (muzzleflash.alpha < 0)
	{
		remove_glowent(self);
		self.drawmask = 0;
	}
	
	return PREDRAW_AUTOADD;
}

void(entity pl, float weapon, float size) add_muzzleflash =
{
	size = size - 1;
	muzzleflash.alpha = 0.4 + random() * 0.5 + size;
	muzzleflash.scale = 1 + random() * 0.5 + size;
	muzzleflash.frame1time = 0 + random() * 0.1;
	muzzleflash.angles_z = random() * 360;
	muzzleflash.predraw = muzzleflash_predraw;
	muzzleflash.drawmask = MASK_ENGINE;
	muzzleflash.solid = SOLID_NOT;
	
	make_glowent(muzzleflash);
}

vector newcampos;
float meleetime;
.float oldframe;

void() player_play_run =
{
	float speed = vlen(self.velocity);
	self.frame2 = FRAME_RUN;
	if (speed > 20)
	{
		self.lerpfrac += frametime * 18;
		self.lerpfrac = min(1, self.lerpfrac);
		self.frame2time += frametime * speed * 0.005;
	}
	else
	{
		self.lerpfrac -= frametime * 10;
		self.lerpfrac = max(0, self.lerpfrac);
	}
}

float() player_predraw =
{
    if (self.entnum == player_localentnum)
    {
    	player = self;
		// Set renderflag for mirrors!
		// self.renderflags = RF_EXTERNALMODEL;
    }
    makevectors(self.angles);
    if (self.frame != self.oldframe) self.frame1time = 0;
    float speed = vlen(self.velocity);
    vector veldir = normalize(self.velocity);
    float sideways = v_right * veldir;
    float forwards = v_forward * veldir;
    //printf("side: %f, forward: %f\n", sideways, forwards);
    self.angles.x = -forwards * speed * 0.04 + camshake * 5;
    self.angles_z = sideways * speed * 0.06;
    if (self.frame == FRAME_IDLE)
    {
		self.frame = FRAME_IDLE;
		player_play_run();
	}
	else if (self.frame == FRAME_MELEE)
	{
		self.lerpfrac = max(0, self.lerpfrac - frametime * 20);
		self.frame1time += frametime;
		if (self.frame1time > 0.7) self.frame = FRAME_IDLE;
	}
	else if (self.frame == FRAME_RELOAD)
	{	
		if (self == player)
		{
			self.frame1time += (frameduration(self.modelindex, FRAME_RELOAD) * frametime * 0.95) / weapon_list[inv_item_id[active_weapon]].reload_time;
			if (time > reload_finished) self.frame = FRAME_IDLE;
		}
		else
		{
			self.frame1time += frametime * 0.8;
			if (self.frame1time > frameduration(self.modelindex, FRAME_RELOAD)) self.frame = FRAME_IDLE;
		}
		player_play_run();
		self.lerpfrac = min(0.35, self.lerpfrac);
	}
	else if (self.frame == FRAME_SWAP)
	{
		self.lerpfrac = min(0.3, self.lerpfrac);
		self.frame1time += frametime;
		if (self.frame1time > 0.15) self.frame = FRAME_IDLE;
	}
    // addentity(self);
    self.oldframe = self.frame;
    
    vector pos = gettaginfo(self, gettagindex(self, "armhand.R"));
    setorigin(gunmodel, pos - v_right * 4);
    gunmodel.angles = vectoangles(-v_right, -v_forward);
    setmodel(gunmodel, weapon_list[inv_item_id[active_weapon]].model);
    addentity(gunmodel);
    
    return PREDRAW_AUTOADD;
};

vector oldorg;
vector oldangles;
vector oldvel;
float oldflags;

void() set_input_movevalues;
void() predict_player =
{
	
	setorigin(player, oldorg);
	player.angles = oldangles;
	player.velocity = oldvel;
	player.flags = oldflags;
	
	for (int i = servercommandframe; i <= clientcommandframe; i++)
	{
		if (getinputstate(i))
		{
			// partial frame
			if (i == clientcommandframe)
			{
				set_input_movevalues();
			}
			input_angles = aim_normalized;
			player_move(player);
		}
		// runstandardplayerphysics(self);
	}
	setorigin(player, player.origin);
	newcampos = player.origin;
}

void(float isnew) player_update =
{
	if (isnew)
	{
		self.classname = "player";
		self.solid = SOLID_SLIDEBOX;
		self.predraw = player_predraw;
		self.drawmask = MASK_ENGINE;
		setmodel(self, "models/player.iqm");
	}	

	vector org = readvector();
	vector ang = readvector();
	vector vel = readvector();
	float fl = readfloat();

	self.movetype = MOVETYPE_WALK;
		
	setsize(self, '-16 -16 0', '16 16 64');
	
	// Apply physics for every single input-frame that has not yet been
	// acknowledged by the server (servercommandframe = last acknowledged frame)
	if(self.entnum == player_localentnum)
	{
		oldorg = org;
		oldangles = ang;
		oldvel = vel;
		oldflags = fl;
		/*
		for (int i = servercommandframe + 1; i <= clientcommandframe; i++)
		{
			getinputstate(i);
			// runstandardplayerphysics(self);
			player_move(self);
		}
		*/
		if (vlen(self.origin - oldorg) < 100)
		{
			self.origin = oldorg;
			self.angles = oldangles;
			self.velocity = oldvel;
			self.flags = oldflags;
		}
		
		// newcampos = self.origin;
		
		// getinputstate(clientcommandframe);
		// player_move(self);
		//newcamtime = time;
	}
	else
	{
		// print("non local\n");
		setorigin(self, org);
		self.angles = ang;
		self.velocity = vel;
		self.flags = fl;
	}
	// traceline('0 0 0', '0 0 100', 0, self);

	
	
	self.movetype = MOVETYPE_NONE;
}

const int MAX_PROJECTILES = 256;
// entity player_projectiles[MAX_PROJECTILES];
float current_projectile;

.float projectile_type;
.float id;
.float owner_entnum;

void() move_projectile =
{
	vector newpos = self.origin + self.velocity * frametime;
	
	if (self.owner)
	{
		traceline(self.origin, newpos, 0, self.owner);
		if (!trace_startsolid) self.origin = trace_endpos;
		if (trace_fraction < 1 || trace_startsolid)
		{
			self.velocity = '0 0 0';
			entity oldother = other;
			other = trace_ent;
			if (self.touch) self.touch();
			other = oldother;
		}
		
	}
	else
	{
		self.origin = newpos;
	}
};

float() bullet_predraw = 
{
	if (light_pass) return PREDRAW_AUTOADD;
		
	move_projectile();
	
	if (vlen(self.velocity) > 0)
		add_light(self.origin, '0.3 0.2 0.1', 15 * self.scale);
	else
		add_light(self.origin, '0.6 0.4 0.2' * 5 * (self.nextthink - time), self.scale * 100 * (self.nextthink - time));

	return PREDRAW_AUTOADD;
};

float() pellet_predraw = 
{
	if (light_pass) return PREDRAW_AUTOADD;
		
	move_projectile();
	
	if (vlen(self.velocity) > 0)
		add_light(self.origin, '0.3 0.2 0.1', 8 * self.scale);
	else
		add_light(self.origin, '0.6 0.4 0.2' * 5 * (self.nextthink - time), self.scale * 60 * (self.nextthink - time));

	return PREDRAW_AUTOADD;
};

void() remove_spark =
{
	remove_glowent(self);
	remove(self);
};

float() spark_predraw =
{
	if (light_pass) return PREDRAW_AUTOADD;
	
	self.origin += self.velocity * frametime;
	self.scale -= frametime * 12;
	if (self.scale <= 0.01)
	{
		remove_glowent(self);
		remove(self);
		return PREDRAW_NEXT;
	}
	return PREDRAW_AUTOADD;
};



void(entity projectile) send_projectile =
{
	int index = current_projectile + 1;
	if (index >= MAX_PROJECTILES) index -= MAX_PROJECTILES;
	// if (player_projectiles[index]) continue;
	
	// player_projectiles[index] = projectile;
	projectile.id = index;
	vector parms = [projectile.projectile_type, index, 0];
	sendevent("sproj", "vvv", projectile.origin, projectile.velocity, parms);
	current_projectile = index;
};

void(entity projectile) remove_projectile =
{
	// player_projectiles[projectile.id] = world;
};

void() clean_projectile =
{
	if (self.owner) remove_projectile(self);
	remove_glowent(self);
	remove(self);
};

entity(vector org, vector vel, float type) spawn_projectile =
{
	entity proj = spawn();
	proj.solid = SOLID_NOT;
	setorigin(proj, org);
	proj.velocity = vel;
	proj.angles = vectoangles(vel);
	proj.projectile_type = type;
	proj.drawmask = MASK_ENGINE;
	proj.effects = EF_ADDITIVE | EF_FULLBRIGHT;
	proj.nextthink = time + 1.2;
	proj.think = clean_projectile;
	
	switch (type)
	{
		case PT_SMALL_BULLET:
			setmodel(proj, "models/bullet.iqm");
			proj.scale = 0.8;
			proj.predraw = bullet_predraw;
			make_glowent(proj);
			break;
		case PT_MEDIUM_BULLET:
			setmodel(proj, "models/bullet.iqm");
			proj.scale = 1.1;
			proj.predraw = bullet_predraw;
			make_glowent(proj);
			break;
		case PT_BIG_BULLET:
			setmodel(proj, "models/bullet.iqm");
			proj.scale = 1.4;
			proj.predraw = bullet_predraw;
			make_glowent(proj);
			break;
		case PT_PELLET:
			setmodel(proj, "models/bullet.iqm");
			proj.scale = 0.9;
			proj.predraw = pellet_predraw;
			make_glowent(proj);
			break;
		default:
			break;
	}
	return proj;
}

void(vector org, vector n, entity target) bullet_hit =
{
	self.nextthink = time + 0.2;
	self.think = sub_remove;
	self.modelindex = 0;
	self.solid = SOLID_NOT;
	self.touch = sub_noop;
	remove_glowent(self);
	self.origin = org;
	self.velocity = '0 0 0';
	
	int numsparks = 2 + random() * 3;
	for (int i = 0; i < numsparks;  i++)
	{
		entity spark = spawn();
		spark.solid = SOLID_NOT;
		setmodel(spark, "models/bullet.iqm");
		spark.velocity = (n + randomvec()) * 1000;
		spark.origin = org + spark.velocity * 0.0005;
		spark.velocity_z *= 0.1;
		spark.scale = 0.9;
		spark.drawmask = MASK_ENGINE;
		spark.predraw = spark_predraw;
		spark.effects = EF_ADDITIVE | EF_FULLBRIGHT;
		spark.angles = vectoangles(spark.velocity);
		make_glowent(spark);
	}
};


void(vector pos, vector normal, float proj_id, float owner, entity target) projectile_hit =
{
	entity head = findfloat(world, owner_entnum, owner);
	while (head)
	{
		if (head.id == proj_id)
		{
			// printf("remove %f, %f\n", proj_id, owner);
			
			entity oself = self;
			self = head;
			bullet_hit(pos, normal, target);
			self = oself;
			return;
		}
		head = findfloat(head, owner_entnum, owner);
	}
}

void(entity proj, vector n, entity target) send_hit = 
{
	sendevent("projhit", "vvv", proj.origin, n, [proj.id, target.entnum, proj.dmg]);
}


void() test_projectile_touch =
{
	send_hit(self, trace_plane_normal, other);
	remove_projectile(self);
	bullet_hit(self.origin, trace_plane_normal, other);
};

vector() aimangles =
{
	vector ang = -vectoangles(aim_normalized);
	if (ang_y < 0) ang_y += 360;
	return ang;
};


float(float slot) max_ammo_for =
{
	float item = inv_item_id[slot];
	
	float mag_size_mod = 1;
	item_effect * w_ef = &weapon_effects[inv_item_effect[slot]];
	if (w_ef->effect1 == IEF_MAGSIZE) mag_size_mod += 0.2 * w_ef->level1; 
	if (w_ef->effect2 == IEF_MAGSIZE) mag_size_mod += 0.2 * w_ef->level2; 
	
	float base_size = weapon_list[item].mag_size;
	
	return ceil(base_size * mag_size_mod);
};

void(float slot) reload_fill =
{
	sound(player, CHAN_ITEM, "sounds/reload3.wav", 1, 0.2);
	float item = inv_item_id[slot];

	float leftinmag = inv_item_ammo[slot];
	reloading = FALSE;
	
	inv_item_ammo[slot] = max_ammo_for(slot);
	weapon_mags[item] -= 1;
	reload_finished = time + 0.2;
};

void(float slot) reload_with =
{
	// attack_finished is time until reload_fill, when mag gets filled
	float item = inv_item_id[slot];
	
	if (weapon_mags[item] <= 0) return;
	if (inv_item_ammo[slot] >= max_ammo_for(slot)) return;
	if (time < reload_finished) return;

	float reload_time_mod = 1;
	
	sound(player, CHAN_ITEM, "sounds/reload1.wav", 1, 0.2);
	player.frame = FRAME_RELOAD;
	player.frame1time = 0;
	
	item_effect * w_ef = &weapon_effects[inv_item_effect[slot]];
	if (w_ef->effect1 == IEF_RELOADSPEED) reload_time_mod -= 0.1 * w_ef->level1; 
	if (w_ef->effect2 == IEF_RELOADSPEED) reload_time_mod -= 0.1 * w_ef->level2; 
	
	reloading = TRUE;
	reload_finished = time + weapon_list[item].reload_time * reload_time_mod;
}

void(float slot) shoot_with =
{
	entity e;
	float item = inv_item_id[slot];
	float firerate_mod = 1;
	float acc_mod = 1;
	float dmg_mod = 1;
	
	item_effect * w_ef = &weapon_effects[inv_item_effect[slot]];
	if (w_ef->effect1 == IEF_FIRERATE) firerate_mod -= 0.1 * w_ef->level1; 
	if (w_ef->effect2 == IEF_FIRERATE) firerate_mod -= 0.1 * w_ef->level2; 
	
	if (w_ef->effect1 == IEF_ACCURACY) acc_mod -= 0.1 * w_ef->level1; 
	if (w_ef->effect2 == IEF_ACCURACY) acc_mod -= 0.1 * w_ef->level2;
	
	if (w_ef->effect1 == IEF_DAMAGE) dmg_mod += 0.1 * w_ef->level1;
	if (w_ef->effect2 == IEF_DAMAGE) dmg_mod += 0.1 * w_ef->level2; 
	
	vector angles = aimangles();
	makevectors(angles);
	
	
	if (inv_item_ammo[slot] <= 0)
	{
		attack_finished = time + 0.1;
		reload_with(slot);
		return;
	}
	
	weapon * wep = &(weapon_list[inv_item_id[slot]]);
	
	vector spawn_ofs = player.origin + '0 0 40' + v_forward * 24 + v_right * 4;
	float muzzleflashsize =
		wep->proj_type == PT_SMALL_BULLET ? 1.0 :
		wep->proj_type == PT_MEDIUM_BULLET ? 1.3 :
		wep->proj_type == PT_BIG_BULLET ? 1.5 :
		wep->proj_type == PT_PELLET ? 1.6 : 1.0;
	
	camshake = muzzleflashsize * 0.75;
		
	add_muzzleflash(self, item, muzzleflashsize);
	sound(player, CHAN_WEAPON, strcat("sounds/", wep->sample), 1, 0.25, wep->soundspeed + crandom() * 2);
	inv_item_ammo[slot] -= 1;
	float speed = 1200 + (wep->damage * dmg_mod) * 90;
	for (int i = 0; i < wep.proj_per_shot; i++)
	{	
		float spread = (1 - wep->accuracy) * (speed / 2) * acc_mod;
		e = spawn_projectile(spawn_ofs, v_forward * (speed + (random() * wep.proj_per_shot * 250)) + v_right * spread * spread_random(), wep->proj_type);
		e.touch = test_projectile_touch;
		e.owner = self;
		e.dmg = ceil(wep->damage * dmg_mod);
		send_projectile(e);
		attack_finished = time + wep->fire_rate * firerate_mod;
	}
	
	if (inv_item_ammo[slot] == 0) attack_finished = time + 0.3;
}

void() melee_hit =
{
	vector angles = aimangles();
	makevectors(angles);
	entity e = findradius(player.origin, 80);
	float meleedmg = 25;
	print("Melee\n");
	
	while (e)
	{
		vector to_ent = e.origin - player.origin;
		if (normalize(to_ent) * v_forward > 0.6 && e.is_enemy)
		{
			sendevent("meleehit", "vvv", 0.5 * (e.origin + player.origin), normalize(to_ent), [e.entnum, meleedmg]);
		}
		
		e = e.chain;
	}
}

void() melee_attack =
{
	player.nextthink = time + 0.3;
	player.think = melee_hit;
	player.frame = FRAME_MELEE;
	player.frame1time = 0;
	
	if (reloading)
	{
		reloading = FALSE;
		reload_finished = 0;
	}
	
	attack_finished = time + 0.8;
}

void(float slot) drop_item =
{
	if (inv_item_id[slot] == 0) return;
	
	// handle dropping weapons differently because they have ammo and spare mags
	if (slot < 2)
	{
		float item = inv_item_id[slot];
		float dropping_ammo = inv_item_ammo[slot];
		// don't drop spare mags if the other gun uses the same ammo
		float dropping_mags = inv_item_id[!slot] == item ? 0 : weapon_mags[item];
		weapon_mags[item] = dropping_mags ? 0 : weapon_mags[item];
		sendevent("dropitem", "fff", slot, dropping_ammo, dropping_mags);
	}
	else
	{
		sendevent("dropitem", "f", slot);
	}
	
	inv_item_ammo[slot] = 0;
	inv_item_id[slot] = 0;
	inv_item_effect[slot] = 0;
	attack_finished = 0;
	reload_finished = 0;
	reloading = FALSE;
	self.frame = FRAME_SWAP;
	self.frame1time = 0;
	
}

void() swap_weapon =
{
	if (time < attack_finished) return;
	// hack
	self.velocity *= 0.3;
	reloading = FALSE;
	reload_finished = 0;
	attack_finished = time + 0.1;
	active_weapon = !active_weapon;
	self.frame = FRAME_SWAP;
	self.frame1time = 0;
}

void() set_input_movevalues =
{
	if (!player)
	{
		input_movevalues = '0 0 0';
		return;
	}

	float basespeed = 220;
	input_movevalues_x = bound(-basespeed, input_movevalues_x, basespeed);
	input_movevalues_y = bound(-basespeed, input_movevalues_y, basespeed);
	input_movevalues_z = bound(-basespeed, input_movevalues_z, basespeed);
	if (vlen(input_movevalues) > basespeed) input_movevalues = normalize(input_movevalues) * basespeed;
	
	if (player.frame == FRAME_MELEE)
	{
		input_movevalues *= MELEE_SLOWDOWN;
	}
	
	if (player.frame == FRAME_RELOAD)
	{
		input_movevalues *= 0.65;
	}
	
	float weapon_speed = (weapon_list[inv_item_id[active_weapon]].move_speed);
	float speed_mod = weapon_speed ? weapon_speed : 1;
	item_effect * w_ef = &weapon_effects[inv_item_effect[active_weapon]];
	if (w_ef->effect1 == IEF_MOVESPEED) speed_mod += 0.05 * w_ef->level1; 
	if (w_ef->effect2 == IEF_MOVESPEED) speed_mod += 0.05 * w_ef->level2; 
	input_movevalues *= speed_mod;
}

void() CSQC_Input_Frame =
{
	set_input_movevalues();
	
	input_angles = aim_normalized;

	if (!player) return;
	
	if (reloading && time >= reload_finished)
	{
		reload_fill(active_weapon);
	}
	else if (input_buttons & 1 && time >= attack_finished && time >= reload_finished)
	{
		shoot_with(active_weapon);
	}
	else if (input_buttons & 2 && time >= attack_finished)
	{
		melee_attack();
	}
};


