extends Camera3D

@export var target: Node3D
@export var offset = Vector3(0, 5, 8)
@export var follow_speed = 5.0
@export var look_ahead = 2.0

func _physics_process(delta):
	if target == null:
		return
	
	# Позиция камеры за котом
	var target_pos = target.global_position - target.transform.basis.z * offset.z + Vector3.UP * offset.y
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Камера смотрит на кота с небольшим опережением
	var look_at_pos = target.global_position + target.transform.basis.z * look_ahead
	look_at(look_at_pos, Vector3.UP)
