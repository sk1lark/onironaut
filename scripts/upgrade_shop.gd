# upgrade_shop.gd
extends Control

@onready var fragments_label = $Content/Header/FragmentsLabel
@onready var stats_label = $Content/Header/StatsLabel
@onready var upgrade_container = $Content/ScrollContainer/UpgradeContainer
@onready var continue_button = $Content/ContinueButton

var upgrade_manager: Node
var selected_key: String = ""
var selected_button: Button = null

func _ready():
	# Start menu music
	SoundManager.start_menu_music()

	# get upgrade manager singleton
	upgrade_manager = get_node_or_null("/root/UpgradeManager")
	if not upgrade_manager:
		print("[upgrade_shop] Warning: UpgradeManager not found at /root/UpgradeManager")

	# setup ui
	update_header()
	populate_upgrades()

	# setup continue button
	style_button(continue_button)
	continue_button.pressed.connect(_on_continue_pressed)

	# Check if player can afford ANY upgrade
	var can_afford_any = false
	if upgrade_manager:
		for upgrade_key in upgrade_manager.upgrades.keys():
			if upgrade_manager.can_afford_upgrade(upgrade_key):
				can_afford_any = true
				break

	# If can't afford anything, enable skip. Otherwise require selection
	if not can_afford_any:
		continue_button.disabled = false
		continue_button.text = "skip (too broke)".to_lower()
	else:
		continue_button.disabled = true
		continue_button.text = "enter the dream".to_lower()

func update_header():
	if upgrade_manager:
		fragments_label.text = "dream fragments: %d" % upgrade_manager.dream_fragments

		stats_label.text = "runs: %d | highest wave: %d | best combo: %d" % [
			upgrade_manager.total_runs,
			upgrade_manager.highest_wave,
			upgrade_manager.highest_combo
		]
	else:
		# Fallback UI when UpgradeManager is missing
		fragments_label.text = "dream fragments: 0"
		stats_label.text = "runs: 0 | highest wave: 1 | best combo: 0"
		# Disable continue to prevent entering gameplay without manager
		if continue_button:
			continue_button.disabled = true

func populate_upgrades():
	# clear existing children
	for child in upgrade_container.get_children():
		child.queue_free()

	# clear any previous selection since we're rebuilding the list
	selected_key = ""
	selected_button = null

	# start with continue disabled until player explicitly selects an upgrade
	if continue_button:
		continue_button.disabled = true

	# create upgrade buttons (guard missing manager)
	if not upgrade_manager:
		var label = Label.new()
		label.text = "upgrade manager missing".to_lower()
		label.add_theme_font_override("font", load("res://fonts/monogram-extended.ttf"))
		label.add_theme_font_size_override("font_size", 20)
		upgrade_container.add_child(label)
		return

	for upgrade_key in upgrade_manager.upgrades.keys():
		var upgrade_button = create_upgrade_button(upgrade_key)
		upgrade_container.add_child(upgrade_button)

	# debug: list upgrade states
	print("[upgrade_shop] populate_upgrades: available fragments=", upgrade_manager.dream_fragments)
	for k in upgrade_manager.upgrades.keys():
		var cost = upgrade_manager.get_upgrade_cost(k)
		var can_afford = upgrade_manager.can_afford_upgrade(k)
		var maxed = upgrade_manager.is_upgrade_maxed(k)
		print("[upgrade_shop] ", k, " cost=", cost, " afford=", can_afford, " maxed=", maxed)

	print("[upgrade_shop] post-populate selected_key=", selected_key)

func create_upgrade_button(upgrade_key: String) -> Control:
	# card container (acts like a card frame) - BIGGER
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 280)
	card.add_theme_constant_override("separation", 12)

	# inner layout with padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	# top: icon placeholder with clean design
	var icon_rect = ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(188, 100)
	icon_rect.color = Color(0.15, 0.15, 0.15)  # dark icon area
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_rect)

	# divider line
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(188, 2)
	divider.color = Color(0.2, 0.2, 0.2)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(divider)

	# text area
	var text_box = VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(188, 120)
	text_box.add_theme_constant_override("separation", 8)

	# load monogram font
	var monogram_font = load("res://fonts/monogram-extended.ttf")

	# get upgrade info
	var info = upgrade_manager.UPGRADE_INFO[upgrade_key]
	var level = upgrade_manager.upgrades[upgrade_key]
	var cost = upgrade_manager.get_upgrade_cost(upgrade_key)
	var is_maxed = upgrade_manager.is_upgrade_maxed(upgrade_key)

	var title = Label.new()
	title.text = info["name"].to_upper()
	title.add_theme_font_override("font", monogram_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(title)

	var desc = Label.new()
	desc.text = info["desc"]
	desc.add_theme_font_override("font", monogram_font)
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(desc)

	# spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	text_box.add_child(spacer)

	var footer = Label.new()
	if is_maxed:
		footer.text = "★ MAXED OUT ★"
		footer.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		footer.text = "LEVEL %d → %d FRAGMENTS" % [level + 1, cost]
		footer.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	footer.add_theme_font_override("font", monogram_font)
	footer.add_theme_font_size_override("font_size", 20)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_box.add_child(footer)

	vbox.add_child(text_box)
	margin.add_child(vbox)
	card.add_child(margin)

	# style the card with clean modern design
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.95)
	style.border_color = Color(0.1, 0.1, 0.1)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	# Bigger shadow for more depth
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	style.shadow_offset = Vector2(4, 4)
	card.add_theme_stylebox_override("panel", style)

	# make the whole card clickable: add a transparent button overlay
	var overlay = Button.new()
	overlay.text = ""
	overlay.flat = true
	overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.custom_minimum_size = Vector2(220, 280)
	overlay.focus_mode = Control.FOCUS_NONE

	# Check affordability and disable if can't afford or maxed
	var can_afford = upgrade_manager.can_afford_upgrade(upgrade_key)
	var is_affordable = can_afford and not is_maxed
	overlay.disabled = not is_affordable

	# Store references for later updates
	card.set_meta("overlay_button", overlay)
	card.set_meta("upgrade_key", upgrade_key)
	card.set_meta("card_style", style)

	# Grey out the card if unaffordable with opacity
	if not is_affordable:
		style.bg_color = Color(0.5, 0.5, 0.5)
		style.border_color = Color(0.3, 0.3, 0.3)
		icon_rect.color = Color(0.35, 0.35, 0.35)
		divider.color = Color(0.4, 0.4, 0.4)
		title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		desc.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		footer.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		# Add "LOCKED" overlay
		var locked_label = Label.new()
		locked_label.text = "X LOCKED"
		locked_label.add_theme_font_override("font", monogram_font)
		locked_label.add_theme_font_size_override("font_size", 32)
		locked_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		locked_label.position = Vector2(50, 100)
		locked_label.size = Vector2(120, 80)
		locked_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(locked_label)

	overlay.connect("pressed", Callable(self, "_on_upgrade_button_pressed").bind(upgrade_key, overlay, card))
	card.add_child(overlay)

	return card

func style_button(button: Button) -> Dictionary:
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color.WHITE
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color.BLACK
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.9, 0.9, 0.9)
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color.BLACK
	hover_style.corner_radius_top_left = 10
	hover_style.corner_radius_top_right = 10
	hover_style.corner_radius_bottom_left = 10
	hover_style.corner_radius_bottom_right = 10

	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.7, 0.7, 0.7)
	disabled_style.border_width_left = 2
	disabled_style.border_width_right = 2
	disabled_style.border_width_top = 2
	disabled_style.border_width_bottom = 2
	disabled_style.border_color = Color(0.5, 0.5, 0.5)
	disabled_style.corner_radius_top_left = 10
	disabled_style.corner_radius_top_right = 10
	disabled_style.corner_radius_bottom_left = 10
	disabled_style.corner_radius_bottom_right = 10

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

	return {"normal": normal_style, "hover": hover_style, "disabled": disabled_style}

func _apply_selection_style(_button: Button):
	# no-op — simplified selection UI
	return

func _on_upgrade_pressed(upgrade_key: String, _container: Control):
	if upgrade_manager.purchase_upgrade(upgrade_key):
		SoundManager.play_dealt()
		update_header()
		populate_upgrades()  # refresh all buttons
	else:
		SoundManager.play_hurt()

func _on_upgrade_selected(upgrade_key: String, button: Button):
	# ignore selecting disabled buttons
	if button.disabled:
		SoundManager.play_hurt()
		return

	# if clicking the already-selected button, toggle off
	if selected_button == button:
		# deselect
		if selected_button:
			# restore original style if available (guarded)
			if selected_button.has_meta("orig_normal_style"):
				var orig = selected_button.get_meta("orig_normal_style")
				if orig:
					selected_button.add_theme_stylebox_override("normal", orig)
				selected_button.remove_meta("orig_normal_style")
			selected_button = null
			selected_key = ""
			if continue_button:
				continue_button.disabled = true
		return

	# deselect previous (toggle previous container's sel_label)
	if selected_button:
		var prev_container = selected_button.get_parent()
		if prev_container:
			if prev_container.has_meta("sel_label"):
				var prev_sel = prev_container.get_meta("sel_label")
				if prev_sel:
					prev_sel.visible = false

	# select new
	selected_button = button
	selected_key = upgrade_key

	# show selection indicator on this button's container
	var this_container = button.get_parent()
	if this_container:
		if this_container.has_meta("sel_label"):
			var this_sel = this_container.get_meta("sel_label")
			if this_sel:
				this_sel.visible = true

	# enable continue only if affordable (guard against race or state mismatch)
	var affordable = true
	if upgrade_manager:
		affordable = upgrade_manager.can_afford_upgrade(selected_key)

	if continue_button:
		continue_button.disabled = not affordable

	print("[upgrade_shop] selected=", selected_key, " affordable=", affordable)

func _on_upgrade_button_pressed(upgrade_key: String, button: Button, card: Control) -> void:
	# Don't allow selecting disabled buttons
	if button.disabled:
		SoundManager.play_hurt()
		return

	# Deselect previous card
	if selected_button and selected_button != button:
		var prev_card = selected_button.get_parent()
		if prev_card and prev_card.has_meta("card_style"):
			var prev_style = prev_card.get_meta("card_style")
			prev_style.bg_color = Color(0.95, 0.95, 0.95)
			prev_style.border_color = Color(0.1, 0.1, 0.1)
			prev_style.border_width_left = 4
			prev_style.border_width_right = 4
			prev_style.border_width_top = 4
			prev_style.border_width_bottom = 4
			prev_style.shadow_size = 8
			prev_style.shadow_offset = Vector2(4, 4)

	# Select this card
	selected_button = button
	selected_key = upgrade_key

	# Highlight the selected card with white background and thicker border
	if card.has_meta("card_style"):
		var card_style = card.get_meta("card_style")
		card_style.bg_color = Color(1.0, 1.0, 1.0)  # pure white when selected
		card_style.border_color = Color(0, 0, 0)
		card_style.border_width_left = 6
		card_style.border_width_right = 6
		card_style.border_width_top = 6
		card_style.border_width_bottom = 6
		card_style.shadow_size = 12
		card_style.shadow_offset = Vector2(6, 6)

	SoundManager.play_dealt()

	if continue_button:
		continue_button.disabled = false

func _on_continue_pressed():
	# Check if player can afford anything
	var can_afford_any = false
	if upgrade_manager:
		for upgrade_key in upgrade_manager.upgrades.keys():
			if upgrade_manager.can_afford_upgrade(upgrade_key):
				can_afford_any = true
				break

	# If can't afford anything, allow skip without selection
	if not can_afford_any:
		print("[upgrade_shop] skipping - player can't afford anything")
		SoundManager.play_dealt()
		# If this shop was presented as an in-scene modal (child of main), just close it so main resumes
		if get_parent() != null:
			queue_free()
		else:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		return

	# Only proceed if an upgrade has been explicitly selected
	if not selected_key or selected_key == "":
		SoundManager.play_hurt()
		return

	print("[upgrade_shop] continue pressed. attempting purchase of:", selected_key)

	# attempt purchase
	if not upgrade_manager:
		print("[upgrade_shop] ERROR: UpgradeManager missing on continue")
		SoundManager.play_hurt()
		return

	if not upgrade_manager.can_afford_upgrade(selected_key):
		print("[upgrade_shop] cannot afford selected upgrade:", selected_key)
		SoundManager.play_hurt()
		# Flash screen red and show message
		var flash_rect = ColorRect.new()
		flash_rect.color = Color(1, 0, 0, 0.5)  # red overlay
		flash_rect.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
		flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # don't block input!
		add_child(flash_rect)

		var message_label = Label.new()
		message_label.text = "you cannot afford that".to_lower()
		message_label.add_theme_font_override("font", load("res://fonts/monogram-extended.ttf"))
		message_label.add_theme_font_size_override("font_size", 48)
		message_label.add_theme_color_override("font_color", Color.WHITE)
		message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		message_label.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
		message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # don't block input!
		add_child(message_label)

		await get_tree().create_timer(0.6).timeout
		flash_rect.queue_free()
		message_label.queue_free()
		# keep the shop open for the player to select a different option
		return

	if upgrade_manager.purchase_upgrade(selected_key):
		print("[upgrade_shop] purchase success:", selected_key)
		SoundManager.play_dealt()
		update_header()
		# clear selection and refresh
		selected_key = ""
		selected_button = null
		populate_upgrades()
		# Close shop if this was a modal; otherwise change scene back to main
		if get_parent() != null:
			queue_free()
		else:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		print("[upgrade_shop] purchase failed (unexpected):", selected_key)
		SoundManager.play_hurt()

# removed debug gui_input handler
