extends Node3D

@export var target_node_path: NodePath #Ruta al PJ
@export var follow_speed: float = 5.0 #Velocidad de la cámara


var target_node: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if target_node_path:
		target_node = get_node(target_node_path)
	else:
		printerr("Error: target_node_path no está asignado para CameraAnchor.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if target_node:
		var target_position = target_node.global_transform.origin
		#interpola la posición del CameraAnchor hacia la posición del personaje, esto crea un seguimiento suave
		global_transform.origin = global_transform.origin.lerp(target_position, delta*follow_speed)
