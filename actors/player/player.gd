class_name Player
extends CharacterBody2D

signal died
## Pour le HUD, par signal : vie et mana ne bougent qu'aux coups et à la régénération.
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int, level: int)
signal leveled_up(level: int)
## Un nœud de l'arbre pris ou repris, ou un point d'arbre gagné.
signal passives_changed
signal equipment_changed

const ACCEL := 0.25          # réactivité au démarrage
const FRICTION := 0.35       # freinage à l'arrêt
const ATTACK_MOVE_MULT := 0.4  # on ralentit pendant le coup, on ne fige pas

## La ressource du disque, **jamais modifiée** (invariant 2).
@export var base_stats: CharacterStats

## Le personnage persiste : ni la mort ni le changement de zone ne remettent la
## progression à zéro.
const XP_BASE := 40.0
const XP_POWER := 1.5
## Au plafond, l'expérience ne s'accumule plus : `xp_to_next` vaut zéro.
const MAX_LEVEL := 100
## Soin partiel à la montée : complet, on chercherait à monter au milieu d'un paquet.
const LEVEL_HEAL := 0.30

## Les attaques de départ ne s'apprennent pas : leur table n'a qu'une entrée.
const BASIC_ATTACK_POINTS := 1

## Jusqu'où un nuage ou un serpent se posent du personnage. Au-delà du curseur, on
## poserait hors de l'écran à la manette ; en deçà, on se jetterait dans le paquet.
const PLACEMENT_RANGE := 140.0
## Ce qui distingue une frappe lourde d'un coup d'épée au toucher, en plus du dessin.
const STRIKE_SHAKE := 2.0

## Durée pendant laquelle la hitbox est active. Réglable à chaud depuis l'arène.
@export var swing_duration: float = 0.12

@export_group("Tir")
## Moins de dégâts que le corps à corps, sans obliger à entrer dans la mêlée.
@export var bolt_scene: PackedScene
## Le tir de Boule de feu, qui explose à l'impact.
@export var orb_scene: PackedScene
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

## La fiche de travail — disque, attributs, équipement —, **recalculée d'un bloc** et
## jamais retouchée : sinon les bonus s'accumulent.
var stats: CharacterStats

var level := 1
var xp := 0
var xp_to_next := 40

## Partagé et jamais écrit ; une variable pour qu'un test y pose un petit arbre.
var passive_tree := PassiveTree.shared()
## Les nœuds pris, et rien d'autre : les points restants se déduisent du niveau.
var passives := PackedStringArray()

## Le sac porte son propre signal `changed`.
var inventory := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)

## Ce qui est porté, par emplacement. Un Item par entrée, ou rien.
var equipment := {}

## L'interface s'y branche, elle ne les possède pas.
var rack := Rack.new()
var bar := SkillBar.starting()

## Le manuel de départ a-t-il déjà été donné à ce personnage.
var manual_given := false

## Ce que l'équipement donne aux compétences d'un mot-clé, reconstruit par
## `recompute_stats()` et lu à chaque lancer.
var skill_mods: Array[StatMod] = []

var health: float
var mana: float
var is_dead := false
## Ses états, comme ceux d'un ennemi.
var states := StatusEffects.new()
var facing := Vector2.RIGHT
## Une recharge par case : deux compétences voisines s'enchaînent.
var _recharges := PackedFloat32Array()
## Les cases tenues depuis un appui **né en jeu** : sinon le clic qui choisit une
## compétence dans le menu de la barre la lancerait aussitôt.
var _held: Array[bool] = []
## Les parts du coup en cours, **tirées une fois au départ du geste** : tout l'arc
## reçoit la même valeur.
var _hit_parts: Array[float] = []
var _hit_cast: SkillStats
var _hit_shake := 0.0
var _is_swinging := false
## L'aura allumée, ou null. Une seule : Immolation est la seule compétence entretenue.
var _aura: Immolation
var _crown: BladeCrown
## Ce que la brûlure d'Immolation a pris depuis le dernier chiffre affiché.
var _burn_to_show := StatusEffects.Pack.new()
var _already_hit: Array[Node] = []
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true


func _ready() -> void:
	# Sans .tres assigné on part sur des valeurs par défaut plutôt que de planter.
	if base_stats == null:
		base_stats = CharacterStats.new()
	_recharges.resize(SkillBar.SLOT_COUNT)
	_held.resize(SkillBar.SLOT_COUNT)
	recompute_stats()
	xp_to_next = _needed_for(level)
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.damaged.connect(_on_damaged)
	hurtbox.states = states
	states.change.connect(_show_states)
	states.reached.connect(_announce_state)
	states.heal.connect(_heal)


## La souris sert-elle à viser ? Pas déduit de sa position, qui bouge avec la caméra.
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
	# Le gel ralentit la recharge des cinq cases ici, la marche plus bas.
	var cadence := states.speed_factor
	for i in _recharges.size():
		_recharges[i] = maxf(_recharges[i] - delta * cadence, 0.0)

	_regen(delta)
	_suffer_states(delta)
	if is_dead:
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _aim_with_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			facing = to_mouse.normalized()
	elif input != Vector2.ZERO:
		facing = input.normalized()

	attack_pivot.rotation = facing.angle()
	# Le sprite suit la visée, pas le déplacement : on recule face à l'ennemi.
	sprite.set_state(input != Vector2.ZERO, facing)

	var speed := stats.move_speed * cadence * (ATTACK_MOVE_MULT if _is_swinging else 1.0)
	if input != Vector2.ZERO:
		velocity = velocity.lerp(input.normalized() * speed, ACCEL)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION)

	move_and_slide()

	# Sondage des cinq cases, sauf quand un panneau tient la souris. Tenue, la touche
	# relance à chaque fin de recharge : la cadence est celle de `cast_slot()`.
	for i in SkillBar.SLOT_COUNT:
		var action := "skill_%d" % (i + 1)
		if Game.ui_grabs_input or not Input.is_action_pressed(action):
			_held[i] = false
			continue
		if Input.is_action_just_pressed(action):
			_held[i] = true
		if _held[i]:
			cast_slot(i)


## Lance la compétence de cette case. **Le seul chemin** — touches, barre, tests — et
## il porte les six refus : case vide, non apprise, mauvaise arme, réserve, recharge, orbite pleine.
func cast_slot(index: int) -> bool:
	if is_dead or _recharges.size() <= index or _recharges[index] > 0.0:
		return false
	var skill := bar.skill_of(index)
	if skill == null:
		return false
	var points := skill_points(skill.id)
	if points <= 0:
		return false
	var cast := resolve(skill, points)

	if skill.shape == Skill.Shape.AURA:
		# Tenir la touche n'alterne pas : une aura qui clignote serait inutilisable.
		_held[index] = false
		if aura_lit():
			# Éteindre n'est pas lancer : ni coût, la recharge seulement contre le rebond.
			_aura.extinguish()
			_aura = null
			_recharges[index] = cast.interval
			return true
	# Après l'extinction : changer d'arme ne doit pas empêcher d'éteindre une aura.
	if not skill.usable_with(_weapon_base()):
		return false
	if mana < cast.mana_cost:
		return false
	# Refusée plutôt que de remplacer la plus ancienne : la touche tenue paierait pour
	# rien.
	if skill.shape == Skill.Shape.ORBIT and _blade_crown().full(cast.max_simultaneous()):
		return false

	_set_mana(mana - cast.mana_cost)
	_recharges[index] = cast.interval
	# La forme de la compétence et non celle du geste : aucun nœud ne la change.
	match skill.shape:
		Skill.Shape.BOLT:
			_roll(cast, bolt_scene)
		Skill.Shape.BALL:
			_roll(cast, orb_scene)
		Skill.Shape.CHAIN:
			if ChainLightning.unload(_effects_parent(), self, cast, facing) > 0:
				Game.hit_stop()
				Game.shake_camera(camera, shake_amount)
		Skill.Shape.CLOUD:
			StormCloud.put(_effects_parent(), _aim_point(), cast, states)
		Skill.Shape.SNAKE:
			HellSnake.drop(_effects_parent(), _aim_point(), cast, facing, states)
		Skill.Shape.AURA:
			_aura = Immolation.ignite(self, skill)
		Skill.Shape.ORBIT:
			_blade_crown().add_to(cast)
		Skill.Shape.STRIKE:
			_swing(cast, SwingArc.Style.STRIKE)
		Skill.Shape.CROSS:
			_swing(cast, SwingArc.Style.CROSS)
		_:
			_swing(cast)
	return true


func aura_lit() -> bool:
	return is_instance_valid(_aura) and _aura.lit()


## Combien d'épées tournent autour du personnage.
func orbiting_swords() -> int:
	return _crown.count() if _crown != null else 0


## Ce qu'une aura coûte à son porteur cette image-ci, réparti entre les natures comme
## ses dégâts, chaque part par `CharacterStats.mitigate()`, engourdissement compris.
## **Pas un coup** : ni esquive ni plancher. L'armure se compte sur la perte **par
## seconde**, pas sur la tranche d'une image. Mortelle.
func burn(part_per_second: float, distribution: Array[float], delta: float) -> void:
	if is_dead or part_per_second <= 0.0:
		return
	var per_second := stats.max_health * part_per_second
	var taken_value := 0.0
	for kind in distribution.size():
		taken_value += stats.mitigate(kind, per_second * distribution[kind])
	var loss := taken_value * states.damage_taken_factor * delta
	_set_health(health - loss)
	var digit := _burn_to_show.add_to(loss, delta)
	HitFeedback.damage_without_hit(hurtbox.global_position, digit, true)
	if health <= 0.0:
		_die()


## Ce que les états brûlent, ôté par le seul chemin de la vie.
func _suffer_states(delta: float) -> void:
	var loss := states.advance(delta)
	if loss <= 0.0:
		return
	_set_health(health - loss)
	var digit := states.digit()
	HitFeedback.damage_without_hit(hurtbox.global_position, digit, true)
	if health <= 0.0:
		_die()


## Ce que sa pourriture lui rend.
func _heal(amount: float) -> void:
	if not is_dead:
		_set_health(health + amount)


## Un état neuf s'annonce : la pastille seule ne dirait pas pourquoi on ralentit.
func _announce_state(kind: int) -> void:
	if HitFeedback.current != null:
		HitFeedback.current.state(hurtbox.global_position, kind)


func _show_states() -> void:
	sprite.show_states(states)
	health_bar.show_states(states)


## Au curseur, à `PLACEMENT_RANGE` au plus ; à la manette, à cette distance devant.
func _aim_point() -> Vector2:
	var toward := facing * PLACEMENT_RANGE
	if _aim_with_mouse:
		toward = (get_global_mouse_position() - global_position).limit_length(PLACEMENT_RANGE)
	return global_position + toward


## Où naissent tirs, nuages et serpents ; à défaut d'un conteneur, à côté du joueur.
func _effects_parent() -> Node:
	return projectile_parent if projectile_parent != null else get_parent()


func _blade_crown() -> BladeCrown:
	if _crown == null:
		_crown = BladeCrown.new()
		_crown.author = states
		add_child(_crown)
	return _crown


## **Le chemin du lancer et de la page du manuel** : fiche et modificateurs de mot-clé.
func resolve(skill: Skill, points: int) -> SkillStats:
	return skill.resolve(points, stats, skill_mods, talents_of(skill.id))


## Publique pour le voile de la barre.
func remaining_cooldown(index: int) -> float:
	return _recharges[index] if index >= 0 and index < _recharges.size() else 0.0


## Les points du manuel qui l'enseigne, ou l'unique point d'une attaque de départ ;
## zéro si son livre a quitté le râtelier.
func skill_points(skill_id: String) -> int:
	var book := book_of(skill_id)
	if book != null:
		return book.manual.points_of(skill_id)
	if SkillCatalog.is_starting(skill_id):
		return BASIC_ATTACK_POINTS
	return 0


## **Le seul endroit qui le cherche** : points et nœuds viennent du même livre.
func book_of(skill_id: String) -> Item:
	for book in rack.equipped_items():
		if book.teaches(skill_id):
			return book
	return null


## Vides pour une attaque de départ, qui n'a pas de case.
func talents_of(skill_id: String) -> Array[InvestedTalent]:
	var book := book_of(skill_id)
	return book.invested_talents(skill_id) if book != null else [] as Array[InvestedTalent]


## **Le seul chemin** : un passif change la fiche, le recalcul ne s'oublie pas.
func invest(slot: int, identifier: String) -> bool:
	var book := rack.at(slot)
	if book == null or book.base.manual == null:
		return false
	if not book.manual.invest(book.base.manual, identifier):
		return false
	_after_equipment_change()
	return true


## Reprend un point d'une case, d'un passif ou d'un nœud — `Manual` dit quand.
## Une compétence retombée à zéro sort de la barre, comme quand son livre part.
func refund(slot: int, identifier: String) -> bool:
	var book := rack.at(slot)
	if book == null or book.base.manual == null:
		return false
	if not book.manual.refund(book.base.manual, identifier):
		return false
	_clear_bar_of(book.base.manual.skills())
	_after_equipment_change()
	return true


## Ce qu'on peut poser dans une case de barre : les deux attaques de départ, et
## toute case des manuels à l'étude où l'on a mis au moins un point.
func available_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for id: String in SkillCatalog.STARTING:
		out.append(SkillCatalog.by_id(id))
	for book in rack.equipped_items():
		for skill in book.base.manual.skills():
			if book.manual.points_of(skill.id) > 0:
				out.append(skill)
	return out


## Un coup par coup du geste — deux pour une croix —, chacun tiré, avec sa hitbox.
func _swing(cast: SkillStats, style := SwingArc.Style.ARC) -> void:
	_is_swinging = true
	_hit_shake = shake_amount * (STRIKE_SHAKE if style == SwingArc.Style.STRIKE else 1.0)
	swing_arc.play(swing_duration * float(cast.hits), style)
	sprite.attack()

	for hit in cast.hits:
		if hit > 0:
			# Un ennemi déjà dedans n'y *entre* pas deux fois : la hitbox doit être fermée une
			# image de physique avant de se rouvrir.
			await get_tree().physics_frame
		_hit_parts = cast.roll(Game.rng)
		_hit_cast = cast
		_already_hit.clear()
		# set_deferred : on est peut-être dans un rappel de physique.
		hitbox.set_deferred("monitoring", true)
		# ignore_time_scale : sinon le hit-stop étire la fenêtre de swing.
		await get_tree().create_timer(swing_duration, true, false, true).timeout
		hitbox.set_deferred("monitoring", false)
	_is_swinging = false


## Les traits répartis sur l'écart du geste résolu : tout vient de
## `SkillStats`, rien n'est relu sur la compétence.
func _roll(cast: SkillStats, scene: PackedScene) -> void:
	if scene == null:
		return
	var parent := _effects_parent()
	var count := cast.projectile_count()

	# Un seul trait part droit devant, quelle que soit la dispersion.
	var spread := deg_to_rad(cast.spread_in_degrees)
	# Un cercle complet divise l'écart par le nombre de traits et non par les intervalles
	# — sinon le dernier retombe sur le premier —, décalé d'un demi-pas.
	var closes := is_equal_approx(spread, TAU)
	var step := 0.0
	var start := 0.0
	if count > 1:
		step = spread / float(count if closes else count - 1)
		start = -spread * 0.5 + (step * 0.5 if closes else 0.0)

	# Une fois pour la salve : la nature que le tir montre ne dépend pas du trait.
	var nature := cast.dominant_nature()
	for i in count:
		var direction := facing.rotated(start + step * float(i))
		# Un tirage par trait : trois traits identiques se liraient comme un seul coup.
		var bolt := Projectile.spawn(
			parent, scene, global_position, direction, cast.roll(Game.rng), self,
			cast.projectile_speed, nature, cast
		)
		if bolt is Fireball:
			(bolt as Fireball).explosion_radius = cast.radius


## Testé avant d'écrire : une barre pleine n'émet rien.
func _regen(delta: float) -> void:
	if stats.health_regen > 0.0 and health < stats.max_health:
		_set_health(health + stats.health_regen * delta)
	if stats.mana_regen > 0.0 and mana < stats.max_mana:
		_set_mana(mana + stats.mana_regen * delta)


## Reconstruit la fiche **de zéro** : additionner compterait les bonus à chaque appel.
func recompute_stats() -> void:
	stats = base_stats.duplicate()

	# Tous les objets d'un coup : les plats avant les pourcentages, quel que soit
	# l'ordre d'équipement.
	var mods: Array[StatMod] = []
	for slot in EquipmentSlots.ids():
		var item: Item = equipment.get(slot)
		if item != null:
			mods.append_array(item.mods())

	# Les passifs du râtelier et de l'arbre, dans la même liste et le même tri que les
	# objets.
	for book in rack.equipped_items():
		mods.append_array(book.passive_mods())
	mods.append_array(passive_tree.mods(passives))

	# En trois temps — attributs, dérivation, reste — pour que « +20 force » rapporte ses
	# PV et que « +10 % PV » les multiplie. Ce qui vise un mot-clé part à part, pour le
	# lancer.
	var over_attributes: Array[StatMod] = []
	var on_the_rest: Array[StatMod] = []
	var on_skills: Array[StatMod] = []
	for m in mods:
		# Un accru de chance critique multiplie au lancer la base que la fiche porte : l'arme et les plats.
		if not m.scope.is_empty() or (m.stat == SkillStats.CRIT_CHANCE and m.mode != StatMod.Mode.FLAT):
			on_skills.append(m)
		elif m.stat in CharacterStats.ATTRIBUTES:
			over_attributes.append(m)
		else:
			on_the_rest.append(m)
	StatMod.apply_all(stats, over_attributes)
	stats.apply_attributes()
	StatMod.apply_all(stats, on_the_rest)

	# La force ajoute ses dégâts aux attaques, lue sur la fiche **finale**.
	on_skills.append(StatMod.ranged(
		SkillStats.added_stat(DamageType.Kind.PHYSICAL),
		stats.strength_damage(), stats.strength_damage(), Keywords.ATTACK
	))
	skill_mods = on_skills

	# Un multiplicateur sous 1 transformerait un critique en coup amorti.
	stats.crit_multiplier = maxf(stats.crit_multiplier, 1.0)

	# Réassignée : la hurtbox défendrait sinon avec l'ancienne fiche.
	hurtbox.stats = stats


## Fait entrer un personnage sauvegardé dans ce corps, après son _ready. **Recopie** et
## non adoption : sac, râtelier et barre restent ceux que l'interface a liés.
func load_character(character: Character) -> void:
	if character == null:
		return

	level = clampi(character.level, 1, MAX_LEVEL)
	xp = character.experience if level < MAX_LEVEL else 0
	xp_to_next = _needed_for(level)
	passives = character.passives.duplicate()

	inventory.clear()
	for placed in character.bag.placed:
		# Sa place d'abord : un sac rechargé se retrouve tel qu'on l'a laissé.
		if not inventory.place(placed.data, placed.cell):
			inventory.add(placed.data)

	equipment.clear()
	for slot in character.equipment:
		# Un emplacement inconnu est écarté : il fausserait la fiche sans s'afficher.
		if EquipmentSlots.exists(slot):
			equipment[slot] = character.equipment[slot]

	# Recopiés comme le sac, pour la même raison.
	for i in Rack.SLOT_COUNT:
		rack.remove(i)
		rack.put(i, character.rack.at(i))
	for i in SkillBar.SLOT_COUNT:
		bar.put(i, character.bar.id_of(i))
	manual_given = character.manual_given

	sprite.set_variant(character.silhouette)
	# Recalcul, plafonds et arme visible : trois choses qu'on oublierait à la main.
	_after_equipment_change()
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)

	# Sans ces signaux, HUD et fiche attendraient le premier ennemi tué.
	xp_changed.emit(xp, xp_to_next, level)
	passives_changed.emit()


## L'inverse, avant l'écriture : rien de calculé.
func fill(character: Character) -> void:
	if character == null:
		return
	character.level = level
	character.experience = xp
	character.passives = passives.duplicate()
	character.silhouette = sprite.current_variant()

	character.bag = Inventory.new(inventory.cols, inventory.rows)
	for placed in inventory.placed:
		character.bag.place(placed.data, placed.cell)
	character.equipment = equipment.duplicate()

	character.rack = Rack.new()
	for i in Rack.SLOT_COUNT:
		character.rack.put(i, rack.at(i))
	character.bar = SkillBar.new()
	for i in SkillBar.SLOT_COUNT:
		character.bar.put(i, bar.id_of(i))
	character.manual_given = manual_given


## Porte un objet et rend celui qu'il remplace. `slot` vide : le premier libre
## (le ramassage) ; le panneau impose le sien. Rend l'objet lui-même s'il est refusé.
func equip(item: Item, slot := "") -> Item:
	if item == null:
		return null
	var target := slot if not slot.is_empty() else EquipmentSlots.free_for(item, equipment)
	if target.is_empty() or not EquipmentSlots.accepts(target, item):
		return item
	var old: Item = equipment.get(target)
	equipment[target] = item
	_after_equipment_change()
	return old


## Le pendant d'`equip()` pour ce qui se lit : l'objet refusé est rendu. `index` à -1 :
## le premier emplacement libre, à défaut le premier.
func study(item: Item, index := -1) -> Item:
	if not Rack.accepts(item):
		return item
	var target := index
	if target < 0:
		target = 0
		for i in Rack.SLOT_COUNT:
			if rack.at(i) == null:
				target = i
				break
	var old := rack.put(target, item)
	# Un manuel porte des passifs : le poser change la fiche.
	_after_equipment_change()
	return old


## Retire un manuel et **vide les cases de barre de ses compétences** : une case grisée
## se découvre au pire moment. Le seul chemin (page, rechargement).
func stop_studying(index: int) -> Item:
	var gone := rack.remove(index)
	if gone == null or gone.base.manual == null:
		return gone

	_clear_bar_of(gone.base.manual.skills())
	# Et ses passifs s'en vont avec lui.
	_after_equipment_change()
	return gone


## « La sait-on encore », pas « d'où venait-elle » : un autre livre peut l'enseigner.
func _clear_bar_of(skills: Array[Skill]) -> void:
	for skill in skills:
		if skill_points(skill.id) > 0:
			continue
		for i in SkillBar.SLOT_COUNT:
			if bar.id_of(i) == skill.id:
				bar.clear(i)


func unequip(slot: String) -> Item:
	var item: Item = equipment.get(slot)
	if item == null:
		return null
	equipment.erase(slot)
	_after_equipment_change()
	return item


func equipped(slot: String) -> Item:
	return equipment.get(slot)


func remaining_passive_points() -> int:
	return PassiveTree.remaining_points(passives, level)


## Les deux seuls chemins de l'arbre ; les conditions sont dans `PassiveTree`.
func take_passive(id: String) -> bool:
	if not passive_tree.can_take(passives, id, level):
		return false
	passives.append(id)
	_after_passives_change()
	return true


func release_passive(id: String) -> bool:
	if not passive_tree.can_release(passives, id):
		return false
	passives.remove_at(passives.find(id))
	_after_passives_change()
	return true


## Les plafonds ont bougé : un nœud de PV ou de mana les change.
func _after_passives_change() -> void:
	recompute_stats()
	_set_health(health)
	_set_mana(mana)
	passives_changed.emit()


## La fiche change, donc les plafonds : la vie courante redescend sous le nouveau. Un
## manuel passe par ici aussi, ses passifs étant une pièce d'armure.
func _after_equipment_change() -> void:
	recompute_stats()
	_set_health(health)
	_set_mana(mana)
	sprite.set_weapon(weapon_kind())
	equipment_changed.emit()


## L'arme visible, vide pour celle de la fiche. Publique : la fenêtre de personnage
## dessine la même silhouette.
func weapon_kind() -> String:
	var base := _weapon_base()
	return "" if base == null else base.kind


func _weapon_base() -> ItemBase:
	var weapon: Item = equipment.get(EquipmentSlots.WEAPON)
	return null if weapon == null else weapon.base


## **Le seul chemin pour changer la vie** : la barre suit, le plafond s'applique.
func _set_health(value: float) -> void:
	health = clampf(value, 0.0, stats.max_health)
	health_bar.set_health(health, stats.max_health)
	health_changed.emit(health, stats.max_health)


## Le pendant du précédent pour la réserve, plafond compris.
func _set_mana(value: float) -> void:
	mana = clampf(value, 0.0, stats.max_mana)
	mana_changed.emit(mana, stats.max_mana)


func _needed_for(lvl: int) -> int:
	return 0 if lvl >= MAX_LEVEL else Progression.level_cost(lvl, XP_BASE, XP_POWER)


## Appelée par l'EnemyManager quand un ennemi meurt d'un vrai coup.
func gain_xp(amount: int) -> void:
	if is_dead or amount <= 0 or level >= MAX_LEVEL:
		return
	xp += amount
	# Une boucle et non un test : un ennemi qui vaut beaucoup peut faire monter
	# de deux niveaux d'un coup.
	while level < MAX_LEVEL and xp >= xp_to_next:
		xp -= xp_to_next
		_level_up()
	if level >= MAX_LEVEL:
		xp = 0
	xp_changed.emit(xp, xp_to_next, level)


func _level_up() -> void:
	level += 1
	xp_to_next = _needed_for(level)
	passives_changed.emit()
	_set_health(health + stats.max_health * LEVEL_HEAL)
	_set_mana(mana + stats.max_mana * LEVEL_HEAL)
	leveled_up.emit(level)


## **Le seul chemin** d'une récompense, mort ou boule d'expérience : le retard sur la
## zone, puis le joueur et les manuels du râtelier, **du même montant**. Rien ne la
## borne vers le haut : descendre plus bas rapporte mieux.
func reward(raw: float, zone_level_value: int, where: Vector2) -> int:
	var gain := maxi(roundi(raw * Enemy.experience_factor(zone_level_value, level)), 1)
	gain_xp(gain)
	for book in rack.equipped_items():
		book.manual.gain_experience(gain)
	if HitFeedback.current != null:
		HitFeedback.current.xp_gain(where, gain)
	return gain


## Faux quand le sac est plein : l'objet reste au sol.
func pick_up(item: Item) -> bool:
	if item == null:
		return false
	var taken := inventory.add(item)
	# Le livre de départ est « donné » quand il est **pris**, pas quand il tombe ; un
	# joueur qui le jette n'en reçoit pas un second.
	if taken and item.manual != null:
		manual_given = true
	if HitFeedback.current != null:
		HitFeedback.current.loot_gain(
			global_position, item.display_name() if taken else Texts.t("sac plein")
		)
	return taken


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area is Hurtbox or area in _already_hit:
		return
	_already_hit.append(area)   # un swing ne touche une cible qu'une fois

	var info := DamageInfo.roll(_hit_cast, global_position, _hit_parts, stats.knockback_force)
	info.author = states
	(area as Hurtbox).take_damage(info)

	# **Au premier touché seulement** : un balayage est un geste, pas cinq.
	if _already_hit.size() == 1:
		Game.hit_stop()
		Game.shake_camera(camera, _hit_shake)


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	_set_health(health - info.amount)
	velocity += (global_position - info.source_position).normalized() * info.knockback
	sprite.flash()
	if health <= 0.0:
		_die()


## Le drapeau évite plusieurs `died` : plusieurs grunts frappent dans la même image.
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	# Ce qui frappait pour lui s'éteint avec lui.
	if aura_lit():
		_aura.extinguish()
	_aura = null
	if _crown != null:
		_crown.clear()
	# Un corps relevé ne se relève pas en flammes.
	states.clear()
	died.emit()   # l'écran de fin de run se branchera ici


func revive() -> void:
	is_dead = false
	# Un corps tombé encaisse toujours : ses tirages ont pu reposer des états.
	states.clear()
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	velocity = Vector2.ZERO
	set_physics_process(true)
