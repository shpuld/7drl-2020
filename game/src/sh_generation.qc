
const int META_W = 8;
const int META_H = 8;
const int MAP_METAS_X = 4;
const int MAP_METAS_Y = 6;
const int MAP_W = MAP_METAS_X * META_W;
const int MAP_H = MAP_METAS_Y * META_H;

const int DIR_N = 1;
const int DIR_E = 2;
const int DIR_S = 4;
const int DIR_W = 8;

enum {
	TC_EMPTY, TC_SPAWN, TC_EXIT, TC_ENEMY1, TC_ITEM1
};

const float NUM_CONTENT_TYPES = 5;

string(int contenttype) content_name =
{
	switch (contenttype)
	{
		case TC_EMPTY: return "Empty";
		case TC_SPAWN: return "Start";
		case TC_EXIT: return "Exit";
		case TC_ENEMY1: return "Enm1";
		case TC_ITEM1: return "Item1";
		default: return "Unkn";
	}
};

vector(int contenttype) content_color =
{
	switch (contenttype)
	{
		case TC_EMPTY: return '0 0 0';
		case TC_SPAWN: return '0 1 0';
		case TC_EXIT: return '0 1 1';
		case TC_ENEMY1: return '1 0 0';
		case TC_ITEM1: return '1 1 0';
		default: return '1 0 1';
	}
};

enum {
	TILE_WALL, TILE_FLOOR, TILE_FLOOR2, TILE_FLOOR3,
	TILE_WALL2, TILE_WALL3
};
const float NUM_TILE_TYPES = 6;

string(int tiletype) tile_name =
{
	switch (tiletype)
	{
	case TILE_WALL: return "Wall";
	case TILE_FLOOR: return "Flr1";
	case TILE_FLOOR2: return "Flr2";
	case TILE_FLOOR3: return "Flr3";
	case TILE_WALL2: return "Wall2";
	case TILE_WALL3: return "Wall3";
	default: return "UNKN";
	}
};

vector(int tiletype) tile_color =
{
	switch (tiletype)
	{
	case TILE_WALL: return '0.1 0.2 0.3';
	case TILE_FLOOR: return '0.7 0.7 0.8';
	case TILE_FLOOR2: return '0.7 0.8 0.7';
	case TILE_FLOOR3: return '0.8 0.7 0.7';
	case TILE_WALL2: return '0.2 0.2 0.1';
	case TILE_WALL3: return '0.3 0.1 0.1';
	default: return '1 0 1';
	}	
};

struct meta_map {
	int tiles[META_W * META_H];
	int flags[META_W * META_H];
};

int(int dir) opposite_dir =
{
	switch (dir) 
	{
		case DIR_N: return DIR_S;
		case DIR_W: return DIR_E;
		case DIR_E: return DIR_W;
		case DIR_S: return DIR_N;
		default: return -1;
	}
};

vector(int dir) dir_to_vector =
{
	switch (dir) 
	{
		case DIR_N: return [0, 1];
		case DIR_W: return [-1, 0];
		case DIR_E: return [1, 0];
		case DIR_S: return [0, -1];
		default: return [0, 0];
	}	
};

int(vector coord) map_meta_i =
{
	return coord_y * MAP_METAS_X + coord_x;
};

int(vector coord) map_tile_i =
{
	return coord_y * MAP_W + coord_x;
};

// NOTE bits go 0001 = 1 = up, 0010 = 2 = right, etc

vector(int bits) bit_to_dir =
{
	switch (bits)
	{
	case 1: return [0, 1];
	case 2: return [1, 0];
	case 4: return [0, -1];
	case 8: return [-1, 0];
	default: return [0, 0];
	}
};

int(int bits) opposite_bit =
{
	switch (bits)
	{
	case 1: return 4;
	case 2: return 8;
	case 4: return 1;
	case 8: return 2;
	default: return 0;
	}
};

int(vector pos) pos_to_meta_index =
{
	return pos_y * MAP_METAS_X + pos_x;
};

vector(int index) meta_index_to_pos =
{
	return [(float)index % (float)MAP_METAS_X, floor(index / MAP_METAS_X)];
};

int(vector pos) is_in_bounds = 
{
	return (pos_x < 0 || pos_x >= MAP_METAS_X || pos_y < 0 || pos_y >= MAP_METAS_Y) ? FALSE : TRUE;
}

// Check if it's possible to fit a specific piece in a specific position
// returns true or false

int(int * metas, vector pos, int piece) piece_fits =
{
	// printf("testing piece fits with %v, %i\n", pos, piece);
	// if the place is already occupied
	if (metas[pos_to_meta_index(pos)]) return FALSE;
	
	int failed = FALSE;
	int currentbit;
	
	for (int i = 0; i < 4; i++)
	{
		currentbit = 1i << i; // explicit 1 integer instead of 1 float
		// printf("testing direction %f\n", currentbit);
		
		// Go through all the opening directions
		vector newpos = pos + bit_to_dir(currentbit);
		// printf("testing position %v\n", newpos);
		if (piece & currentbit)
		{
			if (!is_in_bounds(newpos))
			{
				// The opening direction faces an edge
				// print("The opening direction faces an edge\n");
				failed = TRUE;
				break;
			}
		}
		if (!is_in_bounds(newpos)) continue;
		
		int facingtile = metas[pos_to_meta_index(newpos)];
		if (facingtile != 0)
		{
			// printf("facing %i, its bit this way %i, our bit that way %i\n", facingtile, facingtile & opposite_bit(currentbit), (piece & currentbit));
			// There's a tile in one of the opening directions
			if (!(facingtile & opposite_bit(currentbit)) && (piece & currentbit))
			{
				// The opposing tile does not face this way
				// print("The opposing tile does not face this way\n");
				failed = TRUE;
				break;
			}
			// There's a tile facing this way, but we dont face that way
			if ((facingtile & opposite_bit(currentbit)) && !(piece & currentbit))
			{
				// print("There's a tile facing this way, but we dont face that way\n");
				failed = TRUE;
				break;
			}
		}
	}
	return !failed;
};


int(int * metas, vector pos, int from, int try_cut_short = FALSE) random_valid_meta =
{
	int critical = from != 0;
	int choices[14];
	int currentindex = 0;
	for (int i = 1; i < 15; i++)
	{
		// printf("%v, piece here is %i, trying to cut short: %i\n", pos, metas[pos_to_meta_index(pos)], try_cut_short);
		if (!piece_fits(metas, pos, i))
			continue;
		
		// printf("trying piece %i\n", i);
		switch (i)
		{
		// DEAD ENDS
		case 1: // 0001
			if (critical && pos_y != 0) continue; // allow U shape in beginning 	
			if (try_cut_short) return i;
			break;
		case 2: // 0010
			if (critical) continue;
			if (try_cut_short) return i;
			break;
		case 4: // 0100
			if (critical) continue;
			if (try_cut_short) return i;
			break;
		case 8: // 1000
			if (critical) continue;
			if (try_cut_short) return i;
			break;
		
		// CORNERS
		case 3: // 0011
			break;
		case 6: // 0110
			if (critical && from != DIR_S) continue;
			break;
		case 12: // 1100
			if (critical && from != DIR_S) continue;
			break;
		case 9: // 1001
			break;
		
		// STRAIGHTS
		case 5: // 0101
			break;
		case 10: // 1010
			break;
		
		// T-JUNCTIONS
		case 7: // 0111
			if (critical && from == DIR_S) continue;
			break;
		case 14: // 1110
			if (critical && from == DIR_N) continue;
			break;
		case 13: // 1101
			if (critical && from == DIR_S) continue;
			break;
		case 11: // 1011
			if (critical) continue;
			break;
		default:
			break;
		}
		// printf("Valid %i\n", i);
		choices[currentindex] = i;
		currentindex++;
	}
	
	if (currentindex == 0) return 0;
	return choices[floor(random() * currentindex)];
};

int(int * metas, vector pos, int dir) is_valid_direction =
{
	int currentpiece = metas[pos_to_meta_index(pos)];
	vector newpos = pos + dir_to_vector(dir);
	
	if (!(dir & currentpiece)) return FALSE; // not facing that way
	if (!is_in_bounds(newpos)) return FALSE; // out of bounds there
	
	int facingpiece = metas[pos_to_meta_index(newpos)];
	
	if (facingpiece) return FALSE;
	
	return TRUE;
};

int(int * metas, vector pos, int critical) random_new_meta_direction =
{
	int valid_directions[4];
	int currentindex = 0;
	int currentpiece = metas[pos_to_meta_index(pos)];
	for (int dir = 1; dir <= 8; dir *= 2)
	{
		if (critical && dir == DIR_S) continue;
		if (is_valid_direction(metas, pos, dir))
		{
			valid_directions[currentindex] = dir;
			currentindex += 1;
		}
	}
	
	if (currentindex == 0) return 0;
	return valid_directions[floor(random() * currentindex)];
};

int(int * metas, vector pos) is_untied =
{
	int currentpiece = metas[pos_to_meta_index(pos)];
	if (currentpiece > 0) return FALSE;
	
	int untied = FALSE;
	for (int dir = 1; dir <= 8; dir *= 2)
	{
		vector newpos = pos + bit_to_dir(dir);
		if (!is_in_bounds(newpos)) continue;
		int facingtile = metas[pos_to_meta_index(newpos)];
		if (!facingtile) continue;
		if (facingtile & opposite_bit(dir)) untied = TRUE;
	}
	return untied;
};

string(int bits) bits_to_imgname =
{
	return strcat(bits & DIR_N ? "1" : "0", bits & DIR_E ? "1" : "0", bits & DIR_S ? "1" : "0", bits & DIR_W ? "1" : "0");
}; 


void(meta_map * metamap) clear_map =
{
	int asd = 1;
	for (int i = 0; i < MAP_METAS_X * MAP_METAS_Y; i++) 
	{
		metamap->tiles[i] = 0;
		metamap->flags[i] = 0;
	}
};


int(int * metas, __inout vector startpos, __inout vector endpos) generate_critical_path =
{
	// 1. pick a starting location on bottom row, entrance direction = bottom
	vector pos = [floor(random() * MAP_METAS_X), 0];
	startpos = pos;
	int from_direction = DIR_S;

	// 2. randomly pick a tile that fits the entrance direction
	int meta_index = random_valid_meta(metas, pos, from_direction);
	int newdir;
	
	int length = 0;
	int count = 0;
	while (meta_index != 0)
	{
		//printf("meta index: %i, pos: %v\n", meta_index, pos);
		length += 1;
		metas[pos_to_meta_index(pos)] = meta_index;
		newdir = random_new_meta_direction(metas, pos, TRUE);
		pos = pos + dir_to_vector(newdir);
		//printf("new meta pos = %v\n", pos);
		if (!is_in_bounds(pos)) break;
		
		meta_index = random_valid_meta(metas, pos, opposite_dir(newdir));
		if (!meta_index) 
		{
			meta_index = random_valid_meta(metas, pos, 0);
			if (meta_index)
			{
				length += 1;
				metas[pos_to_meta_index(pos)] = meta_index;
			}
			break;
		}
		count++;
		if (count > 16)
		{
			//print("too many pieces\n");
			break;
		}
	}
	endpos = pos;
	return length;
};

void(meta_map * metamap) generate_map = 
{
	int * metas = &(metamap->tiles);
	int runaway = 0;
	int numuntied = 0;
	vector startpos, endpos;
	int pathlength = generate_critical_path(metas, startpos, endpos);
	while (pathlength < 12 || numuntied < 4)
	{
		clear_map(metamap);
		pathlength = generate_critical_path(metas, startpos, endpos);
		numuntied = 0;
		for (int i = 0; i < MAP_METAS_X * MAP_METAS_Y; i++)
		{
			if (is_untied(metas, meta_index_to_pos(i))) numuntied++;
		}
		runaway++;
		if (runaway > 16) break;
	}
	
	metamap->flags[pos_to_meta_index(startpos)] = 1;
	metamap->flags[pos_to_meta_index(endpos)] = 2;
	
	int untied_spots_filled = 0;
	while (TRUE)
	{
		int untied_indices[16];
		int untied_spots = 0;
		for (int i = 0; i < MAP_METAS_X * MAP_METAS_Y; i++)
		{
			if (is_untied(metas, meta_index_to_pos(i)))
			{
				untied_indices[untied_spots] = i;
				untied_spots++;
				// printf("untied spot at %v\n", meta_index_to_pos(i));
			}
		}
		if (untied_spots == 0) break;
		
		for (int u = 0; u < untied_spots; u++)
		{
			int meta = random_valid_meta(metas, meta_index_to_pos(untied_indices[u]), 0, untied_spots_filled > 0);
			if (meta)
			{
				metas[untied_indices[u]] = meta;
				untied_spots_filled += 1;
				// printf("spots tied: %i\n", untied_spots_filled);
			}
		}
	}
	
	/*
	for (int i = 0; i < MAP_METAS_X * MAP_METAS_Y; i++)
	{
		printf("%i/", metas[i]);
	}
	print("\n");
	*/
	
	// 3. go to where current tile lets us go (random pick of multiple options)
	// go to 2. until at the top
};

// int metamap[MAP_METAS_X * MAP_METAS_Y];

void(meta_map * metamap) init_map =
{
	clear_map(metamap);
	generate_map(metamap);
};

struct metatile {
	int flags;
	int tiles[META_W * META_H];
	int content[META_W * META_H];
	int contentrot[META_W * META_H];
};

const int MAX_META_VARIATIONS = 16;
struct meta_category {
	int shape;
	int num_entries;
	metatile variations[MAX_META_VARIATIONS];
};

const int NUM_CATEGORIES = 14;
struct tile_set {
	string name;
	int style;
	meta_category categories[NUM_CATEGORIES];
};

tile_set * () new_tile_set =
{
	return (tile_set*)memalloc(sizeof(tile_set));
};

string(string set_name) filename_for_set =
{
	return strcat("sets/", set_name, ".dat");
};

int file_version = 1;
void(tile_set * tileset) write_tile_set_to_file =
{
	float file = fopen(filename_for_set(tileset->name), FILE_WRITE);
	fputs(file, ftos(file_version), "\n");
	fputs(file, ftos(tileset->style), "\n");
	
	for (int cat_i = 0; cat_i < NUM_CATEGORIES; cat_i++)
	{
		meta_category * category = &(tileset->categories[cat_i]);
		fputs(file, ftos(cat_i + 1), "\n");
		fputs(file, ftos(category->num_entries), "\n");
		
		for (int var_i = 0; var_i < category->num_entries; var_i++)
		{
			metatile * meta = &(category->variations[var_i]);
			fputs(file, ftos(meta->flags), "\n");
			
			for (int tile_i = 0; tile_i < META_W * META_H; tile_i++)
			{
				fputs(file, ftos(meta->tiles[tile_i]), ",");
				fputs(file, ftos(meta->content[tile_i]), ",");
				// fputs(file, ftos(meta->contentrot[tile_i]), ",");
			}
			fputs(file, "\n");
		}
	}
	fclose(file);
};

int(float filehandle) file_read_int =
{
	return stof(fgets(filehandle));
};

float(string set_name, tile_set * tileset) read_tile_set =
{
	float file = fopen(filename_for_set(set_name), FILE_READ);
	if (file < 0)
	{
		printf("No tileset \"%s\" found!\n", set_name);
		return FALSE;
	}
	int version = file_read_int(file);
	if (version != file_version)
	{
		printf("Wrong version set file, expected %i, got %i\n", file_version, version);
		return FALSE;
	}
	tileset->name = set_name;
	tileset->style = file_read_int(file);
	
	for (int cat_i = 0; cat_i < NUM_CATEGORIES; cat_i++)
	{
		meta_category * category = &(tileset->categories[cat_i]);
		category->shape = file_read_int(file);
		category->num_entries = file_read_int(file);
		
		for (int var_i = 0; var_i < category->num_entries; var_i++)
		{
			metatile * meta = &(category->variations[var_i]);
			meta->flags = file_read_int(file);
			
			// TODO: read content and content rotation too
			string line = fgets(file);
			float argc = tokenizebyseparator(line, ",");
			if (argc != (META_W * META_H) * 2)
			{
				printf("Wrong amount of tiles! Expected %i, got %f\n", (META_W * META_H) * 2i, argc);
				break;
			}
			for (int tile_i = 0; tile_i < META_W * META_H; tile_i++)
			{
				meta->tiles[tile_i] = stof(argv(tile_i*2));
				meta->content[tile_i] = stof(argv(tile_i*2 + 1));
			}
		}
	}
	fclose(file);
	return TRUE;
};

const int MAP_W = META_W * MAP_METAS_X;
const int MAP_H = META_H * MAP_METAS_Y;

struct tile_map {
	int tiles[MAP_W * MAP_H];
	int content[MAP_W * MAP_H];
};

int(vector pos) map_pos_to_index =
{
	return pos_y * MAP_W + pos_x;
};

vector(int index) index_to_map_pos =
{
	return [(float)index % (float)MAP_W, floor((float)index / (float)MAP_W)];
};

int(vector pos) is_map_pos_in_bounds =
{
	return (pos_x < 0 || pos_x >= MAP_W || pos_y < 0 || pos_y >= MAP_H) ? FALSE : TRUE;
}


void(tile_map * map, metatile * meta, vector pos) fill_meta =
{
	vector start_pos = [pos_x * META_W, pos_y * META_H];
	vector realpos;
	for (int y = 0; y < META_H; y++)
	{
		for (int x = 0; x < META_W; x++)
		{
			// meta tiles start from top-left corner
			// map starts from bottom-left corner
			// TODO: make meta editor already display it flipped to keep them sane
			realpos = start_pos + [x, META_H - y - 1];
			//if (random() > 0.2)
			// Make sure borders are closed even if meta says they're open
			if (realpos_x == 0 || realpos_x == MAP_W - 1 || realpos_y == 0 || realpos_y == MAP_H - 1)
			{
				map->tiles[map_pos_to_index(realpos)] = TILE_WALL;
				map->content[map_pos_to_index(realpos)] = TC_EMPTY;
			}
			else
			{
				map->tiles[map_pos_to_index(realpos)] = meta->tiles[y * META_H + x];
				map->content[map_pos_to_index(realpos)] = meta->content[y * META_H + x];
			}
			//else
			//	map->tiles[map_pos_to_index(realpos)] = rint(random());
		}
	}
};

void(tile_map * map, vector pos) clear_meta =
{
	vector start_pos = [pos_x * META_W, pos_y * META_H];
	vector realpos;
	for (int y = 0; y < META_H; y++)
	{
		for (int x = 0; x < META_W; x++)
		{
			realpos = start_pos + [x, META_H - y - 1];
			map->tiles[map_pos_to_index(realpos)] = TILE_WALL;
			map->content[map_pos_to_index(realpos)] = TC_EMPTY;
		}
	}
};

void(tile_map * map, meta_map * metamap, tile_set * tileset) fill_map =
{
	int * metas = &(metamap->tiles);
	for (int y = 0; y < MAP_METAS_Y; y++)
	{
		for (int x = 0; x < MAP_METAS_X; x++)
		{
			// printf("index: %i\n", pos_to_meta_index([x, y]));
			int currentmeta = metas[pos_to_meta_index([x, y])];
			// printf("currentmeta: %i\n", currentmeta);
			if (currentmeta > 0)
			{
				meta_category * cat = &(tileset->categories[currentmeta - 1]);
				int metaindex = floor(random() * cat->num_entries);
				metatile * meta = &(cat->variations[metaindex]);
				fill_meta(map, meta, [x, y]);
			}
			else
			{
				clear_meta(map, [x, y]);
			}
		}
	}
};

void() sh_generation_tests =
{
	begin_test("sh_generation.qc");

	// float_expect(map_meta_i([2, 3]), 14);
	
	// vector_expect(meta_index_to_pos(14), [2, 3]);
	
	int metas[MAP_METAS_X * MAP_METAS_Y] = {
		0, 0, 0, 0,
		0, 5, 0, 5,
		5, 0, 5, 0,
		0, 10, 0, 10
	};
	vector pos = [2, 1]; // between 5's
	
	expect_true(piece_fits(metas, pos, 5));		// straight up/down
	expect_false(piece_fits(metas, pos, 10));  	// straight left/right
	pos = [2, 3];
	expect_true(piece_fits(metas, pos, 14));
	expect_false(piece_fits(metas, pos, 11));
	pos = [0, 3];
	expect_true(piece_fits(metas, pos, 6));
	expect_false(piece_fits(metas, pos, 1));
	expect_false(piece_fits(metas, pos, 14));
	pos = [1, 0];
	expect_false(piece_fits(metas, pos, 10));
	pos = [0, 0];
	expect_true(piece_fits(metas, pos, 1));
	
	expect_true(is_valid_direction(metas, [1, 1], DIR_N));
	expect_true(is_valid_direction(metas, [0, 2], DIR_N));
	
	int metas2[MAP_METAS_X * MAP_METAS_Y] = {
		0, 0, 0, 0,
		0, 0, 0, 0,
		3, 13, 0, 0,
		6, 0, 0, 0
	};
	pos = [1, 3];
	expect_false(piece_fits(metas2, pos, 6)); // fails
	pos = [3, 0];
	expect_true(piece_fits(metas, pos, 1));
	expect_false(is_valid_direction(metas, [0, 2], DIR_W));
	
	string_expect(bits_to_imgname(1), "1000");
	string_expect(bits_to_imgname(13), "1011");
	
	end_test();
};

