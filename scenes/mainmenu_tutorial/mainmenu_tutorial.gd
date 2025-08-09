extends Node

# This triggers when logo intro finishes.
func _on_logo_animation_animation_finished(anim_name: StringName) -> void:
	# Simple check.
	if anim_name == "intro":
		# Do stuff. Mostly the showing of buttons for menu or something.
		pass
