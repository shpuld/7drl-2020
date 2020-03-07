vector MENU_BG = '0.1 0.1 0.1';
vector MENU_BG_DARK = '0.05 0.05 0.05';
vector MENU_BORDER = '0.15 0.15 0.15';
vector MENU_BUTTON = '0.15 0.15 0.15';
vector MENU_BUTTON_BORDER = '0.2 0.2 0.2';
vector MENU_TEXT_1 = '1 1 1';
vector MENU_TEXT_2 = '0.7 0.75 0.75';
vector MENU_HIGHLIGHT = '1 1 1';
vector MENU_DARKEN = '1 1 1';

vector FS_NORMAL = '8 8 0';
vector FS_MED = '12 12 0';
vector FS_BIG = '16 16 0';

void() input_tester =
{
	float char = 0;
	float scan = 0;
	string printme = "";
	while (sui_get_input(char, scan))
	{
		printme = strcat(printme, chr2str(char));
	}
	// if (printme != "") printf("INPUT: %s\n", printme); 
};

void(string id, vector pos, vector size, float maxlen, __inout string text, __inout float cursor) text_input_control =
{
	vector textsize = [size_y - 4, size_y - 4];
	sui_push_frame(pos, size);
	vector basecolor = sui_is_hovered(id) ? MENU_BG_DARK + MENU_HIGHLIGHT * 0.08 : MENU_BG_DARK; 
	sui_fill([0, 0], size, basecolor, 0.6, 0);

	sui_text_input(id, [0, 0], size, text, cursor);
	
	if (strlen(text) > maxlen) 
	{
		text = substring(text, 0, maxlen);
		if (cursor > maxlen) cursor = maxlen;
	}
	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	float focused = sui_is_last_clicked(id);
	// Under focus
	focused ? sui_border_box([0, 0], size, 1, MENU_BORDER, 0.6, 0) : 0;	
	
	sui_push_frame([2, 0], [size_x - 4, size_y - 4]);
	
	float cursorx;
	if (stringwidth(text, 1, textsize) > size_x - 4)
	{
		sui_clip_to_frame();
		cursorx = 0;
		sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
		sui_text([0, 0], textsize, text, MENU_TEXT_1, 1, 0);
	}
	else
	{
		cursorx = stringwidth(substring(text, 0, cursor), 1, textsize);
		sui_text([0, 0], textsize, text, MENU_TEXT_1, 1, 0);
	}
	if (focused) 
	{
		sui_fill([cursorx, 0], [2, textsize_y], MENU_TEXT_1, fabs(sin(time * 4)), 0);
	}
	
	sui_reset_clip();
	sui_pop_frame();
	
	sui_pop_frame();
};

float(string id, vector pos, vector size, string text) my_button =
{
	sui_push_frame(pos, size);
	vector basecolor = sui_is_hovered(id) ? MENU_BUTTON + MENU_HIGHLIGHT * 0.1 : MENU_BUTTON; 
	basecolor = sui_is_held(id) ? MENU_BUTTON - MENU_DARKEN * 0.1 : basecolor;
	sui_fill([0, 0], size, basecolor, 0.6, 0);
	sui_border_box([0, 0], size, 1, MENU_BUTTON_BORDER, 0.4, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_text([0, 0], FS_NORMAL, text, MENU_TEXT_1, 1, 0);	
	sui_action_element([0, 0], size, id, sui_noop);
	sui_pop_frame();
	
	return sui_is_clicked(id);
};


void(string id, vector pos, vector size, vector minmaxsteps, __inout float value) my_slider =
{
	sui_push_frame(pos, size);
	
	value = sui_slidercontrol(id, [0, 0], size, minmaxsteps, value, sui_slider_noop);
	float maxval = minmaxsteps[1];
	float sliderx = (value / maxval) * size_x;
	sui_fill([0, size_y * 0.25], [size_x, size_y * 0.5], MENU_BG_DARK, 1.0, 0);
	
	float is_active = sui_is_held(id) || (sui_is_hovered(id) && !sui_click_held());
	vector slider_ctrl_color = is_active ? MENU_BUTTON + MENU_HIGHLIGHT * 0.1 : MENU_BUTTON;
	sui_fill([sliderx - 2, 0], [4, size_y], slider_ctrl_color, 1.0, 0);
	
	sui_pop_frame();
};

void(vector pos, vector size, vector minmaxsteps, string cvar_s, string name, string format) cvar_slider =
{
	float current = cvar(cvar_s);
	float old = current;
	sui_push_frame(pos, [size_x, size_y * 0.5 - 4]);
	sui_text([0, 0], FS_NORMAL, name, MENU_TEXT_1, 1, 0);
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text([0, 0], FS_NORMAL, sprintf(format, current), MENU_TEXT_1, 1, 0);
	sui_pop_frame();
	my_slider(strcat(cvar_s, "sldr"), [pos_x, pos_y + size_y * 0.5], [size_x, size_y * 0.5], minmaxsteps, current);
	if (current != old) cvar_set(cvar_s, ftos(current));
};

struct name_command {
	string name;
	string command;
};

name_command bindlist[] = 
{
	{ "Up", "+forward" },
	{ "Down", "+back" },
	{ "Left", "+moveleft" },
	{ "Right", "+moveright" },
	{ "Shoot", "+attack" },
	{ "Use", "+button3" },
	{ "Reload", "reload" },
	{ "Melee", "+jump" },
	{ "Inventory", "toggleinventory" },
	{ "Swap", "swap" },
	{ "Drop", "dropgun" }
};

void(string id, vector pos, vector size, string name, string command) bind_button =
{
	sui_push_frame(pos, size);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	string key = sui_binder(id, [0, 0], size, name, command);
	if (sui_is_hovered(id)) sui_fill([0, 0], size, MENU_HIGHLIGHT, 0.1, 0);
	sui_text([6, 0], FS_NORMAL, name, MENU_TEXT_1, 1, 0);
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
	sui_text([-6, 0], FS_NORMAL, key, MENU_TEXT_1, 1, 0);
	
	sui_pop_frame();
};


void(string id, vector pos, vector size, __inout vector scrollofs) bind_list =
{
	sui_fill(pos, size, MENU_BG_DARK, 0.75, 0);
	sui_list_view_begin(strcat(id, "scrl"), pos, size, [size_x - 6, 24], bindlist.length, scrollofs, [0, 6]);
	vector listitem_pos = '0 0 0';
	for (float index = sui_list_item(listitem_pos); index > -1; index = sui_list_item(listitem_pos))
	{
		sui_push_frame(listitem_pos, [size_x - 6, 24]);
		bind_button(strcat(id, ftos(index)), [0, 0], [size_x - 6, 24], bindlist[index].name, bindlist[index].command);
		sui_pop_frame();
	}
	sui_list_view_end();	
};

string current_tutorial;
float current_menu;
const float MENU_MAIN = 1;
const float MENU_SETTINGS = 2;
const float MENU_HELP = 3;
const float MENU_TILEEDITOR = 4;
const float MENU_METAMAP = 5;
const float MENU_TUTORIAL = 6;

vector binds_scroll;
void() settings_menu =
{
	vector pos = [0, 0];
	vector size = [360, 280];
	
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 4], FS_NORMAL, "Settings", MENU_TEXT_1, 1, 0);

	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	
	float xpos = 8;
	float ypos = 32;
	float width = size_x * 0.5 - 8 * 2;
	sui_text([xpos, ypos], FS_NORMAL, "Controls", MENU_TEXT_1, 1, 0);
	ypos += 16;
	bind_list("bindlist", [xpos, ypos], [width, 160], binds_scroll);
	ypos += 160 + 8;

	cvar_slider([xpos, ypos], [width, 32], [0.1, 10], "sensitivity", "Sensitivity", "%.2f");
	ypos += 32;

	ypos = 32;
	xpos = 8 + width + 8 + 8;
	
	cvar_slider([xpos, ypos], [width, 32], [0, 1], "volume", "Volume", "%.2f");
	ypos += 32 + 4;
	cvar_slider([xpos, ypos], [width, 32], [0, 1], "musicvolume", "Music Volume", "%.2f");
	ypos += 32 + 4 + 8;
	
	sui_text([xpos, ypos], FS_NORMAL, "Video", MENU_TEXT_1, 1, 0);
	ypos += 16;
	my_button("fs_btn", [xpos, ypos], [width, 20], "Fullscreen") ? localcmd("vid_fullscreen 2; vid_restart\n") : 0;
	ypos += 24;
	my_button("wn_btn", [xpos, ypos], [width, 20], "Windowed") ? localcmd("vid_fullscreen 0; vid_width 1024; vid_height 768; vid_restart\n") : 0;
	ypos += 24;
	sui_text([xpos, ypos], FS_NORMAL, "Window can be resized.", MENU_TEXT_1, 0.8, 0);
	ypos += 16;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("stg_back", [-8, -8], [80, 20], "Back") ? current_menu = MENU_MAIN : 0;
	
	sui_pop_frame();
};

void() metamap_menu;

void() help_menu =
{
	vector pos = [0, 0];
	vector size = [360, 280];
	
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 4], FS_NORMAL, "Help", MENU_TEXT_1, 1, 0);
	
	float xpos = 0;
	float ypos = 32;
	sui_text([xpos, ypos], FS_NORMAL, "Bunch of Help and About", MENU_TEXT_1, 1, 0);
	
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("hlp_back", [-8, -8], [80, 20], "Back") ? current_menu = MENU_MAIN : 0;

	sui_pop_frame();	
};

void() main_menu =
{
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	float y = 64 + floor(sin(time * 0.5) * 8 * 16)/16;
	float a = 0.75 + sin(time * 0.5) * 0.25;
	sui_text([0, y], FS_BIG, "DESCENDANTS", [1, 1, 1], a, 0);
	y += FS_BIG_y;
	sui_text([0, y], FS_MED, "of the", [1, 1, 1], a * 0.6, 0);
	y += FS_MED_y;
	sui_text([0, y], FS_BIG, "HELLBEAST", [1, 1, 1], a, 0);
	
	y = 144;
	sui_text([0, y], FS_NORMAL, "7DRL-2020 game by", [1, 1, 1], 0.6, 0);
	y += FS_NORMAL_y;
	sui_text([0, y], FS_NORMAL, "shp and Leonovsky75", [1, 1, 1], 0.6, 0);
	
	vector pos = [0, -24];
	vector size = [120, 140];
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
	sui_push_frame(pos, size);
	
	sui_fill([0, 0], size, MENU_BG, 0.3, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.2, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	
	my_button("mm_start", [0, 8], [size_x - 16, 20], "Start Game") ? localcmd("map bigbox\n") : 0;
	my_button("mm_settings", [0, 8 + 24], [size_x - 16, 20], "Settings") ? current_menu = MENU_SETTINGS : 0;
	if (my_button("mm_help", [0, 8 + 48], [size_x - 16, 20], "Help"))
	{
		current_tutorial = "start";
		current_menu = MENU_TUTORIAL;
	}
	// my_button("mm_tileeditor", [0, 8 + 48 + 24], [size_x - 16, 20], "Tile Editor") ? current_menu = MENU_TILEEDITOR : 0;
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
	my_button("mm_quit", [0, -8], [size_x - 16, 20], "Quit") ? localcmd("quit\n") : 0;
	sui_pop_frame();	
};

struct tutorial {
	string map;
	string title;
	string line1;
	string line2;
	string line3;
	string line4;
	string line5;
	string line6;
	string line7;
};

tutorial tutorials[] = {
	{ "start", "Welcome Trooper", "We've lost contact with", "an arctic research facility.", "We're sending you to investigate", "and to clean up the mess.", "Get to the bottom of it.", "", "Good luck." },
	{ "cont", "How to play", "Use WSAD and mouse to", "move, aim and shoot.", "Use [SPACE] to melee attack", "and [R] to reload.", "Use [SCROLL WHEEL] to switch", "your equipped weapon.", "All keys can be changed in settings." },
	{ "inv", "Inventory", "You'll find equipment to help", "you on your journey.", "Use [TAB] to open the inventory", "to see your equipment.", "Use [G] to quickly drop your", "current weapon." },
	{ "crate", "Loot", "Items are found in these green crates", "all over the facility.", "Use [SPACE] to punch the crate open", "to get your first real weapon." }
};


void() m_close;
void() tutorial_menu =
{
	string currentmap = current_tutorial;
	int i;
	for (i = 0; i < tutorials.length; i++)
	{
		if (tutorials[i].map == currentmap) break;
	}
	if (i >= tutorials.length)
	{
		current_menu = MENU_MAIN;
		m_close();
		return;
	}
	
	vector pos = [0, 0];
	vector size = [320, 160];
	
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 4], FS_MED, tutorials[i].title, MENU_TEXT_1, 1, 0);
	
	float xpos = 0;
	float ypos = 32;
	sui_text([xpos, ypos], FS_NORMAL, tutorials[i].line1, MENU_TEXT_1, 1, 0);
	ypos += 8;
	sui_text([xpos, ypos], FS_NORMAL, tutorials[i].line2, MENU_TEXT_1, 1, 0);
	ypos += 16;
	sui_text([xpos, ypos], FS_NORMAL, tutorials[i].line3, MENU_TEXT_1, 1, 0);
	ypos += 8;
	sui_text([xpos, ypos], FS_NORMAL, tutorials[i].line4, MENU_TEXT_1, 1, 0);
	ypos += 16;
	sui_text([xpos, ypos], FS_NORMAL, tutorials[i].line5, MENU_TEXT_1, 1, 0);
	ypos += 8;
	sui_text([xpos, ypos], FS_NORMAL, tutorials[i].line6, MENU_TEXT_1, 1, 0);
	
	ypos += 16;
	sui_text([xpos, ypos], FS_NORMAL, tutorials[i].line7, MENU_TEXT_1, 1, 0);
	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	if (my_button("tut_close", [8, -8], [80, 20], "Close"))
	{
		current_menu = MENU_MAIN;
		if (clientstate() != 1)
			m_close();
	}
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
	if (i > 0)
	{
		if (my_button("tutprev", [0, -8], [80, 20], "Prev"))
		{
			current_tutorial = tutorials[i-1].map;
		}
	}
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	if (i < tutorials.length - 1)
	{
		if (my_button("tutnext", [-8, -8], [80, 20], "Next"))
		{
			current_tutorial = tutorials[i+1].map;
		}
	}

	sui_pop_frame();	
};

void() tileeditor_menu;
void(vector size) root_menu =
{
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	
	if (clientstate() == 1)
	{
		sui_pic([0, 0], size, "textures/bg.tga", '1 1 1', 1, 0);
		sui_pic([0, 0], size * (1.5 + sin(time * 0.5) * 0.5), "textures/bg.tga", '1 1 1' * (0.5 + sin(time * 0.5) * 0.5), 1, 1);
	}
	
	sui_fill([0, 0], size, '0 0 0', 0.5, 0);
	switch (current_menu)
	{
		case MENU_MAIN: main_menu(); break;
		case MENU_SETTINGS: settings_menu(); break;
		case MENU_HELP: help_menu(); break;
		case MENU_METAMAP: metamap_menu(); break;
		case MENU_TILEEDITOR: tileeditor_menu(); break;
		case MENU_TUTORIAL: tutorial_menu(); break;
		default: break;
	}
};