extends Control
class_name CardChoiceModal

signal card_chosen(card: CardData)

@onready var option_container: HBoxContainer = $Panel/VBox/Options
@onready var title_label: Label = $Panel/VBox/Title

var cards: Array[CardData] = []

func _ready():
    title_label.text = "choose a boon"
    for i in range(cards.size()):
        _add_card_option(i, cards[i])

    # keyboard shortcuts
    set_process_unhandled_input(true)

func _get_roman_numeral(num: int) -> String:
    match num:
        1: return "I"
        2: return "II"
        3: return "III"
        _: return str(num)

func _get_card_ascii_art(card: CardData) -> String:
    # Generate ASCII art based on card effect type
    var art = ""

    match card.effect:
        "typing_speed":
            # Lightning/Speed symbol
            art += "    ▲\n"
            art += "   ▲│▲\n"
            art += "  ▲ │ ▲\n"
            art += "    ▼\n"
            art += "   ▼ ▼\n"
        "damage_reduction":
            # Shield symbol
            art += "  ╔═══╗\n"
            art += "  ║ ◊ ║\n"
            art += "  ║ ◊ ║\n"
            art += "   ╚═╝\n"
            art += "    ▼\n"
        "health_regen":
            # Heart/Life symbol
            art += "  ♥   ♥\n"
            art += " ♥♥♥ ♥♥♥\n"
            art += "  ♥♥♥♥♥\n"
            art += "   ♥♥♥\n"
            art += "    ♥\n"
        "max_phantoms":
            # Multiple spirits
            art += "  ✧ ✧ ✧\n"
            art += "   ◊ ◊\n"
            art += "  ✧ ✧ ✧\n"
            art += "   ◊ ◊\n"
            art += "  ✧ ✧ ✧\n"
        "power_up_chance":
            # Fortune wheel
            art += "   ╔═╗\n"
            art += "  ╔╬═╬╗\n"
            art += "  ║ ✧ ║\n"
            art += "  ╚╬═╬╝\n"
            art += "   ╚═╝\n"
        _:
            # Default mystical symbol
            art += "    ✧\n"
            art += "   ◊◊◊\n"
            art += "  ◊ ★ ◊\n"
            art += "   ◊◊◊\n"
            art += "    ✧\n"

    return art

func _add_card_option(index: int, card: CardData):
    # Create card container - taller like tarot cards
    var card_container := Control.new()
    card_container.name = "Card_%d" % (index + 1)
    card_container.custom_minimum_size = Vector2(200, 360)
    card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card_container.mouse_filter = Control.MOUSE_FILTER_STOP

    var monogram_font = load("res://fonts/monogram-extended.ttf")

    # Background with ASCII border
    var bg := ColorRect.new()
    bg.color = Color.BLACK
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    card_container.add_child(bg)

    # Full card frame with double border like tarot cards
    var border := Label.new()
    border.set_anchors_preset(Control.PRESET_FULL_RECT)
    border.add_theme_font_override("font", monogram_font)
    border.add_theme_font_size_override("font_size", 18)
    border.add_theme_color_override("font_color", Color.WHITE)

    # Create tarot-style double border frame
    var border_text = ""
    border_text += "╔══════════════╗\n"
    border_text += "║╔════════════╗║\n"
    for i in range(18):
        border_text += "║║            ║║\n"
    border_text += "║╚════════════╝║\n"
    border_text += "╚══════════════╝"
    border.text = border_text
    card_container.add_child(border)

    # Card content container
    var vb := VBoxContainer.new()
    vb.position = Vector2(25, 30)
    vb.size = Vector2(150, 300)
    vb.add_theme_constant_override("separation", 8)

    # Roman numeral at top
    var numeral_label := Label.new()
    numeral_label.text = _get_roman_numeral(index + 1)
    numeral_label.add_theme_font_override("font", monogram_font)
    numeral_label.add_theme_font_size_override("font_size", 24)
    numeral_label.add_theme_color_override("font_color", Color(1.8, 1.8, 1.8))
    numeral_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # ASCII art symbol based on card effect
    var symbol_label := Label.new()
    symbol_label.add_theme_font_override("font", monogram_font)
    symbol_label.add_theme_font_size_override("font_size", 14)
    symbol_label.add_theme_color_override("font_color", Color(1.8, 1.8, 1.8))
    symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # Create tarot-style ASCII art based on card type
    var ascii_art = _get_card_ascii_art(card)
    symbol_label.text = ascii_art

    # Card name in mystical style
    var name_label := Label.new()
    name_label.text = card.name.to_upper()
    name_label.add_theme_font_override("font", monogram_font)
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.add_theme_color_override("font_color", Color(1.8, 1.8, 1.8))
    name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # Description
    var desc := Label.new()
    desc.text = card.description
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD
    desc.add_theme_font_override("font", monogram_font)
    desc.add_theme_font_size_override("font_size", 13)
    desc.add_theme_color_override("font_color", Color(1.2, 1.2, 1.2))
    desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    vb.add_child(numeral_label)
    vb.add_child(symbol_label)
    vb.add_child(name_label)
    vb.add_child(desc)
    card_container.add_child(vb)

    # hover/press effects
    card_container.mouse_entered.connect(func(): _hover_card(card_container, border, true))
    card_container.mouse_exited.connect(func(): _hover_card(card_container, border, false))
    card_container.gui_input.connect(func(e):
        if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
            _choose(index)
    )

    option_container.add_child(card_container)

func _hover_card(card: Control, border: Label, hover: bool):
    var tween = create_tween()
    tween.set_parallel(true)

    if hover:
        # Scale up and brighten border
        tween.tween_property(card, "scale", Vector2(1.08, 1.08), 0.1)
        tween.tween_property(border, "modulate", Color(2.0, 2.0, 2.0), 0.1)
    else:
        # Scale back down
        tween.tween_property(card, "scale", Vector2.ONE, 0.1)
        tween.tween_property(border, "modulate", Color.WHITE, 0.1)

func _unhandled_input(event: InputEvent):
    if event is InputEventKey and event.pressed and not event.is_echo():
        match event.keycode:
            KEY_1:
                if cards.size() > 0: _choose(0)
            KEY_2:
                if cards.size() > 1: _choose(1)
            KEY_3:
                if cards.size() > 2: _choose(2)

func _choose(index: int):
    if index >= 0 and index < cards.size():
        emit_signal("card_chosen", cards[index])
        queue_free()
