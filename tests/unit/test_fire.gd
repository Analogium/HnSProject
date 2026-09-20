extends GutTest

## La couleur du feu. Sa promesse tient en une mesure que la campagne ne voit pas
## autrement : un **cœur au-dessus du seuil de glow** (0,9). Les assertions de
## forme sont parties avec la langue en polygones, que plus rien ne trace — ce que
## vaut le dessin se mesure maintenant dans `test_effect_forge.gd`.

const FIRE := Color(1.00, 0.48, 0.18)
const THRESHOLD := 0.9


## Le chiffre de cette couche : l'orange du feu plafonne à 0,57 de luminance, donc
## une flamme entièrement teintée ne déborde jamais. Les quatre blancs chauds que
## `Fire.WARM` remplace donnaient des cœurs de 0,75 à 0,899 — tous sous le seuil,
## et deux d'entre eux prétendaient le passer.
func test_the_heart_of_a_flame_passes_the_glow_threshold() -> void:
	assert_lt(FIRE.get_luminance(), THRESHOLD, "l'orange du feu, seul, ne brille pas")
	assert_gt(Fire.heart(FIRE).get_luminance(), THRESHOLD, "son cœur, si")
