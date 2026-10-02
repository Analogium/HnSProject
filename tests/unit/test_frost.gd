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


## Ce qui fait la glace, c'est la **facette** : une arête qui déborde et deux
## flancs qui ne débordent pas. Un cristal dont tout passe le seuil est une
## ampoule, un cristal dont rien ne le passe est un caillou bleu.
func test_the_crystal_glows_by_its_ridge_only() -> void:
	var image: Image = EffectForge.spike(COLD).get_image()
	var lit := 0
	var matter := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			matter += 1
			if c.get_luminance() > THRESHOLD:
				lit += 1
	assert_gt(lit, 0, "l'arête déborde")
	assert_lt(float(lit) / float(matter), 0.4, "mais elle reste une arête")


## Le petit cristal est la même matière à une autre taille : alternés, c'est leur
## différence qui casse la palissade.
func test_the_small_crystal_is_shorter_than_the_tall_one() -> void:
	assert_lt(
		EffectForge.SMALL_SPIKE_HEIGHT, EffectForge.SPIKE_HEIGHT,
		"un grand, un petit"
	)


## Le javelot du Trait de glace : fabriqué une fois par cap, et le tour complet retombe
## sur le premier. Il reste une facette — l'arête claire, des flancs qui ne débordent pas.
func test_the_javelin_is_made_once_per_heading() -> void:
	var a := Frost.javelin(COLD, 3)
	assert_same(a, Frost.javelin(COLD, 3 + Slash.TURNS), "deux demandes, une fabrication")
	assert_ne(a, Frost.javelin(COLD, 4), "deux caps voisins diffèrent")
	var image: Image = a.texture.get_image()
	var bright := 0
	var matter := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			matter += 1
			if c.get_luminance() > 0.85:
				bright += 1
	assert_gt(bright, 0, "l'arête")
	assert_lt(float(bright) / float(matter), 0.5, "et des flancs")
