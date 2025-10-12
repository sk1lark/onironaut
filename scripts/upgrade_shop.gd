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
	# start disabled until a selection is made (unless manager missing handled elsewhere)
	continue_button.disabled = true

func update_header():
	if upgrade_manager:
		fragments_label.text = "dream fragments: %d" % upgrade_manager.dream_fragments

		var stats = "runs: %d | highest wave: %d | best combo: %d" % [
			upgrade_manager.total_runs,
			upgrade_manager.highest_wave,
			upgrade_manager.highest_combo
		]
		stats_label.text = stats
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
		label.text = "upgrade manager missing"
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

func create_upgrade_button(upgrade_key: String) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var button = Button.new()
	button.custom_minimum_size = Vector2(700, 60)

	# load monogram font
	var monogram_font = load("res://fonts/monogram-extended.ttf")

	# get upgrade info
	var info = upgrade_manager.UPGRADE_INFO[upgrade_key]
	var level = upgrade_manager.upgrades[upgrade_key]
	var cost = upgrade_manager.get_upgrade_cost(upgrade_key)
	var is_maxed = upgrade_manager.is_upgrade_maxed(upgrade_key)

	# build button text
	var button_text = info["name"]

	if is_maxed:
		button_text += " [maxed]"
		button.disabled = true
	else:
		button_text += " [lv %d] - %d fragments" % [level + 1, cost]

		if not upgrade_manager.can_afford_upgrade(upgrade_key):
			button.disabled = true

	button.text = button_text
	button.add_theme_font_override("font", monogram_font)
	button.add_theme_font_size_override("font_size", 28)

	# description label
	var desc_label = Label.new()
	desc_label.text = "  %s" % info["desc"]
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.add_theme_font_override("font", monogram_font)
	desc_label.add_theme_font_size_override("font_size", 22)

	if level > 0:
		desc_label.text += " (current: +%s)" % str(upgrade_manager.get_upgrade_value(upgrade_key))

	# connect button to selection handler (do not auto-purchase)
	button.pressed.connect(_on_upgrade_selected.bind(upgrade_key, button))
	# prevent keyboard/gamepad focus auto-activating the first button
	button.focus_mode = Control.FOCUS_NONE

	container.add_child(button)
	container.add_child(desc_label)

	# style button
	style_button(button)

	return container

func style_button(button: Button) -> Dictionary:
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color.BLACK
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color.WHITE

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.1, 0.1, 0.1)
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color.WHITE

	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.05, 0.05, 0.05)
	disabled_style.border_width_left = 2
	disabled_style.border_width_right = 2
	disabled_style.border_width_top = 2
	disabled_style.border_width_bottom = 2
	disabled_style.border_color = Color(0.3, 0.3, 0.3)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("disabled", disabled_style)

	return {"normal": normal_style, "hover": hover_style, "disabled": disabled_style}

func _apply_selection_style(button: Button):
	var selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.12, 0.12, 0.12)
	selected_style.border_width_left = 2
	selected_style.border_width_right = 2
	selected_style.border_width_top = 2
	selected_style.border_width_bottom = 2
	selected_style.border_color = Color(1, 0.9, 0.5)

	button.add_theme_stylebox_override("normal", selected_style)

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
			# restore original style if available
			var orig = selected_button.get_meta("orig_normal_style")
			if orig:
				selected_button.add_theme_stylebox_override("normal", orig)
			selected_button = null
			selected_key = ""
			if continue_button:
				continue_button.disabled = true
		return

	# deselect previous
	if selected_button:
		var prev_orig = selected_button.get_meta("orig_normal_style")
		if prev_orig:
			selected_button.add_theme_stylebox_override("normal", prev_orig)

	# select new
	selected_button = button
	selected_key = upgrade_key
	# store original style for restoration
	var current_normal = button.get_theme_stylebox("normal")
	if current_normal:
		button.set_meta("orig_normal_style", current_normal)

	_apply_selection_style(button)

	# enable continue only if affordable (guard against race or state mismatch)
	var affordable = true
	if upgrade_manager:
		affordable = upgrade_manager.can_afford_upgrade(selected_key)

	if continue_button:
		continue_button.disabled = not affordable

	print("[upgrade_shop] selected=", selected_key, " affordable=", affordable)

func _on_continue_pressed():
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
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		print("[upgrade_shop] purchase failed (unexpected):", selected_key)
		SoundManager.play_hurt()
