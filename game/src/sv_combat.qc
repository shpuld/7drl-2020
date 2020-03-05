
void(entity target, entity attacker, vector dir, float amount) damage =
{
	entity oself;
	if (!target.takes_damage) return;
	if (target.health <= 0) return;
	
	target.health -= amount;
	if (target.health <= 0)
	{
		oself = self;
		self = target;
		if (self.die) self.die(attacker, dir, amount);
		self = oself;
	}
	else
	{
		oself = self;
		self = target;
		if (self.hurt) self.hurt(attacker, dir, amount);
		self = oself;
	}
};

void(float amount, float dealer) CSEv_took_damage_ff =
{
	if (amount < 0)
	{
		self.health = min(100, self.health + fabs(amount));
	}
	else
	{
		damage(self, edict_num(dealer), '0 0 0', amount);
	}
};

void(vector org, vector vel, vector parms) CSEv_sproj_vvv =
{
	BeginEvent(EV_SPAWN_PROJECTILE);
	MulticastVector(org);
	MulticastVector(vel);
	MulticastByte(parms_x);
	MulticastByte(parms_y);
	MulticastEnt(self);
	multicast(org, MULTICAST_ALL);
};

void(vector org, vector n, vector parms) CSEv_projhit_vvv =
{
	float id = parms_x;
	float entnum = parms_y;
	float dmg = parms_z;

	entity target = edict_num(entnum);
	if (target)
	{
		damage(target, self, -n, dmg);
	}

	BeginEvent(EV_PROJECTILE_HIT);
	MulticastVector(org);
	MulticastVector(n);
	MulticastByte(id);
	MulticastEnt(self);
	MulticastEnt(target);
	multicast(org, MULTICAST_ALL);
};

void(vector org, vector dir, vector parms) CSEv_meleehit_vvv =
{
	float entnum = parms_x;
	float dmg = parms_y;

	entity target = edict_num(entnum);
	if (target)
	{
		damage(target, self, normalize(target.origin - self.origin), dmg);
	}
};