extends CharacterBody3D

@export var stop_distance: float = 0.1 # Distancia mínima para considerar que ha llegado al objetivo y detenerse
@export var rotation_speed: float = 10.0
@export var attack_raycast_range: float = 2.0

@export var player_stats: PlayerStats

@export_flags_3d_physics var ray_collision_mask: int = 0

@onready var camera: Camera3D = $"../CameraAnchor/IsometricCamera"

var enemies_in_range: Array[Node] = []

var target_position: Vector3 = global_transform.origin

func _ready() -> void:
	target_position = global_transform.origin
	add_to_group("player")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("moveAttack"):
		var mouse_position: Vector2 = get_viewport().get_mouse_position()
		
		#Lanza un rayo desde la posición del ratón en la pantalla
		var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
		var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)
		
		#Preparar los parámetros de consulta para el rayo
		var query = PhysicsRayQueryParameters3D.new()
		query.from = ray_origin
		query.to = ray_origin + ray_direction*1000 # Larga distancia para el rayo
		query.collide_with_areas = false # No colisionar con áreas
		query.collide_with_bodies = true # Sí colisionar con cuerpos
		query.collision_mask = ray_collision_mask #Usamos la máscara de colisión
		
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		
		if result.has("position"):
			var collided_object: Object = result.collider
			print("Colisión detectada en: ", result.position, " con: ", collided_object.name)
			
			
			if collided_object is CharacterBody3D:
				var distance_to_target = (result.position - global_transform.origin).length()
				if collided_object.is_in_group("monstruos") and (distance_to_target < player_stats.attack_range) and player_stats.can_attack():
					perform_attack(collided_object)
				return
			
			target_position = result.position
			target_position.y = global_transform.origin.y #Mantenemos altura
			print("Moviendo a: ", target_position)
		else:
			print("El rayo no colisionó con una superficie válida para el movimiento")
	
func _physics_process(delta: float) -> void:
	if player_stats.current_health <= 0:
		#c muere
		queue_free()
	#Actualizamos cd
	player_stats.update_cooldown(delta)
	
	var direction_to_target = target_position - global_transform.origin
	direction_to_target.y = 0
	
	if direction_to_target.length_squared() < stop_distance * stop_distance:
		velocity = Vector3.ZERO
	else:
		var move_direction = direction_to_target.normalized()
		velocity = move_direction * player_stats.move_speed
		
		var target_look_at_vector = Vector3(move_direction.x, 0, move_direction.z)
		if target_look_at_vector.length_squared() > 0:
			var target_transform = global_transform.looking_at(global_transform.origin + target_look_at_vector, Vector3.UP)
			global_transform = global_transform.interpolate_with(target_transform, rotation_speed*delta)
	move_and_slide()

func perform_attack(target: CharacterBody3D):
	#El pj se gira hacia el monstruo y le da
	target.take_damage(player_stats.attack_damage)
		
