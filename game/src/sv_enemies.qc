// Empty

const float AGGRO_DIST = 300;
const float AGGRO_DOT = 0.5;

.float attack_range;

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
		
		printf("aggro against player %f\n", normalize(to_player) * v_forward);
		return head;
	}
	return world;
};

void() enemy_think;

void() enemy_attack =
{
	changeyaw();
	makevectors(self.angles);
	if (self.attack_range < 100)
	{
		if (vlen(self.enemy.origin - self.origin) < 90)
		{
			if (normalize(self.enemy.origin - self.origin) * v_forward > 0.7)
				damage(self.enemy, self, (self.enemy.origin - self.origin), 10 + random() * 10);
		}
	}
	self.nextthink = time + 0.5;
	self.think = enemy_think;
};

void() enemy_think =
{
	self.nextthink = 0;
	if (!self.enemy)
	{
		self.enemy = find_enemy();
	}
	else
	{
		self.frame = 0;
		vector to_player = self.enemy.origin - self.origin;
		self.ideal_yaw = vectoangles(to_player).y;
		changeyaw();
		
		if (vlen(to_player) < self.attack_range && time > self.attack_finished && can_see(self.enemy))
		{
			print("Try to attack\n");
			self.frame = 1;
			self.nextthink = time + 0.35;
			self.think = enemy_attack;
			self.attack_finished = time + 1;
		}
		else
		{
			self.goalentity = self.enemy;
			movetogoal(15);
		}
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
	
	self.frame = 1;
	self.nextthink = time + 0.5 * (amount / 25);
	self.think = enemy_think;
	self.flags (-) FL_ONGROUND;
	self.velocity = (dir * 5 + '0 0 5') * amount;
};

void(entity attacker, vector dir, float amount) enemy_die =
{
	self.solid = SOLID_NOT;
	remove(self);
};

void() enemy_crawler =
{
	self.clearable = TRUE;
	setmodel(self, "models/crawler.iqm");
	setsize(self, '-16 -16 0', '16 16 56');
	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_STEP;
	self.health = 90;
	self.takes_damage = TRUE;
	// self.think = crawler_think;
	// self.nextthink = time + 0.05;
	// self.die = crawler_die;
	// self.hurt = crawler_hurt;
	self.gravity = 1;
	self.yaw_speed = 20;
	self.think = enemy_think;
	self.angles_y = random() * 360;
	self.nextthink = time + 0.1 + random();
	self.hurt = enemy_hurt;
	self.die = enemy_die;
	self.attack_range = 80;
};