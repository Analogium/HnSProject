class_name Progression

## La courbe d'expérience, écrite **une fois** pour le personnage et les manuels,
## chacun avec ses constantes. Une feuille.


## Ce qu'il en coûte pour quitter ce niveau-là. Le personnage l'appelle pour son
## palier suivant, le manuel pour additionner les siens.
static func cout_du_niveau(niveau: int, base: float, puissance: float) -> int:
	return roundi(base * pow(float(maxi(niveau, 1)), puissance))


## Le niveau atteint avec cette expérience **totale**. Le personnage retient
## l'expérience du niveau en cours, le manuel son total ; la courbe est la même.
static func niveau_atteint(
	experience: int, base: float, puissance: float, niveau_max: int
) -> int:
	return _parcourir(experience, base, puissance, niveau_max).x


## Ce qu'il reste avant le niveau suivant et ce qu'il coûte ; (0, 0) au maximum.
static func avancement(
	experience: int, base: float, puissance: float, niveau_max: int
) -> Vector2i:
	var atteint := _parcourir(experience, base, puissance, niveau_max)
	return Vector2i(atteint.y, atteint.z)


## Le parcours de la courbe, écrit une fois : niveau atteint (x), dépassement (y),
## coût du suivant (z). Borné par `niveau_max` contre une expérience aberrante.
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
