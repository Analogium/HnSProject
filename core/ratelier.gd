class_name Ratelier
extends RefCounted

## Les manuels en cours d'étude. Trois emplacements, et **c'est le seul endroit
## où un manuel apprend** : celui qui dort dans le sac ne gagne rien.
##
## Trois, et pas « autant qu'on en ramasse » : c'est ce nombre qui fait du
## râtelier un choix plutôt qu'un rangement. Il vit sur une constante pour
## pouvoir bouger, jamais dans la mise en page d'un panneau.
##
## Le manuel posé ici **quitte le sac**, comme un plastron qu'on enfile. Trois
## livres de deux cases sur deux, c'est le quart du sac immobilisé à demeure ; et
## laisser un manuel à la fois rangé et étudié rendrait flou le seul endroit où
## il progresse.

const EMPLACEMENTS := 3

## Un Item par emplacement, ou null. L'Item et non le seul `Manuel` : c'est
## l'objet entier qu'on a ramassé, avec sa base, son niveau d'objet et son
## icône — le retirer doit le rendre au sac tel qu'il est entré.
var manuels: Array[Item] = []


func _init() -> void:
	manuels.resize(EMPLACEMENTS)


## Ce qui se pose ici : un objet qui porte un manuel, et rien d'autre.
static func accepte(item: Item) -> bool:
	return item != null and item.manuel != null


## Pose un manuel et rend celui qu'il remplace, ou null.
##
## **Rend l'objet lui-même quand il est refusé** — mauvais emplacement, ou objet
## qui n'est pas un manuel — pour que l'appelant ne le perde jamais. C'est la
## règle de `Player.equip()`, et pour la même raison.
func poser(index: int, item: Item) -> Item:
	if item == null:
		return null
	if index < 0 or index >= EMPLACEMENTS or not accepte(item):
		return item
	var ancien := manuels[index]
	manuels[index] = item
	return ancien


func retirer(index: int) -> Item:
	if index < 0 or index >= EMPLACEMENTS:
		return null
	var parti := manuels[index]
	manuels[index] = null
	return parti


func a(index: int) -> Item:
	return manuels[index] if index >= 0 and index < EMPLACEMENTS else null


## Les manuels réellement posés, sans les trous. C'est cette liste que
## l'expérience parcourt à chaque mort d'ennemi.
func equipes() -> Array[Item]:
	var out: Array[Item] = []
	for item in manuels:
		if item != null:
			out.append(item)
	return out


func vide() -> bool:
	return equipes().is_empty()
