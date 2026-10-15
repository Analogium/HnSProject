# Hack'n'slash top-down — jalon 52

Suite des jalons 1 à 51. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 15 octobre 2026.** La chaîne 3D du jalon 51 s'étend aux six ennemis et au
joueur de flûte, redessiné ; tout le monde rapetisse de 30 %.

---

## 1. Ce que l'utilisateur a demandé

- **Refaire les ennemis** en 3D : les six (grunt et caster compris, encore en grilles),
  en gardant leur apparence.
- **Diminuer de 30 %** la taille du joueur et des ennemis en jeu, « pour l'instant ».
- **Revoir le joueur de flûte**, plus détaillé : « il contrôle les rats avec sa
  mécanique, il est axé dégâts physique et nécrotique, et est un hybride sort/attaque ».
  Puis : « je ne veux pas un médecin mais un joueur de flûte ».
- Pas de rat compagnon ; les gestes « joués » attendront les compétences du manuel.

## 2. Les ennemis

Même chaîne que la sorcière (recette : `tools/characters/LISEZMOI.md`, « En 3D ») :
rendu « 3D » de face d'après la vue de face existante, dos, Stable Fast 3D, face et dos
repeints, gréage local, planche. Le grunt et le caster, sans image source, ont d'abord eu
un concept fidèle à leur grille (orc trapu tête basse ; robe à capuche pointue, deux
braises cyan dans le noir). Graines choisies seul, sur la ressemblance.

| ennemi | geste (`attack`) | arme | hauteur, avant → 3D → à 70 % |
|---|---|---|---|
| grunt | balayage | hachoir | grille → 33 → ~23 px |
| caster | incantation | bâton | grille → 34 → ~23 px |
| chevalier bélier | estoc (coup d'épaule) | — | 38 → 37 → ~26 px |
| gobelin cuivré | lancer | — | 32 → 32 → ~22 px |
| champignon | — (il éclate) | — | 30 → 31 → ~22 px |
| colosse | frappe de haut | — | 44 → 43 → ~30 px |

Un ennemi ne joue que sa rangée `attack` (`Enemy._strike()`), à la cadence de la
planche : un seul geste chacun. Le hachoir et le bâton sont modélisés dans
`blender/weapons.py` et rendus en couche, comme les armes des classes.

Erreurs vues en route :

- **Les dos sortaient de face** sur les quatre monstres : leurs yeux lumineux
  l'emportaient. Réglé par la vue en tête de prompt, l'image de face à 0,25 et le
  visage interdit. Le champignon garde son visage à toutes les graines : il prend le
  dos que Stable Fast 3D devine (`mesh --sf3d`).
- **Le gréage local posait les articulations au centre** des corps élargis (`width`) :
  la pose A n'était pas élargie comme celle des images.
- Le colosse fait 43 px de large contre 24 en 2D : sa carrure de colosse est plus marquée.

## 3. La taille

Réduits **au rendu**, pas étirés en jeu : étirer une planche de 0,7 donnerait des
pixels de tailles inégales. `blender.size` × 0,7 pour les neuf planches, `scale` 0,7
pour l'ombre au sol et l'arme procédurale. Les classes passent de 38 à ~27 px.

Ce qui ne bouge pas : **la collision**. Les PNJ de la ville, encore en grilles,
paraissaient plus grands que le joueur à la capture : voir §5.

## 4. Le joueur de flûte

Trois planches de concepts, en « rendu 3D », LoRA éteint :

1. **Six directions sur le thème**. La première a raté d'un bloc : « rat master » dans
   le prompt a fait six hommes-rats. Refaite sans le mot, l'utilisateur a choisi le
   **médecin de peste**… puis l'a refusé une fois vu en pose A : « je ne veux pas un
   médecin mais un joueur de flûte ».
2. **Six musiciens**. « chibi » dans le prompt donnait des bébés : refaite en
   proportions adultes. Choisi : **Hamelin sombre** (manteau mi-parti jaune et cramoisi,
   toque à plume), graine 4242.
3. **En pose A, aux proportions du jeu** : la toque à plume sortait en chevelure rouge,
   réglé en nommant un béret de velours. Retenu : la 4242 ; le dos, la 777.

**Le rat sur l'épaule** : SDXL ne l'y dessinait pas (prompt seul, puis retouche locale :
il collait des moustaches à l'homme). Posé à la main puis fondu, il a été jugé
« illisible » et retiré. Pas de rat dans le modèle : collé au pied, il suivrait la jambe.

**Le détourage** gardait le fond dégradé d'un rendu « studio » : le premier modèle avait
une plaque au-dessus du chapeau et sous les pieds. `model_3d.silhouette` retire
désormais le fond qui varie doucement depuis les bords.

À 26 px, le manteau sort plutôt beige doré que jaune ; la flûte se lit comme un bâton
clair. La flûte reste une couche, comme au jalon 51 : le modèle a les mains vides.

## 5. Les PNJ de la ville

Le marchand et l'entraîneur empruntaient la grille du guerrier, à l'ancienne taille :
plus grands que le joueur une fois celui-ci réduit. Passés en 3D par la même chaîne,
choisis sur planche (`Desktop/hns-pnj`) : le **colporteur** (sac à dos, tonnelets à la
main, graine 4242 de face et de dos) et le **vétéran** (gambison rouge, cape, épée en
couche ; face 777, dos 4242). Archétypes `merchant` et `trainer`, le repos et la marche
— la marche seulement pour que la couche d'épée ait des images où tirer sa palette.

## 6. La lueur

Vu en rédigeant : les couches d'arme 3D du jalon 51 rompaient l'invariant de lueur.
Les reflets des lames montaient à **0,913** de luminance, sur quelques centaines de
pixels par planche, au-dessus du seuil de glow (0,9). La palette des planches 3D est
désormais plafonnée à 0,88 (`blender_sheet.LIGHT_MAX`) — 0,879 mesuré ensuite sur les
24 planches — et `test_no_sheet_pixel_passes_the_glow_threshold` les relit toutes
(0,4 s : 24,9 s de suite unitaire sans lui, 25,3 avec).

## 7. Ce qui est parti

- Les grilles du grunt et du caster, leurs entrées dans `ART` et leurs cas de `config()` ;
  les armes procédurales `cleaver`, `club` et `staff`, que plus rien ne portait.
- L'assemblage en capsules (`_draw_front`, `_draw_side`, `_draw_head`, `_draw_robe`) et
  ses réglages de `config()` : plus aucun archétype n'y tombait.
- Les sources 2D du joueur de flûte (`concept.png`, `down.png` et les références de
  l'utilisateur restent), celles de la sorcière et du Vive lame.
- L'outillage local quitte `%TEMP%`, que Windows peut vider : `C:\Generate\hns-local3d`
  et `C:\Generate\hns-trellis-venv`.

## 8. Reste à faire

- Le manuel du joueur de flûte (pistes ci-dessous) ; puis les gestes « joués » (la
  flûte à la bouche) et l'icône du manuel.

### Le manuel du joueur de flûte — pistes, rien de concret

Demandé : des attaques **et** des sorts, des dégâts physiques ou nécrotiques, au moins
une compétence liée aux rats **qui ne soit pas une invocation**, une petite note
musicale, et le **Roi des Rats**, qui le transforme. Pistes qui plaisent « pour
l'instant » :

- **Fil rouge, la vermine** : des rats accrochés aux ennemis (des charges, lisibles sur
  leur fiche) que certaines compétences posent et d'autres consomment.
- **Morsure** (attaque) : accroche un rat, qui ronge (saignement).
- **Danse macabre** (attaque) : une suite de coups, le dernier fait sauter les rats
  accrochés autour de la cible (nécrotique).
- **La Nuée** (sort) : un tapis de rats qui déferle au sol comme une vague, frappe et
  accroche des rats — une forme posée, pas un allié.
- **Air de Hamelin** (sort entretenu) : une mélodie qui attire et ralentit les ennemis
  proches, nécrotique faible et continu.
- **Peste** (malédiction) : un ennemi mort avec des rats libère un nuage qui contamine
  ses voisins.
- **Contrepoint** (buff) : alterner attaque et sort donne de l'Harmonie, répéter le même
  type la fait retomber.
- **Le Roi des Rats** : transformation qui consomme la vermine ; ses autres compétences
  changent de forme pendant qu'elle dure, avec des nœuds-suites propres. Visuel : le roi
  des rats de la légende (rats aux queues nouées, couronne d'os), un second modèle 3D
  et une animation de transformation.

Décidé : le Roi des Rats est **une compétence comme les autres** (pas un ultime à
part) ; **certaines compétences sont physiques, d'autres nécrotiques**, la conversion
restant possible. En réserve : Note stridente, Terrier, Fausse note.
- **La suite a triplé** depuis la mesure du 22/09 : 366 s de tests au lieu de 108
  (430 s en tout), 30 s pour l'unitaire au lieu de 8. Durées reportées dans `CLAUDE.md` ;
  la cause n'est pas cherchée.
