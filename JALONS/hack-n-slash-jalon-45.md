# Hack'n'slash top-down — jalon 45

Suite des jalons 1 à 44. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 9 octobre 2026.** Les arbres du **manuel de la nécromancie** repris comme ceux
des flammes (jalon 42), de la foudre (jalon 43) et du froid (jalon 44).

---

## 1. Ce que l'utilisateur a demandé

« À la manière des précédents jalons avec les manuels, fais le manuel de nécrose. » Les
demandes du jalon 42, §1, valent telles quelles : un peu plus de nœuds, aucun nœud qui
revient d'un arbre à l'autre, des nœuds originaux par compétence, des **suites** derrière
ce qui change le jeu, quelques interactions, quelques leviers simples — et une vignette par
nœud (jalon 42, §14), arbre par arbre.

## 2. La règle du jalon

Celle du jalon 42, §2, devenue celle de tous les arbres au jalon 44 : **aucun nom ni aucune
ligne** ne revient d'un arbre à l'autre, sauf un nœud de dégâts, de rayon et de durée par
arbre, et les échanges entiers. Une suite n'a qu'un parent, et ne lit que des nombres que ce
parent fait servir. Un nom ne double pas un autre manuel.

La nécrose respecte déjà la première moitié : c'est elle qui l'a inaugurée (jalon 38). Ce
qui lui manque, c'est le reste — **sept nœuds par arbre, 21 à 29 points**, aucune suite, et
la plupart de ses nœuds sont des leviers chiffrés.

**Cible** : celle du froid — 13 à 21 nœuds par arbre, 30 à 40 points pour un pool de 20,
deux à quatre nœuds que seule la compétence a, une à deux suites par nœud qui change le jeu.
La nécrose a **six** arbres : une interaction dans deux au plus.

Inspirations relevées : dans PoE, la *Contagion* qui saute de mort en mort, le *Detonate
Dead*, l'*Iron Maiden* et le *Despair*, les *Offerings* qui nourrissent les invocations ;
dans Last Epoch, la *Spirit Plague* qui change d'hôte, la *Reaper Form* et le *Death Seal*
qui paient de la vie, le *Dread Shade* ; dans Diablo II, la *Poison Nova*, l'*Amplify Damage*
et la *Decrepify*, le *Revive* ; dans Hero Siege, les squelettes mages du nécromancien ; dans
Torchlight Infinite, les malédictions qui achèvent sous un seuil.

## 3. Le manuel de la nécromancie — la proposition

### Noms pris ailleurs

| nom | pris par | devient |
|---|---|---|
| Couvée | Serpent infernal (flammes, jalon 42) | **Ponte** |
| Frénésie | l'état de la Soif de sang (Vive lame) | **Cliquetis** |

Conventions du jalon 42 : chiffres de **premier réglage**, « relié à (n) » = points demandés
dans le parent, ⇄ marque un échange, **neuf** = un nombre de `SkillStats` à écrire, 🔗 =
interaction avec une autre compétence, **↳** = suite, accessible par son seul parent.

### Peste — le trait qui contamine *(8 → 15 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Virulence *(gardé)* | 5 | +13 % dégâts plus | — |
| Fléau rampant *(gardé)* | 2 | traverse un ennemi de plus | — |
| **Projection** *(neuf)* | 2 | +15 % vitesse du trait — le plus lent du manuel (150 px/s) | — |
| Condamnation *(gardé)* | 3 | +20 % accrus contre les maudits | Virulence (1) |
| Incubation *(gardé)* | 4 | +15 % effet de la décomposition | Virulence (1) |
| Contagion *(gardé)* | 3 | à l'impact, la décomposition gagne les voisins | Fléau rampant (1) ou Incubation (1) |
| Fléaux jumeaux *(gardé)* | 2 | +1 trait en éventail | Fléau rampant (2) |
| Bubons *(gardé)* | 3 | un pourrissant tué explose | Incubation (2) |
| Nuée *(gardé)* | 1 | transformation : l'essaim lent qui mord son cercle | Virulence (2) ou Condamnation (1) |
| **Épidémie** *(neuf)* | 3 | **la décomposition change d'hôte** : un décomposé qui meurt la passe à l'ennemi le plus proche (80 px), avec ce qui lui restait et 1 s de plus par point — la *Spirit Plague* | Contagion (1) |
| **Vecteur** *(neuf)* | 2 | **le trait cherche les sains** : il s'incurve vers l'ennemi pas encore décomposé le plus proche, à 60 px par point | Projection (1) |
| **Germe** *(neuf)* | 1 | **un trait qui ne touche rien n'est pas perdu** : au bout de sa course, il crève en un nuage qui décompose son cercle | Projection (2) ou Fléaux jumeaux (1) |
| ↳ **Pandémie** *(neuf)* | 1 | l'Épidémie passe à **deux** ennemis au lieu d'un | Épidémie (2) |
| ↳ **Pustules** *(neuf)* | 1 | les Bubons font éclater aussi ce qui n'est que **décomposé** | Bubons (1) |
| ↳ **Dispersion** *(neuf)* | 2 | au bout de sa course, **l'essaim se divise** : un petit essaim de plus par point, à 40 % du coup | Nuée (1) |

Le Vecteur est sans effet avec la Nuée, qui file droit (`IGNORED_BY_SHAPE`).

### Relève — les morts qui servent *(8 → 15 nœuds, 36 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Moelle *(gardé)* | 5 | +12 % dégâts plus | — |
| Guet *(gardé)* | 3 | +20 % rayon de garde | — |
| Ossature *(gardé)* | 4 | +25 % PV des morts-vivants | — |
| Légion d'os *(gardé)* | 1 | +1 mort-vivant | — |
| **Marche funèbre** *(neuf)* | 2 | +15 % vitesse des morts-vivants | — |
| **Cliquetis** *(la Frénésie)* | 3 | ils frappent 10 % plus souvent | Moelle (1) |
| Rempart d'os *(gardé)* | 3 | chacun debout retire 2 % des dégâts subis | Ossature (1) |
| Dernier souffle *(gardé)* | 3 | un mort-vivant qui tombe explose | Ossature (2) |
| Colosse d'os *(gardé)* | 1 | transformation : un seul, géant | Moelle (2) ou Dernier souffle (1) |
| **Os rapiécés** *(neuf)* | 3 | chaque coup d'un mort-vivant lui rend 2 % de ses PV par point | Ossature (1) |
| **Curée** *(neuf)* | 3 | **la meute** : un mort-vivant frappe 8 % plus fort par point quand un autre frappe la même proie | Cliquetis (1) |
| **Rappel** *(neuf)* | 1 | **relancer quand tous sont debout n'est plus perdu** : ils reviennent à pleins PV et frappent 30 % plus fort pendant 3 s | Marche funèbre (1) |
| **Lanceurs d'os** *(neuf)* | 1 | **ils ne vont plus au contact** : depuis la formation, ils jettent un éclat d'os vers l'ennemi le plus proche (100 px), à 70 % du coup — les mages squelettes de Hero Siege | Guet (2) ou Curée (1) |
| ↳ **Éboulis d'os** *(neuf)* | 1 | le colosse qui tombe **se brise en trois morts-vivants ordinaires**, pour 6 s | Colosse d'os (1) |
| ↳ **Martyr** *(neuf)* | 2 | sous 25 % de PV, un mort-vivant **fonce exploser** sur l'ennemi le plus proche, son Dernier souffle 20 % plus fort par point | Dernier souffle (1) |

Les Lanceurs d'os sont sans effet avec le Colosse : un géant qui jette des os se lirait mal.

### Déferlante toxique — le souffle qui flétrit *(7 → 14 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Caustique *(gardé)* | 5 | +14 % dégâts plus | — |
| Miasme *(gardé)* | 3 | +20 % rayon | — |
| Haleine fétide *(gardé)* | 4 | +15 % chance de flétrir | — |
| Dessiccation *(gardé)* | 3 | +25 % accrus contre les flétris | Haleine fétide (1) |
| Asphyxie *(gardé)* | 4 | le flétri inflige moins de dégâts | Haleine fétide (2) |
| Marais *(gardé)* | 3 | laisse un sol toxique — **le seul sol du manuel** | Miasme (1) |
| Haleine *(gardé)* | 1 | transformation : le cône devant soi | Miasme (2) ou Asphyxie (1) |
| **Langueur** *(neuf)* | 2 | le flétrissement de la Déferlante dure 1 s de plus par point | Haleine fétide (1) |
| **Apnée** *(neuf)* | 3 | **retenir son souffle paie** : +10 % de dégâts plus par point et par seconde depuis la dernière Déferlante, 3 s au plus | Caustique (1) |
| **Succion** *(neuf)* | 2 | chaque flétri touché vous rend 0,5 % de vos PV max par point | Dessiccation (1) |
| **Détonation** 🔗 *(neuf)* | 2 | **le souffle fait éclater sur-le-champ les créatures de la Porte** qu'il touche, 15 % plus fort par point — le *Detonate Dead* | Caustique (2) |
| ↳ **Plongée** *(neuf)* | 1 | l'Apnée monte jusqu'à 5 s | Apnée (2) |
| ↳ **Râle** *(neuf)* | 1 | **le flétri s'use en frappant** : chaque coup qu'il porte prolonge son flétrissement de 0,5 s | Asphyxie (1) |
| ↳ **Quinte** *(neuf)* | 1 | le cône **repart deux fois** à 0,15 s d'écart, à 40 % du coup | Haleine (1) |

### Porte pourrissante — la couvée qui explose *(7 → 14 nœuds, 33 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Essaim *(gardé)* | 5 | +12 % dégâts plus | — |
| **Ponte** *(la Couvée)* | 4 | +25 % durée, donc plus de créatures | — |
| **Fécondité** *(neuf)* | 3 | la porte crache 12 % plus souvent par point | — |
| Boursouflure *(gardé)* | 3 | +20 % rayon | Essaim (1) |
| Rampants véloces *(gardé)* | 3 | elles courent plus vite | Ponte (1) |
| Flair *(gardé)* | 3 | elles voient de plus loin | Rampants véloces (1) |
| Progéniture *(gardé)* | 3 | elles lâchent des petits en éclatant | Boursouflure (1) |
| Nid porté *(gardé)* | 1 | transformation : la porte à l'épaule | Rampants véloces (2) ou Ponte (2) |
| **Gestation** *(neuf)* | 2 | **l'attente les fait grossir** : une créature sans proie gagne 10 % de dégâts plus par point et par seconde d'attente, 3 s au plus | Essaim (1) |
| **Laisse** *(neuf)* | 1 | **elles foncent sur ce que vous visez** : l'ennemi le plus proche du curseur plutôt que d'elles | Flair (1) |
| **Amalgame** *(neuf)* | 1 | **trois qui s'amassent fusionnent** en une seule, au triple des dégâts et au double du rayon | Gestation (1) ou Fécondité (2) |
| ↳ **Lignée** *(neuf)* | 1 | les petits lâchent **à leur tour** des petits, une fois | Progéniture (2) |
| ↳ **Grouillement** *(neuf)* | 2 | portée, la porte crache une créature de plus **chaque fois qu'un coup vous touche**, une fois par seconde | Nid porté (1) |
| ↳ **Masse critique** *(neuf)* | 1 | l'amalgame n'attend plus de proie : **il roule vers le groupe le plus dense** à portée | Amalgame (1) |

### Malédiction putride — le sceau *(6 → 14 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Anathème *(gardé)* | 3 | +25 % rayon | — |
| Malédiction prompte *(gardé)* | 3 | −12 % temps du geste | — |
| Malédiction profonde *(gardé)* | 5 | +15 % effet de la malédiction | — |
| **Récidive** *(neuf)* | 3 | −8 % recharge par point | — |
| Longue malédiction *(gardé)* | 4 | +20 % durée | Malédiction profonde (1) |
| Tribut *(gardé)* | 5 | chaque maudit rend du mana | Anathème (1) |
| Marque de mort *(gardé)* | 1 | transformation : un seul ennemi, plus fort, qui passe | Malédiction profonde (2) ou Tribut (1) |
| **Ronces** *(neuf)* | 2 | **le maudit se blesse** : 15 % par point des dégâts qu'il inflige lui reviennent — l'*Iron Maiden* | Malédiction profonde (1) |
| **Présage** *(neuf)* | 2 | le sceau tombe 1 s plus tard ⇄ +30 % d'effet par point | Malédiction prompte (1) |
| **Sentence** *(neuf)* | 2 | **le maudit est achevé** : sous 5 % de PV par point, il meurt sur-le-champ | Longue malédiction (1) |
| **Exhumation** 🔗 *(neuf)* | 1 | **un maudit qui meurt se relève à vos côtés**, mort-vivant de la Relève pour 6 s — dans la limite des trois | Longue malédiction (2) ou Tribut (2) |
| ↳ **Héritage** *(neuf)* | 2 | la marque qui passe **gagne 20 % de force par point** à chaque passage, trois fois au plus | Marque de mort (1) |
| ↳ **Dîme** *(neuf)* | 1 | un maudit tué vous rend 3 mana | Tribut (2) |
| ↳ **Exécuteur** *(neuf)* | 1 | un ennemi achevé par la Sentence **maudit ses voisins** (60 px) pour ce qui lui restait | Sentence (1) |

### Nécrose avancée — la chair qui paie *(6 → 14 nœuds, 34 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Gangrène *(gardé)* | 5 | +4 % chance de pourrir | — |
| Endurcissement *(gardé)* | 3 | −20 % vie rongée | — |
| Sang noir *(gardé)* | 4 | +1,5 PV/s | Gangrène (1) |
| Chair morte *(gardé)* | 4 | +8 % rés. nécrotique | Endurcissement (1) |
| Pacte *(gardé)* | 4 | +15 % dégâts nécrotiques ⇄ +25 % vie rongée | Gangrène (2) |
| Fardeau partagé *(gardé)* | 1 | ce qui vous est rongé frappe autour de vous | Pacte (1) ou Sang noir (2) |
| **Lente agonie** *(neuf)* | 2 | tant que la Nécrose brûle, vos états nécrotiques durent 10 % de plus par point | Gangrène (1) |
| **Charognard** *(neuf)* | 2 | tant qu'elle brûle, chaque ennemi qui meurt à 100 px vous rend 1 % de vos PV max par point | Sang noir (1) |
| **Moribond** *(neuf)* | 3 | **sous la moitié de votre vie**, la Nécrose cesse de ronger et vos sorts nécrotiques frappent 10 % plus fort par point | Endurcissement (2) |
| **Sursis** *(neuf)* | 1 | **un coup qui devrait vous tuer vous laisse à 1 PV** et éteint la Nécrose, une fois par minute | Chair morte (2) |
| **Faucheuse** *(neuf)* | 1 | transformation : la Nécrose ronge deux fois plus ⇄ vos sorts nécrotiques ne coûtent plus de mana — la *Reaper Form* | Pacte (2) ou Moribond (1) |
| ↳ **Exutoire** *(neuf)* | 1 | le Fardeau part aussi **dès qu'un coup vous ôte 10 % de vie** | Fardeau partagé (1) |
| ↳ **Linceul** *(neuf)* | 2 | sous la Faucheuse, vous subissez 3 % de dégâts en moins par point | Faucheuse (1) |
| ↳ **Revenant** *(neuf)* | 1 | le Sursis revient en 30 s, et vous laisse à 30 % de vie au lieu d'un PV | Sursis (1) |

### Récapitulatif

- **42 → 86 nœuds**, dont **17 suites** ; une quarantaine de nombres neufs dans `SkillStats`.
  Deux arbres sur six ont une interaction, toutes deux **à l'intérieur du manuel** : la
  Déferlante (Détonation, vers la Porte) et la Malédiction (Exhumation, vers la Relève).
- **Chaque arbre a son rôle** : la Peste ce qui se propage, la Relève la meute qui sert, la
  Déferlante l'affaiblissement autour de soi, la Porte la couvée qui grossit, la Malédiction
  ce qui achève, la Nécrose la vie qu'on paie.
- **Ce qui se réutilise** : `seek` (Vecteur, Laisse) ; le signal `slew` et
  `StatusEffects.pass_on()` (Épidémie, Pandémie, Pustules, Exécuteur, Charognard) ;
  `Minion.raise()` (Exhumation, Éboulis d'os, Rappel) ; `Explosion.put()` (Martyr,
  Détonation, Germe) ; `Projectile.split` (Dispersion, Lanceurs d'os) ; le compteur de
  lancers du Plein régime pour l'Apnée ; la `strength` des états (jalon 38) pour l'Héritage.
- **Dessin** (`/dessiner-un-effet`) : le nuage du Germe, l'éclat d'os des Lanceurs, l'amalgame,
  la Faucheuse sur le joueur. Les vignettes des 86 nœuds passent par `tools/node_icons.py`,
  palette `necrotic` (jalon 42, §14).
- **Ce qui se multiplie** : la Dispersion, la Quinte et la Lignée font naître des coups d'un
  seul lancer ; l'Épidémie et l'Exécuteur se propagent de mort en mort (bornés : ils posent un
  état, ils ne tuent pas) ; l'Exhumation lève des corps (bornée par la limite des trois). À
  remesurer sur `world/stress_test.tscn`.
- **Livraison** arbre par arbre, chacun avec ses tests et ses vignettes : Peste, Relève,
  Déferlante, Porte, Malédiction, Nécrose. `docs/ARBRES.md` se régénère ; les couloirs
  d'équilibrage se relèvent avant → après, sans les corriger (jalon 13, §7).

### Les questions

1. **Des cadavres ?** Le *Detonate Dead*, le *Revive* et la *Corpse Explosion* tiennent sur
   des corps laissés au sol, que le jeu n'a pas. Proposé : **non** — l'Épidémie, l'Exhumation
   et le Charognard lisent la mort elle-même (`slew`), sans rien laisser par terre. Ou un
   système de cadavres, qui ouvrirait d'autres nœuds mais coûte un objet par mort.
2. **La Sentence achève-t-elle les élites et les boss ?** Proposé : les élites au demi-seuil,
   les boss jamais.
3. **Les renommages** — Couvée → Ponte, Frénésie → Cliquetis : d'accord ?

## 4. Les réponses

L'utilisateur, sur la proposition : « non, oui et oui », puis « vas-y ».

- **pas de cadavres** : ce qui suit une mort lit la mort elle-même (`slew`) ;
- **la Sentence achève tout**, élites et boss compris, au même seuil ;
- **les renommages** : Couvée → Ponte, Frénésie → Cliquetis. Les identifiants restent
  (`rotting_gate_brood`, `rise_frenzy`) : ils sont dans les sauvegardes (invariant 1).

## 5. Les six arbres — livrés

Les arbres du §3, **86 nœuds**, livrés d'un tenant. Les identifiants des nœuds gardés ne
changent pas ; seuls deux noms changent (§4).

### Ce qui sert à tous : l'état garde son lancer

Le décomposé meurt souvent **de ses à-coups**, sans coup ni lancer derrière : `slew` ne part
pas. L'Épidémie, la Dîme, l'Exhumation, la Sentence, le Râle et les Ronces se lisent donc sur
**l'état posé**, qui garde le lancer qui l'a posé (`StatusEffects.attach()`, appelé après
`inflict()` par `Hurtbox.take_damage()` et par `PutridCurse` ; `pass_on()` le recopie). À sa
mort, `Enemy.die()` parcourt ses états : l'Épidémie change d'hôte (`Enemy.relay()`, différé),
et l'auteur l'apprend par le signal `StatusEffects.fell`, que `Player._on_fell()` lit. À
chaque coup porté, `Hurtbox` appelle `StatusEffects.landed()` sur l'auteur : le Râle et les
Ronces.

### Les écarts avec la proposition

- **L'Épidémie** compte sa portée (40 px par point) plutôt qu'une seconde de plus par point :
  l'état passe **à pleine durée**, comme la Contagion (`pass_on()`).
- **Le Germe** prend l'explosion nécrotique déjà dessinée (`GERM_PART`, `GERM_RADIUS`) : il
  frappe aussi, sans quoi un nuage qui ne fait que décomposer serait un coup de zéro. Il
  s'ouvre par la Projection (2) ou les Fléaux jumeaux (1).
- **La Fécondité** est un nombre à elle, qui se lit en période (`finalize()`) : `period` est
  déjà la ligne du Cliquetis, dans un autre arbre.
- **Les Lanceurs d'os** s'ouvrent par le Guet (2) seul, et lancent le crâne de la Peste en
  attendant leur dessin. **L'amalgame** est la créature au double, en attendant le sien.
- **L'Exhumation** s'ouvre par la Longue malédiction (2) seule, **la Faucheuse** par le Pacte
  (2) seul : l'autre parent passait sous un lien.
- **La Lente agonie** allonge les sorts nécrotiques lancés sous la Nécrose — leur durée, et
  celle de l'état qu'ils posent, par la Langueur (`languor`) — dans `Player.cast_slot()`. Une
  ligne du buff visant la durée des compétences nécrotiques débordait de la fiche de 34 px.
- **La Faucheuse** n'est pas une forme : `reaper`, lu par `Player.cast_slot()`, plus +100 %
  de vie rongée. Le **Linceul** est une ligne du buff (`damage_taken`).
- **`self_wither` et `omen`** entrent dans `StatMod.LOWER_IS_BETTER` : ronger davantage et
  tomber plus tard sont des pertes, la fiche les écrit en rouge.
- **La Succion et la Détonation** se lisent sur la nova : l'Haleine les ignore
  (`IGNORED_BY_SHAPE`). Le Vecteur et le Germe, sur le trait : la Nuée les ignore. Le Colosse
  ignore les Lanceurs d'os (`IGNORED_BY_MECHANIC`).

### Les tests

Trente-sept tests, par arbre (« Peste (jalon 45) » et suivants, `test_shapes.gd`). Capture des
six arbres en jeu : `hns-captures-arbres-necromancie\` sur le Bureau. Deux libellés
débordaient de leur fiche (`test_passive_and_node_sheets_fit_in_both_languages`) : raccourcis.

### Le banc

Relevé sans correction (jalon 13, §7), `tools/balance.sh trees only=…`. La Malédiction et la
Nécrose ne frappent pas : le banc ne les mesure pas.

| arbre | | avant | après |
|---|---|---|---|
| Peste | paquet | ×17,1 (Nuée) | **×19,2** (Nuée, Dispersion, Projection) |
| | duel | ×9,84 (Nuée) | ×9,84 |
| Relève | paquet | ×5,15 | ×5,85 (Marche funèbre, Rappel) |
| | duel | ×3,33 | **×5,30** (Curée, Rappel) |
| Déferlante | paquet | ×9,13 | **×13,5** (Haleine, Quinte, Apnée) |
| | duel | ×3,83 | ×5,42 (Apnée, Plongée) |
| Porte | paquet | ×8,32 | ×11,3 (Lignée, Fécondité) |
| | duel | ×6,67 | **×14,8** (Lignée, Fécondité, Gestation) |

La Porte au duel fait plus que doubler : la Lignée et la Fécondité sont dans tous ses builds.
Le Rappel paie au banc parce qu'il relance sans cesse. À reprendre à l'équilibrage. Jamais
pris — le banc ne compte ni la propagation, ni les morts, ni les coups reçus : Vecteur, Germe,
Épidémie, Pandémie, Pustules ; Os rapiécés, Lanceurs d'os, Éboulis d'os, Martyr ; Langueur,
Succion, Détonation, Râle ; Amalgame, Grouillement, Masse critique.

### La performance

`Hurtbox.take_damage()` et `Enemy.die()` ont gagné une boucle sur les états. Banc
`world/stress_test.tscn`, 300 ennemis, combat tenu, 240 images de chauffe puis 1 440, cinq
paires alternées avant / après : **7,55 contre 7,69 ms** de physique en moyenne, pour un écart
de 1 ms d'un tir à l'autre — dans le bruit ; ~183 img/s des deux côtés. Ce qui se multiplie
(Dispersion, Lignée, Quinte, Épidémie, Exhumation) n'a pas été mesuré à part.

### Ce qui reste au jalon

- ~~**les dessins sur planche**~~ — faits, §7 ;
- ~~**les vignettes** des 86 nœuds et des icônes de compétence~~ — faites, §8 ;
- **l'équilibrage**, en dernier.

## 6. Les retours sur les six arbres

1. **« La Gestation devrait aussi les faire grossir visuellement, l'Amalgame également. »**
   `RottingGate._swell()` est le seul calcul : ce que la créature a enflé à attendre, pour ses
   dégâts et pour son dessin ; l'amalgame dessine `AMALGAM_RADIUS` fois par-dessus. Le dessin
   est mis à l'échelle au pixel entier près : à ×1,6, les pixels ne sont pas tous de la même
   taille. L'amalgame garde son dessin provisoire. Captures : `hns-captures-porte-gestation\`.
2. **« La Masse critique n'a pas de sens : l'amalgame va de toute façon vers une cible. »**
   Juste : elle ne changeait que le choix de la proie (la plus entourée plutôt que la plus
   proche), ce qui ne se voyait pas. Elle garde son nom et son identifiant, et devient une
   fission : **en éclatant, l'amalgame relâche les trois créatures qui le formaient**, qui
   chassent et éclatent à leur tour, sans refusionner (`Crawler.loose`). `_thickest()` part.
3. **La Nécrose avancée coûte 5 % des PV actuels par seconde** (1 % avant). Le test du jalon
   38 qui bornait la perte à 1 % suit la règle.
4. **La Faucheuse divise le coût par deux** (`REAPER_COST`) au lieu de l'annuler.
5. **Un plafond de 60 % sur la réduction des dégâts subis**, pour tous les corps :
   `CharacterStats.MAX_DAMAGE_REDUCTION`, lu par `damage_taken_factor()` dans `mitigate()` —
   Rempart d'os, Glace épaisse, Linceul, Accalmie et Bouclier de lames cumulés n'y passent plus.
   Une vulnérabilité reste sans borne. Le test du jalon 21 qui posait −70 % suit la règle ; un
   test du plafond s'y ajoute. Le Linceul et l'article « Résistances » du guide le disent. **La
   fiche ne l'affiche pas** : elle ne montre que ce qu'un affixe atteint, et n'avait plus la
   hauteur.
6. **Sang noir : 2 points, 1 % des PV max par seconde et par point**, sous la Nécrose. C'est
   `self_heal`, que le buff rend déjà (`Player.mend()`), et non plus `health_regen` ; il entre
   dans `StatMod.SCALED` pour se lire « +1 % ».
7. **« L'Exhumation doit faire naître en lien avec l'arbre de la Relève. »** L'exhumé est un
   mort-vivant de la Relève résolue, **tout son arbre compris** — Colosse et Éboulis aussi,
   qu'il retirait. La naissance d'un mort-vivant n'a plus qu'un chemin, `Minion._spawn()`, que
   la levée et `risen()` partagent ; l'Éboulis retire le Colosse de son propre lancer. La
   description dit que rien ne se lève sans la Relève apprise.

## 7. Les planches — l'os et l'amalgame

Par `/dessiner-un-effet`. Planches et captures sur le Bureau, `hns-captures-os-amalgame\`.

**L'os des Lanceurs d'os** (`1-planche-os.png`) : six partis pris — os court, fémur, esquille
courbe, os à traînée de fumée, os cerné de vert, os au bout rongé. **Choisi : l'os court.** Il
**tournoie** en quatre temps — couché, biais, debout, l'autre biais —, ce qui dispense de
l'orienter : le debout est le couché tourné d'un quart (`EffectForge.turned()`), l'autre biais
le premier en miroir, sans perte. Deux défauts vus sur la première planche : les biais n'avaient
pas de nœuds et se lisaient en bâtons (redessinés en fourche), et la rampe du cœur — le jaune
maladif — faisait de l'os une tige verte : il a son ivoire, `Necrotic.BONE`.

**L'amalgame** (`2-planche-amalgame.png`) : cinq recettes fabriquées à la taille — six yeux,
grappe de trois, gueule à crocs, masse bosselée, pustules —, chacune à 13 px puis gonflée à
19 px, assise et tassée. **Choisi : six yeux.** Et, sur la même planche, **la créature qui
enfle par paliers** (7 dessinée, 9, 11) plutôt qu'étirée — choisi aussi : l'étirement du §6
faisait des pixels inégaux. `RottingGate._side()` arrondit la taille au palier impair ;
`EffectForge.grown_crawlers()` la fabrique, une fois par teinte, taille et sorte. Défaut vu sur
la première planche : les yeux, dans le jaune du cœur, disparaissaient sur le vert — ils sont
sombres, avec leur reflet en grand.

**Mesuré** (banc headless) : 0,2 ms l'os, de 0,15 ms (9 px) à 0,6 ms (amalgame de 21 px) une
créature, une seule fois chacune.

**En jeu** (`3-os-en-jeu.png`, `4-porte-en-jeu.png`, captures brutes dans `brut\`) : les os volent du squelette au
mannequin en tournoyant ; la porte montre la créature qui enfle et deux amalgames à pleine
Gestation, nets. Deux tests (`test_effect_forge.gd` : l'os sans perte au quart de tour, la
créature cuite une fois par taille), deux assertions de plus dans `test_shapes.gd`.

## 8. Une vignette par nœud — le manuel de la nécromancie

Les nœuds et les six icônes de compétence, par le tuyau du feu, de la foudre et du froid
(jalon 42, §14 ; recette : `resources/icons/LISEZMOI.md`) avec la palette `necrotic`, **arbre
par arbre** : chaque arbre posé, capturé en jeu et validé avant le suivant. Captures sur le
Bureau, `hns-captures-noeuds-necrose\`.

**La Peste** : quinze vignettes neuves, et l'icône de la compétence quitte le tuyau SDXL pour
Qwen-Image (un crâne dans sa fumée, graine 777). Six sujets refaits avant de montrer : le
**Fléau rampant** (des crânes sans flèche → une flèche qui traverse un crâne), les **Fléaux
jumeaux** (une bouillie → trois orbes en éventail), les **Bubons** (un tas → un sac qui crève),
la **Projection** (un gobelin qui court → une comète) ; la **Nuée** et la **Dispersion** sont
passées deux fois : **des mouches en nombre sortent en bruit à 32 px**, d'où une seule grosse
mouche vue de dessus et un pissenlit qui lâche ses graines. Arbre en jeu en `01`, planches en
`02` (nœuds) et `03` (icône).

Le premier lancement s'est arrêté : 136 s par tirage d'un sujet déjà encodé, puis ComfyUI a
coupé la connexion. Après un redémarrage de Windows, retour à 17 s — voir `LISEZMOI.md`, « Si
un tirage dépasse la minute ».

**La Relève** : quinze vignettes neuves, et l'icône quitte SDXL (une main d'os qui sort de
terre, graine 1337). Quatre sujets refaits : la **Légion d'os** (trois têtes casquées
minuscules → un crâne et un plus vert), les **Os rapiécés** (des os en croix, le double du
Cliquetis → un os bandé sous un cœur), la **Curée** (deux mains en bouillie → un cœur que
deux os transpercent) et l'**Éboulis d'os**, passé deux fois (un crâne fêlé → un tas d'os et
de crânes). Arbre en jeu en `04`, planches en `05` et `06`.

**La Déferlante toxique** : quatorze vignettes neuves, et l'icône quitte SDXL (un anneau de gaz
qui s'ouvre, graine 777). Cinq sujets refaits : l'**Haleine** (un canon → un cône de gaz), la
**Succion** (le tourbillon sortait en arbre → quatre volutes vers un cœur), le **Râle** (un
crâne à la pipe → un crâne de profil qui exhale) ; l'**Asphyxie** et la **Quinte** deux fois —
**une épée affaiblie ne se lit pas à 24 px** (croisées puis molle, une bouillie), d'où un crâne
au masque à gaz, et des cônes en rang sortaient en sapins, d'où trois chevrons. Arbre en jeu
en `07`, planches en `08` et `09`.

**La Porte pourrissante** : quatorze vignettes neuves, et l'icône quitte SDXL (une gueule
dentée dans un portail de chair, graine 777). **Toute créature demandée sort en gobelin vert**,
et la moitié de l'arbre se ressemblait : la créature ne reste que là où elle est le sujet
(Progéniture, Gestation, Amalgame, Lignée). Cinq sujets refaits en objets ou en bêtes : la
**Boursouflure** (un poisson-globe), les **Rampants véloces** (un cafard qui file, le plus
faible), le **Flair** (une truffe qui renifle), le **Grouillement** (un bouclier fendu d'où
suinte la vase) et la **Masse critique** (une boule de vase qui s'ouvre comme un œuf). Arbre en
jeu en `10`, planches en `11` et `12`.

**La Malédiction putride** : quatorze vignettes neuves, et l'icône quitte SDXL (un œil au
centre d'un cercle, graine 4242). Deux sujets refaits : la **Malédiction prompte** (un tampon
en bouillie → un crâne ailé qui file) et l'**Exécuteur**, sorti en visage humain malgré la
cagoule demandée (→ un crâne d'où éclate un anneau de runes). Faibles en jeu : les **Ronces**,
une couronne d'épines sombre. Arbre en jeu en `13`, planches en `14` et `15`.

**La Nécrose avancée** : quatorze vignettes neuves, et l'icône quitte SDXL (un cœur pourri veiné
de noir, graine 4242). Deux sujets refaits : l'**Endurcissement** (un cœur cuirassé, le double de
l'icône → une carapace de tortue) et le **Linceul**, sorti en silhouette encapuchonnée (→ un
crâne emmailloté de bandelettes). Arbre en jeu en `16`, planches en `17` et `18`.

Le manuel compte ainsi **86 vignettes, aucune reprise** — rien des autres manuels n'était de la
nécrose —, et six icônes de compétence en Qwen. Restent faibles, non refaits : l'**Éboulis
d'os**, les **Rampants véloces** et les **Ronces**. Deux règles de sujet apprises, reportées
dans `LISEZMOI.md` : **un nombre de petites bêtes sort en bruit à 32 px** (la Nuée, la
Dispersion), et **une créature demandée sort en gobelin** — elle ne reste que là où elle est le
sujet.
