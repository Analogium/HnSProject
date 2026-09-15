class_name StatsDeCompetence
extends RefCounted

## Ce qu'un lancer fait vraiment : les nombres de la compétence après modificateurs.
## Le résultat d'un lancer, jamais gardé, donc jamais périmé. Hors de
## `CharacterStats` : c'est la propriété d'un geste, pas d'un corps.

## Ce qu'un modificateur peut viser, et son nom à l'écran — en plus des dégâts
## ajoutés `degats_<nature>`. `degats` ne se vise qu'en pourcentage et multiplie
## toutes les parts. Ni coût ni intervalle (la réserve et les vitesses ont leur voie),
## ni `periode` ni `brulure` (voir `Competence`).
const LABELS := {
	DEGATS: "dégâts",
	"projectiles": "nombre de projectiles",
	"vitesse_de_projectile": "vitesse de projectile",
	"cibles": "nombre de cibles",
	"duree": "durée",
	"rayon": "rayon",
	"simultanes": "maximum simultané",
}

const DEGATS := "degats"

## Le début du nom d'une statistique de dégâts ajoutés : `degats_` puis
## l'identifiant d'une nature.
const PREFIXE_AJOUTE := "degats_"

## L'écart minimal entre deux traits voisins, en degrés : sans lui, « +1 projectile »
## sur un trait droit en superposerait deux.
const ECART_MINIMAL := 8.0

## Les dégâts **par nature et en fourchette**, indexés par `DamageType.Kind`.
var degats_min: Array[float] = DamageType.parts_vides()
var degats_max: Array[float] = DamageType.parts_vides()
## Réels pendant la résolution, arrondis par `conclure()` : arrondir à chaque
## modificateur ferait dépendre le résultat de leur ordre.
var projectiles := 1.0
var dispersion_en_degres := 0.0
var vitesse_de_projectile := 0.0
## Réels puis arrondis, comme `projectiles`.
var cibles := 1.0
var simultanes := 0.0
var duree := 0.0
var rayon := 0.0
var periode := 0.0
var brulure := 0.0
## Les coups d'un geste, que la forme décide.
var coups := 1
## Vrai pour ce qui n'a pas de fin, l'aura : pas de « par lancer ».
var entretenue := false
var cout_en_mana := 0.0
var intervalle := 0.0

## Les mots-clés que ce lancer porte vraiment, nœuds compris : c'est cette liste
## qui a filtré les modificateurs.
var mots_cles := PackedStringArray()

## La nature de la compétence, avant conversion.
var nature := int(DamageType.Kind.PHYSICAL)

## La décomposition pour la fiche du manuel, **écrite par les appels qui calculent**
## les dégâts : recomposée à côté, elle finirait par mentir.
var degats_de_base := 0.0
var ajoutes_min: Array[float] = DamageType.parts_vides()
var ajoutes_max: Array[float] = DamageType.parts_vides()
## Le produit des « +% dégâts » portés : ils se multiplient entre eux, donc deux
## « +10 % » font 1,21 et non 1,20.
var accroissement := 1.0
## La part du coup qu'un nœud a déplacée, **par nature d'arrivée**, pour la fiche.
## Le lancer n'en a pas besoin : `degats_min` et `degats_max` sont déjà déplacés.
var convertis: Array[float] = DamageType.parts_vides()


## La nature ajoutée par cette statistique, ou -1.
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


## Un nombre nommé, ou des dégâts ajoutés d'une nature connue.
static func modifiable(stat: String) -> bool:
	return LABELS.has(stat) or nature_ajoutee(stat) >= 0


func nombre_de_projectiles() -> int:
	return int(projectiles)


func nombre_de_cibles() -> int:
	return int(cibles)


func maximum_simultane() -> int:
	return int(simultanes)


## Une impulsion à la pose, puis une par période ; l'epsilon absorbe l'arrondi d'une
## durée modifiée. **Le nuage compte ses frappes par ici**, comme la fiche.
func frappes_dans_la_duree() -> int:
	if duree <= 0.0 or periode <= 0.0:
		return 1
	return maxi(floori(duree / periode + 0.0001), 1)


## « Projectile · Foudre · Sort », nœuds compris.
func libelle_des_mots_cles() -> String:
	return MotsCles.ligne(mots_cles)


## La nature que le lancer **montre** : la sienne, ou celle où une conversion a
## emmené le plus de ses dégâts propres — jamais ce qu'un objet ajoute (jalon 8).
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


## La borne haute ne descend jamais sous la basse.
func ajouter(nature: int, bas: float, haut: float) -> void:
	var sommet := maxf(haut, bas)
	ajoutes_min[nature] += bas
	ajoutes_max[nature] += sommet
	degats_min[nature] += bas
	degats_max[nature] += sommet


## Le nœud de conversion, appelé **après les fourchettes ajoutées** : il prend sa part
## de **chaque** nature, ajouts compris. Entière, il ne reste qu'une nature, donc
## qu'un état possible.
func convertir(cible: int, part: float) -> void:
	var reste := clampf(part, 0.0, 1.0)
	if reste <= 0.0:
		return
	for source in degats_min.size():
		if source == cible:
			continue
		var bas := degats_min[source] * reste
		var haut := degats_max[source] * reste
		degats_min[source] -= bas
		degats_max[source] -= haut
		degats_min[cible] += bas
		degats_max[cible] += haut
		convertis[source] *= 1.0 - reste
	# La part du coup **entier** : deux nœuds à 50 % font 75 %, pas 100 %.
	convertis[cible] += reste * (1.0 - convertis[cible])


## Appliqué à la suite, pas sommé : deux « +10 % » font 1,21.
func accroitre(pourcentage: float) -> void:
	var facteur := 1.0 + pourcentage * 0.01
	accroissement *= facteur
	_multiplier(facteur)


func _multiplier(facteur: float) -> void:
	for i in degats_min.size():
		degats_min[i] *= facteur
		degats_max[i] *= facteur


## La part de chaque nature, somme à un ; toute dans sa nature sans dégâts.
## Contrairement à `nature_dominante()`, ce qu'un objet ajoute compte.
func repartition() -> Array[float]:
	var out := DamageType.parts_vides()
	var total := total_min() + total_max()
	if total <= 0.0:
		out[nature] = 1.0
		return out
	for i in out.size():
		out[i] = (degats_min[i] + degats_max[i]) / total
	return out


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


## Le milieu de chaque fourchette.
func moyenne_par_coup() -> float:
	return (total_min() + total_max()) * 0.5


## Un lancer entier **si tout touche**, avant défenses et sans critique :
## projectiles × cibles × coups × frappes dans la durée. Zéro pour une aura.
func moyenne_par_lancer() -> float:
	if entretenue:
		return 0.0
	var nombre := nombre_de_projectiles() * nombre_de_cibles() * coups * frappes_dans_la_duree()
	return moyenne_par_coup() * float(nombre)


## Par l'intervalle entre deux lancers, sans compter la réserve ; pour une aura, un
## coup par période. Une orbite est bornée par son maximum simultané.
func moyenne_par_seconde() -> float:
	if entretenue:
		return moyenne_par_coup() / periode if periode > 0.0 else 0.0
	if intervalle <= 0.0:
		return 0.0
	var par_seconde := moyenne_par_lancer() / intervalle
	if maximum_simultane() > 0 and periode > 0.0:
		par_seconde = minf(par_seconde, moyenne_par_coup() * float(maximum_simultane()) / periode)
	return par_seconde


## Les parts d'**un** coup : un tirage par fourchette ouverte, quel que soit le
## résultat (invariant 3).
func tirer(rng: RandomNumberGenerator) -> Array[float]:
	var parts := DamageType.parts_vides()
	for i in parts.size():
		parts[i] = degats_min[i]
		if degats_max[i] > degats_min[i]:
			parts[i] = rng.randf_range(degats_min[i], degats_max[i])
	return parts


## Les bornes, une fois tous les modificateurs appliqués : dispersion bornée au tour
## complet, et une chaîne garde au moins une cible.
func conclure() -> void:
	var n := maxi(roundi(projectiles), 1)
	projectiles = float(n)
	dispersion_en_degres = clampf(
		maxf(dispersion_en_degres, ECART_MINIMAL * float(n - 1)), 0.0, 360.0
	)
	cibles = float(maxi(roundi(cibles), 1))
	simultanes = float(maxi(roundi(simultanes), 0))
	duree = maxf(duree, 0.0)
	rayon = maxf(rayon, 0.0)
