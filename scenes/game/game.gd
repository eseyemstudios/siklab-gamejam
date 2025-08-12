extends Node

var _tasklist: Array[Area2D] = []
var _current_task: Area2D = null
var _last_task: Area2D = null

func _ready() -> void:
	for _task in $objects/physics/stations.get_children():
		_tasklist.append(_task)
		_task.connect("success", Callable(self, "_on_task_success"))
		_task.connect("failed", Callable(self, "_on_task_failed"))
	
	_select_task()

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
	print("Task succeeded")
	_select_task()

func _on_task_failed() -> void:
	print("Task failed")
