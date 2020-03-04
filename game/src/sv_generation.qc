
entity e_map[MAP_W * MAP_H];

.int blocktype;
.vector blockpos;
float(entity viewer, float changed_flags) block_sendentity =
{
    WriteByte(MSG_ENTITY, ENT_TILEBLOCK);
    WriteByte(MSG_ENTITY, self.blockpos_x);
    WriteByte(MSG_ENTITY, self.blockpos_y);
    WriteByte(MSG_ENTITY, self.blocktype);
    return TRUE;
}

void(entity e, int type) set_block_type =
{
	if (e.blocktype == type) return;
	
	switch (type)
	{
	case 0:
		setmodel(e, "models/testblock.iqm");
		setsize(e, BLOCK_MINS, BLOCK_MAXS);
		e.solid = SOLID_BBOX;
		break;
	case 1:
		e.modelindex = 0;
		e.solid = SOLID_NOT;
		break;
	default:
		printf("set_block_type: unknown block type %i\n", type);
		return;
	}
	e.SendFlags = 1;
	e.blocktype = type;
};

void(entity e, int content) spawn_content =
{
	entity newent;
	switch (content)
	{
	case TC_ENEMY1:
		newent = spawn();
		setorigin(newent, e.origin);
		self_call(newent, enemy_crawler);	
		break;
	case TC_ITEM1:
		newent = spawn();
		setorigin(newent, e.origin);
		self_call(newent, item_crate);
		break;
	case TC_EXIT:
		newent = spawn();
		setorigin(newent, e.origin);
		self_call(newent, misc_exit);
		break;
	default: break;
	}
};


entity * __init_e_map_data;
int __init_e_map_index;
var void() __init_e_map_cb;
void() __init_e_map =
{
	int count = 0;
	vector pos;
	entity * emap = __init_e_map_data;
	for (int i = __init_e_map_index; i < MAP_W * MAP_H; i++)
	{
		// printf("at index %i\n", i);
		emap[i] = spawn();
		emap[i].SendEntity = block_sendentity;
		emap[i].movetype = MOVETYPE_NONE;
		emap[i].blocktype = -1; // make sure that set_block_type doesnt optimize
		emap[i].scale = 0.5;
		pos = index_to_map_pos(i);
		emap[i].blockpos = pos;
		setorigin(emap[i], [BLOCK_SIZE_x * pos_x, BLOCK_SIZE_y * pos_y] + MAP_ORIGIN);
		set_block_type(emap[i], 0);
		
		count++;
		if (count > 256)
		{
			__init_e_map_index = i;
			self.think = __init_e_map;
			self.nextthink = time + 0.05;
			return;
		}
	}
	
	__init_e_map_cb();
};

void() __reset_e_map =
{
	int count = 0;
	entity * emap = __init_e_map_data;
	for (int i = __init_e_map_index; i < MAP_W * MAP_H; i++)
	{
		emap[i].blocktype = -1; // make sure that set_block_type doesnt optimize
		set_block_type(emap[i], 0);
		count++;
		if (count > 256)
		{
			__init_e_map_index = i;
			self.think = __reset_e_map;
			self.nextthink = time + 0.05;
			return;
		}
	}
	__init_e_map_cb();
}

void(entity * emap, void() cb) init_e_map =
{
	__init_e_map_data = emap;
	__init_e_map_index = 0;
	__init_e_map_cb = cb;
	self.nextthink = time + 2;
	self.think = __init_e_map;
	// __init_e_map();
};

void(entity * emap, void() cb) reset_e_map =
{
	__init_e_map_data = emap;
	__init_e_map_index = 0;
	__init_e_map_cb = cb;
	self.nextthink = time + 2;
	self.think = __reset_e_map;	
};

void(tile_map * tilemap, entity * emap) apply_tilemap_to_emap =
{
	for (int i = 0; i < MAP_W * MAP_H; i++)
	{
		set_block_type(emap[i], tilemap->tiles[i]);
		spawn_content(emap[i], tilemap->content[i]);
	}
};

tile_set * test_tile_set;
tile_map test_tile_map;
meta_map test_meta_map;

void() apply_tilemap_wrapper =
{
	apply_tilemap_to_emap(&test_tile_map, e_map);
};

int(tile_map * map, vector pos) random_floor_tile_in_meta =
{
	int found = FALSE;
	int attempts = 0;
	while (!found)
	{
		int x = (int)floor(random() * META_W);
		int y = (int)floor(random() * META_H);
		int i = map_tile_i([pos_x * META_W + x, pos_y * META_H + y]);
		if (map->tiles[i] == 1) return i;
		attempts++;
		if (attempts > 500) return i;
	}
	return 0;
};

vector(tile_map * tilemap, meta_map * metamap) get_map_spawn_point =
{
	for (int i = 0; i < MAP_METAS_X * MAP_METAS_Y; i++)
	{
		if (metamap->flags[i] & 1)
		{
			int tile = random_floor_tile_in_meta(tilemap, meta_index_to_pos(i));
			vector pos = index_to_map_pos(tile);
			return 64 * pos + MAP_ORIGIN;
		}
	}
	
	return '0 0 0';
};

void(tile_map * tilemap, meta_map * metamap) set_map_goal_point =
{
	for (int i = 0; i < MAP_METAS_X * MAP_METAS_Y; i++)
	{
		if (metamap->flags[i] & 2)
		{
			int tile = random_floor_tile_in_meta(tilemap, meta_index_to_pos(i));
			// vector pos = index_to_map_pos(tile);
			tilemap->content[tile] = TC_EXIT;
		}
	}
	
	// return '0 0 0';
};


entity emap_init;
void() init_test_map =
{
	emap_init = spawn();
	test_tile_set = new_tile_set();
	read_tile_set("cofe_enm", test_tile_set);
	generate_map(&test_meta_map);
	fill_map(&test_tile_map, &test_meta_map, test_tile_set);
	set_map_goal_point(&test_tile_map, &test_meta_map);
	test_spawnpoint = get_map_spawn_point(&test_tile_map, &test_meta_map);
	entity old_self = self;
	self = emap_init;
	init_e_map(e_map, apply_tilemap_wrapper);
	self = old_self;
};

void() reset_map =
{
	BeginEvent(EV_CLEAR_MAP);
	multicast('0 0 0', MULTICAST_ALL_R);
	
	// Things that have to be cleared:
	// - enemies
	// - items that are on the ground
	// - any temporary stuff
	// - crates
	// - lights (csqc)
	// - exit
	// Things that can't be cleared:
	// - players
	// - tiles (just change them instead)
	for (entity e = findfloat(world, clearable, TRUE); e; e = findfloat(e, clearable, TRUE))
	{
		if (e.player_chain_next || e.player_chain_prev)
			usable_chain_remove(e);

		remove(e);
	}

	generate_map(&test_meta_map);
	fill_map(&test_tile_map, &test_meta_map, test_tile_set);
	set_map_goal_point(&test_tile_map, &test_meta_map);
	test_spawnpoint = get_map_spawn_point(&test_tile_map, &test_meta_map);
	entity old_self = self;
	self = emap_init;
	reset_e_map(e_map, apply_tilemap_wrapper);
	self = old_self;
};

void() next_floor =
{
	reset_map();
	for (entity p = player_chain_head; p; p = p.player_chain_next)
	{
		setorigin (p, test_spawnpoint);
	}
};
