class_name GameMaterials
## Shared, procedurally-generated materials for the whole game.
##
## No image files are shipped: textures are generated from code at startup
## (deterministic, seeded) so the repository stays asset-free while the world
## still reads as weathered wood, mud, concrete, roof tiles and so on.
##
## Every material is cached by name, which keeps the material count low and lets
## Godot batch draw calls efficiently.
##
## To swap in real textures later: drop files in `res://assets/textures/` and set
## `albedo_texture` on the relevant material in `_build()`.

extends RefCounted

const TEX_SIZE := 64

static var _cache: Dictionary = {}
static var _textures: Dictionary = {}


# ------------------------------------------------------------------ textures ---
## Small deterministic RGB noise texture used to break up flat colour.
static func noise_texture(key: String, base: Color, spread: float, seed_value: int, stripes: float = 0.0) -> ImageTexture:
	if _textures.has(key):
		return _textures[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	for y in TEX_SIZE:
		for x in TEX_SIZE:
			var n := rng.randf_range(-spread, spread)
			if stripes > 0.0:
				# Vertical wood-grain / roof-tile banding.
				n += sin(float(x) * stripes) * spread * 0.6
			var c := Color(
				clampf(base.r + n, 0.0, 1.0),
				clampf(base.g + n, 0.0, 1.0),
				clampf(base.b + n, 0.0, 1.0),
				1.0
			)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex


# ------------------------------------------------------------------ builder ---
static func get_material(name: String) -> StandardMaterial3D:
	if _cache.has(name):
		return _cache[name]
	var m := _build(name)
	_cache[name] = m
	return m


static func _build(name: String) -> StandardMaterial3D:
	match name:
		# ---------------------------------------------------------- ground ---
		"mud":
			return _textured(name, Color(0.36, 0.27, 0.19), 0.07, 101, 0.0, 0.92, Vector3(6, 6, 6))
		"mud_wet":
			return _textured(name, Color(0.24, 0.18, 0.13), 0.06, 102, 0.0, 0.55, Vector3(6, 6, 6))
		"dirt_path":
			return _textured(name, Color(0.46, 0.37, 0.27), 0.09, 103, 0.0, 0.95, Vector3(8, 8, 8))
		"gravel":
			return _textured(name, Color(0.45, 0.44, 0.42), 0.12, 104, 0.0, 0.9, Vector3(10, 10, 10))
		"concrete":
			return _textured(name, Color(0.66, 0.65, 0.62), 0.05, 105, 0.0, 0.85, Vector3(4, 4, 4))
		"concrete_white":
			return _textured(name, Color(0.85, 0.86, 0.84), 0.03, 106, 0.0, 0.7, Vector3(4, 4, 4))
		"tile_floor":
			return _textured(name, Color(0.78, 0.77, 0.74), 0.04, 107, 0.5, 0.4, Vector3(8, 8, 8))
		"grass":
			return _textured(name, Color(0.29, 0.44, 0.21), 0.10, 108, 0.0, 0.95, Vector3(8, 8, 8))
		"grass_dry":
			return _textured(name, Color(0.55, 0.52, 0.24), 0.09, 109, 0.4, 0.95, Vector3(8, 8, 8))
		"rice_field":
			return _textured(name, Color(0.55, 0.62, 0.26), 0.08, 110, 0.6, 0.95, Vector3(6, 6, 6))

		# ------------------------------------------------------------ wood ---
		"wood":
			return _textured(name, Color(0.55, 0.38, 0.22), 0.06, 201, 0.9, 0.8, Vector3(1, 2, 1))
		"wood_dark":
			return _textured(name, Color(0.33, 0.22, 0.13), 0.05, 202, 1.1, 0.85, Vector3(1, 2, 1))
		"wood_light":
			return _textured(name, Color(0.72, 0.56, 0.36), 0.05, 203, 0.8, 0.75, Vector3(1, 2, 1))
		"wood_painted":
			return _colored(name, Color(0.83, 0.80, 0.72), 0.7, 0.0)
		"bamboo":
			return _textured(name, Color(0.62, 0.62, 0.32), 0.05, 204, 0.0, 0.6, Vector3(1, 3, 1))

		# ------------------------------------------------------- buildings ---
		"roof_tile":
			return _textured(name, Color(0.62, 0.26, 0.20), 0.06, 301, 6.0, 0.75, Vector3(2, 2, 2))
		"roof_tile_blue":
			return _textured(name, Color(0.28, 0.36, 0.52), 0.05, 302, 6.0, 0.75, Vector3(2, 2, 2))
		"roof_tin":
			return _textured(name, Color(0.58, 0.60, 0.63), 0.04, 303, 3.0, 0.45, Vector3(3, 3, 3))
		"thatch":
			return _textured(name, Color(0.63, 0.53, 0.28), 0.08, 304, 2.5, 0.95, Vector3(3, 3, 3))
		"plaster_cream":
			return _textured(name, Color(0.88, 0.85, 0.76), 0.03, 305, 0.0, 0.85, Vector3(3, 3, 3))
		"plaster_teal":
			return _textured(name, Color(0.55, 0.72, 0.70), 0.03, 306, 0.0, 0.8, Vector3(3, 3, 3))
		"glass":
			var g := _colored(name, Color(0.72, 0.82, 0.86, 0.35), 0.08, 0.1)
			g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			g.cull_mode = BaseMaterial3D.CULL_DISABLED
			g.metallic = 0.2
			g.roughness = 0.06
			return g

		# ----------------------------------------------------------- metal ---
		"steel":
			return _colored(name, Color(0.76, 0.78, 0.80), 0.25, 0.85)
		"steel_dull":
			return _colored(name, Color(0.60, 0.61, 0.62), 0.45, 0.7)
		"rust":
			return _textured(name, Color(0.47, 0.30, 0.20), 0.08, 401, 0.0, 0.85, Vector3(4, 4, 4))
		"painted_metal_green":
			return _colored(name, Color(0.24, 0.45, 0.35), 0.5, 0.15)
		"painted_metal_blue":
			return _colored(name, Color(0.20, 0.35, 0.60), 0.5, 0.15)

		# ------------------------------------------------------ vegetation ---
		"leaf":
			return _colored(name, Color(0.20, 0.46, 0.18), 0.85, 0.0)
		"leaf_bright":
			return _colored(name, Color(0.35, 0.60, 0.22), 0.85, 0.0)
		"leaf_banana":
			return _colored(name, Color(0.28, 0.52, 0.26), 0.8, 0.0)
		"leaf_dark":
			return _colored(name, Color(0.13, 0.30, 0.15), 0.9, 0.0)
		"trunk":
			return _textured(name, Color(0.42, 0.33, 0.24), 0.05, 501, 0.0, 0.9, Vector3(1, 3, 1))
		"trunk_palm":
			return _textured(name, Color(0.50, 0.42, 0.30), 0.05, 502, 0.0, 0.9, Vector3(1, 2, 1))
		"flower_pink":
			return _colored(name, Color(0.85, 0.45, 0.62), 0.7, 0.0)
		"flower_white":
			return _colored(name, Color(0.93, 0.92, 0.86), 0.7, 0.0)

		# ------------------------------------------------------------ cloth ---
		"cloth_red":
			return _textured(name, Color(0.72, 0.22, 0.18), 0.05, 601, 0.0, 0.9, Vector3(2, 2, 2))
		"cloth_blue":
			return _textured(name, Color(0.22, 0.38, 0.66), 0.05, 602, 0.0, 0.9, Vector3(2, 2, 2))
		"cloth_yellow":
			return _textured(name, Color(0.88, 0.72, 0.20), 0.05, 603, 0.0, 0.9, Vector3(2, 2, 2))
		"cloth_green":
			return _textured(name, Color(0.24, 0.55, 0.36), 0.05, 604, 0.0, 0.9, Vector3(2, 2, 2))
		"cloth_orange":
			return _textured(name, Color(0.86, 0.48, 0.16), 0.05, 605, 0.0, 0.9, Vector3(2, 2, 2))
		"cloth_purple":
			return _textured(name, Color(0.48, 0.30, 0.60), 0.05, 606, 0.0, 0.9, Vector3(2, 2, 2))

		# ----------------------------------------------------------- signs ---
		"sign_white":
			return _colored(name, Color(0.94, 0.94, 0.90), 0.6, 0.0)
		"sign_blue":
			return _colored(name, Color(0.10, 0.34, 0.62), 0.6, 0.0)
		"sign_green":
			return _colored(name, Color(0.13, 0.50, 0.30), 0.6, 0.0)
		"sign_red":
			return _colored(name, Color(0.72, 0.15, 0.14), 0.65, 0.0)
		"sign_yellow":
			return _colored(name, Color(0.93, 0.78, 0.16), 0.6, 0.0)

		# ------------------------------------------------------------ food ---
		"fish_raw":
			return _colored(name, Color(0.86, 0.62, 0.58), 0.35, 0.05)
		"fish_raw_dark":
			return _colored(name, Color(0.66, 0.36, 0.34), 0.4, 0.05)
		"fish_cooked":
			return _colored(name, Color(0.78, 0.60, 0.32), 0.6, 0.0)
		"fish_grilled":
			return _colored(name, Color(0.45, 0.30, 0.18), 0.75, 0.0)
		"fish_gill":
			# The dark line behind the head. It is deliberately *not* a food
			# surface, so cooking never washes it out: it is what keeps the fish
			# readable as a fish once the flesh has browned.
			return _colored(name, Color(0.20, 0.09, 0.09), 0.45, 0.0)
		"meat":
			return _colored(name, Color(0.62, 0.26, 0.24), 0.5, 0.0)
		"veg_green":
			return _colored(name, Color(0.32, 0.58, 0.24), 0.8, 0.0)
		"veg_red":
			return _colored(name, Color(0.78, 0.24, 0.18), 0.7, 0.0)
		"veg_orange":
			return _colored(name, Color(0.85, 0.52, 0.16), 0.7, 0.0)
		"rice":
			return _colored(name, Color(0.93, 0.91, 0.84), 0.85, 0.0)
		"noodle":
			return _colored(name, Color(0.90, 0.82, 0.60), 0.8, 0.0)
		"basket":
			return _textured(name, Color(0.68, 0.52, 0.28), 0.07, 701, 3.0, 0.9, Vector3(3, 3, 3))
		"plastic_red":
			return _colored(name, Color(0.70, 0.20, 0.18), 0.5, 0.0)
		"plastic_blue":
			return _colored(name, Color(0.22, 0.40, 0.68), 0.5, 0.0)
		"tray_steel":
			return _colored(name, Color(0.72, 0.74, 0.76), 0.3, 0.8)
		"charcoal":
			return _colored(name, Color(0.14, 0.13, 0.13), 0.95, 0.0)

		# ----------------------------------------------------------- water ---
		"puddle":
			var p := _colored(name, Color(0.30, 0.34, 0.26, 0.8), 0.05, 0.15)
			p.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			p.albedo_color = Color(0.30, 0.34, 0.26, 0.8)
			return p
		"wastewater":
			var w := _colored(name, Color(0.30, 0.30, 0.22, 0.85), 0.15, 0.05)
			w.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			w.albedo_color = Color(0.32, 0.31, 0.22, 0.85)
			return w

		# ---------------------------------------------------------- player ---
		"skin":
			return _colored(name, Color(0.76, 0.58, 0.44), 0.6, 0.0)
		"hair":
			return _colored(name, Color(0.12, 0.10, 0.10), 0.8, 0.0)
		"shirt":
			return _colored(name, Color(0.16, 0.52, 0.58), 0.7, 0.0)
		"shorts":
			return _colored(name, Color(0.20, 0.24, 0.36), 0.75, 0.0)
		"shoe":
			return _colored(name, Color(0.92, 0.90, 0.86), 0.6, 0.0)
		"hat": 
			return _colored(name, Color(0.78, 0.68, 0.42), 0.8, 0.0)

		# ------------------------------------------------------- gameplay ----
		"token_wood":
			return _colored(name, Color(0.62, 0.42, 0.22), 0.7, 0.05)
		"token_steel":
			return _colored(name, Color(0.72, 0.74, 0.76), 0.35, 0.8)
		"token_concrete":
			return _colored(name, Color(0.72, 0.71, 0.68), 0.85, 0.0)
		"lens":
			var l := _colored(name, Color(0.82, 0.90, 0.95, 0.5), 0.05, 0.3)
			l.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			return l
		_:
			return _colored(name, Color(0.8, 0.8, 0.8), 0.7, 0.0)


## Emissive material used for lamps, markers and glow effects.
static func glow(name: String, color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var key := "glow_%s_%.1f" % [name, energy]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.3
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_cache[key] = m
	return m


static func _colored(name: String, color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static func _textured(name: String, base: Color, spread: float, seed_value: int,
		stripes: float, roughness: float, uv_scale: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_texture = noise_texture("tex_" + name, base, spread, seed_value, stripes)
	m.albedo_color = Color(1, 1, 1, 1)
	m.uv1_scale = uv_scale
	m.roughness = roughness
	m.metallic = 0.0
	return m


## Clears the caches. Used by tests that want to check generation is repeatable.
static func reset_cache() -> void:
	_cache.clear()
	_textures.clear()
