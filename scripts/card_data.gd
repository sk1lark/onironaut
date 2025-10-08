extends Resource
class_name CardData

## Custom resource for card data
## Stores card info and effects

@export var name: String = ""  ## Card name
@export_multiline var description: String = ""  ## Card description
@export var effect: String = ""  ## Effect type (e.g., "typing_speed", "health_regen")
@export var value: float = 0.0  ## Effect value
@export var rarity: float = 1.0  ## How common this card is (higher = rarer)