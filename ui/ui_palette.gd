class_name UiPalette

## Les couleurs communes aux panneaux du jeu : le cadre du sac, la fiche de
## personnage, l'écran de sélection.
##
## Ce qui est ici est ce que **plusieurs** panneaux emploient. Une couleur propre
## à un seul reste chez lui : le fond des cases du sac ou les boutons de la fiche
## n'ont rien à faire dans une palette partagée.

## Fond de panneau. L'opacité vaut pour une fenêtre posée sur le décor.
const BACK := Color(0.082, 0.075, 0.106, 0.97)
## Le même, rendu opaque. Un panneau qui couvre tout l'écran laisse sinon
## transparaître le bandeau de débogage qu'il est censé recouvrir — et les deux
## écrans plein cadre écrivaient chacun cette conversion.
const BACK_PLEIN := Color(BACK, 1.0)
## Fond d'infobulle. Plus sombre et plus opaque qu'un panneau : elle se pose
## **par-dessus** lui, et un fond trop clair y laisserait transparaître les
## lignes qu'elle vient justement expliquer.
const TIP_BACK := Color(0.055, 0.051, 0.075, 0.98)
const BORDER := Color(0.29, 0.27, 0.35)
## Les lignes d'aide, en bas des panneaux : présentes, jamais lues avant qu'on
## les cherche.
const HINT := Color(0.52, 0.50, 0.60)
## Les intitulés — nom d'un emplacement d'équipement, titre d'un groupe de
## statistiques. Plus sombres que le texte qu'ils annoncent.
const LABEL := Color(0.42, 0.40, 0.50)
## Le texte courant des panneaux dessinés : noms, valeurs, entrées de menu.
const TEXTE := Color(0.90, 0.88, 0.95)
## Le titre en tête d'une fenêtre : « SAC », « PERSONNAGE », « MANUELS ».
const TITRE := Color(0.80, 0.77, 0.86)
## Les points à placer : un gain en attente, pas un avertissement. La fiche de
## personnage et la page d'un manuel le disent au même endroit du regard.
const A_PLACER := Color(0.52, 0.88, 0.48)
