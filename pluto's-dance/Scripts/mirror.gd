extends Camera3D

@export var mirror_node: Node3D  # Ссылка на узел зеркала (например, MeshInstance3D)
@export var target_camera: Camera3D  # Камера игрока
@export var mirror_surface_normal: Vector3 = Vector3(0, 0, 1)  # Нормаль поверхности зеркала
@export var mirror_offset: float = 0.0  # Смещение камеры от плоскости зеркала

func _ready():
	if not mirror_node or not target_camera:
		push_error("Mirror node or target camera not assigned!")
		return
	
	# Устанавливаем начальную позицию камеры относительно зеркала
	update_mirror_position()

func _process(delta):
	if not mirror_node or not target_camera:
		return
	
	# Обновляем позицию и ориентацию камеры
	update_mirror_position()

func update_mirror_position():
	# Позиция зеркала
	var mirror_pos = mirror_node.global_transform.origin
	var mirror_normal = (mirror_node.global_transform.basis * mirror_surface_normal).normalized()
	
	# Позиция камеры игрока
	var camera_pos = target_camera.global_transform.origin
	
	# Вычисляем отраженную позицию камеры относительно зеркала
	var to_camera = camera_pos - mirror_pos
	var distance = to_camera.dot(mirror_normal)
	var reflected_pos = camera_pos - 2 * distance * mirror_normal
	
	# Устанавливаем позицию зеркальной камеры (фиксированная относительно зеркала)
	global_transform.origin = mirror_pos + mirror_normal * mirror_offset
	
	# Получаем ориентацию камеры игрока
	var camera_basis = target_camera.global_transform.basis
	
	# Извлекаем только yaw (поворот влево/вправо) из камеры игрока
	var forward = camera_basis.z  # Направление вперед камеры игрока
	var forward_flat = Vector3(forward.x, 0, forward.z).normalized()  # Проецируем на плоскость XZ
	var up = Vector3.UP  # Фиксируем вертикальную ось
	
	# Отражаем направление вперед относительно нормали зеркала
	var reflected_forward = forward_flat - 2 * (forward_flat.dot(mirror_normal)) * mirror_normal
	
	# Устанавливаем ориентацию камеры (только горизонтальное вращение)
	var reflected_basis = Basis()
	reflected_basis.z = -reflected_forward.normalized()
	reflected_basis.y = up
	reflected_basis.x = reflected_basis.y.cross(reflected_basis.z).normalized()
	global_transform.basis = reflected_basis
	
	# Копируем параметры камеры игрока (fov, near, far)
	fov = target_camera.fov
	near = target_camera.near
	far = target_camera.far
