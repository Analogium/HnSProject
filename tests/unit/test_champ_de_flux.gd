extends GutTest

## Le champ de flux. Du calcul sur une grille : aucun nœud, aucune physique.
##
## Les cartes sont écrites à la main, en toutes lettres. C'est plus long qu'une
## graine, mais un test de contournement doit montrer **le mur qu'on contourne**
## — sinon on ne sait pas ce qu'il vérifie quand il échoue.

const MUR := MapGenerator.WALL
const SOL := MapGenerator.FLOOR


## Construit une carte depuis un dessin. '#' est un mur, tout le reste du sol.
func _carte(lignes: Array) -> MapGenerator:
	var gen := MapGenerator.new(lignes[0].length(), lignes.size())
	gen.grid = []
	for ligne in lignes:
		var rangee := []
		for x in ligne.length():
			rangee.append(MUR if ligne[x] == "#" else SOL)
		gen.grid.append(rangee)
	return gen


## Suit le champ pas à pas et rend le nombre de cases parcourues, ou -1 si on
## n'arrive jamais. C'est la seule façon honnête de tester un champ de flux :
## une direction isolée ne prouve rien, c'est le chemin entier qui compte.
func _marcher(champ: FlowField, depuis: Vector2i, plafond := 400) -> int:
	var ou := depuis
	for pas in plafond:
		if ou == champ.origin:
			return pas
		var d := champ.direction_at(ou)
		if d == Vector2.ZERO:
			return -1
		ou += Vector2i(roundi(d.x), roundi(d.y))
	return -1


## Le défaut que le champ vient corriger : un ennemi enfermé dans un U fonçait
## sur la paroi qui le sépare du joueur et y restait.
func test_un_ennemi_dans_un_cul_de_sac_en_sort() -> void:
	var gen := _carte([
		"#########",
		"#.......#",
		"#.#####.#",
		"#.#...#.#",
		"#.#.#.#.#",
		"#...#...#",
		"#########",
	])
	var champ := FlowField.new(gen)
	champ.rebuild(Vector2i(1, 1), 20)

	# (4, 3) est au fond du U : à vol d'oiseau le joueur est à trois cases, mais
	# il faut en faire bien plus pour contourner.
	var pas := _marcher(champ, Vector2i(4, 3))
	assert_gt(pas, 3, "le chemin contourne, il ne traverse pas")
	assert_ne(pas, -1, "et il arrive")


func test_le_champ_mene_au_joueur_depuis_partout() -> void:
	var gen := _carte([
		"#########",
		"#.......#",
		"#.#####.#",
		"#.#...#.#",
		"#.#.#.#.#",
		"#...#...#",
		"#########",
	])
	var champ := FlowField.new(gen)
	champ.rebuild(Vector2i(7, 5), 20)

	for y in gen.height:
		for x in gen.width:
			var cell := Vector2i(x, y)
			if not gen.is_walkable(cell):
				continue
			assert_ne(_marcher(champ, cell), -1, "depuis %s" % cell)


## Une poche fermée n'a aucun chemin. Le champ doit le dire par un zéro, et non
## par une direction qui enverrait l'ennemi dans le mur.
func test_une_poche_fermee_n_a_pas_de_direction() -> void:
	var gen := _carte([
		"#######",
		"#..#..#",
		"#..#..#",
		"#######",
	])
	var champ := FlowField.new(gen)
	champ.rebuild(Vector2i(1, 1), 20)

	assert_true(champ.reaches(Vector2i(2, 2)), "son côté est atteignable")
	assert_false(champ.reaches(Vector2i(4, 1)), "l'autre côté ne l'est pas")
	assert_eq(champ.direction_at(Vector2i(4, 1)), Vector2.ZERO, "et n'a pas de direction")


## Sans ce test, une diagonale passerait entre deux pierres qui se touchent par
## le coin — l'ennemi s'y coincerait en essayant de suivre une direction que la
## physique lui refuse.
func test_une_diagonale_ne_coupe_pas_un_angle_de_mur() -> void:
	var gen := _carte([
		"#####",
		"#.#.#",
		"#..##",
		"#...#",
		"#####",
	])
	var champ := FlowField.new(gen)
	champ.rebuild(Vector2i(1, 1), 20)
	# (3, 1) touche (2, 2) par le coin, entre les murs (2, 1) et (3, 2).
	assert_false(champ.reaches(Vector2i(3, 1)), "on ne se faufile pas par un coin")


func test_la_case_du_joueur_n_a_pas_de_direction() -> void:
	var gen := _carte(["#####", "#...#", "#####"])
	var champ := FlowField.new(gen)
	champ.rebuild(Vector2i(2, 1), 20)
	assert_true(champ.reaches(Vector2i(2, 1)), "on y est")
	assert_eq(champ.direction_at(Vector2i(2, 1)), Vector2.ZERO, "il n'y a plus où aller")


## Le rayon vient de la distance de culling : au-delà, l'EnemyManager ne fait
## plus vivre personne, et calculer un chemin y serait du travail pour des
## ennemis figés.
func test_le_champ_s_arrete_au_rayon_demande() -> void:
	var lignes := ["#" .repeat(20)]
	for y in 8:
		lignes.append("#" + ".".repeat(18) + "#")
	lignes.append("#".repeat(20))

	var champ := FlowField.new(_carte(lignes))
	champ.rebuild(Vector2i(2, 4), 3)
	assert_true(champ.reaches(Vector2i(5, 4)), "trois cases : dedans")
	assert_false(champ.reaches(Vector2i(12, 4)), "dix cases : dehors")
	assert_eq(champ.direction_at(Vector2i(12, 4)), Vector2.ZERO)


## Un joueur repoussé dans la pierre ne doit pas faire décrocher tous les
## ennemis d'un coup : le champ repart de la case praticable la plus proche.
func test_un_depart_dans_un_mur_se_rattrape() -> void:
	var gen := _carte([
		"#####",
		"#...#",
		"#.#.#",
		"#...#",
		"#####",
	])
	var champ := FlowField.new(gen)
	champ.rebuild(Vector2i(2, 2), 20)
	assert_ne(champ.origin, Vector2i(2, 2), "l'origine a glissé hors du mur")
	assert_true(gen.is_walkable(champ.origin), "sur une case praticable")
	assert_ne(_marcher(champ, Vector2i(1, 1)), -1, "et le champ reste utilisable")


## Deux calculs sur la même carte depuis la même case donnent le même champ.
## C'est la doctrine du projet : une graine doit redonner exactement la même
## partie, poursuite comprise.
func test_deux_calculs_donnent_le_meme_champ() -> void:
	var gen := _carte([
		"#########",
		"#.......#",
		"#.#####.#",
		"#.#...#.#",
		"#...#...#",
		"#########",
	])
	var a := FlowField.new(gen)
	var b := FlowField.new(gen)
	a.rebuild(Vector2i(1, 1), 20)
	b.rebuild(Vector2i(1, 1), 20)
	for y in gen.height:
		for x in gen.width:
			assert_eq(
				a.direction_at(Vector2i(x, y)), b.direction_at(Vector2i(x, y)),
				"case %d,%d" % [x, y]
			)
