
tile_set * example_set;

tile_map example_map;

meta_map example_meta;

// in m_menu.qc
// int metamap[MAP_METAS_X * MAP_METAS_Y];

void() init_m_generation =
{
	example_set = new_tile_set();
};

vector(vector size, vector pos) drawpos =
{
	return [pos_x * size_x, (MAP_METAS_Y - 1 - pos_y) * size_y];
};

void() draw_map =
{
	vector size = [32, 32];
	int index;
	for (float y = 0; y < MAP_METAS_Y; y++)
	{
		for (float x = 0; x < MAP_METAS_X; x++)
		{
			index = pos_to_meta_index([x, y]);
			string imgname = strcat("textures/metatiles/", bits_to_imgname(example_meta.tiles[index]), ".png");
			// imgname = "textures/metatiles/0001.png";
			sui_pic(drawpos(size, [x, y]), size, imgname, [1, 1, 1], 1, 0);
			
			if (example_meta.flags[index] & 1)
			{
				sui_fill(drawpos(size, [x, y]), [16, 16], '0 1 0', 1, 0);
			}
			if (example_meta.flags[index] & 2)
			{
				sui_fill(drawpos(size, [x, y]), [16, 16], '1 0 0', 1, 0);
			}
		}
	}
};

void() metamap_menu =
{
	vector pos = [0, 0];
	vector size = [360, 280];
	
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 4], FS_NORMAL, "Meta Map", MENU_TEXT_1, 1, 0);
	
	float xpos = 0;
	float ypos = 32;
	sui_text([xpos, ypos], FS_NORMAL, "Preview of meta map", MENU_TEXT_1, 1, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	draw_map();
	
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("hlp_back", [-8, -8], [80, 20], "Back") ? current_menu = MENU_MAIN : 0;
	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	my_button("reset_map", [8, -8], [80, 20], "Reset") ? init_map(&example_meta) : 0;

	sui_pop_frame();	
};


void() print_full_map =
{
	fill_map(&example_map, &example_meta, example_set);
	
	for (int y = MAP_H - 1; y >= 0; y--)
	{
		for (int x = 0; x < MAP_W; x++)
		{
			printf("%s", ftos(example_map.tiles[map_pos_to_index([x, y])]));
		}
		print("\n");
	}
};

int paint_mode; // 0 = tile, 1 = content;
var int brush_content = 0;
var int brush_tile = 0;

void(metatile * currenttile) draw_tileeditor =
{
	vector size = [16, 16];
	vector col;
	for (int y = 0; y < META_H; y++)
	{
		for (int x = 0; x < META_W; x++)
		{
			string nm = sprintf("tl%i%i", x, y);
			sui_action_element([x, y] * size_x, size, nm, sui_noop);
			col = sui_is_hovered(nm) ? '0.35 0.25 0.25' : '0 0 0';
			sui_fill([x, y] * size_x, size - [1, 1], col + tile_color(currenttile->tiles[y*META_W + x]), 1, 0);
			
			if (currenttile->content[y*META_W + x])
				sui_fill([x, y] * size_x + [4, 4], size - [9, 9], col + content_color(currenttile->content[y*META_W + x]), 1, 0);
				
			if (paint_mode == 0)
				(sui_is_hovered(nm) && sui_click_held()) ? currenttile->tiles[y*META_W + x] = brush_tile : 0;
			else
				(sui_is_hovered(nm) && sui_click_held()) ? currenttile->content[y*META_W + x] = brush_content : 0;
		}
	}
};

tile_set * current_set;
vector categories_offset;
vector variations_offset;
int selected_category;
int selected_variation;
string set_name;
float set_name_cursor;

void() tileeditor_menu =
{
	vector pos = [0, 0];
	vector size = [360, 280];
	
	current_set = example_set;
	
	sui_push_frame(pos, size);
	
	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 4], FS_NORMAL, "Tile Editor", MENU_TEXT_1, 1, 0);
	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	// pick category 
	vector listitem_pos = '0 0 0';
	string elemid;
	vector itemsize = [20, 20];
	float xpos = 8;
	float ypos = 24;
	sui_fill([xpos, ypos], [itemsize_x + 4, 20 * 8], '0 0 0', 0.25, 0);
	sui_list_view_begin("te_categories", [8, 24], [itemsize_x + 4, 20 * 8], [itemsize_x + 4, itemsize_y], 14, categories_offset, [0, 4]);
	for (float index = sui_list_item(listitem_pos); index > -1; index = sui_list_item(listitem_pos))
	{
		string texture = strcat("textures/metatiles/", bits_to_imgname(index + 1), ".png");
		elemid = strcat("cat", ftos(index));
		sui_push_frame(listitem_pos, itemsize);
		sui_pic([2, 2], itemsize - [4, 4], texture, '1 1 1', 1, 0);
		sui_action_element([0, 0], itemsize, elemid, sui_noop);
		sui_is_hovered(elemid) ? sui_fill([0, 0], itemsize, '1 1 1', 0.1, 0) : 0;
		sui_is_clicked(elemid) ? (selected_category = index && selected_variation = 0) : 0;
		
		selected_category == index ? sui_fill([0, 0], itemsize, '1 0 0', 0.25, 1) : 0;
		sui_pop_frame();
	}
	sui_list_view_end();
	
	xpos += 32;
	
	// pick variation
	itemsize = [20, 16];
	sui_fill([xpos, ypos], [20, 20 * 8], '0 0 0', 0.25, 0);
	
	int numvariations = current_set->categories[selected_category]->num_entries;
	
	sui_list_view_begin("te_variations", [32 + 8, 24], [itemsize_x, 20 * 8], itemsize, numvariations, variations_offset, [0, 4]);
	for (float index = sui_list_item(listitem_pos); index > -1; index = sui_list_item(listitem_pos))
	{
		elemid = strcat("var", ftos(index));
		sui_push_frame(listitem_pos, size);
		sui_text([2, 4], [8, 8], ftos(index), '1 1 1', 1, 0);
		sui_action_element([0, 0], itemsize, elemid, sui_noop);
		sui_is_hovered(elemid) ? sui_fill([0, 0], itemsize, '1 1 1', 0.1, 0) : 0;
		sui_is_clicked(elemid) ? selected_variation = index : 0;
		
		selected_variation == index ? sui_fill([0, 0], itemsize, '1 0 0', 0.25, 1) : 0;
		sui_pop_frame();
	}
	sui_list_view_end();
	
	float var_added = my_button("te_add_variation", [xpos, ypos + 20 * 8], itemsize, "+");
	float var_removed = my_button("te_remove_variation", [xpos, ypos + 20 * 8 + itemsize_y], itemsize, "-");
	if (var_added)
	{
		current_set->categories[selected_category]->num_entries += 1;
		if (current_set->categories[selected_category]->num_entries > MAX_META_VARIATIONS)
			current_set->categories[selected_category]->num_entries = MAX_META_VARIATIONS;
		
		selected_variation = current_set->categories[selected_category]->num_entries - 1;
	}
	if (var_removed)
	{
		current_set->categories[selected_category]->num_entries -= 1;
		if (current_set->categories[selected_category]->num_entries < 1)
			current_set->categories[selected_category]->num_entries = 1;
			
		if (selected_variation >= current_set->categories[selected_category]->num_entries)
		{
			selected_variation = current_set->categories[selected_category]->num_entries - 1;
		}
	}
	
	xpos += 32;
	
	// PLAN FOR THE BRUSH SELECTOR
	// 2 modes: TILE and CONTENT, switch by using buttons for both
	// Change the stuff below the image to have a button for each tile when in tile mode
	// and for each content when in content mode.
	// Highlight selected mode and selected tile/content.
	
	sui_push_frame([xpos, ypos], [128, 128]);
	if (current_set)
	{
		draw_tileeditor(&(current_set->categories[selected_category].variations[selected_variation]));
	}
	sui_pop_frame();
	
	xpos += 128 + 8;
	
	sui_push_frame([xpos, ypos], [160, 200]);
	xpos = 0; 
	ypos = 0;
	vector buttonsize = [64, 20];
	my_button("te_set_tile_mode", [xpos, ypos], buttonsize, "Tile") ? paint_mode = 0 : 0;
	paint_mode == 0 ? sui_fill([xpos, ypos], buttonsize, '1 1 1', 0.2, 1) : 0;
	xpos += buttonsize_x + 8;
	my_button("te_set_content_mode", [xpos, ypos], buttonsize, "Content") ? paint_mode = 1 : 0;
	paint_mode == 1 ? sui_fill([xpos, ypos], buttonsize, '1 1 1', 0.2, 1) : 0;
	
	xpos = 0;
	ypos += buttonsize_y + 8;
	
	buttonsize_x = 64 + 4;
	buttonsize_y = 16;
	
	int tile_type, content_type;
	vector button_pos;
	int row, col;
	if (paint_mode == 0)
	{
		for (row = 0; row < ceil(NUM_TILE_TYPES / 2); row++)
		{
			for (col = 0; col < 2; col++)
			{
				tile_type = row * 2 + col;
				button_pos = [xpos, ypos] + [col*buttonsize_x, row*buttonsize_y];
				if (tile_type >= NUM_TILE_TYPES) break;
				my_button(sprintf("te_tilebtn%i", tile_type), button_pos, buttonsize, tile_name(tile_type)) ? brush_tile = tile_type : 0;
				brush_tile == tile_type ? sui_fill(button_pos, buttonsize, '1 1 1', 0.2, 1) : 0;
				sui_fill(button_pos + [2, 2], [8, buttonsize_y - 4], tile_color(tile_type), 1, 0);
			}
		}
	}
	else
	{
		for (row = 0; row < ceil(NUM_CONTENT_TYPES / 2); row++)
		{
			for (col = 0; col < 2; col++)
			{
				content_type = row * 2 + col;
				button_pos = [xpos, ypos] + [col*buttonsize_x, row*buttonsize_y];
				if (content_type >= NUM_CONTENT_TYPES) break;
				my_button(sprintf("te_contbtn%i", content_type), button_pos, buttonsize, content_name(content_type)) ? brush_content = content_type : 0;
				brush_content == content_type ? sui_fill(button_pos, buttonsize, '1 1 1', 0.2, 1) : 0;
				sui_fill(button_pos + [2, 2], [8, buttonsize_y - 4], content_color(content_type), 1, 0);
			}
		}
	}
	sui_pop_frame();
	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	my_button("te_save", [8, -8], [80, 20], "Save") ? write_tile_set_to_file(current_set) : 0;
	text_input_control("te_save_input", [8, -20 - 16], FS_MED_x * [9, 1], 12, set_name, set_name_cursor);
	current_set->name = set_name;
	
	my_button("te_load", [8 + 80 + 8, -8], [80, 20], "Load") ? read_tile_set(set_name, current_set) : 0;
	current_set->name = set_name;
	
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("te_back", [-8, -8], [80, 20], "Back") ? current_menu = MENU_MAIN : 0;
	
	my_button("te_testmap", [-8, -8 - 20 - 8], [80, 20], "Test") ? print_full_map() : 0;
	
	
	sui_pop_frame();
};
