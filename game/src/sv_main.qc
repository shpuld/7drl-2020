//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//

void() main =
{
};

//called for each frame that QC runs
void() StartFrame =
{
};

// #define SSQC_TEST
void() run_sv_unit_tests =
{
	print("Running SSQC unit tests...\n");
	// Add tests here
	print("Tests complete!\n");
};


void() worldspawn =
{	
	precache_everything();
	
	current_level = LEVEL_SNOW;
	
	if (world.model == "maps/bigbox.bsp")
	{
		init_test_map();
	}
	
	clientstat(STAT_ITEM_ID, EV_FLOAT, item_id);
	clientstat(STAT_ITEM_EFFECT, EV_FLOAT, item_effect);
	clientstat(STAT_ITEM_TYPE, EV_FLOAT, type);
	
	globalstat(STAT_LEVEL, EV_FLOAT, "current_level");

	#ifdef SSQC_TEST
	run_sv_unit_tests();
	#endif
};

void() SpectatorConnect =
{	
};

