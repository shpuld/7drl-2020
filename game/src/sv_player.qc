
//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc.
//

void() PlayerJump =
{
	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;
	
	self.weaponframe = 0;
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.button2 = 0;
};

.float equipped_slot;

void() reset_map;

void() CheckImpulses =
{
	switch (self.impulse)
	{
	default: break;
	case 1:
		self.equipped_slot = !self.equipped_slot;
		break;
	case 100:
		reset_map();
		break;
	case 101:
		spawn_weapon_cheat(6, 1);
		break;
	case 200:
		entity test = find(world, classname, "info_endzone");
		setorigin(self, test.origin);
		break;
	}
	self.impulse = 0;
};

vector() get_spawn_point =
{
	/*
	if (test_spawnpoint != '0 0 0')
	{
		return test_spawnpoint;
	}
	*/
	entity spawnpoint = world;
	spawnpoint = find(spawnpoint, classname, "info_endzone");

	return spawnpoint.origin + '0 0 1';
};

.float use_released;
void() PlayerPreThink =
{	
	CheckImpulses();
	
	float closest_usable_dist = 5000;
	entity closest_usable = world;
	for (entity e = usable_chain_head; e; e = e.player_chain_next)
	{
		vector diff = [e.origin.x - self.origin.x, e.origin.y - self.origin.y];
		float sqdist = diff.x*diff.x + diff.y*diff.y;
		
		if (sqdist < closest_usable_dist)
		{
			closest_usable_dist = sqdist;
			closest_usable = e;
		}
	}
	if (closest_usable_dist < 5000)
	{
		if (closest_usable.item_id)
		{
			self.type = closest_usable.type;
			self.item_id = closest_usable.item_id;
			self.item_effect = closest_usable.item_effect;
			self.ammo_shells = closest_usable.ammo_shells;
			self.ammo_nails = closest_usable.ammo_nails;
			
			if (
				closest_usable.ammo_nails && 
				(closest_usable.item_id == self.inventory[0].item_id || closest_usable.item_id == self.inventory[1].item_id)
			) {
				// take spare mags
				msg_entity = self;
				BeginEvent(EV_GIVE_AMMO);
				MulticastByte(closest_usable.item_id);
				MulticastByte(closest_usable.ammo_nails);
				multicast(self.origin, MULTICAST_ONE_R);
				closest_usable.ammo_nails = 0;
			}
		}
		if (self.button3 && self.use_released)
		{
			entity oldself = self;
			entity oldother = other;
			other = self;
			self = closest_usable;
			self.touch();
			other = oldother;
			self = oldself;
			
			self.use_released = FALSE;
		}
	}
	else
	{
		self.item_id = 0;
		self.item_effect = 0;
		self.ammo_shells = 0;
		self.ammo_nails = 0;
	}
	if (!self.button3) self.use_released = TRUE;

	// entity gun = self.inventory[self.equipped_slot];
	if (self.button0)
	{
		// if (gun) gun.primary_fire();
	}
	if (self.button1)
	{
		// if (gun) gun.secondary_fire();
	}
	if (self.button2)
	{
		PlayerJump();
	}
	else
	{
		self.flags = self.flags | FL_JUMPRELEASED;
	}
};

void() PlayerPostThink =
{
	self.SendFlags = 1;
};

void() ClientKill =
{
};

//called when a client connects to the server
void() ClientConnect =
{
	// print("Client connect\n");
};

float(entity viewer, float changed_flags) player_sendentity =
{
    WriteByte(MSG_ENTITY, ENT_PLAYER);
    WriteVector(MSG_ENTITY, self.origin);
    WriteVector(MSG_ENTITY, self.angles);
    WriteVector(MSG_ENTITY, self.velocity);
    WriteFloat(MSG_ENTITY, self.flags); // Flags, important for physics
    return TRUE;
};

void() PlayerSpawn =
{
	self.classname = "player";
	self.solid = SOLID_SLIDEBOX;
	setmodel(self, "models/player.iqm");
	self.movetype = MOVETYPE_NONE;
	self.health = 100;
	self.takes_damage = TRUE;
	self.SendEntity = player_sendentity;
	setorigin(self, get_spawn_point());
	self.fixangle = TRUE;
	setsize(self, '-12 -12 0', '12 12 64');
	self.view_ofs = [0, 0, 56];
	self.equipped_slot = 0;
	
	msg_entity = self;
};

void() PutClientInServer =
{
	player_chain_add(self);
	PlayerSpawn();
};

void() ClientDisconnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the game.\n");
	player_chain_remove(self);
};


void() SetNewParms =
{
};

void() SetChangeParms =
{
};

void() info_player_start =
{
};

void(float elapsedtime) SV_PausedTic =
{
	// if (elapsedtime > 2) setpause(0);
};

void(string command_string) SV_ParseClientCommand =
{
	tokenize(command_string);
	string cmd = argv(0);
	switch (cmd)
	{
	default: break;
	}
	clientcommand(self, command_string);
};


void() SV_RunClientCommand =
{
	// runstandardplayerphysics(self);
	player_move(self);
};


