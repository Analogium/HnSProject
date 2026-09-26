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
## Un geste entretenu s'est allumé ou éteint : le bandeau en montre les icônes.
signal buffs_changed
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
## De combien on recule le long de la visée quand l'arrivée d'une ruée est prise. Huit
## pixels : plus fin ne se voit pas, plus gros fait rater une embrasure.
const LANDING_STEP := 8.0

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
## Le corps, pour chercher où une ruée peut atterrir.
@onready var body_shape: CollisionShape2D = $CollisionShape2D

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
## Ce que valait cette recharge au lancer, pour le voile de la barre. Gardé plutôt que
## recalculé : un nœud peut avoir changé l'intervalle (jalon 23), et `Skill.interval()`
## ne connaît pas les nœuds.
var _recharge_totals := PackedFloat32Array()
## Les cases tenues depuis un appui **né en jeu** : sinon le clic qui choisit une
## compétence dans le menu de la barre la lancerait aussitôt.
var _held: Array[bool] = []
## Les parts du coup en cours, **tirées une fois au départ du geste** : tout l'arc
## reçoit la même valeur.
var _hit_parts: Array[float] = []
var _hit_cast: SkillStats
var _hit_shake := 0.0
var _is_swinging := false
## Les gestes entretenus allumés, par identifiant de compétence : une aura et les
## buffs. Leurs nœuds vivent sous le joueur ; le dictionnaire dit lequel répond à
## quelle case.
var _lit := {}
## L'identifiant du geste entretenu qui enferme son lanceur, ou vide. Tenu à jour à
## l'allumage plutôt que relu à chaque image : il est lu par le déplacement.
var _bound := ""
var _crown: BladeCrown
## Ce que la brûlure d'Immolation a pris depuis le dernier chiffre affiché.
var _burn_to_show := StatusEffects.Pack.new()
var _already_hit: Array[Node] = []
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true


func _ready() -> void:
	camera.zoom = Vector2.ONE * Game.WORLD_ZOOM
	Settings.veil(swing_arc, Settings.SPELLS)
	# Sans .tres assigné on part sur des valeurs par défaut plutôt que de planter.
	if base_stats == null:
		base_stats = CharacterStats.new()
	_recharges.resize(SkillBar.SLOT_COUNT)
	_recharge_totals.resize(SkillBar.SLOT_COUNT)
	_held.resize(SkillBar.SLOT_COUNT)
	recompute_stats()
	xp_to_next = _needed_for(level)
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.damaged.connect(_on_damaged)
	hurtbox.states = states
	states.struck.connect(_on_struck)
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
	# Enfermé dans la glace : la visée et le sprite suivent encore, les pieds non. Et
	# ZQSD tapé dans un champ de texte — la recherche de l'arbre — ne fait pas marcher.
	if not _bound.is_empty() or get_viewport().gui_get_focus_owner() is LineEdit:
		input = Vector2.ZERO

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

	# Sondage des cinq cases, sauf quand un panneau tient la souris ou qu'une étiquette
	# de butin réclame le clic gauche. Tenue, la touche relance à chaque fin de
	# recharge : la cadence est celle de `cast_slot()`.
	for i in SkillBar.SLOT_COUNT:
		var action := "skill_%d" % (i + 1)
		if Game.ui_grabs_input or GroundItem.takes_the_click(action):
			_held[i] = false
			continue
		if not Input.is_action_pressed(action):
			_held[i] = false
			continue
		if Input.is_action_just_pressed(action):
			_held[i] = true
		if _held[i]:
			cast_slot(i)


## Lance la compétence de cette case. **Le seul chemin** — touches, barre, tests — et
## il porte les sept refus : case vide, non apprise, mauvaise arme, réserve, recharge, orbite
## pleine, morts-vivants au complet.
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

	if _is_sustained(skill.shape):
		# Tenir la touche n'alterne pas : un geste entretenu qui clignote serait
		# inutilisable.
		_held[index] = false
		if lit(skill.id):
			# Éteindre n'est pas lancer : ni coût, la recharge seulement contre le rebond.
			extinguish(skill.id)
			_start_recharge(index, cast.interval)
			return true
	# Après l'extinction : changer d'arme ne doit pas empêcher d'éteindre ce qui brûle,
	# et le tombeau de glace ne laisse partir que lui-même.
	if not _bound.is_empty() and skill.id != _bound:
		return false
	if not skill.usable_with(_weapon_base()):
		return false
	if mana < cast.mana_cost:
		return false
	# Refusée plutôt que de remplacer la plus ancienne : la touche tenue paierait pour
	# rien.
	if skill.shape == Skill.Shape.ORBIT and _blade_crown().full(cast.max_simultaneous()):
		return false
	if skill.shape == Skill.Shape.SUMMON \
			and Minion.count_of(self, skill.id) >= cast.max_simultaneous():
		return false

	_set_mana(mana - cast.mana_cost)
	_start_recharge(index, cast.interval)
	# Tout lancer anime le lanceur, un sort comme un coup d'arme : sans ça, la
	# sorcière lançait ses sorts immobile. Pas la ruée, où le corps traverse l'écran.
	if skill.shape != Skill.Shape.DASH:
		sprite.attack(skill.cadence == Skill.Cadence.CAST)
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
			_light(skill.id, Immolation.ignite(self, skill))
		Skill.Shape.BUFF:
			# Sa durée, ou zéro : un buff sans durée brûle tant qu'on le paie.
			_light(skill.id, Buff.light(self, skill, cast.duration))
		Skill.Shape.CYCLONE:
			_light(skill.id, Cyclone.spin(self, skill))
		Skill.Shape.DASH:
			_dash(skill, cast)
		Skill.Shape.WAVE:
			_swing(cast)
			SlashWave.send(_effects_parent(), global_position, facing, cast, states)
		Skill.Shape.SPIKES:
			IceSpikes.raise_at(_effects_parent(), _aim_point(), cast, states)
		Skill.Shape.NOVA:
			# L'explosion de la boule de feu, posée sur soi : elle frappe une fois son
			# cercle et s'efface, ce qu'une nova fait exactement.
			Explosion.put(
				_effects_parent(), global_position, cast.roll(Game.rng), cast.radius, null,
				DamageType.COLORS[cast.dominant_nature()], states, cast
			)
		Skill.Shape.VORTEX:
			IceVortex.open(_effects_parent(), global_position, cast, states)
		Skill.Shape.BEAM:
			HolyBeam.fire(_effects_parent(), global_position, facing, cast, states)
		Skill.Shape.PILLAR:
			SacredPillar.fall(_effects_parent(), _aim_point(), cast, states)
		Skill.Shape.PULSE:
			# Portée par le joueur et non posée : elle suit celui qui l'a lancée.
			HolyPulse.emanate(self, cast)
		Skill.Shape.ORBIT:
			_blade_crown().add_to(cast)
		Skill.Shape.SUMMON:
			Minion.raise(self, cast, _effects_parent())
		Skill.Shape.GATE:
			RottingGate.open(_effects_parent(), _aim_point(), cast, states)
		Skill.Shape.CURSE:
			PutridCurse.fall(_effects_parent(), _aim_point(), cast, states)
		Skill.Shape.STRIKE:
			_swing(cast, SwingArc.Style.STRIKE)
		Skill.Shape.CROSS:
			_swing(cast, SwingArc.Style.CROSS)
		_:
			_swing(cast)
	return true


## Ce geste entretenu brûle-t-il en ce moment.
func lit(skill_id: String) -> bool:
	# Sans type : assigner une instance déjà libérée à une variable typée est en soi une
	# erreur, avant même le test de validité (invariant 4).
	var node: Variant = _lit.get(skill_id)
	return is_instance_valid(node) and not (node as Node).is_queued_for_deletion()


## Une aura, quelle qu'elle soit : ce que la mort et l'arène demandent.
func aura_lit() -> bool:
	for id: String in _lit:
		if lit(id) and _lit[id] is Immolation:
			return true
	return false


## **Le seul chemin de l'extinction**, touche ou réserve vide : le nœud s'en va et la
## fiche perd les lignes du buff.
func extinguish(skill_id: String) -> void:
	var node: Variant = _lit.get(skill_id)
	_lit.erase(skill_id)
	if is_instance_valid(node):
		(node as Node).extinguish()
	_after_buff_change()


## L'allumage, son pendant : la fiche reçoit les lignes du buff.
func _light(skill_id: String, node: Node) -> void:
	# Une ruée relancée avant la fin de son buff remplace le sien : sans ça le premier
	# nœud brûlerait sans que rien ne le tienne plus.
	var old: Variant = _lit.get(skill_id)
	if is_instance_valid(old) and old != node:
		(old as Node).extinguish()
	_lit[skill_id] = node
	_after_buff_change()


static func _is_sustained(shape: Skill.Shape) -> bool:
	return shape in [Skill.Shape.AURA, Skill.Shape.BUFF, Skill.Shape.CYCLONE]


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
	HitFeedback.damage_without_hit(hurtbox.overhead(), digit, true)
	if health <= 0.0:
		_die()


## Ce qu'un geste entretenu **rend** cette image-ci, en part des PV max : le pendant de
## `burn()`, sans mitigation — un soin ne se résiste pas.
func mend(part_per_second: float, delta: float) -> void:
	if part_per_second > 0.0:
		_heal(stats.max_health * part_per_second * delta)


## Ce qu'un geste entretenu prend à la réserve cette image-ci, **à plat**. Faux quand
## elle est vide : le geste s'éteint, là où la brûlure des PV tue. Aucun drain demandé,
## rien à payer.
func drain(mana_per_second: float, delta: float) -> bool:
	if mana_per_second <= 0.0:
		return true
	var cost := mana_per_second * delta
	if mana < cost:
		return false
	_set_mana(mana - cost)
	return true


## Ce que les états brûlent, ôté par le seul chemin de la vie.
func _suffer_states(delta: float) -> void:
	var loss := states.advance(delta)
	if loss <= 0.0:
		return
	_set_health(health - loss)
	var digit := states.digit()
	HitFeedback.damage_without_hit(hurtbox.overhead(), digit, true)
	if health <= 0.0:
		_die()


## Ce que sa pourriture lui rend.
func _heal(amount: float) -> void:
	if not is_dead:
		_set_health(health + amount)


## Un coup du joueur vient de toucher : **le seul endroit** qui tire la charge statique.
## La condition porte sur l'état — chance non nulle, cible engourdie — et jamais sur le
## résultat, donc le nombre de tirages ne dépend pas de ce qui sort (invariant 3).
func _on_struck(at: Vector2, parts: Array, victim: StatusEffects) -> void:
	if stats.static_charge_chance <= 0.0 or victim == null:
		return
	if not victim.active(StatusEffects.Kind.NUMB):
		return
	if Game.rng.randf() * 100.0 >= stats.static_charge_chance:
		return
	StaticCharge.put(_effects_parent(), at, at - global_position, parts, states)


## Un état neuf s'annonce : la pastille seule ne dirait pas pourquoi on ralentit.
func _announce_state(kind: int) -> void:
	if HitFeedback.current != null:
		HitFeedback.current.state(hurtbox.overhead(), kind)


func _show_states() -> void:
	sprite.show_states(states)
	health_bar.show_states(states)


## Une ruée : on se **porte** au curseur, murs et ennemis traversés — seule l'arrivée
## doit être libre. Ni gel ni secousse : ce qui dure ne fige jamais.
##
## Ce qu'elle laisse derrière, **jamais les deux** : une trace qui frappe quand elle a
## un rayon et une période, ou un buff bref sur le lanceur quand elle a des lignes.
func _dash(skill: Skill, cast: SkillStats) -> void:
	var from_value := global_position
	global_position = _landing(from_value, _aim_point())
	if cast.period > 0.0 and cast.radius > 0.0:
		DashTrail.leave(_effects_parent(), from_value, global_position, cast, states)
	elif skill.grants_buffs():
		_light(skill.id, Buff.light(self, skill, cast.duration))


## Le point le plus proche de la visée où le corps tient, en reculant vers le départ.
## Le départ ferme la marche : on en vient, donc on y tient.
func _landing(from_value: Vector2, toward: Vector2) -> Vector2:
	var steps := maxi(ceili(from_value.distance_to(toward) / LANDING_STEP), 1)
	for i in steps:
		var point := toward.lerp(from_value, float(i) / float(steps))
		if _fits_at(point):
			return point
	return from_value


## **Le décor seul** : un ennemi sous les pieds se repousse de lui-même à l'image
## suivante, la roche non.
func _fits_at(point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body_shape.shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = Targets.DECOR
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


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
		Settings.veil(_crown, Settings.SPELLS)
	return _crown


## **Le chemin du lancer et de la page du manuel** : fiche et modificateurs de mot-clé.
func resolve(skill: Skill, points: int) -> SkillStats:
	return skill.resolve(points, stats, skill_mods, talents_of(skill.id))


## Les deux ensemble : gardés séparément, l'un finirait par ne plus décrire l'autre.
func _start_recharge(index: int, interval: float) -> void:
	_recharges[index] = interval
	_recharge_totals[index] = interval


## Ce qu'il reste à attendre, en secondes : la barre s'en sert pour savoir si elle se
## repeint. Le voile, lui, veut une part — `cooldown_ratio()`.
func remaining_cooldown(index: int) -> float:
	return _recharges[index] if index >= 0 and index < _recharges.size() else 0.0


## La part de recharge qu'il reste, de 1 à 0 : contre **l'intervalle du lancer**, le
## seul que les nœuds de la case aient pu changer.
func cooldown_ratio(index: int) -> float:
	if index < 0 or index >= _recharges.size() or _recharge_totals[index] <= 0.0:
		return 0.0
	return clampf(_recharges[index] / _recharge_totals[index], 0.0, 1.0)


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
	# objets — et les buffs allumés, qui ne durent que tant qu'on les paie.
	for book in rack.equipped_items():
		mods.append_array(book.passive_mods())
	mods.append_array(passive_tree.mods(passives))
	mods.append_array(buff_mods())

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

	# Ce que le joueur inflige en plus voyage avec ses états : c'est le seul attribut de
	# l'attaquant qui arrive jusqu'à la hurtbox de la cible.
	for kind in StatusEffects.CHANCE_STATS.size():
		var field: String = StatusEffects.CHANCE_STATS[kind]
		if not field.is_empty():
			states.chance_factors[kind] = 1.0 + float(stats.get(field)) * 0.01

	# Réassignée : la hurtbox défendrait sinon avec l'ancienne fiche.
	hurtbox.stats = stats


## Ce que les buffs allumés versent dans la fiche, par point placé : les lignes d'un
## passif, par la même fonction. Un livre parti éteint la case et vide ses lignes.
func buff_mods() -> Array[StatMod]:
	var out: Array[StatMod] = []
	for skill in lit_skills():
		out.append_array(skill.buff_mods(skill_points(skill.id)))
	return out


## Ce qui brûle en ce moment, **dans l'ordre d'allumage** : la fiche y prend ses lignes,
## le bandeau ses icônes.
func lit_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for id: String in _lit:
		if not lit(id):
			continue
		var skill := SkillCatalog.by_id(id)
		if skill != null:
			out.append(skill)
	return out


## Ce qu'il reste à ce geste, entre 0 et 1. **Un pour ce qui dure tant qu'on le paie** —
## une aura, un buff sans durée : le bandeau n'y dessine aucun voile.
func lit_ratio(skill_id: String) -> float:
	var node: Variant = _lit.get(skill_id)
	if not is_instance_valid(node) or not node is Buff:
		return 1.0
	return (node as Buff).remaining_ratio()


## Les plafonds ont pu bouger avec les lignes du buff, comme à un changement d'objet.
func _after_buff_change() -> void:
	_bound = ""
	for skill in lit_skills():
		if skill.binds_caster:
			_bound = skill.id
	recompute_stats()
	_set_health(health)
	_set_mana(mana)
	buffs_changed.emit()


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

	sprite.set_archetype(character.archetype())
	var lift := SpriteForge.head_room(character.archetype())
	health_bar.lift = lift
	hurtbox.feedback_lift = lift
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
			hurtbox.overhead(), item.display_name() if taken else Texts.t("sac plein")
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
	# Ce qui brûlait pour lui s'éteint avec lui.
	for id: String in _lit.keys():
		extinguish(id)
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
