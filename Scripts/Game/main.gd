extends Node3D
class_name GameManager

@export var pollution_per_sec : float = 0.5
@export var max_polution : float = 100.0

@onready var water: MeshInstance3D = $Water
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var player = $Player

@onready var UI_PollBar: ProgressBar = $CanvasLayer/Control/HUD/VBoxContainer/PollutionBar
@onready var UI_Trash: Label = $CanvasLayer/Control/HUD/VBoxContainer/Trash
@onready var UI_TimeElapsed: Label = $CanvasLayer/Control/HUD/VBoxContainer/TimeElapsed
@onready var UI_PlayAgainBtn: Button = $CanvasLayer/Control/GameOverPanel/Control/PlayAgainBtn
@onready var UI_GameOverPanel: Panel = $CanvasLayer/Control/GameOverPanel
@onready var UI_GameWonPanel: Panel = $CanvasLayer/Control/GameWonPanel
@onready var UI_RestartButtonWin : Button = $CanvasLayer/Control/GameWonPanel/Control/PlayAgainBtn

#ENV MATS
var env_res: Environment
var water_mat: ShaderMaterial
var clean_water_col: Color
var dirty_water_col = Color(0.1, 0.2, 0.05, 0.7)
var clean_fog_col = Color(0.8, 0.9, 1.0)
var dirty_fog_col = Color(0.1, 0.4, 0.1)
var clean_amb = Color(0.9, 0.95, 1.0)
var dirty_amb = Color(0.2, 0.3, 0.1)
var clean_sky_top = Color(0.5, 0.7, 1.0)
var dirty_sky_top = Color(0.1, 0.2, 0.3)


var curr_pollution : float = 0.0
var trash_collected : int  = 0
var total_trash : int = 0
var trash_reduction : float = 0.0
var elapsed_time: float = 0.0
var game_active : bool = true

#UI
var canvas : CanvasLayer
var warning_canvas := CanvasLayer.new()
var pollution_bar: ProgressBar
var trash_lbl: Label
var time_lbl: Label
var game_over_bg: ColorRect
var game_over_title: Label
var restart_btn: Button
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UI_PlayAgainBtn.pressed.connect(_restart_game)
	UI_RestartButtonWin.pressed.connect(_restart_game)
	$TrashSpawner.clear_and_spawn()
	await get_tree().process_frame
	#trash collection
	var trash_nodes = get_tree().get_nodes_in_group("trash")
	total_trash = trash_nodes.size()
	print(trash_nodes)
	if total_trash == 0:
		show_game_over(true)
		return
	
	trash_reduction = max_polution / total_trash
	
	for trash in trash_nodes:
		if trash.has_signal("collected"):
			trash.collected.connect(_on_trash_collected)
			
	#purifier
	var purifiers = get_tree().get_nodes_in_group("purifier")
	if purifiers.size() > 0:
		purifiers[0].activated.connect(_on_purifier_activated)
		
	water_mat = water.get_active_material(0) as ShaderMaterial
	if water_mat:
		clean_water_col = water_mat.get_shader_parameter("albedo")


	add_child(warning_canvas)
	warning_canvas.layer = 10
	
	
	update_ui()
	setup_env()
	show_warning("Исчистете го отпадот и спасете го езерото!", 1.2)

func show_warning(msg: String, dur : float):
	var panel := Panel.new()
	var label := Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	panel.add_child(label)
	warning_canvas.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.custom_minimum_size.y = 80
	panel.modulate.a = 0
	
	var tween := create_tween()
	tween.parallel().tween_property(panel, "modulate:a", 1.0, dur)
	tween.parallel().tween_property(panel, "scale", Vector2(1.1, 1.1), dur)
	await tween.finished
	
	tween = create_tween()
	tween.parallel().tween_property(panel, "modulate:a", 0.0, dur)
	tween.parallel().tween_property(panel, "scale", Vector2(0.9, 0.9), dur)
	await tween.finished
	panel.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if not game_active:
		return
	
	elapsed_time += delta
	curr_pollution += delta * pollution_per_sec
	curr_pollution = min(curr_pollution, max_polution)
	
	UI_TimeElapsed.text = "Изминато време: %.0f s" % elapsed_time
	
	if curr_pollution >= max_polution:
		show_game_over(false)
	
	update_ui()
	var pct = clamp(curr_pollution / (max_polution * 1.5), 0.0, 1.0)  
	update_env(pct)
	
func _on_trash_collected():
	trash_collected += 1
	curr_pollution = max(0.0, curr_pollution - trash_reduction)
	update_ui()
	
func _on_purifier_activated():
	if (trash_collected >= total_trash):
		show_game_over(true)
	else:
		show_warning("Отпадот не е собран!",1)

func update_ui():
	UI_PollBar.value = curr_pollution
	UI_Trash.text = "Отпад: %d/%d" % [trash_collected, total_trash]
	
func show_game_over(is_win: bool):
	game_active = false
	player.set_process_input(false)

	if is_win:
		UI_GameWonPanel.visible = true
		UI_GameOverPanel.visible = false
	else:
		UI_GameOverPanel.visible = true
		UI_GameWonPanel.visible = false



func _restart_game():
	get_tree().reload_current_scene()
	
	
func setup_env():
	env_res = world_env.environment
	if not env_res:
		env_res = Environment.new()
		world_env.environment = env_res
	
	env_res.fog_enabled = true
	env_res.volumetric_fog_enabled = true
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_res.background_mode = Environment.BG_SKY
	
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = clean_sky_top
	sky.sky_material = sky_mat
	env_res.sky = sky
	
	# Water mat
	water_mat = water.material_override
	if not water_mat:
		water_mat = water.get_active_material(0)
	clean_water_col = water_mat.get_shader_parameter("albedo") if water_mat else clean_water_col
	
func update_env(pct: float):
	if water_mat:
		var new_col = clean_water_col.lerp(dirty_water_col, pct)
		water_mat.set_shader_parameter("albedo", new_col)
	if pct < 0.1:
		env_res.fog_density = 0.0
		env_res.volumetric_fog_density = 0.0
	else:
		var adjusted_pct = (pct - 0.1) / 0.9
		env_res.fog_density = lerp(0.005, 0.04, adjusted_pct)
		env_res.volumetric_fog_density = lerp(0.0, 0.2, adjusted_pct)
	
	if env_res.sky and env_res.sky.sky_material:
		var sky_m = env_res.sky.sky_material as ProceduralSkyMaterial
		sky_m.sky_top_color = clean_sky_top.lerp(dirty_sky_top, pct)
		sky_m.ground_bottom_color = Color.WHITE.lerp(Color(0.3, 0.8, 0.3), pct)
