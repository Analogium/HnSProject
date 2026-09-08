class_name FlowField

## Le chemin vers le joueur, calculé une fois pour tout le monde : un parcours en
## largeur depuis sa case, où chaque case retient **vers quelle voisine partir**.
## Un ennemi lit la direction de sa case et n'a rien d'autre à savoir.
##
## Le coût ne dépend pas du nombre d'ennemis : soixante-dix lisent le même champ,
## sept cents aussi. Un A* par ennemi ferait exactement l'inverse, et c'est le
## nombre d'ennemis que la mesure de référence surveille.
##
## Déterministe : à grille et case de départ égales, l'ordre de parcours étant
## fixe, le champ est toujours le même.

## Les huit voisines, dans l'ordre du parcours. Les quatre orthogonales d'abord :
## à distance égale, un ennemi préfère un couloir droit à un escalier de
## diagonales, qui le ferait raser les murs.
##
## **Rangées par paires opposées** — 0 et 1, 2 et 3, et ainsi de suite : c'est ce
## qui permet de retrouver la direction inverse par un simple `d ^ 1`. Changer cet
## ordre sans garder les paires ferait pointer les diagonales à l'exact opposé de
## leur chemin, ce qui ne se verrait qu'en jeu.
const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, -1),
	Vector2i(1, -1), Vector2i(-1, 1),
]

## Case sans direction : hors du champ, dans un mur, ou dans une poche qui ne
## communique pas avec le joueur. L'appelant retombe alors sur la ligne droite.
const NONE := 255
## La case du joueur elle-même : on y est, il n'y a plus de direction à suivre.
const HERE := 254

var _generator: MapGenerator
var _dirs := PackedByteArray()
var _file := PackedInt32Array()

## La praticabilité de la carte, à plat, et les huit décalages de DIRS en index de
## tableau. Trois tableaux packés au lieu des structures lisibles d'à côté : c'est
## l'exception que ce projet réserve aux boucles **mesurées**.
##
## Le parcours interroge huit voisines par case, une vingtaine de milliers de fois
## par recalcul. En passant par `MapGenerator.is_walkable` il coûtait **5,45 ms**,
## un tiers d'image dix fois par seconde ; à plat, **1,67 ms** (graine 4242, après
## chauffe).
##
## La carte ne change pas sous nos pieds : la zone fabrique un champ neuf à chaque
## nouvelle carte.
var _walkable := PackedByteArray()
var _dx := PackedInt32Array()
var _dy := PackedInt32Array()
## D'où le champ a été calculé, et jusqu'où. Publics : c'est l'appelant qui
## décide s'il est encore valable.
var origin := Vector2i(-1, -1)
var radius := 0


func _init(generator: MapGenerator) -> void:
	_generator = generator
	_dirs.resize(generator.width * generator.height)
	_dirs.fill(NONE)
	# La file est allouée une fois et réemployée : un recalcul par dixième de
	# seconde qui redemanderait trente-six kilo-octets à chaque fois travaillerait
	# surtout pour le ramasse-miettes.
	_file.resize(_dirs.size())

	_walkable.resize(_dirs.size())
	for y in generator.height:
		for x in generator.width:
			_walkable[y * generator.width + x] = 1 if generator.grid[y][x] == MapGenerator.FLOOR else 0
	for d in DIRS:
		_dx.append(d.x)
		_dy.append(d.y)


## Recalcule le champ autour de `from`, dans un rayon de `cells` cases.
##
## Borné, et pas par principe : au-delà de sa distance de culling l'EnemyManager ne
## fait plus vivre personne. Le rayon vient de lui, et il coûte cher — carte
## entière 8,9 ms, rayon de 23 cases 1,67 ms.
func rebuild(from: Vector2i, cells: int) -> void:
	_dirs.fill(NONE)
	origin = from
	radius = cells
	if not _generator.is_walkable(from):
		# Le joueur peut être poussé dans un mur par un recul. On repart de la
		# case praticable la plus proche plutôt que de rendre un champ vide, qui
		# ferait décrocher tous les ennemis d'un coup.
		origin = _nearest_walkable(from)
		if origin.x < 0:
			return

	var queue := 0
	var tete := 0
	var w := _generator.width
	var h := _generator.height
	_dirs[_index(origin)] = HERE
	_file[queue] = _index(origin)
	queue += 1

	while tete < queue:
		var courant := _file[tete]
		tete += 1
		var cx := courant % w
		var cy := courant / w
		for d in DIRS.size():
			var nx := cx + _dx[d]
			var ny := cy + _dy[d]
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			if absi(nx - origin.x) > cells or absi(ny - origin.y) > cells:
				continue
			var i := ny * w + nx
			if _walkable[i] == 0 or _dirs[i] != NONE:
				continue
			# Une diagonale ne coupe pas un angle de mur : sans ce test, un ennemi
			# passerait en biais entre deux pierres qui se touchent par le coin,
			# et resterait bloqué contre elles en essayant.
			if _dx[d] != 0 and _dy[d] != 0:
				if _walkable[ny * w + cx] == 0 or _walkable[cy * w + nx] == 0:
					continue
			# On stocke la direction **inverse** : la voisine qu'on vient
			# d'atteindre doit repartir vers la case dont elle vient. Les paires
			# opposées étant adjacentes dans DIRS, l'inverse est un bit à
			# retourner.
			_dirs[i] = d ^ 1
			_file[queue] = i
			queue += 1


## La direction à suivre depuis cette case, ou Vector2.ZERO quand le champ n'a
## rien à en dire. Le zéro n'est pas une erreur : c'est le signal que l'appelant
## doit se débrouiller autrement — en général, foncer en ligne droite.
func direction_at(cell: Vector2i) -> Vector2:
	if not _generator.in_bounds(cell):
		return Vector2.ZERO
	var d := _dirs[_index(cell)]
	if d >= HERE:
		return Vector2.ZERO
	return Vector2(DIRS[d]).normalized()


## Vrai quand cette case a un chemin vers l'origine. Distinct de la direction :
## la case du joueur est atteignable et n'a pourtant aucune direction.
func reaches(cell: Vector2i) -> bool:
	if not _generator.in_bounds(cell):
		return false
	return _dirs[_index(cell)] != NONE


func _index(cell: Vector2i) -> int:
	return cell.y * _generator.width + cell.x


## Balayage en carrés concentriques autour de la case. Sur quelques anneaux
## seulement : au-delà, c'est que le joueur est perdu très loin dans la pierre,
## et le champ vide est alors la bonne réponse.
func _nearest_walkable(from: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var c := from + Vector2i(dx, dy)
				if _generator.is_walkable(c):
					return c
	return Vector2i(-1, -1)
