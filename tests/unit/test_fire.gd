extends GutTest

## La matière du feu. Deux promesses, et la campagne ne voit ni l'une ni l'autre
## sans ces assertions : un **cœur au-dessus du seuil de glow** (0,9), et un
## profil qui se renfle au lieu de décroître.

const FIRE := Color(1.00, 0.48, 0.18)
const THRESHOLD := 0.9


## Le chiffre de cette couche : l'orange du feu plafonne à 0,57 de luminance, donc
## une flamme entièrement teintée ne déborde jamais. Les quatre blancs chauds que
## `Fire.WARM` remplace donnaient des cœurs de 0,75 à 0,899 — tous sous le seuil,
## et deux d'entre eux prétendaient le passer.
func test_the_heart_of_a_flame_passes_the_glow_threshold() -> void:
	assert_lt(FIRE.get_luminance(), THRESHOLD, "l'orange du feu, seul, ne brille pas")
	assert_gt(Fire.heart(FIRE).get_luminance(), THRESHOLD, "son cœur, si")


## Le renflement, c'est la flamme. Un profil qui ne fait que décroître du pied à
## la pointe est un triangle, quelle que soit la façon dont on l'anime.
func test_a_tongue_swells_above_its_foot() -> void:
	var pts := Fire.tongue(Vector2.ZERO, Vector2.UP, 20.0, 4.0, 0.0)
	var foot: float = pts[0].x
	var widest := 0.0
	for p: Vector2 in pts:
		widest = maxf(widest, p.x)
	assert_gt(widest, foot, "la langue est plus large au-dessus du pied qu'au pied")
	assert_almost_eq(pts[Fire.PROFILE.size() - 1].x, 0.0, 0.001, "et sa pointe se ferme")


## `sway` déplace la pointe et **laisse le pied** : une langue lèche, elle ne
## penche pas d'un bloc. Le carré sur la hauteur est ce qui tient le pied en place.
func test_sway_moves_the_tip_and_not_the_foot() -> void:
	var still := Fire.tongue(Vector2.ZERO, Vector2.UP, 20.0, 4.0, 0.0)
	var licking := Fire.tongue(Vector2.ZERO, Vector2.UP, 20.0, 4.0, 6.0)
	var tip := Fire.PROFILE.size() - 1
	assert_almost_eq(licking[0].x, still[0].x, 0.001, "le pied ne bouge pas")
	assert_almost_eq(licking[tip].x - still[tip].x, 6.0, 0.001, "la pointe porte tout l'écart")


## Un sommet en double fait **échouer la triangulation** de Godot : la langue
## disparaît et la console crie, une fois sur deux, sur les plus fines seulement.
## Le piège se repose à chaque polygone dont un bout se ferme sur un point.
func test_a_tongue_has_no_duplicated_vertex() -> void:
	var pts := Fire.tongue(Vector2.ZERO, Vector2.UP, 3.0, 1.0, 1.4)
	assert_eq(pts.size(), Fire.PROFILE.size() * 2 - 1, "la pointe n'est écrite qu'une fois")
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			assert_gt(pts[i].distance_to(pts[j]), 0.0001, "deux sommets confondus en %d/%d" % [i, j])
