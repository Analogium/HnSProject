class_name Progression

## La courbe d'expérience, écrite **une fois**. Le personnage et les manuels
## montent sur la même forme — un coût qui croît en puissance du niveau — avec
## leurs propres constantes.
##
## Une classe à part plutôt qu'une méthode du joueur : le jour où l'une des deux
## courbes se réglera, on veut choisir de ne pas toucher l'autre, pas découvrir
## qu'on l'a fait sans le savoir. Et deux exponentielles écrites côte à côte
## finissent par diverger d'un arrondi.
##
## Une feuille : elle ne dépend de rien, comme `Tirage` et `DamageType`.


## Ce qu'il en coûte pour quitter ce niveau-là. Le personnage l'appelle pour son
## palier suivant, le manuel pour additionner les siens.
static func cout_du_niveau(niveau: int, base: float, puissance: float) -> int:
	return roundi(base * pow(float(maxi(niveau, 1)), puissance))


## Le niveau atteint avec cette expérience **totale**.
##
## Deux modèles cohabitent dans le jeu, et c'est assumé : le personnage retient
## l'expérience de son niveau en cours et la défalque à chaque montée — c'est ce
## que sa barre affiche — là où le manuel retient son total, parce que son niveau
## se déduit et ne s'écrit pas. La courbe, elle, est la même.
static func niveau_atteint(
	experience: int, base: float, puissance: float, niveau_max: int
) -> int:
	return _parcourir(experience, base, puissance, niveau_max).x


## Ce qu'il reste à gagner avant le niveau suivant, et ce que ce niveau coûte en
## tout : de quoi dessiner une barre sans la recalculer à l'écran.
##
## Rend (0, 0) au niveau maximum : une jauge pleine qui ne bougera plus se dessine
## mieux vide de promesse qu'avec un dénominateur inventé.
static func avancement(
	experience: int, base: float, puissance: float, niveau_max: int
) -> Vector2i:
	var atteint := _parcourir(experience, base, puissance, niveau_max)
	return Vector2i(atteint.y, atteint.z)


## Le parcours de la courbe, **écrit une fois** : le niveau atteint en `x`, ce qui
## dépasse son seuil en `y`, et ce que le niveau suivant coûte en `z`. Les deux
## fonctions publiques n'en gardent chacune qu'une part.
##
## Elles portaient la même boucle chacune de son côté. Deux escaliers montés en
## parallèle finissent par diverger d'un arrondi, et ça ne se voit qu'à l'écran :
## une barre pleine sous un niveau qui n'a pas bougé, ou l'inverse.
##
## Bornée par `niveau_max` : sans plafond, une expérience aberrante lue dans un
## fichier ferait tourner cette boucle longtemps avant de rendre un nombre qui ne
## veut rien dire. Au plafond, le coût vaut zéro — il n'y a plus rien à annoncer.
static func _parcourir(
	experience: int, base: float, puissance: float, niveau_max: int
) -> Vector3i:
	var niveau := 1
	var reste := maxi(experience, 0)
	while niveau < niveau_max:
		var cout := cout_du_niveau(niveau, base, puissance)
		if reste < cout:
			return Vector3i(niveau, reste, cout)
		reste -= cout
		niveau += 1
	return Vector3i(niveau_max, 0, 0)
