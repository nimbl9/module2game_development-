extends CanvasLayer

var total_mice: int = 0
var killed_mice: int = 0
var remaining_time: float = 30.0
var is_game_over: bool = false

@onready var kill_label: Label = $VBoxContainer/LabelKillCount
@onready var timer_label: Label = $VBoxContainer/LabelTimer

signal time_up
signal all_mice_killed

func _ready():
	_update_labels()

func _process(delta):
	if is_game_over:
		return

	remaining_time -= delta
	if remaining_time <= 0:
		remaining_time = 0
		is_game_over = true
		emit_signal("time_up")

	_update_labels()

func set_total_mice(count: int):
	total_mice = count
	_update_labels()

func add_kill():
	killed_mice += 1
	_update_labels()

	if killed_mice >= total_mice and not is_game_over:
		is_game_over = true
		emit_signal("all_mice_killed")

func _update_labels():
	if kill_label:
		kill_label.text = "Мышей убито: %d / %d" % [killed_mice, total_mice]
	if timer_label:
		timer_label.text = "Время: %.1f сек" % remaining_time
