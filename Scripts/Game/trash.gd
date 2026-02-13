extends Area3D

signal collected

func _ready():
	body_entered.connect(_on_body_entered)
	collision_mask = 1
	collision_layer = 2
	
func _on_body_entered(body : Node3D):
	if body.is_in_group("player"):
		print("Touched: ", body.name)
		collected.emit()
		queue_free()
	
