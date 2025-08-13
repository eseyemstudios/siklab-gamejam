extends Node

var _paused: bool = false

# Tasks
var task_list: Array[Area2D] = []
var current_task: Area2D = null
var last_task: Area2D = null

# Task Fail
var decoy_active: bool = false

# Game settings.
const MAX_TASKS := 5                # Max successful routine tasks before losing (Monotony)
const MAX_FAIL_BEFORE_CAUGHT := 3    # Fails while under camera WATCH triggers Deviation

# States
var routine_task_count := 0           # Number of successful routine tasks
var fail_count := 0                   # Consecutive fails
var defiance_active := false

@onready var _env: Environment = $world_environment.environment

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		_pause()

func _ready() -> void:
	# Gather tasks
	for task in $objects/physics/stations.get_children():
		if task is Area2D:
			task_list.append(task)
			task.connect("success", Callable(self, "_on_task_success"))
			task.connect("failed", Callable(self, "_on_task_failed"))
			task.connect("broken", Callable(self, "_on_task_broken").bind(task))
	
	# Decoys
	for decoy in $objects/background/decoys.get_children():
		decoy.connect("decoy", Callable(self, "_on_decoy_activated").bind(decoy))

	# Unlock movement after intro/dialog
	$gui/gameplay/dialog_fade.connect("next", Callable(self, "_enable_movement"))

	$objects/physics/camera.start_watching($objects/physics/player)
	_shuffle_task_positions()
	_select_next_task()

# Movement
func _enable_movement() -> void:
	$objects/physics/player.can_move = true

# Random task positions
func _shuffle_task_positions() -> void:
	var positions := $objects/physics/stations.get_children().map(func(t): return t.position)
	positions.shuffle()
	
	for i in $objects/physics/stations.get_child_count():
		$objects/physics/stations.get_children()[i].position = positions[i]

# Select task.
func _select_next_task() -> void:
	if current_task:
		current_task.can_interacted = false
		current_task.get_node("highlight").hide()
		last_task = current_task
	
	# Pick a new task different from last
	var new_task = task_list.pick_random()
	while new_task == last_task and task_list.size() > 1:
		new_task = task_list.pick_random()
	
	current_task = new_task
	current_task.can_interacted = true
	current_task.get_node("highlight").show()

# Task success
func _on_task_success() -> void:
	$objects/physics/camera.finish_task()
	routine_task_count = clamp(routine_task_count + 1, 0, MAX_TASKS)
	fail_count = 0  # reset fail streak
	_update_saturation()

	# Lose by over-compliance (Monotony)
	if routine_task_count >= MAX_TASKS:
		_trigger_monotony()
	else:
		_select_next_task()

# Task Fail
func _on_task_failed() -> void:
	fail_count += 1
	var camera_state = $objects/physics/camera.state

	# Camera watching fail — skip if decoy is active
	if not decoy_active:
		if camera_state == $objects/physics/camera.CameraState.PATROL:
			$objects/physics/camera.start_watching($objects/physics/player)
		elif camera_state == $objects/physics/camera.CameraState.WATCH:
			if fail_count >= MAX_FAIL_BEFORE_CAUGHT:
				_trigger_deviation()

	_update_saturation()
	routine_task_count = clamp(routine_task_count - 1, 0, MAX_TASKS)

# Task broken
func _on_task_broken(task: Area2D) -> void:
	# Visual explode effect
	task.get_node("explosion").play()
	task_list.erase(task)
	
	if task_list.is_empty():
		_trigger_defiance()
	else:
		_select_next_task()


# Environment / Saturation Feedback
func _update_saturation() -> void:
	var t = float(routine_task_count) / MAX_TASKS
	_env.adjustment_enabled = true
	_env.adjustment_saturation = lerp(1.0, 0.0, t)
	_env.adjustment_brightness = lerp(1.0, 0.0, t)

# ENDINGS
func _trigger_monotony() -> void:
	$objects/physics/player.can_move = false
	$objects.set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	$game_animation.play("compliance")
	await $game_animation.animation_finished
	get_tree().change_scene_to_file("res://scenes/mainmenu_tutorial/mainmenu_tutorial.tscn")

func _trigger_deviation() -> void:
	$objects/physics/player.can_move = false
	$objects.set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	$game_animation.play("deviation")
	await $game_animation.animation_finished
	get_tree().change_scene_to_file("res://scenes/mainmenu_tutorial/mainmenu_tutorial.tscn")

func _trigger_defiance() -> void:
	$objects/physics/player.can_move = false
	$objects/physics/player.velocity = Vector2.ZERO
	$objects/physics/camera/main_camera/camera/detector.monitoring = false
	
	var _camera_tween: Tween = create_tween()
	_camera_tween.tween_property($objects/physics/player/camera, "global_position:x", 1915, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	_camera_tween.tween_property($objects/physics/camera/main_camera/camera, "rotation_degrees", 0, 1)
	
	await _camera_tween.finished
	$game_animation.play("defiance")
	await $game_animation.animation_finished
	get_tree().change_scene_to_file("res://scenes/mainmenu_tutorial/about_us.tscn")

# Decoys
func _on_decoy_activated(decoy: Area2D) -> void:
	decoy_active = true
	$objects/physics/camera.start_watching(decoy)
	$objects/physics/camera/main_camera/camera/detector.monitoring = false
	
	await get_tree().create_timer(5).timeout
	
	decoy_active = false
	$objects/physics/camera.finish_task()
	$objects/physics/camera/main_camera/camera/detector.monitoring = true

func _pause() -> void:
	_paused = !_paused
	if _paused:
		$pause_player.play("pause")
	else:
		$pause_player.play_backwards("pause")
	get_tree().paused = _paused

func _on_continue_pressed() -> void:
	_pause()

func _on_menu_pressed() -> void:
	$gui/fx/fade/paused/continue.disabled = true
	$gui/fx/fade/paused/menu.disabled = true
	$pause_player.play("to_menu")
	await $pause_player.animation_finished
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mainmenu_tutorial/mainmenu_tutorial.tscn")
