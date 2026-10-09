# Hack'n'slash top-down — jalon 44

Suite des jalons 1 à 43. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 8 octobre 2026.** Les arbres du **manuel du froid** repris comme ceux des
flammes (jalon 42) et de la foudre (jalon 43). C'est le dernier manuel hors de
`UNIQUE_TREES` : une fois fini, la constante disparaît et la règle devient celle de tous
les arbres (jalon 42, §2).

---

## 1. Ce que l'utilisateur a demandé

« Comme dans le jalon précédent avec le manuel de la foudre, j'aimerais maintenant faire le
manuel de glace. » Les demandes du jalon 42, §1, valent telles quelles : un peu plus de
nœuds, aucun nœud qui revient d'un arbre à l'autre, des nœuds originaux par compétence, des
**suites** derrière ce qui change le jeu, quelques interactions, quelques leviers simples —
et une vignette par nœud (jalon 42, §14), arbre par arbre.

## 2. La règle du jalon

Celle du jalon 42, §2 : **aucun nom ni aucune ligne** ne revient d'un arbre à l'autre, sauf
un nœud de dégâts, de rayon et de durée par arbre, et les échanges entiers. Une suite n'a
qu'un parent, et ne lit que des nombres que ce parent fait servir. Un nom ne double pas un
autre manuel.

**Cible** : 13 à 21 nœuds par arbre, 30 à 40 points pour un pool de 20, deux à quatre nœuds
que seule la compétence a, une à deux suites par nœud qui change le jeu. Le froid n'a que
**quatre** arbres (la foudre et les flammes cinq) : une interaction dans deux arbres au plus.

Inspirations relevées : dans PoE, la *Glacial Cascade* qui perce en ligne, le *Frost Bomb*
qui éclate après coup, l'*Arctic Armour* qui gèle le sol sous les pas ; dans Last Epoch, le
*Glacier* dont un lancer sur trois perce plus grand, le *Frost Wall* ; dans Diablo II, la
*Chilling Armor* qui transit qui la frappe, la *Frozen Orb* ; dans Hero Siege, le
*Blizzard* qui grossit ; dans Torchlight Infinite, le gel qui se propage d'un mort à
l'autre.

## 3. Le manuel du froid — la proposition

### Ce qui se répète aujourd'hui

| ligne | arbres qui la portent | où elle reste |
|---|---|---|
| Engelure (chance d'état) | les quatre | **Pics** — l'Acharnement en a besoin, et la nova transit déjà à +50 % |
| Froid mordant (effet du transi) | les quatre | **Nova** — « qui transit vite » |
| Bris (explosion des tués) | les quatre | **Nova** — l'arbre de la meute, qu'elle transit d'elle-même |
| Acharnement (contre les transis) | Pics, Nova | **Pics** — le coup visé qui finit ce que la nova a transi |
| Givre persistant (sol) | Pics, Nova | **Nova** — un sol de sa taille, sous soi |
| Réflexe (temps du geste) | Pics, Nova | **Nova** — 1,1 s de geste, le plus lent du manuel |
| explosion finale | Tombeau (Éclatement), Désastre (Avalanche) | **Tombeau** — la glace qui vole en éclats en sortant ; le Désastre garde l'Implosion |

### Noms pris ailleurs

| nom | pris par | devient |
|---|---|---|
| Tranchant | Frappe lourde (chevalier) | **Arête** |

Les autres doublons d'hier (Éclats, Réflexe, Isolant, Sobriété) ont été levés du côté de la
foudre au jalon 43 : le froid les garde.

Conventions du jalon 42 : chiffres de **premier réglage**, « relié à (n) » = points demandés
dans le parent, ⇄ marque un échange, **neuf** = un nombre de `SkillStats` à écrire, 🔗 =
interaction avec une autre compétence, **↳** = suite, accessible par son seul parent.

### Pics de glace — le coup visé *(10 → 15 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| **Arête** *(le Tranchant)* | 4 | +8 % dégâts plus | — |
| Poussée *(gardé)* | 2 | +10 % rayon | — |
| Engelure *(gardé)* | 3 | +15 % chance d'état — **la seule du manuel** | Arête (1) |
| Acharnement *(gardé)* | 3 | +12 % accrus contre les transis — **le seul du manuel** | Engelure (1) |
| Éclats *(gardé)* | 2 | se brisent en éclats en retombant | Arête (2) |
| Sillon de glace *(gardé)* | 1 | transformation : des cercles en ligne | Poussée (2) ou Éclats (1) |
| **Plein centre** *(neuf)* | 3 | **viser juste** : un ennemi dans le tiers central du cercle prend 15 % de dégâts plus par point | Poussée (1) |
| **Réplique** *(neuf)* | 2 | **les pics repercent au même endroit 0,4 s plus tard**, à 25 % du coup par point | Arête (1) |
| **Bosquet** *(neuf)* | 2 | +1 cercle de pics, posé contre le premier, par point ⇄ −20 % plus | Poussée (1) |
| **Glacier** *(neuf)* | 1 | **un lancer sur trois perce un glacier** : rayon ×1,5 et +40 % de dégâts plus | Acharnement (1) ou Plein centre (2) |
| **Cristallisation** 🔗 *(neuf)* | 1 | **des pics percés dans un vortex de Désastre hivernal lui rendent 0,3 s** de durée — le vortex se nourrit du sort qu'on lance dedans | Réplique (1) |
| ↳ **Crevasse** *(neuf)* | 1 | **le bout du sillon s'ouvre** en un cercle de pics deux fois plus large | Sillon de glace (1) |
| ↳ **Grésil** *(neuf)* | 2 | **les éclats s'incurvent** vers l'ennemi le plus proche, à 60 px par point | Éclats (1) |
| ↳ **Secousses** *(neuf)* | 2 | **la réplique se répète** : une de plus par point, à 0,4 s d'écart | Réplique (2) |
| ↳ **Sérac** *(neuf)* | 1 | **le glacier tombe un lancer sur deux** au lieu de trois | Glacier (1) |

*Retirés* : Réflexe (Nova), Givre persistant (Nova), Froid mordant (Nova), Bris (Nova).

### Nova de glace — le froid autour de soi *(9 → 15 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Morsure *(gardé)* | 4 | +8 % dégâts plus | — |
| Souffle *(gardé)* | 3 | +10 % rayon | — |
| Réflexe *(gardé)* | 2 | −10 % temps du geste — **le seul du manuel** | — |
| Froid mordant *(gardé)* | 3 | +10 % effet du transi — **le seul du manuel** | Morsure (1) |
| Givre persistant *(gardé)* | 2 | laisse un sol gelé — **le seul sol du manuel** | Souffle (2) |
| Bris *(gardé)* | 1 | un transi tué explose — **la seule explosion des tués du manuel** | Froid mordant (2) |
| Onde de givre *(gardé)* | 1 | transformation : l'anneau qui s'élargit | Souffle (2) ou Réflexe (2) |
| **Grand froid** *(neuf)* | 3 | **la nova mord plus fort dans la foule gelée** : +4 % de dégâts plus par point et par ennemi transi dans son rayon, cinq au plus | Froid mordant (1) |
| **Frimas** *(neuf)* | 2 | le transi de la nova dure 0,5 s de plus par point | Morsure (1) |
| **Repoussoir** *(neuf)* | 2 | la nova repousse ce qu'elle touche de 30 px par point (`knockback`, déjà lu par `Targets`) | Souffle (1) |
| **Sursaut** *(neuf)* | 1 | **un coup qui vous ôte plus de 10 % de vie fait partir une nova d'elle-même**, une fois toutes les 4 s | Réflexe (1) |
| ↳ **Reflux** *(neuf)* | 1 | **à bout de course, l'anneau revient vers vous** et refrappe ce qu'il croise | Onde de givre (1) |
| ↳ **Gelée blanche** *(neuf)* | 2 | **le gel se propage** : l'explosion d'un transi tué transit ce qu'elle touche, à 50 % de la force du transi du mort par point | Bris (1) |
| ↳ **Glace noire** *(neuf)* | 2 | sur votre sol gelé, **vous glissez** : +8 % de vitesse de déplacement par point | Givre persistant (1) |
| ↳ **Qui-vive** *(neuf)* | 1 | le Sursaut ne demande plus que 5 % de vie, et revient en 2 s | Sursaut (1) |

*Retirés* : Engelure (Pics), Acharnement (Pics).

### Tombeau de glace — l'abri *(10 → 14 nœuds, 32 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Glace épaisse *(gardé)* | 4 | −3 % dégâts subis | — |
| Dégel *(gardé)* | 3 | +20 % soin | — |
| Longue nuit *(gardé)* | 3 | +20 % durée | — |
| Isolant *(gardé)* | 3 | +8 % rés. froid | Glace épaisse (1) |
| Sobriété *(gardé)* | 2 | −25 % mana drainé | Longue nuit (1) |
| Éclatement *(gardé)* | 3 | la glace éclate en sortant — **la seule explosion finale du manuel** | Glace épaisse (2) ou Longue nuit (2) |
| Armure de givre *(gardé)* | 1 | transformation : protège sans enfermer ⇄ −50 % durée | Dégel (2) ou Sobriété (1) |
| **Peau de givre** *(neuf)* | 3 | **qui vous frappe au contact est transi**, à 30 % de force par point — la *Chilling Armor* | Glace épaisse (1) |
| **Hibernation** *(neuf)* | 3 | **enfermé, le temps court pour le reste** : les recharges de vos autres compétences avancent 20 % plus vite par point tant que le tombeau tient | Longue nuit (1) |
| **Refuge** *(neuf)* | 1 | **entrer dans la glace éteint vos états** : embrasé, transi, engourdi, empoisonné… | Dégel (1) |
| ↳ **Halo de givre** *(neuf)* | 2 | sous l'armure, **ce qui passe à 40 px de vous est transi**, une fois par seconde, à 50 % de force par point | Armure de givre (1) |
| ↳ **Hiver sans fin** *(neuf)* | 1 | chaque ennemi tué sous l'armure **lui rend 0,3 s** | Armure de givre (1) |
| ↳ **Cœur de glace** *(neuf)* | 1 | **l'éclatement transit à coup sûr**, à double force | Éclatement (1) |
| ↳ **Brise-glace** *(neuf)* | 2 | **sortir tôt paie** : l'éclatement frappe 25 % plus fort par point et par seconde de tombeau qu'il restait | Éclatement (2) |

*Retirés* : Engelure (Pics), Froid mordant (Nova), Bris (Nova).

### Désastre hivernal — la tempête qui grandit *(10 → 14 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Œil du cyclone *(gardé)* | 4 | +8 % dégâts plus | — |
| Blizzard *(gardé)* | 2 | +20 % durée | — |
| Bourrasque *(gardé)* | 3 | +10 % rayon | — |
| Rafales *(gardé)* | 2 | frappe plus souvent ⇄ dure moins | Œil du cyclone (1) |
| Aspiration *(gardé)* | 3 | attire vers le cœur | Bourrasque (1) |
| Implosion *(gardé)* | 1 | transformation : se resserre, puis éclate | Aspiration (2) ou Blizzard (2) |
| **Boule de neige** *(neuf)* | 3 | **le vortex se nourrit de ce qu'il frappe** : chaque ennemi touché le fait grossir de 2 % par point, au-delà de son plein, 40 % au plus | Bourrasque (1) |
| **Coulée** *(neuf)* | 1 | **le vortex ne reste plus sous vous** : il roule droit vers le point visé, à 50 px/s, et grandit en roulant | Blizzard (1) |
| **Accalmie** *(neuf)* | 2 | **dans l'œil** (le tiers central), vous subissez 8 % de dégâts en moins par point | Œil du cyclone (1) |
| **Givrage** *(neuf)* | 3 | chaque impulsion **renforce le transi** de ce qu'elle touche de 10 % par point, trois fois au plus | Rafales (1) |
| **Supraconduction** 🔗 *(neuf)* | 1 | **le froid conduit** : un engourdi (foudre) pris dans le vortex est transi à coup sûr, et l'aspiration le tire deux fois plus fort | Aspiration (1) |
| ↳ **Singularité** *(neuf)* | 1 | au moment d'éclater, **l'implosion aspire tout à deux fois son rayon** | Implosion (1) |
| ↳ **Ornière** *(neuf)* | 2 | la coulée **laisse un sol gelé derrière elle**, 1 s par point | Coulée (1) |
| ↳ **Meule** *(neuf)* | 2 | un ennemi aspiré jusqu'au cœur (15 px) prend 20 % de dégâts plus par point | Aspiration (2) |

*Retirés* : Engelure (Pics), Froid mordant (Nova), Bris (Nova), Avalanche (l'explosion
finale va au Tombeau ; l'Implosion s'ouvre désormais par l'Aspiration ou le Blizzard).

### Récapitulatif

- **39 → 58 nœuds**, dont **15 suites** ; ~30 nombres neufs dans `SkillStats`. Deux arbres
  sur quatre ont une interaction : les Pics (Cristallisation, vers le Désastre) et le
  Désastre (Supraconduction, qui lit **l'engourdi de la foudre** — l'interaction entre
  manuels que le jalon 43, §3, renvoyait au froid).
- **Chaque arbre a son rôle** : les Pics le coup visé et le transi qu'ils exploitent, la
  Nova la foule gelée autour de soi, le Tombeau la défense, le Désastre la zone qui grandit.
- **Ce qui se réutilise** : `knockback` et `pull` de `Targets.strike_circle` (Repoussoir,
  Supraconduction) ; `DashTrail.patch` pour l'Ornière ; `IceSpikes.raise_at(…, delay)` pour
  la Réplique, les Secousses et la Crevasse ; `seek` pour le Grésil ; le compteur de lancers
  du Plein régime (jalon 43) pour le Glacier ; la `strength` du transi (jalon 36) pour la
  Gelée blanche, le Givrage, le Cœur de glace et la Peau de givre.
- **Dessin** (`/dessiner-un-effet`) : le glacier, la coulée qui roule. Les vignettes des 58
  nœuds passent par `tools/node_icons.py`, palette `cold` (jalon 42, §14).
- **Ce qui se multiplie** : Bosquet, Réplique et Secousses font percer des cercles depuis
  un lancer, le Glacier par-dessus ; la Gelée blanche propage le transi de mort en mort
  (bornée : elle transit, elle ne tue pas). À remesurer sur `world/stress_test.tscn`.
- **Livraison** arbre par arbre, chacun avec ses tests et ses vignettes : Pics, Nova,
  Tombeau, Désastre. Le froid entre dans `UNIQUE_TREES` au dernier, et **la constante
  disparaît**. `docs/ARBRES.md` se régénère ; les couloirs d'équilibrage se relèvent
  avant → après, sans les corriger (jalon 13, §7).

### Les questions

1. **Une cinquième compétence ?** Le froid en a quatre, la foudre et les flammes cinq, et
   il n'a **aucun projectile**. Proposé : un *Javelot de givre* (lent, transperce, transit
   ce qu'il traverse) ou une *Orbe gelée* à la Diablo II (lente, crache des éclats en
   tournant, puis éclate) — avec son arbre. Ou rester à quatre.
2. **Le Tombeau garde-t-il son enfermement** comme forme de base, l'Armure de givre restant
   la transformation qui libère ?
3. **L'Avalanche part** du Désastre (l'explosion finale va au Tombeau) : d'accord ?

## 4. Les réponses

L'utilisateur, sur la proposition : « ok ». Et sur les trois questions :

- **une cinquième compétence, l'Orbe gelée**, avec son arbre ;
- **le Tombeau garde son enfermement**, l'Armure de givre reste la transformation qui
  libère ;
- **l'Avalanche part** : l'explosion finale reste au Tombeau seul.

### L'Orbe gelée — la proposition *(neuve, 14 nœuds, 30 points)*

Le seul projectile du froid, à la *Frozen Orb* de Diablo II : **une orbe lente qui file
droit en tournant, crache un éclat de glace à chaque période dans une direction qui
tourne, puis éclate en une couronne d'éclats** à la fin de sa course. Elle ne frappe pas
elle-même ; un mur l'éclate plus tôt. Forme neuve (`FROST_ORB`), classe à part
(`FrozenOrb`) : l'Orbe statique se dessine en foudre et frappe en cercle, celle-ci tire.
Les éclats sont ceux des Pics (`Projectile.split`, la scène des tirs).

Premier réglage : niveau 5 du manuel, 18 mana, 0,8 s de geste, 110 px/s, 1,6 s de course,
un éclat toutes les 0,12 s, huit à l'éclatement, 5 · 7 · 9 · 11 · 14 par éclat.

| nœud | pts | effet | relié à |
|---|---|---|---|
| **Noyau** | 4 | +8 % dégâts plus | — |
| **Long cours** | 3 | +20 % durée | — |
| **Bise** | 2 | +15 % vitesse de l'orbe | — |
| **Aiguilles** | 2 | les éclats traversent un ennemi de plus | Noyau (1) |
| **Toupie** *(neuf)* | 3 | l'orbe crache 10 % d'éclats de plus par seconde, par point | Long cours (1) |
| **Pluie d'éclats** *(neuf)* | 2 | +3 éclats à l'éclatement final, par point | Long cours (2) |
| **Constellation** *(neuf)* | 2 | +1 orbe en éventail, par point ⇄ −20 % plus | Noyau (2) |
| **Orbe mordante** *(neuf)* | 3 | **l'orbe frappe aussi ce qu'elle traverse**, à 30 % du coup par point, une fois par ennemi | Bise (1) |
| **Fracture** *(neuf)* | 3 | **un éclat qui touche un transi se brise en deux**, 20 % de chance par point ; les morceaux ne se brisent plus | Aiguilles (1) |
| **Guidage** *(neuf)* | 1 | **l'orbe s'incurve vers le curseur** tant qu'elle vole | Toupie (1) ou Bise (2) |
| **Stase** *(neuf)* | 1 | **l'orbe s'arrête au point visé** et y tourne jusqu'à la fin, crachant tout autour | Pluie d'éclats (1) |
| ↳ **Kaléidoscope** *(neuf)* | 1 | les morceaux d'une fracture se brisent encore une fois | Fracture (2) |
| ↳ **Cristallin** *(neuf)* | 2 | arrêtée, **l'orbe grossit** : +10 % de dégâts plus par point et par seconde de stase | Stase (1) |
| ↳ **Viseur** *(neuf)* | 1 | guidée, **l'orbe crache vers l'ennemi le plus proche** plutôt qu'en spirale | Guidage (1) |

Pas d'interaction : les Pics et le Désastre en ont déjà, deux arbres sur cinq. **Une limite
d'orbes par lanceur**, comme l'Orbe statique (jalon 43, §7) : elle crache sans viser, et la
Constellation, la Toupie et la Fracture multiplient les tirs. Chiffre à mesurer sur
`world/stress_test.tscn`, pas avant. **Son dessin passe sur planche** (`/dessiner-un-effet`) :
l'orbe, ses éclats, l'éclatement.

**Livraison** : Pics, Nova, Tombeau, Désastre, puis l'Orbe et sa planche. Le froid entre
dans `UNIQUE_TREES` avec l'Orbe.

## 5. Les Pics de glace — livrés

L'arbre du §3, **15 nœuds, 30 points**. Réflexe, Givre persistant, Froid mordant et Bris
sont partis (leurs points reviennent à placer) ; le Tranchant s'appelle Arête. Trois écarts :

- **le Plein centre ne fait pas de nombre neuf** : c'est `eye`, l'Œil de l'Immolation —
  le même tirage, plus fort dans le tiers central du rayon (`EYE_PART`). Une règle, un
  endroit ; le feu et le froid sont deux manuels ;
- **la Cristallisation s'ouvre aussi par l'Arête (2)** : par la Réplique seule, elle se
  lisait comme une suite (`ManualCell.is_suite()`), alors qu'elle ne la prolonge pas ;
- **le Grésil est `seek_radius`**, que `SkillStats.shard()` passe désormais aux éclats ;
  `Projectile._seek()` les incurve du virage borné du paratonnerre (`_steer()`, partagé).

```
             Sérac      Glacier
             Acharnement  Engelure   Plein centre
 Secousses   Réplique     Arête      [PICS]   Poussée   Bosquet
             Cristallisation  Éclats          Sillon de glace
                          Grésil              Crevasse
```

**La Réplique** naît à la frappe, au même cœur (`AFTERSHOCK_GAP`, 0,4 s), d'un lancer
`aftershock_of()` qui ne réplique pas. **Le Glacier** est compté par `Player.cast_slot()`
(`_glacier`) : un lancer sur trois, deux sous le Sérac, part en `SkillStats.swollen()`.
**La Cristallisation** passe par `IceVortex.feed()` : le vortex prend sa copie du lancer à
la première fois, et sa croissance garde la durée d'origine (`_grow`) — sans quoi il
rétrécissait en s'allongeant. Le Sillon ignore le Bosquet (`IGNORED_BY_SHAPE`).

Huit tests (« Pics de glace (jalon 44) »). Capture :
`hns-captures-arbre-glace\1-arbre-pics.png`. Les vignettes viendront à la fin, arbre par
arbre, comme pour la foudre.

**Le banc** (`only=ice_spike`), relevé sans correction (jalon 13, §7) :

| | avant | après |
|---|---|---|
| meilleur au paquet | ×3,68 | **×9,71** |
| meilleur au duel | ×2,89 | **×7,77** |

Les deux font plus que doubler : **la Réplique et ses Secousses** (trois répliques à 50 %
pour quatre points) et le Glacier sous le Sérac sont dans tous les builds. À reprendre à
l'équilibrage. Jamais pris : Bosquet, Cristallisation — le banc ne pose pas de vortex, et
l'échange du Bosquet ne paie pas sur des cibles groupées dans un seul cercle.

## 6. Les retours sur les Pics de glace

1. **La Réplique est un pic entier** : « elle doit profiter des autres nœuds, ça reste un
   pic de glace — les Éclats ne marchent pas ». Elle partait d'un lancer dérivé
   (`_derived()`), qui ne recopie ni éclats ni sol, et sans la scène des éclats.
   `aftershock_of()` part désormais du lancer entier (`echoed()`), à sa part du coup ;
   seules la Réplique et les Secousses n'y sont pas recopiées, sans quoi elle répliquerait
   sans fin. Un test de plus : une réplique sous les Éclats projette les siens.

   Au banc, le meilleur build passe à **×12,1 au paquet** et **×15,6 au duel**, par le
   Sillon — Crevasse, Éclats et Grésil sous chaque réplique. À reprendre à l'équilibrage.

## 7. La Nova de glace — livrée

L'arbre du §3, **15 nœuds, 30 points**. Engelure et Acharnement sont partis aux Pics. Trois
écarts :

- **la Gelée blanche est la Poudrière du feu** (`powder_keg`) : l'explosion d'un tué transit
  à coup sûr ce qu'elle touche, à la force de la nova — et le gel se propage. La force « du
  transi du mort » aurait demandé de lire l'état d'un corps qui disparaît. Elle passe à un
  point ; le Frimas en prend trois ;
- **le Repoussoir est `knockback`**, 30 px par point, et l'Onde de givre le lit aussi ; elle
  ignore le Grand froid (`IGNORED_BY_SHAPE`), qui compte un cercle qu'elle n'a pas ;
- **le Reflux se referme sur le centre de l'anneau**, là où la nova est partie, et non sur
  le lanceur, qui a pu bouger : l'anneau posé ne le suit pas.

```
             Gelée blanche  Bris
             Grand froid    Froid mordant           Repoussoir
             Frimas         Morsure   [NOVA]   Souffle   Givre persistant  Glace noire
                            Sursaut   Réflexe  Onde de givre
                            Qui-vive           Reflux
```

**La nova pose deux nombres sur son explosion** (`Explosion.crowd` et `knockback`), elle
seule : les autres explosions du jeu ne changent pas. **Le Sursaut** passe par
`Player._on_damaged()` : la nova résolue au moment du coup, reposée en différé, puisque le
coup arrive d'un rappel de collision. **La Glace noire** ne retient que le dernier sol de la
nova du joueur — un sol de plus n'y changerait rien, la nova pose le sien sous ses pieds.

Sept tests (« Nova de glace (jalon 44) »). Capture :
`hns-captures-arbre-glace\2-arbre-nova.png`. Le libellé anglais du Grand froid débordait de
sa fiche (`test_passive_and_node_sheets_fit_in_both_languages`) : raccourci.

**Le banc** (`only=ice_nova`), relevé sans correction :

| | avant | après |
|---|---|---|
| meilleur au paquet | ×6,66 | **×9,10** |
| meilleur au duel | ×2,77 | ×2,38 |

Le paquet monte par l'Onde de givre et son Reflux, qui frappe deux fois ; le duel perd
l'Acharnement, parti aux Pics. Jamais pris : Repoussoir, Gelée blanche, Glace noire,
Qui-vive — le banc ne bouge pas, ne reçoit pas de coups et ne compte pas la propagation.

## 8. Le Tombeau de glace — livré

L'arbre du §3, **14 nœuds, 32 points**. Engelure, Froid mordant et Bris sont partis ; le
Tombeau garde son enfermement et l'Armure de givre qui libère (§4). Deux écarts :

- **la Peau de givre transit à la force du nœud** (30 % par point) : un transi plus faible
  que celui d'un sort, qui ne remplace pas un transi plus fort déjà posé ;
- **le coup reçu au contact s'appelle `Player.melee_blow()`** : `backlash()` portait le
  nom du Choc en retour de la foudre, et sert désormais aussi au froid.

```
                       Cœur de glace   Brise-glace
             Peau de givre  Éclatement  Hibernation
 Isolant     Glace épaisse  [TOMBEAU]   Longue nuit
 Refuge      Dégel          Armure de givre   Sobriété
                            Halo de givre     Hiver sans fin
```

**Le buff résout déjà son lancer à chaque image** (son drain, son soin) : l'Hibernation et
le Halo s'y lisent sans rien résoudre de plus. **L'Hibernation reprend `Player._hasten()`**,
celui du Tempo : elle n'accélère que les compétences à recharge, pas les simples gestes.
**Le Brise-glace** lit ce qu'il restait au buff (`Buff.remaining()`) au moment où il
s'éteint ; à sa fin naturelle, il ne donne rien.

Sept tests (« Tombeau de glace (jalon 44) »). Capture :
`hns-captures-arbre-glace\3-arbre-tombeau.png`. Le libellé du Brise-glace débordait de sa
fiche en français : raccourci en « dégâts par seconde restante ». Un buff ne frappe pas
de lui-même : le banc des arbres ne le mesure pas.

## 9. Le Désastre hivernal — livré

L'arbre du §3, **14 nœuds, 30 points**. Engelure, Froid mordant, Bris et l'Avalanche sont
partis (§4) : **le vortex ne lit plus `end_burst`**, son test et sa ligne
d'`IGNORED_BY_SHAPE` avec. L'Implosion s'ouvre par l'Aspiration (2) ou le Blizzard (2).
Trois écarts :

- **la Singularité fait éclater l'implosion à deux fois son rayon**, plutôt qu'aspirer
  au moment d'éclater : le jeu n'a pas de traction sans coup, et l'éclatement portant plus
  loin dit la même chose ;
- **la Supraconduction s'ouvre aussi par la Bourrasque (2)** — par la seule Aspiration,
  elle se lisait comme une suite. Sans l'Aspiration, elle transit les engourdis et n'a rien
  à doubler ; sa fiche le dit ;
- **la Coulée s'arrête au point visé**, ou contre un mur, plutôt que de rouler toute sa
  durée.

```
                      Boule de neige  Bourrasque  Supraconduction  Meule
             Accalmie  Œil du cyclone  [DÉSASTRE]  Aspiration  Implosion  Singularité
             Givrage   Rafales                     Blizzard
                                                   Coulée
                                                   Ornière
```

**L'impulsion n'est plus `Targets.strike_circle()`** : la Meule, la Supraconduction et le
Givrage décident cible par cible, sur un seul tirage. **L'Accalmie passe par la fiche**
(`damage_taken`, comme le Rempart d'os) : `Player` la relit à chaque image et ne refait sa
fiche que lorsqu'elle change — en entrant dans l'œil ou en en sortant.

Sept tests (« Désastre hivernal (jalon 44) »). Capture :
`hns-captures-arbre-glace\4-arbre-desastre.png`. Le libellé de la Meule doublait celui du
Plein centre (« dégâts en plus au cœur ») : elle a le sien, « dégâts au cœur du vortex ».
En route, un `sed` de débogage a touché deux tests voisins de la même ligne ; rétablis,
vérifiés au diff.

**Le banc** (`only=winter_disaster`), relevé sans correction :

| | avant | après |
|---|---|---|
| meilleur au paquet | ×3,74 | **×6,03** |
| meilleur au duel | ×2,41 | ×2,41 |

Le paquet monte par l'Implosion, la Singularité, la Boule de neige et la Coulée (qui porte
le vortex sur le paquet, posé au point visé du banc). Jamais pris : Aspiration, Givrage,
Supraconduction, Meule — le banc ne déplace pas les ennemis et ne pose ni transi à
renforcer ni engourdi.

## 10. L'Orbe gelée — livrée, et le manuel entier

La compétence et l'arbre du §4, **14 nœuds, 30 points**. Niveau 5, case `(1, 1)` du
manuel, sous la Nova.

**Choisie sur planche** (`hns-captures-orbe-gelee\1-planche-orbe-gelee.png`, six partis
pris en cinq temps — elle tourne en crachant, puis éclate) : **la 1, « sphère de givre »**,
contre une étoile de cristaux, un flocon géant, un cœur et sa ronde, un oursin et un
cristal taillé. `Frost.orb()` : une boule pleine que traverse une facette de givre, huit
positions sur un demi-tour, fabriquées une fois. Ses éclats sont les javelots du Trait de
glace, déjà dessinés. La première planche posait les éclats contre l'orbe : un javelot
fait vingt pixels, sa pointe revenait sur elle et cachait le cristal taillé — écartés à
vingt pixels.

**Vu à la capture** (`hns-captures-orbe-gelee\2` à `6`) : l'orbe se lit, la spirale aussi,
l'éclatement fait une étoile nette. Les éclats sont plus longs que l'orbe — c'est la
proportion de la planche choisie.

**Une forme neuve**, `FROST_ORB` : `FrozenOrb` crache des tirs du joueur, de son propre
lancer — ils lisent donc la perforation (Aiguilles) et la Fracture comme n'importe quel
tir. Deux écarts au §4 :

- **la Fracture et l'Orbe statique ne partagent rien** : la Fracture se lit dans
  `Projectile`, sur tout tir du froid qui la porte ;
- **le Guidage est sans effet sous la Stase**, qui mène l'orbe au point visé. Les deux ne
  se relient pas, mais un même arbre peut les prendre : la fiche du Guidage le dit.

```
                              Orbe mordante  Guidage       Viseur
 Kaléidoscope  Fracture  Aiguilles  Bise     Toupie
               Noyau     [ORBE]    Long cours   Pluie d'éclats
               Constellation                     Stase   Cristallin
```

**La limite : six orbes par lanceur**, mesurée au pire cas — 300 grunts collés et
immortels, l'orbe lancée sans relâche sous Toupie 3, Constellation 2, Pluie d'éclats 2,
Fracture 3, Kaléidoscope et Orbe mordante 3 :

| orbes au plus | seul | avec le corbeau |
|---|---|---|
| 6 | 165 img/s, 11,8 ms de physique | 130 img/s |
| 9 | 157 | 105 |
| 12 | 134 | 34, une image à 76 ms |

**Ce qui coûtait** : la première mesure, à six orbes, donnait 124 img/s et 16,8 ms. Coupée
une à une sur une copie, l'Orbe mordante ne coûtait rien ; sans la Fracture, 164 img/s.
`SkillStats.fragment()` recopiait le lancer entier par `echoed()` à **chaque** bris —
0,27 ms la copie, des dizaines de bris par seconde. Le morceau est désormais fabriqué une
fois par lancer et gardé (`_fragment`), et `echoed()` ne recopie plus ce qui commence par
un souligné : un cache ne vaut que pour son lancer.

Huit tests (« Orbe gelée (jalon 44) »), et celui du dessin (`test_effect_forge.gd`).
`test_the_shape_gives_projectile` compte la forme parmi celles qui portent `projectile`.
Capture de l'arbre : `hns-captures-arbre-glace\5-arbre-orbe.png`. **L'icône de la
compétence manque** : un disque cyan dans la barre, une case vide sur la page — elle
viendra avec les vignettes.

**Le banc** (`only=frozen_orb`), relevé sans correction :

| | sans arbre | meilleur |
|---|---|---|
| au paquet | 94,5/s | 908/s ×9,61 |
| au duel | 15,2/s | **1 005/s ×65,9** |

Seule, l'orbe crache en spirale et ne touche une cible unique que par hasard ; **le Viseur**
dirige tous ses éclats sur elle, et la Stase avec le Cristallin la tient à bout portant.
1 005/s, c'est deux fois le meilleur duel des Pics : à reprendre à l'équilibrage, en
premier. Jamais pris : Constellation, Kaléidoscope.

**`UNIQUE_TREES` a disparu** : le froid y entrait en dernier, et la règle — aucun nom ni
aucune ligne d'un arbre à l'autre — est désormais celle de tous les manuels
(`test_trees_share_no_line_and_no_name`). Elle passe du premier coup.

### Ce qui reste au jalon

- ~~**les vignettes** des 72 nœuds du froid et l'icône de l'Orbe~~ — faites, §12 ;
- **l'équilibrage**, en dernier : l'Orbe au duel (×65,9), les Pics (×12,1 et ×15,6), la
  Nova et le Désastre au paquet.

## 11. Les retours sur l'Orbe gelée

1. **« Indique que le Guidage n'a aucun effet avec la Stase »** : la fiche ne le disait que
   pour une transformation (`IGNORED_BY_SHAPE`). La Stase est une mécanique : une table
   sœur, `Skill.IGNORED_BY_MECHANIC`, que `ManualPanel._node_sheet()` lit au même endroit.
   La fiche du Guidage écrit en rouge « sans effet avec Stase », et la description de la
   Stase le dit aussi. Un test (`test_a_node_says_what_a_mechanic_ignores`).
2. **Une erreur en jeu** : `FrozenOrb._spit` passait à `Projectile.spawn()` un lanceur déjà
   libéré — l'épaule du corbeau, éteint pendant que ses orbes volaient. L'orbe se dissout
   désormais avec son lanceur, comme le Satellite avec le sien ; ses tirs n'auraient plus
   eu d'auteur. Un test (`test_a_frozen_orb_dissolves_with_its_caster`).

## 12. Une vignette par nœud — le manuel du froid

Les 72 nœuds et les cinq icônes de compétence, par le tuyau du feu et de la foudre (jalon 42,
§14 ; recette : `resources/icons/LISEZMOI.md`) avec la palette `cold`, **arbre par arbre** :
chaque arbre posé, capturé en jeu et validé avant le suivant. Captures sur le Bureau,
`hns-captures-noeuds-glace\`.

**Les Pics de glace** : quinze vignettes, dont une reprise — l'Engelure reprend le flocon du
Gel intense (`fireball_deep_frost`). L'icône de la compétence quitte le tuyau SDXL pour
Qwen-Image (`qwen`, `nature: cold`), graine 4242. Arbre en jeu en `01`, planches en `02`
(nœuds) et `03` (icône). Faibles : la **Crevasse** (deux blocs pâles, la faille ne se lit
pas) et l'**Arête**, sortie en épée plutôt qu'en lame de cristal. Validés tels quels.

**La Nova de glace** : quinze vignettes neuves — rien d'existant ne disait la même chose, et le
flocon sert déjà trois fois. Trois sujets refaits avant de montrer : le **Souffle** (un nuage
informe → le visage du vent du nord qui souffle), le **Froid mordant** (un boulet sombre perdu
à 24 px → un escargot pris dans la glace : le ralenti) et le **Reflux** (des flèches courbes
invisibles → quatre flèches pleines vers le centre de l'anneau). Icône de la compétence en
Qwen, graine 4242. Arbre en jeu en `04`, planches en `05` et `06`.

**Le Tombeau de glace** : quatorze vignettes neuves. Deux sujets refaits : le **Brise-glace**
(la proue d'un brise-glace, illisible → un marteau qui fend un bloc de glace) et le **Halo de
givre** (un anneau nu, le quatrième du manuel après l'Onde, le Reflux et l'icône de la Nova →
une silhouette au milieu d'un cercle de givre : ce qui passe près de vous). Icône de la
compétence en Qwen, graine 777 — la silhouette debout dans son bloc se lit mieux. Arbre en
jeu en `07`, planches en `08` et `09`.

**Le Désastre hivernal** : quatorze vignettes neuves. Le premier tirage sortait trois tornades
presque identiques (Œil du cyclone, Bourrasque, Coulée) : l'Œil garde la tornade, la Coulée
sa traînée. Cinq sujets refaits : la **Bourrasque** (un arbre dans le vent), le **Blizzard**
(un nuage qui lâche un rideau de neige), l'**Implosion** (des éclats qui convergent),
l'**Accalmie** (un parapluie dans la tempête) et l'**Aspiration**, dont le tourbillon doublait
l'icône de la compétence (des éclats tirés vers un point). Icône en Qwen, graine 4242.
Arbre en jeu en `10`, planches en `11` et `12`. Faibles en jeu : la Bourrasque, une tache à
24 px, et la Supraconduction, dont le violet se perd.

**L'Orbe gelée** : quatorze vignettes neuves et sa première icône — une orbe de glace qui
crache ses éclats, graine 4242 ; `skill_icons.py apply` lui a ajouté son champ `icon`. Deux
sujets refaits : le **Long cours** (une orbe et trois points, confondue avec la Bise → une
comète à longue queue) et la **Pluie d'éclats** (une silhouette sous la pluie → une orbe
fendue qui répand ses éclats). Arbre en jeu en `13`, planches en `14` et `15`.

Le manuel compte ainsi **72 vignettes, dont une reprise** (l'Engelure), et cinq icônes de
compétence en Qwen. Restent faibles, non refaites : la Crevasse, l'Arête, la Bourrasque, la
Supraconduction.

**Le tuyau s'est arrêté une fois** : 122-126 s par tirage au lieu de 15. C'était le processus
ComfyUI, pas la machine — voir `LISEZMOI.md`, « Si un tirage dépasse la minute ». Le second arrêt (117 s par
tirage, ComfyUI pourtant relancé) avait une cause mesurée : **la VRAM débordait** — ComfyUI
20 Go dédiés et 3 Go en mémoire partagée, les autres applications 8 Go dont 4,9 Go pour
`QmlRenderer` (iCUE). Après le redémarrage de la machine, retour à 15 s.
