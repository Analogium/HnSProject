# Icônes de compétences

Une image par compétence. Elle est branchée sur le champ `icone` du `.tres` de la
compétence, dans `resources/competences/` — **pas** retrouvée par son nom de
fichier : un identifiant mal tapé donnerait une case vide sans que rien ne le
dise, là où un champ vide se voit dans l'inspecteur.

## Ce que le jeu en fait

`IconeDeCompetence` la ramène à **24 × 24**, au plus proche voisin, puis la case
l'agrandit d'un facteur **entier**. Une image plus petite que 24 est laissée
telle quelle ; une plus grande est réduite.

Les deux tailles d'affichage sont **26** (barre de compétences) et **34** (page
de manuel), en pixels logiques — le jeu tourne en 640 × 360 étiré. Une icône de
24 tient donc à l'échelle 1 dans les deux.

## Produire les images

Dessinées, générées, découpées d'une planche : le tuyau ne s'en soucie pas. Deux
choses comptent, et elles ne sont pas négociables à cette taille :

**La silhouette avant le détail.** Ce qui se lit dans 24 pixels, c'est une forme.
Un détail de deux pixels disparaît — c'est ce qui a coûté trois brouillons à
l'icône du manuel, et ce qui a fait rejeter un éclair aminci qui se lisait comme
une pointe de flèche.

**La cohérence entre les icônes.** Si elles sont générées, les produire **en une
seule planche** plutôt qu'une par une : quatre générations séparées donnent
quatre éclairages et quatre palettes, et l'ensemble se lit comme un assemblage
disparate. Le reste du jeu sort d'une seule forge, avec une seule direction de
lumière — en haut à gauche, voir `PixelCanvas.LIGHT`.

## À l'import

Ces images sont du pixel art : dans l'onglet Import de Godot, filtre **désactivé**
et compression **sans perte**. Un filtre linéaire lisse la trame, et une
compression VRAM y laisse des artefacts qui ne se voient qu'à l'agrandissement.

## Sans icône

Le champ vide est un état normal : la barre dessine alors un disque de la couleur
de la nature du sort. Une compétence sans image reste jouable et reconnaissable.
