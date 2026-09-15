class_name WeightedRoll

## Le tirage pondéré. Une feuille : dans `ItemAffixPool`, un `ItemAffix` qui
## l'appellerait refermerait un cycle de dépendances.


## L'index tiré, ou -1 s'il n'y a rien à tirer — un cas de jeu, à ne pas réessayer.
## Un poids négatif compte pour zéro. **Exactement un tirage**, aucun s'il n'y a rien
## à tirer (invariant 3).
static func weighted(rng: RandomNumberGenerator, weight: Array) -> int:
	var total := 0
	for p in weight:
		total += maxi(int(p), 0)
	if total <= 0:
		return -1

	var rest := rng.randi_range(1, total)
	for i in weight.size():
		rest -= maxi(int(weight[i]), 0)
		if rest <= 0:
			return i
	return -1
