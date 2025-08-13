extends Area2D

var _is_inside: bool = false
var _is_console_open: bool = false

var is_doing: bool = false # Know if the player has opened the UI.
@export var can_interacted: bool = false

signal success
signal failed
signal broken

var _max_failures: int = 3
var _fail_count: int = 0
var _handling_fail: bool = false

# Main logic.
var _current_button: int = 0

func _input(_event: InputEvent) -> void:
	if can_interacted:
		if Input.is_action_just_pressed("interact"):
			if _is_inside:
				_is_console_open = not _is_console_open
				if _is_console_open:
					$task/ui_panel/ui_panel_animation.play("intro")
					_randomize_button()
					is_doing = true
				else:
					$task/ui_panel/ui_panel_animation.play_backwards("intro")
					is_doing = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_inside:
		if can_interacted:
			$e/interact_animation.play("interact")
		$tutorial_station.play("default")
		_is_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and _is_inside:
		# Only play interact backward if console is NOT already closed
		if _is_console_open:
			_leave()
		else:
			# If console already closed, just clean up _is_inside and animations
			if _is_console_open:
				$e/interact_animation.play_backwards("interact")
			$tutorial_station.play_backwards("default")
		
		_is_inside = false

func _leave() -> void:
	if _is_inside:
		is_doing = false
		if _is_console_open:
			_is_console_open = false
			if $task/ui_panel/ui_panel_animation.is_playing():
				await $task/ui_panel/ui_panel_animation.animation_finished
			$task/ui_panel/ui_panel_animation.play_backwards("intro")
			
			# Play the backward interact animation once here
			$e/interact_animation.play_backwards("interact")
			
			await $task/ui_panel/ui_panel_animation.animation_finished

func _ready() -> void:
	$task/ui_panel/button.connect("pressed", Callable(self, "_button_pressed").bind(1))
	$task/ui_panel/button_2.connect("pressed", Callable(self, "_button_pressed").bind(2))
	$task/ui_panel/button_3.connect("pressed", Callable(self, "_button_pressed").bind(3))

func _randomize_button() -> void:
	randomize()
	var _time: float = randf_range(2, 3)
	_current_button = randi_range(1, 3)

	if $timer.is_stopped() == false:
		$timer.stop()

	$timer.start(_time)

	$task/ui_panel/ui_screen/circles_1.frame = 0
	$task/ui_panel/ui_screen/circles_2.frame = 0
	$task/ui_panel/ui_screen/circles_3.frame = 0

	get_node("task/ui_panel/ui_screen/circles_" + str(_current_button)).frame = 1
	$task/ui_panel/ui_screen/progress_bar.max_value = _time

func _button_pressed(_id: int) -> void:
	if is_doing and not _handling_fail:
		if _id == _current_button:
			$timer.stop()
			success.emit()
			_leave()
		else:
			_handling_fail = true
			$buzzer.play()
			if $task/ui_panel/ui_panel_animation.is_playing():
				await $task/ui_panel/ui_panel_animation.animation_finished
			$task/ui_panel/ui_panel_animation.play("shake")
			failed.emit()
			_fail_count += 1
			if _fail_count >= _max_failures:
				_break_console()
			else:
				_randomize_button()
			_handling_fail = false

func _physics_process(_delta: float) -> void:
	if is_doing:
		$task/ui_panel/ui_screen/progress_bar.value = $timer.time_left
		$fx/vignette.self_modulate.a = remap($timer.time_left, $task/ui_panel/ui_screen/progress_bar.max_value, 0.0, 0.0, 1.0)
	else:
		create_tween().tween_property($fx/vignette, "self_modulate:a", 0.0, 0.5)

func _on_timer_timeout() -> void:
	if is_doing and not _handling_fail:
		_handling_fail = true
		$task/ui_panel/ui_panel_animation.play("shake")
		$buzzer.play()
		failed.emit()
		_fail_count += 1
		if _fail_count >= _max_failures:
			_break_console()
		else:
			_randomize_button()
		_handling_fail = false

func _break_console() -> void:
	can_interacted = false
	monitoring = false
	get_node("highlight").hide()
	broken.emit()
	$tutorial_station.play("broken")
	$destroy.play()
	await $tutorial_station.animation_finished
	$tutorial_station/particles.emitting = true
