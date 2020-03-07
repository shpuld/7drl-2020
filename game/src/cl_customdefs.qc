//Various globals that are used in this FTEQW example are defined here, they are not used by the engine itself

#pragma warning disable Q302
vector cursor_pos; /* Current mouse cursor position, updated in csqc_inputevent */
float g_width, g_height; /* Globals for screen width and height */

vector crosshair_pos; /* Topdown crosshair constrained inside window */
vector aim_normalized; /* from -1 to 1 on Y, X not completely normalized, affected by aspect ratio */

entity player;


//Menu stuff
float in_menu; //what menu are we in
float time_in_menu;

// for keybinding
float active_bind_index;
float menu_click_held;

const float MENU_NONE = 0;
const float MENU_MAIN = 1;
const float MENU_JOIN = 2;
const float MENU_SETTINGS = 4;
const float MENU_BUY = 8;
const float MENU_HOST = 16;
const float MENU_PREGAME = 32;
const float MENU_POSTGAME = 64;

float in_input_box;
float input_cursor;

vector campos;
vector camang;

entity localplayer;

vector() readvector =
{
	vector r = '0 0 0';
	r_x = readcoord();
	r_y = readcoord();
	r_z = readcoord();
	return r;
};


.float is_enemy;

int blocks_loaded;
int block_loading_done;

float light_pass;

float inv_item_id[INV_SIZE];
float inv_item_effect[INV_SIZE];
float inv_item_ammo[INV_SIZE];

float weapon_mags[weapon_list.length];

float ammo_bullets;
float ammo_shells;
float ammo_cells;

.float dmg;

float active_weapon;

float reload_finished;
float attack_finished;
float reloading;

float camshake;

float entertime;
float exittime;

float victorytime;



