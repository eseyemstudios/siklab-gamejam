extends Node

# This triggers when logo intro finishes.
func _on_logo_animation_animation_finished(_anim_name: StringName) -> void:
	# Reparents the camera to the player.
	$camera.reparent($objects/physics/player)
	
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
var _count: int = 0
func _tutorial_manager() -> void:
	# Sequence changes.
	if _count == 0: 
		create_tween().tween_property($gui/logo_sticky/logo_animation/main_pa, "volume_db", -20, 2)
	
	# Animate.
	$game_animation.play("tutorial_" + str(_count))
	_count += 1
