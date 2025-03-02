extends CharacterBody3D


@export var player_node: NodePath  # Путь к узлу игрока

var player: CharacterBody3D = null

func _ready():
	if player_node:
		player = get_node(player_node) as CharacterBody3D
		
		
func _physics_process(delta: float) -> void:
	look_at(player.global_transform.origin, Vector3.UP)
