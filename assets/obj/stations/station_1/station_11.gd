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

# Interaction.
func _input(_event: InputEvent) -> void:
	if can_interacted:
		if Input.is_action_just_pressed("interact"):
			if _is_inside:
				_is_console_open = not _is_console_open
				if _is_console_open:
					$task/ui_panel/ui_panel_animation.play("intro")
					_create_timer()
					_randomize_order()
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
		_player_button_order.clear()
		
		if _is_console_open:
			_is_console_open = false
			if $task/ui_panel/ui_panel_animation.is_playing():
				await $task/ui_panel/ui_panel_animation.animation_finished
			$task/ui_panel/ui_panel_animation.play_backwards("intro")
			
			# Play the backward interact animation once here
			$e/interact_animation.play_backwards("interact")
			
			await $task/ui_panel/ui_panel_animation.animation_finished
			_untoggle_btns()

# Main logic.
# ----
var _correct_button_order: Array = [1, 2, 3, 4]
var _player_button_order: Array = []

func _ready() -> void:
	# Connect the levers.
	$task/ui_panel/lever.connect("toggled", Callable(self, "_lever_toggled").bind(1, $task/ui_panel/lever))
	$task/ui_panel/lever_2.connect("toggled", Callable(self, "_lever_toggled").bind(2, $task/ui_panel/lever_2))
	$task/ui_panel/lever_3.connect("toggled", Callable(self, "_lever_toggled").bind(3, $task/ui_panel/lever_3))
	$task/ui_panel/lever_4.connect("toggled", Callable(self, "_lever_toggled").bind(4, $task/ui_panel/lever_4))
	
	# Randomize.
	_randomize_order()

func _randomize_order() -> void:
	_correct_button_order.shuffle()
	_player_button_order.clear()
	$task/ui_panel/ui_screen/order.text = str(_correct_button_order[0]) + " " + str(_correct_button_order[1]) + " " + str(_correct_button_order[2]) + " " + str(_correct_button_order[3]) 

func _untoggle_btns() -> void:
	$task/ui_panel/lever.button_pressed = false
	$task/ui_panel/lever_2.button_pressed = false
	$task/ui_panel/lever_3.button_pressed = false
	$task/ui_panel/lever_4.button_pressed = false
	
	$task/ui_panel/lever.disabled = false
	$task/ui_panel/lever_2.disabled = false
	$task/ui_panel/lever_3.disabled = false
	$task/ui_panel/lever_4.disabled = false

func _lever_toggled(_toggled: bool, _identifier: int, _button: TextureButton) -> void:
	if is_doing and not _handling_fail:
		if _toggled:
			$click.play()
			_player_button_order.append(_identifier)
			_button.disabled = true
		if _player_button_order.size() >= 4:
			if _player_button_order == _correct_button_order:
				$timer.stop()
				success.emit()
				_leave()
			else:
				_handling_fail = true
				$buzzer.play()
				_untoggle_btns()
				if $task/ui_panel/ui_panel_animation.is_playing():
					await $task/ui_panel/ui_panel_animation.animation_finished
				$task/ui_panel/ui_panel_animation.play("shake")
				failed.emit()
				_fail_count += 1
				if _fail_count >= _max_failures:
					_break_console()
				else:
					_create_timer()
					_randomize_order()
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

func _create_timer() -> void:
	randomize()
	var _time: float = randf_range(3.0, 5.0)

	if $timer.is_stopped() == false:
		$timer.stop()
		
	$timer.start(_time)
	
	$task/ui_panel/ui_screen/progress_bar.max_value = _time

func _physics_process(_delta: float) -> void:
	if is_doing:
		$task/ui_panel/ui_screen/progress_bar.value = $timer.time_left
		$fx/vignette.self_modulate.a = remap($timer.time_left, $task/ui_panel/ui_screen/progress_bar.max_value, 0.0, 0.0, 1.0)
	else:
		create_tween().tween_property($fx/vignette, "self_modulate:a", 0.0, 0.5)

func _on_timer_timeout() -> void:
	if is_doing and not _handling_fail:
		_handling_fail = true
		_untoggle_btns()
		$task/ui_panel/ui_panel_animation.play("shake")
		failed.emit()
		_fail_count += 1
		if _fail_count >= _max_failures:
			_break_console()
		else:
			_create_timer()
			_randomize_order()
			$buzzer.play()
		_handling_fail = false
