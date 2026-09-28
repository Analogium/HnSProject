# Hack'n'slash top-down — jalon 31

Suite des jalons 1 à 30. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 28 septembre 2026.** Le jalon de **l'habillage de l'inventaire** : les
proportions du sac et du coffre, et le visuel des objets.

---

## 1. Ce que l'utilisateur a demandé

- **Se rapprocher des proportions visuelles de Hero Siege**, inventaire ouvert — capture
  de référence fournie (coffre à gauche, sac à droite).
- **Changer le visuel des objets** : trop pixelisés, et banals même pour des objets
  « basiques ».

## 2. Le diagnostic

### Les proportions

Relevé sur la capture de référence, rapporté à la largeur de l'écran :

| | Hero Siege | Nous (jalon 30) |
|---|---|---|
| Coffre | ~45 % de large, **pleine hauteur** | 40 % de large, 78 % de haut |
| Sac | ~35 % de large, **pleine hauteur** | 36 % de large, 84 % de haut |
| Équipement | cadre orné, ~55 % du panneau, emplacements teintés | 56 % du panneau, cases grises, poupée dans un coin |
| Case de grille | ~2,7 % de l'écran | 3,1 % (20 px logiques sur 640) |
| Monde visible entre les deux | ~20 % | 22 % |

Mesuré sur `hns-captures-jalon30-ville/4-coffre-sac.png`. Les largeurs et la part de
l'équipement sont **déjà** celles de Hero Siege. Ce qui fait la différence : **la pleine hauteur**,
**l'équipement en cadre** dont les emplacements ont la forme de leur objet, et **le fond
d'un emplacement teinté par la rareté** — c'est lui, plus que le dessin, qui donne sa
couleur à l'écran de Hero Siege. La case de 20 peut rester : 17 ne changerait presque
rien à l'œil et obligerait à retailler toutes les icônes.

### Les icônes

- **Trop pixelisées, mesuré** : les images font 24 px sur leur grand côté — une épée
  fait **4 × 24**. `SpriteForge._fit` les agrandit d'un facteur entier, ×2 dans une case
  1 × 3, et `canvas_items` double encore à 1280 × 720 : **4 pixels d'écran par pixel
  d'image**, 6,4 en plein écran sur le 2048 × 1152 de l'utilisateur. Un plastron de
  24 × 23 reste à ×1 dans sa case 2 × 3 et n'en occupe que 69 % de la largeur.
- **Banales** : les sujets de `tools/item_icons.json` le demandent — « a plain iron
  straight sword », « a simple iron open helmet ». SDXL a obéi.

## 3. Les planches

Sur le Bureau : `hns-captures-jalon31-sac-et-icones`.

- `0` la référence, `1` le sac actuel ;
- `2` et `3` : **les proportions de Hero Siege** sur une capture de la ville — coffre et
  sac pleine hauteur, équipement dans un cadre, fond des objets teinté par la rareté —,
  en palette cramoisie (`2`) et dans la palette actuelle (`3`). Les icônes y sont
  **celles d'aujourd'hui**, pour ne juger que la mise en page ;
- `4` (échelle réelle de l'écran à 1280 × 720) et `5` (×2) : **cinq partis pris
  d'icônes** sur quatre bases, dans les vraies tailles de case :
  1. l'actuelle ;
  2. même sujet, même graine, **réduite au cadre de la case** et non plus à 24 px — la
     résolution seule ;
  3. **sujet enrichi** (« a sturdy iron longsword with a bronze crossguard, a red
     leather wrapped grip… »), pixel art, un pixel d'image par pixel logique ;
  4. le même, **deux pixels d'image par pixel logique** — un pixel d'écran à
     1280 × 720 ;
  5. **peinte**, sans le LoRA pixel art, à la même densité que 4.

Trois choses vues en montant les planches :

- **Sans le LoRA, SDXL ignore l'orientation** : l'épée peinte sort en diagonale, pointe
  en bas ou en planche de trois ; la retenue est retournée. Chaque arme peinte coûtera
  plusieurs graines ;
- **le style peint sort « dark fantasy » quoi qu'on demande** — cornes, rouge, dorures sur
  un simple casque de fer. Il faudra le tenir au négatif pour les objets de base ;
- **la densité 4 ou 5 ne tombe juste qu'à 1280 × 720.** En plein écran à 2048 × 1152
  (facteur 3,2), deux pixels d'image par pixel logique donnent 1,6 pixel d'écran au plus
  proche voisin, donc des pixels doublés un sur deux ; une image peinte y voudra un
  filtrage linéaire, du pixel art fin non.

## 4. Le choix sur planche

- **Palette cramoisie** (planche 2), fond des objets teinté par la rareté ;
- **icônes 3 : sujet enrichi, pixel art, un pixel d'image par pixel logique** — la
  densité des personnages et du décor, qui reste juste à tout facteur d'affichage ;
- **jauges et barre de compétences cachées** sous les panneaux, comme Hero Siege.

## 5. Le sac et le coffre

- **Pleine hauteur**, collés aux bords : le sac à droite (233 px logiques, 36 % de
  l'écran), le coffre et l'étal à gauche (265 px, 41 %). Il reste 142 px de monde entre
  les deux, 22 %.
- **L'équipement dans un cadre** à double liseré et coins pleins, emplacements disposés
  comme chez Hero Siege : arme et main gauche en grandes cartes 2 × 4 de part et d'autre,
  tête, torse et ceinture au milieu, anneaux de chaque côté de la ceinture, gants et
  bottes en bas. Le portrait reste dans le coin haut-gauche, à même le cadre.
- **Chaque emplacement tient au moins l'encombrement de sa famille**
  (`test_each_slot_holds_its_family_footprint`) : l'icône y est posée à 1:1, jamais
  agrandie — le paramètre `fill` de `_draw_item`, qui l'agrandissait pour remplir
  l'emplacement, est supprimé.
- **Le fond d'un objet dit sa rareté**, dans le sac comme porté : cramoisi pour un objet
  commun, sa couleur assombrie de 68 % sinon. Il remplace le fond gris unique du sac et
  le fond « rareté à 80 % » des seuls emplacements.
- **Le sac est le dernier enfant de `UI`** : jauges et barre passent dessous
  (`test_the_bag_is_drawn_over_the_hud`), et il reçoit les clics avant la barre.
- La palette cramoisie vit dans `InventoryPanel` ; les autres panneaux gardent celle de
  `UiPalette`.

Ce que la capture a corrigé (`hns-captures-jalon31-sac-et-icones`, 6 à 9) :

- **le fond à 98 % laissait lire le bandeau d'aide** sous l'étal, et le bord des jauges
  sous le coffre : sur toute la hauteur de l'écran, les fonds sont opaques ;
- reste visible : l'infobulle d'un objet du sac, et surtout l'encadré du glossaire, se
  posent sur le coffre quand il est ouvert — la bande de monde entre les deux panneaux
  est plus étroite qu'une infobulle et son glossaire côte à côte.

## 6. Les icônes

- **Les 61 bases** ont une image, dont les six gantelets et solerets que la forge
  dessinait encore. Trois graines par base, 183 tirages, ~10 s l'un.
- **Taillées à la case de leur famille**, un pixel d'image par pixel logique :
  `tools/item_icons.py` lit le cadre dans le jeu (`box_of()` : `GRID_SIZES`, `CELL`,
  `PAD`, `MARGIN`) au lieu du côté fixe de 24. `SIDE` ne sert plus qu'aux compétences
  et vit désormais dans `skill_icons.py`.
- **Le gabarit enrichi** de la planche 3, et des sujets réécrits sans « plain » ni
  « simple » : un palier 1 reste en fer usé, avec du bronze, du cuir, des rivets.
- **Au sol**, `SpriteForge._fit` réduit en Lanczos : au plus proche voisin, une image
  de 56 px réduite à 14 ne gardait qu'un pixel sur quatre. Planche 10.

Choisi sur les planches par famille, ce que les graines ont refusé :

- **les manuels de la foudre et du feu sortent en coffre ou en tonneau** sur deux
  graines sur trois : le gabarit enrichi pousse vers l'objet en volume. La formule de
  famille des manuels tient encore, sur la troisième ;
- **la capuche sortait en robe portée** sur les trois graines ; « an empty grey wool
  hood … just the hood alone » l'a réglée ;
- **une ceinture enroulée est minuscule** dans un cadre de 35 × 14 : on retient celles
  que SDXL a posées à plat ;
- une dague a la longueur d'une épée : le détourage remplit le cadre, qui est celui de
  toutes les armes.

Reste : **les silhouettes des emplacements vides** sont encore les dessins de la forge,
agrandis d'un facteur entier — à 13 % d'opacité, ils ne jurent pas encore assez pour
justifier une passe.
