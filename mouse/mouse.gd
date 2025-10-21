extends CharacterBody3D

@export var hp: int = 30
@export var walk_speed: float = 2.0
@export var run_speed: float = 5.0
@export var detection_range: float = 10.0
@export var vision_angle: float = 120.0  # Угол обзора в градусах

var player: Node3D = null
var current_speed: float = walk_speed
var wander_timer: float = 0.0
var wander_direction: Vector3 = Vector3.ZERO
var is_fleeing: bool = false
var hp_label: Label3D = null

# Состояния мыши
enum State { WANDER, FLEE }
var current_state: State = State.WANDER

func _ready():
	# Находим игрока (кота)
	player = get_tree().get_first_node_in_group("player")
	_set_new_wander_direction()
	
	# Находим или создаём Label3D для отображения HP
	hp_label = get_node_or_null("HPLabel")
	if hp_label:
		_update_hp_label()

func _physics_process(delta):
	if hp <= 0:
		die()
		return
	
	# Проверяем, видит ли мышь игрока
	if player and can_see_player():
		current_state = State.FLEE
		is_fleeing = true
	else:
		is_fleeing = false
		if current_state == State.FLEE:
			current_state = State.WANDER
			_set_new_wander_direction()
	
	# Выполняем поведение в зависимости от состояния
	match current_state:
		State.WANDER:
			wander(delta)
		State.FLEE:
			flee_from_player(delta)
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	# Поворачиваем мышь в сторону движения
	if velocity.length() > 0.1:
		look_at(global_position + velocity.normalized(), Vector3.UP)

func wander(delta):
	current_speed = walk_speed
	
	# Обновляем таймер
	wander_timer -= delta
	
	if wander_timer <= 0:
		_set_new_wander_direction()
	
	# Движение в случайном направлении
	velocity.x = wander_direction.x * current_speed
	velocity.z = wander_direction.z * current_speed

func flee_from_player(delta):
	current_speed = run_speed
	
	if player:
		# Направление от игрока
		var direction = (global_position - player.global_position).normalized()
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

func can_see_player() -> bool:
	if not player:
		return false
	
	var distance = global_position.distance_to(player.global_position)
	
	# Проверяем дистанцию
	if distance > detection_range:
		return false
	
	# Проверяем угол обзора
	var direction_to_player = (player.global_position - global_position).normalized()
	var forward = -global_transform.basis.z.normalized()
	var angle = rad_to_deg(acos(forward.dot(direction_to_player)))
	
	if angle > vision_angle / 2:
		return false
	
	# Проверяем, есть ли препятствия (опционально)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		player.global_position + Vector3.UP * 0.5
	)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == player:
		return true
	elif not result:
		return true
	
	return false

func _set_new_wander_direction():
	# Устанавливаем новое случайное направление
	wander_direction = Vector3(
		randf_range(-1, 1),
		0,
		randf_range(-1, 1)
	).normalized()
	
	# Случайное время до следующей смены направления
	wander_timer = randf_range(2.0, 5.0)

func take_damage(damage: int):
	hp -= damage
	print("Мышь получила урон! Осталось HP: ", hp)
	_update_hp_label()
	
	if hp <= 0:
		die()

func die():
	print("Мышь умерла!")
	queue_free()

func _update_hp_label():
	if hp_label:
		hp_label.text = str(hp) + " HP"
		
		# Меняем цвет в зависимости от количества HP
		if hp > 20:
			hp_label.modulate = Color.GREEN
		elif hp > 10:
			hp_label.modulate = Color.YELLOW
		else:
			hp_label.modulate = Color.RED
