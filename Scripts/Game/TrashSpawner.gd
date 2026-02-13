extends Node3D
class_name TrashSpawner

@export var trash_scene: PackedScene
@export var trash_meshes: Array[PackedScene] = []
@export var spawn_area: StaticBody3D
@export var num_min: int = 5
@export var num_max: int = 15
@export var height_offset: float = 0.8
@export var random_scale_min: float = 0.8
@export var random_scale_max: float = 1.5
@export var terrain_collision_layer: int = 1

@onready var water: MeshInstance3D = get_node_or_null("../Water")

func clear_and_spawn():
	clear_old_trash()
	var num = randi_range(num_min, num_max)
	var spawned = 0
	while spawned < num:
		if spawn_one_trash():
			spawned += 1

func clear_old_trash():
	for node in get_tree().get_nodes_in_group("trash"):
		node.queue_free()

func spawn_one_trash() -> bool:
	if not spawn_area or trash_meshes.is_empty():
		return false
	
	var shape_node = spawn_area.get_node_or_null("CollisionShape3D")
	if not shape_node or not shape_node.shape is BoxShape3D:
		return false
	
	var box: BoxShape3D = shape_node.shape
	var half = box.size * 0.5
	
	var local_pos = Vector3(
		randf_range(-half.x, half.x),
		0.0,
		randf_range(-half.z, half.z)
	)
	
	var global_offset = spawn_area.global_transform.basis * local_pos
	var x = spawn_area.global_position.x + global_offset.x
	var z = spawn_area.global_position.z + global_offset.z
	
	var terrain = get_tree().get_first_node_in_group("terrain")
	if not terrain or not terrain is Terrain3D:
		return false
	
	var terrain_y = terrain.data.get_height(Vector3(x, 0, z))
	if is_nan(terrain_y):
		return false
	
	var y = height_offset + terrain_y
	
	if water:
		var water_half = (water.mesh as BoxMesh).size.y / 2.0 * water.scale.y
		var water_surface_y = water.global_position.y + water_half
		if terrain_y < water_surface_y:
			y = height_offset + water_surface_y
	
	
	var chosen_scene = trash_meshes[randi() % trash_meshes.size()]
	var inst = chosen_scene.instantiate()
	add_child(inst)
	inst.add_to_group("trash")
	inst.global_position = Vector3(x, y, z)
	inst.rotation_degrees.y = randf() * 360.0
	print("Position of trash: %s ", inst.global_position)
	inst.scale = Vector3.ONE * randf_range(random_scale_min, random_scale_max)
	
	return true
