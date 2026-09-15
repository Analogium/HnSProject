class_name Progression

## La courbe d'expérience, écrite **une fois** pour le personnage et les manuels,
## chacun avec ses constantes. Une feuille.


## Ce qu'il en coûte pour quitter ce niveau-là. Le personnage l'appelle pour son
## palier suivant, le manuel pour additionner les siens.
static func level_cost(level: int, base: float, power: float) -> int:
	return roundi(base * pow(float(maxi(level, 1)), power))


## Le niveau atteint avec cette expérience **totale**. Le personnage retient
## l'expérience du niveau en cours, le manuel son total ; la courbe est la même.
static func reached_level(
	experience: int, base: float, power: float, max_level: int
) -> int:
	return _walk(experience, base, power, max_level).x


## Ce qu'il reste avant le niveau suivant et ce qu'il coûte ; (0, 0) au maximum.
static func progress(
	experience: int, base: float, power: float, max_level: int
) -> Vector2i:
	var reached := _walk(experience, base, power, max_level)
	return Vector2i(reached.y, reached.z)


## Le parcours de la courbe, écrit une fois : niveau atteint (x), dépassement (y),
## coût du suivant (z). Borné par `max_level` contre une expérience aberrante.
static func _walk(
	experience: int, base: float, power: float, max_level: int
) -> Vector3i:
	var level := 1
	var rest := maxi(experience, 0)
	while level < max_level:
		var cost := level_cost(level, base, power)
		if rest < cost:
			return Vector3i(level, rest, cost)
		rest -= cost
		level += 1
	return Vector3i(max_level, 0, 0)
