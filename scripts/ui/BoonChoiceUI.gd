extends Control

@onready var hbox: HBoxContainer = $HBox

signal choice_made(index)

func _ready():
	# populate three cards
	for i in range(3):
		var card = preload("res://scripts/ui/BoonCard.gd").new()
		card.title = "Option %d".format(i+1)
		card.description = "some boon text here"
		card.rect_min_size = Vector2(260, 420)
		card.connect("pressed", Callable(self, "_on_card_pressed"), [i])
		hbox.add_child(card)

func _on_card_pressed(idx):
	emit_signal("choice_made", idx)