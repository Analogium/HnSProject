class_name Piper
extends RefCounted

## La matière du joueur de flûte (jalon 53), **posée** en un seul endroit : le tapis de rats de
## la Marée, la ronde de notes de l'Air de Hamelin, l'éclat des rats de la Danse macabre, la
## file qui court d'un mort à son héritier. Les dessins viennent de `EffectForge` ; ce
## fichier dit comment ils se posent — chaque rat à sa place dans le tapis, tourné vers le cap le
## plus proche (une planche ne pivote pas), chaque note sur le bord de son cercle, calés sur le
## pixel.

## La ronde de notes : une tous les `NOTE_GAP` px de son cercle, en dedans de `NOTE_INSET`, qui
## tourne à `NOTE_TURN` rad/s en se balançant de `NOTE_BOB` px.
const NOTE_GAP := 70.0
const NOTE_INSET := 8.0
const NOTE_TURN := 1.2
const NOTE_BOB := 3.0
const NOTE_BOB_HZ := 6.0
## L'éclat des rats : la part de sa vie où ils bondissent, avant de crever ; jusqu'où, de combien
## ils montent depuis le pied du porteur, l'écart de l'éventail en radians.
const LEAP := 0.6
const LEAP_REACH := 18.0
const LEAP_LIFT := 6.0
const LEAP_SPREAD := 1.1
## Le pelage : le gris brun de l'état rongé.
const FUR := StatusEffects.OWN_COLORS[StatusEffects.Kind.RATS]
## Les rats d'un tapis de `SkillStats.TIDE_WIDTH` de large ; il en a d'autant plus qu'il est large.
const CARPET := 15
const LANES := 5
## Sa longueur derrière le centre de la marée, et ce qu'il dépasse devant.
const CARPET_BACK := 30.0
const CARPET_FRONT := 6.0
## Le grouillement, « dépassements » choisi sur planche : chaque rat remonte et recule dans le
## tapis de `SURGE` px, louvoie de `SWAY` px, à son propre rythme — ils se doublent. Le même pas
## pour tous, le tapis glissait d'un bloc.
const SURGE := 7.0
const SURGE_HZ := 4.0
const SWAY := 1.5
const SWAY_HZ := 7.0


## Les places d'un tapis, tirées une fois : en long de 1 (devant) à 0 (derrière), en travers de
## −1 à 1. **Par couloirs**, un peu de jeu dans chacun : tirées au hasard, elles laissaient un
## tapis bancal, deux rats seuls d'un côté et le paquet de l'autre. Triées de l'arrière à
## l'avant, pour que les premiers rats passent par-dessus.
static func carpet(seed_value: int, width: float) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := maxi(roundi(CARPET * width / SkillStats.TIDE_WIDTH), 3)
	var lanes := maxi(roundi(LANES * width / SkillStats.TIDE_WIDTH), 2)
	var rows := ceili(float(count) / float(lanes))
	var places: Array[Vector2] = []
	for i in count:
		var lane := i % lanes
		var row := i / lanes
		places.append(Vector2(
			(float(row) + rng.randf()) / float(rows),
			-1.0 + (float(lane) + 0.5 + rng.randf_range(-0.3, 0.3)) * 2.0 / float(lanes)
		))
	places.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	return PackedVector2Array(places)


## Le tapis autour de l'origine de `ci`, vers `heading`, de `half_width` de part et d'autre.
## Sa traîne ne dépasse pas ce qu'il a couru (`run`) : au lancer, il sort de devant le lanceur
## au lieu de le recouvrir.
static func pose_carpet(
	ci: CanvasItem, places: PackedVector2Array, heading: Vector2, half_width: float, age: float,
	run: float
) -> void:
	var frames: Array = EffectForge.rats(FUR)[EffectForge.chip_turn(heading.angle())]
	var across := heading.orthogonal()
	var back := minf(CARPET_BACK, run)
	for i in places.size():
		var place := places[i]
		# Un rythme et une phase par rat, étalés par le nombre d'or : jamais deux au même pas.
		var phase := float(i) * 2.399
		var pace := 0.75 + 0.5 * fposmod(float(i) * 0.618, 1.0)
		var along := place.x * (back + CARPET_FRONT) - back + sin(age * SURGE_HZ * pace + phase) * SURGE
		var aside := place.y * half_width + sin(age * SWAY_HZ * pace + phase) * SWAY
		# Jamais derrière ce qu'il a couru : au lancer, il recouvrirait le lanceur.
		var at := heading * maxf(along, -back) + across * aside
		var frame := int(age * EffectForge.RAT_HZ * pace * 1.6 + phase) % 2
		EffectForge.put_centered(ci, frames[frame], at)


## La ronde de notes de l'Air de Hamelin autour de l'origine de `ci`.
static func pose_notes(ci: CanvasItem, tint: Color, radius: float, age: float) -> void:
	var notes := EffectForge.notes(tint)
	var count := maxi(roundi(TAU * radius / NOTE_GAP), 4)
	for i in count:
		var angle := TAU * float(i) / float(count) + age * NOTE_TURN
		var bob := sin(age * NOTE_BOB_HZ + float(i)) * NOTE_BOB
		EffectForge.put_centered(ci, notes[i % 2], Vector2.from_angle(angle) * (radius - NOTE_INSET) + Vector2(0.0, bob))


## L'éclat des rats, « rats qui jaillissent » choisi sur planche, à `k` de sa vie : `count` rats
## bondissent en éventail vers le haut, puis crèvent chacun en bouffée nécrotique.
static func pose_burst(ci: CanvasItem, count: int, k: float) -> void:
	var spread := minf(LEAP_SPREAD, PI / float(count))
	for i in count:
		var angle := -PI * 0.5 + (float(i) - float(count - 1) * 0.5) * spread
		var dir := Vector2.from_angle(angle)
		var lift := Vector2(0.0, -LEAP_LIFT)
		if k < LEAP:
			var frames: Array = EffectForge.rats(FUR)[EffectForge.chip_turn(angle)]
			EffectForge.put_centered(ci, frames[0], lift + dir * (4.0 + k / LEAP * (LEAP_REACH - 4.0)))
		else:
			var puffs := EffectForge.rot_puffs(DamageType.COLORS[DamageType.Kind.NECROTIC])
			var step := mini(int((k - LEAP) / (1.0 - LEAP) * float(puffs.size())), puffs.size() - 1)
			EffectForge.put_centered(ci, puffs[step], lift + dir * LEAP_REACH)


## La file de `count` rats qui court vers `heading`, chacun `RatRun.GAP` derrière le précédent
## sans dépasser ce qu'elle a couru ; la bouffée du mort à `puff_at` tant que `puff` < 1.
static func pose_run(ci: CanvasItem, count: int, heading: Vector2, run: float, puff_at: Vector2, puff: float) -> void:
	if puff < 1.0:
		var puffs := EffectForge.rot_puffs(DamageType.COLORS[DamageType.Kind.NECROTIC])
		EffectForge.put_centered(ci, puffs[mini(int(puff * float(puffs.size())), puffs.size() - 1)], puff_at + Vector2(0.0, -LEAP_LIFT))
	if heading == Vector2.ZERO:
		return
	var frames: Array = EffectForge.rats(FUR)[EffectForge.chip_turn(heading.angle())]
	for i in count:
		var back := minf(float(i) * RatRun.GAP, run)
		# Un pas de côté sur deux : en file stricte, les rats se lisaient en boudin.
		var aside := heading.orthogonal() * (2.0 if i % 2 == 1 else 0.0)
		EffectForge.put_centered(ci, frames[(int(run / 6.0) + i) % 2], -heading * back + aside)
