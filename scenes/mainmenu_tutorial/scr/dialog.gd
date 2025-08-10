extends TextureRect

signal next

func dialog(message: String) -> void:
	$dialog.text = message
	$dialog_animation.play("show_dialog")

func _on_skip_pressed() -> void:
	$dialog_animation.play_backwards("show_dialog")
	next.emit()
