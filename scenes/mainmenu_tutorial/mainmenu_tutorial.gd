extends Node

var _count: int = 0
var _deviated: bool = false
var _tut_levers_enabled = false

# This triggers when logo intro finishes.
func _on_logo_animation_animation_finished(_anim_name: StringName) -> void:
	# Reparents the camera to the player.
	$camera.reparent($objects/physics/player)
	$objects/environment/foreground/walkways.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Plays the UI Panel with start buttons.
	$gui/menu/ui_panel/ui_panel_animation.play("intro")

func _on_play_pressed() -> void:
	# Play backwards (The UI Animation).
	$gui/menu/ui_panel/ui_panel_animation.play_backwards("intro")
	$gui/menu/ui_panel/ui_screen/screen_text/text_animation.stop(false)
	
	# Gameplay related stuff.
	$gui/gameplay/dialog_fade.connect("next", Callable(self, "_tutorial_manager")) # Connect skip button.
	_tutorial_manager()

# Tutorial function helper.
# If you want how the dialog and stuff are activated, you can look at the "game_animation" node.
# Timing-based calls are located in its keyframes.
# Inanimatable calls are coded here.
func _tutorial_manager() -> void:
	# Sequence changes.
	if _count == 0: 
		create_tween().tween_property($gui/logo_sticky/logo_animation/main_pa, "volume_db", -40, 2)
	elif _count == 5:
		$objects/physics/player/button_animation.play("show_buttons")
		$objects/physics/player.can_move = true
	elif _count == 7:
		$objects/physics/tutorial/anchor/animation_player.play("walk")
	elif _count == 9:
		$objects/physics/player.can_move = false
	
	# Animate.
	var _next_animation: String = "tutorial_" + str(_count)
	if $game_animation.has_animation(_next_animation):
		$game_animation.play(_next_animation)
		_count += 1

# If player deviates from the highlight.
func _on_checker_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if _count == 6:
			_tutorial_manager()

func _on_checker_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and _count > 7:
		_deviated = true
		$game_animation.play("deviation")

func _reset():
	$objects/physics/tutorial/anchor/animation_player.play("RESET")
	$gui/gameplay/dialog_fade/dialog_animation.play_backwards("show_dialog")
	_count = 6
	$objects/physics/player.position = Vector2(303, 459)
	_deviated = false

func _on_walking_animation_finished(_anim_name: StringName) -> void:
	if _count == 8 and not _deviated:
		_tutorial_manager()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E:
		if _count == 10 and not _deviated:
			_count += 1
			_tutorial_manager()

func _physics_process(_delta: float) -> void:
	if _count == 13:
		_tut_levers_enabled = $gui/task/ui_panel/lever.button_pressed and $gui/task/ui_panel/lever_2.button_pressed and $gui/task/ui_panel/lever_3.button_pressed and $gui/task/ui_panel/lever_4.button_pressed
		if _tut_levers_enabled:
			_tutorial_manager()

func change_to_main() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_about_pressed() -> void:
	$gui/menu/ui_panel/about.disabled = true
	$gui/menu/ui_panel/play.disabled = true
	var _tween: Tween = create_tween()
	_tween.tween_property($gui/fx/fade, "color", Color.html("F5F5F5"), 3)
	await _tween.finished
	get_tree().change_scene_to_file("res://scenes/mainmenu_tutorial/about_us.tscn")
