//shared definitions

const float STAT_ITEM_ID = 50;
const float STAT_ITEM_EFFECT = 51;
const float STAT_ITEM_TYPE = 52;
const float STAT_LEVEL = 53;

const float EV_SPAWN_PROJECTILE = 10;
const float EV_PROJECTILE_HIT = 11;
const float EV_SET_INVENTORY = 12;
const float EV_GIVE_AMMO = 13;
const float EV_BOX_BREAK = 14;
const float EV_CLEAR_MAP = 15;
const float EV_ENEMY_PROJECTILE = 16;
const float EV_EXIT_LEVEL = 17;
const float EV_ENTER_LEVEL = 18;
const float EV_VICTORY = 19;

const int INV_SIZE = 6;
const int INV_SLOT_WEAPON1 = 0;
const int INV_SLOT_WEAPON2 = 1;
const int INV_SLOT_ARMOR = 2;
const int INV_SLOT_MOD1 = 3;
const int INV_SLOT_MOD2 = 4;
const int INV_SLOT_MOD3 = 5;

.float clearable;
.float type;

float current_level;

const float LEVEL_SNOW = 0;
const float LEVEL_INSIDE = 1;
const float LEVEL_RUST = 4;
const float LEVEL_HECK = 7;

// Projectile Types
enum {
	PT_SMALL_BULLET, PT_MEDIUM_BULLET, PT_BIG_BULLET, PT_PELLET, PT_PLASMA, PT_LASER
};

enum {
	EPT_MELEE, EPT_BULLET, EPT_CANNON, EPT_GREEN, EPT_MELEE_STRONG
};

// Item Types
enum {
	IT_NONE, IT_WEAPON, IT_ARMOR, IT_POWERMOD, IT_AMMO, IT_MEDKIT
};

// Items
.float item_id;
enum {
	I_EMPTY,
	I_ARMOR,
	I_POWERMOD,
};

string item_names[] = {
	"",
	"Flak Vest",
	"Power Module"
};

.float item_effect;

// Item Effects
enum {
	IEF_NONE, IEF_DAMAGE, IEF_DEFENSE, IEF_ACCURACY, IEF_FIRERATE, IEF_RELOADSPEED, IEF_MOVESPEED, IEF_MAGSIZE, IEF_VAMPIRIC, IEF_REGEN, IEF_LIGHT, IEF_MELEE
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
		case IEF_REGEN: return "Regeneration";
		case IEF_LIGHT: return "Light Radius";
		case IEF_MELEE: return "Melee Damage";
		default: return "";
	}
}


const float MOD_BAD_START = 1;
const float MOD_AVG_START = 12;
const float MOD_GOOD_START = 23;

item_effect powermod_effects[] = 
{
	{ "", IEF_NONE, 0, IEF_NONE, 0 },
	// ok 1
	{ "", IEF_ACCURACY, 2, IEF_NONE, 0 },
	{ "", IEF_FIRERATE, 2, IEF_NONE, 0 },
	{ "", IEF_DAMAGE, 1, IEF_NONE, 0 },
	{ "", IEF_DEFENSE, 1, IEF_NONE, 0 },
	{ "", IEF_MOVESPEED, 1, IEF_NONE, 0 },
	{ "", IEF_MAGSIZE, 2, IEF_NONE, 0 },
	{ "", IEF_RELOADSPEED, 1, IEF_NONE, 0 },
	{ "", IEF_MAGSIZE, 1, IEF_NONE, 0 },
	{ "", IEF_DAMAGE, 1, IEF_NONE, 0 },
	{ "", IEF_LIGHT, 1, IEF_NONE, 0 },
	{ "", IEF_MELEE, 1, IEF_NONE, 0 },
	// good 12
	{ "", IEF_ACCURACY, 2, IEF_DAMAGE, 1 },
	{ "", IEF_FIRERATE, 2, IEF_RELOADSPEED, 1 },
	{ "", IEF_FIRERATE, 2, IEF_DAMAGE, 1 },
	{ "", IEF_DEFENSE, 1, IEF_MOVESPEED, 1 },
	{ "", IEF_MOVESPEED, 1, IEF_FIRERATE, 1 },
	{ "", IEF_MAGSIZE, 2, IEF_RELOADSPEED, 1 },
	{ "", IEF_RELOADSPEED, 1, IEF_MOVESPEED, 1 },
	{ "", IEF_DAMAGE, 2, IEF_NONE, 0 },
	{ "", IEF_RELOADSPEED, 2, IEF_NONE, 0 },
	{ "", IEF_LIGHT, 2, IEF_ACCURACY, 1 },
	{ "", IEF_MELEE, 2, IEF_MOVESPEED, 1 },
	// best 23
	{ "", IEF_ACCURACY, 3, IEF_DAMAGE, 2 },
	{ "", IEF_FIRERATE, 3, IEF_RELOADSPEED, 2 },
	{ "", IEF_FIRERATE, 3, IEF_DAMAGE, 2 },
	{ "", IEF_DEFENSE, 2, IEF_MOVESPEED, 2 },
	{ "", IEF_MOVESPEED, 2, IEF_FIRERATE, 2 },
	{ "", IEF_MAGSIZE, 3, IEF_RELOADSPEED, 2 },
	{ "", IEF_RELOADSPEED, 2, IEF_MOVESPEED, 2 },
	{ "", IEF_VAMPIRIC, 1, IEF_NONE, 0 },
	{ "", IEF_REGEN, 1, IEF_NONE, 0 },
	{ "", IEF_LIGHT, 3, IEF_ACCURACY, 2 },
	{ "", IEF_MELEE, 3, IEF_MOVESPEED, 2 }
};

item_effect armor_effects[] =
{
	{ "", IEF_NONE, 0, IEF_NONE, 0 },
	// ok 1
	{ "Flak Vest", IEF_DEFENSE, 2, IEF_NONE, 0 },
	{ "Plate Armor", IEF_DEFENSE, 3, IEF_NONE, 0 },
	{ "Power Armor", IEF_DEFENSE, 5, IEF_NONE, 0 },
	{ "Turbo Armor", IEF_DEFENSE, 6, IEF_NONE, 0 },
};

string(float effect, float which) powermod_stats_string =
{
	float ef;
	if (which == 2) ef = powermod_effects[effect].effect2;
	else ef = powermod_effects[effect].effect1;
	float level;
	if (which == 2) level = powermod_effects[effect].level2;
	else level = powermod_effects[effect].level1;
	
	if (ef == IEF_NONE) return "";

	
	string sign = level > 0 ? "+" : "";
	return sprintf("%s%.0f %s", sign, level, effect_stat_name(ef));
}

const float WEAPON_BAD_START = 1;
const float WEAPON_AVG_START = 13;
const float WEAPON_GOOD_START = 22;
const float WEAPON_SUPER_START = 40;

item_effect weapon_effects[] = 
{
	{ "", IEF_NONE, 0, IEF_NONE, 0 },
	// Bad, 1
	{ "Junk", IEF_ACCURACY, -4, IEF_DAMAGE, -3 },
	{ "Junk", IEF_ACCURACY, -3, IEF_DAMAGE, -4 },
	{ "Junk", IEF_FIRERATE, -4, IEF_DAMAGE, -1 },
	{ "Bad", IEF_DAMAGE, -2, IEF_FIRERATE, -2 },
	{ "Bad", IEF_DAMAGE, -1, IEF_ACCURACY, -4 },
	{ "Bad", IEF_DAMAGE, -1, IEF_RELOADSPEED, -2 },
	{ "Used", IEF_FIRERATE, -1, IEF_ACCURACY, -1 },
	{ "Used", IEF_FIRERATE, -1, IEF_RELOADSPEED, -1 },
	{ "Used", IEF_FIRERATE, -2, IEF_NONE, 0 },
	{ "Clunky", IEF_RELOADSPEED, -3, IEF_ACCURACY, -1 },
	{ "Clunky", IEF_RELOADSPEED, -2, IEF_ACCURACY, -2 },
	{ "Clunky", IEF_RELOADSPEED, -1, IEF_NONE, 0 },
	// Neutral 13
	{ "Average", IEF_FIRERATE, 1, IEF_RELOADSPEED, -1 },
	{ "Average", IEF_FIRERATE, 1, IEF_DAMAGE, -1 },
	{ "Average", IEF_FIRERATE, 1, IEF_ACCURACY, -1 },
	{ "Average", IEF_MAGSIZE, 1, IEF_RELOADSPEED, -1 },
	{ "Average", IEF_MAGSIZE, 1, IEF_DAMAGE, -1 },
	{ "Average", IEF_MAGSIZE, 1, IEF_ACCURACY, -1 },
	{ "Average", IEF_DAMAGE, 1, IEF_RELOADSPEED, -1 },
	{ "Average", IEF_DAMAGE, 1, IEF_MOVESPEED, -1 },
	{ "Average", IEF_DAMAGE, 1, IEF_ACCURACY, -1 },
	// Slightly good 22
	{ "Strong", IEF_DAMAGE, 1, IEF_NONE, 0 },
	{ "Strong", IEF_DAMAGE, 3, IEF_MOVESPEED, -2 },
	{ "Strong", IEF_DAMAGE, 2, IEF_MOVESPEED, -1 },
	{ "Precise", IEF_ACCURACY, 4, IEF_FIRERATE, -1 },
	{ "Precise", IEF_ACCURACY, 3, IEF_NONE, 0 },
	{ "Precise", IEF_ACCURACY, 2, IEF_DAMAGE, 1 },
	{ "Firehose", IEF_FIRERATE, 3, IEF_ACCURACY, -3 },
	{ "Firehose", IEF_FIRERATE, 2, IEF_ACCURACY, -1 },
	{ "Firehose", IEF_FIRERATE, 2, IEF_RELOADSPEED, -1 },
	{ "Fast", IEF_MOVESPEED, 4, IEF_DAMAGE, -1 }, 
	{ "Fast", IEF_MOVESPEED, 2, IEF_NONE, 0 },
	{ "Fast", IEF_MOVESPEED, 1, IEF_FIRERATE, 1 },
	{ "Extended", IEF_MAGSIZE, 3, IEF_RELOADSPEED, -1 },
	{ "Extended", IEF_MAGSIZE, 3, IEF_MOVESPEED, -1 }, 
	{ "Extended", IEF_MAGSIZE, 5, IEF_MOVESPEED, -2 },
	{ "Quick", IEF_RELOADSPEED, 2, IEF_FIRERATE, -1 },
	{ "Quick", IEF_RELOADSPEED, 1, IEF_NONE, 0 },
	{ "Quick", IEF_RELOADSPEED, 3, IEF_ACCURACY, -2 },
	// Really good 40
	{ "Superb", IEF_DAMAGE, 2, IEF_RELOADSPEED, 2 },
	{ "Great", IEF_DAMAGE, 2, IEF_FIRERATE, 2 },
	{ "Blazing", IEF_MOVESPEED, 2, IEF_RELOADSPEED, 2 },
	{ "Strong+", IEF_DAMAGE, 4, IEF_ACCURACY, 1 },
	{ "Firehose+", IEF_FIRERATE, 4, IEF_MAGSIZE, 1 },
	{ "Fast+", IEF_MOVESPEED, 4, IEF_RELOADSPEED, 1 },
	{ "Extended+", IEF_MAGSIZE, 4, IEF_FIRERATE, 1 },
	{ "Quick+", IEF_RELOADSPEED, 4, IEF_FIRERATE, 1 }
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
	case INV_SLOT_MOD1:
	case INV_SLOT_MOD2:
	case INV_SLOT_MOD3:
		return IT_POWERMOD;
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
	string sample;
	float soundspeed;
};

weapon weapon_list[] = {
	{ "", "", 0, 0, 0, 0, 0, 0, 0, 1.0, "", 100 },
	{ "SMG", "models/smg.iqm", 10, 0.6, PT_SMALL_BULLET, 			1, 0.090, 1.5, 40, 0.9, "sounds/ShotSMG.wav", 100 },
	{ "Micro SMG", "models/minismg.iqm", 8, 0.5, PT_SMALL_BULLET, 	1, 0.075, 1.1, 35, 1.0, "sounds/rifle.wav", 100 },
	{ "Combat Rifle", "models/ar.iqm", 13, 0.7, PT_MEDIUM_BULLET, 	1, 0.125, 1.8, 30, 0.8, "sounds/ShotSMGEQ.wav", 110 },
	{ "Bullpup", "models/bullpup.iqm", 16, 0.8, PT_MEDIUM_BULLET, 	1, 0.090, 2.0, 25, 0.85, "sounds/ShotSMGOther.wav", 100 },
	{ "Pump Shotgun", "models/sg.iqm", 18, 0.3, PT_PELLET, 			5, 0.900, 1.6, 6, 0.9, "sounds/shotgun.wav", 100 },
	{ "Auto Shotgun", "models/autosg.iqm", 14, 0.4, PT_PELLET, 		4, 0.200, 2.2, 8, 0.8, "sounds/shotgun.wav", 110 },
	{ "DMR", "models/rifle.iqm", 50, 0.85, PT_BIG_BULLET, 			1, 0.650, 1.8, 5, 0.75, "sounds/bigrifle.wav", 100 },
	{ "LMG", "models/lmg.iqm", 16, 0.6, PT_BIG_BULLET, 				1, 0.150, 3.3, 60, 0.7, "sounds/ShotLMGEQ.wav", 100 }
};

void() precache_guns =
{
	for (int i = 1; i < weapon_list.length; i++)
	{
		precache_sound(weapon_list[i].sample);
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

float PART_BLOOD;

void() precache_everything =
{
	PART_BLOOD = particleeffectnum("weapons.blood");

	precache_sound("sounds/demon/dland2.wav");
	precache_model("models/testplayer.iqm");
	precache_model("models/player.iqm");
	precache_model("models/light.iqm");
	precache_model("models/testblock.iqm");
	precache_model("models/crawler.iqm");
	precache_model("models/bomb.iqm");
	precache_model("models/bullet.iqm");
	precache_model("models/slime.iqm");
	precache_model("models/crate.iqm");
	precache_model("models/sg_ammo.iqm");
	precache_model("models/bullets_ammo.iqm");
	precache_model("models/ladderdown.iqm");
	precache_model("models/ring.iqm");
	precache_model("models/muzzleflash.iqm");
	precache_model("models/zombiegunner.iqm");
	precache_model("models/icegunner.iqm");
	precache_model("models/hellgunner.iqm");
	precache_model("models/greengunner.iqm");
	precache_model("models/zombieberserker.iqm");
	precache_model("models/iceberserker.iqm");
	precache_model("models/hellberserker.iqm");
	precache_model("models/greenberserker.iqm");
	precache_model("models/melee_proj.iqm");
	precache_model("models/power_mod.iqm");
	precache_model("models/glowstick.iqm");
	precache_model("models/medkit.iqm");
	precache_model("models/armor.iqm");
	precache_model("models/machine.iqm");
	
	precache_sound("sounds/t75.wav");
	precache_sound("sounds/reloadbegin.wav");
	precache_sound("sounds/reloadbegin2.wav");
	precache_sound("sounds/reloadend.wav");
	precache_sound("sounds/reloadendperfect.wav");
	precache_sound("sounds/reload1.wav");
	precache_sound("sounds/reload2.wav");
	precache_sound("sounds/reload3.wav");
	precache_sound("sounds/meleeswing.wav");
	precache_sound("sounds/meleehit.wav");
	precache_sound("sounds/meleehit2.wav");
	precache_sound("sounds/meleehit-old1.wav");
	precache_sound("sounds/meleehit-old2.wav");
	precache_sound("sounds/ShotSMGEQOther.wav");
	precache_sound("sounds/ShotSMGEQ.wav");
	precache_sound("sounds/spawn.wav");
	precache_sound("sounds/ladderdown.wav");
	
	precache_sound("sounds/oneshot1.wav");
	precache_sound("sounds/oneshot2.wav");
	precache_sound("sounds/oneshotwind.wav");
	precache_sound("sounds/wind1.wav");
	precache_sound("sounds/wind2.wav");
	precache_sound("sounds/wind3.wav");
	precache_sound("sounds/wind4.wav");
	
	precache_sound("sounds/mutieidle1.wav");
	precache_sound("sounds/mutieidle2.wav");
	precache_sound("sounds/mutieidle3.wav");
	precache_sound("sounds/mutiehurt1.wav");
	precache_sound("sounds/mutiehurt2.wav");
	precache_sound("sounds/mutiespot1.wav");
	precache_sound("sounds/mutiespot2.wav");
	precache_sound("sounds/mutiespot3.wav");
	precache_sound("sounds/mutiespot4.wav");
	precache_sound("sounds/mutiespot5.wav");
	precache_sound("sounds/mutiespot6.wav");
	precache_sound("sounds/mutiespot7.wav");
	
	precache_sound("sounds/gladdie1.wav");
	precache_sound("sounds/gladdie2.wav");
	precache_sound("sounds/gladhurt1.wav");
	precache_sound("sounds/gladhurt2.wav");
	precache_sound("sounds/gladspot1.wav");
	precache_sound("sounds/gladspot2.wav");
	precache_sound("sounds/gladspot3.wav");
	
	particleeffectnum("weapons.explosion");
	
	precache_guns();
};

void(entity e, float chan, string samp, float numvar, float vol, float atten) sound_variation =
{
	sound(e, chan, sprintf(samp, 1 + floor(random() * numvar)), vol, atten, 95 + random() * 10);
}

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

