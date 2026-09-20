class_name Fire
extends RefCounted

## Le feu du jeu, dessiné en un seul endroit : les langues d'Immolation et de la
## Ruée ardente, les braises qui montent, la traînée de la Boule de feu, son
## explosion et le dos du Serpent infernal. Cinq gestes dessinés de cinq façons
## ne se lisaient pas comme la même matière — c'était le cas : quatre triangles
## écrits quatre fois, et quatre blancs chauds voisins dans quatre fichiers.
##
## **Ce qui fait le feu, c'est le dégradé de température**, pas la forme : une
## langue d'une seule couleur reste un triangle orange, si bien découpé soit-il.
## Trois couches emboîtées, de la plus large et la plus teintée à un cœur presque
## blanc, et c'est ce cœur seul qui dépasse le seuil de glow (0,9).

## Le blanc chaud d'un cœur de flamme, assez jaune pour rester du feu. Les quatre
## constantes qu'il remplace étaient toutes **trop sombres une fois mélangées** :
## l'orange du feu plafonne à 0,57 de luminance, le plus clair des quatre cœurs
## arrivait à 0,899 et celui de la boule de feu à 0,836. Aucun ne débordait, et
## deux d'entre eux disaient en commentaire qu'ils passaient le seuil.
const WARM := Color(1.0, 0.96, 0.78)
## La part de blanc chaud dans le cœur : 0,92 monte l'orange à 0,92 de luminance.
const HEART := 0.92

## Le profil d'une langue, du pied à la pointe : hauteur relative, largeur
## relative. Le renflement à 30 % est la seule chose qui sépare une flamme d'un
## cône de papier — un profil qui décroît de bout en bout est un triangle.
const PROFILE := [
	Vector2(0.0, 1.0), Vector2(0.30, 1.12), Vector2(0.58, 0.76),
	Vector2(0.82, 0.40), Vector2(1.0, 0.0),
]

## Les trois couches, en part de la langue entière : le halo teinté, le corps
## tiède, le cœur. Leur rétrécissement est ce qui donne le dégradé ; les dessiner
## de la même taille rendrait la plus claire seule visible.
##
## **Le cœur est une mèche, pas une flamme réduite** : les deux tiers du feu
## doivent rester teintés. À 0,35 de large il saturait le tout en additif — trois
## couches qui s'ajoutent dépassent le blanc bien avant d'avoir l'air chaudes, et
## le brasier ressortait en couronne de dents blanches.
const BODY_SCALE := 0.78
const HEART_SCALE := 0.40
const HEART_WIDTH := 0.22

## Sous cette taille une langue ne couvre plus un pixel, et son cœur — deux
## dixièmes de sa largeur — a une aire que **la triangulation de Godot refuse** :
## elle ne dessine rien et crie dans la console à chaque image.
const MIN_HEIGHT := 2.0
const MIN_WIDTH := 0.5


## Le cœur d'une flamme de cette teinte — le seul endroit où le feu a le droit
## d'être presque blanc.
static func heart(tint: Color) -> Color:
	return tint.lerp(WARM, HEART)


## La respiration d'une flamme, entre −1 et 1. Deux sinus de périodes
## incommensurables : un seul donne un battement régulier, qui se lit comme une
## boucle d'animation. `i` décale chaque langue d'un brasier.
static func breath(age: float, i: int) -> float:
	return 0.6 * sin(age * 9.0 + float(i) * 1.7) + 0.4 * sin(age * 13.0 + float(i) * 0.6)


## Vu de dessus en vue plongeante, un brasier brûle **vers le haut de l'écran** :
## tout ce qui est posé au sol passe `Vector2.UP`, et seul ce qui vole traîne ses
## langues derrière lui.
##
## Une langue posée sur `foot`, qui lèche vers `up`. `sway` déplace la pointe
## latéralement — le pied ne bouge pas : une flamme lèche, elle ne penche pas d'un
## bloc.
static func tongue(
	foot: Vector2, up: Vector2, height: float, half_width: float, sway: float
) -> PackedVector2Array:
	# `side` est la gauche-droite de la langue : pour une flamme qui monte, `sway`
	# positif pousse la pointe vers la droite de l'écran.
	var side := Vector2(-up.y, up.x)
	var out := PackedVector2Array()
	for p: Vector2 in PROFILE:
		# Le carré sur la hauteur : la pointe part de côté, le milieu à peine.
		var axis := foot + up * height * p.x + side * sway * p.x * p.x
		out.append(axis + side * half_width * p.y)
	# Le retour saute la pointe, dont la largeur est nulle : **un sommet en double**
	# fait échouer la triangulation de Godot sur les langues les plus fines, et la
	# langue disparaît en criant dans la console.
	for i in range(PROFILE.size() - 2, -1, -1):
		var p: Vector2 = PROFILE[i]
		var axis := foot + up * height * p.x + side * sway * p.x * p.x
		out.append(axis - side * half_width * p.y)
	return out


## Une langue complète : trois couches emboîtées. `fade` porte l'apparition et
## l'extinction de l'effet qui l'appelle.
##
## **Les opacités sont réglées pour le mélange additif**, celui de quatre des
## cinq appelants : elles s'y ajoutent, et trois couches franches y dépassent le
## blanc avant d'avoir l'air chaudes. Un appelant en mélange normal — le serpent,
## qui est une bête et non une lueur — n'a pas cette somme et doit compenser par
## des langues plus grandes, pas par un `fade` au-dessus de 1, qui ne monterait
## que le cœur.
static func draw_tongue(
	ci: CanvasItem, foot: Vector2, up: Vector2, height: float, half_width: float,
	tint: Color, fade: float, sway := 0.0
) -> void:
	if fade <= 0.0 or height < MIN_HEIGHT or half_width < MIN_WIDTH:
		return
	ci.draw_colored_polygon(tongue(foot, up, height, half_width, sway), Color(tint, 0.28 * fade))
	ci.draw_colored_polygon(
		tongue(foot, up, height * BODY_SCALE, half_width * BODY_SCALE, sway * 0.8),
		Color(tint.lerp(WARM, 0.40), 0.34 * fade)
	)
	ci.draw_colored_polygon(
		tongue(
			foot, up, maxf(height * HEART_SCALE, MIN_HEIGHT),
			maxf(half_width * HEART_WIDTH, MIN_WIDTH), sway * 0.6
		),
		Color(heart(tint), 0.85 * fade)
	)


## Une braise : un pixel vif et un halo à peine. Deux pixels donnent un confetti,
## et un pixel sans halo disparaît sur un sol clair.
static func draw_ember(ci: CanvasItem, at: Vector2, tint: Color, fade: float, size := 1.0) -> void:
	if fade <= 0.0:
		return
	Glow.draw_blob(ci, at, size * 2.4, Color(tint, 0.30 * fade))
	ci.draw_rect(Rect2(at - Vector2(size, size) * 0.5, Vector2(size, size)), Color(heart(tint), fade))
