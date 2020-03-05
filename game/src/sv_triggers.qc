
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
	
	put_item_in_inventory(other, self);
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

void() item_bullets =
{
	setmodel(self, "models/bullets_ammo.iqm");
	self.solid = SOLID_TRIGGER;
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
	self.item_effect = 1+ floor((weapon_effects.length - 1) * random());
	// current mag
	self.ammo_shells = weapon_list[i].mag_size;
	// spare mags
	self.ammo_nails = floor(1 + random() * 2.5);
	self.angles = '0 0 -90';
}

void(float item, float effect) spawn_weapon_cheat =
{
	entity e = spawn();
	e.type = IT_WEAPON;
	e.item_id = item;
	setmodel(e, weapon_list[item].model);
	e.clearable = TRUE;
	e.item_effect = effect;
	e.ammo_shells = weapon_list[item].mag_size;
	e.ammo_nails = 5;
	e.angles = '0 0 -90';
	setorigin(e, self.origin + '0 0 5');
	setsize(e, '-16 -16 0', '16 16 32');
	e.touch = item_touch;
	e.solid = SOLID_TRIGGER;
	usable_chain_add(e);
}

void() power_module =
{
	self.type = IT_POWERMOD;
	self.item_id = I_POWERMOD;
	setmodel(self, "models/power_mod.iqm");
	self.clearable = TRUE;
	self.item_effect = 1 + floor((powermod_effects.length - 1) * random());
}

void() ammo_touch =
{
	if (other.classname != "player") return;
	
	msg_entity = other;
	float gavesomething = FALSE;
	if (other.inventory[INV_SLOT_WEAPON1].item_id)
	{
		BeginEvent(EV_GIVE_AMMO);
		MulticastByte(other.inventory[INV_SLOT_WEAPON1].item_id);
		MulticastByte(1);
		multicast(self.origin, MULTICAST_ONE_R);
		gavesomething = TRUE;
	}
	if (other.inventory[INV_SLOT_WEAPON2].item_id)
	{
		BeginEvent(EV_GIVE_AMMO);
		MulticastByte(other.inventory[INV_SLOT_WEAPON2].item_id);
		MulticastByte(1);
		multicast(self.origin, MULTICAST_ONE_R);
		gavesomething = TRUE;
	}
	
	if (gavesomething)
	{
		remove(self);
		usable_chain_remove(self);
	}
}

void() ammo_box =
{
	setmodel(self, "models/bullets_ammo.iqm");
	self.clearable = TRUE;
	self.touch = ammo_touch;
	self.type = IT_AMMO;
}

void(entity opener) test_item =
{
	setmodel(self, "models/bomb.iqm");
	self.solid = SOLID_TRIGGER;
	self.touch = item_touch;
	// self.flags = FL_FINDABLE_NONSOLID;
	float r = random();
	float force_spawn_gun = opener.classname == "player" && !opener.inventory[INV_SLOT_WEAPON1].item_id && !opener.inventory[INV_SLOT_WEAPON2].item_id;
	if (r < 0.6 || force_spawn_gun)
		item_weapon();
	else if (r < 0.8)
		power_module();
	else
		ammo_box();
	setsize(self, '-16 -16 0', '16 16 32');
	usable_chain_add(self);
};

void(entity attacker, vector dir, float amount) crate_die =
{
	entity drop = spawn();
	entity oldself = self;
	self = drop;
	test_item(attacker);
	self = oldself;
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

void() reset_map;
void() start_next_floor;
void() exit_touch =
{
	if (other.classname != "player") return;

	entity endzone = find(world, classname, "info_endzone");
	for (entity e = player_chain_head; e; e = e.player_chain_next)
		setorigin(e, endzone.origin);

	reset_map();
	entity oldself = self;
	for (entity e = find(world, classname, "info_endzone_item"); e; e = find(e, classname, "info_endzone_item"))
	{
		self = spawn();
		setorigin(self, e.origin);
		item_crate();		
	}
	self = oldself;
	// next_floor();
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

void() info_endzone_item =
{
	// initial crate only
};

void() real_exit_touch =
{
	start_next_floor();
};

// TODO:
// on enter regular exit, start by clearing ents
// then spawn info_endzone_items as rewards or whatever
// then we can regenerate map
void() info_endzone_exit =
{
	misc_exit();
	self.clearable = FALSE;
	self.touch = real_exit_touch;
};

void() info_endzone =
{
	entity e = spawn();
	setorigin(e, self.origin + '0 128 0');
	self_call(e, item_crate);
};
