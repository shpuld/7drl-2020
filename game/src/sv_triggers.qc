
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

void() set_bad_weapon_effect =
{
	self.item_effect = WEAPON_BAD_START + floor(random() * (WEAPON_AVG_START - WEAPON_BAD_START));
}

void() set_avg_weapon_effect =
{
	self.item_effect = WEAPON_AVG_START + floor(random() * (WEAPON_GOOD_START - WEAPON_AVG_START));
}

void() set_good_weapon_effect =
{
	self.item_effect = WEAPON_GOOD_START + floor(random() * (WEAPON_SUPER_START - WEAPON_GOOD_START));
}

void() set_super_weapon_effect =
{
	self.item_effect = WEAPON_SUPER_START + floor(random() * (weapon_effects.length - WEAPON_SUPER_START));
}

void() set_weapon_effect =
{
	float r = random();
	if (current_level >= LEVEL_HECK)
	{
		if (r < 0.1) set_bad_weapon_effect();
		else if (r < 0.4) set_avg_weapon_effect();
		else if (r < 0.85) set_good_weapon_effect();
		else set_super_weapon_effect();				
	}
	else if (current_level >= LEVEL_RUST)
	{
		if (r < 0.2) set_bad_weapon_effect();
		else if (r < 0.6) set_avg_weapon_effect();
		else if (r < 0.95) set_good_weapon_effect();
		else set_super_weapon_effect();		
	}
	else if (current_level >= LEVEL_INSIDE)
	{
		if (r < 0.5) set_bad_weapon_effect();
		else if (r < 0.8) set_avg_weapon_effect();
		else if (r < 0.98) set_good_weapon_effect();
		else set_super_weapon_effect();
	}
	else // LEVEL_SNOW
	{
		if (r < 0.75) set_bad_weapon_effect();
		else if (r < 0.96) set_avg_weapon_effect();
		else set_good_weapon_effect();
	}
}


void() item_weapon =
{
	self.type = IT_WEAPON;
	float i = floor(random() * (weapon_list.length - 1) + 1);
	self.item_id = i;
	setmodel(self, weapon_list[i].model);
	self.clearable = TRUE;
	set_weapon_effect();
	// current mag
	self.ammo_shells = weapon_list[i].mag_size;
	// spare mags
	self.ammo_nails = 2;
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

void(float start, float end) set_mod_effect =
{
	self.item_effect = start + floor(random() * (end - start));
}

void() set_powermod_effect =
{
	float r = random();
	if (current_level >= LEVEL_HECK)
	{
		if (r < 0.1) set_mod_effect(MOD_BAD_START, MOD_AVG_START);
		else if (r < 0.6) set_mod_effect(MOD_AVG_START, MOD_GOOD_START);
		else set_mod_effect(MOD_GOOD_START, powermod_effects.length);				
	}
	else if (current_level >= LEVEL_RUST)
	{
		if (r < 0.4) set_mod_effect(MOD_BAD_START, MOD_AVG_START);
		else if (r < 0.8) set_mod_effect(MOD_AVG_START, MOD_GOOD_START);
		else set_mod_effect(MOD_GOOD_START, powermod_effects.length);		
	}
	else if (current_level >= LEVEL_INSIDE)
	{
		if (r < 0.6) set_mod_effect(MOD_BAD_START, MOD_AVG_START);
		else if (r < 0.96) set_mod_effect(MOD_AVG_START, MOD_GOOD_START);
		else set_mod_effect(MOD_GOOD_START, powermod_effects.length);			
	}
	else // LEVEL_SNOW
	{
		if (r < 0.8) set_mod_effect(MOD_BAD_START, MOD_AVG_START);
		else if (r < 0.99) set_mod_effect(MOD_AVG_START, MOD_GOOD_START);
		else set_mod_effect(MOD_GOOD_START, powermod_effects.length);		
	}
}


void() power_module =
{
	self.type = IT_POWERMOD;
	self.item_id = I_POWERMOD;
	setmodel(self, "models/power_mod.iqm");
	self.clearable = TRUE;
	set_powermod_effect();
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

void() medkit_touch =
{
	if (other.classname != "player") return;
	if (other.health >= 100) return;
	
	other.health = min(100, other.health + 20);
	usable_chain_remove(self);
	sound(self, CHAN_AUTO, "sounds/spawn.wav", 0.7, 0.5, 120);
	remove(self);
};

void() medkit =
{
	setmodel(self, "models/medkit.iqm");
	self.clearable = TRUE;
	self.touch = medkit_touch;
	self.type = IT_MEDKIT;
}

void() armor =
{
	setmodel(self, "models/armor.iqm");
	self.item_id = I_ARMOR;
	self.item_effect = min(armor_effects.length - 1, 1 + random() * floor(current_level * 0.75));
	self.clearable = TRUE;
	self.type = IT_ARMOR;
}

void(float force_spawn_gun) snow_item_spawn =
{
	float r = random();
	if (r < 0.85 || force_spawn_gun)
		item_weapon();
	else if (r < 0.9)
		ammo_box();
	else if (r < 0.95)
		power_module();
	else
		armor();
};

void(float force_spawn_gun) inside_item_spawn =
{
	float r = random();
	if (r < 0.7 || force_spawn_gun)
		item_weapon();
	else if (r < 0.85)
		ammo_box();
	else if (r < 0.95)
		power_module();
	else
		armor();
};

void(float force_spawn_gun) rust_item_spawn =
{
	float r = random();
	if (r < 0.7 || force_spawn_gun)
		item_weapon();
	else if (r < 0.85)
		ammo_box();
	else if (r < 0.95)
		power_module();
	else
		armor();
};

void(float force_spawn_gun) heck_item_spawn =
{
	float r = random();
	if (r < 0.6 || force_spawn_gun)
		item_weapon();
	else if (r < 0.75)
		ammo_box();
	else if (r < 0.95)
		power_module();
	else
		armor();
};

void(entity opener) test_item =
{
	setmodel(self, "models/bomb.iqm");
	self.solid = SOLID_TRIGGER;
	self.touch = item_touch;
	// self.flags = FL_FINDABLE_NONSOLID;
	float force_spawn_gun = opener.classname == "player" && !opener.inventory[INV_SLOT_WEAPON1].item_id && !opener.inventory[INV_SLOT_WEAPON2].item_id;
	
	if (!force_spawn_gun && opener.health < 85 && random() < 0.08) medkit();
	else if (current_level >= LEVEL_HECK) heck_item_spawn(force_spawn_gun);
	else if (current_level >= LEVEL_RUST) rust_item_spawn(force_spawn_gun);
	else if (current_level >= LEVEL_INSIDE) inside_item_spawn(force_spawn_gun);
	else snow_item_spawn(force_spawn_gun);
	
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
	entity endzone = find(world, classname, "info_endzone");
	for (entity e = player_chain_head; e; e = e.player_chain_next)
		setorigin(e, endzone.origin);

	current_level += 1;

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

void() pre_exit_touch =
{
	if (other.classname != "player") return;
	if (self.nextthink >= time) return;

	BeginEvent(EV_EXIT_LEVEL);
	multicast('0 0 0', MULTICAST_ALL_R);
	self.nextthink = time + 0.25;
	self.think = exit_touch;
}

void(entity dealer, vector dir, float amount) machine_hurt = {};

void(entity dealer, vector dir, float amount) machine_die =
{
	BeginEvent(EV_VICTORY);
	multicast('0 0 0', MULTICAST_ALL_R);
	game_over = TRUE;
};

void() machine =
{
	self.takes_damage = TRUE;
	self.health = 500;
	setmodel(self, "models/machine.iqm");
	setsize(self, '-32 -32 0', '32 32 64');
	self.solid = SOLID_BBOX;
	self.hurt = machine_hurt;
	self.die = machine_die;
}

void() misc_exit =
{
	self.clearable = TRUE;
	if (current_level == 10 && self.classname != "info_endzone_exit")
	{
		machine();
		return;
	}

	self.type = IT_LADDER;
	setmodel(self, "models/ladderdown.iqm");
	setsize(self, '-32 -32 0', '32 32 64');
	self.touch = pre_exit_touch;
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

void() pre_real_exit_touch =
{
	if (other.classname != "player") return;
	if (self.nextthink >= time) return;

	BeginEvent(EV_ENTER_LEVEL);
	multicast('0 0 0', MULTICAST_ALL_R);
	self.nextthink = time + 0.25;
	self.think = real_exit_touch;	
}

// TODO:
// on enter regular exit, start by clearing ents
// then spawn info_endzone_items as rewards or whatever
// then we can regenerate map
void() info_endzone_exit =
{
	misc_exit();
	self.clearable = FALSE;
	self.touch = pre_real_exit_touch;
};

void() info_endzone =
{
	entity e = spawn();
	setorigin(e, self.origin + '0 128 0');
	self_call(e, item_crate);
};

void() misc_light =
{
	self.effects |= EF_FULLBRIGHT;
	setorigin(self, self.origin + [crandom() * 10, crandom() * 10]);
	self.angles_y = random() * 360;
	setmodel(self, "models/glowstick.iqm");
	self.scale = 1.4;
	self.clearable = TRUE;
};

void() misc_light_small =
{
	self.scale = 0.8;
	self.frame = 1;
	self.effects |= EF_FULLBRIGHT;
	setorigin(self, self.origin + [crandom() * 10, crandom() * 10]);
	self.angles_y = random() * 360;
	setmodel(self, "models/glowstick.iqm");
	self.clearable = TRUE;
};
