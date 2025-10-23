extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 0.5

@onready var camera = $Camera3D
@onready var attack_timer: float = 0.0
var hud: CanvasLayer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	await get_tree().process_frame

	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		var mice = get_tree().get_nodes_in_group("mouse")
		hud.set_total_mice(mice.size())
		hud.connect("time_up", Callable(self, "_on_time_up"))
		hud.connect("all_mice_killed", Callable(self, "_on_all_mice_killed"))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	attack_timer -= delta
	if Input.is_action_just_pressed("attack") and attack_timer <= 0:
		attack()
		attack_timer = attack_cooldown

func attack():
	print("🐾 Кот атакует!")
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()

	var shape = SphereShape3D.new()
	shape.radius = attack_range
	query.shape = shape
	query.transform = global_transform
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results = space_state.intersect_shape(query)

	for result in results:
		var collider = result.collider
		if collider != self and collider.has_method("take_damage"):
			collider.take_damage(attack_damage)
			print("💥 Попадание!")

func on_mouse_killed():
	if hud:
		hud.add_kill()

func _on_time_up():
	print("Время вышло! Поражение!")
	get_tree().change_scene_to_file("res://scenes/LoseScreen.tscn")

func _on_all_mice_killed():
	print("Все мыши уничтожены! Победа!")
	get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
