class_name Tirage

## Le tirage pondéré, et rien d'autre.
##
## Trois endroits du système d'objets l'écrivaient à la main : la réserve
## d'affixes, l'échelle de paliers d'un affixe, et le nombre d'affixes d'un objet
## neuf. Trois fois la même somme, le même `randi_range(1, total)` et la même
## soustraction en cascade — et cette soustraction est exactement le genre de
## boucle dont l'erreur d'une unité ne se voit pas : elle ne plante pas, elle
## **biaise**, et un biais de tirage ne se remarque qu'après des centaines de
## chutes, quand plus personne ne pense à le chercher là.
##
## Une classe à part et non une méthode d'ItemAffixPool : la réserve précharge
## les `.tres` d'ItemAffix, donc un ItemAffix qui appellerait la réserve
## refermerait le cycle de dépendances que GDScript refuse. Ici, rien ne dépend
## de rien — c'est une feuille de l'arbre, comme DamageType.


## L'index tiré dans `poids`, ou -1 quand il n'y a rien à tirer : liste vide, ou
## que des poids nuls. Le -1 n'est pas une erreur de programmation mais un cas de
## jeu ordinaire — un affixe dont aucun palier n'est ouvert, une réserve épuisée
## — et l'appelant qui le reçoit ne doit pas réessayer.
##
## Les poids négatifs comptent pour zéro plutôt que de retrancher à leurs
## voisins. Un poids négatif est une faute de saisie dans un `.tres` ; la seule
## chose à ne pas faire est de la laisser fausser le reste de la table en
## silence.
##
## **Exactement un nombre tiré, quel que soit le résultat** — et aucun quand il
## n'y a rien à tirer. Le hasard de ce projet est reproductible à partir d'une
## graine : une fonction qui consommerait tantôt un tirage tantôt deux décalerait
## tout ce qui vient après elle.
static func pondere(rng: RandomNumberGenerator, poids: Array) -> int:
	var total := 0
	for p in poids:
		total += maxi(int(p), 0)
	if total <= 0:
		return -1

	var reste := rng.randi_range(1, total)
	for i in poids.size():
		reste -= maxi(int(poids[i]), 0)
		if reste <= 0:
			return i
	return -1
