extends Node

## Les réglages du joueur, distincts de Game qui porte l'état de la partie.
##
## Un signal plutôt qu'une lecture directe : avec trois cents barres de vie à
## l'écran, faire interroger le réglage par chacune à chaque image se paierait
## pour une valeur qui change une fois par heure.

signal changed

## Barres de vie au-dessus des acteurs, ennemis comme alliés.
var show_health_bars := true:
	set(value):
		if value == show_health_bars:
			return
		show_health_bars = value
		changed.emit()

## Noms des affixes empilés au-dessus des ennemis qui en portent.
var show_affix_names := true:
	set(value):
		if value == show_affix_names:
			return
		show_affix_names = value
		changed.emit()
