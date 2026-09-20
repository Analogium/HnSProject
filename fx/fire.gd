class_name Fire
extends RefCounted

## La couleur du feu, en un seul endroit : son blanc chaud et les braises qui
## montent. Quatre blancs chauds voisins vivaient dans quatre fichiers, et deux
## d'entre eux disaient en commentaire passer un seuil qu'ils ne passaient pas.
##
## **Ce qui fait le feu, c'est le dégradé de température**, pas la forme : une
## flamme d'une seule couleur reste un triangle orange, si bien découpé soit-il.
## Ses langues, elles, ne se tracent plus — elles se **dessinent**, dans
## `EffectForge` ; il ne reste ici que la braise, seul geste du feu encore tracé.

## Le blanc chaud d'un cœur de flamme, assez jaune pour rester du feu. Les quatre
## constantes qu'il remplace étaient toutes **trop sombres une fois mélangées** :
## l'orange du feu plafonne à 0,57 de luminance, le plus clair des quatre cœurs
## arrivait à 0,899 et celui de la boule de feu à 0,836. Aucun ne débordait, et
## deux d'entre eux disaient en commentaire qu'ils passaient le seuil.
const WARM := Color(1.0, 0.96, 0.78)
## La part de blanc chaud dans le cœur : 0,92 monte l'orange à 0,92 de luminance.
const HEART := 0.92


## Le cœur d'une flamme de cette teinte — le seul endroit où le feu a le droit
## d'être presque blanc.
static func heart(tint: Color) -> Color:
	return tint.lerp(WARM, HEART)


## Une braise : un pixel vif et un halo à peine. Deux pixels donnent un confetti,
## et un pixel sans halo disparaît sur un sol clair.
static func draw_ember(ci: CanvasItem, at: Vector2, tint: Color, fade: float, size := 1.0) -> void:
	if fade <= 0.0:
		return
	Glow.draw_blob(ci, at, size * 2.4, Color(tint, 0.30 * fade))
	ci.draw_rect(Rect2(at - Vector2(size, size) * 0.5, Vector2(size, size)), Color(heart(tint), fade))
