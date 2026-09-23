# Personnages joueurs

Un personnage jouable, d'un prompt jusqu'au jeu. Le tuyau : `tools/character_forge.py`,
avec ComfyUI sur l'hôte Windows (voir `resources/icons/LISEZMOI.md` pour le joindre
depuis WSL). La sorcière du jalon 25 en est le premier exemple : `witch.json` et
`witch/`.

## Ce que le jeu en fait

`art/characters/<id>.png` porte en rangée 0 **trois poses fixes** — face, profil
(tourné vers la droite), dos — dans des cases de `frame` pixels, pieds sur la rangée
`feet` ; puis une rangée par geste généré et par vue (marche, 4 images ; attaque, 3).
`art/characters/<id>.json` donne les repères de chaque vue et, par geste, la rangée de
chaque vue et **la main armée de chaque image**. `SpriteForge._draw_sheet()` joue les
gestes tels quels et fait respirer la pose au repos. L'arme n'est **jamais** dans la
planche : la forge la pose à la main, et elle suit l'équipement.

Une classe se déclare dans `Character.CLASSES` (l'archétype, le nom affiché), et son
nom se traduit dans `i18n/en.po`.

## Les étapes

Chacune dépose une planche sur le Bureau ; on choisit, puis la suivante repart du
choix.

1. **Concept** — `tools/character_forge.py concept <id>` : le prompt de
   `concept.prompt`, une image par graine de `concept.seeds`. Puis
   `keep <id> concept <graine>`. Une image faite ailleurs (Leonardo, un dessin)
   se dépose directement en `tools/characters/<id>/concept.png`.
2. **Vues** — `views <id>` : face, profil et dos, une ligne par graine de
   `views.seeds`. IPAdapter tient l'identité du concept, OpenPose impose la vue
   par des squelettes chibi écrits dans l'outil. Le prompt de `views.prompt`
   décrit le personnage **mains vides**. Puis `keep <id> views <graine>`.
3. **Gestes** — `anim <id>` : la marche et l'attaque, chaque cycle **en une seule
   image** (des squelettes côte à côte), pour chaque graine de `anim.seeds`, le
   personnage décrit par `anim.who`. Un GIF par geste et par graine sur le Bureau,
   les trois vues côte à côte, la main armée marquée d'un point jaune. Puis
   `keep <id> walk all <graine>` (ou une vue : `down`, `side`, `up`).
4. **Planche** — `build <id>` : détourage, ombre générée retirée, réduction à
   `height` pixels, recolorations et retouches, contour du jeu. Écrit
   `art/characters/<id>.png` et `.json`, et `hns-<id>-planche.png` sur le Bureau.
   `build` ne demande pas ComfyUI : les images retenues sont dans
   `tools/characters/<id>/`.
5. **En jeu** — capture réelle, fenêtrée (skill `/dessiner-un-effet`, §5).

## Ce qui se règle à la main, dans `<id>.json`

- **`recolor`** : ce que le prompt n'obtient pas. SDXL ignore « peau bleue » ; la
  règle repeint une plage de teinte dans une bande de hauteur en gardant la valeur.
- **`slim`** et **`squash`** : la part de largeur et de hauteur gardée **sous la
  tête** (0,8 et 0,8 pour la sorcière, trop massive sinon). La tête ne change pas de
  taille : le visage retouché y reste juste. Appliqués sur l'image source, avant
  réduction, aux poses comme aux gestes ; la main armée de chaque image suit. Les
  `anchors` et les `patches` s'écrivent **sur la silhouette d'origine** :
  `reshape_point()` les déplace comme le corps.
- **`patches`** : des grilles posées par-dessus, en coordonnées **de la case**,
  `.` laisse passer, couleurs dans `colors`. C'est là que vit **le visage** : réduit
  à 48, celui que dessine le modèle n'est qu'une tache de 9 × 5 pixels. Le visage,
  les runes, l'amulette de la sorcière sont des retouches.
- **`anchors`** : pour chaque vue, `hand` (où l'arme se tient au repos), `waist`
  (la taille), `legs` (le haut des pieds, sous lequel rien ne respire) et `head` (le
  bas de la tête : c'est sur elle qu'une image générée se recale). Se lisent sur la
  planche agrandie.
- **`palette`** : les rampes de la forge pour ce qu'elle dessine elle-même — le
  manche de l'arme, la main à l'attaque, qui doit avoir la couleur de la peau.

## Les pièges déjà payés

- **Des proportions adultes ne survivent pas à 48 px** : la tête retombe à quatre
  pixels. Tout passe par le chibi, dans le prompt comme dans les squelettes.
- **Trop de détails font du bruit** : une référence chargée (runes partout,
  fioles, broderie) sort en masse sombre sans contraste. Peu de détails, mais très
  contrastés — et les petits se posent en retouches.
- **Redonner une image générée comme référence** amplifie sa dominante de
  couleur : le tirage suivant vire au magenta.
- **La marche image par image ne tient pas** : le modèle ignore les petits écarts
  de pose et la couleur dérive d'une image à l'autre. **Un cycle en une seule image,
  si** : d'où `anim`. Et une animation faite en décalant des bandes de la pose reste
  raide, quel que soit le réglage — trois versions refusées au jalon 25.
- **La couleur d'un cycle généré dérive** : chaque image est ramenée sur la palette
  de la pose validée. La peau est recolorée **avant**, sinon le rose part au rouge.
- **L'ombre des cycles est rosée**, pas grise : `silhouette()` retire aussi, dans le
  bas, ce qui est proche du fond.
- **De dos, pas de nez ni d'yeux dans le squelette**, sinon le modèle dessine un
  visage.
- **L'ombre que dessine le modèle** entre dans le cadrage et écrase le personnage :
  `silhouette()` la retire (grise, peu saturée, dans le bas).
