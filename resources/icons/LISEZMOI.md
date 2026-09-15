# Icônes de compétences

Une image par compétence. Elle est branchée sur le champ `icon` du `.tres` de la
compétence, dans `resources/skills/` — **pas** retrouvée par son nom de
fichier : un identifiant mal tapé donnerait une case vide sans que rien ne le
dise, là où un champ vide se voit dans l'inspecteur.

## Ce que le jeu en fait

`SkillIcon` la ramène à **24 × 24**, au plus proche voisin, puis la case
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

### La recette du jalon 11

Les icônes des manuels sortent de ComfyUI, **SDXL 1.0** (`sdXL_v10VAEFix`) avec le
LoRA **`pixel-art-xl-v1.1`** à pleine force, en 1024 × 1024 :

- **un gabarit de prompt partagé** — « pixel art, 16-bit rpg ability icon, *sujet*,
  centered, single subject, bold readable silhouette, high contrast, simple solid
  *fond* background, square game icon » — où seul le sujet change, et le fond
  suit la nature : violet pour la foudre, cramoisi pour le feu, bleu ardoise pour
  le physique ;
- **les mêmes réglages pour toutes** : `dpmpp_2m`, `karras`, 30 pas, CFG 6, et la
  graine 4242 — 777 pour les trois refaites avec un sujet plus direct (Chaîne
  d'éclairs, Frappe lourde, Boule de feu). C'est ce qui remplace la planche unique,
  que SDXL ne sait pas découper en neuf sujets distincts ;
- **la réduction à 24 px par moyenne de zone**, puis une palette ramenée à
  24 couleurs. Au plus proche voisin depuis 1024, chaque pixel est tiré au hasard
  dans un bloc de 42, et la trame devient du bruit.

L'image est **recadrée à 70 % au centre avant la réduction** : le sujet occupe
rarement plus que ce centre, et réduite entière, la tuile noyait sa silhouette
dans le fond. On génère trois images par compétence et on choisit sur une
planche où chacune est déjà réduite — juger une image de 1024 px ne dit rien de
ce qui restera à 24.

L'icône d'Éclair vif est antérieure et ne suit pas cette recette.

## À l'import

Ces images sont du pixel art : dans l'onglet Import de Godot, filtre **désactivé**
et compression **sans perte**. Un filtre linéaire lisse la trame, et une
compression VRAM y laisse des artefacts qui ne se voient qu'à l'agrandissement.

## Sans icône

Le champ vide est un état normal : la barre dessine alors un disque de la couleur
de la nature du sort. Une compétence sans image reste jouable et reconnaissable.
