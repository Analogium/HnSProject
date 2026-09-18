class_name SkillBuff
extends Resource

## Ce qu'un lancer pose **sur son lanceur** : un nom, et les lignes qu'il donne tant
## qu'il tient. Les lignes sont celles d'un passif, au mot près.
##
## Une ressource et non un champ de `Skill`, parce qu'une compétence peut en poser
## plusieurs et que **chacun se lit à part** sur la fiche, sous son nom — c'est ce qui
## distingue « ce que la compétence fait » de « ce qu'elle laisse ».
##
## Tous les buffs d'un lancer s'allument et s'éteignent ensemble : un seul nœud `Buff`
## les porte, et le joueur les range sous l'identifiant de la compétence.

## Unique dans le jeu, comme celui d'un passif — mais **jamais écrit sur le disque** :
## un buff ne se sauvegarde pas, il se rallume.
@export var id: String = ""
@export var name: String = ""
@export var lines: Array[TalentLine] = []


func displayed_name() -> String:
	return Texts.t(name)


## Ce que ce buff donne à ce nombre de points placés.
func mods(points: int) -> Array[StatMod]:
	return TalentLine.modifiers(lines, points)
