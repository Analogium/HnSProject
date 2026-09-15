class_name Tirage

## Le tirage pondéré. Une feuille : dans `ItemAffixPool`, un `ItemAffix` qui
## l'appellerait refermerait un cycle de dépendances.


## L'index tiré, ou -1 s'il n'y a rien à tirer — un cas de jeu, à ne pas réessayer.
## Un poids négatif compte pour zéro. **Exactement un tirage**, aucun s'il n'y a rien
## à tirer (invariant 3).
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
