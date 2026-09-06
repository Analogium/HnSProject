class_name UiPalette

## Les couleurs communes aux panneaux du jeu : le cadre du sac, la fiche de
## personnage, l'écran de sélection.
##
## Elles vivaient dans InventoryPanel, et la fiche allait les y chercher —
## `const BACK := InventoryPanel.BACK`. Un commentaire y annonçait le seuil :
## « le jour où un troisième panneau arrive, cette palette méritera son propre
## fichier ». Le troisième est là. Un écran plein cadre n'a aucune raison de
## demander ses couleurs au panneau du sac, et deux gris différents pour le même
## rôle se lisent comme un défaut d'affichage.
##
## Ce qui est ici est ce que **plusieurs** panneaux emploient. Une couleur
## propre à un seul reste chez lui : le fond des cases du sac ou le vert des
## points à placer n'ont rien à faire dans une palette partagée.

## Fond de panneau. L'opacité vaut pour une fenêtre posée sur le décor ; un
## panneau qui couvre tout l'écran la rend opaque à son dessin.
const BACK := Color(0.082, 0.075, 0.106, 0.97)
const BORDER := Color(0.29, 0.27, 0.35)
## Les lignes d'aide, en bas des panneaux : présentes, jamais lues avant qu'on
## les cherche.
const HINT := Color(0.52, 0.50, 0.60)
## Les intitulés — nom d'un emplacement d'équipement, titre d'un groupe de
## statistiques. Plus sombres que le texte qu'ils annoncent.
const LABEL := Color(0.42, 0.40, 0.50)
