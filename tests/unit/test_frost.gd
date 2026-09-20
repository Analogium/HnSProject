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


## Les deux flancs partagent le pied et la pointe, et rien d'autre : c'est cette
## arête commune qui fait la facette. S'ils se recouvraient, le cristal serait plat.
func test_the_two_flanks_share_the_foot_and_the_tip() -> void:
	var dark := Frost.shard(Vector2.ZERO, Vector2.UP, 20.0, 4.0, 0.0, false)
	var lit := Frost.shard(Vector2.ZERO, Vector2.UP, 20.0, 4.0, 0.0, true)
	assert_eq(dark[0], lit[0], "même pied")
	assert_eq(dark[dark.size() - 1], lit[lit.size() - 1], "même pointe")
	assert_lt(dark[1].x, 0.0, "le flanc sombre est d'un côté")
	assert_gt(lit[1].x, 0.0, "l'éclairé de l'autre")


## `lean` penche les deux flancs **du même côté** : signés chacun du sien, le
## cristal s'ouvrirait en ciseaux au lieu de pencher.
func test_lean_tilts_both_flanks_the_same_way() -> void:
	var dark := Frost.shard(Vector2.ZERO, Vector2.UP, 20.0, 4.0, 5.0, false)
	var lit := Frost.shard(Vector2.ZERO, Vector2.UP, 20.0, 4.0, 5.0, true)
	assert_almost_eq(dark[dark.size() - 1].x, 5.0, 0.001, "la pointe sombre penche")
	assert_almost_eq(lit[lit.size() - 1].x, 5.0, 0.001, "la pointe éclairée aussi")


## Même piège que les langues de `Fire` : un sommet en double fait échouer la
## triangulation de Godot, qui ne dessine alors rien et crie à chaque image.
func test_a_flank_has_no_duplicated_vertex() -> void:
	for lit: bool in [false, true]:
		var pts := Frost.shard(Vector2.ZERO, Vector2.UP, 3.0, 1.0, 1.0, lit)
		for i in pts.size():
			for j in range(i + 1, pts.size()):
				assert_gt(pts[i].distance_to(pts[j]), 0.0001, "sommets confondus en %d/%d" % [i, j])
