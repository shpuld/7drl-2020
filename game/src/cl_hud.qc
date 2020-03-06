// Empty

float inventory_active;

void() draw_inventory =
{
	
	float ypos = 240;
	for (int i = 0; i < 2; i++)
	{
		if (i == active_weapon) drawfill([0, ypos], [128, 16], '1 1 1', 0.1, 1);
		drawstring([0, ypos], sprintf("%s %s", weapon_effects[inv_item_effect[i]].name, weapon_list[inv_item_id[i]].name), [8, 8], '1 1 1', 1, 0); 
		ypos += 8;
		drawstring([0, ypos], sprintf("%.0f/%.0f - %.0f", inv_item_ammo[i], max_ammo_for(i), weapon_mags[inv_item_id[i]]), [8, 8], '1 1 1', 1, 0); 
		ypos += 8;
	}
	
	float pu_item_type = getstatf(STAT_ITEM_TYPE);
	float pu_item_id = getstatf(STAT_ITEM_ID);
	float pu_item_effect = getstatf(STAT_ITEM_EFFECT);
	float pu_ammo = getstatf(STAT_SHELLS);
	float pu_mags = getstatf(STAT_NAILS);
	
	if (pu_item_type)
	{
		string strings[4];
		strings[0] = "Press USE to pick up";
		if (pu_item_type == IT_WEAPON)
		{
			strings[1] = pu_item_effect ? sprintf("%s %s", weapon_effects[pu_item_effect].name, weapon_list[pu_item_id].name) : weapon_list[pu_item_id].name;
			strings[2] = strpad(16, weapon_stats_string(pu_item_effect, 1));
			strings[3] = strpad(16, weapon_stats_string(pu_item_effect, 2));
		}
		else if (pu_item_type == IT_POWERMOD)
		{
			strings[1] = "Power Module";
			strings[2] = strpad(16, powermod_stats_string(pu_item_effect, 1));
			strings[3] = strpad(16, powermod_stats_string(pu_item_effect, 2));
		}
		else if (pu_item_type == IT_AMMO)
		{
			strings[1] = "Ammo";
			strings[2] = strings[3] = "";
		}
		else if (pu_item_type == IT_MEDKIT)
		{
			strings[1] = "Medkit";
			strings[2] = strings[3] = "";
		}
		else if (pu_item_type == IT_ARMOR)
		{
			strings[1] = sprintf("%s", armor_effects[pu_item_effect].name);
			strings[2] = sprintf("+%.0f Defense", armor_effects[pu_item_effect].level1);
			strings[3] = "";
		}

		for (int i = 0; i < strings.length; i++)
		{
			float ofs = i > 0 ? i*8 + 8 : 0;
			drawstring([g_width/2 - 4*strlen(strings[i]), g_height - 100 + ofs], strings[i], '8 8 0', '1 1 1', 0.8, 0);
		}
	}
};

void() draw_ammo =
{
	drawstring([0, g_height - 16], ftos(ammo_bullets), [16, 16], '1 1 1', 1, 0);
	drawstring([64, g_height - 16], ftos(ammo_shells), [16, 16], '1 1 1', 1, 0);
	drawstring([128, g_height - 16], ftos(ammo_cells), [16, 16], '1 1 1', 1, 0);
};

void() draw_health =
{
	string hpstr = sprintf("+%.0f/100", getstatf(STAT_HEALTH));
	drawstring([g_width - strlen(hpstr)*16, g_height - 16], hpstr, [16, 16], '1 1 1', 1, 0);
};

float old_hp;
float dmg_amount;
void() draw_dmg =
{
	float hp = getstatf(STAT_HEALTH);
	
	dmg_amount += old_hp - hp;
	
	float a = dmg_amount * 0.02;
	
	if (a > 0) drawfill([0, 0], [g_width, g_height], '1 0.1 0.1', a, 1);
	
	if (dmg_amount > 0)
		dmg_amount -= frametime * 20;
	else
		dmg_amount = 0;
	
	old_hp = hp;
};

void() draw_hud =
{
	draw_inventory();
	// draw_ammo();
	draw_health();
	draw_dmg();
};

void(vector pos, float width, int slot) draw_inventory_weapon =
{
	float ef = inv_item_effect[slot];
	weapon * wep = &(weapon_list[inv_item_id[slot]]);
	string itname = sprintf("%s %.0f/%.0f", wep->name, inv_item_ammo[slot], max_ammo_for(slot));
	string efname = ef ? strcat(weapon_effects[ef].name, " ") : "";
	
	vector size = [width, 32];
	
	sui_push_frame([pos_x, pos_y], size);
	
	sui_fill([0, 0], size, '0.3 0.3 0.3', 0.4, 0);

	if (inv_item_id[slot] == 0)
	{
		sui_text([8, 4], [8, 8], "Empty", '1 1 1', 0.8, 0);
	}
	else
	{
		float ypos = 0;
		sui_text([0, ypos], [8, 8], sprintf("%s%s", efname, itname), '1 1 1', 1, 0);
		ypos += 8;
		sui_text([8, ypos], [8, 8], weapon_stats_string(ef, 1), '1 1 1', 1, 0);
		ypos += 8;
		sui_text([8, ypos], [8, 8], weapon_stats_string(ef, 2), '1 1 1', 1, 0);
		
		string id = sprintf("%isldrop", slot);
		sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
		sui_action_element([-4, 0], [36, 24], id, sui_noop);
		sui_is_clicked(id) ? drop_item(slot) : 0;
		
		sui_fill([-4, 0], [36, 24], '0.5 0.5 0.5', 0.3 + 0.3 * sui_is_hovered(id), 0);
		sui_text([-6, 0], [8, 8], "Drop", '1 1 1', 0.7 + 0.3 * sui_is_hovered(id), 0);
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	}
	
	sui_pop_frame();
};

void(vector pos, float width, int slot) draw_inventory_other =
{
	float ef = inv_item_effect[slot];
	string itname = sprintf("%s", item_names[inv_item_id[slot]]);
	// string efname = ef ? strcat(weapon_effects[ef].name, " ") : ""; // CHANGE TO item_effects
	
	vector size = [width, 24];
	
	sui_push_frame([pos_x, pos_y], size);
	
	sui_fill([0, 0], size, '0.3 0.3 0.3', 0.4, 0);

	if (inv_item_id[slot] == 0)
	{
		sui_text([8, 8], [8, 8], "Empty", '1 1 1', 0.8, 0);
	}
	else
	{
		float ypos = 4;
		// sui_text([0, ypos], [8, 8], sprintf("%s%s", efname, itname), '1 1 1', 1, 0);
		// ypos += 8;
		if (slot == INV_SLOT_ARMOR)
		{
			sui_text([8, ypos], [8, 8], armor_effects[ef].name, '1 1 1', 1, 0);
			ypos += 8;
			sui_text([8, ypos], [8, 8], sprintf("+%.0f Defense", armor_effects[ef].level1), '1 1 1', 1, 0);
		}
		else
		{
			sui_text([8, ypos], [8, 8], powermod_stats_string(ef, 1), '1 1 1', 1, 0);
			ypos += 8;
			sui_text([8, ypos], [8, 8], powermod_stats_string(ef, 2), '1 1 1', 1, 0);
		}
		
		string id = sprintf("%isldrop", slot);
		sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
		sui_action_element([-4, 0], [32, 16], id, sui_noop);
		sui_is_clicked(id) ? drop_item(slot) : 0;
		
		sui_fill([-4, 0], [32, 16], '0.5 0.5 0.5', 0.3 + 0.3 * sui_is_hovered(id), 0);
		sui_text([-4, 0], [8, 8], "Drop", '1 1 1', 0.7 + 0.3 * sui_is_hovered(id), 0);
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	}
	
	sui_pop_frame();
};


void() draw_sui =
{
	if (inventory_active)
	{
		vector inv_size = [220, 280];
		
		sui_action_element([inv_size_x, 0], [g_width - inv_size_x, g_height], "clickoutside", sui_noop);
		sui_is_clicked("clickoutside") ? inventory_active = FALSE : 0;
		
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
		sui_push_frame([0, 0], inv_size);
		
		sui_fill([0, 0], inv_size, [0, 0, 0], 0.5, 0);
		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
		sui_text([0, 0], [8, 8], "Inventory", '1 1 1', 1, 0);
		
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
		float ypos = 24;
		
		sui_text([4, ypos], [8, 8], "Weapons", '1 1 1', 0.7, 0);
		ypos += 12; 
		draw_inventory_weapon([4, ypos], inv_size_x - 8, 0);
		ypos += 32 + 8;
		draw_inventory_weapon([4, ypos], inv_size_x - 8, 1);
		ypos += 32 + 8;
		
		sui_text([4, ypos], [8, 8], "Armor", '1 1 1', 0.7, 0);
		ypos += 12; 
		draw_inventory_other([4, ypos], inv_size_x - 8, 2);
		ypos += 32;
		
		sui_text([4, ypos], [8, 8], "Power Modules", '1 1 1', 0.7, 0);
		ypos += 12; 
		draw_inventory_other([4, ypos], inv_size_x - 8, 3);
		ypos += 32;
		draw_inventory_other([4, ypos], inv_size_x - 8, 4);
		ypos += 32;
		draw_inventory_other([4, ypos], inv_size_x - 8, 5);
		
		sui_pop_frame();
	}
};
