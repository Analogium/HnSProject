class_name SacredPillar
extends Node2D

## Le pilier de Pilier sacré : une colonne de lumière tombée du ciel sur le point
## visé, qui frappe son cercle à chaque période puis s'éteint. Comme le nuage
## d'orage, il ne fige jamais le jeu — une impulsion qui gèle toutes les demi-secondes
## hacherait l'image tant qu'il brûle.

## La hauteur de la colonne, en pixels. Mesurée à la capture : à 200 elle traversait
## les 360 px du cadrage et se lisait comme un projecteur, à 130 elle tombe du bord.
const HEIGHT := 130.0
## Ce qu'elle met à s'ouvrir et à se refermer, en secondes.
const OPENING := 0.12
const CLOSING := 0.35
## Les grains de lumière qui montent dans la colonne — ce qui monte dit qu'elle
## brûle, la colonne, elle, verse.
const MOTES := 9
const RISE := 40.0
## Ce que la colonne défile vers le bas, en pixels par seconde. C'est le défilement
## du carrelage qui fait **couler** la lumière ; sans lui, la colonne est un
## panneau. Entier, parce qu'un carrelage posé sur un demi-pixel se rééchantillonne.
const FLOW := 24
## Le Pilier errant (jalon 40) : sa vitesse vers l'ennemi le plus proche, en pixels par
## seconde, et jusqu'où il le cherche. Premier réglage.
const DRIFT_SPEED := 40.0
const DRIFT_SIGHT := 160.0

## Ceux qui brûlent, pour la Communion et le Pilori (jalon 48).
static var _standing: Array[SacredPillar] = []

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
## Ce que suit le Pilier errant, choisi à chaque impulsion. Sans type : il peut mourir
## entre deux, et `is_instance_valid()` passe avant tout usage (invariant 4).
var _prey: Variant = null
## Le lanceur, que soigne la Consécration (jalon 48) ; null pour un pilier posé sans lui.
var _caster: Player
## L'Ascension : les secondes déjà gagnées. L'Apothéose : les ennemis frappés.
var _gained := 0.0
var _struck := 0


## `caster` : le joueur qui se tient dans la colonne, pour la Consécration.
static func fall(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects, caster: Player = null
) -> SacredPillar:
	var pillar := SacredPillar.new()
	# Une copie pour lui seul, quand il change son lancer : l'Ascension allonge sa durée, le
	# Sanctuaire bénit à coup sûr — et le Triptyque pose trois piliers d'un même lancer.
	if cast.ascension > 0.0 or cast.sanctuary > 0.0:
		cast = cast.echoed(1.0)
		if cast.sanctuary > 0.0:
			cast.status_chance_increase += SkillStats.SURE_STATE
	pillar._cast = cast
	pillar._author = author
	pillar._caster = caster
	pillar._tint = DamageType.COLORS[cast.nature]
	if cast.ascension > 0.0 and author != null:
		author.slew.connect(pillar._on_slew)
	parent.add_child(pillar)
	Settings.veil(pillar, Settings.SPELLS)
	pillar.global_position = point
	_standing.assign(_standing.filter(
		func(p) -> bool: return is_instance_valid(p) and not p.is_queued_for_deletion()
	))
	_standing.append(pillar)
	return pillar


## Les piliers de ce lanceur qui brûlent encore.
static func standing_for(author: StatusEffects) -> Array[SacredPillar]:
	var out: Array[SacredPillar] = []
	for p in _standing:
		if is_instance_valid(p) and not p.is_queued_for_deletion() and p._author == author:
			out.append(p)
	return out


## Le cercle qu'il mord.
func reach() -> float:
	return _cast.radius


## Pas de lumière ajoutée : la colonne est **dessinée**, et une planche cernée ne
## peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 4


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le pilier ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	if is_instance_valid(_prey):
		global_position = global_position.move_toward(
			(_prey as Node2D).global_position, DRIFT_SPEED * (1.0 + _cast.procession * 0.01) * delta
		)
	# La Consécration (jalon 48) : son lanceur, debout dans le cercle, regagne des PV.
	if _cast.consecration > 0.0 and is_instance_valid(_caster) \
			and _caster.global_position.distance_to(global_position) <= reach():
		_caster.mend(_cast.consecration * 0.01, delta)
	queue_redraw()
	if _age >= _cast.duration and _strikes >= _cast.strikes_over_duration():
		# L'Effondrement : en s'éteignant, la colonne éclate ; l'Apothéose, d'autant plus fort
		# qu'elle a frappé de monde.
		if _cast.end_burst > 0.0:
			var burst := _cast
			if _cast.apotheosis > 0.0:
				burst = _cast.echoed(
					1.0 + _cast.apotheosis * 0.01 * float(mini(_struck, SkillStats.APOTHEOSIS_MOST))
				)
			Explosion.of_cast(get_parent(), global_position, burst, _cast.end_burst, _author)
		queue_free()


## L'Appel céleste tire vers le cœur, par un recul négatif. Le Verdict (jalon 48) : la
## colonne tombe, et sa première impulsion frappe plus fort.
func _strike(factor := 1.0) -> void:
	if _strikes == 0:
		factor *= 1.0 + _cast.verdict * 0.01
	_struck += Targets.strike_circle(
		get_world_2d(), global_position, _cast.radius, _cast, _author, -_cast.pull, factor
	).size()
	if _cast.shape == Skill.Shape.DRIFT:
		_prey = Targets.nearest(get_world_2d(), global_position, DRIFT_SIGHT)


## La Communion (jalon 48) : une onde de la Pulsation qui l'atteint la fait frapper sur-le-champ,
## une impulsion de plus à cette part de son coup.
func commune(part: float) -> void:
	_struck += Targets.strike_circle(
		get_world_2d(), global_position, _cast.radius, _cast, _author, -_cast.pull, part
	).size()


## L'Ascension (jalon 48) : un ennemi tué par cette colonne la fait brûler plus longtemps.
func _on_slew(cast: SkillStats, _at: Vector2, _victim: StatusEffects) -> void:
	if cast != _cast or _gained >= SkillStats.ASCENSION_MOST:
		return
	var gain := minf(_cast.ascension, SkillStats.ASCENSION_MOST - _gained)
	_gained += gain
	_cast.duration += gain


## La colonne **tombe du ciel** : elle se découvre du haut vers le bas au lieu de
## s'élargir sur place, ce qui est la seule des deux choses qu'un dessin sait faire
## sans s'étirer. Le halo au sol dit **où elle mord** — la colonne est plus étroite
## que le cercle, et lui seul donne la portée.
##
## Sa largeur est celle de son dessin et ne suit pas le rayon : ce qu'un nœud
## agrandit, c'est la morsure, pas le faisceau.
func _draw() -> void:
	var fade := clampf((_cast.duration - _age) / CLOSING, 0.0, 1.0)
	# Elle tombe, puis se **retire par le haut** : une colonne qui s'éteint en
	# pâlissant sort grise sur un sol sombre, comme tout ce qui est dessiné. Seul le
	# halo au sol s'efface, parce qu'il est tramé et fait pour ça.
	var fallen := minf(clampf(_age / OPENING, 0.0, 1.0), fade)
	var span := maxi(roundi(_cast.radius), 1)
	# La Consécration (jalon 48) : le sol qui soigne a ses dalles.
	if _cast.consecration > 0.0:
		draw_texture_rect(
			Holy.consecrated(_tint, span),
			Rect2(EffectForge.snap(self, -Vector2(span, span)), Vector2.ONE * float(span * 2 + 1)),
			false, Color(1.0, 1.0, 1.0, fade)
		)
	else:
		EffectForge.put_scorch(self, _tint, span, fade)
	_column(fallen)

	# **Autour** de la colonne et non dedans : un grain posé sur un cœur blanc n'est
	# qu'un trou plus sombre. Ils montent à pleine opacité et s'éteignent en haut de
	# leur course, comme tous les grains dessinés.
	var clear := float(EffectForge.SHAFT_WIDTH) * 0.5 + 3.0
	for i in MOTES:
		var rise := fmod(_age * 0.9 + float(i) * 0.113, 1.0)
		# Écartés du faisceau, jamais dessus : un grain posé sur un cœur blanc n'est
		# qu'un trou plus sombre.
		var away := clear + absf(sin(float(i) * 2.4)) * _cast.radius * 0.5
		Holy.spark(
			self, Vector2(away * (1.0 if i % 2 == 0 else -1.0), -rise * RISE), _tint, 1.0
		)


## La colonne, carrelée d'une seule tranche qui défile. Une tranche pleine bord à
## bord ne porte aucun contour, donc deux tranches posées l'une sur l'autre ne
## montrent pas de barre sombre entre elles.
func _column(fallen: float) -> void:
	var tile := EffectForge.shaft(_tint)
	var slab := float(EffectForge.SHAFT_HEIGHT)
	var width := float(EffectForge.SHAFT_WIDTH)
	var bottom := -HEIGHT + HEIGHT * fallen
	# Le défilement est un nombre entier de pixels : une source fractionnaire
	# rééchantillonne le carrelage et casse ses bandes.
	var shift := float(int(_age * float(FLOW)) % EffectForge.SHAFT_HEIGHT)
	var y := -HEIGHT + shift - slab
	# La pointe d'abord, posée au sommet : elle ne défile pas, sinon le haut de la
	# colonne se mettrait à monter et à descendre.
	var tip := EffectForge.shaft_tip(_tint)
	var tip_high := float(EffectForge.SHAFT_TIP_HEIGHT)
	if bottom > -HEIGHT:
		var shown := minf(tip_high, bottom + HEIGHT)
		draw_texture_rect_region(
			tip, Rect2(EffectForge.snap(self, Vector2(-width * 0.5, -HEIGHT)), Vector2(width, shown)),
			Rect2(0.0, 0.0, width, shown)
		)
	while y < bottom:
		var top := maxf(y, -HEIGHT + tip_high)
		var low := minf(y + slab, bottom)
		if low > top:
			var size := Vector2(width, low - top)
			draw_texture_rect_region(
				tile, Rect2(EffectForge.snap(self, Vector2(-width * 0.5, top)), size),
				Rect2(0.0, top - y, width, size.y)
			)
		y += slab
