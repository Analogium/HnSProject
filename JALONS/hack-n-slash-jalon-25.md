# Hack'n'slash top-down — jalon 25

Suite des jalons 1 à 24. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 22 septembre 2026.** Le jalon des **classes**. Avant tout gameplay, un
visuel : à la création, choisir entre un **guerrier** et une **sorcière**, qui ne
diffèrent encore que par le dessin — et la sorcière part baguette en main, l'arme
suivant toujours l'équipement.

Livré dans ce lot : la sorcière, jouable, et **l'outil** qui l'a produite. Reste :
le guerrier refait par le même outil (§6).

---

## 1. Ce que l'utilisateur a refusé, et pourquoi c'est l'essentiel

La méthode du jalon 24 — des grilles de pixels écrites à la main dans le code — a
donné une sorcière lisible et **« trop basique, surtout dans son visage »**. La
référence est Hero Siege, dont la Stormweaver en jeu fait une cinquantaine de pixels :
tramés, contours colorés, visage expressif. Écrit en texte, pixel par pixel, sans
voir, ce niveau ne s'atteint pas. Même en passant la case de 32 à 48.

Le choix a donc été fait **sur pièce**, en trois planches, toutes dans
`hns-captures-jalon25` sur le Bureau :

| Essai | Ce qu'il a montré |
|---|---|
| Grilles à la main, 32 puis 48 px (`01`–`04`) | silhouette lisible, visage pauvre — refusé |
| La référence de l'utilisateur réduite (`05`–`06`) | proportions adultes : **la tête tombe à 4 px**, tout vire au brun sombre |
| SDXL + `pixel-art-xl`, sprite **chibi** (`07`–`09`) | à 48 px le visage se lit ; retenu : la 1, « chibi noire », à 48 px |

**Ce qui fait le rendu Hero Siege, c'est le chibi** — une tête du tiers du corps —
plus que la résolution.

## 2. Garder un personnage d'une vue à l'autre

Trois tirages séparés font trois sorcières. Essayés dans l'ordre :

- **une planche de retournement en une image** (`10`, `11`) : cohérente à
  l'intérieur d'une image, mais sans lien avec le concept retenu, et les couleurs
  passent d'une pièce à l'autre (le cramoisi du chapeau finit dans les cheveux) ;
- **IPAdapter + OpenPose** (`12`–`14`) — installés dans le ComfyUI de
  l'utilisateur, l'extraction de pose non : **les squelettes sont écrits dans
  l'outil**, ce qui est plus précis. Retenu. Deux réglages ont compté : des
  squelettes **chibi** (avec un corps adulte, le visage redevenait une tache) et
  `style transfer` à 1,0.

## 3. La personnalité : ce qui survit à 48 px

L'utilisateur a voulu plus de caractère et fourni une seconde référence, très
chargée — runes, breloques, fioles, broderie. Générée telle quelle (`15`), elle
sort en masse bleu sombre sans contraste : **le détail fait du bruit à cette
taille**. Redonnée comme référence une image déjà générée (`16`), la dominante
vire au magenta.

Ce qui a marché (`17`, `18`) : la base cohérente, puis des **retouches à la main**
sur la planche réduite — la peau recolorée en bleu (SDXL ignore « peau bleue »), le
**visage redessiné** en 12 × 9 pixels, des runes cyan sur la bande du chapeau,
l'amulette. Peu de détails, très contrastés. Ce sont les `recolor` et `patches` de
`tools/characters/witch.json`.

## 4. L'animation se fait dans la forge

Une marche générée image par image (`19-marche-generee.gif`) ne tient pas : le
modèle ignore les petits écarts de pose et la couleur dérive d'une image à l'autre.
L'outil ne livre donc que **trois poses fixes**, que `SpriteForge._draw_sheet()`
découpe en bandes et décale. La main armée reste commune aux deux chemins
(`_armed_hand()`).

**Trois versions refusées avant la bonne.** Toutes découpaient les trois poses fixes en
bandes et les décalaient :

1. les constantes des grilles (1 px de souffle, un pied levé d'un pixel, la cape en
   bloc) : un personnage de 48 px y glisse au lieu de marcher (`29-marche-actuelle.gif`) ;
2. amplitudes doublées, chapeau en retard d'une image (`33-marche-*.gif`, colonne 1) ;
3. **bandes cisaillées**, chaque rangée décalée un peu plus que celle du dessus, en huit
   temps (`34-*.gif`). Refusée à son tour : **raide, qui tremble, pas assez de
   mouvement**. C'est la limite du procédé, pas du réglage : décaler des morceaux
   d'une image ne fait pas un pas, parce qu'un pas redessine les jambes.

Des poses de marche générées **une à une** (`19-marche-generee.gif`, puis en img2img,
`31-B-*.gif`) ne tenaient pas non plus : le visage et la couleur changent à chaque
image. Mais la planche de retournement (§2) avait montré qu'**à l'intérieur d'une
seule image**, le modèle garde le personnage. D'où la solution retenue : **un cycle
entier en une seule génération**, quatre squelettes côte à côte (`38-*.gif`, puis
`hns-witch-walk-*.gif` et `hns-witch-attack-*.gif`), chaque image ensuite :

- ramenée sur **la palette de la pose validée** — sans ça, la dominante dérive vers le
  magenta, le piège du §3 ;
- recalée **par la tête** sur la pose validée, pieds au sol, à une échelle **commune au
  cycle** (un pas jambes écartées est plus bas ; le mettre à la hauteur des autres
  l'agrandirait) ;
- retouchée comme la pose (le visage), à l'endroit où le recouvrement des silhouettes
  place la tête.

Le bras armé reste le long du corps pendant la marche, et c'est l'autre qui balance :
l'arme, posée par le jeu au poignet de chaque image, battrait sinon comme un fléau. Sa
position dans chaque image vient du squelette qui l'a guidée.

Retenus par l'utilisateur : la marche de la graine 4242, l'attaque de la 777 (bras
écartés, cape déployée au temps fort). Le repos reste la pose validée, qui respire d'un
pixel, sans cisaillement.

Puis **le corps affiné** : l'utilisateur le trouvait trop massif. Planche de cinq
carrures à côté des autres personnages (`42-corps.png`) — plus petite, bien plus
petite, affinée, les deux ; retenue : **même hauteur, tout ce qui est sous la tête
20 % plus étroit** (`slim` à 0,8), plus chibi encore. Appliqué sur l'image source
avant réduction, donc sans perte, et à tous les gestes (`43-*`, `44-*.gif`).
« Toujours un peu trop grosse et grande » : seconde planche (`45-corps-tasse.png`),
cette fois en **raccourcissant** aussi le corps sous la tête — la réduire entière
aurait rapetissé la tête, et le visage retouché à la main avec. Retenue : corps
20 % plus court (`squash` à 0,8) en plus de l'affinage (`46-*`, `47-*.gif`).
Repères et retouches restent écrits sur la silhouette d'origine ; un oubli l'a
montré : sur les cycles, le visage retombait cinq pixels trop haut, dans le chapeau.

Et un manque trouvé à la capture : **un sort n'animait pas le lanceur**, seul un coup
d'arme le faisait. `Player.cast_slot()` joue maintenant l'attaque à tout lancer, sauf la
ruée (`41-jeu-sort-*`).

Mesuré en jeu, en fenêtré : **33 images en 13,9 ms** pour la sorcière (repos 4,
marche 4, attaque 3, par vue), 5,2 ms pour les 24 du guerrier — une fois par arme et
par silhouette.

Un bug trouvé au passage : les repères d'animation étaient rangés sous la clé
`views` de la fiche du personnage, qui porte déjà le prompt et les graines des vues,
et l'écrasaient. Ils vivent maintenant sous `anchors`.

## 5. Le système

`tools/character_forge.py` : `concept`, `views`, `keep`, `build`. Une planche sur le
Bureau à chaque étape, le choix de l'utilisateur entre deux. Tout ce qui fait un
personnage est versionné — prompts, graines, recolorations, retouches, repères, et
les images retenues, pour que `build` ne demande jamais ComfyUI. Le concept peut
venir d'ailleurs : l'utilisateur fait ses références dans Leonardo, qui n'a pas à
être branché.

Côté jeu : `Character.CLASSES`, `class` dans la sauvegarde (v8, les v1 à v7 sont
des guerriers), la classe choisie à la création, la baguette en main de la
sorcière. Captures : `19-creation-sorciere`, `18b-liste`, `20` à `26`.

Vu à la capture et corrigé : dans la vignette de création, le chapeau sortait du
cadre — les pieds calés sur ceux des guerriers remontent la sorcière de 10 px ;
les vignettes descendent d'autant (`THUMBNAIL_FEET`).

Puis, à la demande de l'utilisateur, **tout ce qui dépend de la taille** :

- la barre de vie et les textes du joueur (dégâts, état, butin) montent de
  `SpriteForge.head_room()` — lu sur l'image, parce que c'est le chapeau qui dépasse,
  et qu'aucun repère ne le décrit. Pour le guerrier, rien ne bouge d'un pixel ;
- la liste des personnages passe à des lignes de 50 (quatre visibles au lieu de
  cinq : une cinquième passerait sous les boutons), personnages posés par les pieds ;
- la poupée du sac passe de 2 × 2 cases à 3 × 3 ; arme, torse, main gauche et ce
  qui suit descendent d'une rangée.

La collision ne change pas : le gameplay des classes est encore le même.

## 6. La suite

- **Le guerrier par l'outil**, pour qu'il ne jure pas à côté d'elle. Ses quatre
  tenues deviendront des recolorations de sa planche.
- Le gameplay des classes.
