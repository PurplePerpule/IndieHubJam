extends CharacterBody3D

@export var player_node: NodePath  # Путь к узлу игрока
@export var head_bone_name: String = "Bone.001"  # Имя кости головы

var dia = false

var player: Camera3D = null
@onready var skeleton = $LilBro/Armature/Skeleton3D  # Ссылка на Skeleton3D

func interact():
	if dia == false:
		Dialogic.start_timeline("LilBroQuest")
		dia = true
	else:
		Dialogic.start_timeline("GoGoGo")


func _ready():
	if player_node:
		player = get_node(player_node) as Camera3D
	if not player:
		print("Warning: Player node not set!")
	if not skeleton:
		print("Warning: Skeleton3D not found!")
	
	# Убедимся, что кость головы существует
	if not skeleton.find_bone(head_bone_name) >= 0:
		print("Warning: Bone '", head_bone_name, "' not found in Skeleton3D!")

func _physics_process(delta):
	if not player or not skeleton:
		return
	
	# Получаем позицию игрока
	var player_pos = player.global_transform.origin
	var npc_pos = global_transform.origin
	
	# Вычисляем направление к игроку в глобальных координатах
	var direction_to_player = (player_pos - npc_pos).normalized()
	
	# Отладочный вывод для проверки направления
	#print("Direction to player: ", direction_to_player)
	
	# Получаем индекс кости головы
	var head_bone_index = skeleton.find_bone(head_bone_name)
	if head_bone_index >= 0:
		# Получаем текущую трансформацию кости головы
		var head_transform = skeleton.get_bone_global_pose(head_bone_index)
		
		# Экспериментируем с направлением, чтобы найти правильное
		# Попробуйте следующие варианты, комментируя/разкомментируя их:
		#var corrected_direction = Vector3(direction_to_player.x, direction_to_player.y, direction_to_player.z)  # Без изменений
		var corrected_direction = Vector3(-direction_to_player.x, direction_to_player.y, -direction_to_player.z)  # Инверсия X и Z
		#var corrected_direction = Vector3(-direction_to_player.x, direction_to_player.y, direction_to_player.z)  # Инверсия X
		# var corrected_direction = Vector3(direction_to_player.x, direction_to_player.y, -direction_to_player.z)  # Инверсия Z
		
		# Создаём новую ориентацию, чтобы голова смотрела на игрока
		var head_basis = Basis.looking_at(corrected_direction, Vector3.UP)
		
		# Устанавливаем новую ориентацию кости
		head_transform.basis = head_basis
		skeleton.set_bone_global_pose_override(head_bone_index, head_transform, 1.0)
	else:
		print("Warning: Bone '", head_bone_name, "' not found in Skeleton3D!")
