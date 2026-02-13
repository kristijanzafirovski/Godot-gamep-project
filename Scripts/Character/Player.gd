extends CharacterBody3D

const LERP_VALUE : float = 0.15

var snap_vector : Vector3 = Vector3.DOWN
var speed : float



@export_group("Movement variables")
@export var walk_speed : float = 2.0
@export var run_speed : float = 5.0
@export var jump_strength : float = 15.0
@export var gravity : float = 50.0
@export var mouse_sensitivity : float = 0.002
const ANIMATION_BLEND : float = 7.0

var surface_y : float
@export var bouyancy_force : float = 15.0
var capsule_height: float
var swimming: bool = false

@onready var player_mesh : Node3D = $Mesh
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var animator : AnimationTree = $AnimationTree

@export var water_path: NodePath
@onready var water_mesh : MeshInstance3D = get_node(water_path)
@onready var collisionShape : CollisionShape3D = $CollisionShape3D





func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var shape = collisionShape.shape as CapsuleShape3D
	capsule_height = shape.height * scale.y
	update_water_surface()

func update_water_surface():
	var boxMesh = water_mesh.mesh as BoxMesh
	var scaled_half_height = (boxMesh.size.y / 2.0) * water_mesh.scale.y
	surface_y = water_mesh.global_position.y + scaled_half_height
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.MOUSE_MODE_CAPTURED:
		spring_arm_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm_pivot.rotate_x(event.relative.y * mouse_sensitivity)
		spring_arm_pivot.rotation.x = clamp(
			spring_arm_pivot.rotation.x,
			deg_to_rad(-85), 
			deg_to_rad( 60)   
		)
		spring_arm_pivot.rotation.z = 0.0

func _physics_process(delta):
	var move_direction : Vector3 = Vector3.ZERO
	move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_direction.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	
	speed = run_speed if Input.is_action_pressed("sprint") else walk_speed
	var swim_speed_mult = 1.4 if swimming else 1.0
	velocity.x = move_direction.x * speed * swim_speed_mult
	velocity.z = move_direction.z * speed * swim_speed_mult
	
	var half_h = capsule_height / 2.0
	var bottom_y = global_position.y - half_h + 0.5
	var submerged = maxf(0.0, surface_y - bottom_y)
	var fraction = submerged / capsule_height
	swimming = fraction > 0.2
	if swimming:
		global_position.y = surface_y - half_h + 1  
		velocity.y = maxf(velocity.y, -2.0)        
		snap_vector = Vector3.ZERO
	else:
		velocity.y -= gravity * delta
		var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
		var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump")
		if is_jumping:
			velocity.y = jump_strength
			snap_vector = Vector3.ZERO
		elif just_landed:
			snap_vector = Vector3.DOWN
			
	if move_direction:
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)

	apply_floor_snap()
	move_and_slide()
	animate(delta)
	update_water_surface()
	
func animate(delta):
	if swimming:
		animator.set("parameters/ground_air_transition/transition_request", "swimming")
		animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 0.5, delta * ANIMATION_BLEND))
	elif is_on_floor():
		animator.set("parameters/ground_air_transition/transition_request", "grounded")
		if velocity.length() > 0:
			if speed == run_speed:
				animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
			else:
				animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
		else:
			animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), -1.0, delta * ANIMATION_BLEND))
	else:
		animator.set("parameters/ground_air_transition/transition_request", "air")
