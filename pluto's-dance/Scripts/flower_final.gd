extends StaticBody3D

var use = false
# Ссылка на материал шейдера игрока
var player_shader_material: ShaderMaterial

func _ready() -> void:
	$AnimationPlayer.play("up")
	# Находим игрока в сцене (предполагая, что он в группе "player")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Получаем материал шейдера из ColorRect внутри CanvasLayer
		player_shader_material = player.get_node("Crossfire/PixelShader").material
		# Пример начального изменения параметров шейдера
		if player_shader_material:
			player_shader_material.set_shader_parameter("shake", 0.015)

func _physics_process(delta: float) -> void:
	$Cube.rotation.y += delta

func interact():
	if use == false:
		use = true
		visible = false
		# Изменяем параметры шейдера игрока при взаимодействии
		if player_shader_material:
			player_shader_material.set_shader_parameter("shake", 0.5)  # Увеличиваем тряску
			player_shader_material.set_shader_parameter("overlay_color", Color(1.0, 0.0, 0.0, 0.8))
			player_shader_material.set_shader_parameter("colorOffsetIntensity", 1.5)  # Красный оттенок
			player_shader_material.set_shader_parameter("grainIntensity", 1.0)
			player_shader_material.set_shader_parameter("lens_distortion_strength", 0.1)
			$"../NewWallMove/Column49".queue_free()
			$"../NewWallMove/Column48".queue_free()
			$"../NewWallMove/Column46".queue_free()
			$CollisionShape3D.disabled = true
			await get_tree().create_timer(0.1).timeout
			player_shader_material.set_shader_parameter("grainIntensity", 0.0)
			# Опционально: возвращаем параметры через время
			await get_tree().create_timer(10.0).timeout
			player_shader_material.set_shader_parameter("shake", 0.00)
			player_shader_material.set_shader_parameter("overlay_color", Color(1.0, 1.0, 1.0, 1.0))
			player_shader_material.set_shader_parameter("colorOffsetIntensity", 0.0)
			player_shader_material.set_shader_parameter("lens_distortion_strength", 0.0)
