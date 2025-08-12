extends Area2D

signal success
signal failed

var _is_inside: bool = false
var _is_active: bool = false
var can_interacted: bool = false

func start_task(duration: float) -> void:
	_is_active = true
	_is_inside = false
	$timer.wait_time = duration
	$timer.start()

	$task/progress_bar.max_value = duration
	$task/progress_bar.value = duration

	$task/ui_panel_animation.play("intro")
	set_physics_process(true)

func _on_body_entered(body: Node2D) -> void:
	if not _is_active:
		return
	if body.is_in_group("player"):
		_is_inside = true
		$timer.stop()
		$task/ui_panel_animation.play_backwards("intro")
		success.emit()
		_is_active = false
		set_physics_process(false)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_is_inside = false

func _physics_process(_delta: float) -> void:
	if _is_active and $timer.time_left > 0:
		$task/progress_bar.value = $timer.time_left
	elif _is_active and $timer.time_left <= 0:
		$task/ui_panel_animation.play_backwards("intro")
		failed.emit()
		_is_active = false
		set_physics_process(false)
