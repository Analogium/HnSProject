class_name Projectile
extends Area2D

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

# --------------------------------------------------------------------------
# Le dessin
# --------------------------------------------------------------------------

## Le glyphe de l'éclair, sept sommets dans une boîte de 24, **pointe vers +x** — le
## nœud tourne déjà. Des sommets et non une image : c'est leur gigue qui vit.
const GLYPH := [
	Vector2(-10, 5), Vector2(1, 5), Vector2(1, 2), Vector2(10, 2),
	Vector2(-2, -5), Vector2(-2, -1), Vector2(-10, -5),
]

## Long et mince : un dard de dix-huit pixels sur trois. **Un choix de lecture**, fait
## en jeu contre une variante large de la taille du torse.
const SIZE := 12.0
const REACH := 1.8
const FINESSE := 0.62

## Le halo est le glyphe réempilé plus large : une polyligne épaisse sortait carrée.
const AUREOLES := [[1.34, 0.10], [1.18, 0.15], [1.07, 0.20]]

## Sous-alimenté exprès : en additif, la teinte pleine sature en blanc et le froid se
## confondrait avec la foudre.
const BODY := 0.78

## Écart des sommets d'une image à l'autre, en unités du glyphe. C'est tout le
## grésillement : sans lui le tir est un autocollant qui glisse.
const JITTER := 0.4

## Les natures **dessinées** : planches cernées, qui ne tournent pas et ne sont pas
## additives. Les autres restent des glyphes tracés.
const DRAWN := [DamageType.Kind.LIGHTNING, DamageType.Kind.NECROTIC]
## L'écart entre deux volutes de la traînée de la Peste, et leur tangage.
const FUME_STEP := 7.0
const FUME_SWAY := 1.5

var _dir := Vector2.RIGHT
## Les parts du coup, par nature, tirées au lancer.
var _parts: Array[float] = []
var _source: Node2D
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

## Tirage **local**, semé sur le nœud : invariant 3, et deux tirs ne grésillent pas à
## l'unisson.
var _flicker := RandomNumberGenerator.new()


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_flicker.seed = int(get_instance_id())
	material = ArtPalette.ADDITIVE


## Dessiné plutôt que tracé : la foudre, la nécrose, et le froid **du joueur** — le
## Trait de glace (jalon 35). Le tir des casters reste tracé, au choix de
## l'utilisateur : on le distingue du sien en combat.
func _drawn() -> bool:
	return nature() in DRAWN or (nature() == DamageType.Kind.COLD and _cast != null)


## Reconstruit à chaque appel : c'est le changement qui fait l'effet.
func _shape(scale_factor: float) -> PackedVector2Array:
	var k := SIZE * scale_factor / 24.0
	var pts := PackedVector2Array()
	for v: Vector2 in GLYPH:
		var d := Vector2(v.x * REACH, v.y * FINESSE)
		d += Vector2(
			_flicker.randf_range(-JITTER, JITTER),
			_flicker.randf_range(-JITTER, JITTER)
		)
		pts.append(d * k)
	return pts


func tint() -> Color:
	return DamageType.COLORS[nature()]


## La nature effectivement dessinée : celle que le lanceur a passée, sinon celle
## de la scène.
func nature() -> DamageType.Kind:
	return _nature if _nature >= 0 else damage_type


func _draw() -> void:
	var color := tint()
	# **La foudre ne se dessine pas comme une bille.** Un éclair court et fourché,
	# couché sur la trajectoire au cap le plus proche. La nécrose, elle, est un crâne.
	# Ce sont les deux écarts par nature de ce nœud : les autres natures sont des
	# boules qui brillent.
	if nature() == DamageType.Kind.LIGHTNING:
		Lightning.put(self, Lightning.dart(
			color, Slash.turn_of(_dir.angle()), Lightning.hold(_life) + int(get_instance_id())
		))
		return
	if nature() == DamageType.Kind.NECROTIC:
		_plague(color)
		return
	if _drawn():
		Frost.javelin(color, Slash.turn_of(_dir.angle())).put(self, Vector2.ZERO)
		return
	for a: Array in AUREOLES:
		var halo := color
		halo.a = float(a[1])
		draw_colored_polygon(_shape(float(a[0])), halo)
	var body := color
	body.a = BODY
	draw_colored_polygon(_shape(1.0), body)


## Le crâne de la Peste et ses fumées, qui ondulent de part et d'autre de la course.
func _plague(color: Color) -> void:
	var fumes := EffectForge.fumes(color)
	var side := _dir.orthogonal()
	for i in fumes.size():
		var behind := -_dir * FUME_STEP * float(i + 1) + side * FUME_SWAY * (1.0 if i % 2 == 0 else -1.0)
		Necrotic.centered(self, fumes[i], behind)
	var skulls := EffectForge.plagues(color)
	Necrotic.centered(self, skulls[int(_life * EffectForge.PLAGUE_HZ) % skulls.size()], Vector2.ZERO)


## add_child d'abord, sinon global_position ne veut rien dire. Immédiat : un tir ne
## part jamais d'un rappel de collision.
static func spawn(
	parent: Node, scene: PackedScene, from: Vector2, dir: Vector2,
	parts: Array[float], source: Node2D, p_speed := 0.0, nature := -1, cast: SkillStats = null
) -> Projectile:
	var bolt := _spawn(parent, scene, from, dir)
	if bolt != null:
		# Avant `setup()`, qui lit le lancer pour savoir si le tir est dessiné.
		bolt._cast = cast
		bolt.setup(dir, parts, source, p_speed, nature)
		Settings.veil(bolt, Settings.SPELLS)
	return bolt


## Le chemin des ennemis : la nature reste écrite dans `enemy_bolt.tscn`.
static func spawn_of_nature(
	parent: Node, scene: PackedScene, from: Vector2, dir: Vector2,
	amount: float, source: Node2D
) -> Projectile:
	var bolt := _spawn(parent, scene, from, dir)
	if bolt != null:
		var parts := DamageType.empty_parts()
		parts[bolt.damage_type] = amount
		bolt.setup(dir, parts, source)
		Settings.veil(bolt, Settings.ENEMY_ATTACKS)
	return bolt


static func _spawn(parent: Node, scene: PackedScene, from: Vector2, dir: Vector2) -> Projectile:
	if scene == null or parent == null:
		return null
	var bolt: Projectile = scene.instantiate()
	parent.add_child(bolt)
	bolt.global_position = from + dir * MUZZLE
	return bolt


## Après add_child. `speed` à zéro garde celle de la scène (tirs ennemis) ; la durée
## de vie reste sur la scène, donc un tir plus rapide porte plus loin. Parts recopiées.
func setup(
	dir: Vector2, parts: Array[float], source: Node2D, p_speed := 0.0, nature := -1
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
	rotation = _dir.angle()
	# Dessinées, elles ne tournent pas et ne sont pas additives : une planche pivotée se
	# rééchantillonne, et son contour sombre n'ajoute rien en lumière ajoutée.
	if _drawn():
		rotation = 0.0
		material = null


func _physics_process(delta: float) -> void:
	if _cast != null and _cast.lightning_rod > 0.0:
		_home(delta)
	elif _cast != null and _cast.seek_radius > 0.0:
		_seek(delta)
	global_position += _dir * speed * delta
	_life += delta
	# Redessiné à chaque pas : c'est le changement qu'on regarde.
	queue_redraw()
	if _life >= lifetime:
		_finish()


## Hors de `_on_area_entered` : `Fireball` décide d'exploser avant l'appel parent.
func strikes(area: Area2D) -> bool:
	return area is Hurtbox and not _struck.has(area.get_instance_id())


func _on_area_entered(area: Area2D) -> void:
	if not strikes(area):
		return
	_struck[area.get_instance_id()] = true
	var info := DamageInfo.roll(_cast, global_position, _conducted(area as Hurtbox), knockback)
	info.author = _author
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
	if _cast != null and _pierced < int(_cast.pierce):
		_pierced += 1
		_shatter(true)
		return
	if _cast != null and _bounced < int(_cast.bounces):
		_bounced += 1
		_bounce.call_deferred()
		return
	_finish()


## Repart vers l'ennemi non frappé le plus proche, **dans tout le reste de sa course** et
## dans toutes les directions : la portée d'un saut de chaîne (90 px) faisait échouer le
## rebond dès que les ennemis s'espaçaient. Différé : l'impact arrive d'un rappel de
## collision, où l'espace refuse les requêtes (invariant 4).
func _bounce() -> void:
	if is_queued_for_deletion():
		return
	var reach := speed * (lifetime - _life)
	var best := Targets.nearest(get_world_2d(), global_position, reach, _struck, true)
	if best == null:
		_finish()
		return
	_dir = global_position.direction_to(best.global_position)
	if not _drawn():
		rotation = _dir.angle()


## Le Paratonnerre (jalon 43) : à portée de la marque de son lanceur, le tir s'incurve
## vers elle — un virage borné, pas un aimant : un tir qui la croise de loin la manque.
func _home(delta: float) -> void:
	var rod := LightningRod.target_of(_author)
	if rod == null or _struck.has(rod.get_instance_id()):
		return
	if global_position.distance_to(rod.global_position) <= SkillStats.ROD_REACH:
		_steer(rod.global_position, delta)


## Le Grésil (jalon 44) : vers l'ennemi non frappé le plus proche, gardé jusqu'à ce qu'il
## soit frappé ou mort.
func _seek(delta: float) -> void:
	if not is_instance_valid(_quarry) or _struck.has(_quarry.get_instance_id()):
		_quarry = Targets.nearest(get_world_2d(), global_position, _cast.seek_radius, _struck, true)
	if _quarry != null:
		_steer(_quarry.global_position, delta)


func _steer(toward: Vector2, delta: float) -> void:
	var turn := SkillStats.ROD_TURN * delta
	_dir = _dir.rotated(clampf(_dir.angle_to(toward - global_position), -turn, turn))
	if not _drawn():
		rotation = _dir.angle()


## La Glace vive (jalon 43) : sur un transi, le trait de glace ajoute une part de foudre.
func _conducted(target: Hurtbox) -> Array[float]:
	if _cast == null or _cast.live_ice <= 0.0 or not target.has_state(StatusEffects.Kind.CHILL):
		return _parts
	var parts := _parts.duplicate()
	parts[DamageType.Kind.LIGHTNING] += DamageType.total(_parts) * _cast.live_ice * 0.01
	return parts


## Le masque ne retient que le décor pour les corps : le tir s'arrête au mur,
## et traverse les autres ennemis sans les toucher. Sauf le Carambolage (jalon 43).
func _on_body_entered(_body: Node2D) -> void:
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
	var query := PhysicsRayQueryParameters2D.create(back, global_position + _dir * 4.0, Targets.DECOR)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_dir = -_dir
	else:
		var normal: Vector2 = hit["normal"]
		_dir = _dir.bounce(normal)
		global_position = hit["position"] + normal * 2.0
	if not _drawn():
		rotation = _dir.angle()


## La fin de course, quelle qu'elle soit — cible, mur, portée.
func _finish() -> void:
	if is_queued_for_deletion():
		return
	_shatter()
	queue_free()


## Les éclats partent de chaque ennemi traversé et de la fin de course. Ils emportent
## la liste de ce qui a été frappé **à cet instant** : une copie, que le tir qui continue
## ne rallonge pas sous eux. **Traversé, l'étoile tourne d'un demi-pas** : le tir garde
## l'axe, et un éclat qui l'y suivrait frapperait deux fois l'ennemi suivant.
func _shatter(pierced := false) -> void:
	if _cast == null or _cast.splits <= 0.0:
		return
	var count := int(_cast.splits)
	var dir := _dir.rotated(PI / float(count)) if pierced else _dir
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
	parent: Node, scene: PackedScene, at: Vector2, dir: Vector2, p_speed: float, nature: int,
	source, piece: SkillStats, struck: Dictionary
) -> void:
	if not is_instance_valid(parent):
		return
	var author: Node2D = source if is_instance_valid(source) else null
	for side in [-1.0, 1.0]:
		var bolt := spawn(
			parent, scene, at, dir.rotated(side * SkillStats.FRACTURE_SPREAD), piece.roll(Game.rng),
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
	for other in Targets.in_circle(from_target.get_world_2d(), from_target.global_position, radius):
		if other.states != null:
			from_target.states.pass_on(kind, other.states)


## En étoile, le premier dans `dir`. **Différé** : la fin de course arrive d'un
## rappel de collision, où un tir ne naît pas (invariant 4). Statique, parce que le tir
## est déjà libéré quand l'appel arrive ; `source` sans type pour la même raison.
static func split(
	parent: Node, scene: PackedScene, at: Vector2, dir: Vector2, p_speed: float,
	nature: int, source, shard: SkillStats, count: int, struck: Dictionary
) -> void:
	if not is_instance_valid(parent):
		return
	var author: Node2D = source if is_instance_valid(source) else null
	for i in count:
		var toward := dir.rotated(TAU * float(i) / float(count))
		var bolt := spawn(
			parent, scene, at - toward * MUZZLE, toward, shard.roll(Game.rng), author,
			p_speed, nature, shard
		)
		if bolt != null:
			bolt._struck = struck.duplicate()
			if bolt is Fireball:
				(bolt as Fireball).explosion_radius = shard.radius
				(bolt as Fireball).is_shard = true
