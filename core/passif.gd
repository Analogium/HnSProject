class_name Passif
extends Resource

## Une case de manuel qu'on ne lance pas : ses points agissent tant que le livre
## est au râtelier, et rien de plus n'est à faire.
##
## Une classe à part et non une compétence sans dégâts : une compétence porte une
## cadence, un coût, un nombre de projectiles et une table de dégâts dont aucun
## n'aurait de sens ici, et c'est `Player.lancer()` qui finirait par devoir
## deviner ce qu'il ne peut pas lancer.
##
## Ses lignes entrent dans le **même tri** que celles des objets portés
## (`Player.recompute_stats`) : sans portée sur la fiche du personnage, avec
## portée sur les compétences qui ont le mot-clé. C'est ce qui évite d'écrire une
## seconde fois la règle qui interdit à un bonus de compter deux fois.

## **Définitif** : il part dans les sauvegardes, dans le dictionnaire de points du
## manuel (invariant 1).
@export var id: String = ""
@export var nom: String = ""

## Comme celle d'une compétence, elle peut manquer : la case garde alors son fond
## et son compte de points.
@export var icone: Texture2D

@export var niveau_de_manuel_requis: int = 0

## Un champ, contrairement à `Competence.points_max()` qui se déduit de sa table
## de dégâts : un passif n'a pas de table d'où le tirer, et ses lignes disent une
## valeur par point sans dire combien de points la case accepte.
@export var points_max: int = 1

@export var lignes: Array[LigneDeTalent] = []


func nom_affiche() -> String:
	return Textes.t(nom)


func mods(points: int) -> Array[StatMod]:
	var out: Array[StatMod] = []
	if points <= 0:
		return out
	for ligne in lignes:
		var m := ligne.modificateur(points)
		if m != null:
			out.append(m)
	return out
