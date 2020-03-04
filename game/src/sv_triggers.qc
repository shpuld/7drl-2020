
/*
void() trigger_example =
{
	setmodel(self, self.model);
	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	self.touch = something;
};
*/

void() info_null =
{
};

void() func_illusionary =
{
	setmodel(self, self.model);
	self.solid = SOLID_NOT;
};

void() death_touch =
{
	printf("someone %s died\n", etos(other));
};

void() trigger_death =
{
	setmodel(self, self.model);
	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	self.touch = death_touch;
};

void() goal_touch =
{
	printf("someone %s reached goal\n", etos(other));
};

void() trigger_goal =
{
	setmodel(self, self.model);
	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	self.touch = goal_touch;
};

float(entity player, entity item) put_item_in_inventory =
{
	for (int i = 0; i < INV_SIZE; i++)
	{
		if (type_for_slot(i) != item.type) continue;
		if (player.inventory[i]) continue;

		msg_entity = player;
		BeginEvent(EV_SET_INVENTORY);
		MulticastByte(i);
		MulticastByte(item.item_id);
		MulticastByte(item.item_effect);
		MulticastByte(item.ammo_shells);
		MulticastByte(item.ammo_nails);
		multicast('0 0 0', MULTICAST_ONE_R);
		
		player.inventory[i] = item;
		item.solid = SOLID_NOT;
		item.modelindex = 0;
		item.owner = player;
		item.touch = sub_noop;
		item.clearable = FALSE;
		usable_chain_remove(item);
		return TRUE;
	}
	return FALSE;
};

void() item_touch =
{
	if (other.classname != "player") return;
	
	if (put_item_in_inventory(other, self)) print("success\n");
};

void() reactivate_item =
{
	self.touch = item_touch;
	// self.flags = FL_FINDABLE_NONSOLID;
	usable_chain_add(self);
};

void(float slot) CSEv_dropitem_f =
{
	entity item = self.inventory[slot];
	self.inventory[slot] = world;
	setorigin(item, self.origin + '0 0 40');
	item.velocity = randomvec() * 20 + '0 0 50';
	setmodel(item, item.model);
	item.owner = world;
	item.clearable = TRUE;
	item.solid = SOLID_TRIGGER;
	item.nextthink = time + 1;
	item.think = reactivate_item;
};

void(float slot, float dropped_ammo, float dropped_mags) CSEv_dropitem_fff =
{
	entity item = self.inventory[slot];
	self.inventory[slot] = world;
	setorigin(item, self.origin + '0 0 40');
	item.velocity = randomvec() * 20 + '0 0 50';
	setmodel(item, item.model);
	item.owner = world;
	item.clearable = TRUE;
	item.solid = SOLID_TRIGGER;
	item.nextthink = time + 1;
	item.think = reactivate_item;
	item.ammo_shells = dropped_ammo;
	item.ammo_nails = dropped_mags;
};


void() item_fastreload = 
{
	self.type = IT_TRINKET;
	self.item_id = I_FASTRELOAD;
	self.clearable = TRUE;
};

void() item_sharpshooter = 
{
	self.type = IT_TRINKET;
	self.item_id = I_SHARPSHOOTER;
	self.clearable = TRUE;
};

void() ammo_touch =
{
	if (other.classname != "player") return;

	float ammotype = 0;
	float ammoval = 0;
	if (self.ammo_shells)
	{
		ammotype = 1;
		ammoval = self.ammo_shells;
	}
	else if (self.ammo_nails)
	{
		ammotype = 0;
		ammoval = self.ammo_nails;
	}
	else if (self.ammo_cells)
	{
		ammotype = 2;
		ammoval = self.ammo_cells;
	}
	
	msg_entity = other;
	BeginEvent(EV_GIVE_AMMO);
	MulticastByte(ammotype);
	MulticastByte(ammoval);
	multicast('0 0 0', MULTICAST_ONE_R);
	
	remove(self);
};

void() item_shells =
{
	setmodel(self, "models/sg_ammo.iqm");
	self.solid = SOLID_TRIGGER;
	self.touch = ammo_touch;
	self.ammo_shells = 10 + floor(random() * 15);
	setsize(self, '-16 -16 0', '16 16 32');
	self.clearable = TRUE;
};

void() item_bullets =
{
	setmodel(self, "models/bullets_ammo.iqm");
	self.solid = SOLID_TRIGGER;
	self.touch = ammo_touch;
	self.ammo_nails = 20 + floor(random() * 40);
	setsize(self, '-16 -16 0', '16 16 32');
	self.clearable = TRUE;
};

void() item_weapon =
{
	self.type = IT_WEAPON;
	float i = floor(random() * (weapon_list.length - 1) + 1);
	self.item_id = i;
	setmodel(self, weapon_list[i].model);
	self.clearable = TRUE;
	self.item_effect = floor(weapon_effects.length * random());
	// current mag
	self.ammo_shells = weapon_list[i].mag_size * (random() * 0.5 + 0.5);
	// spare mags
	self.ammo_nails = floor(1 + random() * 2.5);
	self.angles = '0 0 -90';
}

void() test_item =
{
	setmodel(self, "models/bomb.iqm");
	self.solid = SOLID_TRIGGER;
	self.touch = item_touch;
	// self.flags = FL_FINDABLE_NONSOLID;
	item_weapon();
	setsize(self, '-16 -16 0', '16 16 32');
	usable_chain_add(self);
};

void(entity attacker, vector dir, float amount) crate_die =
{
	entity drop = spawn();
	self_call(drop, test_item);
	setorigin(drop, self.origin + '0 0 16');
	drop.movetype = MOVETYPE_TOSS;
	// drop.avelocity = [0, crandom() * 2500, 0];
	drop.velocity = [crandom() * 25, crandom() * 25, 120];
	BeginEvent(EV_BOX_BREAK);
	MulticastVector(self.origin + '0 0 24');
	multicast(self.origin, MULTICAST_PVS);
	remove(self);
};

void() item_crate =
{
	self.clearable = TRUE;
	setmodel(self, "models/crate.iqm");
	self.solid = SOLID_BBOX;
	setsize(self, '-24 -24 0', '24 24 64');
	self.takes_damage = TRUE;
	self.health = 25;
	self.die = crate_die;
};

void() next_floor;
void() exit_touch =
{
	if (other.classname != "player") return;
	
	print("exit touched\n");
	next_floor();
};

void() misc_exit =
{
	self.clearable = TRUE;
	setmodel(self, "models/ladderdown.iqm");
	setsize(self, '-32 -32 0', '32 32 64');
	self.touch = exit_touch;
	self.solid = SOLID_TRIGGER;
	// self.flags = FL_FINDABLE_NONSOLID;
	usable_chain_add(self);
};
