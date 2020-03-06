
// MOVE THE FOLLOWING STUFF TO CL_GENERATION or something

tile_map * csqc_map;

// 1 bottom/top + 4 side quads
const int QUADS_PER_BLOCK = 5;
struct block_geom { 
	trisoup_simple_vert_s verts[QUADS_PER_BLOCK * 4];
};

struct map_row_geom {
	block_geom blocks[MAP_METAS_X * META_W];
};

struct map_geom {
	map_row_geom rows[MAP_METAS_Y * META_H];
	int indices[MAP_METAS_Y * MAP_METAS_X * META_H * META_W * QUADS_PER_BLOCK * 6];
};

var map_geom * csqc_mapgeom;

const int INDICES_PER_ROW = MAP_METAS_X * META_W * QUADS_PER_BLOCK * 6;

void(map_geom * mapgeom, int startrow, int numrows) draw_map_geom =
{
	int total_rows = MAP_METAS_Y * META_H;
	if (total_rows - startrow < numrows) numrows = total_rows - startrow;
	
	int num_indices = INDICES_PER_ROW * numrows;
	int start_index_ofs = startrow * INDICES_PER_ROW;
	int * indices_ptr = &(mapgeom->indices[start_index_ofs]);
	//printf("numindices: %i\n", num_indices);
	float level = getstatf(STAT_LEVEL);
	string texture = 
		level >= LEVEL_HECK ? "heck_blocks" :
		level >= LEVEL_RUST ? "rust_blocks" :
		level >= LEVEL_INSIDE ?  "test_blocks" :
		"ice_blocks";

	addtrisoup_simple(texture, 0, &(mapgeom->rows[0]->blocks[0]->verts[0]), indices_ptr, num_indices);
};

block_geom * (map_geom * mapgeom, vector pos) block_geom_for_pos =
{
	// pick correct row and correct column by coord, return pointer
	map_row_geom * row = &(mapgeom->rows[pos_y]);
	return &(row->blocks[pos_x]);
};

int(int type) is_floor_tile =
{
	return type != 0;
};



float(int cornernum) vertex_x_ofs =
{
	return (cornernum == 1 || cornernum == 2) * BLOCK_SIZE_x;
};

float(int cornernum) vertex_y_ofs =
{
	return (cornernum == 0 || cornernum == 1) * BLOCK_SIZE_y;
};

const vector tile_st_size = [1/16, 1/2];
float(int cornernum, int rotation = 0) vertex_s_ofs =
{
	switch (rotation)
	{
	case 0: return (cornernum == 1 || cornernum == 2) * tile_st_size_x;
	case 1: return (cornernum == 2 || cornernum == 3) * tile_st_size_x;
	case 2: return (cornernum == 3 || cornernum == 0) * tile_st_size_x;
	case 3: return (cornernum == 0 || cornernum == 1) * tile_st_size_x;
	}
	return 0;
};

float(int cornernum, int rotation = 0) vertex_t_ofs =
{
	switch (rotation)
	{
	case 0: return (cornernum == 2 || cornernum == 3) * tile_st_size_y;
	case 1: return (cornernum == 3 || cornernum == 0) * tile_st_size_y;
	case 2: return (cornernum == 0 || cornernum == 1) * tile_st_size_y;
	case 3: return (cornernum == 1 || cornernum == 2) * tile_st_size_y;
	}
	return 0;
};

vector(int neighbor) neighboring_to_dir =
{
	vector ret = '0 0 0';

	// neighbors go like:
	// 7 0 1
	// 6   2
	// 5 4 3
	if (neighbor >= 1 && neighbor <= 3) ret_x = 1;
	else if (neighbor >= 5 && neighbor <= 7) ret_x = -1;
	
	if (neighbor >= 3 && neighbor <= 5) ret_y = -1;
	else if (neighbor <= 1 || neighbor == 7) ret_y = 1;
	
	return ret;
};

vector(tile_map * map, vector pos) tile_s_base_and_rot =
{
	// return [baseline, rotation, 0], baseline is x coord of top-left of texture on atlas
	string cardinal_surr = "";
	string all_surr = "";
	vector nb_dir;
	float facing_similar_block;
	int first_one_cardinal = -1; // for orientation to make it easier to match like 0100 -> 1000
	int first_one = -1;
	float rotation = 0;
	
	// Form rotation string, could be done as a bit field too
	for (float i = 0; i < 8; i++)
	{
		nb_dir = neighboring_to_dir(i);
		facing_similar_block = TRUE;
		if (is_map_pos_in_bounds(pos + nb_dir))
		{
			facing_similar_block = map->tiles[map_pos_to_index(pos + nb_dir)] == map->tiles[map_pos_to_index(pos)];
		}
		if (i % 2 == 0)
		{
			cardinal_surr = strcat(cardinal_surr, facing_similar_block ? "0" : "1");
			if (first_one_cardinal < 0 && !facing_similar_block) first_one_cardinal = i * 0.5;
		}
		all_surr = strcat(all_surr, facing_similar_block ? "0" : "1");
		if (first_one < 0 && !facing_similar_block) first_one = i;
	}
	// printf("card: %s, all: %s, first card: %i, first: %i\n", cardinal_surr, all_surr, first_one_cardinal, first_one);
	
	// Orient and save rotation
	
	// it's not "0000", meaning at least one cardinal direction faces a different blocktype
	if (first_one_cardinal >= 0)
		rotation = first_one_cardinal;
	else // it's a "0000" case
		rotation = floor(first_one / 2);
	
	if (rotation > 0)
	{
		cardinal_surr = strcat(
			substring(cardinal_surr, rotation, 4 - rotation),
			substring(cardinal_surr, 0, rotation)
		);
		all_surr = strcat(
			substring(all_surr, rotation * 2, 8 - (rotation * 2)),
			substring(all_surr, 0, rotation * 2)
		);
	}

	float uv_x;
	switch (cardinal_surr)
	{
	case "1111":
		uv_x = 0;
		break;
	case "1110":
		uv_x = 1;
		break;
	case "1101":
		uv_x = 1;
		rotation = 3;
		break;
	case "1011":
		uv_x = 1;
		rotation = 2;
		break;
	case "1010":
		uv_x = 2;
		break;
	case "1001": // hard coded
		rotation = 3;
		if (str_at(all_surr, 3) == "0") uv_x = 3;
		else uv_x = 4;
		break;
	case "1100":
		if (str_at(all_surr, 5) == "0") uv_x = 3;
		else uv_x = 4;
		break;
	case "1000":
		if (str_at(all_surr, 3) == "0")
		{
			if (str_at(all_surr, 5) == "0") uv_x = 5;
			else uv_x = 7;
		}
		else if (str_at(all_surr, 5) == "0")
		{
			uv_x = 6;
		}
		else
		{
			uv_x = 8;
		}
		break;
	case "0000":
		if (all_surr == "00000000")
		{
			// printf("all empty %s, rot %f\n", all_surr, rotation);
			rotation = 0;
			uv_x = 9;
			break;
		}
		if (all_surr == "01000000")
		{
			uv_x = 10;
			break;
		}
		if (all_surr == "01010000")
		{
			uv_x = 11;
			break;
		}
		if (all_surr == "01000001")
		{
			// hard code
			uv_x = 11;
			rotation = 3;
			break;
		}
		if (all_surr == "01010100")
		{
			uv_x = 12;
			break;
		}
		if (all_surr == "01010001")
		{
			// hard code
			uv_x = 12;
			rotation = 3;
			break;
		}
		if (all_surr == "01000101")
		{
			// hard code
			uv_x = 12;
			rotation = 2;
			break;
		}
		if (all_surr == "01000100")
		{
			uv_x = 13;
			break;
		}
		uv_x = 14;
		break;
	}
	
	return [uv_x * tile_st_size_x, rotation, 0];
};

void(map_geom * mapgeom, tile_map * map, vector pos) shape_block =
{
	// look at the actual tilemap to seee what sort of shape a certain block should have
	// set its floor/ceil height, walls, texture coords, call this func again when map changes
	// block->
	int blocktype = map->tiles[map_pos_to_index(pos)];
	block_geom * geom = block_geom_for_pos(mapgeom, pos);
	int is_floor = is_floor_tile(blocktype);
	float wall_height = 72;
	float blockheight = (!is_floor) * wall_height;
	vector world_ofs = MAP_ORIGIN + [BLOCK_SIZE_x * pos_x, BLOCK_SIZE_y * pos_y] - BLOCK_SIZE * 0.5;
	float xpos, ypos;
	vector st_infos = tile_s_base_and_rot(map, pos);
	
	float wobble_magnitude = getstatf(STAT_LEVEL) == 0 ? 3 : 0;
	float level = getstatf(STAT_LEVEL);
	// x = vert frequency, y = hor frequency, z = magnitude
	vector wobble_values = 
		level >= LEVEL_HECK ? [85, 95, 4] :
		level >= LEVEL_RUST ? [75, 85, level - LEVEL_RUST + 1] :
		level >= LEVEL_INSIDE ? [64, 64, 0] :
		level >= LEVEL_SNOW ? [95, 105, 3] :
		'1 1 0';

	for (int i = 0; i < 4; i++)
	{
		xpos = world_ofs_x + vertex_x_ofs(i);
		ypos = world_ofs_y + vertex_y_ofs(i);
		// xpos += sin(xpos * 1.7) * 8;
		ypos += cos(xpos * wobble_values_x) * wobble_values_z;
		xpos += sin(ypos * wobble_values_y) * wobble_values_z;
		geom->verts[i].xyz[0] = xpos;
		geom->verts[i].xyz[1] = ypos;
		geom->verts[i].xyz[2] = blockheight;
		geom->verts[i].st[0] = st_infos_x + vertex_s_ofs(i, st_infos_y);
		geom->verts[i].st[1] = (is_floor ? 0.5 : 0) + vertex_t_ofs(i, st_infos_y);
		
		// for example, 0 corner has west to its left and and north to its right,
		// and 1 corner has north to its left and east to its right.
		// 1 = north, 2 = east, 3 = south, 4 = west
		int leftwall = i;
		int rightwall = i + 1;
		if (leftwall < 1) leftwall = 4;
		
		geom->verts[(leftwall*4) + 1].xyz[0] = xpos;
		geom->verts[(leftwall*4) + 1].xyz[1] = ypos;
		geom->verts[(leftwall*4) + 1].xyz[2] = blockheight;
		
		geom->verts[(leftwall*4) + 2].xyz[0] = xpos;
		geom->verts[(leftwall*4) + 2].xyz[1] = ypos;
		geom->verts[(leftwall*4) + 2].xyz[2] = blockheight;
		
		geom->verts[(rightwall*4) + 0].xyz[0] = xpos;
		geom->verts[(rightwall*4) + 0].xyz[1] = ypos;
		geom->verts[(rightwall*4) + 0].xyz[2] = blockheight;
		
		geom->verts[(rightwall*4) + 3].xyz[0] = xpos;
		geom->verts[(rightwall*4) + 3].xyz[1] = ypos;
		geom->verts[(rightwall*4) + 3].xyz[2] = blockheight;
	}
	
	if (is_floor)
	{
		int currentbit;
		vector dir, newpos;
		int is_facing_wall;
		int facing_tile;
		int quadnum;
		for (int i = 0; i < 4; i++)
		{
			currentbit = 1i << i;
			dir = bit_to_dir(currentbit);
			newpos = pos + dir;
			is_facing_wall = FALSE;
			if (is_map_pos_in_bounds(newpos))
			{
				facing_tile = map->tiles[map_pos_to_index(newpos)];
				if (!is_floor_tile(facing_tile)) is_facing_wall = TRUE;
			}
			
			if (is_facing_wall)
			{
				quadnum = i + 1;
				for (int j = 0; j < 4; j++)
				{
					if (j < 2)
						geom->verts[quadnum*4 + j].xyz[2] = wall_height;
					geom->verts[quadnum*4 + j].st[0] = (15 * tile_st_size_x) + vertex_s_ofs(j);
					geom->verts[quadnum*4 + j].st[1] = (1 * tile_st_size_y) + vertex_t_ofs(j);
				}
			}
		}
	}
};

void(map_geom * mapgeom, tile_map * map) shape_all_blocks =
{
	for (int i = 0; i < MAP_W * MAP_H; i++)
	{
		shape_block(mapgeom, map, index_to_map_pos(i));
	}
};

void() clear_csqc_map =
{
	for (int i = 0; i < MAP_W * MAP_H; i++)
		csqc_map->tiles[i] = -1;
	
	memfill8(csqc_mapgeom, 0, sizeof(map_geom));
	
	int num_indices = csqc_mapgeom->indices.length;
	int num_quads = num_indices / 6;
	for (int quadnum = 0; quadnum < num_quads; quadnum++)
	{
		csqc_mapgeom->indices[quadnum*6 + 0] = quadnum*4 + 0;
		csqc_mapgeom->indices[quadnum*6 + 1] = quadnum*4 + 1;
		csqc_mapgeom->indices[quadnum*6 + 2] = quadnum*4 + 2;
		csqc_mapgeom->indices[quadnum*6 + 3] = quadnum*4 + 0;
		csqc_mapgeom->indices[quadnum*6 + 4] = quadnum*4 + 2;
		csqc_mapgeom->indices[quadnum*6 + 5] = quadnum*4 + 3;
	}
	
	blocks_loaded = 0;
	block_loading_done = FALSE;
};

void() init_csqc_map =
{
	csqc_map = (tile_map*)memalloc(sizeof(tile_map));
	csqc_mapgeom = (map_geom*)memalloc(sizeof(map_geom));
	
	clear_csqc_map();
};


float() block_predraw =
{
	return PREDRAW_AUTOADD;
};

void(float isnew) block_update =
{
	if (isnew)
	{
		self.predraw = block_predraw;
		self.drawmask = MASK_ENGINE;
		self.scale = 0.5;
	}
	float posx = readbyte();
	float posy = readbyte();
	float type = readbyte();
	setorigin(self, [BLOCK_SIZE_x * posx, BLOCK_SIZE_y * posy] + MAP_ORIGIN);
	float oldtile = csqc_map->tiles[map_pos_to_index([posx, posy])];
	csqc_map->tiles[map_pos_to_index([posx, posy])] = type;
	if (block_loading_done)
	{
		shape_block(csqc_mapgeom, csqc_map, [posx, posy]);
	}
	else
	{
		if (oldtile == -1)
		{
			blocks_loaded++;
		}
		if (blocks_loaded >= MAP_W * MAP_H)
		{
			block_loading_done = TRUE;
			shape_all_blocks(csqc_mapgeom, csqc_map);
		}
	}
	
	if (type == 0) 
	{
		// setmodel(self, "models/testblock.iqm");
		setsize(self, BLOCK_MINS, BLOCK_MAXS); 
		self.solid = SOLID_BBOX;
	}
	else 
	{	
		self.solid = SOLID_NOT;
		setsize(self, '0 0 0', '0 0 0');
		self.modelindex = 0;
	}
};
