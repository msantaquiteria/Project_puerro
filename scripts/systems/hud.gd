extends CanvasLayer

@onready var monster_info = $MonsterHUD/MonsterInfo
@onready var monster_name = $MonsterHUD/MonsterInfo/MonsterName
@onready var monster_health = $MonsterHUD/MonsterInfo/MonsterHealth

@onready var life_orb = $PlayerHUD/LifeOrb

func _ready() -> void:
	#Inicializamos el HUD del monstruo
	monster_info.visible = false #Al principio oculto
	monster_health.texture_under = _create_color_texture(Color(0.2, 0.2, 0.2))  # gris oscuro
	monster_health.texture_progress = _create_color_texture(Color(1.0, 0.0, 0.0))  # verde
	monster_health.texture_over = _create_color_texture(Color(1, 1, 1, 0.2))  # blanco semitransparente
	
	#Inicializamos el HUD del player
	life_orb.value = 100  # por defecto vacío
	# Texturas placeholder para el orbe
	var orb_under = _create_circle_texture(Color(0.2, 0.2, 0.2, 1.0), 64)   # gris oscuro
	var orb_progress = _create_circle_texture(Color(1.0, 0.0, 0.0, 0.8), 64) # rojo semi
	var orb_over = _create_circle_texture(Color(1.0, 1.0, 1.0, 0.2), 64)     # borde blanco suave
	
	life_orb.texture_under = orb_under
	life_orb.texture_progress = orb_progress
	life_orb.texture_over = orb_over

func show_monster(monster: CharacterBody3D):
	monster_info.visible = true
	monster_name.text = monster.monster_stats.enemy_name
	monster_health.max_value = monster.monster_stats.max_health
	monster_health.value = monster.monster_stats.current_health
	
	#Conectar señales de vida del monstruo
	var callable_monster_hp_change = Callable(self, "_on_monster_health_changed")
	if not monster.is_connected("monster_health_changed", callable_monster_hp_change):
		monster.connect("monster_health_changed", callable_monster_hp_change)
		
func _on_monster_health_changed(new_health: int):
	monster_health.value = new_health
	if new_health <= 0:
		monster_info.visible = false

func set_player_health(current: int, maximum: int):
	life_orb.max_value = maximum
	life_orb.value = current


#funciones placeholder para crear las barras de vida
func _create_color_texture(color: Color, size: Vector2i = Vector2i(200, 20)) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex := ImageTexture.create_from_image(img)
	return tex
	
func _create_circle_texture(color: Color, radius: int = 64) -> ImageTexture:
	var size = radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # transparente

	for y in size:
		for x in size:
			var dx = x - radius
			var dy = y - radius
			if dx * dx + dy * dy <= radius * radius:
				img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)
	
