extends GutTest

## La matière de la glace. Sa promesse est l'inverse de celle du feu : le cyan
## **brille déjà** (0,81 de luminance, la matière la plus claire du jeu), donc ce
## qu'il faut protéger n'est pas son éclat mais sa teinte — un cristal blanchi se
## lit comme du verre, et plus rien ne dit qu'il est froid.

const COLD := Color(0.50, 0.88, 1.00)
const THRESHOLD := 0.9


## Les deux bouts de la mesure : l'arête déborde, et elle reste bleue. La pointe
## d'avant, à 0,55 vers le blanc, avait 0,775 de rouge — autant dire du blanc.
func test_the_ridge_glows_without_losing_its_blue() -> void:
	var rim := Frost.rim(COLD)
	assert_gt(COLD.get_luminance(), 0.75, "le froid part déjà clair")
	assert_gt(rim.get_luminance(), 0.85, "et son arête frôle le seuil de glow")
	assert_lt(rim.r, 0.75, "sans virer au blanc")
