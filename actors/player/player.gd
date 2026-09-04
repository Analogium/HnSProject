class_name Player
extends CharacterBody2D

signal died
signal xp_changed(current: int, needed: int, level: int)
signal leveled_up(level: int)
signal equipment_changed

const ACCEL := 0.25          # réactivité au démarrage
const FRICTION := 0.35       # freinage à l'arrêt
const ATTACK_MOVE_MULT := 0.4  # on ralentit pendant le coup, on ne fige pas

## La ressource du disque. **Jamais modifiée** : aucun `.tres` du projet n'est
## `resource_local_to_scene`, donc l'écrire toucherait le fichier lui-même et
## toutes les parties suivantes de la session.
@export var base_stats: CharacterStats

## Progression. Le personnage persiste : ni la mort ni le changement de zone ne
## les remettent à zéro.
const XP_BASE := 40.0
const XP_POWER := 1.5
const LEVEL_HEALTH := 8.0
const LEVEL_DAMAGE := 1.0
## Soin partiel à la montée de niveau, jamais complet : à 100 % on chercherait à
## monter de niveau au milieu d'un paquet plutôt qu'à se battre.
const LEVEL_HEAL := 0.30

## Les emplacements d'équipement, dans l'ordre où l'interface les montre. Un
## dictionnaire indexé par nom et non un champ par emplacement : ajouter les
## bottes ou l'anneau se fera en allongeant cette liste, sans toucher au calcul
## des statistiques ni au dessin du panneau.
const SLOTS := ["weapon", "chest"]
const SLOT_NAMES := {"weapon": "ARME", "chest": "TORSE"}

## Taille du sac, en cases. Large plutôt que haut, comme dans les jeux dont il
## reprend la règle : une épée mange trois lignes, et un sac de quatre lignes
## n'accepterait presque rien.
const INVENTORY_COLS := 10
const INVENTORY_ROWS := 5

## Durée pendant laquelle la hitbox est active. Réglable à chaud (étape 5).
@export var swing_duration: float = 0.12

@export_group("Tir")
## Attaque à distance. Moins de dégâts que le corps à corps, mais elle
## n'oblige pas à entrer dans la mêlée : c'est le compromis à régler.
@export var bolt_scene: PackedScene
@export var bolt_damage: float = 7.0
@export var bolt_cooldown: float = 0.30
## Secousse de caméra à l'impact. 0 pour la couper.
@export var shake_amount: float = 2.0

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar
@onready var attack_pivot: Node2D = $AttackPivot
@onready var hitbox: Area2D = $AttackPivot/Hitbox
@onready var swing_arc: SwingArc = $AttackPivot/SwingArc
@onready var camera: Camera2D = $Camera2D

## Où atterrissent les tirs du joueur. Posé par la scène (zone ou arène) ;
## à défaut, ils naissent à côté du joueur.
var projectile_parent: Node2D

## Copie de travail : base + niveaux, et plus tard l'équipement. Recalculée
## d'un bloc à chaque changement, jamais retouchée pièce par pièce — sinon les
## bonus s'accumuleraient à chaque recalcul.
var stats: CharacterStats

var level := 1
var xp := 0
var xp_to_next := 40

## Ce qu'on a ramassé, et où c'est rangé. Le sac porte son propre signal
## `changed` : l'interface s'y abonne directement, sans que le joueur ait à le
## réémettre sous un autre nom.
var inventory := Inventory.new(INVENTORY_COLS, INVENTORY_ROWS)

## Ce qui est porté, par emplacement. Un Item par entrée, ou rien.
var equipment := {}

var health: float
var is_dead := false
var facing := Vector2.RIGHT
var _attack_cd := 0.0
var _bolt_cd := 0.0
var _is_swinging := false
var _already_hit: Array[Node] = []
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true


func _ready() -> void:
	# Sans .tres assigné on part sur des valeurs par défaut plutôt que de planter.
	if base_stats == null:
		base_stats = CharacterStats.new()
	recompute_stats()
	xp_to_next = _needed_for(level)
	health = stats.max_health
	health_bar.set_health(health, stats.max_health)
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.damaged.connect(_on_damaged)


## Purement observationnel : on retient quel périphérique sert à viser.
## À ne pas tester via get_global_mouse_position(), qui bouge aussi quand la
## caméra suit le joueur — la souris paraîtrait alors constamment en mouvement.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_aim_with_mouse = true
	elif event is InputEventJoypadButton:
		_aim_with_mouse = false
	elif event is InputEventJoypadMotion:
		# Seuil large : sinon la dérive du stick au repos rebascule la visée.
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			_aim_with_mouse = false


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_bolt_cd = maxf(_bolt_cd - delta, 0.0)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _aim_with_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			facing = to_mouse.normalized()
	elif input != Vector2.ZERO:
		facing = input.normalized()

	attack_pivot.rotation = facing.angle()
	# Le sprite suit la visée, pas le déplacement : dans un hack'n'slash on
	# recule en gardant l'ennemi en face, et voir le dos du joueur à ce
	# moment-là casse la lecture du combat.
	sprite.set_state(input != Vector2.ZERO, facing)

	var speed := stats.move_speed * (ATTACK_MOVE_MULT if _is_swinging else 1.0)
	if input != Vector2.ZERO:
		velocity = velocity.lerp(input.normalized() * speed, ACCEL)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION)

	move_and_slide()

	# L'attaque est lue par sondage, ce qui court-circuite le système d'entrées
	# de l'interface : sans ce test, chaque clic pour déplacer une épée dans le
	# sac déclencherait aussi un coup d'épée.
	if not Game.ui_grabs_input:
		if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
			_swing()

		if Input.is_action_just_pressed("attack_ranged") and _bolt_cd <= 0.0:
			_shoot()


func _swing() -> void:
	_attack_cd = stats.attack_cooldown
	_is_swinging = true
	_already_hit.clear()
	swing_arc.play(swing_duration)
	sprite.attack()

	# set_deferred : on est dans un callback physique, on ne peut pas
	# modifier l'état de monitoring en direct.
	hitbox.set_deferred("monitoring", true)

	# ignore_time_scale : sinon le hit-stop étire la fenêtre de swing.
	await get_tree().create_timer(swing_duration, true, false, true).timeout

	hitbox.set_deferred("monitoring", false)
	_is_swinging = false


func _shoot() -> void:
	if bolt_scene == null:
		return
	_bolt_cd = bolt_cooldown

	var parent := projectile_parent if projectile_parent != null else get_parent()
	var bolt: Projectile = bolt_scene.instantiate()
	# add_child d'abord : global_position n'a de sens qu'une fois dans l'arbre.
	parent.add_child(bolt)
	bolt.global_position = global_position + facing * 12.0
	bolt.setup(facing, bolt_damage, self)


## Reconstruit les stats de zéro à partir de la ressource du disque. De zéro et
## non par incréments : additionner le bonus de niveau à la valeur courante le
## compterait une fois de plus à chaque appel — et un objet retiré laisserait son
## bonus derrière lui.
##
## Publique : l'arène de réglage l'appelle après avoir modifié base_stats, et
## l'équipement l'appelle à chaque objet porté ou retiré.
func recompute_stats() -> void:
	stats = base_stats.duplicate()
	stats.max_health += LEVEL_HEALTH * float(level - 1)
	stats.attack_damage += LEVEL_DAMAGE * float(level - 1)

	# Tous les objets d'un coup, et non emplacement par emplacement : c'est ce
	# qui permet d'appliquer les valeurs plates avant les pourcentages, donc
	# d'obtenir le même personnage quel que soit l'ordre d'équipement.
	var mods: Array[StatMod] = []
	for slot in SLOTS:
		var item: Item = equipment.get(slot)
		if item != null:
			mods.append_array(item.mods())
	StatMod.apply_all(stats, mods)

	# Une chance critique au-dessus de 1 ne veut rien dire, et le multiplicateur
	# sous 1 transformerait un critique en coup amorti.
	stats.crit_chance = clampf(stats.crit_chance, 0.0, 1.0)
	stats.crit_multiplier = maxf(stats.crit_multiplier, 1.0)

	# L'armure vit sur la hurtbox : c'est elle le point de passage unique de
	# tous les coups reçus, et elle applique déjà la même règle aux ennemis
	# blindés. Réassignée à chaque recalcul, donc retirer un plastron la reprend.
	hurtbox.damage_reduction = maxf(stats.damage_reduction, 0.0)


## Porte un objet et rend celui qu'il remplace, ou null. L'appelant décide du
## sort de l'ancien : le sac s'il y reste de la place, le sol sinon — ce n'est
## pas au joueur d'en juger, c'est à l'interface qui a déclenché l'échange.
##
## Renvoie l'objet lui-même quand il ne peut pas être porté (pas d'emplacement),
## pour que l'appelant n'ait pas à le tester d'avance et ne le perde jamais.
func equip(item: Item) -> Item:
	if item == null:
		return null
	if item.base == null or not SLOTS.has(item.base.slot):
		return item
	var ancien: Item = equipment.get(item.base.slot)
	equipment[item.base.slot] = item
	_after_equipment_change()
	return ancien


func unequip(slot: String) -> Item:
	var item: Item = equipment.get(slot)
	if item == null:
		return null
	equipment.erase(slot)
	_after_equipment_change()
	return item


func equipped(slot: String) -> Item:
	return equipment.get(slot)


## Les statistiques changent, donc les PV maximum aussi : retirer un plastron
## doit ramener la vie courante sous le nouveau plafond, sinon la barre déborde
## et le joueur garde des PV qu'il n'a plus.
func _after_equipment_change() -> void:
	recompute_stats()
	health = minf(health, stats.max_health)
	health_bar.set_health(health, stats.max_health)
	sprite.set_weapon(_weapon_kind())
	equipment_changed.emit()


## L'arme visible. Vide quand rien n'est porté : le joueur reprend alors l'épée
## de sa fiche d'archétype plutôt que de se battre à mains nues, ce qui serait
## une régression de silhouette pour une information qu'on lit déjà dans le sac.
func _weapon_kind() -> String:
	var arme: Item = equipment.get("weapon")
	return "" if arme == null else arme.base.kind


func _needed_for(lvl: int) -> int:
	return roundi(XP_BASE * pow(float(lvl), XP_POWER))


## Appelée par l'EnemyManager quand un ennemi meurt d'un vrai coup.
func gain_xp(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	xp += amount
	# Une boucle et non un test : un ennemi qui vaut beaucoup peut faire monter
	# de deux niveaux d'un coup.
	while xp >= xp_to_next:
		xp -= xp_to_next
		_level_up()
	xp_changed.emit(xp, xp_to_next, level)


func _level_up() -> void:
	level += 1
	xp_to_next = _needed_for(level)
	recompute_stats()
	health = minf(health + stats.max_health * LEVEL_HEAL, stats.max_health)
	health_bar.set_health(health, stats.max_health)
	leveled_up.emit(level)


## Appelée par l'objet au sol quand le joueur lui passe dessus. Renvoie faux
## quand il ne reste pas de rectangle libre à sa taille — l'objet reste alors
## au sol, il ne doit pas s'évaporer parce que le sac est plein.
func pick_up(item: Item) -> bool:
	if item == null:
		return false
	if not inventory.add(item):
		if HitFeedback.current != null:
			HitFeedback.current.loot_gain(global_position, "sac plein")
		return false
	if HitFeedback.current != null:
		HitFeedback.current.loot_gain(global_position, item.display_name())
	return true


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area is Hurtbox or area in _already_hit:
		return
	_already_hit.append(area)   # un swing ne touche une cible qu'une fois

	var info := DamageInfo.roll(stats, global_position)
	(area as Hurtbox).take_damage(info)
	Game.hit_stop()
	if shake_amount > 0.0:
		Game.shake_camera(camera, shake_amount)


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	health -= info.amount
	health_bar.set_health(health, stats.max_health)
	velocity += (global_position - info.source_position).normalized() * info.knockback
	sprite.flash()
	if health <= 0.0:
		_die()


## Le drapeau évite d'émettre died plusieurs fois : plusieurs grunts peuvent
## frapper dans la même image, et chaque coup relancerait sinon un rechargement
## complet de la zone.
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	died.emit()   # l'écran de fin de run se branchera ici


func revive() -> void:
	is_dead = false
	health = stats.max_health
	health_bar.set_health(health, stats.max_health)
	velocity = Vector2.ZERO
	set_physics_process(true)
