// Empty

const float AGGRO_DIST = 350;
const float AGGRO_DOT = 0.4;

const float E_FRAME_IDLE = 0;
const float E_FRAME_MOVE = 1;
const float E_FRAME_ATTACK = 2;
const float E_FRAME_HURT = 3;
const float E_FRAME_DIE = 4;

.float attack_range;
.float move_speed;

.float is_gladiatar;

float(entity target) can_see =
{
	traceline(self.origin + '0 0 30', target.origin + '0 0 30', MOVE_ENTCHAIN, self);
	for (entity e = trace_ent; e; e = e.chain)
	{
		if (e.movetype == MOVETYPE_NONE && e != target) return FALSE;
	}
	return TRUE;
};

float(float a, float b) yaw_diff =
{
	return fabs((a - b + 180) % 360 - 180);
}

void(float dist) move_to_enemy =
{
	if (yaw_diff(self.angles_y, self.ideal_yaw) > 45)
	{
		changeyaw();
		return;
	}
	float success = walkmove(self.ideal_yaw, dist);
	if (!success) success = walkmove(self.ideal_yaw + 25, dist);
	if (!success) success = walkmove(self.ideal_yaw - 25, dist);
	if (!success) success = walkmove(self.ideal_yaw + 65, dist);
	if (!success) success = walkmove(self.ideal_yaw - 65, dist);
	if (!success) success = walkmove(self.ideal_yaw + 90, dist);
	if (!success) success = walkmove(self.ideal_yaw - 90, dist);
};

entity() find_enemy =
{
	for (entity head = player_chain_head; head; head = head.player_chain_next)
	{
		vector to_player = head.origin - self.origin;
		if (vlen(to_player) > AGGRO_DIST) continue;
		makevectors(self.angles);
		if (normalize(to_player) * v_forward < AGGRO_DOT) continue;
		if (!can_see(head)) continue;
		
		return head;
	}
	return world;
};

void() enemy_think;

.float shots_left;

void() enemy_attack =
{
	vector to_player = self.enemy.origin - self.origin;
	self.ideal_yaw = vectoangles(to_player).y;
	
	makevectors(self.angles);
	
	self.nextthink = time + 0.5;
	self.think = enemy_think;
	
	BeginEvent(EV_ENEMY_PROJECTILE);
	switch (self.classname)
	{
		case "enemy_berserker":
			changeyaw();
			MulticastByte(EPT_MELEE);
			self.attack_finished += 0.3;
			break;
		case "enemy_hellberserker":
			changeyaw();
			MulticastByte(EPT_MELEE_STRONG);
			self.attack_finished += 0.3;
			break;
		case "enemy_greenberserker":
			changeyaw();
			MulticastByte(EPT_MELEE_STRONG);
			self.attack_finished += 0.4;
			break;
		case "enemy-icegunner":
			MulticastByte(EPT_BULLET);
			self.attack_finished += 1.1;
			break;
		case "enemy_gunner":
			MulticastByte(EPT_BULLET);
			self.attack_finished += 2.0;
			break;
		case "enemy_hellgunner":
			MulticastByte(EPT_CANNON);
			self.attack_finished += 1.3;
			break;
		case "enemy_greengunner":
			MulticastByte(EPT_GREEN);
			self.attack_finished += 2.0;
			break;
		default:
			MulticastByte(EPT_BULLET);
			break;
	}
	MulticastEnt(self);
	if (v_forward * normalize(to_player) > 0.95)
		MulticastEnt(self.enemy);
	else
		MulticastEnt(world);
	MulticastVector(self.origin + v_forward * 16);
	MulticastVector(v_forward);
	multicast(self.origin, MULTICAST_PVS);
	
	if (self.shots_left)
	{
		self.nextthink = time + 0.25;
		self.think = enemy_attack;
		self.shots_left -= 1;
	}
};

.float attack_delay;
void() attack_turn =
{
	if (self.attack_finished - time < (1 - self.attack_delay))
		self.think = enemy_attack;
	else
		self.think = attack_turn;

	self.nextthink = time + 0.1;
	vector to_player = self.enemy.origin - self.origin;
	self.ideal_yaw = vectoangles(to_player).y;
	changeyaw();
	if (self.attack_range < 100) move_to_enemy(self.move_speed * 0.65);
	
	self.shots_left = self.ammo_shells;
}

.vector last_seen;
.float last_seen_time;


.float walking;
void() enemy_think =
{
	self.nextthink = 0;
	// IDLE
	if (!self.enemy)
	{
		changeyaw();
		if (self.walking)
		{
			self.frame = E_FRAME_MOVE;
			walkmove(self.angles_y, self.move_speed / 2);
			if (random() < 0.2) self.ideal_yaw += crandom() * 20;
			if (random() < 0.3) self.walking = FALSE; 
		}
		else
		{
			self.frame = E_FRAME_IDLE;
			if (random() < 0.2) self.ideal_yaw = random() * 360;
			if (random() < 0.1) self.walking = TRUE;
		}
		
		self.enemy = find_enemy();
		if (self.enemy)
		{
			if (self.is_gladiatar)
				sound_variation(self, CHAN_VOICE, "sounds/gladspot%.0f.wav", 3, 1, 0.5);
			else
				sound_variation(self, CHAN_VOICE, "sounds/mutiespot%.0f.wav", 7, 1, 0.5);		
		}
		else if (random() < 0.05)
		{
			sound_variation(self, CHAN_VOICE, "sounds/mutieidle%.0f.wav", 3, 1, 1.0);
		}
	}
	// CHASE
	else
	{
		float cansee = can_see(self.enemy);
		if (cansee) 
		{
			self.last_seen = '0 0 0';
			self.last_seen_time = time;
		}
		
		vector to_player = cansee ? self.enemy.origin - self.origin : self.last_seen - self.origin;
		self.ideal_yaw = vectoangles(to_player).y;
		changeyaw();
		
		// ATTACK
		if (vlen(to_player) < self.attack_range && time > self.attack_finished && cansee)
		{
			self.frame = E_FRAME_ATTACK;
			self.nextthink = time + 0.1;
			self.think = attack_turn;
			self.attack_finished = time + 1;
		}
		else
		{
			self.frame = E_FRAME_MOVE;
			self.goalentity = self.enemy;
			move_to_enemy(self.move_speed);
		}
		
		if (cansee) self.last_seen = self.enemy.origin;
		else if (time - self.last_seen_time > 10) self.enemy = world;
	}
	if (!self.nextthink)
	{
		self.think = enemy_think;
		self.nextthink = time + 0.1;
	}
};


.float pain_threshold;

void(entity attacker, vector dir, float amount) enemy_hurt =
{
 
	if (attacker.classname == "player") self.enemy = attacker;
	if (amount < self.pain_threshold && random() < 0.8) return;
	if (amount < self.pain_threshold*2 && random() < 0.5) return;
	
	if (self.is_gladiatar)
		sound_variation(self, CHAN_VOICE, "sounds/gladhurt%.0f.wav", 2, 1, 0.5);
	else
		sound_variation(self, CHAN_VOICE, "sounds/mutiehurt%.0f.wav", 2, 1, 0.5);

	self.frame = E_FRAME_HURT;
	self.nextthink = time + min(0.6, 0.5 * (amount / 15));
	self.think = enemy_think;
	self.flags (-) FL_ONGROUND;
	self.velocity = dir * 5 * amount + '0 0 10' * min(10, amount * 0.5);
};

void(entity attacker, vector dir, float amount) enemy_die =
{
	self.velocity = dir * 25 * min(20, amount) + '0 0 12' * min(10, amount);
	tracebox(self.origin, '-24 -24 0', '24 24 16', self.origin, 0, self);
	if (!trace_startsolid) setsize(self, '-24 -24 0', '24 24 15'); 
	self.flags (-) FL_ONGROUND;
	self.angles_y = vectoangles(-dir).y;
	self.frame = E_FRAME_DIE;
	self.solid = SOLID_NOT;
	self.nextthink = 0;
	
	sound_variation(self, CHAN_VOICE, "sounds/gladdie%.0f.wav", 2, 1, 0.5);
};

void() enemy_common =
{
	self.clearable = TRUE;
	setsize(self, '-16 -16 0', '16 16 56');
	self.solid = SOLID_BBOX; 
	self.movetype = MOVETYPE_STEP;
	self.takes_damage = TRUE;
	self.gravity = 1;
	self.yaw_speed = 16;
	self.think = enemy_think;
	self.angles_y = random() * 360;
	self.nextthink = time + 0.1 + random();
	self.hurt = enemy_hurt;
	self.die = enemy_die;
	self.pain_threshold = 15;
	
	if (vlen(self.origin - test_spawnpoint) < 360)
	{
		self.nextthink = time;
		self.think = sub_remove;
	}
};

void() enemy_gunner =
{
	self.classname = "enemy_gunner";
	enemy_common();
	setmodel(self, "models/zombiegunner.iqm");
	self.health = 60;
	self.attack_range = 250;
	self.move_speed = 15;
	self.attack_delay = 0.5;
	self.pain_threshold = 13;
	self.ammo_shells = 2;
};

void() ice_gunner =
{
	self.classname = "enemy_gunner";
	enemy_common();
	setmodel(self, "models/icegunner.iqm");
	self.health = 50;
	self.attack_range = 250;
	self.move_speed = 12;
	self.attack_delay = 0.7;
	self.pain_threshold = 8;
};

void() hell_gunner =
{
	self.classname = "enemy_hellgunner";
	enemy_common();
	setmodel(self, "models/hellgunner.iqm");
	self.health = 180;
	self.attack_range = 280;
	self.move_speed = 15;
	self.attack_delay = 0.5;
	self.pain_threshold = 25;
	self.ammo_shells = 1;
	self.yaw_speed = 20;
};

void() green_gunner =
{
	self.classname = "enemy_greengunner";
	enemy_common();
	setmodel(self, "models/greengunner.iqm");
	self.health = 120;
	self.attack_range = 280;
	self.move_speed = 15;
	self.attack_delay = 0.5;
	self.pain_threshold = 20;
};


void() enemy_berserker =
{
	self.classname = "enemy_berserker";
	enemy_common();
	setmodel(self, "models/zombieberserker.iqm");
	self.health = 95;
	self.attack_range = 56;
	self.move_speed = 23;
	self.attack_delay = 0.3;
	self.pain_threshold = 22;
};

void() ice_berserker =
{
	self.classname = "enemy_berserker";
	enemy_common();
	setmodel(self, "models/iceberserker.iqm");
	self.health = 70;
	self.attack_range = 55;
	self.move_speed = 19;
	self.attack_delay = 0.4;
	self.pain_threshold = 12;
	self.is_gladiatar = TRUE;
};

void() hell_berserker =
{
	self.classname = "enemy_hellberserker";
	enemy_common();
	setmodel(self, "models/hellberserker.iqm");
	self.health = 220;
	self.attack_range = 55;
	self.move_speed = 30;
	self.attack_delay = 0.3;
	self.pain_threshold = 30;
	self.yaw_speed = 20;
};

void() green_berserker =
{
	self.classname = "enemy_greenberserker";
	enemy_common();
	setmodel(self, "models/greenberserker.iqm");
	self.health = 170;
	self.attack_range = 55;
	self.move_speed = 25;
	self.attack_delay = 0.3;
	self.pain_threshold = 25;
};


void() enemy_crawler =
{
	if (random() > 0.4 + current_level * 0.06)
	{
		remove(self);
		return;
	}
	
	float r = random();
	if (current_level >= LEVEL_HECK)
	{
		if (r < 0.5) hell_berserker();
		else hell_gunner();
	}
	else if (current_level >= LEVEL_RUST)
	{
		if (r < 0.5) green_berserker();
		else green_gunner();
	}
	else if (current_level >= LEVEL_INSIDE)
	{
		if (r < 0.5) enemy_berserker();
		else enemy_gunner();
	}
	else // LEVEL_SNOW
	{
		if (r < 0.5) ice_berserker();
		else ice_gunner();
	}
};