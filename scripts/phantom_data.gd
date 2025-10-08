extends Resource
class_name PhantomData

## Custom resource for phantom data
## Stores ASCII art, text, and spawn parameters

@export var art: String = ""  ## ASCII art representation
@export_multiline var text_to_type: String = ""  ## Text player must type
@export var base_speed: float = 50.0  ## Movement speed in pixels/second
@export var level: int = 1  ## Which level this phantom belongs to
@export var rarity: float = 1.0  ## How common this phantom is (higher = rarer)