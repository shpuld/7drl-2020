block
{
	//cull disable
	{
		map $nearest:models/block/block.png
		rgbGen entity
		alphaGen entity
	}
}

floor
{
	{
		nodraw
		map $nearest:models/block/floor.png
		rgbGen vertex
		alphaGen entity
	}
}

test_blocks
{
	//cull disable
	{
		map $nearest:models/block/test_blocks.png
		rgbGen entity
		alphaGen entity
	}
}