extends Label

func _ready() -> void:
	self_modulate = Color.TRANSPARENT
	Events.show_reset_label.connect(show_or_hide.bind(true))
	Events.hide_reset_label.connect(show_or_hide.bind(false))
	
func show_or_hide(player, v):
	if player - 1 == get_index():
		self_modulate = Color.WHITE if v else Color.TRANSPARENT
