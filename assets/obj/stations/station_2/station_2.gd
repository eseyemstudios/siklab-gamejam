extends Area2D

var _is_inside: bool = false
var _is_console_open: bool = false

var is_doing: bool = false # Know if the player has opened the UI.
@export var can_interacted: bool = false

signal success
signal failed

# Interaction.
func _input(event: InputEvent) -> void:
	if can_interacted:
		if event is InputEventKey and event.keycode == KEY_E and event.pressed:
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
		_leave()
		if can_interacted:
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
			await $task/ui_panel/ui_panel_animation.animation_finished

# Main logic.
var _current_button: int = 0

func _ready() -> void:
	$task/ui_panel/button.connect("pressed", Callable(self, "_button_pressed").bind(1))
	$task/ui_panel/button_2.connect("pressed", Callable(self, "_button_pressed").bind(2))
	$task/ui_panel/button_3.connect("pressed", Callable(self, "_button_pressed").bind(3))

func _randomize_button() -> void:
	randomize()
	var _time: float = randf_range(2, 3)
	_current_button = randi_range(1, 3)
	
	$timer.start(_time)
	
	$task/ui_panel/ui_screen/circles_1.frame = 0
	$task/ui_panel/ui_screen/circles_2.frame = 0
	$task/ui_panel/ui_screen/circles_3.frame = 0
	
	get_node("task/ui_panel/ui_screen/circles_" + str(_current_button)).frame = 1
	$task/ui_panel/ui_screen/progress_bar.max_value = _time

func _button_pressed(_id: int) -> void:
	if is_doing:
		if _id == _current_button:
			$timer.stop()
			success.emit()
			_leave()
		else:
			if $task/ui_panel/ui_panel_animation.is_playing():
				await $task/ui_panel/ui_panel_animation.animation_finished
			$task/ui_panel/ui_panel_animation.play("shake")
			_randomize_button()
			failed.emit()

func _physics_process(_delta: float) -> void:
	if is_doing:
		$task/ui_panel/ui_screen/progress_bar.value = $timer.time_left
		$fx/vignette.self_modulate.a = remap($timer.time_left, $task/ui_panel/ui_screen/progress_bar.max_value, 0.0, 0.0, 1.0)
	else:
		create_tween().tween_property($fx/vignette, "self_modulate:a", 0.0, 0.5)

func _on_timer_timeout() -> void:
	if is_doing:
		$task/ui_panel/ui_panel_animation.play("shake")
		_randomize_button()
		failed.emit()
