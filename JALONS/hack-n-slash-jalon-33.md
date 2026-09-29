# Hack'n'slash top-down — jalon 33

Suite des jalons 1 à 32. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 29 septembre 2026.** Le jalon du **premier biome**.

---

## 1. Ce que l'utilisateur a demandé

Revoir le visuel de la zone pour qu'il se rapproche d'une zone de l'enfer de Hero
Siege (« Outskirts of Inoya ») : terre rouge-brun, grandes taches plus claires,
herbe sèche, arbres morts, os, barricades, vignettage. D'autres biomes viendront ;
celui-ci est le premier.

## 2. La planche

Relevé sur la capture de référence : la terre sombre à **0,16** de luminance, les
taches à **0,20 – 0,26**, douze couleurs pour l'essentiel de l'image. Quatre maquettes
de 640 × 360 px, avec les vrais personnages du jeu, le même semis, le même éperon de
mur — seules la palette et la densité changent :

| | Parti pris |
|---|---|
| 1 | Fidèle : les valeurs relevées sur la référence, rouge brique et taches rosées |
| 2 | Sombre : la même teinte un quart plus bas, la règle d'avant (le sol sous les acteurs) |
| 3 | **Ocre** : terre brûlée, taches sable, herbe jaune |
| 4 | Cendre et sang : sol gris-violet, taches rouge sang, décor plus dense |

**Choisi : la 3**, avec arbres morts, herbe et buissons, rochers. **Refusés : les os.**
Les barricades de pieux ne figuraient pas sur la planche : quatre tirages SDXL, quatre
tables ou potences.

## 3. Ce que la planche a appris

- **Le sol ne passe pas par ComfyUI.** Trois sujets × trois graines, et toujours des
  dalles — le piège que le négatif de `tools/tiles.py` évite pour le mur, mais qu'un sol
  « terre » ne contourne pas. Une terre marbrée à quatre tons, c'est un bruit tramé :
  `tools/tiles.py` la tire elle-même.
- **Le détourage des icônes ne va pas à un arbre.** `item_icons.cut()` part des bords :
  le fond pris entre deux branches restait en taches grises. `keyed()` détoure par
  couleur sur toute l'image.
- Buisson et rocher : les sujets « bush » sortent des arbres ; réduits à 30 px, ce sont
  des arbustes morts, et c'est ce qu'on voulait.

## 4. Le montage

- **Le sol est un shader**, pas un TileSet plus riche. Des taches de plusieurs cases
  demandaient 47 tuiles de transition ; une image par zone, 3 072 px de côté, se
  peindrait en secondes en GDScript. Le shader lit deux textures raccordables au pixel
  du monde et un masque `FastNoiseLite` d'un texel pour 16 px : **1,4 à 2,6 ms** la
  fabrication, mesurés sur quatre graines.
- **Le seuil 0,56** donne 34 à 42 % de masque selon la graine ; la trame du bord en
  retranche un peu, et on retombe sur le **tiers** de la planche (0,33 mesuré).
- **Les arbres poussent sur le bord sud des murs.** C'est là qu'on ne marche jamais :
  pas de collision à ajouter, pas de champ de flux à prévenir. Buissons et rochers se
  traversent, comme le petit décor de la référence.
- **Le masque est le premier tirage de `zone_rng`**, là où l'étaient les variantes de
  tuiles : un retour de portail redonne les mêmes taches et le même décor
  (`test_the_zone_floor_comes_back_identical`, qui compare désormais le masque et chaque
  pièce, les tuiles de sol étant toutes la même).

## 5. Vu à la capture

- Les taches semblaient plus pâles et plus grandes qu'en maquette : **c'est l'échelle**,
  la planche était agrandie ×2. Couleurs rendues fidèles aux textures (tache
  111, 75, 51 sous le vignettage) ; même part de taches.
- **La cendre ne tenait plus sous le sol.** `test_a_burn_is_darker_than_the_floor`,
  rebranché sur `TilesetBuilder.FLOOR_BASE` au lieu du 0,21 recopié, a trouvé la brûlure
  à 0,183 pour un sol à 0,179 : le brun choisi au jalon 24 pour ressortir sur le gris
  en avait la valeur sur l'ocre. `EffectForge.ASH` descend de 15 %, même teinte.

## 6. Mesures

Banc `world/stress_test.tscn`, 300 ennemis en combat, 240 images de chauffe puis
1 440, cinq paires alternées avant / après : **165 img/s des deux côtés**, physique
**7,06 ms avant, 6,49 après** — dans le bruit. Peinture de la zone : 7 ms.

## 7. La route et les trois zones

Retour de l'utilisateur sur la première livraison :

- **une surface grise sous les arbres et les rochers**. C'était l'ombre que SDXL pose
  au pied malgré « no shadow, no ground » : un gris sans teinte, plus sombre que le
  fond, donc gardé par le détourage. La couleur seule ne la sépare pas de l'écorce,
  grise elle aussi (mesuré : 0,4 de luminance et 0,02 de chroma des deux côtés). Elle
  est retirée **dans le bas de la silhouette seulement** (`cast_shadow()`). ComfyUI a
  un nœud de détourage, mais aucun modèle installé ;
- **trop de taches claires** : une zone, c'est son biome et **une route** de l'entrée
  à la sortie. Les taches ont disparu, la route les remplace dans le même masque ;
- **un mécanisme** : trois zones du biome enchaînées depuis la ville, chacune avec un
  waypoint qu'on active en marchant dessus, pour de bon.

Choisis par l'utilisateur : **une carte neuve à chaque entrée**, **le niveau choisi
+0 / +1 / +2**, **un réseau de waypoints façon Diablo** (celui de la ville compris),
**pas de sortie après la zone 3** pour l'instant.

- **La route serpente sans chercher de chemin pondéré.** Un plus court chemin brut,
  sur une carte ouverte à 83 %, tirait des L à la règle. On calcule les distances à la
  sortie, puis on marche de l'entrée vers une case plus proche, en suivant un bruit
  lent. La route reste un plus court chemin (le test le vérifie), et elle ondule.
- **La sortie est la case la plus loin à pied**, pas à vol d'oiseau.
- **Les deux bouts touchent le bord** : la caméra y montrait le gris du fond. Un
  `ColorRect` de la couleur des murs couvre le hors-carte.
- **Le banc de stress recentre le joueur** : l'entrée est contre le bord, et la moitié
  de ses vagues tombait dans le mur. Le tableau de référence reste comparable.
- **La sauvegarde passe en v11** (`waypoints`, des rangs). Insérer une zone au milieu
  de `AREAS` décalerait les waypoints déjà activés : on ajoute toujours à la fin.

Mesures : la route coûte **28 ms** sur ~125 de génération, le masque **7 ms**. Au
banc, 300 ennemis en combat, cinq paires : **165 img/s** des deux côtés, physique
**5,74 ms avant, 5,42 après**. `EXPECTED_ENEMIES` reste à 68 : l'apparition déplacée
au bord n'a pas changé le peuplement de la graine 4242.

Demandé ensuite : **la carte (TAB) montre la route, le waypoint et la sortie**. La
route est peinte dans le fond de la carte, les deux autres sont des cadres creux. Vu
à la capture : en carré plein, le waypoint allumé avait le cyan du joueur et
l'éteint le gris du sol ; c'est la forme qui les sépare, pas la couleur.

## 8. Ce qui reste

- **Les murs** sont toujours des carrés sombres ; un arbre planté sur un petit éperon
  se lit mal. Falaises rocheuses ou fourrés d'arbres morts : une planche à faire.
- **Le waypoint, le passage et la liste sont provisoires** : tracés comme les autres
  objets de la ville, et la liste est un `PopupMenu` nu. À refaire sur planche.
- Le nom de la zone ne s'affiche qu'en entrant.
- Les barricades, si on les veut, se dessineront à la main.
