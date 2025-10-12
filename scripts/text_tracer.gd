extends Node2D
class_name TextTracer

# Lightweight projectile that travels from start to end with a small trail

@export var speed: float = 900.0
@export var lifetime: float = 1.2
@export var thickness: float = 2.0

var start_pos: Vector2
var end_pos: Vector2
var dir: Vector2
var t: float = 0.0
var distance: float = 1.0
var trail: Array[Vector2] = []

func setup(a: Vector2, b: Vector2):
    start_pos = a
    end_pos = b
    dir = (end_pos - start_pos).normalized()
    distance = max(1.0, a.distance_to(b))
    global_position = a

func _process(delta):
    # Move forward
    var move = speed * delta
    var to_end = end_pos - global_position
    if to_end.length() <= move:
        global_position = end_pos
        _on_hit()
        queue_free()
        return
    global_position += dir * move

    # Record trail (keep it tight)
    trail.push_front(global_position)
    if trail.size() > 16:
        trail.pop_back()

    # fade-out guard
    t += delta
    if t >= lifetime:
        queue_free()

    queue_redraw()

func _draw():
    # Draw head glow
    draw_circle(Vector2.ZERO, 3.0, Color(1, 1, 1, 0.95))
    draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 1, 0.15))

    # Draw trail as segments with diminishing alpha
    var prev = Vector2.ZERO
    var alpha = 0.8
    for i in range(min(12, trail.size())):
        var p = to_local(trail[i])
        if i > 0:
            draw_line(prev, p, Color(1, 1, 1, alpha), thickness)
        prev = p
        alpha *= 0.85

func _on_hit():
    # Small impact flash
    var flash = ColorRect.new()
    flash.color = Color(1, 1, 1, 1)
    flash.size = Vector2(8, 8)
    flash.position = -flash.size * 0.5
    add_child(flash)
    var tw = create_tween()
    tw.tween_property(flash, "modulate:a", 0.0, 0.12)
    tw.finished.connect(func(): if is_instance_valid(flash): flash.queue_free())
