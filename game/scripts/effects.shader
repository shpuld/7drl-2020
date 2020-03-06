aparticle
{
	{
		map particles/ccloud.tga
		alphagen vertex
		rgbGen vertex
		alphafunc GE128
		blendFunc GL_ONE GL_ONE
	}
}

aparticle2
{
	{
		map particles/splat.tga
		alphagen vertex
		rgbGen vertex
		alphafunc GE128
	}
}


lightpoly
{
	cull disable
	{
		rgbGen vertex
		blendFunc GL_ONE GL_ONE
	}
}

lightmat 
{
	cull disable
	{
		map $linear:models/lightmat
		rgbGen entity
		blendFunc GL_ONE GL_ONE
	}
}

lights_postproc
{
	{
		map $rt:$nearest:lightsbuf
		// alphaGen entity
		blendFunc GL_DST_COLOR GL_ZERO
	}
	{
		map $rt:$nearest:lightsbuf
		// alphaGen entity
		alphaGen vertex
		rgbGen vertex
		blendFunc GL_ONE GL_ONE
	}
}

menu/cursor
{
	{
		map gfx/xhair
	}
}

vc
{
	{
		map $whitetexture
		rgbGen vertex 
	}
	{
		map $whitetexture
		rgbGen lightingDiffuse
		blendFunc gl_dst_color gl_zero
	}
}

ring
{
	{
		map $whitetexture
		rgbGen entity
		alphaGen entity
		blendFunc gl_src_alpha gl_one
	}
}

muzzleflash
{
	{
		map $diffuse
		blendFunc gl_src_alpha GL_ONE
		alphaGen entity
	}
}

melee_proj
{
	{
		map $diffuse
		blendFunc gl_src_alpha GL_ONE
		alphaGen entity
	}
}

snowfall
{
	cull disable
	{
		map textures/snowfall.tga
		blendFunc GL_ONE GL_ONE
	}
}

fog
{
	cull disable
	{
		map textures/fog.tga
		blendFunc GL_ONE GL_ONE
	}
}

fog2
{
	cull disable
	{
		map textures/fog2.tga
		blendFunc GL_ONE GL_ONE
	}
}

ash
{
	cull front
	{
		map textures/ash.tga
		blendFunc GL_ONE GL_ONE
	}
}