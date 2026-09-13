extends Node3D
## تولید جهان رویه‌ای — ارتفاع، بیوم، اشیاء + شیدر PBR روی مش زمین

const CHUNK_SIZE := 32
const VIEW_CHUNKS := 3
const HEIGHT_SCALE := 18.0

@export var seed_value: int = 12345

var _noise: FastNoiseLite
var _biome_noise: FastNoiseLite
var _loaded: Dictionary = {}
var _mats: Dictionary = {}

@onready var terrain_root: Node3D = $Terrain
@onready var objects_root: Node3D = $Objects

func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = seed_value
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.012
	_noise.fractal_octaves = 5
	_noise.fractal_gain = 0.45

	_biome_noise = FastNoiseLite.new()
	_biome_noise.seed = seed_value + 99
	_biome_noise.frequency = 0.004
	_biome_noise.fractal_octaves = 3

	_build_pbr_materials()

func _build_pbr_materials() -> void:
	var shader: Shader = load("res://shaders/terrain_pbr.gdshader")
	if shader == null:
		push_warning("terrain_pbr.gdshader not found — fallback StandardMaterial3D")
		_mats = _fallback_standard_mats()
		return

	var biome_cfg := {
		"grass": {"alb": "grass_albedo.png", "nrm": "grass_normal.png", "tint": Color(0.85, 1.0, 0.75), "rough": 0.82, "uv": 0.09},
		"forest": {"alb": "forest_albedo.png", "nrm": "grass_normal.png", "tint": Color(0.7, 0.95, 0.7), "rough": 0.88, "uv": 0.10},
		"sand": {"alb": "sand_albedo.png", "nrm": "sand_normal.png", "tint": Color(1.0, 0.95, 0.85), "rough": 0.70, "uv": 0.07},
		"desert": {"alb": "desert_albedo.png", "nrm": "sand_normal.png", "tint": Color(1.0, 0.9, 0.75), "rough": 0.72, "uv": 0.07},
		"snow": {"alb": "snow_albedo.png", "nrm": "dirt_normal.png", "tint": Color(0.95, 0.97, 1.0), "rough": 0.45, "uv": 0.08},
		"water": {"alb": "water_albedo.png", "nrm": "sand_normal.png", "tint": Color(0.6, 0.8, 1.0), "rough": 0.12, "uv": 0.05},
		"dirt": {"alb": "dirt_albedo.png", "nrm": "dirt_normal.png", "tint": Color(0.95, 0.9, 0.85), "rough": 0.90, "uv": 0.09},
	}

	for biome in biome_cfg:
		var cfg: Dictionary = biome_cfg[biome]
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var alb_path := "res://assets/textures/%s" % cfg["alb"]
		var nrm_path := "res://assets/textures/%s" % cfg["nrm"]
		if ResourceLoader.exists(alb_path):
			mat.set_shader_parameter("albedo_tex", load(alb_path))
		if ResourceLoader.exists(nrm_path):
			mat.set_shader_parameter("normal_tex", load(nrm_path))
		mat.set_shader_parameter("albedo_tint", cfg["tint"])
		mat.set_shader_parameter("uv_scale", cfg["uv"])
		mat.set_shader_parameter("normal_strength", 0.9)
		mat.set_shader_parameter("roughness_base", cfg["rough"])
		mat.set_shader_parameter("metallic_base", 0.0)
		mat.set_shader_parameter("ao_strength", 0.4)
		mat.set_shader_parameter("fog_color", Vector3(0.55, 0.65, 0.80))
		mat.set_shader_parameter("fog_start", 35.0)
		mat.set_shader_parameter("fog_end", 110.0)
		_mats[biome] = mat

	var stone := ShaderMaterial.new()
	stone.shader = shader
	if ResourceLoader.exists("res://assets/textures/stone_albedo.png"):
		stone.set_shader_parameter("albedo_tex", load("res://assets/textures/stone_albedo.png"))
	if ResourceLoader.exists("res://assets/textures/stone_normal.png"):
		stone.set_shader_parameter("normal_tex", load("res://assets/textures/stone_normal.png"))
	stone.set_shader_parameter("albedo_tint", Color(0.95, 0.95, 0.95))
	stone.set_shader_parameter("uv_scale", 0.08)
	stone.set_shader_parameter("normal_strength", 1.4)
	stone.set_shader_parameter("roughness_base", 0.78)
	_mats["stone"] = stone

func _fallback_standard_mats() -> Dictionary:
	var d := {}
	for b in ["grass", "forest", "sand", "desert", "snow", "water", "dirt", "stone"]:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.85
		d[b] = m
	return d

func height_at(x: float, z: float) -> float:
	var n := _noise.get_noise_2d(x, z)
	n += _noise.get_noise_2d(x * 2.1, z * 2.1) * 0.35
	n += _noise.get_noise_2d(x * 0.3, z * 0.3) * 0.5
	return n * HEIGHT_SCALE + 2.0

func biome_at(x: float, z: float) -> String:
	var h := height_at(x, z)
	var b := _biome_noise.get_noise_2d(x, z)
	if h < 0.8:
		return "water"
	if h > 14.0:
		return "snow"
	if b > 0.35:
		return "desert" if h < 6.0 else "sand"
	if b < -0.25:
		return "forest"
	return "grass"

func _process(_delta: float) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.player:
		_update_chunks(gm.player.global_position)

func _chunk_key(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / CHUNK_SIZE), floori(pos.z / CHUNK_SIZE))

func _update_chunks(player_pos: Vector3) -> void:
	var center := _chunk_key(player_pos)
	var needed: Dictionary = {}
	for cx in range(center.x - VIEW_CHUNKS, center.x + VIEW_CHUNKS + 1):
		for cz in range(center.y - VIEW_CHUNKS, center.y + VIEW_CHUNKS + 1):
			var key := Vector2i(cx, cz)
			needed[key] = true
			if not _loaded.has(key):
				_loaded[key] = _build_chunk(cx, cz)
	var to_remove: Array[Vector2i] = []
	for key in _loaded:
		if not needed.has(key):
			to_remove.append(key)
	for key in to_remove:
		_loaded[key].queue_free()
		_loaded.erase(key)

func _build_chunk(cx: int, cz: int) -> Node3D:
	var root := Node3D.new()
	root.name = "chunk_%d_%d" % [cx, cz]
	terrain_root.add_child(root)

	var biome_surfaces: Dictionary = {}
	var res := 16
	var step := float(CHUNK_SIZE) / res
	var ox := cx * CHUNK_SIZE
	var oz := cz * CHUNK_SIZE

	for iz in range(res):
		for ix in range(res):
			var x0 := ox + ix * step
			var z0 := oz + iz * step
			var x1 := x0 + step
			var z1 := z0 + step
			var h00 := height_at(x0, z0)
			var h10 := height_at(x1, z0)
			var h11 := height_at(x1, z1)
			var h01 := height_at(x0, z1)
			var biome := biome_at(x0 + step * 0.5, z0 + step * 0.5)
			if not biome_surfaces.has(biome):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				biome_surfaces[biome] = st
			var st: SurfaceTool = biome_surfaces[biome]
			var color := Color.WHITE
			var uv_s := 0.08
			_add_vert(st, Vector3(x0, h00, z0), color, Vector2(x0, z0) * uv_s)
			_add_vert(st, Vector3(x1, h10, z0), color, Vector2(x1, z0) * uv_s)
			_add_vert(st, Vector3(x1, h11, z1), color, Vector2(x1, z1) * uv_s)
			_add_vert(st, Vector3(x0, h00, z0), color, Vector2(x0, z0) * uv_s)
			_add_vert(st, Vector3(x1, h11, z1), color, Vector2(x1, z1) * uv_s)
			_add_vert(st, Vector3(x0, h01, z1), color, Vector2(x0, z1) * uv_s)

	var all_faces: PackedVector3Array = PackedVector3Array()
	for biome in biome_surfaces:
		var st: SurfaceTool = biome_surfaces[biome]
		st.generate_normals()
		st.generate_tangents()
		var mesh := st.commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _mats.get(biome, _mats.get("grass"))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(mi)
		all_faces.append_array(mesh.get_faces())

	if all_faces.size() >= 3:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(all_faces)
		col.shape = shape
		body.add_child(col)
		root.add_child(body)

	_scatter_objects(root, ox, oz)
	return root

func _add_vert(st: SurfaceTool, pos: Vector3, color: Color, uv: Vector2) -> void:
	st.set_color(color)
	st.set_uv(uv)
	st.add_vertex(pos)

func _scatter_objects(parent: Node3D, ox: float, oz: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2(ox, oz)) + seed_value
	for i in range(8):
		var lx := ox + rng.randf() * CHUNK_SIZE
		var lz := oz + rng.randf() * CHUNK_SIZE
		var h := height_at(lx, lz)
		var biome := biome_at(lx, lz)
		if biome == "water" or h < 1.0:
			continue
		var kind: String
		if biome == "forest" or biome == "grass":
			kind = "tree" if rng.randf() > 0.35 else "rock"
		elif biome == "desert" or biome == "sand":
			kind = "cactus" if rng.randf() > 0.5 else "rock"
		else:
			kind = "rock"
		var obj := _make_prop(kind, Vector3(lx, h, lz))
		if obj:
			parent.add_child(obj)

func _make_prop(kind: String, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	match kind:
		"tree":
			var trunk := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.18
			cyl.bottom_radius = 0.22
			cyl.height = 2.6
			trunk.mesh = cyl
			trunk.position.y = 1.3
			var wood_mat := StandardMaterial3D.new()
			wood_mat.albedo_color = Color(0.35, 0.20, 0.10)
			wood_mat.roughness = 0.85
			if ResourceLoader.exists("res://assets/textures/wood_albedo.png"):
				wood_mat.albedo_texture = load("res://assets/textures/wood_albedo.png")
			if ResourceLoader.exists("res://assets/textures/wood_normal.png"):
				wood_mat.normal_enabled = true
				wood_mat.normal_texture = load("res://assets/textures/wood_normal.png")
			trunk.material_override = wood_mat
			trunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(trunk)
			var leaves := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 1.3
			sph.height = 2.2
			leaves.mesh = sph
			leaves.position.y = 3.0
			var leaf_mat := StandardMaterial3D.new()
			leaf_mat.albedo_color = Color(0.15, 0.42, 0.18)
			leaf_mat.roughness = 0.9
			if ResourceLoader.exists("res://assets/textures/leaf_albedo.png"):
				leaf_mat.albedo_texture = load("res://assets/textures/leaf_albedo.png")
			leaves.material_override = leaf_mat
			leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(leaves)
		"rock":
			var mi := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.2, 0.7, 1.0)
			mi.mesh = box
			mi.position.y = 0.35
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.45, 0.42, 0.40)
			mat.roughness = 0.8
			if ResourceLoader.exists("res://assets/textures/stone_albedo.png"):
				mat.albedo_texture = load("res://assets/textures/stone_albedo.png")
			if ResourceLoader.exists("res://assets/textures/stone_normal.png"):
				mat.normal_enabled = true
				mat.normal_texture = load("res://assets/textures/stone_normal.png")
				mat.normal_scale = 1.2
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mi)
		"cactus":
			var mi := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.14
			cyl.bottom_radius = 0.16
			cyl.height = 2.0
			mi.mesh = cyl
			mi.position.y = 1.0
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.18, 0.45, 0.20)
			mat.roughness = 0.75
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mi)
		_:
			return null
	return root
