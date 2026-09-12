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
	DamageType.Kind.FIRE: MotsCles.FEU,
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

## L'attribut qui la fait monter, et de combien par point de cet attribut. Il
## multiplie aussi ce que les objets ajoutent — voir `resoudre()`.
##
## **Vide pour une compétence qui ne monte avec rien.** C'est le cas des deux
## attaques de départ : la force ajoute déjà ses dégâts physiques aux attaques,
## l'intelligence nourrit la réserve, et les faire compter une seconde fois ici
## les paierait deux fois.
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


## Le nom tel que le joueur le lit. `nom` est la clé française écrite dans le
## `.tres` : une interface qui l'afficherait directement resterait en français.
func nom_affiche() -> String:
	return Textes.t(nom)


## Combien de points cette compétence accepte. Déduit de la table plutôt que
## saisi à côté d'elle : deux nombres qui doivent s'accorder finissent par
## diverger, et c'est la case qui refuserait un point sans dire pourquoi.
func points_max() -> int:
	return degats_par_point.size()


## Les mots-clés portés : ceux qui sont déclarés, plus ceux que donnent la
## cadence et la nature. **Ceux d'un nœud d'arbre n'y sont pas** — ils
## appartiennent à un lancer et non à la fiche, et `resoudre()` les ajoute.
##
## Une fonction et non un champ rempli au chargement : ce qui se déduit n'est
## écrit nulle part, donc ne peut pas diverger de la nature qu'il traduit.
func mots_cles() -> PackedStringArray:
	return _mots_cles(PackedStringArray())


## Les mots-clés portés, ceux-ci en plus. L'ordre de lecture est celui de
## `MotsCles` et de nulle part ailleurs.
func _mots_cles(ajoutes: PackedStringArray) -> PackedStringArray:
	var tous := PackedStringArray([
		MOT_CLE_DE_CADENCE.get(cadence, ""), MOT_CLE_DE_NATURE.get(nature, "")
	])
	tous.append_array(mots_cles_declares)
	tous.append_array(ajoutes)
	return MotsCles.ordonner(tous)


func porte(mot_cle: String) -> bool:
	return mots_cles().has(mot_cle)


## « Projectile · Foudre · Sort » : les mots-clés **de la compétence**, tels que
## le catalogue les décrit. Ce que la page du manuel affiche est la ligne du geste
## résolu (`StatsDeCompetence.libelle_des_mots_cles`), qui porte en plus ceux d'un
## nœud d'arbre investi.
func libelle_des_mots_cles() -> String:
	return MotsCles.ligne(mots_cles())


## Les dégâts propres de la compétence, sans objet : la ligne de la table fois
## l'attribut. **Aucun lancer ne passe par ici** — `resoudre()` part des deux mêmes
## fonctions et y ajoute ce que portent les objets — mais les tests s'en servent de
## témoin, pour vérifier la table et l'attribut sans passer par la résolution.
##
## Zéro point, zéro dégât : une compétence non apprise n'est pas une compétence
## faible, elle n'existe pas.
func degats(points: int, stats: CharacterStats) -> float:
	if stats == null:
		return 0.0
	return _base(points) * facteur_d_attribut(stats)


## Les dégâts propres, avant l'attribut : la ligne de la table.
func _base(points: int) -> float:
	if points <= 0 or degats_par_point.is_empty():
		return 0.0
	# Au-delà du dernier point, le dernier : un appelant qui demande plus que ce
	# que la table contient doit obtenir le meilleur, pas une erreur d'indice.
	return degats_par_point[mini(points, points_max()) - 1]


## Ce que l'attribut rapporte, en multiplicateur : 1,4 pour dix points à 4 %.
func facteur_d_attribut(stats: CharacterStats) -> float:
	if stats == null:
		return 1.0
	return 1.0 + pourcentage_par_attribut * 0.01 * _champ(stats, attribut)


## Ce qu'un lancer fait, à ce nombre de points, avec cette fiche et ces
## modificateurs : les nombres de la compétence, puis ceux des modificateurs dont
## elle porte le mot-clé.
##
## **Le seul calcul.** Le lancer et la fiche du manuel passent tous deux par ici,
## sinon la fiche finirait par annoncer un trait de moins que ce qui part.
##
## Un modificateur qui vise un nombre qu'on ne sait pas modifier est ignoré plutôt
## que de planter, comme un champ inconnu dans `_champ()` : c'est un test de la
## réserve d'affixes qui doit l'attraper, pas un combat.
##
## **L'ordre des dégâts** : les dégâts propres, puis les fourchettes ajoutées,
## puis la conversion, puis l'attribut, puis les pourcentages. L'attribut
## multiplie ce que les objets ajoutent, et pas seulement la table : les dégâts
## de sort d'un objet passaient déjà par l'intelligence, et un personnage relu
## d'une ancienne sauvegarde ne doit pas frapper moins fort parce que ses lignes
## ont changé de forme.
##
## **Mesurée** : 8,1 µs par appel nue, 12,7 µs avec trois lignes d'objet, 21,6 µs
## avec en plus deux nœuds investis. C'est ce qui permet à la page du manuel de la
## rappeler à chaque redessin plutôt que de garder un résultat qui périmerait au
## premier changement d'équipement.
##
## **Les talents ne sont pas filtrés** : un nœud ne vise que sa propre
## compétence, et c'est tout ce qui le distingue d'un modificateur d'objet. Ses
## mots-clés à lui, en revanche, sont posés **avant** le filtre — c'est ce qui
## fait qu'un nœud de conversion peut rendre un affixe de feu mordant sur un sort
## de foudre.
func resoudre(
	points: int, stats: CharacterStats, mods: Array = [], talents: Array = []
) -> StatsDeCompetence:
	var r := StatsDeCompetence.new()
	r.nature = nature
	r.poser_la_base(nature, _base(points))
	r.projectiles = float(projectiles)
	r.dispersion_en_degres = dispersion_en_degres
	r.vitesse_de_projectile = vitesse_de_projectile
	r.cout_en_mana = cout_en_mana
	r.intervalle = intervalle(stats)

	var donnes := PackedStringArray()
	for t: TalentInvesti in talents:
		donnes.append_array(t.noeud.mots_cles_ajoutes)
	var portes := _mots_cles(donnes)
	r.mots_cles = portes

	var champs: Array[StatMod] = []
	var pourcents_de_degats: Array[StatMod] = []
	for m: StatMod in mods:
		if portes.has(m.portee):
			_ranger(r, m, champs, pourcents_de_degats)
	for t: TalentInvesti in talents:
		for m in t.mods():
			_ranger(r, m, champs, pourcents_de_degats)

	StatMod.appliquer(r, champs)
	for t: TalentInvesti in talents:
		r.convertir(nature, t.noeud.convertit_vers, t.conversion())
	r.appliquer_l_attribut(facteur_d_attribut(stats))
	for m in pourcents_de_degats:
		r.accroitre(m.value)
	r.conclure()
	return r


## Où va un modificateur retenu : dans les dégâts ajoutés de sa nature, dans les
## pourcentages qu'on garde pour la fin, ou dans les champs nommés.
##
## Une seule fonction pour les lignes d'objet et celles des talents : deux tris
## finiraient par ne pas traiter « +12 % dégâts » de la même façon selon qu'il
## vient d'un anneau ou d'un nœud.
static func _ranger(
	r: StatsDeCompetence, m: StatMod, champs: Array[StatMod], pourcents: Array[StatMod]
) -> void:
	var ajoutee := StatsDeCompetence.nature_ajoutee(m.stat)
	if ajoutee >= 0 and m.mode == StatMod.Mode.FLAT:
		r.ajouter(ajoutee, m.value, m.value_max)
	elif m.stat == StatsDeCompetence.DEGATS and m.mode == StatMod.Mode.PERCENT:
		pourcents.append(m)
	elif m.stat != StatsDeCompetence.DEGATS and StatsDeCompetence.LABELS.has(m.stat):
		champs.append(m)


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
