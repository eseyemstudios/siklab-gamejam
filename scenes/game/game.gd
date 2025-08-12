extends Node

var _tasklist: Array[Area2D] = []
var _current_task: Area2D = null
var _last_task: Area2D = null


const MAX_FAIL_BEFORE_CAUGHT := 3
const DEFIANCE_FAIL_THRESHOLD := 5
const MAX_TASKS := 10
var routine_task_count := 0
var fail_count := 0
var defiance_active := false

@onready var _env: Environment = $world_environment.environment

func _ready() -> void:
	for _task in $objects/physics/stations.get_children():
		if _task is Area2D:
			_tasklist.append(_task)
			_task.connect("success", Callable(self, "_on_task_success"))
			_task.connect("failed", Callable(self, "_on_task_failed"))
	
	$gui/gameplay/dialog_fade.connect("next", Callable(self, "_enable_movement"))
	
	$objects/physics/camera.start_watching($objects/physics/player)
	_shuffle_task_positions()
	_select_task()

func _enable_movement() -> void:
	$objects/physics/player.can_move = true

func _shuffle_task_positions() -> void:
	var positions := []
	for task in $objects/physics/stations.get_children():
		positions.append(task.position)
	
	positions.shuffle()
	
	for i in $objects/physics/stations.get_child_count():
		$objects/physics/stations.get_children()[i].position = positions[i]

func _select_task() -> void:
	if _current_task:
		_current_task.can_interacted = false
		_current_task.get_node("highlight").hide()
		_last_task = _current_task
	
	# Pick a new random task that is different from the last
	var new_task = _tasklist.pick_random()
	while new_task == _last_task and _tasklist.size() > 1:
		new_task = _tasklist.pick_random()
	
	_current_task = new_task
	_current_task.can_interacted = true
	_current_task.get_node("highlight").show()
	
	if _current_task.has_method("start_task"):
		_current_task.start_task(5.0)

func _on_task_success() -> void:
	$objects/physics/camera.finish_task()
	routine_task_count = clamp(routine_task_count + 1, 0, MAX_TASKS)
	fail_count = 0  # reset fail streak on success
	_update_saturation()

	if routine_task_count >= MAX_TASKS:
		_trigger_compliance_ending()
	else:
		_select_task()

func _on_task_failed() -> void:
	fail_count += 1
	
	var camera_state = $objects/physics/camera.state
	if camera_state == $objects/physics/camera.CameraState.PATROL:
		$objects/physics/camera.start_watching($objects/physics/player)
	elif camera_state == $objects/physics/camera.CameraState.WATCH:
		# Player caught by camera due to fail
		if fail_count >= MAX_FAIL_BEFORE_CAUGHT:
			_trigger_caught_ending()
	
	_update_saturation()
	routine_task_count = clamp(routine_task_count - 1, 0, MAX_TASKS)
	
	# Defiance condition: fails without being caught repeatedly
	if camera_state != $objects/physics/camera.CameraState.WATCH and fail_count >= DEFIANCE_FAIL_THRESHOLD and not defiance_active:
		defiance_active = true
		_trigger_defiance_ending()

func _update_saturation() -> void:
	var t = float(routine_task_count) / MAX_TASKS
	_env.adjustment_enabled = true
	_env.adjustment_saturation = lerp(1.0, 0.0, t)
	_env.adjustment_brightness = lerp(1.0, 0.0, t)

# Ending functions (implement these yourself)
func _trigger_compliance_ending() -> void:
	$game_animation.play("compliance")
	await $game_animation.animation_finished
	get_tree().change_scene_to_file("res://scenes/mainmenu_tutorial/mainmenu_tutorial.tscn")

func _trigger_caught_ending() -> void:
	print("Ending: Caught - Surveillance consumed you.")
	# TODO: show message, alarm sounds, end game

func _trigger_defiance_ending() -> void:
	print("Ending: Defiance - You broke the cycle!")
	# TODO: restore saturation, show message, play uplifting audio, end game
