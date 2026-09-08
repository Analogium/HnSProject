class_name AffixPool

## Le tirage des affixes et la règle de couleur. Séparé d'Enemy : un ennemi n'a
## pas à connaître le catalogue, il reçoit ce qu'on lui donne.

const ALL := [
	preload("res://resources/affixes/colossal.tres"),
	preload("res://resources/affixes/veloce.tres"),
	preload("res://resources/affixes/brutal.tres"),
	preload("res://resources/affixes/blinde.tres"),
	preload("res://resources/affixes/vorace.tres"),
]

## Deux affixes doivent rester rares : c'est l'exception qui fait ralentir le
## joueur devant un paquet, et une exception fréquente n'en est plus une.
const CHANCE_ONE := 0.18
const CHANCE_TWO := 0.04

## L'or de l'élite, la même couleur que les coups critiques : dans les deux cas
## elle veut dire « ça compte plus que d'habitude ».
const ELITE_TINT := Color(0.980, 0.800, 0.302)

## Opacité du liseré. Pleine : c'est un pixel vide qu'on colore, et un liseré
## translucide se perd sur un sol clair.
const RIM_AMOUNT := 1.0
## L'élite porte un liseré de deux pixels : il doit se repérer de plus loin, et
## l'épaisseur se lit à une distance où la couleur ne se distingue plus.
const ELITE_WIDTH := 2.0
const RIM_WIDTH := 1.0

## Paires qui s'annulent : Colossal ralentit et gonfle, Véloce accélère et
## amincit. Ensemble ils donnent un ennemi ordinaire de couleur dorée, ce qui
## ment au joueur.
const INCOMPATIBLE := {
	"colossal": "veloce",
	"veloce": "colossal",
}


## rng doit être propre à la zone. Surtout pas Game.rng : une même graine doit
## redonner exactement les mêmes ennemis affixés.
static func roll(rng: RandomNumberGenerator) -> Array[Affix]:
	var out: Array[Affix] = []
	var draw := rng.randf()
	if draw >= CHANCE_ONE + CHANCE_TWO:
		return out

	out.append(ALL[rng.randi() % ALL.size()])
	if draw >= CHANCE_TWO:
		return out

	# Deuxième affixe : on retire d'abord le premier et son incompatible, sinon
	# une boucle de rejet rendrait le tirage dépendant du nombre d'essais et
	# casserait la reproductibilité.
	var pool: Array[Affix] = []
	for a in ALL:
		var affix: Affix = a
		if affix.id == out[0].id or affix.id == INCOMPATIBLE.get(out[0].id, ""):
			continue
		pool.append(affix)
	if not pool.is_empty():
		out.append(pool[rng.randi() % pool.size()])
	return out


## Aucun affixe : aucun liseré. Un ennemi ordinaire doit rester exactement tel
## que la forge l'a dessiné, sinon la couleur cesse de vouloir dire quelque chose.
static func tint_of(affixes: Array[Affix]) -> Color:
	if affixes.is_empty():
		return Color.WHITE
	if affixes.size() >= 2:
		return ELITE_TINT
	return affixes[0].tint


static func rim_amount_of(affixes: Array[Affix]) -> float:
	return 0.0 if affixes.is_empty() else RIM_AMOUNT


static func rim_width_of(affixes: Array[Affix]) -> float:
	return ELITE_WIDTH if affixes.size() >= 2 else RIM_WIDTH
