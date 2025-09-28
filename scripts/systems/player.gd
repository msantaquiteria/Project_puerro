extends CharacterBody3D

@export var stop_distance: float = 0.1 # Distancia mínima para considerar que ha llegado al objetivo y detenerse
@export var attack_raycast_range: float = 2.0
@export var player_stats: PlayerStats

@export_flags_3d_physics var ray_collision_mask: int = 0

@onready var camera: Camera3D = get_viewport().get_camera_3d()

var current_target: CharacterBody3D
var target_position: Vector3 

func _ready() -> void:
	target_position = global_transform.origin
	add_to_group("player")
	
	if player_stats != null:
		var hp_callable = Callable(HUD, "set_player_health")
		if not player_stats.is_connected("player_health_changed", hp_callable):
			player_stats.connect("player_health_changed", hp_callable)
	
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
			
			if collided_object is CharacterBody3D and collided_object.is_in_group("monstruos"):
				current_target = collided_object
			else:
				current_target = null
			
			target_position = result.position
			target_position.y = global_transform.origin.y #Mantenemos altura
			print("Moviendo a: ", target_position)
		else:
			print("El rayo no colisionó con una superficie válida para el movimiento")
	
func _physics_process(delta: float) -> void:
	if player_stats.current_health <= 0:
		#c muere
		queue_free()
	#Actualizamos cds (sustituir a futuro a actualizar stats con bufos y debufos)
	player_stats.update_cooldown(delta)
	
	var direction_to_target = target_position - global_transform.origin
	direction_to_target.y = 0
	
	if current_target != null:
		direction_to_target = current_target.position - global_transform.origin
		direction_to_target.y = 0
		#Si está el pj dentro del rango de ataque devolvemos un return para que no se mueva.
		if perform_attack(current_target, direction_to_target.length()): return
				
	if direction_to_target.length_squared() < stop_distance * stop_distance:
		velocity = Vector3.ZERO
	else:
		var move_direction = direction_to_target.normalized()
		velocity = move_direction * player_stats.move_speed
		var target_look_at_vector = Vector3(target_position.x, 0, target_position.z)
		if target_look_at_vector.length_squared() > 0:
			var target_transform = global_transform.looking_at(global_transform.origin + target_look_at_vector, Vector3.UP)
			global_transform = global_transform.interpolate_with(target_transform, player_stats.rotation_speed*delta)
	
	move_and_slide()

func perform_attack(monster: CharacterBody3D, distance: int) -> bool:
	var is_in_range: bool = false
	#Mandamos al HUD la señal del target
	HUD.show_monster(monster)
	#El pj se gira hacia el monstruo y le da y liberamos al current_target
	if(distance <= player_stats.attack_range):
		if(player_stats.can_attack()):
			monster.take_damage(player_stats.attack_damage)
		is_in_range = true	
	return is_in_range

func take_damage(amount: int) -> void:
	player_stats.take_damage(amount)
