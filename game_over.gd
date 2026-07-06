extends ColorRect

func _ready():
	hide()
	Events.winner.connect(on_winner)


func on_winner(area):
	show()
	$Label.text = "Player " + str(area.get_parent().player) + " wins!"

func _input(event):
	if event.is_action_pressed("one_player") || event.is_action_pressed("two_player"):
		get_tree().reload_current_scene()
