class_name BenchTrees
extends RefCounted

## Le banc des arbres (jalon 37) : une compétence lancée sans relâche sur des cibles
## immobiles, avec ses nœuds, par les vraies fonctions du jeu — `Player.cast_slot()`, les
## nœuds de geste, `Hurtbox`. Les nombres de mécanique (perforation, rebonds, sols,
## explosions des tués) ne se calculent pas : ils se jouent.
##
## Deux scènes : **le paquet**, des vagues de neuf cibles — la suivante quand la
## précédente est morte, comme on passe au paquet d'après —, et **le duel**, une cible
## qui ne meurt pas. Chacune à deux distances de la cible vivante la plus proche, au
## contact et au point visé ; la compétence garde la meilleure.

const PLAYER := preload("res://actors/player/player.tscn")
const Weapons := preload("res://tests/weapons.gd")

## Le temps compté par mesure, après une chauffe qui vide la réserve et laisse s'empiler
## ce qui dure : le régime établi, celui d'un combat qui se prolonge.
const WARM_UP := 6.0
const SECONDS := 12.0
const SEED := 3737
## Les cibles : un grunt de cette zone, sans affixe. Le banc compare des arbres entre eux,
## pas un personnage à une zone ; la zone ne règle que la fréquence des morts. En zone 20,
## un météore tuait la vague d'un coup et plus rien ne rendait : le paquet saturait.
const ZONE := 40
const PACK_RING := 8
const PACK_SPACING := 30.0
const NEAR := 24.0
const FAR := Player.PLACEMENT_RANGE
## Le temps entre deux vagues. Une cible qui renaissait seule, sur l'instant, mourait
## sous l'explosion du voisin et explosait à son tour : une réaction en chaîne sans fin,
## et des explosions de tués qui valaient ×9 là où un vrai paquet meurt une fois.
const WAVE_GAP := 0.5
## Une vie que rien n'épuise en douze secondes : le duel ne voit aucune mort.
const ENDLESS := 1.0e12
## La réserve et la régénération du banc : celles du Sort « Équipé » de cette zone
## (`BenchProfiles`), tirage 0. Sans réserve à payer, les nuages s'empilaient sans fin.
const MANA_ZONE := 40

enum Scene { PACK, DUEL }
const SCENE_NAMES := ["paquet", "duel"]


## Une cible : une hurtbox nue qui compte ce qu'elle perd, coups et brûlures. Morte, elle
## attend la vague suivante (`revive()`). Sa mort se dit à l'auteur comme celle d'un
## ennemi (`slew`), **avant** que ses états ne s'effacent : l'explosion d'un tué lit son état.
class Target extends Hurtbox:
	var dealt := 0.0
	var kills := 0
	var _health := 0.0
	var dead := false

	func _init(sheet: CharacterStats) -> void:
		stats = sheet
		states = StatusEffects.new()
		_health = sheet.max_health
		collision_layer = Targets.ENEMIES
		collision_mask = 0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
		add_child(shape)
		damaged.connect(func(info: DamageInfo) -> void: _lose(info.amount, info))

	func _physics_process(delta: float) -> void:
		if dead:
			return
		var burnt := states.advance(delta)
		if burnt > 0.0:
			_lose(burnt, null)

	func _lose(amount: float, info: DamageInfo) -> void:
		if dead:
			return
		dealt += minf(amount, _health)
		_health -= amount
		if _health > 0.0:
			return
		kills += 1
		if info != null and info.author != null:
			info.author.slew.emit(info.cast, global_position, states)
		dead = true
		# Différé : la mort arrive d'un rappel de collision (invariant 4).
		set_deferred("collision_layer", 0)

	func revive() -> void:
		dead = false
		_health = stats.max_health
		states.clear()
		collision_layer = Targets.ENEMIES


class Measure:
	var per_second := 0.0
	var kills := 0
	var distance := 0.0


var _host: Node
var _grunt: CharacterStats
var _endless: CharacterStats
var mana_pool := 0.0
var mana_regen := 0.0
## Combien de simulations ont tourné : le coût du banc se lit là.
var runs := 0
## Ce qui a déjà été joué : la graine est fixe, un même build rend le même chiffre. La
## recherche et la mesure finale retombent souvent sur les mêmes points.
var _measured := {}


func _init(host: Node) -> void:
	_host = host
	var without_affix: Array[Affix] = []
	_grunt = Enemy.sheet_of(BenchProfiles.base_sheet(BenchProfiles.ZONE.GRUNT_SCENE), ZONE, without_affix)
	_endless = _grunt.duplicate()
	_endless.max_health = ENDLESS
	var reference: Player = PLAYER.instantiate()
	host.add_child(reference)
	reference.load_character(
		BenchProfiles.character(BenchProfiles.builds()[0], BenchProfiles.Profile.EQUIPPED, MANA_ZONE)
	)
	mana_pool = reference.stats.max_mana
	mana_regen = reference.stats.mana_regen
	reference.free()


## La meilleure des deux distances. `nodes` : les points de l'arbre, un identifiant par point.
func measure(manual_id: String, skill_id: String, nodes: Array, scene: Scene) -> Measure:
	var best := Measure.new()
	for distance in [NEAR, FAR]:
		var m: Measure = await _run(manual_id, skill_id, nodes, scene, distance)
		if m.per_second > best.per_second:
			best = m
	return best


func _run(manual_id: String, skill_id: String, nodes: Array, scene: Scene, distance: float) -> Measure:
	var sorted_nodes := nodes.duplicate()
	sorted_nodes.sort()
	var key := "%s|%d|%d|%s" % [skill_id, scene, distance, ",".join(sorted_nodes)]
	if not _measured.has(key):
		_measured[key] = await _play(manual_id, skill_id, nodes, scene, distance)
	return _measured[key]


func _play(manual_id: String, skill_id: String, nodes: Array, scene: Scene, distance: float) -> Measure:
	runs += 1
	var tree := _host.get_tree()
	var world := Node2D.new()
	# Caché : rien ne se dessine, et le banc ne regarde que les chiffres.
	world.visible = false
	_host.add_child(world)
	var player: Player = PLAYER.instantiate()
	world.add_child(player)
	var effects := Node2D.new()
	world.add_child(effects)
	player.projectile_parent = effects
	player._aim_with_mouse = false
	player.facing = Vector2.RIGHT
	player.hurtbox.invulnerable = true

	var book := Item.new(ItemCatalog.by_id(manual_id))
	book.manual.gain_experience(999999)
	player.study(book, 0)
	while player.invest(0, skill_id):
		pass
	for id: String in nodes:
		if not player.invest(0, id):
			push_error("banc des arbres : « %s » refusé pour %s" % [id, skill_id])
	player.bar.put(0, skill_id)
	Weapons.arm(player, skill_id)

	var targets: Array[Target] = []
	var center := Vector2(distance + PACK_SPACING, 0.0)
	var count := 1 if scene == Scene.DUEL else PACK_RING + 1
	for i in count:
		var t := Target.new(_endless if scene == Scene.DUEL else _grunt.duplicate())
		world.add_child(t)
		t.global_position = center + (
			Vector2.ZERO if i == 0 else Vector2.from_angle(TAU * float(i) / PACK_RING) * PACK_SPACING
		)
		targets.append(t)
	await tree.physics_frame

	Game.rng.seed = SEED
	var skill := SkillCatalog.by_id(skill_id)
	# Un geste entretenu s'allume une fois : relancé, il s'éteindrait.
	var sustained := player.resolve(skill, player.skill_points(skill_id)).sustained
	_impose_mana(player)
	player._set_mana(mana_pool)
	var warm_up := roundi(WARM_UP * Engine.physics_ticks_per_second)
	var gap := 0.0
	for frame in warm_up + roundi(SECONDS * Engine.physics_ticks_per_second):
		if frame == warm_up:
			for t in targets:
				t.dealt = 0.0
				t.kills = 0
		if targets.all(func(t: Target) -> bool: return t.dead):
			gap += 1.0 / Engine.physics_ticks_per_second
			if gap >= WAVE_GAP:
				gap = 0.0
				for t in targets:
					t.revive()
		# Le joueur se tient à sa distance de la cible vivante la plus proche, qu'il vise —
		# une ruée l'en écarte, le pas suivant l'y ramène. Planté, il ne finissait jamais une
		# vague : ni une nova ni une aura n'atteignaient le fond du paquet.
		var aim := _nearest_alive(targets, player.global_position)
		if aim != null:
			player.global_position = aim.global_position - Vector2(distance, 0.0)
		player.facing = Vector2.RIGHT
		player._set_health(player.stats.max_health)
		if not (sustained and player.lit(skill_id)):
			player.cast_slot(0)
		# Après le lancer : un buff allumé refait la fiche.
		_impose_mana(player)
		await tree.physics_frame

	var m := Measure.new()
	m.distance = distance
	for t in targets:
		m.per_second += t.dealt / SECONDS
		m.kills += t.kills
	world.queue_free()
	await tree.process_frame
	return m


func _nearest_alive(targets: Array[Target], from: Vector2) -> Target:
	var best: Target = null
	for t in targets:
		if not t.dead and (best == null or t.global_position.distance_to(from) < best.global_position.distance_to(from)):
			best = t
	return best


func _impose_mana(player: Player) -> void:
	player.stats.max_mana = mana_pool
	player.stats.mana_regen = mana_regen


## Un build : les points dans l'ordre où ils se placent — un parent avant son enfant —,
## et ce qu'il rend dans chaque scène.
class Build:
	var points: Array[String] = []
	var pack: Measure
	var duel: Measure

	func count(id: String) -> int:
		return points.count(id)

	## « Surcharge 4, Fourche 2… », dans l'ordre du premier point.
	func label(cell: ManualCell) -> String:
		var seen := PackedStringArray()
		var out := PackedStringArray()
		for id in points:
			if id in seen:
				continue
			seen.append(id)
			out.append("%s %d" % [cell.node_of(id).name, count(id)])
		return ", ".join(out) if not out.is_empty() else "—"


## Le meilleur build de `Manual.MAX_LEVEL` points pour cette scène, **glouton par nœud
## entier** : à chaque pas, le nœud — avec le chemin le moins cher qui l'ouvre — qui rend
## le plus par point. Les conversions et les transformations n'y entrent que par
## `forced` : ce sont des choix de jeu, comparés à part.
func best_build(manual_id: String, cell: ManualCell, scene: Scene, forced: Array[String] = []) -> Build:
	var b := Build.new()
	b.points = forced.duplicate()
	# Les deux distances à chaque candidat : gardée fixe depuis le départ, la recherche en
	# duel de la Boule de feu ratait un build deux fois meilleur au contact.
	var current: Measure = await measure(manual_id, cell.skill.id, b.points, scene)
	while b.points.size() < Manual.MAX_LEVEL:
		var best_gain := 0.0
		var best_points: Array[String] = []
		var best_measure: Measure = null
		for node in cell.talents:
			if node.converts or node.transforms or node.frees or b.count(node.id) >= node.points_max:
				continue
			var add := _path(cell, node, b)
			for i in node.points_max - b.count(node.id):
				add.append(node.id)
			add = add.slice(0, Manual.MAX_LEVEL - b.points.size())
			if add.is_empty() or not node.id in add:
				continue
			var m: Measure = await measure(manual_id, cell.skill.id, b.points + add, scene)
			var gain := (m.per_second - current.per_second) / float(add.size())
			if gain > best_gain:
				best_gain = gain
				best_points = add
				best_measure = m
		# Plus rien ne rend : les points restants iraient à ce que le banc ne mesure pas.
		if best_measure == null:
			break
		b.points.append_array(best_points)
		current = best_measure
	return b


## Les points qui manquent pour ouvrir ce nœud, par le parent le moins cher — lui-même
## ouvert au besoin.
func _path(cell: ManualCell, node: TalentNode, b: Build) -> Array[String]:
	var out: Array[String] = []
	if node.parents.is_empty():
		return out
	var cheapest: Array[String] = []
	var found := false
	for parent_id: String in node.parents:
		var missing := node.parents[parent_id] - b.count(parent_id)
		if missing <= 0:
			return out
		var parent := cell.node_of(parent_id)
		var through := _path(cell, parent, b)
		for i in missing:
			through.append(parent_id)
		if not found or through.size() < cheapest.size():
			cheapest = through
			found = true
	return cheapest


## Le chemin le moins cher jusqu'à ce nœud, et le nœud : ce qu'on prend d'abord pour
## mesurer une transformation ou une conversion.
func opening(cell: ManualCell, node: TalentNode) -> Array[String]:
	var out := _path(cell, node, Build.new())
	for i in node.points_max:
		out.append(node.id)
	return out


## Le build et ses deux scènes : celle pour laquelle il a été cherché, et l'autre.
func complete(manual_id: String, cell: ManualCell, b: Build) -> void:
	b.pack = await measure(manual_id, cell.skill.id, b.points, Scene.PACK)
	b.duel = await measure(manual_id, cell.skill.id, b.points, Scene.DUEL)
