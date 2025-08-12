extends Node

var _tasklist: Array[Area2D] = []
var _current_task: Area2D = null
var _last_task: Area2D = null

var routine_task_count := 0
const MAX_TASKS := 10

@onready var _env: Environment = $world_environment.environment

func _ready() -> void:
	for _task in $objects/physics/stations.get_children():
		if _task is Area2D:
			_tasklist.append(_task)
			_task.connect("success", Callable(self, "_on_task_success"))
			_task.connect("failed", Callable(self, "_on_task_failed"))
	
	$objects/physics/camera.start_watching($objects/physics/player)
	_shuffle_task_positions()
	_select_task()

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

#---------------------------------------------------------------
func _on_task_success() -> void:
	$objects/physics/camera.finish_task()
	routine_task_count = clamp(routine_task_count + 1, 0, MAX_TASKS)
	_update_saturation()
	_select_task()

func _on_task_failed() -> void:
	if $objects/physics/camera.state == $objects/physics/camera.CameraState.PATROL:
		$objects/physics/camera.start_watching($objects/physics/player)
	elif $objects/physics/camera.state == $objects/physics/camera.CameraState.WATCH:
		print("Warning")
	
	routine_task_count = clamp(routine_task_count - 1, 0, MAX_TASKS)
	_update_saturation()

#---------------------------------------------------------------

func _update_saturation() -> void:
	var t = float(routine_task_count) / MAX_TASKS
	_env.adjustment_enabled = true
	_env.adjustment_saturation = lerp(1.0, 0.0, t)
	_env.adjustment_brightness = lerp(1.0, 0.0, t)
