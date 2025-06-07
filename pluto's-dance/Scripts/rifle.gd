extends RigidBody3D


# Параметры оружия
@export var bullet_scene: PackedScene # Сцена пули (нужно создать отдельно)
@export var bullet_speed: float = 50.0 # Скорость пули
@export var fire_rate: float = 0.5 # Задержка между выстрелами (в секундах)
@export var max_ammo: int = 64 # Максимум патронов в обойме
@export var damage: float = 10.0 # Урон пули

# Текущие параметры
var current_ammo: int = 64 # Текущие патроны
var can_shoot: bool = true # Можно ли стрелять

# Точка спавна пули
@onready var bullet_spawn_point: Node3D = $BulletSpawnPoint # Node3D в сцене оружия


func pickable():
	pass

func throw():
	pass

func aim():
	
	pass

func stop_aiming():
	
	pass

func shoot():
	if current_ammo <= 0:
		print("No ammo!")
		return
	$BulletShoot.playing = true
	$hunting_rifle/GPUParticles3D.emitting = true
	$hunting_rifle/GPUParticles3D2.emitting = true
	$hunting_rifle/GPUParticles3D3.emitting = true
	if not can_shoot:
		return
	
	# Создаем пулю
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	$AnimationPlayer.play("shoot")
	# Устанавливаем позицию и направление пули
	bullet.global_transform = bullet_spawn_point.global_transform
	bullet.apply_central_impulse(bullet_spawn_point.global_transform.basis.x * bullet_speed)
	
	# Уменьшаем патроны и устанавливаем задержку
	current_ammo -= 1
	can_shoot = false
	print("Shot fired! Ammo left: ", current_ammo)
	
	# Задержка для следующего выстрела
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
