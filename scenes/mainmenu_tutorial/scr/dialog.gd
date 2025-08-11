extends TextureRect

var _skipped: bool = false
signal next

func dialog(message: String) -> void:
	_skipped = false
	$dialog.text = message
	$dialog_animation.play("show_dialog")

func _on_skip_pressed() -> void:
	if not _skipped:
		_skipped = true
		$dialog_animation.play_backwards("show_dialog")
		next.emit()
