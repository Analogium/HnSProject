class_name Projectile
extends Area3D

## Tir générique du caster et du joueur : avancer, s'arrêter au mur, blesser la
## première Hurtbox. Les layers de la scène décident de qui il touche.

@export var speed: float = 140.0
## Zéro : ce jeu n'a pas de recul.
@export var knockback: float = 0.0
@export var lifetime: float = 3.0
## Les tirs du joueur figent le jeu à l'impact ; ceux des ennemis non.
@export var hit_stop_on_impact: bool = false
## La nature de la scène : celle des tirs ennemis, et la couleur par défaut. Le joueur
## passe celle de son geste (`setup`), pour qu'un sort converti change de couleur.
@export var damage_type: DamageType.Kind = DamageType.Kind.PHYSICAL

## Distance à laquelle le tir naît devant son lanceur. Trop court, il apparaît
## dans le corps et touche le tireur lui-même ; trop loin, il saute une case.
const MUZZLE := 12.0

var _dir := Vector3.RIGHT
## Les parts du coup, par nature, tirées au lancer.
var _parts: Array[float] = []
var _source: Node3D
## Les états du lanceur, lus à la naissance du tir et gardés jusqu'à l'impact : le
## tir d'un caster mort en vol frappe encore, et sa bénédiction avec.
var _author: StatusEffects
## Le lancer du joueur, null pour un tir ennemi.
var _cast: SkillStats
var _life := 0.0
## La nature montrée, ou -1 pour celle de la scène.
var _nature := -1
## Ce qu'il a déjà frappé, par identifiant : un tir qui traverse ne frappe pas deux fois
## la même cible, et ses éclats non plus.
var _struck := {}
var _pierced := 0
var _bounced := 0
var _caromed := 0
## Le Grésil (jalon 44) : l'ennemi que l'éclat cherche.
var _quarry: Hurtbox
## Le Spectre (jalon 49) : partagé par les traits d'une salve, les éléments qui ont déjà
## touché chaque cible, par identifiant.
var salvo_hits := {}
## Le Chatoiement (jalon 49) : le lancer de chaque rebond, pris au départ.
var _turns: Array[SkillStats] = []
## L'os des Lanceurs d'os (jalon 45) : dessiné, il tournoie et ne s'oriente pas.
var bone := false
## Ce qui le montre : l'éclair de la foudre, ou la traînée d'étincelles des autres natures.
var _bolt_fx: BoltFx
var _trail: ElementFx


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func tint() -> Color:
	return DamageType.COLORS[nature()]


## La nature du tir : celle que le lanceur a passée, sinon celle de la scène.
func nature() -> DamageType.Kind:
	return _nature if _nature >= 0 else damage_type


## add_child d'abord, sinon global_position ne veut rien dire. Immédiat : un tir ne
## part jamais d'un rappel de collision.
static func spawn(
	parent: Node, scene: PackedScene, from: Vector3, dir: Vector3,
	parts: Array[float], source: Node3D, p_speed := 0.0, nature := -1, cast: SkillStats = null
) -> Projectile:
	var bolt := _spawn(parent, scene, from, dir)
	if bolt != null:
		bolt._cast = cast
		if cast != null:
			bolt._turns = cast.bounce_turns
		bolt.setup(dir, parts, source, p_speed, nature)
		bolt._show(Settings.SPELLS)
	return bolt


## Le chemin des ennemis : la nature reste écrite dans `enemy_bolt.tscn`.
static func spawn_of_nature(
	parent: Node, scene: PackedScene, from: Vector3, dir: Vector3,
	amount: float, source: Node3D
) -> Projectile:
	var bolt := _spawn(parent, scene, from, dir)
	if bolt != null:
		var parts := DamageType.empty_parts()
		parts[bolt.damage_type] = amount
		bolt.setup(dir, parts, source)
		bolt._show(Settings.ENEMY_ATTACKS)
	return bolt


## Son voile, puis ce qui le montre, qui le reprend.
func _show(group: StringName) -> void:
	Settings.veil(self, group)
	_dress()


## L'éclair pour la foudre (`BoltFx`), les étincelles de sa nature sinon (`ElementFx`). Un
## rebond du Chatoiement change de nature : l'ancien visuel s'efface, le neuf prend la suite.
func _dress() -> void:
	if _bolt_fx != null:
		_bolt_fx.queue_free()
		_bolt_fx = null
	if _trail != null:
		_trail.let_go()
		_trail = null
	if nature() == DamageType.Kind.LIGHTNING:
		_bolt_fx = BoltFx.show_on(self, nature())
	else:
		_trail = ElementFx.trail(self, tint())


static func _spawn(parent: Node, scene: PackedScene, from: Vector3, dir: Vector3) -> Projectile:
	if scene == null or parent == null:
		return null
	var bolt: Projectile = scene.instantiate()
	parent.add_child(bolt)
	bolt.global_position = from + dir * MUZZLE
	return bolt


## Après add_child. `speed` à zéro garde celle de la scène (tirs ennemis) ; la durée
## de vie reste sur la scène, donc un tir plus rapide porte plus loin. Parts recopiées.
func setup(
	dir: Vector3, parts: Array[float], source: Node3D, p_speed := 0.0, nature := -1
) -> void:
	_dir = dir.normalized()
	_parts = parts.duplicate()
	_source = source
	_author = StatusEffects.of(source)
	if p_speed > 0.0:
		speed = p_speed
	# Négative, on garde celle de la scène : c'est le cas des tirs ennemis, qui
	# n'ont pas de geste résolu derrière eux.
	if nature >= 0:
		_nature = nature


func _physics_process(delta: float) -> void:
	if _cast != null and _cast.lightning_rod > 0.0:
		_home(delta)
	elif _cast != null and (_cast.seek_radius > 0.0 or _cast.vector > 0.0):
		_seek(delta)
	global_position += _dir * speed * delta
	_life += delta
	if _life >= lifetime:
		_finish()


## Hors de `_on_area_entered` : `Fireball` décide d'exploser avant l'appel parent.
func strikes(area: Area3D) -> bool:
	return area is Hurtbox and not _struck.has(area.get_instance_id())


func _on_area_entered(area: Area3D) -> void:
	if not strikes(area):
		return
	_struck[area.get_instance_id()] = true
	if _cast != null and _cast.precipitate > 0.0:
		_precipitate(area as Hurtbox)
	var info := DamageInfo.roll(_cast, global_position, _conducted(area as Hurtbox), knockback)
	info.author = _author
	if _cast != null and _cast.spectrum > 0.0:
		info.multiplier(_spectrum(area as Hurtbox))
	info.multiplier(_hit_factor())
	(area as Hurtbox).take_damage(info)
	# Le lanceur porte l'affixe : c'est lui qu'on soigne. **Valide avant le `as`** : un
	# caster libéré ferait sinon traverser le joueur par son tir (invariant 4).
	if is_instance_valid(_source):
		var caster := _source as Enemy
		if caster != null:
			caster.on_damage_dealt(info.amount)
	if hit_stop_on_impact:
		Game.hit_stop()
	if _cast != null and _cast.lightning_rod > 0.0:
		LightningRod.mark(get_parent(), area as Hurtbox, _author, _cast)
	if _cast != null and _cast.fracture > 0.0 and _fractures(area as Hurtbox):
		Projectile.fork.call_deferred(
			get_parent(), load(scene_file_path), global_position, _dir, speed, _nature, _source,
			_cast.fragment(), _struck.duplicate()
		)
	if _cast != null and _cast.contagion > 0.0 and _cast.inflicted_state >= 0:
		Projectile.contaminate.call_deferred(area, _cast.inflicted_state, _cast.contagion)
	if _keeps_flying(info):
		return
	if _cast != null and _pierced < int(_cast.pierce):
		_pierced += 1
		_shatter(true)
		return
	if _cast != null and _bounced < int(_cast.bounces):
		_bounced += 1
		_bounce.call_deferred()
		return
	if _lodge(area as Hurtbox):
		return
	_finish()


## Ce que ce tir ajoute à son coup, en facteur : 1, sauf le couteau (jalon 50).
func _hit_factor() -> float:
	return 1.0


## Ce tir reste-t-il dans la cible où il s'arrête — il s'en charge alors : la lame plantée
## (jalon 50). Les autres finissent leur course.
func _lodge(_target: Hurtbox) -> bool:
	return false


## Ce tir passe-t-il outre la cible qu'il vient de frapper, sans rien compter : le couteau
## qui critique (jalon 50). Les autres tirs s'y arrêtent.
func _keeps_flying(_info: DamageInfo) -> bool:
	return false


## Repart vers l'ennemi non frappé le plus proche, **dans tout le reste de sa course** et
## dans toutes les directions : la portée d'un saut de chaîne (90 px) faisait échouer le
## rebond dès que les ennemis s'espaçaient. Différé : l'impact arrive d'un rappel de
## collision, où l'espace refuse les requêtes (invariant 4).
func _bounce() -> void:
	if is_queued_for_deletion():
		return
	var reach := speed * (lifetime - _life)
	var best := Targets.nearest(get_world_3d(), global_position, reach, _struck, true)
	if best == null:
		_finish()
		return
	_dir = global_position.direction_to(best.global_position)
	# Le Chatoiement (jalon 49) : le rebond prend le lancer du tour suivant.
	if _bounced <= _turns.size():
		_cast = _turns[_bounced - 1]
		_parts = _cast.roll(Game.rng)
		if _cast.nature != nature():
			_nature = _cast.nature
			_dress()


## Le Précipité (jalon 49) : les deux états des autres éléments, lus avant que le coup ne
## pose le sien, réagissent après lui.
func _precipitate(target: Hurtbox) -> void:
	var held := Reactions.held_by(target.states)
	held.erase(StatusEffects.rolled_by(nature()))
	if held.size() >= 2:
		Reactions.precipitate.call_deferred(get_parent(), target, held, _cast, _author)


## Le Spectre (jalon 49) : plus fort de chaque autre élément de la salve passé sur la cible.
func _spectrum(target: Hurtbox) -> float:
	var id := target.get_instance_id()
	var seen: Dictionary = salvo_hits.get(id, {})
	var others := seen.size() - (1 if seen.has(nature()) else 0)
	seen[nature()] = true
	salvo_hits[id] = seen
	return 1.0 + _cast.spectrum * 0.01 * float(others)


## Le Paratonnerre (jalon 43) : à portée de la marque de son lanceur, le tir s'incurve
## vers elle — un virage borné, pas un aimant : un tir qui la croise de loin la manque.
func _home(delta: float) -> void:
	var rod := LightningRod.target_of(_author)
	if rod == null or _struck.has(rod.get_instance_id()):
		return
	if global_position.distance_to(rod.global_position) <= SkillStats.ROD_REACH:
		_steer(rod.global_position, delta)


## Le Grésil (jalon 44) : vers l'ennemi non frappé le plus proche, gardé jusqu'à ce qu'il
## soit frappé ou mort. Le Vecteur de la Peste (jalon 45) : vers le plus proche **sain**,
## lâché dès qu'il se décompose.
func _seek(delta: float) -> void:
	var healthy := StatusEffects.Kind.DECAY if _cast.vector > 0.0 else -1
	if not is_instance_valid(_quarry) or _struck.has(_quarry.get_instance_id()) \
			or (healthy >= 0 and _quarry.has_state(healthy)):
		_quarry = Targets.nearest(
			get_world_3d(), global_position, maxf(_cast.seek_radius, _cast.vector), _struck, true, healthy
		)
	if _quarry != null:
		_steer(_quarry.global_position, delta)


func _steer(toward: Vector3, delta: float) -> void:
	var turn := SkillStats.ROD_TURN * delta
	_dir = Flat.rotated(_dir, clampf(Flat.angle_to(_dir, toward - global_position), -turn, turn))


## La Glace vive (jalon 43) : sur un transi, le trait de glace ajoute une part de foudre.
func _conducted(target: Hurtbox) -> Array[float]:
	if _cast == null or _cast.live_ice <= 0.0 or not target.has_state(StatusEffects.Kind.CHILL):
		return _parts
	var parts := _parts.duplicate()
	parts[DamageType.Kind.LIGHTNING] += DamageType.total(_parts) * _cast.live_ice * 0.01
	return parts


## Le masque ne retient que le décor pour les corps : le tir s'arrête au mur,
## et traverse les autres ennemis sans les toucher. Sauf le Carambolage (jalon 43).
func _on_body_entered(_body: Node3D) -> void:
	if _cast != null and _caromed < int(_cast.caroms):
		_caromed += 1
		_carom.call_deferred()
		return
	_finish()


## Repart du mur comme une bille de la bande. Différé : l'espace refuse les requêtes dans
## un rappel de collision (invariant 4). Le rayon revient sur la course pour trouver la
## face touchée ; sans face — un coin —, le tir rebrousse chemin.
func _carom() -> void:
	if is_queued_for_deletion():
		return
	var back := global_position - _dir * speed * get_physics_process_delta_time() * 2.0
	var query := PhysicsRayQueryParameters3D.create(back, global_position + _dir * 4.0, Targets.DECOR)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_dir = -_dir
	else:
		var normal: Vector3 = hit["normal"]
		_dir = _dir.bounce(normal)
		global_position = hit["position"] + normal * 2.0


## La fin de course, quelle qu'elle soit — cible, mur, portée.
func _finish() -> void:
	if is_queued_for_deletion():
		return
	_shatter()
	# Le Germe (jalon 45) : un trait qui n'a rien touché crève en nuage. L'explosion naît
	# d'elle-même en différé.
	if _cast != null and _cast.germ > 0.0 and _struck.is_empty():
		var cloud := _cast.echoed(SkillStats.GERM_PART)
		Explosion.put(
			get_parent(), global_position, cloud.roll(Game.rng), SkillStats.GERM_RADIUS, null,
			tint(), _author, cloud
		)
	if _bolt_fx != null:
		_bolt_fx.flare()
	queue_free()


## Les éclats partent de chaque ennemi traversé et de la fin de course. Ils emportent
## la liste de ce qui a été frappé **à cet instant** : une copie, que le tir qui continue
## ne rallonge pas sous eux. **Traversé, l'étoile tourne d'un demi-pas** : le tir garde
## l'axe, et un éclat qui l'y suivrait frapperait deux fois l'ennemi suivant.
func _shatter(pierced := false) -> void:
	if _cast == null or _cast.splits <= 0.0:
		return
	var count := int(_cast.splits)
	var dir := Flat.rotated(_dir, PI / float(count)) if pierced else _dir
	Projectile.split.call_deferred(
		get_parent(), load(scene_file_path), global_position, dir, speed, _nature,
		_source, _cast.shard(), count, _struck.duplicate()
	)


## La Fracture (jalon 44) : sur un transi, un tirage.
func _fractures(target: Hurtbox) -> bool:
	return target.has_state(StatusEffects.Kind.CHILL) and Game.rng.randf() * 100.0 < _cast.fracture


## Les deux morceaux d'un éclat brisé, en V sur son cap. Différée et statique, comme les
## éclats : l'impact est un rappel de collision.
static func fork(
	parent: Node, scene: PackedScene, at: Vector3, dir: Vector3, p_speed: float, nature: int,
	source, piece: SkillStats, struck: Dictionary
) -> void:
	if not is_instance_valid(parent):
		return
	var author: Node3D = source if is_instance_valid(source) else null
	for side in [-1.0, 1.0]:
		var bolt := spawn(
			parent, scene, at, Flat.rotated(dir, side * SkillStats.FRACTURE_SPREAD), piece.roll(Game.rng),
			author, p_speed, nature, piece
		)
		if bolt != null:
			bolt._struck = struck.duplicate()


## La Contagion (jalon 38) : l'état que le tir a posé gagne les voisins de sa cible,
## sans coup. Différée et statique : l'impact est un rappel de collision, et le tir peut
## être libéré quand l'appel arrive.
static func contaminate(target, kind: int, radius: float) -> void:
	if not is_instance_valid(target):
		return
	var from_target := target as Hurtbox
	if from_target.states == null:
		return
	for other in Targets.in_circle(from_target.get_world_3d(), from_target.global_position, radius):
		if other.states != null:
			from_target.states.pass_on(kind, other.states)


## En étoile, le premier dans `dir`. **Différé** : la fin de course arrive d'un
## rappel de collision, où un tir ne naît pas (invariant 4). Statique, parce que le tir
## est déjà libéré quand l'appel arrive ; `source` sans type pour la même raison.
static func split(
	parent: Node, scene: PackedScene, at: Vector3, dir: Vector3, p_speed: float,
	nature: int, source, shard: SkillStats, count: int, struck: Dictionary
) -> void:
	if not is_instance_valid(parent):
		return
	var author: Node3D = source if is_instance_valid(source) else null
	for i in count:
		var toward := Flat.rotated(dir, TAU * float(i) / float(count))
		var bolt := spawn(
			parent, scene, at - toward * MUZZLE, toward, shard.roll(Game.rng), author,
			p_speed, nature, shard
		)
		if bolt != null:
			bolt._struck = struck.duplicate()
			if bolt is Fireball:
				(bolt as Fireball).explosion_radius = shard.radius
				(bolt as Fireball).is_shard = true
