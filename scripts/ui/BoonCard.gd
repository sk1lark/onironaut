extends Control

# Simple 1-bit art card drawn procedurally. Not ascii — draws blocky glyphs using rectangles.
# Exposes a 'title' and 'description' and a 'selected' state for highlighting.

@export var title: String = "Boon"
@export var description: String = "Do something cool"
@export var selected: bool = false
@export var accent_color: Color = Color(1,1,1)

func _ready():
	set_process(true)

	# Create title and description labels so text renders reliably (avoid draw_string usage)
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.anchor_left = 0
	title_label.anchor_top = 0
	title_label.anchor_right = 1
	title_label.margin_left = 12
	title_label.margin_right = 12
	add_child(title_label)

	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = description
	desc_label.anchor_left = 0
	desc_label.anchor_right = 1
	desc_label.margin_left = 12
	desc_label.margin_right = 12
	add_child(desc_label)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("pressed")

signal pressed

func _draw():
	var r = Rect2(Vector2.ZERO, rect_size)
	# Background (black)
	draw_rect(r, Color(0,0,0))
	# Border
	draw_rect(r.grow(-4), Color(0,0,0), false, 2)
	# Inner white panel
	var inner = r.grow(-10)
	draw_rect(inner, Color(0.05,0.05,0.05))

	# Draw 1-bit glyph (blocky) at top center
	var glyph_w = inner.size.x * 0.6
	var glyph_h = inner.size.y * 0.45
	var glyph_rect = Rect2(inner.position + Vector2((inner.size.x - glyph_w)/2, 12), Vector2(glyph_w, glyph_h))
	_draw_blocky_glyph(glyph_rect)

	# Position labels (if present)
	var tl = $TitleLabel if has_node("TitleLabel") else null
	var dl = $DescLabel if has_node("DescLabel") else null
	if tl:
		tl.margin_top = int(glyph_rect.position.y + glyph_rect.size.y + 6)
	if dl:
		dl.margin_top = int(glyph_rect.position.y + glyph_rect.size.y + 30)

func _draw_blocky_glyph(r: Rect2):
	# A simple grid of blocks to draw a pseudo-icon
	var cols = 6
	var rows = 8
	var cell = Vector2(r.size.x/cols, r.size.y/rows)
	var pad = 2
	for y in range(rows):
		for x in range(cols):
			var v = randf()
			if (x + y) % 2 == 0:
				draw_rect(Rect2(r.position + Vector2(x*cell.x + pad, y*cell.y + pad), cell - Vector2(pad*2, pad*2)), Color(0.9,0.9,0.9))
*** End Patch