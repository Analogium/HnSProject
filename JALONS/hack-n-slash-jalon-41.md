# Hack'n'slash top-down — jalon 41

Suite des jalons 1 à 40. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 4 octobre 2026.** Le **manuel de la sorcière** rempli.

---

## 1. Ce que l'utilisateur a demandé

« Il est temps de remplir le manuel unique de la sorcière, donne-moi des idées
intéressantes. » Sur la proposition (§2), « ça me va, allons-y » : quatre cases neuves —
**Catalyse, Familier, Poupée de chiffon, Trinité** — et les arbres des deux cases du
jalon 28. Le Chaudron et l'Envol restent en réserve.

## 2. L'identité

Les manuels de la foudre, des flammes et du froid tiennent chacun **un** élément. La
sorcière tient **ce qui se passe entre eux** : le tour de rôle (`Skill.nature_cycle`,
`Player._turns`), qu'aucun autre manuel n'a, et ce qui le récompense. Plus ce qu'une
sorcière a et qu'un mage n'a pas : un familier, un fétiche.

| case | ouvre à | ce qu'elle fait | ce qu'elle réutilise |
|---|---|---|---|
| Projectile élémentaire *(jalon 28)* | 1 | trait feu → froid → foudre, +200 % de chance d'état | — |
| **Trinité** | 2 | buff à charges, gratuit : chaque sort d'une autre nature que le précédent donne une charge d'**Harmonie** (dégâts de sort accrus), 3 au plus, 4 s | le buff à charges de la Soif de sang |
| Amplification des sorts *(jalon 28)* | 3 | buff lancé, +20 % de dégâts de sort plus, 10 s | — |
| **Catalyse** | 5 | au point visé, **consomme** les états élémentaires des ennemis et en tire une réaction par paire, puis frappe son cercle ; tourne feu → froid → foudre | `Explosion.put()`, `Targets`, `pass_on()` |
| **Poupée de chiffon** | 7 | un fétiche posé au point visé, que les ennemis frappent à la place du joueur ; il éclate en tombant ou au bout de sa durée, dans la nature du tour | `Enemy.foe()`, le calque du joueur |
| **Familier** | 10 | entretenu : un corbeau à l'épaule **rejoue chaque sort posé** à 40 % de ses dégâts, 0,4 s après | la liste des formes qui se posent et s'oublient |

### Les réactions de la Catalyse

Sur chaque ennemi du cercle qui porte **au moins deux** des trois états élémentaires
(embrasé, transi, engourdi), ces états sont retirés et chaque paire réagit, à
`REACTION_PART` d'un coup de la Catalyse, moitié dans chaque nature de la paire :

| paire | réaction | ce qu'elle fait |
|---|---|---|
| embrasé + transi | **Vapeur** | une explosion autour de l'ennemi |
| embrasé + engourdi | **Arc ardent** | un arc vers les trois ennemis les plus proches |
| transi + engourdi | **Givre conducteur** | frappe l'ennemi, et son transi gagne ses voisins |

Les trois à la fois : les trois réactions. Les états se lisent **avant** la frappe du
cercle : la Catalyse fait réagir ce qu'on a posé, puis sème l'état de son tour pour la
suivante. Le Projectile élémentaire pose justement les trois : c'est le combo de base.

### Le Familier

Il rejoue les sorts (cadence d'incantation) dont la forme **se pose et s'oublie** —
`Familiar.ECHOED`, tiré de `Skill.TRANSFORMABLE` moins ce qui part du corps (ruées,
coups d'arme, l'orage porté, le nid). Depuis sa position, vers le point visé au lancer,
à `ECHO_PART` des dégâts, sans coût, sans tour, sans charge de Trinité : un écho n'est
pas un lancer. Ses points donnent de la vitesse d'incantation tant qu'il vole.

## 3. Les arbres

Mêmes conventions qu'aux jalons 38 à 40 : chiffres de **premier réglage** ; « relié à
(n) » = points demandés dans le parent ; ⇄ marque un échange. Le manuel entre dans
`UNIQUE_TREES`. Les quatre cases neuves ont reçu leur arbre après la livraison (§8).

### Projectile élémentaire — le tour

| nœud | pts | effet | relié à |
|---|---|---|---|
| Arcanes | 5 | +12 % dégâts plus | — |
| Fulgurance | 4 | +15 % vitesse de projectile | — |
| Électrochoc | 4 | +15 % effet de l'engourdi | — |
| Affinité croisée | 3 | +8 % dégâts accrus contre les embrasés, les transis et les engourdis | Arcanes (1) |
| Ricochet | 2 | le trait rebondit vers l'ennemi le plus proche, une fois par point | Fulgurance (1) |
| Prisme | 2 | +1 projectile par point ⇄ −15 % dégâts plus ; **la salve répartit le tour** : chaque trait prend l'élément suivant | Ricochet (1) |
| **Triade** | 1 | **trois comètes, une par élément, naissent autour de la sorcière et se rejoignent au point visé, où elles éclatent ensemble** — le coup porte les trois natures, un tiers chacune ⇄ +25 % temps du geste | Arcanes (2) ou Électrochoc (2) |

21 points. **L'engourdi prend une force** (`numb_effect`), le dernier état qui n'en avait
pas : l'engourdi subit `NUMB` × force de dégâts en plus.

### Amplification des sorts — la surcharge

L'amplification garde sa ligne ; les nœuds de buff s'y ajoutent tant qu'elle brûle.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Surpuissance | 5 | +3 % dégâts de sort plus (buff) | — |
| Volubilité | 4 | +4 % vitesse d'incantation (buff) | — |
| Rémanence | 3 | +15 % durée | — |
| Résonance | 3 | chaque sort lancé sous l'amplification la prolonge de 0,3 s par point | Volubilité (1) |
| Siphon | 3 | chaque ennemi tué par un sort sous l'amplification rend 2 mana par point | Surpuissance (1) |
| Contrecoup | 3 | à sa fin, l'amplification éclate autour de vous : ajoute 6 à 14 dégâts de foudre par point, explosion de 15 px par point | Rémanence (1) ou Résonance (2) |

21 points.

## 4. Ce qui est neuf dans le moteur

- **`Skill.Shape`** : `CATALYSIS`, `DOLL`, `FAMILIAR`, `TRIAD`, à la fin. `FAMILIAR` est
  entretenu (`SUSTAINED_SHAPES`), `TRIAD` n'existe que par transformation.
- **`Skill.stack_trigger`** : ce qui donne une charge à un buff à charges — l'ennemi tué
  d'une attaque (la Soif de sang) ou le sort d'une autre nature (Trinité).
- **`SkillStats`** : `numb_effect` (dans `EFFECT_OF`), `resonance`, `siphon`.
- **`StatusEffects.remove()`** : retirer un état, pour la Catalyse.
- **Le lancer d'une case et sa pose sont séparés** : `Player._pose()` reçoit l'origine,
  le cap et le point visé, pour que le Familier rejoue depuis son épaule.
- **La salve d'une nature tournante** : chaque trait est résolu à son tour.

## 5. Ce que la livraison a changé

- **Le Prisme ne se relie plus qu'au Ricochet** : relié aussi à l'Affinité croisée, son
  lien passait sous la compétence. L'Électrochoc est monté au-dessus d'elle (0, −1),
  à côté de la Triade.
- **Le familier rejoue depuis son épaule** : `Player.cast_slot()` est coupé en deux —
  le lancer (refus, prix, tour, animation) et `_pose()`, qui reçoit l'origine, le cap et
  le point visé. Ce que la pose faisait de `self` passe par l'origine ; le Familier porte
  un champ `states` (ceux de sa maîtresse) pour que `StatusEffects.of()` le reconnaisse.
- **Un écho est le lancer entier** (`SkillStats.echoed()`) : sol, éclats, état posé
  compris. `_derived()`, qui les retire, aurait rejoué un sort amputé.
- **La Poupée n'est pas un `Minion`** : il lui aurait fallu le sprite d'un mort-vivant
  et sa marche. Une `RagDoll` à part, que `Enemy.foe()` parcourt à la suite.
- **L'Amplification éclate par `Player._shatter()`**, l'Éclatement du Tombeau : rien à
  écrire pour le Contrecoup. Relancée avant sa fin, elle n'éclate pas — c'est un rafraîchissement.
- **Les réactions se lisent dans la fenêtre Alt** (bloc « Réactions »), l'écho du Familier
  et la poupée dans le bloc des créatures, l'Harmonie dans « À chaque sort lancé ».
- **Le guide** : l'article de l'engourdi dit que des nœuds de la sorcière le renforcent.
- **Après livraison, à la demande de l'utilisateur** : les descriptions de la Catalyse et
  de Trinité disent ce qu'elles font — les trois paires et leur réaction, ce qui donne une
  charge et ce qui n'en donne pas — ; et **les comètes de la Triade percent** ce qu'elles
  traversent, chacune de sa part et de son élément, avant de se rejoindre. Ce qui est dans
  le cercle de l'éclat n'est frappé que par lui : au point visé, rien ne prend deux fois.

## 6. Le dessin, les icônes, les bancs

**Choisis sur planche** (`Bureau\hns-captures-sorciere-jalon41\`, 01 à 03) : le
**corbeau en vol** (deux battements) parmi un corbeau perché, un corbeau spectral, une
chouette, un chat et un corbeau spectral perché ; la **poupée à boutons** (robe à la
teinte du tour) parmi vaudou, paille, fétiche sur pieu, mini-sorcière et pendue ; le
**cercle d'alchimie** (anneau, triangle qui tourne, un grain par élément) parmi trois arcs,
des grains convergents et une rune tramée. La Triade reprend la comète du jalon 28.

**Vu à la capture** (11 à 20) : la Vapeur et l'Arc ardent se voient sur des grunts
préparés ; le Familier rejoue aussi la Catalyse — un second sceau, 0,4 s après.
Corrigé : **le corbeau se perdait** sur la tête sombre de la sorcière — monté à droite du
chapeau (`SHOULDER` (15, −30)), puis **passé sous un rocher** du décor — `z_index` 3,
il vole. La poupée était cachée par un rocher au point visé : un hasard de la zone, pas
un défaut.

**Les icônes**, refaites à la demande de l'utilisateur (« plus de netteté et de
logique ») : une réduction par couleur dominante, des calques composés à la main
habillés par SDXL en img2img à 0,4, le fond du corbeau ramené au violet — la recette est
dans `resources/icons/LISEZMOI.md`. Choisies sur planche (22) : Trinité, Catalyse et
Poupée A, Familier B. Le corbeau sombre sur fond sombre est le moins contrasté des six.

**Le sceau se fabrique un temps à la fois** : 4,9 ms d'un bloc au premier lancer, au rayon
36 ; découpé en quadrants, rien de gagné (`to_image()` y coûte 0,8 ms par canevas, les traits
traversant le vide) ; fabriqué à la première demande de chaque temps, 1,2 ms au pire au
rayon 36, 2,0 au rayon 52.

**Le banc de combat** (300 ennemis, Catalyse sans relâche, 240 images de chauffe puis
1 440, cinq paires alternées) : 5,59 ms de physique sans le Familier, 4,93 avec — dans le
bruit, et dans le sens inverse de ce qu'on attendait. **165 img/s partout, aucun gel.**

**Le banc des arbres** (`docs/ARBRES.md`, la sorcière mesurée pour la première fois) :
le meilleur build du Projectile élémentaire rend **×8,30 au paquet et ×5,40 au duel** —
Fulgurance, Ricochet, Prisme, Arcanes, Affinité croisée, Électrochoc —, au-dessus des
autres manuels. **La Triade est hors des critères du jalon 37** : 333/s au paquet contre
807, ×0,41 du meilleur build sans elle ; 363/s (×0,45) depuis que ses comètes percent — le
banc pose ses cibles en anneau, peu sur les trajectoires. À régler quand l'utilisateur le demandera.

**Relevé d'équilibrage** (`tests/run.sh balance`) : 4 couloirs sur 5 en échec, comme aux
jalons 38 à 40 ; aucun personnage fixe ne porte la sorcière.

## 7. Le déroulé

**Fait** : 1 à 5, puis les arbres des quatre cases neuves (§8). **Reste** : le réglage du
Prisme et de la Triade au banc des arbres ; l'article du guide sur les réactions, proposé
à l'utilisateur.

1. **Ce document.**
2. **Le moteur** (§4) et ses tests de forme.
3. **Les cases et les arbres** dans `witch.tres`, descriptions relues contre le code ;
   `i18n/en.po`.
4. **Les dessins** sur planche (`/dessiner-un-effet`) : la Catalyse et ses réactions, le
   corbeau, la poupée, la Triade, les quatre icônes.
5. **`/valider`** : la campagne, le banc de combat (le Familier double les lancers),
   `tools/catalog.sh`, `tools/balance.sh trees` avec la sorcière, `tests/run.sh balance`
   relevé. Le guide : ce que le joueur doit savoir des réactions.

## 8. Les arbres des quatre cases neuves

« Fais maintenant les nœuds des nouveaux skills, comme d'habitude un mélange de choses déjà
existantes mais pas trop, avec surtout de l'originalité, afin de ne pas avoir l'impression
que chaque spell fait au final la même chose grâce à l'arbre. » **Un seul nœud de dégâts
par arbre, et aucun dans celui de Trinité** ; chaque arbre a son geste propre : Trinité
joue sur **les charges**, la Catalyse sur **chaque réaction**, la Poupée sur **ce qu'elle
encaisse**, le Familier sur **ce qu'il rejoue**. 21 points chacun.

### Trinité — l'accord

| nœud | pts | effet | relié à |
|---|---|---|---|
| Gamme | 5 | par charge, +4 % chance d'état des sorts (buff) | — |
| Mesure | 4 | par charge, +2 % rés. feu, froid et foudre (buff) | — |
| Point d'orgue | 4 | les charges tiennent +0,5 s | — |
| Dissonance | 2 | +1 charge au plafond ⇄ **un sort qui répète l'élément les fait toutes perdre** | Gamme (1) |
| Tempo | 5 | chaque sort qui donne ou ravive l'Harmonie retire 0,1 s aux recharges en cours des compétences à recharge | Point d'orgue (1) |
| **Accord parfait** | 1 | **à pleines charges, le sort suivant les consomme toutes et part dans les trois éléments, un tiers chacun**, +30 % plus | Dissonance (1) ou Point d'orgue (2) |

**Les lignes de buff d'un nœud comptent par charge** sur un buff à charges : sans charge,
la Gamme et la Mesure ne donnent rien. Trinité n'avait aucune ligne de nœud jusqu'ici, la
règle ne change rien d'autre. Le Tempo ne touche pas les recharges des simples gestes : sur
un sort sans recharge, il serait devenu de la vitesse d'incantation.

### Catalyse — l'alambic

| nœud | pts | effet | relié à |
|---|---|---|---|
| Concentré | 5 | +10 % dégâts plus — les réactions aussi, qui en sont une part | — |
| Exothermie | 4 | +25 % puissance des réactions | — |
| Grand cercle | 3 | +15 % rayon accru | — |
| Nappe brûlante | 3 | **la Vapeur laisse une nappe** de feu et de froid (sol, 1,5 s par point, +0,5 au premier) | Exothermie (1) |
| Arc fourchu | 2 | l'Arc ardent gagne un voisin de plus par point | Exothermie (1) |
| Conductivité | 3 | le Givre conducteur transit 16 px plus loin par point | Exothermie (1) |
| **Amorce** | 1 | **la Catalyse prête l'état de son tour** : un ennemi qui ne porte qu'un état d'un autre élément réagit avec lui ; seul le sien est consommé | Concentré (2) ou Grand cercle (2) |

Les trois réactions ont chacune leur nœud, et chacun lit un nombre existant (`ground_duration`,
`targets`, `contagion`) dans `Catalysis`. Un transi prêté au Givre conducteur se pose sur les
voisins à la force du lancer, faute d'état à recopier.

### Poupée de chiffon — le fétiche

| nœud | pts | effet | relié à |
|---|---|---|---|
| Bourre de poudre | 5 | +10 % dégâts plus | — |
| Rembourrage | 5 | +20 % PV de la poupée | — |
| Appeau | 3 | les ennemis la comptent 20 px plus proche par point | — |
| **Rancune** | 4 | son éclat ajoute 15 % par point de ce qu'elle a encaissé, dans l'élément de son tour | Bourre de poudre (1) |
| **Transfert** | 3 | tant qu'elle tient, elle prend 10 % par point des dégâts que vous subissez | Rembourrage (1) |
| Jumelles | 1 | deux poupées debout ; la troisième fait éclater la plus ancienne | Appeau (2) ou Rembourrage (3) |

Le Transfert et la Rancune se répondent : ce que la poupée prend pour vous grossit son éclat.
Le détournement se fait **après** la mitigation du joueur, dans `Player._on_damaged()` : la
poupée encaisse ce qu'il aurait perdu.

### Familier — le corbeau

| nœud | pts | effet | relié à |
|---|---|---|---|
| Écho fidèle | 5 | +6 % des dégâts rejoués | — |
| Frugalité | 4 | −10 % mana drainé | — |
| Ailes noires | 5 | +2 % vitesse tant qu'il vole (buff) | — |
| Œil du corbeau | 4 | l'écho part vers l'ennemi le plus proche du point visé, dans 15 px par point | Écho fidèle (1) |
| Ressassement | 2 | un écho de plus par point, chacun `ECHO_DELAY` après le précédent ⇄ −10 % des dégâts rejoués | Écho fidèle (2) |
| **Contre-chant** | 1 | **l'écho prend l'élément suivant du tour** : feu → froid → foudre → feu | Frugalité (2) ou Ressassement (1) |

Avec le Contre-chant, un sort et son écho posent deux états différents : à eux seuls, ils
préparent une réaction pour la Catalyse.

### Ce qui est neuf dans le moteur

Treize nombres dans `SkillStats` (`stack_hold`, `dissonance`, `tempo`, `perfect_chord`,
`reaction_power`, `primer`, `doll_life`, `grudge`, `transfer`, `lure`, `echo_power`, `echoes`,
`countersong`), chacun lu à un seul endroit — ARCHITECTURE, « Qu'est-ce qu'un nœud peut
allumer ? ». `DamageType.ELEMENTS` tient le tour feu, froid, foudre que l'Accord et le
Contre-chant lisent. La file des échos n'est plus dans l'ordre où ils tombent : elle se
parcourt en entier. La fiche lit chaque nœud : charges, Accord, Dissonance et Tempo dans le
bloc du buff ; PV, Rancune, Transfert, Appeau et poupées debout dans le bloc de la Poupée ;
part, échos, proie et élément dans celui des échos ; puissance, nappe, arcs, portée et
Amorce dans les réactions.

**Le banc des arbres** (`tools/balance.sh trees only=catalysis,rag_doll` ; Trinité et le
Familier ne frappent pas, il ne les mesure pas). Catalyse : ×4,87 au paquet, ×5,01 au duel
— Concentré, Amorce, Grand cercle, Exothermie, Nappe brûlante ; ses cibles n'ont pas d'état,
l'Amorce est ce qui fait réagir, et l'Arc fourchu comme la Conductivité ne sont jamais pris.
Poupée : ×1,47 et ×1,50 ; **le banc ne la frappe pas**, donc le Rembourrage, la Rancune et le
Transfert n'y valent rien. Ni l'un ni l'autre n'est réglé : l'équilibrage se fait en dernier.

**Vu en route** : trois libellés débordaient de la fiche de nœud
(`test_passive_and_node_sheets_fit_in_both_languages`) — « des dégâts encaissés rendus à
l'éclat », « des dégâts subis détournés sur la poupée », « secondes de recharge rendues par
charge » — raccourcis.

## 9. Le lag du Serpent rejoué par le Familier

L'utilisateur : « j'ai beaucoup de lag avec Contre-chant et ce setup de Serpent » — Couvée 2,
Queue de flammes 3, Chasseur, Hydre, Mue 2, Crocs 2. **Le Contre-chant n'y est pour rien** : le
banc de combat (300 ennemis, le Serpent sans relâche, 8 s de chauffe puis 12 s relevées) donne
le même effondrement avec et sans lui. C'est **le Familier qui rejoue le Serpent** : 24 serpents
et 288 plaques au sol sans lui, 48 et 580 avec.

| mesuré | sans Familier | avec Familier |
|---|---|---|
| au départ | 60 à 113 img/s | **5,4 à 6 img/s**, 8 pas de physique par image |
| rastérisation dans `_process()` | — | 6,2 à 6,9 img/s ; pas de physique 28 → 19-21 ms |
| plaques redessinées à leur rythme | 72 à 77 img/s | **14,5 à 15,5 img/s** ; pas de physique 10 ms |
| budget de peinture des serpents | **162 img/s** | **85 à 98 img/s** ; pas de physique 7-8 ms |

Deux pièges, deux correctifs :

- **La rastérisation des serpents se faisait au pas de physique** (8,4 ms par pas pour 48
  serpents). Le pas dépassait 16,7 ms, Godot enchaînait huit pas par image pour rattraper, et
  chaque serpent se repeignait à chacun — une seule de ces images s'affiche. Déplacée dans
  `_process()`.
- **Les plaques se redessinaient à chaque pas** : 82 ms de `_draw()` par image pour 580. Une
  plaque ne change qu'au pas de ses flammes (9 Hz) ou de ses flocons (10 Hz) et pendant ses
  fondus : `DashTrail._look()` résume son image, et seul un changement la redessine — 9 ms.
  Les décalages d'animation des langues passent en images entières, le fondu en huit paliers.

- **Chaque serpent se rastérisait à chaque image** dès qu'elle durait plus de 1/30 s : 48 ×
  0,6 ms, 29 ms. Choisi par l'utilisateur parmi quatre voies (le Familier sans Serpent, un
  plafond de serpents, laisser ainsi) : **un budget de peinture**, d'abord par seconde de jeu
  (au-delà de 16 serpents, chacun moins souvent), puis par image (ci-dessous). Aucun
  changement de jeu.

Pas de capture : la bête à 10 Hz est à juger en jeu.

**« Ça continue de lagger s'il y en a trop. »** Le banc poussé — des lancers forcés en plus, la
recharge remise à zéro — montre que rien ne borne les deux populations :

| lancers forcés | img/s | serpents | plaques | plaques (physique + dessin) | serpents (physique + peinture) |
|---|---|---|---|---|---|
| aucun | 117 | 48 | 582 | 1,3 ms | 2,1 ms |
| +3/s | 8,8 | 144 | 1 800 | 52 ms | 36 ms |
| +6/s | 4,3 | 294 | 3 600 | 122 ms | 60 ms |

Le budget par seconde de jeu ne tenait pas : le jeu ralenti, chaque image couvre plus de jeu,
et paie plus de corps. Deux bornes, sans rien changer au jeu :

- **un sol ne se pose pas sur un sol** (`DashTrail._laid`) : dans la même case d'un demi-rayon,
  de la même compétence et de la même nature, il ravive celui qui est là. Les sols ne cumulent
  pas leurs coups ; un serpent en laisse ou qui chasse repasse sans cesse au même endroit ;
- **au plus huit corps de serpent repeints par image** (`HellSnake.PAINTED_PER_IMAGE`), chacun à
  son tour — à la place du budget par seconde de jeu.

| lancers forcés | img/s | serpents | plaques |
|---|---|---|---|
| aucun | 105 | 48 | 399 |
| +3/s | **59** | 144 | 825 |
| +6/s | **30** | 288 | 565 |

À 288 serpents, ce qui reste est leur morsure : 8 ms par image, une requête de cercle par
serpent et par pas.

## 10. Trois serpents par lanceur

L'utilisateur : « il faut limiter le nombre d'entités qu'un joueur peut invoquer par skill ;
pour l'instant, trois serpents simultanés — la Couvée atteint la limite en un clic —, les petits
de l'Hydre hors du compte (et plus petits) ; le corbeau qui rejoue a sa propre limite de trois,
six en tout ».

- **`simultaneous = 3`** sur `hell_snake.tres`, compté **par lanceur** : `Player._pose()` passe
  son origine — le joueur, ou le corbeau — à `HellSnake.drop()`, qui tient les serpents de
  chacun dans `HellSnake._broods`. La fiche le dit déjà (« en même temps »).
- **Au-delà, les plus anciens se dissolvent** (choisi parmi « le plus ancien meurt », avec son
  éclat et ses petits, et « lancer refusé ») : le fondu de leur fin, sans morsure, sans sol,
  sans explosion finale ni petits. Relancer replace ses serpents ; ça ne les fait pas éclater.
- **Les petits de l'Hydre à 60 %**, langues comprises (planche 23 sur le Bureau, choisis parmi
  75 %, 60 % sans langue et 50 % sans langue). Le corps prend une échelle (`HellSnake._size`) :
  rayons, écart des anneaux, crâne et yeux — rastérisé à sa taille, jamais étiré. La morsure
  garde son `CONTACT`. `_paint()` rend l'image du corps, pour que la planche la lise.

**Le banc des arbres** (`only=hell_snake`) : le meilleur build passe de ×6,97 à **×3,28** au
paquet et de ×6,06 à **×2,48** au duel ; sans arbre, 178/s → 139/s. Un lancer tous les 1,2 s
pour des serpents de 4 s et plus : sans limite, la Couvée en tenait une dizaine. À régler avec
l'équilibrage, en dernier.
