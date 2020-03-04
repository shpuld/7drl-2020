// Empty

const float AGGRO_DIST = 300;
const float AGGRO_DOT = 0.5;

const float E_FRAME_IDLE = 0;
const float E_FRAME_MOVE = 1;
const float E_FRAME_ATTACK = 2;
const float E_FRAME_HURT = 3;
const float E_FRAME_DIE = 4;

.float attack_range;
.float move_speed;

float(entity target) can_see =
{
	traceline(self.origin + '0 0 30', target.origin + '0 0 30', 0, self);
	if (trace_ent == target) return TRUE;
	return FALSE;
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

void() enemy_attack =
{
	vector to_player = self.enemy.origin - self.origin;
	self.ideal_yaw = vectoangles(to_player).y;
	
	makevectors(self.angles);
	
	BeginEvent(EV_ENEMY_PROJECTILE);
	switch (self.classname)
	{
		case "enemy_berserker":
			changeyaw();
			MulticastByte(EPT_MELEE);
			self.attack_finished += 0.2;
			break;
		case "enemy_gunner":
			MulticastByte(EPT_BULLET);
			self.attack_finished += 1.0;
			break;
		default:
			MulticastByte(EPT_BULLET);
			break;
	}
	MulticastEnt(self);
	if (v_forward * normalize(to_player) > 0.94)
		MulticastEnt(self.enemy);
	else
		MulticastEnt(world);
	MulticastVector(self.origin + v_forward * 16);
	MulticastVector(v_forward);
	multicast(self.origin, MULTICAST_PVS);
	self.nextthink = time + 0.5;
	self.think = enemy_think;
};

void() attack_turn =
{
	if (self.attack_finished - time < 0.55)
		self.think = enemy_attack;
	else
		self.think = attack_turn;

	self.nextthink = time + 0.1;
	vector to_player = self.enemy.origin - self.origin;
	self.ideal_yaw = vectoangles(to_player).y;
	changeyaw();
}

.vector last_seen;
.float last_seen_time;
void(float dist) move_to_enemy =
{
	vector tgt = self.last_seen == '0 0 0' ? self.enemy.origin : self.last_seen;
	vector to_enemy = normalize(tgt - self.origin);
	vector result1, result2, result3;
	makevectors(self.angles);
	if (v_forward * to_enemy < 0.8) return;

	result2 = result3 = self.origin;
	tracebox(self.origin, self.mins, self.maxs, self.origin + to_enemy * dist, 0, self);
	result1 = trace_endpos;
	float initial_d = random() > 0.5 ? -1 : 1;
	float compareagainststart = trace_fraction <= 0.05;
	if (trace_fraction < 1)
	{
		tracebox(self.origin, self.mins, self.maxs, self.origin + v_right * dist*0.8 * initial_d, 0, self);
		result2 = trace_endpos;
		if (trace_fraction < 1)
		{
			tracebox(self.origin, self.mins, self.maxs, self.origin + v_right * dist*0.8 * -initial_d, 0, self);
			result3 = trace_endpos;
		}
	}
	float res1len, res2len, res3len;
	if (compareagainststart)
	{
		res1len = 5000 - vlen(result1 - self.origin);
		res2len = 5000 - vlen(result2 - self.origin);
		res3len = 5000 - vlen(result3 - self.origin);
	}
	else
	{
		res1len = vlen(result1 - tgt);
		res2len = vlen(result2 - tgt);
		res3len = vlen(result3 - tgt);
	}
	if (res1len < res2len && res1len < res2len)
	{
		setorigin(self, result1);
		return;
	}
	if (res2len < res3len)
	{
		setorigin(self, result2);
		return;
	}
	setorigin(self, result3);
	return;
}

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


void(entity attacker, vector dir, float amount) enemy_hurt =
{
	if (attacker.classname == "player") self.enemy = attacker;
	if (amount < 15 && random() < 0.8) return;
	if (amount < 25 && random() < 0.4) return;

	self.frame = E_FRAME_HURT;
	self.nextthink = time + min(0.6, 0.5 * (amount / 15));
	self.think = enemy_think;
	self.flags (-) FL_ONGROUND;
	self.velocity = dir * 5 * amount + '0 0 10' * min(10, amount * 0.5);
};

void(entity attacker, vector dir, float amount) enemy_die =
{
	self.velocity = dir * 20 * min(25, amount) + '0 0 10' * min(15, amount);
	tracebox(self.origin, '-24 -24 0', '24 24 16', self.origin, 0, self);
	if (!trace_startsolid) setsize(self, '-24 -24 0', '24 24 15'); 
	self.flags (-) FL_ONGROUND;
	self.angles_y = vectoangles(-dir).y;
	self.frame = E_FRAME_DIE;
	self.solid = SOLID_NOT;
	self.nextthink = 0;
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
};

void() enemy_berserker =
{
	self.classname = "enemy_berserker";
	enemy_common();
	setmodel(self, "models/zombieberserker.iqm");
	self.health = 90;
	self.attack_range = 50;
	self.move_speed = 25;
};

void() enemy_crawler =
{
	if (random() < 0.5) enemy_gunner();
	else enemy_berserker();
};