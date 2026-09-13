extends Node
## کنترل نور روز/شب، آسمان و مه — آماده برای SDFGI و Volumetric Fog

@onready var sun: DirectionalLight3D = $"../Sun"
@onready var env: WorldEnvironment = $"../WorldEnvironment"

var _gm: Node

func _ready() -> void:
	_gm = get_node_or_null("/root/GameManager")
	if _gm:
		_gm.day_changed.connect(_on_day_changed)
		_gm.weather_changed.connect(_on_weather)

func _on_day_changed(frac: float) -> void:
	if not sun or not env:
		return
	var sun_h := sin(frac * TAU)
	# زاویه خورشید
	sun.rotation_degrees.x = -sun_h * 80.0 - 10.0
	sun.rotation_degrees.y = frac * 360.0 - 90.0

	# شدت و رنگ
	if sun_h > 0.1:
		sun.light_energy = lerpf(0.4, 1.35, clampf((sun_h - 0.1) / 0.7, 0, 1))
		sun.light_color = Color(1.0, 0.96, 0.88)
		sun.shadow_enabled = true
	elif sun_h > -0.15:
		# طلوع/غروب
		var k := (sun_h + 0.15) / 0.25
		sun.light_energy = lerpf(0.15, 0.6, k)
		sun.light_color = Color(1.0, 0.55, 0.30).lerp(Color(1.0, 0.9, 0.7), k)
		sun.shadow_enabled = true
	else:
		sun.light_energy = 0.04
		sun.light_color = Color(0.55, 0.60, 0.85)
		sun.shadow_enabled = false

	# آسمان و مه
	var sky_mat: ShaderMaterial = null
	if env.environment and env.environment.sky and env.environment.sky.sky_material:
		# اگر از ProceduralSkyMaterial استفاده می‌کنیم
		var sm = env.environment.sky.sky_material
		if sm is ProceduralSkyMaterial:
			if sun_h > 0.2:
				sm.sky_top_color = Color(0.25, 0.45, 0.85)
				sm.sky_horizon_color = Color(0.55, 0.70, 0.90)
				sm.ground_bottom_color = Color(0.15, 0.18, 0.12)
			elif sun_h > -0.05:
				sm.sky_top_color = Color(0.55, 0.30, 0.45)
				sm.sky_horizon_color = Color(0.95, 0.50, 0.25)
				sm.ground_bottom_color = Color(0.20, 0.12, 0.08)
			else:
				sm.sky_top_color = Color(0.02, 0.03, 0.08)
				sm.sky_horizon_color = Color(0.05, 0.06, 0.14)
				sm.ground_bottom_color = Color(0.02, 0.02, 0.04)
			sm.sun_angle_max = 30.0
			sm.sun_curve = 0.15

	# Ambient
	if env.environment:
		env.environment.ambient_light_energy = lerpf(0.08, 0.35, clampf(sun_h + 0.2, 0, 1))
		# Fog
		env.environment.fog_enabled = true
		env.environment.fog_density = 0.0015 + (0.004 if sun_h < 0 else 0.0)
		if sun_h > 0.1:
			env.environment.fog_light_color = Color(0.7, 0.8, 0.95)
		elif sun_h > -0.1:
			env.environment.fog_light_color = Color(0.9, 0.5, 0.3)
		else:
			env.environment.fog_light_color = Color(0.15, 0.18, 0.30)

func _on_weather(state: String, intensity: float) -> void:
	if not env or not env.environment:
		return
	match state:
		"fog":
			env.environment.fog_density = 0.008 + intensity * 0.02
		"rain":
			env.environment.fog_density = 0.004 + intensity * 0.01
			env.environment.fog_light_color = Color(0.4, 0.45, 0.55)
		"sandstorm":
			env.environment.fog_density = 0.012 + intensity * 0.025
			env.environment.fog_light_color = Color(0.7, 0.55, 0.30)
		_:
			pass
