class_name SpawnSeed

## La graine de ce qui se déduit du **lieu** d'apparition et non d'un tirage : la
## silhouette d'un ennemi, ses affixes, le sens de rotation d'un caster (invariant 3).
##
## Trois endroits écrivaient la même expression ; il suffisait que l'un arrondisse
## autrement pour qu'une graine de zone cesse de redonner le même combat, et rien
## ne l'aurait dit. Une feuille : elle ne nomme personne.


## `salt` décorrèle deux tirages du même point — sans lui, la variante d'un corps
## et son affixe seraient liés, et un Colossal aurait toujours la même silhouette.
## Le point du plan arrondi en `Vector2i`, comme en 2D : les graines n'ont pas bougé.
static func at(point: Vector3, salt := 0) -> int:
	return absi(hash(Vector2i(roundi(point.x), roundi(point.z)))) ^ salt
