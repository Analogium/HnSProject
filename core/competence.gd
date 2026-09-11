class_name Competence
extends Resource

## Ce qu'un personnage sait faire : une fiche, et rien d'autre. Elle ne connaît
## ni le joueur, ni la scène, ni le manuel qui la contient — c'est le sens de
## circulation du jalon 6, et il ne s'inverse jamais. Le joueur demande des
## dégâts et les porte ; la compétence ne lance rien.
##
## Une Resource et non une classe écrite dans le code : une compétence est du
## contenu. En ajouter une doit être un fichier de plus, pas une branche de plus.

@export var id: String = ""
@export var nom: String = ""

## La nature du coup, qui décide de la résistance qui s'y oppose et de la couleur
## par laquelle il s'annonce. Physique par défaut : un coup dont personne n'a
## choisi l'élément ne doit pas en inventer un.
@export var nature: DamageType.Kind = DamageType.Kind.PHYSICAL

## Comment se compte la cadence de cette compétence. Deux règles et non deux
## valeurs, c'est pourquoi c'est un choix et non un nombre :
##
## - `ARME` : l'intervalle vient de la **fiche** — `attack_cooldown` divisé par
##   `attack_speed` — donc une arme rapide accélère le geste. `recharge` est alors
##   ignorée : la cadence d'un coup d'épée appartient à l'épée.
## - `INCANTATION` : l'intervalle est la `recharge` de la compétence divisée par
##   `cast_speed`. Un sort a sa propre lenteur, que l'incantation abrège.
enum Cadence { ARME, INCANTATION }

@export var cadence: Cadence = Cadence.INCANTATION

## Les mots-clés que la compétence déclare : **seulement ceux que rien d'autre ne
## dit**. Aujourd'hui, `projectile`.
##
## La nature et la cadence ne se redéclarent pas — voir les deux tables
## suivantes. Un `.tres` qui écrirait `foudre` ici en plus de sa nature porterait
## deux vérités sur la même chose, et la première correction en oublierait une.
@export var mots_cles_declares: PackedStringArray = PackedStringArray()

## Ce que la cadence et la nature disent d'elles-mêmes.
##
## Une nature absente de la table ne donne **aucun** mot-clé : rien ne vise encore
## le froid ni le feu, et les afficher enverrait le joueur chercher un objet qui
## n'existe pas.
const MOT_CLE_DE_CADENCE := {
	Cadence.ARME: MotsCles.ATTAQUE,
	Cadence.INCANTATION: MotsCles.SORT,
}
const MOT_CLE_DE_NATURE := {
	DamageType.Kind.LIGHTNING: MotsCles.FOUDRE,
}

## La recharge propre au sort, en secondes, avant `cast_speed`. Sans effet pour
## une compétence à la cadence de l'arme.
@export var recharge: float = 0.0

## Combien de projectiles part d'un lancer, et sur quel écart total en degrés.
## Un seul et zéro : le trait droit. Trois sur vingt-deux degrés : la salve. Huit
## sur trois cent soixante : la nova.
##
## Deux nombres plutôt qu'une forme nommée par compétence : ils décrivent ce que
## le lanceur doit faire, et la prochaine compétence en éventail ne demandera pas
## une branche de plus dans le joueur.
@export var projectiles: int = 1
@export var dispersion_en_degres: float = 0.0

## En pixels par seconde. Sur la compétence et non sur la scène du tir : deux
## compétences qui partagent `player_bolt.tscn` auraient sinon forcément la même
## vitesse, et aucun modificateur ne pourrait l'atteindre.
##
## Zéro pour ce qui ne lance rien.
@export var vitesse_de_projectile: float = 0.0

## Ce que le lancer coûte à la réserve. Zéro pour un coup gratuit — c'est ce qui
## sépare le coup d'épée du sort, et c'est la raison d'être du mana.
@export var cout_en_mana: float = 0.0

## Les dégâts de base, **un nombre par point placé** : le premier de la liste est
## ce que donne le premier point. Sa longueur est donc le nombre de points que la
## case accepte, et personne n'a à l'écrire deux fois.
##
## Une table écrite à la main et non une formule, pour la raison qui a fait
## choisir des paliers écrits au jalon 5 : une courbe calculée oblige à relire du
## code pour savoir ce que vaut le troisième point, et interdit de donner un bond
## franc au dernier.
@export var degats_par_point: Array[float] = []

## Le champ de la fiche qui s'ajoute aux dégâts de base — `attack_damage` ou
## `spell_damage`. C'est ce terme qui garde vivants les affixes du jalon 5 :
## sans lui, « dégâts de sort » et l'implicite du grimoire ne toucheraient aucune
## compétence, et la moitié de la réserve deviendrait morte le jour du jalon 6.
@export var stat_de_base: String = ""

## L'attribut qui la fait monter, et de combien par point de cet attribut.
##
## **Vide pour une compétence qui ne monte avec rien.** C'est le cas des deux
## attaques de départ : la force et l'intelligence nourrissent déjà
## `attack_damage` et la réserve par `apply_attributes()`, et les faire compter
## une seconde fois ici les paierait deux fois.
@export var attribut: String = ""
@export var pourcentage_par_attribut: float = 0.0

## Le niveau de manuel à partir duquel la case accepte son premier point. Zéro
## pour ce qui ne vient d'aucun manuel.
@export var niveau_de_manuel_requis: int = 0

## L'image de la compétence, ou null. **Null est un état normal** : la barre
## retombe alors sur un disque de la couleur de sa nature, et une compétence sans
## icône reste jouable.
##
## Une image fournie et non dessinée par la forge : contrairement à un objet, dont
## l'icône *est* le dessin qui le pose dans la main d'un personnage, un sort n'a
## pas de forme que le jeu connaisse déjà. Elle est ramenée à la grille par
## `IconeDeCompetence`, qui est le seul endroit qui sait quelle taille elle doit
## faire.
@export var icone: Texture2D


## L'intervalle entre deux lancers, cadence comprise. Ici et non chez le joueur :
## c'est la compétence qui sait si elle suit l'arme ou l'incantation, et lui
## demander évite au lanceur un `if` par règle.
##
## Borné en bas comme `CharacterStats.attack_interval()` : une vitesse nulle ou
## négative — un affixe mal réglé — figerait le lanceur pour toujours au lieu de
## le ralentir.
func intervalle(stats: CharacterStats) -> float:
	if stats == null:
		return recharge
	if cadence == Cadence.ARME:
		return stats.attack_interval()
	return recharge / maxf(stats.cast_speed, 0.1)


## Combien de points cette compétence accepte. Déduit de la table plutôt que
## saisi à côté d'elle : deux nombres qui doivent s'accorder finissent par
## diverger, et c'est la case qui refuserait un point sans dire pourquoi.
func points_max() -> int:
	return degats_par_point.size()


## Les mots-clés portés, dans l'ordre de la liste : ceux qui sont déclarés, plus
## ceux que donnent la cadence et la nature.
##
## Une fonction et non un champ rempli au chargement : ce qui se déduit n'est
## écrit nulle part, donc ne peut pas diverger de la nature qu'il traduit.
func mots_cles() -> PackedStringArray:
	var deduits := [MOT_CLE_DE_CADENCE.get(cadence, ""), MOT_CLE_DE_NATURE.get(nature, "")]
	var out := PackedStringArray()
	for id: String in MotsCles.LIBELLES:
		if deduits.has(id) or mots_cles_declares.has(id):
			out.append(id)
	return out


func porte(mot_cle: String) -> bool:
	return mots_cles().has(mot_cle)


## « Projectile · Foudre · Sort » : la ligne que le joueur lit sur la fiche.
func libelle_des_mots_cles() -> String:
	var noms := PackedStringArray()
	for id in mots_cles():
		noms.append(MotsCles.libelle(id))
	return " · ".join(noms)


## Les dégâts d'un lancer, à ce nombre de points et avec cette fiche.
##
## **La seule formule du jalon**, et l'infobulle appellera celle-ci plutôt qu'une
## copie : deux calculs séparés divergent d'un arrondi, et c'est l'affichage qui
## passe alors pour un menteur. C'est la leçon de `StatMod.value_label()`, extraite
## à l'étape 7 du jalon 5 pour exactement cette raison.
##
## Zéro point, zéro dégât : une compétence non apprise n'est pas une compétence
## faible, elle n'existe pas.
func degats(points: int, stats: CharacterStats) -> float:
	if points <= 0 or degats_par_point.is_empty() or stats == null:
		return 0.0
	# Au-delà du dernier point, le dernier : un appelant qui demande plus que ce
	# que la table contient doit obtenir le meilleur, pas une erreur d'indice.
	var i := mini(points, points_max()) - 1
	var base := degats_par_point[i] + _champ(stats, stat_de_base)
	return base * (1.0 + pourcentage_par_attribut * 0.01 * _champ(stats, attribut))


## Ce qu'un lancer fait, à ce nombre de points, avec cette fiche et ces
## modificateurs : les nombres de la compétence, puis ceux des modificateurs dont
## elle porte le mot-clé.
##
## **Le seul calcul.** Le lancer et la fiche du manuel passent tous deux par ici,
## sinon la fiche finirait par annoncer un trait de moins que ce qui part.
##
## Un modificateur qui vise un nombre absent de `StatsDeCompetence.LABELS` est
## ignoré plutôt que de planter, comme un champ inconnu dans `_champ()` : c'est un
## test de la réserve d'affixes qui doit l'attraper, pas un combat.
func resoudre(points: int, stats: CharacterStats, mods: Array = []) -> StatsDeCompetence:
	var r := StatsDeCompetence.new()
	r.degats = degats(points, stats)
	r.projectiles = float(projectiles)
	r.dispersion_en_degres = dispersion_en_degres
	r.vitesse_de_projectile = vitesse_de_projectile
	r.cout_en_mana = cout_en_mana
	r.intervalle = intervalle(stats)

	var portes := mots_cles()
	var retenus: Array[StatMod] = []
	for m: StatMod in mods:
		if portes.has(m.portee) and StatsDeCompetence.LABELS.has(m.stat):
			retenus.append(m)
	StatMod.appliquer(r, retenus)
	r.conclure()
	return r


## Un champ de la fiche, ou zéro quand il n'est pas nommé.
##
## Un nom inconnu rend zéro plutôt que de planter : une faute de frappe dans un
## `.tres` doit être attrapée par un test au démarrage de la campagne, jamais par
## un lancer au milieu d'un combat.
static func _champ(stats: CharacterStats, nom: String) -> float:
	if nom.is_empty():
		return 0.0
	var valeur: Variant = stats.get(nom)
	return 0.0 if valeur == null else float(valeur)
