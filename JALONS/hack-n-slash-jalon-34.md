# Hack'n'slash top-down — jalon 34

Suite des jalons 1 à 33. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 29 septembre 2026.** Le jalon des **arbres de compétence**.

---

## 1. Ce que l'utilisateur a demandé

Se concentrer sur les nœuds de chaque compétence, en en modifiant mais **surtout en en
ajoutant**, sur le modèle de Last Epoch : de la diversité, des nœuds qui **changent la
façon dont le sort se joue** ou qui lui **ajoutent** quelque chose, pas seulement des
nombres.

Tranché avec lui le 29 septembre :

- **Un pool de points par compétence** (option « 1A »), comme Last Epoch.
- **Un pilote** : le système entier, et un seul manuel rempli — le **Maître des
  flammes**. Les autres suivront, un manuel par jalon.

## 2. L'état de départ

Deux à trois nœuds par compétence, tous des nombres (« plus » de dégâts, rayon, durée,
+1 projectile, conversion) ; une grille de 3 × 2 à droite de la racine ; **aucun nœud
ne change la forme** (`Player.cast_slot()`) ; et un seul sac de 20 points par manuel
pour les cases, les passifs et les nœuds. Dans ce sac, un arbre de quinze nœuds ne se
remplit jamais : on en prend trois et on s'arrête.

## 3. L'économie

- **Chaque compétence apprise a son propre pool** : **un point d'arbre par niveau du
  manuel**, 20 au plafond. Déduit, jamais retenu, comme les points du livre. Un sort
  appris au niveau 12 arrive donc avec douze points à placer : on le prend tard, on
  l'oriente tout de suite.
- **Les 20 points du livre** ne servent plus qu'aux cases et aux passifs : ils disent
  *quels* sorts on prend et à quelle force, l'arbre dit *comment* ils se jouent.
- **Un arbre s'ouvre au premier point dans sa case.** `TalentNode.required_points`
  change de sens : ce sont les **points déjà placés dans cet arbre**, comme les paliers
  de Last Epoch — zéro pour la première colonne, et c'est désormais permis.
- Les points restent dans le **même dictionnaire** `Manual.points` (invariant 1) :
  seul le compte change de sac. `points_spent()` ne compte plus les nœuds ;
  `tree_points_spent(cell)` les compte, case par case.
- **Reprendre un nœud** : pas sous un enfant investi, ni sous un nœud plus profond dont
  le palier tomberait. Toujours gratuit.

**Les sauvegardes** : aucune version à monter. Les identifiants retirés tombent déjà
à la relecture (`Item.knows()`). Un arbre relu qui **dépasse son pool ou casse un
palier** est rendu **en entier** : un arbre se replace en quelques clics, et chercher
le nœud fautif coûterait plus cher que ça.

**Les autres manuels** gardent leurs nœuds actuels, paliers ramenés à zéro. Leur arbre
de deux ou trois nœuds se remplit tout de suite avec vingt points : c'est accepté
jusqu'à leur jalon.

## 4. Le vocabulaire des mécaniques

**Une mécanique, un endroit, plusieurs sorts** : chacune est écrite une fois et
servie à qui la veut. Trois leviers, du moins cher au plus cher.

**a. Des nombres de `SkillStats`**, visés par des `TalentLine` ordinaires — le
pipeline ne bouge pas, seule la forme concernée les lit :

| nombre | ce qu'il fait | lu par |
|---|---|---|
| `pierce` | traverse N ennemis avant de finir sa course | `Projectile` |
| `splits` | à la fin de sa course, N éclats partent en étoile | `Projectile` |
| `ground_duration` | laisse un sol brûlant (le sillage de la Ruée ardente, posé sur place) | `Fireball`, `HellSnake`, `Player._on_slew()` pour une aura |
| `end_burst` | explose à la fin de sa vie (rayon) | `HellSnake`, `_dash()` |
| `kill_burst` | un ennemi **embrasé** qu'il tue explose, à 50 % d'un coup (rayon) | `Player._on_slew()` |
| `seek_radius` | le serpent prend l'ennemi le plus proche pour point de chute | `HellSnake` |
| `status_chance_increase` | **devient visable par un nœud** : aujourd'hui seule la compétence le porte | déjà lu |
| `self_burn`, `period` | idem : Immolation en a besoin pour ses échanges | déjà lus |

**b. La transformation** : un seul champ de plus, `TalentNode.shape` — la forme qui
remplace celle de la compétence (vide : aucune). **L'invariant « aucun nœud ne change
la forme » tombe** ; `Skill.KEYWORD_OF_SHAPE` suit la forme du lancer, pas celle de la
compétence. Deux nœuds du pilote s'en servent, sur des formes neuves (météore,
bond). Une combinaison sans effet — Perforation sous Météore — reste permise, comme
dans Last Epoch ; l'info-bulle le dit.

**c. Les déclencheurs** passent par les signaux qui existent : `StatusEffects.slew`
reçoit **la position et les états de la victime** en plus des mots-clés, ce qui suffit
à `kill_burst` (« un ennemi embrasé tué explose »).

Pas de nœud à plusieurs parents ni de nœuds exclusifs : rien dans le pilote ne les
demande.

## 5. Les arbres du pilote — à valider

Les chiffres sont des **premiers réglages** : l'équilibrage se fait en dernier
(jalon 13, §7). « Palier » = points déjà placés dans l'arbre. Chaque arbre offre
**environ 35 points pour 20** : on ne prend pas tout. ⇄ marque un échange.

### Boule de feu

| nœud | palier | pts | effet | parent |
|---|---|---|---|---|
| Attisement *(gardé)* | 0 | 4 | +8 % dégâts plus | — |
| Souffle ardent *(gardé)* | 0 | 3 | +15 % rayon d'explosion | — |
| Vélocité | 0 | 2 | +20 % vitesse de projectile | — |
| Double langue *(gardé)* | 5 | 2 | +1 projectile ⇄ −10 % dégâts | Vélocité |
| Perforation | 5 | 2 | traverse 1 ennemi, explose sur chacun | Vélocité |
| Braises dispersées | 5 | 3 | l'explosion laisse un sol brûlant 1 s | Souffle ardent |
| Fragmentation | 10 | 3 | 1 éclat par point en fin de course, à 40 % des dégâts | Perforation |
| Givre | 10 | 3 | convertit 33 % en froid par point, mot-clé Froid | Attisement |
| Embrasement | 10 | 3 | +30 points de chance d'embraser | Attisement |
| Réaction en chaîne | 15 | 1 | un ennemi embrasé qu'elle tue explose (50 %) | Embrasement |
| **Météore** | 15 | 1 | **tombe du ciel au curseur** : +60 % dégâts plus, +50 % rayon ⇄ +0,4 s de geste, ne voyage plus | Souffle ardent |

### Serpent infernal

| nœud | palier | pts | effet | parent |
|---|---|---|---|---|
| Mue *(gardé)* | 0 | 4 | +8 % dégâts plus | — |
| Longue vie *(gardé)* | 0 | 3 | +20 % durée | — |
| Crocs *(gardé)* | 0 | 2 | ajoute 4 à 9 feu | — |
| Vif | 5 | 2 | +30 % vitesse ⇄ −15 % durée | Longue vie |
| Queue de flammes | 5 | 3 | laisse un sol brûlant derrière lui | Longue vie |
| Chasseur | 5 | 1 | poursuit l'ennemi le plus proche au lieu de rôder | Crocs |
| Couvée | 10 | 2 | +1 serpent par lancer ⇄ −20 % dégâts | Mue |
| Venin | 10 | 2 | convertit 25 % en nécrotique par point, mot-clé Nécrotique | Crocs |
| Mue explosive | 10 | 3 | explose en mourant, rayon 10 par point | Longue vie |
| Hydre | 15 | 1 | l'explosion de mort relâche deux petits serpents (2 s, 40 %) | Mue explosive |

### Immolation

| nœud | palier | pts | effet | parent |
|---|---|---|---|---|
| Fournaise *(gardé)* | 0 | 4 | +8 % dégâts plus | — |
| Brasier *(gardé)* | 0 | 3 | +15 % rayon | — |
| Cœur tiède | 0 | 3 | −20 % brûlure subie | — |
| Pouls lent | 5 | 2 | frappe deux fois moins souvent ⇄ +120 % dégâts plus | Fournaise |
| Embrasement | 5 | 3 | +30 points de chance d'embraser | Brasier |
| Flamme noire *(gardé)* | 5 | 1 | +15 % dégâts plus, convertit 50 % en nécrotique | Fournaise |
| Phénix | 10 | 1 | brûlure subie ×2 ⇄ +40 % dégâts plus | Cœur tiède |
| Cendres vivantes | 10 | 2 | sol brûlant sous chaque ennemi tué | Embrasement |
| Contagion ardente | 15 | 1 | un ennemi embrasé qui meurt dans le cercle explose (60 %) | Embrasement |

### Ruée ardente

| nœud | palier | pts | effet | parent |
|---|---|---|---|---|
| Sillage *(gardé)* | 0 | 3 | +25 % durée du sillage | — |
| Braises *(gardé)* | 0 | 3 | +20 % rayon | — |
| Bûcher *(gardé)* | 0 | 4 | +8 % dégâts plus | — |
| Élan | 5 | 2 | −20 % recharge | Sillage |
| Atterrissage | 5 | 3 | explose à l'arrivée, rayon 10 par point | Braises |
| Voile de flammes | 5 | 2 | 2 s après la ruée : −10 % dégâts subis par point (un buff de ruée, comme la Ruée d'orage) | Bûcher |
| Embrasement | 10 | 3 | +30 points de chance d'embraser | Bûcher |
| Brûle-pavé | 10 | 2 | sillage ×2 durée ⇄ −30 % dégâts | Sillage |
| **Bond** | 15 | 1 | **un saut** : plus de sillage ⇄ explosion d'arrivée +150 % dégâts plus, rayon +50 % | Atterrissage |

**Ce que ces arbres demandent de neuf** : cinq nombres (§4a), la transformation, le
signal `slew` élargi, et **trois visuels** — le météore, le bond, les éclats — qui
passent chacun par `/dessiner-un-effet`. Le sol brûlant et l'explosion d'arrivée
réutilisent le sillage et `Explosion`.

## 6. L'interface

Un arbre de dix nœuds ne tient pas sur la page du manuel, qui en montre six. **La page
d'arbre existait déjà** (clic sur une case) : elle garde sa place, et **la fenêtre
descend jusqu'aux jauges** tant qu'un arbre est ouvert. Grille de quatre colonnes —
les paliers 0 / 5 / 10 / 15 — sur quatre rangées, écart de 12 px pour tenir dans les
210 px de large ; l'en-tête annonce le pool **de l'arbre**. Vu sur capture fenêtrée.

**Repris ensuite** (§6 octies) : la pastille par sorte de nœud, les pertes en rouge,
et la ligne « Demande » qui dit tout ce qui manque.

## 6 bis. Ce que la capture et la campagne ont corrigé

- **Un lien ne saute pas de colonne.** Sur la première capture, « Mue → Couvée »
  passait sous « Vif » et se lisait « Mue → Vif → Couvée ». Chaque parent est donc
  dans la colonne précédente (`test_each_parent_sits_in_the_previous_column`), ce qui
  a déplacé des parents et ajouté deux nœuds pour boucher les trous : **Ardeur**
  (Boule de feu, chance critique) et **Onde de choc** (Ruée ardente, rayon de
  l'explosion d'arrivée). Les tables du §5 sont la proposition ; le contenu en jeu
  est dans `docs/CATALOGUE.md`.
- **Voile de flammes** demandait un buff porté par un nœud, que rien ne sait faire :
  remplacé par **Tison** (+12 % dégâts accrus contre les embrasés). Sa ligne débordait
  la fiche de survol de 4 px — élargie de 170 à 176.
- **Une seule part pour les explosions des tués**, 50 % : Contagion ardente ne fait
  pas exception.
- **« Embrasement » est la clé de traduction de l'état** : les trois nœuds de chance
  d'état s'appellent **Étincelles**.
- **Une transformation apporte les nombres de sa forme** : le trait d'essai devenu
  nova ne frappait rien, faute de rayon.
- Les profils du banc gardent un point de livre : leur nœud paie désormais sur son
  arbre. `test_all_points_are_placed` vérifie que l'ordre du profil est pris en
  entier, plus que le livre est vide.

## 6 bis bis. Chaque nœud dit ce qu'il fait

Demandé par l'utilisateur après la première livraison : « on ne comprend pas ce que ça
fait ». Les lignes d'un nœud disent **de combien** — « +24 rayon de l'explosion des
tués » —, jamais qui explose ni quand. `TalentNode.description`, en tête de la fiche de
survol, le dit en une ou deux phrases ; les chiffres des mécaniques y sont lus sur
`SkillStats.facts()`, les constantes mêmes qui les appliquent. Obligatoire dans un
arbre repris. Relues contre le code avant livraison : trois disaient faux (l'éclat qui
« épargne » un ennemi que son explosion touche encore, le Pouls lent « à dégâts par
seconde égaux », le Givre qui transit dès le premier point).

## 6 quater. La conversion, tout ou rien

Demandé par l'utilisateur sur capture : la Boule de feu gelée à 100 % s'affichait
« Projectile · Feu · Froid », et sa fiche annonçait une chance **d'embraser**. Une
conversion est désormais **tout ou rien** — un point, une par arbre — et **change la
nature du lancer** dans `Skill.resolve()`, avant le filtre des mots-clés : le sort
converti est un sort de sa nouvelle nature comme un autre (mot-clé, affixes, état,
couleur, chance d'état de sa fiche). Ce qu'un objet ajoute garde sa nature. Retirés :
les parts converties, `SkillStats.conversions`, `apply_conversion()`,
`dominant_nature()` — devenu `nature` —, et `TalentNode.added_keywords`, qui ne servait
qu'à donner le mot-clé d'arrivée. Givre et Venin passent à un point. Vu sur capture :
la boule gelée vole bleue, cœur blanc chaud comme toutes les boules.

## 6 quinquies. Le serpent n'est pas un projectile ; le sol dure 2 à 5 s

Demandé par l'utilisateur : Vif et Couvée visaient `projectile_speed` et
`projectiles`, ce qui faisait croire que les affixes de projectile touchaient le
serpent. Ils visent désormais **ses nombres à lui** — `crawl_speed`, `brood` — et
l'Hydre `hatchlings` au lieu de `splits` (« nombre d'éclats » pour des petits serpents).
Un test refuse un nombre de projectile sur ce qui n'en est pas un. Et le sol brûlant de
ses nœuds part de **2 s au premier point pour 5 s au troisième** : `TalentLine.first_point_bonus`,
0,5 au premier point et 1,5 par point. Cendres vivantes passe à trois points comme les
deux autres.

## 6 sexies. Le sillon de la Ruée ardente, aussi large qu'il frappe

Signalé par l'utilisateur : Braises (+20 % de rayon par point) « ne fait rien, ou se
voit très mal ». Le couloir qui frappe grandissait bien (32 → 51 px de large à 3/3), mais
le sillon de feu était **une file unique** de brûlures 7×5 et de langues à ±3 px — une
dizaine de pixels, le tiers du couloir même sans nœud.

**La planche** (`Bureau\hns-captures-sillon-ruee\1-sillon-largeur.png`) : l'actuel et
cinq partis pris à deux rayons, le couloir en pointillés. Première version ratée,
refaite avant de la montrer : un lit de brûlures rectangulaire rangé en briques se
lisait en tapis, des files régulières en palissade, un semis libre en paquets.
**Choisi : 6, « cœur et franges »** — l'axe d'aujourd'hui, et de petites langues semées
jusqu'au bord sur un lit qui s'effiloche.

**En jeu** : les franges sont semées sur une grille dérangée (une langue par case de
8 px au plus) plutôt que par rejet, pour un coût linéaire. Tiré une fois à la naissance :
**0,17 ms** au rayon 16 (141 planches), **0,32 ms** au rayon 25,6 (281). Le sol brûlant
en hérite — un disque au lieu de quatre langues empilées — : **60 plaques à l'écran,
165 img/s**, comme sans. Captures : `Bureau\hns-captures-sillon-ruee-jeu\`.

## 6 septies. La chance d'état ne regarde plus la part du coup

Signalé par l'utilisateur : à physique ajouté égal (1–6), la Ruée ardente saignait à 4 %
et le Serpent à 2 %. La chance était 20 % **fois la part de la nature dans le coup** : le
même physique, noyé dans un plus gros coup de feu, pesait moins. Comparé à PoE — chance
fixe par coup dans PoE 1, seuil de PV pour les états élémentaires de PoE 2 —, cette part
était une invention à nous. Choisi avec l'utilisateur : **20 % par nature présente, plus
la part des PV max retirée**, qui existait déjà et suit les dégâts réels. Accepté en
connaissance de cause : un objet qui ajoute un peu de chaque nature pose tous les états,
faibles. La base se réglera avec l'équilibrage.

## 6 octies. Ce qui restait : banc, planches, Ignition, lisibilité

**Le banc de combat** (`world/stress_test.tscn` patché sur une copie, 300 ennemis tenus,
5 paires alternées de 1 440 images après 240 de chauffe) : la Boule de feu nue contre la
même au maximum de son arbre — Double langue, Perforation 2, Fragmentation 3, Braises
dispersées 3, Étincelles 3, Réaction en chaîne. Au pic, **59 tirs en vol contre 24,
20 plaques de sol, 11 explosions**. **165 img/s des deux côtés, physique 5,76 → 6,40 ms
en moyenne (+0,6 ms), 7 % du temps figé des deux côtés.**

**Trois planches** (`Bureau\hns-captures-formes-feu\`), choisies par l'utilisateur :
- **Météore, « crinière »** — la boule tombe droit du ciel en 0,45 s, trois langues
  dressées au-dessus d'elle, une ombre tramée qui grandit au sol, puis l'éclatement de
  la boule (`Fireball.burst()`, sorti de `Fireball` pour servir aux deux). Nouvelle forme
  `METEOR`. À la capture, l'ombre au réglage d'une aura disparaissait sur la terre
  sombre : poussée à 0,6. Le rocher de la première planche se lisait en bougie sur un
  caillou, remplacé avant de la montrer.
- **Bond, « arc et cratère »** — la ruée reste instantanée ; un arc de bouffées qui
  s'éteint depuis le départ, un cratère de brûlures à l'arrivée (`LeapArc`, décoratif :
  la morsure est l'explosion d'arrivée). Nouvelle forme `LEAP`.
- **Éclats, « mini-boule »** — une boule de sept pixels et deux bouffées
  (`EffectForge.SHARD`, `Fireball.is_shard`), au lieu de la boule entière.

**L'arbre d'Ignition.** Un buff n'a pas de nombres de lancer à viser. Une règle, sans
champ neuf : **sur une compétence qui pose un buff, la ligne d'un nœud qui ne vise pas un
nombre du lancer est une ligne de ce buff** (`Skill.is_buff_line()`), aux règles d'un
passif, versée par `Player.buff_mods()` tant qu'il brûle. La brûlure d'un buff se lit
désormais sur le lancer résolu, pour que Cendres froides et Feu dévorant comptent. Neuf
nœuds, 21 points pour 20.

**La lisibilité de l'arbre** : une pastille violette sur une transformation, orange sur
un nœud de mécanique (`SkillStats.MECHANICS`), la sorte dans le sous-titre de la fiche ;
**les pertes en rouge** (`StatMod.is_loss()`, avec `LOWER_IS_BETTER` — une recharge qui
baisse est un gain) ; **tout ce qui manque** sous « Demande », et non le premier manque.

## 6 nonies. Un réseau plutôt que des couloirs, sans paliers

**La demande** : à l'usage, les arbres étaient trois couloirs parallèles — un parent par
nœud, une colonne par palier. Fragmentation ne servait à rien sous Météore, et Météore
n'était accessible qu'en passant par la conversion en froid. L'utilisateur veut le
système de Last Epoch (capture de l'arbre de « Rive » à l'appui), **paliers compris
retirés**.

**La règle** (`Manual._node_open()`) : `TalentNode.parent` et `required_points`
disparaissent au profit de `parents`, un dictionnaire nœud → points demandés. **Un seul
lien payé suffit.** La profondeur, ce sont les liens et leurs points, dessinés en grains
sur le lien comme les « ••• » de Last Epoch. Deux gardes, parce qu'un réseau peut
mentir là où un arbre ne le pouvait pas : **pas de boucle** (`test_links_lead_to_the_root`
— deux nœuds reliés l'un à l'autre se tiendraient ouverts, et l'arbre se reprendrait
sous eux) et **pas de lien sous un nœud** (`test_nodes_and_links_do_not_overlap`).

**La fenêtre, choisie sur planche** (`hns-captures-arbre-reseau`, quatre variantes :
centre en cases, centre en pastilles, centre élargi, gauche vers droite) : **« centre,
élargi »** — la compétence au centre, les nœuds de 28 px autour, sept colonnes sur trois
rangées. La fenêtre passe de 210 à 300 px le temps de l'arbre, **vers la gauche** : à
droite, le sac l'aurait couverte. **Vu à la capture** : les liens transparaissaient à
travers les nœuds, dont le fond est à 0,9 d'opacité — un fond plein dessous. « 2 points
dans « Cendres vivantes » » débordait la fiche de 11 px (`test_largeurs`) : la ligne dit
« « Cendres vivantes » à 2 ».

**Les transformations gardent leur arbre.** Sous Météore, Double langue fait tomber
**une rangée** de météores en travers de la visée, et Fragmentation
fait jaillir l'étoile d'éclats **du point d'impact** (`Projectile.split()`, rendue
publique). Ce qui reste sans effet — Perforation sous Météore ; Sillage et Braises,
la traînée, sous Bond — est déclaré une fois dans `Skill.IGNORED_BY_SHAPE`, et la fiche
du nœud l'écrit en rouge, « sans effet avec Météore », avant qu'on paie. Choix de
l'utilisateur, plutôt qu'un effet inventé.

**Les cinq arbres de feu refaits en réseau** (positions et liens dans `fire.tres`,
lignes inchangées) : trois nœuds reliés au sort — à gauche la puissance et la
conversion, en haut la zone, à droite le vol ou la mécanique —, des nœuds à deux liens
aux carrefours (Étincelles, Fragmentation, Météore, Hydre…). **Météore** s'ouvre par
Attisement à 3 ou Double langue à 1 ; **Givre** est une branche de côté, plus un passage.
Les autres manuels, pas encore repris, ont été convertis tels quels : leur parent devient
un lien à 1 point, leurs nœuds glissent d'une case à droite du sort.

## 6 decies. Le sol d'une compétence convertie

**La demande** : la Boule de feu gelée ou le Serpent passé au Venin laissaient un sol
qu'on ne voyait pas — hors du feu, `DashTrail` ne traçait qu'un trait et deux taches
de lumière à 0,3, et un sol sans longueur n'a pas de trait.

**Choisi sur planche** (`hns-captures-sols-convertis`, trois pistes par nature, le sol
brûlant en référence) : **« givre et flocons »** pour le froid, **« taches et spores »**
pour la nécrose. Le lit de brûlures, repris dans la rampe de la nature ; un halo tramé
dessous ; des flocons ou des spores qui montent de huit pixels et recommencent. Écartés :
le champ de cristaux (haut, il cachait ce qui s'y tient), la plaque de glace et la
flaque de bile — en traînée, chaque plaque gardait son contour et le serpent laissait
une pile de pièces.

**Vu à la capture** (`hns-captures-sols-convertis-jeu`) : sans ennemi, le serpent tourne
sur place et repasse sur ses plaques ; à la densité des brûlures, les taches claires et
cernées faisaient un tapis. `STAIN_DENSITY` les divise par deux — la cendre, sombre,
se lisait en terre brûlée, pas elles.

**Et sous les corps.** `DashTrail` se relevait à `z_index` 2, au-dessus de tout corps :
on marchait sous sa propre traînée (remarqué par l'utilisateur). Traînées et sols vont
désormais sur la couche `Ground` de la scène, entre le sol et les corps, déjà celle des
zones de danger (`test_a_trail_lies_under_the_bodies`).

## 6 undecies. L'explosion des tués suit la conversion

Contagion ardente (Immolation) et Réaction en chaîne (Boule de feu) ne faisaient
exploser que les **embrasés** : sous Flamme noire ou Givre, le lancer ne pose plus
l'embrasement, et le nœud ne faisait plus rien. Un tué explose désormais s'il porte
**l'état que tire la nature du lancer** (`StatusEffects.rolled_by()`) — pourrissant
pour un brasier nécrotique, transi pour une boule de glace. Les descriptions le disent.

## 6 duodecies. Un Météore qui vaut d'être pris

**Le constat de l'utilisateur** : il ne servait à rien. Le calcul le confirme : +60 %
de dégâts pour +60 % de temps de lancement, soit **les mêmes dégâts par seconde** que
la boule, contre un retard de 0,45 s et la perte du vol — pour un rayon de 30 au lieu
de 20.

**Choisi par l'utilisateur, « frappe lourde »** : +150 % de dégâts plus (≈ +55 % de
dégâts par seconde sur la boule), **rayon doublé** (40), et l'impact se sent — gel
d'impact et secousse de deux fois celle d'un lancer. Le prix reste le lancement plus
long et la chute. Une rangée de Double langue espace ses météores d'un rayon : à
l'écart fixe de 28 px d'avant, des explosions de 40 se couvraient presque entières.

**Le dessin, choisi sur planche** (`hns-captures-meteore-gros`, quatre variantes : grosse
boule, rocher en feu, comète, boule croûtée) : **« grosse boule »**, 21 px au lieu de 13,
une crinière de cinq langues. Rastérisée sur la planche puis relevée en grille dans
`EffectForge.METEOR`. **Vu sur la planche** : lisse et le cœur centré, elle sortait en
ballon de plage — bord bosselé, cœur en deux taches.

## 6 ter. Relevé d'équilibrage, avant → après

`tests/run.sh balance`, sur le commit du jalon 33 puis ici : **les quatre mêmes tests
échouent**. Le sort ne bouge pas en coups. **La mêlée frappe environ 25 % plus fort** —
son nœud « Élan » est désormais au plafond, payé par son arbre (1,05 → 0,92 coup en
zone 1, 19,5 → 14,8 en zone 90), et un couloir de plus sort par le bas : Mêlée Équipé
en zone 20, trivial (0,49 coup). Non corrigé : l'équilibrage se fait en dernier.

## 7. Le déroulé

**Fait** : 1 à 5, l'arbre d'Ignition, et le réseau sans paliers (§6 nonies).
**Reste** : l'équilibrage, en dernier — les liens rendent les nœuds profonds bien moins
chers qu'aux paliers (l'Hydre : 5 points au lieu de 15).


1. **Ce document**, et la validation des arbres du §5 par l'utilisateur.
2. **Le moteur** — l'économie, la relecture des sauvegardes, les nombres, la
   transformation, le signal — **sans contenu neuf** : la campagne doit passer avec
   les arbres actuels, paliers ramenés à zéro.
3. **La fenêtre d'arbre**, sur capture.
4. **Les quatre arbres**, puis les trois visuels sur planche.
5. **`/valider`** : la campagne ; le banc de combat — perforation, éclats et
   explosions en chaîne multiplient les coups ; `tools/catalog.sh` ;
   `tests/run.sh balance` relevé avant → après, sans correction. ARCHITECTURE
   (lignes « Que pose un lancer », « Combien de points », « Peut-on le reprendre »)
   et RECETTES (« Ajouter un nœud de talent ») dans le même geste.
