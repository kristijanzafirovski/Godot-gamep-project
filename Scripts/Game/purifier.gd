extends Area3D

signal activated

func _ready():
	body_entered.connect(_on_body_entered)
	collision_layer = 3  
	collision_mask = 1

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		activated.emit()
