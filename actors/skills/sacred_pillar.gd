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

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0


static func fall(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> SacredPillar:
	var pillar := SacredPillar.new()
	pillar._cast = cast
	pillar._author = author
	pillar._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(pillar)
	pillar.global_position = point
	return pillar


## Pas de lumière ajoutée : la colonne est **dessinée**, et une planche cernée ne
## peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 4


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le pilier ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
		queue_free()


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste du pilier.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		Targets.strike(target, parts, global_position, _author, _cast)


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
	var radius := maxi(int(round(_cast.radius)), 1)
	draw_texture_rect(
		EffectForge.scorch(_tint, radius),
		Rect2(
			EffectForge.snap(self, -Vector2(radius, radius)),
			Vector2.ONE * float(radius * 2 + 1)
		),
		false, Color(1.0, 1.0, 1.0, fade)
	)
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
