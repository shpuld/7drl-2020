//shared definitions

const float EV_SPAWN_PROJECTILE = 10;
const float EV_PROJECTILE_HIT = 11;
const float EV_SET_INVENTORY = 12;
const float EV_GIVE_AMMO = 13;
const float EV_BOX_BREAK = 14;
const float EV_CLEAR_MAP = 15;

const int INV_SIZE = 6;
const int INV_SLOT_WEAPON1 = 0;
const int INV_SLOT_WEAPON2 = 1;
const int INV_SLOT_ARMOR = 2;
const int INV_SLOT_TRINKET1 = 3;
const int INV_SLOT_TRINKET2 = 4;
const int INV_SLOT_TRINKET3 = 5;

.float clearable;

// Projectile Types
enum {
	PT_SMALL_BULLET, PT_MEDIUM_BULLET, PT_BIG_BULLET, PT_PELLET, PT_PLASMA, PT_LASER
};

// Item Types
enum {
	IT_WEAPON, IT_ARMOR, IT_TRINKET
};

// Items
.float item_id;
enum {
	I_EMPTY,
	I_SMG, I_AR, I_SG, I_RIFLE,
	I_FLAKVEST,
	I_FASTRELOAD, I_SPEED, I_SHARPSHOOTER, I_DODGER, I_VAMPIRIC
};

string item_names[] = {
	"",
	"SMG", "Assault Rifle", "Shotgun", "Rifle",
	"Flak Vest",
	"Fast Reload", "Speed Boost", "Sharpshooter", "Dodger", "Vampiric"
};

.float item_effect;

// Item Effects
enum {
	IEF_NONE, IEF_DAMAGE, IEF_DEFENSE, IEF_ACCURACY, IEF_FIRERATE, IEF_RELOADSPEED, IEF_MOVESPEED, IEF_MAGSIZE, IEF_VAMPIRIC
};

struct item_effect {
	string name;
	float effect1;
	float level1;
	float effect2;
	float level2;
};

string(float ef) effect_stat_name =
{
	switch (ef)
	{
		case IEF_DAMAGE: return "Damage";
		case IEF_DEFENSE: return "Defense";
		case IEF_ACCURACY: return "Accuracy";
		case IEF_FIRERATE: return "Fire Rate";
		case IEF_RELOADSPEED: return "Reload Speed";
		case IEF_MOVESPEED: return "Movement Speed";
		case IEF_MAGSIZE: return "Mag Size";
		case IEF_VAMPIRIC: return "Life Steal";
		default: return "";
	}
}

item_effect weapon_effects[] = 
{
	{ "", IEF_NONE, 0, IEF_NONE, 0 },
	{ "Bad", IEF_DAMAGE, -3, IEF_ACCURACY, -3 },
	{ "Bad", IEF_DAMAGE, -2, IEF_ACCURACY, -4 },
	{ "Bad", IEF_DAMAGE, -4, IEF_ACCURACY, -2 },
	{ "Slow", IEF_RELOADSPEED, -2, IEF_FIRERATE, -2 },
	{ "Slow", IEF_RELOADSPEED, -3, IEF_FIRERATE, -1 },
	{ "Heavy", IEF_DAMAGE, 4, IEF_MOVESPEED -3 },
	{ "Heavy", IEF_DAMAGE, 2, IEF_MOVESPEED -2 },
	{ "Precise", IEF_ACCURACY, 5, IEF_FIRERATE, -2 },
	{ "Precise", IEF_ACCURACY, 3, IEF_FIRERATE, -1 },
	{ "Junk", IEF_FIRERATE, -5, IEF_ACCURACY, -5 },
	{ "Junk", IEF_FIRERATE, -4, IEF_ACCURACY, -4 },
	{ "Stellar", IEF_FIRERATE, 3, IEF_DAMAGE, 2 },
	{ "Stellar", IEF_FIRERATE, 2, IEF_DAMAGE, 3 },
	{ "Light", IEF_MOVESPEED, 3, IEF_RELOADSPEED, 2 }, 
	{ "Light", IEF_MOVESPEED, 2, IEF_RELOADSPEED, 3 }, 
	{ "Large", IEF_MOVESPEED, -1, IEF_MAGSIZE, 5 }, 
	{ "Large", IEF_MOVESPEED, -2, IEF_MAGSIZE, 8 }, 
	{ "Vampiric", IEF_VAMPIRIC, 2, IEF_NONE, 0 },
};

string(float effect, float which) weapon_stats_string =
{
	float ef;
	if (which == 2) ef = weapon_effects[effect].effect2;
	else ef = weapon_effects[effect].effect1;
	float level;
	if (which == 2) level = weapon_effects[effect].level2;
	else level = weapon_effects[effect].level1;
	
	if (ef == IEF_NONE) return "";
	
	string sign = level > 0 ? "+" : "";
	return sprintf("%s%.0f %s", sign, level, effect_stat_name(ef));
}

int(int slot) type_for_slot =
{
	switch (slot)
	{
	case INV_SLOT_WEAPON1:
	case INV_SLOT_WEAPON2:
		return IT_WEAPON;
	case INV_SLOT_ARMOR:
		return IT_ARMOR;
	case INV_SLOT_TRINKET1:
	case INV_SLOT_TRINKET2:
	case INV_SLOT_TRINKET3:
		return IT_TRINKET;
	default:
		return -1;
	}
}


// Weapons, define guns with as little customization in code as possible

struct weapon {
	string name;
	string model;
	float damage;
	float accuracy;
	float proj_type;
	float proj_per_shot;
	float fire_rate;
	float reload_time;
	float mag_size;
	float move_speed;
};

weapon weapon_list[] = {
	{ "", "", 0, 0, 0, 0, 0, 0, 0, 0 },
	{ "SMG", "models/smg.iqm", 10, 0.7, PT_SMALL_BULLET, 			1, 0.075, 1.4, 50, 0.9 },
	{ "Micro SMG", "models/minismg.iqm", 8, 0.6, PT_SMALL_BULLET, 	1, 0.05, 1.1, 40, 1.0 },
	{ "Combat Rifle", "models/ar.iqm", 14, 0.75, PT_MEDIUM_BULLET, 	1, 0.15, 1.5, 30, 0.8 },
	{ "Bullpup", "models/bullpup.iqm", 16, 0.85, PT_MEDIUM_BULLET, 	1, 0.1, 1.7, 25, 0.85 },
	{ "Pump Shotgun", "models/sg.iqm", 15, 0.4, PT_PELLET, 			6, 0.9, 1.9, 6, 0.85 },
	{ "Auto Shotgun", "models/autosg.iqm", 15, 0.5, PT_PELLET, 		4, 0.25, 2.2, 6, 0.8 },
	{ "DMR", "models/rifle.iqm", 45, 0.9, PT_BIG_BULLET, 			1, 0.7, 1.8, 5, 0.7 },
	{ "LMG", "models/lmg.iqm", 18, 0.75, PT_BIG_BULLET, 			1, 0.1, 3.5, 70, 0.6 }
};

void() precache_guns =
{
	for (int i = 0; i < weapon_list.length; i++)
	{
		precache_model(weapon_list[i].model);
	}
};


float random_table[] = { -0.65, 0.8, -1, 0.35, -0.45, -0.1, 0.65, -0.5, 0.2, 1, -0.1, 0.1, -0.9, -0.35, 0.4, -0.15, 0.6, 0.25, -0.55, 0.7, -0.85, 0.4, -0.2, 0.6, -0.4, 0.2 };
int randi;

float() spread_random =
{
	randi++;
	if (randi >= random_table.length) randi = 0;
	return random_table[randi];
}

void() precache_everything =
{
	precache_sound("demon/dland2.wav");
	precache_model("models/testplayer.iqm");
	precache_model("models/player.iqm");
	precache_model("models/light.iqm");
	precache_model("models/testblock.iqm");
	precache_model("models/crawler.iqm");
	precache_model("models/bomb.iqm");
	precache_model("models/bullet.iqm");
	precache_model("models/crate.iqm");
	precache_model("models/sg_ammo.iqm");
	precache_model("models/bullets_ammo.iqm");
	precache_model("models/ladderdown.iqm");
	precache_model("models/ring.iqm");
	precache_model("models/muzzleflash.iqm");
	
	precache_sound("sounds/t75.wav");
	
	particleeffectnum("weapons.explosion");
	
	precache_guns();
};

float() crandom =
{
	return (random() * 2) - 1;
};

string(string str, float index) str_at =
{
	return substring(str, index, 1);
};

void() sub_remove =
{
	remove(self);
};

void() sub_noop = {};

const float ENT_TILEBLOCK = 1;
const float ENT_PLAYER = 2;


const vector MAP_ORIGIN = '96 96 0';

const vector BLOCK_MINS = '-32 -32 0';
const vector BLOCK_MAXS = '32 32 64';
const vector BLOCK_SIZE = '64 64 64';


// MOVE ME TO sh_physics

vector(vector to, vector vec) vector_project =
{
	float to_len = vlen(to);
	return ((to * vec)/(to_len * to_len)) * to;
};

vector accel_g;
void(entity pl) player_move =
{
	/*
	vector ang = -vectoangles(aim_normalized);
	if (ang_y < 0) ang_y += 360;
	return ang;
	*/
	
	pl.angles = -vectoangles([input_angles_x, input_angles_y]); // vectoangles([input_angles_x, input_angles_y * -1, 0], '0 0 1');
	if (pl.angles_y < 0) pl.angles_y += 360;
	pl.angles_z = 0;
	vector mins = '-16 -16 0';
	vector maxs = '16 16 64';
	float maxaccel = 1200;
	float maxspeed = vlen(input_movevalues);
	vector move = [input_movevalues_y, input_movevalues_x] * 0.005;
	float timelen = input_timelength;
	vector oldpos = pl.origin;
	vector vel = pl.velocity;
	float speed = vlen(vel);
	float stopspeed = 30 * timelen;
	// Friction
	/*
	float use_full_friction = vlen(wantvel) > maxspeed;
	float friction = (use_full_friction*500 + 550)*timelen;
	vector frictionvec = vlen(wantvel) < friction ? wantvel : normalize(wantvel) * friction;
	wantvel -= frictionvec;
	if (vlen(wantvel) < 5) {
		wantvel = '0 0 0';
	}
	*/
	float drop = speed * input_timelength * 5;
	float new_speed = speed < stopspeed ? 0 : max(speed - drop, 0);
	vel = speed ? vel * (new_speed / speed) : '0 0 0';

	float oldspeed = vlen(vel);
	vector accel = move * maxaccel;
	vel += accel*timelen;
	speed = vlen(vel);
	if (oldspeed < maxspeed && speed > maxspeed)
	{
		vel = vel * (maxspeed / speed);
	}
	
	vector targetpos = oldpos + vel*timelen;
	tracebox(oldpos, mins, maxs, targetpos, 0, pl);
	vector first_hit_pos = trace_endpos;
	
	if (trace_fraction < 1)
	{
		vector wallnormal = trace_plane_normal;
		vector shouldve_moved = targetpos - oldpos;
		
		vector projected_into_wall = vector_project(wallnormal, shouldve_moved);
		vector along_wall = shouldve_moved - projected_into_wall;
		
		// HACKY CORNER SHIFT BEGIN
		vector corner_shift = '0 0 0';
		if ((wallnormal * normalize(accel)) < -0.75) // dont try to shift if we're not running nearly straight towards the wall
		{
			vector fwd = normalize(move);
			vector up = '0 0 1';
			vector right = crossproduct(fwd, up); // hope it's right and not left
			tracebox(oldpos + right*16, mins, maxs, oldpos + right*16 + vel*timelen, 0, pl);
			float dodgeamount = 0.1*vlen(accel)*timelen;
			
			if (trace_fraction >= 1)
			{
				tracebox(first_hit_pos, mins, maxs, first_hit_pos + right*dodgeamount, 0, pl);
				corner_shift = trace_endpos - first_hit_pos;
			}
			else
			{
				tracebox(oldpos - right*16, mins, maxs, oldpos - right*16 + vel*timelen, 0, pl);
				if (trace_fraction >= 1)
				{
					tracebox(first_hit_pos, mins, maxs, first_hit_pos - right*dodgeamount, 0, pl);
					corner_shift = trace_endpos - first_hit_pos;
				}
			}
		}
		// HACKY CORNER SHIFT END
		
		vel -= vector_project(wallnormal, vel);
		if (vlen(vel) < stopspeed)
		{
			vel = '0 0 0';
		}
		targetpos = oldpos + along_wall + corner_shift;
		tracebox(first_hit_pos, mins, maxs, targetpos, 0, pl);	
	}
	
	accel_g = accel;
	pl.velocity = vel;
	setorigin(pl, trace_endpos);
	
	// Handle touches for triggers
	tracebox(oldpos, mins, maxs, trace_endpos, MOVE_TRIGGERS + MOVE_ENTCHAIN, pl);
	entity head = trace_ent;
	entity old_self, old_other;
	while (head)
	{
		if (head.touch) 
		{
			old_self = self;
			old_other = other;
			self = head;
			other = pl;
			head.touch();
			self = old_self;
			other = old_other;
		}
		head = head.chain;
	}
	
};

void(entity e, void() fn) self_call =
{
	entity oself = self;
	self = e;
	fn();
	self = oself;
};

/*
.float attack_finished;
.void() primary_fire;
.void() primary_fire_cb;
.void() secondary_fire;
.void() secondary_fire_cb;
.void() reload;
.void() reload_cb;

void() t75_explode =
{
	pointparticles(particleeffectnum("weapons.explosion"), self.origin + '0 0 32', '0 0 1');
	sound(self, CHAN_AUTO, "sounds/t75.wav", 1, 0.5);
	remove(self);
};

void(entity proj) t75_projectile =
{
	setmodel(proj, "models/bomb.iqm");
	proj.movetype = MOVETYPE_TOSS;
	proj.nextthink = time + 3;
	proj.think = t75_explode;
};

void() test_pf =
{
	if (time < self.attack_finished) return;
	entity mis = spawn();
	t75_projectile(mis);
	mis.owner = self;
	setorigin(mis, self.origin + '0 0 50');
	makevectors(self.angles);
	mis.velocity = v_forward * 300;
	self.attack_finished = time + 0.5;
};
void() test_sf =
{
	if (time < self.attack_finished) return;
	print("secondary fire\n");
	self.attack_finished = time + 2;
};

void() init_weapon =
{
	self.primary_fire = sub_noop;
	self.primary_fire_cb = sub_noop;
	self.secondary_fire = sub_noop;
	self.secondary_fire_cb = sub_noop;
	self.reload = sub_noop;
	self.reload_cb = sub_noop;
};

*/

/*
void() test_weapon =
{
	init_weapon();
	self.classname = "test_weapon";
	self.primary_fire = test_pf;
	self.secondary_fire = test_sf;
	setmodel(self, "models/testplayer.iqm");
	self.scale = 0.25;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	// setmodel
	// setsize
	// solid
	// movetype
};
*/