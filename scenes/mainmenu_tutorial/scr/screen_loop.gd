extends Label

var texts: Array = [
	"Obey",
	"Conform",
	"Routine",
	"Serve",
	"Comply",
	"Yield",
	"Follow",
	"Oblige",
	"Abide"
]
func _on_text_animation_animation_finished(_anim_name: StringName) -> void:
	randomize()
	var prev: String = text
	var next: String = " "
	while true:
		next = texts.pick_random()
		if next != prev:
			text = next
			break
	
	$text_animation.play("loop")
