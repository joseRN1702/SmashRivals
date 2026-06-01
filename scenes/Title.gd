extends Label

func _ready():
	pivot_offset = size / 2  # centraliza o pivot
	_start_pulse()

func _start_pulse():
	var tween = create_tween()
	tween.set_loops()  # loop infinito
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.8)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.8)
