class_name StatsDeCompetence
extends RefCounted

## Ce qu'un lancer fait vraiment : les nombres de la compétence, une fois
## appliqués les modificateurs dont elle porte le mot-clé.
##
## **Le résultat d'un lancer, pas un état.** Elle naît à chaque appel de
## `Competence.resoudre()` et meurt avec lui ; rien ne la garde, donc rien ne peut
## la laisser périmer après un changement d'équipement.
##
## Pas dans `CharacterStats` : la fiche décrit un corps, et « nombre de
## projectiles » n'est pas une propriété du personnage mais d'un geste. Deux
## compétences lancées par le même personnage n'en ont pas le même nombre.

## Ce qu'un modificateur a le droit de viser, et le nom qu'il porte à l'écran —
## en plus des dégâts ajoutés par nature, dont le nom se forme sur
## `DamageType.IDS` (voir `nature_ajoutee`).
##
## `degats` ne se vise qu'en pourcentage, et multiplie **toutes** les parts : un
## « +12 % dégâts (Foudre) » vise les compétences de foudre, et le froid qu'elles
## portent en fait partie. Un plat sans nature ne voudrait plus rien dire.
##
## Le coût et l'intervalle n'y sont pas : ils ont déjà leurs voies — la réserve,
## et les vitesses d'attaque et d'incantation de la fiche — et une seconde voie
## vers le même nombre obligerait à se demander laquelle s'applique d'abord.
##
## « nombre de projectiles » et non « projectile » : la ligne se lit
## « valeur + nom », comme « +25 armure », et un « +2 projectile » au singulier
## serait faux dès le second palier.
const LABELS := {
	DEGATS: "dégâts",
	"projectiles": "nombre de projectiles",
	"vitesse_de_projectile": "vitesse de projectile",
}

const DEGATS := "degats"

## Le début du nom d'une statistique de dégâts ajoutés : `degats_` puis
## l'identifiant d'une nature.
const PREFIXE_AJOUTE := "degats_"

## L'écart minimal entre deux traits voisins, en degrés.
##
## Sans lui, un « +1 projectile » sur un trait droit en ferait partir deux **l'un
## sur l'autre** : on en verrait un seul, qui frapperait deux fois la même cible.
## Huit degrés les séparent d'une largeur d'ennemi à cent pixels, sans en faire un
## éventail. Une salve déjà plus large que ça garde la sienne.
const ECART_MINIMAL := 8.0

## Les dégâts, **par nature et en fourchette** : les deux tableaux sont indexés par
## `DamageType.Kind`. La nature de la compétence y porte ses dégâts propres, bornes
## égales ; les objets y ajoutent leurs fourchettes, dans leur nature à eux.
var degats_min: Array[float] = DamageType.parts_vides()
var degats_max: Array[float] = DamageType.parts_vides()
## Un réel pendant la résolution, arrondi à la fin par `conclure()`. Un « +50 % »
## sur trois projectiles donne 4,5 ; arrondir à chaque modificateur ferait
## dépendre le résultat de leur ordre. Et un champ entier tronquerait en silence
## ce que `set()` y écrit.
var projectiles := 1.0
var dispersion_en_degres := 0.0
var vitesse_de_projectile := 0.0
var cout_en_mana := 0.0
var intervalle := 0.0

## Les mots-clés que ce lancer porte **vraiment** : ceux de la compétence, plus
## ceux qu'un nœud d'arbre investi lui donne.
##
## Ici et non sur la compétence : un mot-clé qui vient d'un talent n'appartient
## pas au sort mais à ce lancer-là. Et c'est cette liste qui a filtré les
## modificateurs, donc la seule qui ne puisse pas annoncer autre chose que ce
## qu'elle a appliqué.
var mots_cles := PackedStringArray()

## La nature de la compétence lancée, avant toute conversion. Posée par
## `resoudre()` : la fiche et le tir la lisaient sur la compétence, et un jour où
## ils ne recevront que le geste, ils auraient eu à la chercher ailleurs.
var nature := int(DamageType.Kind.PHYSICAL)

## Ce qui compose les dégâts, pour la fiche du manuel : la ligne de la table, les
## fourchettes ajoutées par nature, et les deux multiplicateurs. **Écrits par les
## appels mêmes qui calculent** `degats_min` et `degats_max` : une fiche qui
## recomposerait ses lignes de son côté finirait par annoncer une somme que le
## lancer ne fait pas.
var degats_de_base := 0.0
var ajoutes_min: Array[float] = DamageType.parts_vides()
var ajoutes_max: Array[float] = DamageType.parts_vides()
var facteur_d_attribut := 1.0
## Le produit des « +% dégâts » portés : ils se multiplient entre eux, donc deux
## « +10 % » font 1,21 et non 1,20.
var accroissement := 1.0
## La part du coup qu'un nœud a déplacée, **par nature d'arrivée**, pour la fiche.
## Le lancer n'en a pas besoin : `degats_min` et `degats_max` sont déjà déplacés.
var convertis: Array[float] = DamageType.parts_vides()


## La nature qu'ajoute cette statistique, ou -1 si elle n'est pas un ajout de
## dégâts. Une nature inconnue rend aussi -1 : une faute de frappe dans un `.tres`
## est l'affaire du test de la réserve, pas d'un combat.
static func nature_ajoutee(stat: String) -> int:
	if not stat.begins_with(PREFIXE_AJOUTE):
		return -1
	return DamageType.IDS.find(stat.trim_prefix(PREFIXE_AJOUTE))


static func stat_ajoutee(nature: DamageType.Kind) -> String:
	return PREFIXE_AJOUTE + DamageType.IDS[nature]


## « 3–7 », ou « 23 » quand les deux bornes s'arrondissent au même nombre : des
## dégâts résolus sont des réels, et « 29–29 » se lirait comme une faute.
static func fourchette_lisible(bas: float, haut: float) -> String:
	var b := roundi(bas)
	var h := roundi(haut)
	return str(b) if b == h else "%d–%d" % [b, h]


## Ce qu'une ligne portée a le droit de viser : un nombre nommé, ou des dégâts
## ajoutés d'une nature connue.
static func modifiable(stat: String) -> bool:
	return LABELS.has(stat) or nature_ajoutee(stat) >= 0


func nombre_de_projectiles() -> int:
	return int(projectiles)


## « Projectile · Foudre · Sort », mots-clés des talents compris. Par la même
## fonction que la fiche de la compétence : deux compositions divergeraient d'un
## séparateur.
func libelle_des_mots_cles() -> String:
	return MotsCles.ligne(mots_cles)


## La nature que ce lancer **montre** : la sienne, ou celle vers laquelle une
## conversion a emmené la plus grande part de ses dégâts propres.
##
## Elle ne regarde que la base et les conversions, **jamais ce qu'un objet
## ajoute** : c'est la décision du jalon 8 — un éclair reste un éclair, le froid
## qu'un anneau y met change ses dégâts et pas son dessin. Une conversion, elle,
## change ce que la compétence est.
func nature_dominante() -> int:
	var meilleure := nature
	var part := 1.0
	for p in convertis:
		part -= p
	for i in convertis.size():
		if convertis[i] > part:
			part = convertis[i]
			meilleure = i
	return meilleure


## Les dégâts propres de la compétence, dans sa nature, bornes égales.
func poser_la_base(nature: int, montant: float) -> void:
	degats_de_base = montant
	degats_min[nature] += montant
	degats_max[nature] += montant


## Une fourchette de plus dans cette nature. La borne haute ne descend jamais sous
## la basse : un affixe mal saisi ne doit pas donner une fourchette à l'envers,
## que le tirage lirait à rebours.
func ajouter(nature: int, bas: float, haut: float) -> void:
	var sommet := maxf(haut, bas)
	ajoutes_min[nature] += bas
	ajoutes_max[nature] += sommet
	degats_min[nature] += bas
	degats_max[nature] += sommet


## Déplace une part des dégâts d'une nature vers une autre — le nœud de
## conversion. Appelée **après les fourchettes ajoutées** : la foudre qu'un anneau
## ajoute à un sort de foudre part avec le reste, sinon le même objet donnerait
## deux résultats selon l'ordre dans lequel ses lignes arrivent.
##
## Avant ou après les multiplicateurs, c'est numériquement pareil — ils
## multiplient toutes les parts du même facteur.
func convertir(source: int, cible: int, part: float) -> void:
	var reste := clampf(part, 0.0, 1.0)
	if source == cible or reste <= 0.0:
		return
	var bas := degats_min[source] * reste
	var haut := degats_max[source] * reste
	degats_min[source] -= bas
	degats_max[source] -= haut
	degats_min[cible] += bas
	degats_max[cible] += haut

	# Ce qu'on annonce est la part du coup **entier**, et non celle du reste :
	# deux nœuds à 50 % convertissent les trois quarts, et la fiche doit dire 75 %
	# plutôt que 100 %.
	var deja := 0.0
	for p in convertis:
		deja += p
	convertis[cible] += reste * (1.0 - deja)


func appliquer_l_attribut(facteur: float) -> void:
	facteur_d_attribut *= facteur
	_multiplier(facteur)


## Un « +% dégâts ». Appliqué à la suite des précédents et non sommé : c'est ce
## qu'on faisait avant que la fiche ne lise la décomposition, et un personnage ne
## doit pas changer de dégâts parce qu'on les affiche.
func accroitre(pourcentage: float) -> void:
	var facteur := 1.0 + pourcentage * 0.01
	accroissement *= facteur
	_multiplier(facteur)


func _multiplier(facteur: float) -> void:
	for i in degats_min.size():
		degats_min[i] *= facteur
		degats_max[i] *= facteur


func total_min() -> float:
	var total := 0.0
	for part in degats_min:
		total += part
	return total


func total_max() -> float:
	var total := 0.0
	for part in degats_max:
		total += part
	return total


## Ce qu'un lancer entier fait en moyenne, **si tout touche** : le milieu de chaque
## fourchette — un tirage uniforme y tombe en moyenne —, fois le nombre de
## projectiles. Avant les défenses de la cible, qu'on ne connaît pas d'avance.
##
## Sans le critique : un projectile du joueur n'en fait pas, seul le coup d'arme
## passe par `DamageInfo.roll()`. Pour lui, l'estimation est un plancher.
func moyenne_par_lancer() -> float:
	return (total_min() + total_max()) * 0.5 * float(nombre_de_projectiles())


## La même, ramenée à la seconde par l'intervalle entre deux lancers — sans compter
## la réserve, qu'un sort trop cher ne tiendrait pas à cette cadence. Zéro sans
## intervalle, plutôt qu'une division qui afficherait l'infini.
func moyenne_par_seconde() -> float:
	if intervalle <= 0.0:
		return 0.0
	return moyenne_par_lancer() / intervalle


## Les parts d'**un** coup, tirées dans leurs fourchettes.
##
## **Un tirage par fourchette ouverte, quel que soit le résultat** (invariant 3) :
## le compte ne dépend que des bornes, donc de l'équipement. Une part aux bornes
## égales — les dégâts propres d'une compétence — ne tire rien.
func tirer(rng: RandomNumberGenerator) -> Array[float]:
	var parts := DamageType.parts_vides()
	for i in parts.size():
		parts[i] = degats_min[i]
		if degats_max[i] > degats_min[i]:
			parts[i] = rng.randf_range(degats_min[i], degats_max[i])
	return parts


## Les bornes, une fois **tous** les modificateurs appliqués et jamais avant.
##
## La dispersion est bornée au tour complet : au-delà, le lanceur prendrait un
## éventail très large pour une couronne et répartirait les traits comme telle.
func conclure() -> void:
	var n := maxi(roundi(projectiles), 1)
	projectiles = float(n)
	dispersion_en_degres = clampf(
		maxf(dispersion_en_degres, ECART_MINIMAL * float(n - 1)), 0.0, 360.0
	)
