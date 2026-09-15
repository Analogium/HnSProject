class_name SimulationDuBanc

## Un robot dans une vraie zone, à graine fixe : il marche vers l'ennemi le plus proche
## et lance toute sa barre dès que `Player.lancer()` l'accepte. Un joueur médiocre, et
## c'est voulu : la mesure donne un plancher (hack-n-slash-jalon-13.md, §3).

const ZONE := preload("res://world/zone.tscn")
const GRAINE := 4242
## En secondes de jeu : une case qu'on ne vide pas s'arrête ici.
const PLAFOND := 180.0
const VIE_BASSE := 0.30
## Le champ vers la cible couvre la carte entière (8,9 ms mesurés) : pas à chaque image.
const PERIODE_DU_CHAMP := 1.0
## En deçà, la ligne droite : le champ ne dit rien de la case où se tient la cible.
const CONTACT := 2.0 * MapGenerator.TILE


class Resultat:
	var niveau := 0
	var tues := 0
	var morts := 0
	## Temps de jeu : un gel d'impact n'en compte que sa part ralentie.
	var temps := 0.0
	var sous_la_vie_basse := 0.0
	var videe := false

	func tues_par_minute() -> float:
		return float(tues) * 60.0 / temps if temps > 0.0 else 0.0


var _resultat: Resultat
var _joueur: Player


func jouer(hote: Node, personnage: Personnage, zone: int) -> Resultat:
	_resultat = Resultat.new()
	Game.niveau_de_zone = zone
	var arbre := hote.get_tree()
	var scene: Node2D = ZONE.instantiate()
	hote.add_child(scene)
	scene.set_process_unhandled_input(false)
	_joueur = scene.player
	_joueur.charger(personnage)
	_resultat.niveau = _joueur.level
	# Sans souris, la visée suit la marche : c'est ce que fait la manette.
	Input.parse_input_event(InputEventJoypadButton.new())
	Game.rng.seed = GRAINE
	scene.generate_zone(GRAINE)

	var manager: EnemyManager = scene.enemy_manager
	for e in manager.enemies:
		e.died.connect(_on_ennemi_mort)
	# Une mort du joueur repeuple la zone.
	manager.child_entered_tree.connect(_on_naissance)
	_joueur.died.connect(_on_joueur_mort)

	var champ := FlowField.new(scene.generator)
	var etendue: int = maxi(scene.generator.width, scene.generator.height)
	var cible: Enemy = null
	var attente := 0.0
	while _resultat.temps < PLAFOND:
		if manager.enemies.is_empty():
			_resultat.videe = true
			break
		if not is_instance_valid(cible) or cible.is_dead or attente <= 0.0:
			cible = _plus_proche(manager)
			if cible != null:
				champ.rebuild(MapGenerator.cell_at(cible.global_position), etendue)
			attente = PERIODE_DU_CHAMP
		if cible != null:
			var vers := champ.direction_at(MapGenerator.cell_at(_joueur.global_position))
			if vers == Vector2.ZERO or _joueur.global_position.distance_to(cible.global_position) < CONTACT:
				vers = _joueur.global_position.direction_to(cible.global_position)
			_marcher(vers)
		for i in BarreDeCompetences.EMPLACEMENTS:
			_joueur.lancer(i)

		await arbre.physics_frame
		var pas := Engine.time_scale / float(Engine.physics_ticks_per_second)
		_resultat.temps += pas
		attente -= pas
		if _joueur.health < _joueur.stats.max_health * VIE_BASSE:
			_resultat.sous_la_vie_basse += pas

	_marcher(Vector2.ZERO)
	scene.queue_free()
	await arbre.process_frame
	Game.niveau_de_zone = Game.NIVEAU_MIN
	return _resultat


func _plus_proche(manager: EnemyManager) -> Enemy:
	var meilleur: Enemy = null
	var distance := INF
	for e in manager.enemies:
		if not is_instance_valid(e) or e.is_dead:
			continue
		var d := e.global_position.distance_squared_to(_joueur.global_position)
		if d < distance:
			distance = d
			meilleur = e
	return meilleur


func _marcher(vers: Vector2) -> void:
	_presser("move_right", vers.x)
	_presser("move_left", -vers.x)
	_presser("move_down", vers.y)
	_presser("move_up", -vers.y)


func _presser(action: String, force: float) -> void:
	if force > 0.0:
		Input.action_press(action, force)
	else:
		Input.action_release(action)


func _on_naissance(noeud: Node) -> void:
	if noeud is Enemy:
		(noeud as Enemy).died.connect(_on_ennemi_mort)


## Le vidage d'une zone qui se recharge après la mort du joueur n'est pas une victoire.
func _on_ennemi_mort(_ennemi: Enemy) -> void:
	if not _joueur.is_dead:
		_resultat.tues += 1


func _on_joueur_mort() -> void:
	_resultat.morts += 1
