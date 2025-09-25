extends CharacterBody3D

@export var move_speed: float = 5.0 # Velocidad de movimiento
@export var stop_distance: float = 0.1 # Distancia mínima para considerar que ha llegado al objetivo y detenerse
@export var attack_damage: float = 20.0 #daño del pj
@export var attack_cooldown: float = 0.5
@export var rotation_speed: float = 10.0
@export var attack_raycast_range: float = 2.0

var enemies_in_range: Array[Node] = []
var can_attack: bool = true
var attack_area: Area3D
var player_model: Node3D
var current_target: CharacterBody3D

var health: float = 100.0
var max_health: float = 100.0

var target_position: Vector3 = global_transform.origin #La posición a la que el pj debe moverse
var has_target: bool = false #Para saber si el personaje tiene un objetivo de movimiento activo

func _ready() -> void:
	#Asegurarse de que el personaje esté en su posición inicial al inicio
	attack_area = $AttackArea as Area3D
	if attack_area == null:
		push_error("Error: Player node missing AttackArea child.")
		set_process(false)
		return
	
	#conecta las señales del Area3d	
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	
	#El Area3D de ataque debe estar deshabilitado hasta que ataques
	attack_area.monitoring = false
	attack_area.monitorable = false
	
	player_model = $Pivot
	if player_model == null:
		push_error("Error: Player node missing 'Model' child for rotation")
	
func _input(event: InputEvent):
	#Deteccion de click para movimiento o ataque basado en el ratón
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(event)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(event)

func handle_left_click(event: InputEventMouseButton):
	#Raycast desde la cámara para encontrar un punto en el suelo o un enemigo
	var camera = get_viewport().get_camera_3d()
	if camera == null: return
	
	var from = camera.project_ray_normal(event.position) 
	var to = from + camera.project_ray_normal(event.position) * 1000 #Un rayo largo
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	#Se puede usar una máscara de colisión para el suelo
	#query.collision_mask = (1 << Constants.LAYER_GROUND) | (1 << Constants.LAYER_ENEMIES)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider:
			if collider.is_in_group("monstruos"):
				current_target = collider as CharacterBody3D #Bloquea el objetivo
				#Aquí puedes decidir si ataca al objetivo o si se mueve a su lado
				perform_attack() #Ataca inmediatamente si hay un enemigo
			else:
				current_target = null # Desbloquea el objetivo si no es un enemigo
				move_to_position(result.position) #moverse al punto clickado
		else:
			current_target = null #Desbloquea objetivo si hace click en el aire
	
func handle_right_click(event: InputEventMouseButton):
	#El botón derecho puede ser para un ataque secundario o para una habilidad
	if can_attack:
		#Si tienes un 'current_target' puedes hacer un ataque dirigido
		if current_target:
			look_at(current_target.global_position, Vector3.UP) #Mira al objetivo
			perform_attack()
		else:
			#Si no hay objetivo, atacamos en la dirección actual del jugador
			perform_attack()
				
func _physics_process(delta: float) -> void:
	#Lógica de movimiento hacia el punto objetivo si no estoy atacando
	if current_target:
		#Si hay un objetivo, mover hacia él si está fuera del rango de ataque
		var distance_to_target = global_position.distance_to(current_target.global_position)
		if distance_to_target > attack_area.shape_owner_get_shape(0,0).extents.x + 0.5: #Ejemplo de rango
			var direction_to_target = (current_target.global_position - global_position).normalized()
			velocity = direction_to_target * move_speed
			rotate_towards(current_target.global_position,delta) #Mira al objetivo
		else:
			velocity = Vector3.ZERO #Si está en rango deja de moverse y ataca
			rotate_towards(current_target.global_position,delta) #Sigue mirando al objetivo
	elif velocity != Vector3.ZERO:
		#Si no hay objetivo y hay velocidad (movimiento de click de suelo)
		move_to_position(global_position + velocity.normalized()*move_speed*delta)
	else:
		velocity = Vector3.ZERO
	move_and_slide()
			
	
func move_to_position(target_pos: Vector3):
	#Calcula la dirección para moverse al punto clickado en Z (horizontal)
	#Ignora la diferencia de altura para el movimiento del jugador
	var horizontal_target_pos = target_pos
	horizontal_target_pos.y = global_position.y #mantiene la altura
	var direction = (horizontal_target_pos - global_position).normalized()
	
	if global_position.distance_to(horizontal_target_pos) < 0.1: #Margen de llegada
		velocity = Vector3.ZERO
		return
	velocity = direction*move_speed
	rotate_towards(horizontal_target_pos,get_physics_process_delta_time())

func rotate_towards(target_look_at_pos: Vector3, delta: float):
	#Calcula el vector de dirección horizontal hacia el objetivo
	var target_direction = (target_look_at_pos - player_model.global_position).normalized()
	target_direction.y = 0.0 #Ignora la componente vertical
	if target_direction == Vector3.ZERO: return
	
	#Calcula el ángulo de rotación deseado
	#Asume que el modelo por defecto mira hacia -Z
	var desired_angle = atan2(target_direction.x, -target_direction.z) #atan2(x,y) rota alrededor del eje Y
	
	var current_rotation_y = player_model.rotation.y
	var new_rotation_y = lerp_angle(current_rotation_y, desired_angle, delta*rotation_speed)
	
	player_model.rotation.y = new_rotation_y

func perform_attack() -> void:
	if not can_attack: return
	can_attack = false
	
	#Habilitamos el Area3D para detectar enemigos sólo durante el ataque
	attack_area.monitoring = true
	attack_area.monitorable = true
	
	#Si hubiese animaciones las pondríamos aquí
	#$AnimationPlayer.play("attack")
	
	#Temporizador para la duración de la hitbox del ataque
	var attack_hitbox_duration = 0.1 #El AttackArea estará activo por X segundos
	var attack_timer = get_tree().create_timer(attack_hitbox_duration)
	attack_timer.timeout.connect(func():
		attack_area.monitoring = false
		attack_area.monitorable = false
		deal_damage_to_targets()
		#Se puede limpiar la lista o esperar al cooldown
		enemies_in_range.clear() #Limpiar para ataques de un solo golpe por animación
	)
	
	#Temporizador para el cd global del ataque
	var cooldown_timer = get_tree().create_timer(attack_cooldown)
	cooldown_timer.timeout.connect(func():
		can_attack = true
		#Si el target actual ya está muerto, se limpia
		if current_target and not is_instance_valid(current_target):
			current_target = null
	)

func deal_damage_to_targets():
	#Itera sobre la lista de enemigos detectados por el Area3D
	for enemy_node in enemies_in_range:
		if enemy_node and is_instance_valid(enemy_node) and enemy_node.has_method("take_damage"):
			enemy_node.take_damage(attack_damage)
			print("Player attacked: ", enemy_node.name)
			#Si solo se quiere golpear al primer enemigo metemos un break
			#break
			#Esta lista se vacía después de cada ataque para simular un "hit" por animación

func _on_attack_area_body_entered(body: Node3D):
	#Asegurarse que sólo metemos enemigos en la lista
	if body.is_in_group("monstruos") and enemies_in_range.has(body):
		enemies_in_range.append(body)
		print("Enemy entered attack range: ", body.name)
	
func _on_attack_area_body_exited(body: Node3D):
	if body.is_in_group("monstruos") and enemies_in_range.has(body):
		enemies_in_range.erase(body)
		print("Enemy exited attack range: ", body.name)

func take_damage(amount: float) -> void:
	pass

func die() -> void:
	pass
