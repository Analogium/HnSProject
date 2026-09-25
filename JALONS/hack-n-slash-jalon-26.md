# Hack'n'slash top-down — jalon 26

Suite des jalons 1 à 25. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 25 septembre 2026.** Le jalon du **manuel de magie nécrotique** : le
sixième livre, et le premier à porter des **alliés** — des invocations qui se
battent pour le personnage.

Livré en deux lots : la mécanique entière (§1 à §6), puis le dessin, choisi sur
planche geste par geste, et les icônes (§7).

---

## 1. Ce que l'utilisateur a demandé

| Compétence | Mots-clés | Ce qu'elle fait |
|---|---|---|
| **Peste** (*Plague*) | Sort, Projectile, Nécrotique | Un projectile plutôt lent, un peu moins de dégâts à l'impact que les autres sorts ; il pose **Décomposition** (*Decay*) à tout ce qu'il touche |
| **Relève** (*Rise*) | Invocation, Nécrotique | Deux morts-vivants qui restent jusqu'à leur mort, gardent une zone autour du joueur et frappent en nécrotique |
| **Déferlante toxique** (*Toxic unleash*) | Sort, Zone, Nécrotique, Dégâts continus | Une explosion de gaz autour de soi ; une chance sur deux de poser **Flétrissement** (*Wilting*) |
| **Porte pourrissante** (*Rotting gate*) | Invocation, Nécrotique, Zone | Un portail qui crache de petites créatures ; elles s'amassent, puis vont exploser sur l'ennemi le plus proche quand il entre à portée. L'explosion suit le rayon |
| **Malédiction putride** (*Putrid curse*) | Zone, Malédiction | Instantanée sur une zone : les touchés perdent **20 points de résistance nécrotique**, cinq secondes |
| **Nécrose avancée** (*Advanced necrosis*) | — | Un buff qui ronge **1 % des PV actuels** par seconde et accroît la chance de pourrir de 30 % |

Et une règle générale : **ce qu'une invocation inflige, c'est le personnage qui
l'inflige.** Sa pourriture soigne le joueur, pas le mort-vivant.

## 2. Deux états qui brûlent, posés par un lancer

Jusqu'ici **une nature pose exactement un état**, tiré à chaque coup. Décomposition et
Flétrissement ne sont pas tirés par leur nature : c'est **le lancer** qui les pose
(`Skill.inflicted_state`, `inflict_chance`). D'où la séparation de
`StatusEffects` en deux : `ROLLED`, les six que tire un coup, et les autres, que pose
un lancer ou une malédiction. `NATURES` couvre maintenant tous les états — c'est la
couleur et la part brûlée —, et le test « une nature, un état » ne regarde plus que
`ROLLED`.

**Ce qu'ils brûlent se calcule comme l'embrasement** : une part de ce que le coup a
porté dans sa nature, **après** défenses. C'est ce qui fait qu'ils suivent le niveau
du sort — la table de dégâts —, ses accrus, et la malédiction posée avant. Décomposition
rejoue 100 % du coup sur ses quatre secondes, Flétrissement 80 %.

**Leurs à-coups pourrissent.** Toutes les demi-secondes (`DOT_TICK`, l'horloge des
paquets affichés), chacun tire la pourriture comme le ferait un coup entièrement
nécrotique : 20 %, fois la chance de l'auteur. Un tirage par à-coup, qu'il réussisse
ou non (invariant 3). La pourriture posée ainsi part de l'à-coup, donc elle est
petite — c'est son rôle : du soin qui s'entretient.

## 3. La malédiction

Un troisième état, **Maudit**, sans brûlure : il retire 20 points à la résistance
nécrotique, **avant le plafond** (`CharacterStats.resistance()`), donc un ennemi à 0 %
passe à −20 %. Lu par `Hurtbox.mitigate_part()` au moment du coup, pas écrit dans la
fiche de l'ennemi — souvent le `.tres` partagé (invariant 2).

La malédiction ne frappe pas : elle ne passe donc pas par `Hurtbox.take_damage()` — un
coup de zéro prendrait le plancher d'un point et pourrait être esquivé. Elle pose
l'état directement. C'est la seule exception au point de passage unique des états.

## 4. Les alliés

**Relève** fait naître des `Minion` : un corps (`actors/skills/minion.tscn`) avec sa
hurtbox sur le calque **du joueur** — les tirs des casters les touchent sans rien
changer à leur scène, et leurs blessures ne comptent pas dans le DPS du joueur.

- **La zone gardée** est le `radius` de la compétence, autour du joueur : un nœud
  « rayon » l'agrandit. Hors combat, ils suivent le joueur ; trop loin (une ruée),
  ils le rejoignent d'un coup.
- **Leur coup** est un lancer du joueur : `cast.roll()`, auteur = les états du joueur,
  lancer = celui de la Relève. Le critique, la pourriture et le compteur de DPS
  suivent donc sans une ligne de plus.
- **Leur vie** : la moitié des PV max du lanceur au moment de la levée
  (`Minion.LIFE`). Premier réglage.
- **Le plafond** est `simultaneous` (2) ; relancer relève ceux qui manquent, et une
  Relève au complet est **refusée**, comme l'orbite pleine.
- Un livre qui quitte le râtelier les fait tomber, comme il éteint un buff.

**Les ennemis les attaquent** : `Enemy.foe()` rend le plus proche du joueur et des
morts-vivants. Le grunt frappe celui-là, le caster tire sur celui-là. La marche suit
toujours le champ de flux, qui mène au joueur — les morts-vivants sont à côté.

**Les créatures de la Porte** ne sont pas des `Minion` : les ennemis ne les ciblent
pas, elles ne vivent que pour exploser. Ce sont de simples positions que le portail
fait avancer et dessine lui-même. Elles s'amassent autour de lui — sans plafond : la
durée sur la période en borne déjà le nombre, huit, et une ligne de plus faisait
déborder la fiche de cinq pixels —, foncent sur l'ennemi le plus proche à portée de
vue (`SIGHT`), et
explosent au contact par `Explosion.put()` — le souffle de la nova, au `radius` de la
compétence. Le portail refermé, celles qui restent tombent avec lui.

## 5. Ce qui a été tranché sans l'utilisateur

À revoir sur pièce ; aucun n'engage la suite.

- **Nécrose avancée** : +10 % de chance de pourrir **par point**, trois points — les
  30 % demandés au maximum. Le prix se lit en « PV actuels » : il ne tue jamais.
- **Malédiction putride** : un seul point, puisque rien n'y grandit. Elle garde le
  mot-clé « Sort » de sa cadence, comme la Relève — tout ce qui s'incante l'a.
- **Dégâts continus** n'est porté que par la Déferlante, comme demandé ; la Peste ne
  l'a pas, bien que sa Décomposition soit un DoT.
- **Les nœuds de talent** sont venus ensuite, §8.
- **Quatre mots-clés, quatre affixes** : un mot-clé affiché doit être visé. *de la
  Putréfaction* (dégâts nécrotiques), *du Nécromant* (dégâts d'invocation), *de
  l'Anathème* (rayon des malédictions), *de la Gangrène* (dégâts continus).

## 6. Ce que ça coûte

Trois boucles chaudes ont bougé : `StatusEffects.advance()` (l'à-coup), la
mitigation (la malédiction) et le tick ennemi (`Enemy.foe()`). Mesuré le 25 septembre
2026 sur `world/stress_test.tscn`, 300 ennemis en combat, fenêtré, 240 images de
chauffe puis 1 440 mesurées, **sept paires en alternance** avant / après : **5,30 ms**
de physique contre **5,46**, pour un écart d'environ 0,4 ms entre deux tirs du même
arbre ; 165 img/s des deux côtés. Dans le bruit. Une première paire isolée montrait
+0,7 ms : c'était la dérive, et une variante qui *retirait* `foe()` est sortie plus
lente encore.

## 7. Le manuel nécrotique, dessiné — 25 septembre 2026

Planches et captures dans `hns-captures-necrotique` et `hns-captures-necrotique-jeu`,
sur le Bureau.

### Ce qui s'est choisi sur planche

| Planche | Choisi | Écarté |
|---|---|---|
| `01` la Peste en vol | **le crâne de fumée**, orbites qui palpitent | bulle grumeleuse, nuée de spores, glaire qui goutte, orbe noir |
| `02` le mort-vivant | **le squelette nu** | soldat en armure rouillée, revenant encapuchonné, zombie livide |
| `03` la Déferlante | **le mur de gaz bosselé** | couronne de nuages, nappe tramée, spirale, volée de crânes |
| `04` la Porte | **la faille de chair debout** et **la bulle à yeux** | fosse, arche, gueule ; asticot, diablotin, crâne sur pattes |
| `05` la Malédiction | **l'œil qui s'ouvre** au-dessus d'une nappe cerclée | sceau runique, spirale, crâne qui s'abat |
| `06` les états | **bulles** (décomposition), **fleur fanée** (flétrissement), **œil** (maudit) | goutte, crâne effrité ; fiole ; étoile, spirale |
| `07` la Nécrose | **des spores qui montent** | gouttes qui tombent, volutes aux pieds |
| `08`–`09` les icônes | tirées par moi à la demande de l'utilisateur, au plus près des gestes choisis ; le livre, **D2** | — |

Deux variantes de la planche du mort-vivant ont été refaites **avant** d'être montrées :
la goule et le premier zombie étaient aussi verts que le grunt, et un allié qu'on ne
distingue pas d'un ennemi dans une mêlée est un défaut, pas un parti pris. D'où le
squelette : c'est **l'os**, plus que les orbites, qui le sépare.

### Ce que les captures ont corrigé

- **La malédiction était invisible** : posée en `z_index` −1 pour passer sous les corps
  qu'elle maudit, elle passait aussi sous le sol. Tous les effets du jeu se dessinent
  au-dessus des acteurs, halos au sol compris ; une nappe tramée s'y lit très bien.
- **Le mur de gaz sortait en collier** : les bosses de la planche, espacées de 11 px,
  laissaient des trous qu'on ne voyait pas à ×4. Resserrées, il sortait en **perles**,
  chaque disque prenant son éclairage ; en capsules d'une bosse à la suivante, en
  **tore lisse** — un néon. Le mur retenu : le tore, plus une bouffée sur le bord
  extérieur une bosse sur deux.

### Ce que ça coûte

Au premier passage d'un rayon, puis plus rien (cache par teinte, rayon et cran) :

| Rastérisé | Avant | Après |
|---|---|---|
| mur de gaz, pire cran, rayon 48 | 2,85 ms d'un bloc | **2,1 ms** en quadrants, capsules et bouffées comprises |
| cercle maudit, un cran, rayon 48 | 3,0 ms | **1,1 ms** |
| `EffectForge.dissolve()`, anneau de 113 px | 1,1 ms | natif, négligeable |

D'un bloc, `to_image()` balayait tout l'intérieur vide de l'anneau (1,2 ms au rayon
48) et la dissolution posait un `set_pixel()` par pixel (1,1 ms). Essayé en route : huit
secteurs rognés **par angle**, pixel par pixel — 6,9 ms, le rognage en GDScript coûtant
plus que le vide qu'il évitait. Les planches fixes coûtent 0,07 à 0,23 ms chacune, une
fois par teinte.

## 8. Les nœuds de talent — 25 septembre 2026

Le gabarit des autres livres — une racine, son enfant, une seconde racine en rangée
2 —, et ce qui est propre à la nécrose : les **dégâts contre un état** existaient déjà
pour chaque état (`damage_vs_<id>`), ils font des synergies sans une ligne de code.
Rien sur la Nécrose avancée : un nœud ne vise qu'un nombre de lancer, et un buff n'en a
pas.

| Compétence | Nœuds |
|---|---|
| Peste | **Virulence** +13 % de dégâts « plus » (3) → **Condamnation** +20 % contre les maudits (2) ; **Contagion** +1 projectile (1, à 3 points) |
| Relève | **Moelle** +12 % « plus » (3) → **Guet** +20 % de rayon gardé (2) ; **Légion d'os** +1 mort-vivant (1, à 3 points) |
| Déferlante toxique | **Miasme** +20 % de rayon (2) → **Caustique** +14 % « plus » (3) ; **Dessiccation** +25 % contre les flétris (2) |
| Porte pourrissante | **Couvée** +25 % de durée, donc de créatures (2) → **Boursouflure** +20 % de rayon d'explosion (2) ; **Essaim** +12 % « plus » (3) |
| Malédiction putride | **Anathème** +25 % de rayon (2) → **Malédiction prompte** −15 % de temps d'incantation (2) |

Deux arbitrages dictés par la largeur de la fiche d'un nœud : « Dégâts contre les
décomposés » débordait de 15 px en français et 7 en anglais — le nœud de la Peste vise
donc **les maudits**, ce qui la lie à la Malédiction ; et « Anathème étendu » faisait
déborder la ligne « Demande le talent … » de son enfant. 54 destinations de points
pour 20 gagnés.

## 9. La route nécrotique de l'arbre de passifs — 25 septembre 2026

Vingt nœuds pour ce que le livre fait vivre : dégâts nécrotiques, sorts nécrotiques,
invocations, malédictions, dégâts continus. La zone n'y est que par les notables : six
clusters la portent déjà, et un septième la délayerait.

**La couronne était pleine.** Toutes les poches du haut sont encloses par un cluster ou
une chaîne, et une seule jonction de l'anneau extérieur était libre, sur une zone déjà
prise. Le tracé a été cherché **par le calcul**, contre les règles exactes des tests :
deux cases au moins entre deux nœuds, aucun lien croisé, une case entre un nœud et un
lien voisin (le plus serré : 1,34). La route part de `far_int_dex_1`, monte par le seul
couloir restant — une case de chaque côté, entre « Paratonnerre » et « Souffle
élargi » —, longe le haut de l'arbre à y = −48/−49 et descend dans les deux poches du
coin supérieur droit, sous la chaîne « Courant en arc » et au-dessus de
« Coordination ».

| Où | Nœuds |
|---|---|
| La montée, `rot_1`–`3` | +10 % de dégâts nécrotiques ×3 |
| **Nécromancie** | +15 % nécrotiques, +10 % de sort — les sorts nécrotiques |
| `grave_1` | +10 % de chance de pourrir |
| L'ossuaire, `ossuary_1`–`6` | +10 % de dégâts d'invocation ×4, +6 % de rayon aux invocations ×2 |
| **Seigneur des morts** | +15 % de dégâts d'invocation, +15 % de rayon — la zone que gardent les morts-vivants, et le souffle des créatures |
| `grave_2` | +10 % de dégâts continus |
| Le maléfice, `hex_1`–`6` | +10 % de dégâts continus ×3, +6 % de rayon aux malédictions ×2, +10 % de chance de pourrir |
| **Malemort** | +15 % de dégâts continus, −10 % de temps d'incantation des malédictions |

Pas de « +1 mort-vivant » : le maximum simultané visé par la portée `summon` atteindrait
aussi la Porte, qui n'en a pas — sa fiche annoncerait « 1 en même temps », faux. C'est
le nœud Légion d'os de la Relève qui le porte.

Icônes : le crâne pour le nécrotique et la chance de pourrir, l'œil de la malédiction,
les bulles de la décomposition pour les dégâts continus — les masques des états —, et
une pierre tombale pour l'invocation. Vu à la capture (`hns-captures-necrotique-arbre`) :
au zoom large, la rangée du haut passe sous le titre du panneau, comme les nœuds à −46
touchaient déjà la ligne d'aide ; au zoom normal, rien ne déborde.

