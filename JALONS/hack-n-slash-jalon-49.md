# Hack'n'slash top-down — jalon 49

Suite des jalons 1 à 48. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 12 octobre 2026.** Les arbres du **manuel de la sorcière** repris comme ceux des
flammes (jalon 42), de la foudre (jalon 43), du froid (jalon 44), de la nécromancie
(jalon 45), du chevalier (jalon 46) et du sacré (jalon 48).

---

## 1. Ce que l'utilisateur a demandé

« Comme pour les jalons précédents avec les manuels, j'aimerais maintenant faire le manuel
unique de la sorcière ; étant une classe, le manuel de la sorcière se tourne comme
thématique autour des sorts élémentaires et de leurs effets. » Les demandes du jalon 42,
§1, valent telles quelles : un peu plus de nœuds, aucun nœud qui revient d'un arbre à
l'autre, des nœuds originaux par compétence, des **suites** derrière ce qui change le jeu,
quelques interactions, quelques leviers simples — et une vignette par nœud (jalon 42, §14),
arbre par arbre.

Sur la première proposition : « j'aimerais en fait avoir un sort à la place de la poupée, je
ne l'aime pas trop. » La **Poupée de chiffon quitte le manuel** ; un sort neuf prend sa case
du niveau 7 (§3, le Chaudron).

## 2. La règle du jalon

Celle du jalon 46, §2 : **aucun nom ni aucune ligne** ne revient d'un arbre à l'autre, sauf
un nœud de dégâts, de rayon et de durée par arbre, et les échanges entiers. Une suite n'a
qu'un parent et ne lit que des nombres que ce parent fait servir. Un nom ne double pas un
autre manuel.

La sorcière respecte la première moitié depuis le jalon 41. Ce qui lui manque : **six ou
sept nœuds par arbre, 21 points**, aucune suite. **Cible** : celle des jalons 44 à 48 — 13 à
21 nœuds par arbre, 30 à 40 points pour un pool de 20, deux à quatre nœuds que seule la
compétence a, une à deux suites par nœud qui change le jeu, une interaction dans deux arbres
au plus, à l'intérieur du manuel. **Trinité garde sa règle** du jalon 41, §8 : aucun nœud de
dégâts.

**L'identité**, celle du jalon 41, §2 : la sorcière tient **ce qui se passe entre les
éléments** — le tour feu → froid → foudre, la Trinité qui le récompense, la Catalyse qui
fait réagir. Ce que la reprise ajoute, à la demande : **les trois états élémentaires
deviennent la matière du manuel**. Chaque arbre en fait un geste :

| arbre | le geste sur les états |
|---|---|
| Projectile élémentaire | les **poser** — l'un après l'autre, sur la même cible |
| Trinité | les **rythmer** — l'alternance qui les entretient |
| Amplification des sorts | les **exalter** — plus forts, plus sûrs, d'un seul élément |
| Catalyse | les **faire réagir** — une quatrième réaction, la chaîne, l'état qui reste |
| Chaudron *(neuf, à la place de la Poupée)* | les **faire bouillir** — un sol qui suit le tour |
| Familier | les **semer** — le corbeau qui porte le mauvais œil |

Pas de pourriture ni de saignement, pas de critique (aucun nœud de la sorcière n'en a), pas
d'invocation de plus que le corbeau.

Inspirations relevées : dans PoE, l'*Elemental Equilibrium* (frapper d'un élément ouvre les
deux autres), l'*Elementalist* et ses *Shaper of Flames / Winter / Storms*, la *Prismatic
Burst* ; dans Diablo III, l'*Elemental Exposure* du sorcier et le set de *Tal Rasha* ; dans
Diablo IV, les *Enchantments* de la sorcière, le *Shatter* ; dans Last Epoch, le
*Runemaster* qui enchaîne les runes de feu, de givre et de foudre, l'*Elemental Nova* ; dans
Genshin Impact, les réactions qui ne consomment pas tout ; la chimie (catalyseur, enzyme,
précipité, quintessence) pour les noms de la Catalyse, la musique pour ceux de Trinité.

## 3. Le manuel de la sorcière — la proposition

### Noms pris ailleurs

Aucun des 33 noms gardés. Les 46 noms neufs, Chaudron compris, ci-dessous ont été vérifiés contre les 597
noms de nœuds, de compétences et d'objets du jeu.

Conventions du jalon 42 : chiffres de **premier réglage**, « relié à (n) » = points demandés
dans le parent, ⇄ marque un échange, **neuf** = un nombre de `SkillStats` à écrire, 🔗 =
interaction avec une autre compétence, **↳** = suite, accessible par son seul parent.

### Projectile élémentaire — le tour *(7 → 13 nœuds, 33 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Arcanes *(gardé)* | 5 | +12 % dégâts plus | — |
| Fulgurance *(gardé)* | 4 | +15 % vitesse de projectile | — |
| Électrochoc *(gardé)* | 4 | +15 % effet de l'engourdi | — |
| Affinité croisée *(gardé)* | 3 | +8 % dégâts accrus contre les embrasés, les transis et les engourdis | Arcanes (1) |
| Ricochet *(gardé)* | 2 | le trait rebondit vers l'ennemi le plus proche, une fois par point | Fulgurance (1) |
| Prisme *(gardé)* | 2 | +1 projectile par point ⇄ −15 % dégâts plus ; la salve répartit le tour | Ricochet (1) |
| Triade *(gardé)* | 1 | transformation : trois comètes, une par élément, éclatent ensemble au point visé ⇄ +25 % temps du geste | Arcanes (2) ou Électrochoc (2) |
| **Prestidigitation** | 3 | −8 % temps du geste par point | — |
| **Équilibre** *(neuf)* | 3 | **frapper d'un élément ouvre les deux autres** : l'ennemi touché perd 5 % par point de résistance aux deux autres éléments pendant 3 s — l'*Elemental Equilibrium* | Affinité croisée (1) |
| **Précipité** 🔗 *(neuf)* | 2 | **un trait qui touche un ennemi portant les deux autres états les fait réagir**, comme la Catalyse, à 20 % par point d'un coup du trait | Électrochoc (1) |
| ↳ **Chatoiement** *(neuf)* | 1 | **chaque rebond prend l'élément suivant du tour** : un trait qui ricoche deux fois pose les trois états | Ricochet (1) |
| ↳ **Spectre** *(neuf)* | 2 | dans une même salve, chaque élément qui a déjà touché une cible fait frapper le trait suivant 15 % plus fort par point | Prisme (1) |
| ↳ **Conjonction** *(neuf)* | 1 | l'éclat de la Triade **pose les trois états à coup sûr** — la Catalyse trouve tout prêt | Triade (1) |

Le Précipité est la seule interaction du manuel : il emprunte les réactions de la Catalyse
(`Catalysis`, ses trois paires et `REACTION_PART`) sans la lancer. Le Chatoiement, le Prisme
et le Précipité se répondent : la salve pose, le rebond change d'élément, le trait suivant
fait réagir.

### Trinité — l'accord *(6 → 13 nœuds, 35 points)*

Aucun nœud de dégâts (jalon 41, §8). Les lignes de buff comptent par charge.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Gamme *(gardé)* | 5 | par charge, +4 % chance d'état des sorts (buff) | — |
| Mesure *(gardé)* | 4 | par charge, +2 % rés. feu, froid et foudre (buff) | — |
| Point d'orgue *(gardé)* | 4 | les charges tiennent +0,5 s | — |
| Dissonance *(gardé)* | 2 | +1 charge au plafond ⇄ un sort qui répète l'élément les fait toutes perdre | Gamme (1) |
| Tempo *(gardé)* | 5 | chaque sort qui donne ou ravive l'Harmonie retire 0,1 s aux recharges en cours | Point d'orgue (1) |
| Accord parfait *(gardé)* | 1 | à pleines charges, le sort suivant les consomme et part dans les trois éléments, +30 % plus | Dissonance (1) ou Point d'orgue (2) |
| **Arpège** *(neuf)* | 3 | par charge, +4 % durée des états élémentaires que vous posez (buff) | Gamme (1) |
| **Modulation** *(neuf)* | 3 | **chaque charge gagnée entretient le tour** : les états élémentaires des ennemis à 80 px durent 0,25 s de plus par point | Point d'orgue (1) |
| **Diapason** *(neuf)* | 2 | un sort qui donne une charge pose aussi, à 10 % de chance par point, **l'état de l'élément précédent** — deux états d'un seul sort | Gamme (1) |
| **Rubato** *(neuf)* | 2 | à l'échéance, **les charges tombent une à une**, toutes les 1 s, au lieu d'ensemble — le *Frenzy* de PoE | Point d'orgue (1) |
| ↳ **Coda** *(neuf)* | 1 | l'Accord parfait vous laisse une charge | Accord parfait (1) |
| ↳ **Renversement** *(neuf)* | 1 | l'Accord parfait part à une charge du plafond ⇄ son +30 % plus tombe à +15 % | Accord parfait (1) |
| ↳ **Fausse note** *(neuf)* | 1 | les charges que la Dissonance fait perdre **éclatent autour de vous**, une petite explosion de l'élément répété par charge perdue, rayon 40 | Dissonance (1) |

### Amplification des sorts — la surcharge *(6 → 13 nœuds, 34 points)*

L'amplification garde sa ligne ; les nœuds de buff s'y ajoutent tant qu'elle brûle.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Surpuissance *(gardé)* | 5 | +3 % dégâts de sort plus (buff) | — |
| Volubilité *(gardé)* | 4 | +4 % vitesse d'incantation (buff) | — |
| Rémanence *(gardé)* | 3 | +15 % durée | — |
| Résonance *(gardé)* | 3 | chaque sort lancé sous l'amplification la prolonge de 0,3 s par point | Volubilité (1) |
| Siphon *(gardé)* | 3 | chaque ennemi tué par un sort sous l'amplification rend 2 mana par point | Surpuissance (1) |
| Contrecoup *(gardé)* | 3 | à sa fin, l'amplification éclate autour de vous, en foudre | Rémanence (1) ou Résonance (2) |
| **Récurrence** | 3 | −10 % recharge par point | — |
| **Exacerbation** *(neuf)* | 3 | sous l'amplification, les états élémentaires que vous posez sont 8 % plus forts par point (buff) | Surpuissance (1) |
| **Saturation** *(neuf)* | 2 | sous l'amplification, un sort qui touche un ennemi **sans aucun état élémentaire** lui pose le sien à coup sûr, une fois par seconde et par point | Exacerbation (1) |
| **Incarnation** *(neuf)* | 1 | transformation : **l'amplification prend l'élément du tour à son lancer** — tant qu'elle brûle, tous vos sorts sont convertis en cet élément, et son état y est 50 % plus fort ⇄ son +20 % plus tombe à +10 % — les *Enchantments* | Surpuissance (2) ou Rémanence (2) |
| ↳ **Aura** *(neuf)* | 2 | sous l'Incarnation, les ennemis à 40 px de vous prennent son état chaque seconde, à 20 % de force par point | Incarnation (1) |
| ↳ **Métamorphose** *(neuf)* | 1 | l'Incarnation **change d'élément à chaque sort lancé**, dans l'ordre du tour — la Trinité y regagne ses charges | Incarnation (1) |
| ↳ **Triple éclat** *(neuf)* | 1 | le Contrecoup éclate une fois **par élément lancé** sous l'amplification, chacun dans le sien, au lieu d'une fois en foudre | Contrecoup (1) |

Sous l'Incarnation sans Métamorphose, la Trinité ne gagne plus de charge : c'est voulu,
l'échange est là. La conversion passe par celle des dégâts ajoutés (`SkillStats.distribution()`).

### Catalyse — l'alambic *(7 → 14 nœuds, 33 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Concentré *(gardé)* | 5 | +10 % dégâts plus | — |
| Exothermie *(gardé)* | 4 | +25 % puissance des réactions | — |
| Grand cercle *(gardé)* | 3 | +15 % rayon accru | — |
| Nappe brûlante *(gardé)* | 3 | la Vapeur laisse une nappe de feu et de froid | Exothermie (1) |
| Arc fourchu *(gardé)* | 2 | l'Arc ardent gagne un voisin de plus par point | Exothermie (1) |
| Conductivité *(gardé)* | 3 | le Givre conducteur transit 16 px plus loin par point | Exothermie (1) |
| Amorce *(gardé)* | 1 | la Catalyse prête l'état de son tour | Concentré (2) ou Grand cercle (2) |
| **Distillation** *(neuf)* | 3 | chaque réaction rend 1 mana par point | Concentré (1) |
| **Quintessence** *(neuf)* | 2 | **une quatrième réaction** : un ennemi qui porte les trois états éclate en plus, une explosion des trois natures à 40 % par point d'un coup de la Catalyse | Exothermie (1) |
| **Autocatalyse** *(neuf)* | 2 | un ennemi tué par une réaction **pose l'état de la Catalyse** sur ses voisins à 30 px, une fois par point | Grand cercle (1) |
| **Enzyme** *(neuf)* | 1 | transformation : **la Catalyse ne consomme plus** — les états réagissent et restent ⇄ −40 % puissance des réactions | Exothermie (2) ou Amorce (1) |
| ↳ **Ferment** *(neuf)* | 2 | sous l'Enzyme, chaque réaction prolonge de 0,5 s par point les états qui l'ont faite | Enzyme (1) |
| ↳ **Détonateur** *(neuf)* | 1 | l'Amorce prête aussi l'état du tour suivant : **un ennemi sans état réagit**, à 50 % | Amorce (1) |
| ↳ **Pierre philosophale** *(neuf)* | 1 | la Quintessence **repose les trois états**, à 50 % de force, sur tout ce qu'elle frappe | Quintessence (1) |

Enzyme et Ferment font de la Catalyse une machine qui tourne seule : un même ennemi ne
réagit **qu'une fois toutes les 0,5 s** (garde du moteur, pas un nœud), sinon le Familier,
qui rejoue la Catalyse, et la Pierre philosophale bouclent.

### Le Chaudron — à la place de la Poupée de chiffon

**Ce qu'il fait.** Un chaudron posé au point visé, qui **bout dans l'élément de votre dernier
sort** : toutes les 0,8 s, il éclabousse son cercle dans cet élément et y pose son état. Les
sorts lancés pendant qu'il bout s'y **versent** : quand il a reçu les trois éléments, il
**déborde** — une éclaboussure des trois natures, au rayon ×1,5, qui pose les trois états à
coup sûr — puis se remet à bouillir, vide.

Ce qu'aucun sort du manuel ne fait : **un sol qui suit le tour**. La Catalyse fait réagir en un
point et d'un coup, le Projectile pose sur une cible ; le chaudron pose dans la durée, et il
change avec ce que la sorcière lance. Le Brasero des flammes est une tourelle qui tire ; le
chaudron ne tire pas, il bout.

| | |
|---|---|
| sort, nature du tour | niveau 7 du manuel, 5 points — la case de la Poupée |
| coût, geste, recharge | 16 mana, 0,5 s, 3 s |
| forme | `CAULDRON`, neuve : 8 s, rayon 50, un chaudron à la fois ; nature de départ : celle du tour au lancer |
| dégâts par bouillon, par point | 8 · 10 · 13 · 16 · 20 ; le débordement en vaut trois |

Ce qui le nourrit se lit comme les charges de Trinité : **un lancer de la sorcière**, où
qu'il tombe, pas l'écho du Familier.

### Chaudron — la potion *(13 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| **Mijotage** | 5 | +12 % dégâts plus | — |
| **Panse** | 3 | +15 % rayon | — |
| **Feu doux** | 4 | +20 % durée | — |
| **Couvercle** | 3 | −10 % recharge par point | — |
| **Bouillonnement** *(neuf)* | 3 | −10 % intervalle des bouillons par point | Mijotage (1) |
| **Trop-plein** *(neuf)* | 3 | le débordement frappe 25 % plus fort par point | Mijotage (1) |
| **Écume** *(neuf)* | 3 | chaque bouillon a 10 % de chance par point de projeter une goutte vers l'ennemi le plus proche **hors du cercle**, dans son élément | Panse (1) |
| **Philtre** *(neuf)* | 2 | tant que vous vous tenez dans son cercle, vous regagnez 1 mana par seconde et par point | Panse (1) |
| **Mélange** *(neuf)* | 3 | le chaudron garde **les deux derniers éléments versés** : chaque bouillon frappe dans les deux, moitié chacun, et pose les deux états à 15 % de force par point — une paire prête pour la Catalyse | Feu doux (1) |
| **Décoction** *(neuf)* | 1 | transformation : **le chaudron boit au lieu de poser** — chaque bouillon retire 1 s aux états élémentaires des ennemis du cercle, et chaque seconde bue accroît le débordement de 10 % ⇄ les bouillons ne posent plus rien | Trop-plein (1) ou Feu doux (2) |
| ↳ **Bulles** *(neuf)* | 2 | les gouttes de l'Écume éclatent à l'impact, rayon 15 px par point | Écume (1) |
| ↳ **Émulsion** *(neuf)* | 1 | le chaudron garde **les trois éléments** : chaque bouillon les frappe et les pose tous, un tiers chacun ⇄ il ne déborde plus | Mélange (1) |
| ↳ **Lie** *(neuf)* | 2 | sous la Décoction, chaque seconde bue prolonge le chaudron de 0,2 s par point | Décoction (1) |

Décoction et Émulsion sont deux manières de le tenir — boire ou tout poser : pas de chemin de
l'une à l'autre. Sous la Décoction, le Mélange ne sert plus (`IGNORED_BY_MECHANIC`).

**Ce que le départ de la Poupée défait** : `actors/skills/rag_doll.gd`, la `RagDoll` que
`Enemy.foe()` parcourt, le détournement de `Player._on_damaged()` (le Transfert), son bloc
dans la fenêtre Alt, son icône et ses tests. Son identifiant reste dans les sauvegardes
(invariant 1) : la case de barre se vide déjà seule (`Character`, « une compétence retirée
du projet ») ; **les points qu'un personnage y avait mis doivent lui revenir**, à vérifier à
la livraison avec un test. `Skill.Shape.DOLL` garde sa place dans l'enum, ou y devient
`CAULDRON` : les `.tres` y écrivent l'entier.

### Familier — le corbeau *(6 → 13 nœuds, 34 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Écho fidèle *(gardé)* | 5 | +6 % des dégâts rejoués | — |
| Frugalité *(gardé)* | 4 | −10 % mana drainé | — |
| Ailes noires *(gardé)* | 5 | +2 % vitesse tant qu'il vole (buff) | — |
| Œil du corbeau *(gardé)* | 4 | l'écho part vers l'ennemi le plus proche du point visé | Écho fidèle (1) |
| Ressassement *(gardé)* | 2 | un écho de plus par point ⇄ −10 % des dégâts rejoués | Écho fidèle (2) |
| Contre-chant *(gardé)* | 1 | l'écho prend l'élément suivant du tour | Frugalité (2) ou Ressassement (1) |
| **Rémiges** *(neuf)* | 3 | l'écho part 0,1 s plus tôt par point (`ECHO_DELAY`, 0,4 s) | — |
| **Sombre augure** *(neuf)* | 2 | un écho frappe 10 % plus fort par point **pour chaque état élémentaire** que porte sa cible | Œil du corbeau (1) |
| **Becquée** *(neuf)* | 2 | **le corbeau pique** : chaque seconde, il fond sur l'ennemi le plus proche, 3 à 6 dégâts par point dans l'élément de votre dernier sort, et lui pose son état | Ailes noires (1) |
| **Mauvais œil** *(neuf)* | 1 | transformation : **le corbeau ne rejoue plus, il maudit** — chaque écho pose l'état de son élément, à force pleine et à coup sûr, sur tous les ennemis à 50 px du point visé ⇄ sans dégâts | Frugalité (2) ou Contre-chant (1) |
| ↳ **Croassement** *(neuf)* | 2 | +15 % rayon du Mauvais œil par point | Mauvais œil (1) |
| ↳ **Jettatura** *(neuf)* | 1 | le Mauvais œil pose aussi l'état de l'élément suivant, à 50 % de force | Mauvais œil (1) |
| ↳ **Canon** *(neuf)* | 2 | sous le Contre-chant, **chaque écho du Ressassement avance d'un élément** sur le précédent ; +5 % des dégâts rejoués par point | Contre-chant (1) |

Le Mauvais œil fait du corbeau la meilleure amorce de la Catalyse ; Jettatura y ajoute la
paire à lui seul. Sous lui, l'Écho fidèle et le Sombre augure ne servent plus
(`IGNORED_BY_MECHANIC`) — il n'y a pas de dégâts à rejouer.

### Récapitulatif

- **39 → 79 nœuds**, dont **18 suites** ; la Poupée et ses 6 nœuds partent, le Chaudron et ses 13
  arrivent ; une quarantaine de nombres neufs dans `SkillStats`.
  **Une seule interaction**, à l'intérieur du manuel : le Précipité, du Projectile vers les
  réactions de la Catalyse. Le reste des liens passe par **les états eux-mêmes** : ce que le
  chaudron, le corbeau, la Trinité et le Projectile posent, la Catalyse le fait réagir. C'est
  le thème demandé, et ça n'oblige aucune compétence à en connaître une autre.
- **Chaque arbre a son rôle** (§2) : poser, rythmer, exalter, faire réagir, faire bouillir, semer.
  **Quatre transformations neuves** (Incarnation, Enzyme, Décoction, Mauvais œil), une par
  arbre, sauf Trinité qui a déjà l'Accord parfait et le Projectile qui a la Triade.
- **Ce qui se réutilise** : les réactions de `Catalysis` (Précipité, Quintessence) ;
  `StatusEffects.extend()` (Modulation, Ferment), `remove()` et sa garde (Enzyme), `put()`
  (Diapason, Saturation, Chaudron, Mauvais œil), `resistance_lost()` (Équilibre — le
  premier retrait de résistance qui ne tient pas à un état) ; `SURE_STATE` (Conjonction,
  Mauvais œil) ; `Explosion.put()` (Quintessence, Fausse note, Triple éclat) ; le sol de la
  Nappe brûlante (Chaudron) ; la vie d'un objet posé du Brasero (Chaudron) ; `DamageType.ELEMENTS` et le tour (Chatoiement,
  Métamorphose, Jettatura, Canon, Mélange, Émulsion) ; `Player.buff_mods()` et les lignes par charge
  (Arpège, Exacerbation) ; le signal `slew` (Autocatalyse) ; `Familiar.ECHO_DELAY`
  (Rémiges) ; le compte des lancers de Trinité (ce qui se verse au Chaudron).
- **Le neuf qui touche au moteur** : la **conversion d'un sort entier** en un élément
  (Incarnation) ; un **corbeau qui frappe de lui-même** (Becquée) ; une **réaction qui ne
  consomme pas** et sa garde de 0,5 s (Enzyme) ; des **charges qui tombent une à une**
  (Rubato) ; le **Chaudron** entier, forme `CAULDRON`.
- **Dessin** (`/dessiner-un-effet`) : la Becquée (le corbeau qui fond et remonte), l'aura de
  l'Incarnation autour de la sorcière, le **chaudron** (sur planche, avec son icône de
  compétence), l'éclat de la Quintessence (trois
  couleurs dans `Explosion`), le mauvais œil au sol. Les vignettes des 79 nœuds passent par
  `tools/node_icons.py` ; ses palettes sont par nature (`NATURES`), et un nœud des trois
  éléments à la fois (Quintessence, Conjonction, Émulsion…) en demandera une mêlée.
- **Ce qui se multiplie** : le Précipité sous le Prisme (une réaction par trait), l'Enzyme
  rejouée par le Familier, l'Autocatalyse et la Pierre philosophale (chaînes bornées par la
  garde de 0,5 s), l'Aura et la Becquée (une requête de cercle par seconde), l'Écume et les Bulles. À
  remesurer sur `world/stress_test.tscn`.
- **Livraison** arbre par arbre, chacun avec ses tests et ses vignettes : Projectile,
  Catalyse, Trinité, Amplification, Familier — puis le Chaudron, avec sa planche, et le
  départ de la Poupée. `docs/ARBRES.md` se régénère ; les
  couloirs d'équilibrage se relèvent avant → après, sans les corriger (jalon 13, §7).

### Les questions

1. **Le Chaudron à la place de la Poupée** : un sol qui bout dans l'élément de votre
   dernier sort et déborde quand il a reçu les trois. Écartés : des **orbes élémentaires**
   qui tournent autour de la sorcière (trop proches de l'Épée spirale et du Marteau
   béni), une **tourmente** qui erre (l'Orbe gelée, le Nuage d'orage), un **rayon** tenu (le
   Faisceau du jalon 48). Le Chaudron, ou l'un d'eux ?
2. **Le Familier tourné vers les éléments** — la Becquée, le Mauvais œil : il garde ce qu'il
   fait, mais ses nœuds neufs posent des états. D'accord ?
3. **L'Incarnation** convertit tous les sorts en un seul élément pendant l'amplification, et
   coupe la Trinité sans la Métamorphose. D'accord sur l'échange (+20 % plus → +10 %) ?
4. **L'Enzyme** : les états restent après la réaction, avec une garde moteur de 0,5 s par
   ennemi. D'accord, ou préférer qu'elle ne garde qu'**un** des états de la paire ?
5. **Les points mis dans la Poupée** reviennent au personnage, à dépenser ailleurs.
   D'accord ?

## 4. Les réponses

L'utilisateur, sur la proposition : « va pour le chaudron, oui pour le familier, oui, oui,
oui ».

- **le Chaudron** remplace la Poupée de chiffon ;
- **le Familier** se tourne vers les éléments (Becquée, Mauvais œil) ;
- **l'Incarnation** : +20 % plus → +10 %, la Trinité coupée sans la Métamorphose ;
- **l'Enzyme** : les états restent, un même ennemi réagit au plus toutes les 0,5 s ;
- **les points de la Poupée** reviennent au personnage.

Livraison arbre par arbre : Projectile, Catalyse, Trinité, Amplification, Familier, puis le
Chaudron avec sa planche, et le départ de la Poupée.

## 5. Les six arbres et le Chaudron — livrés

| arbre | nœuds | points | suites |
|---|---|---|---|
| Projectile élémentaire | 7 → 13 | 33 | Chatoiement, Spectre, Conjonction |
| Trinité | 6 → 13 | 34 | Coda, Renversement, Fausse note |
| Amplification des sorts | 6 → 13 | 34 | Aura, Métamorphose, Triple éclat |
| Catalyse | 7 → 14 | 33 | Ferment, Détonateur, Pierre philosophale |
| Familier | 6 → 13 | 34 | Croassement, Jettatura, Canon |
| **Chaudron** *(neuf)* | 13 | 31 | Bulles, Émulsion, Lie |

**79 nœuds, 18 suites.** La Poupée de chiffon et ses six nœuds sont partis.

### Ce qui est neuf au moteur

- **Quarante nombres** de `SkillStats`, d'`EQUILIBRIUM` à `LEES`, chacun lu à un seul
  endroit — ARCHITECTURE, « Qu'est-ce qu'un nœud peut allumer ? ».
- **`StatusEffects.ELEMENTAL`** : les trois états de la sorcière, que la Catalyse, l'Arpège,
  la Modulation, la Saturation et le Mauvais œil lisent. Il quitte `Catalysis`.
- **`StatusEffects.expose()`** (Équilibre) : le premier retrait de résistance qui ne tient pas
  à un état — rien ne se montre, rien ne se consomme ; `resistance_lost()` l'ajoute.
- **`Catalysis.react()`** devient statique : la Catalyse et le Précipité passent par lui. **La
  garde de 0,5 s** (`REACTION_GUARD`) vaut pour toute réaction.
- **`SkillStats.lasting_of()`** : la durée d'un état tiré — le Frimas (jalon 44) y entre avec
  l'Arpège ; `StatusEffects.extend()` ne raccourcit plus un état que son lancer a allongé.
- **`SkillStats.tinge()`** (Diapason) et **`bounce_turns`** (Chatoiement, mis à la part de
  l'écho par `echoed()`).
- **`Cauldron`** (`actors/skills/cauldron.gd`) et la forme `CAULDRON`, **à la place de `DOLL`**,
  même entier. `Player._after_spell()` lui verse chaque sort. Le Familier ne le rejoue pas.
- **Partis** : `RagDoll`, `EffectForge.doll()`, le détournement du Transfert dans
  `Player._on_damaged()`, la poupée dans `Enemy.foe()`, `doll_life`, `grudge`, `transfer`,
  `lure`, leurs textes et leurs tests. Les points placés dans la Poupée reviennent au livre
  (`Manual.points_spent()`, jalon 48).

### Les écarts avec la proposition

- **Le Précipité ne réagit pas avec le lancer du trait** : ses +200 % de chance d'état
  reposaient aussitôt ce que la réaction venait de consommer (vu au test). La réaction part
  d'une copie sans eux.
- **Le Diapason passe une part des dégâts** (10 % par point) dans l'élément précédent, qui tire
  son état par la règle commune — plutôt qu'une chance de poser un état sans coup.
- **La Modulation : 0,3 s par point**, pas 0,25 : la fiche l'écrivait « +0.3 ».
- **L'Incarnation prend l'élément du dernier sort lancé** (le feu s'il n'y en a pas), et son
  échange est une ligne « −10 % plus » sur les sorts : les « plus » se multiplient, donc
  ×1,2 × 0,9 = **+8 %**, pas +10 %.
- **La Saturation : 25 % de chance par point**, à chaque coup, pas « une fois par seconde ».
- **L'Aura et la Becquée frappent d'une part du dernier sort** (10 % par point), état sûr —
  l'Aura toutes les 1 s à 40 px, la Becquée toutes les 1 s sur le plus proche à 120 px.
- **L'Autocatalyse** : tout tué de la Catalyse, cercle compris, sème à 20 px par point.
- **La Pierre philosophale** repose les trois états **à coup sûr**, pas à 50 % de force.
- **L'Enzyme se relie à l'Exothermie (2) ou au Grand cercle (2)** : depuis l'Amorce, son lien
  passait sous le Grand cercle.
- **Le Chaudron** : le **Couvercle** n'est plus « −10 % de recharge » — la Récurrence vise déjà
  cette ligne (`test_trees_share_no_line_and_no_name`) — mais **le débordement à sa fin**, de
  ce qui a été versé ; le **Mélange** passe à 1 point, ses deux états posés à coup sûr comme
  tout bouillon ; la **Décoction** se relie au Trop-plein (1) ou au Bouillonnement (2), le
  lien depuis Feu doux passant sous Mijotage.
- **Le Chaudron garde sa recharge de 3 s** : sans elle, le relancer le remplaçait avant son
  premier bouillon — le banc des arbres le mesurait à 0/s. Sa description tient en une ligne
  pour que la fiche tienne dans le cadre (`test_the_sheet_stays_in_frame`).

### Les tests

Trente tests neufs dans `test_shapes.gd` (un par mécanique, souvent deux nœuds ensemble),
un dans `test_status_effects.gd` (l'ouverture qui se referme) ; les cinq de la Poupée partis,
celui du Familier qui « part avec ses points » refait avec le Chaudron, le Tempo mesuré sur
l'Amplification. **Campagne : 1 489 tests, tous passés.**

Vu en route : trois libellés débordaient de la fiche de nœud (« résistance ouverte aux autres
éléments », « dégâts par élément déjà passé », « durée des états élémentaires ») — raccourcis.
Ma suppression des tests de la Poupée avait emporté l'en-tête du Brasero et son `_brazier()` :
remis.

### Le banc des arbres

`tools/balance.sh trees only=elemental_projectile,catalysis,cauldron` (Trinité,
l'Amplification et le Familier ne frappent pas).

| | paquet | duel |
|---|---|---|
| Projectile, meilleur au paquet | 1 249/s ×13,0 (807 ×8,30 avant) | 772/s ×6,97 |
| Projectile, meilleur au duel | 1 039/s ×10,8 | 1 139/s ×10,3 (602 ×5,40 avant) |
| Catalyse, meilleur au paquet | 2 387/s ×6,41 (×4,87 avant) | 199/s ×3,68 |
| Catalyse, meilleur au duel (Enzyme, Quintessence) | 939/s ×2,52 | 747/s ×13,8 (×5,01 avant) |
| Chaudron, meilleur au paquet | 468/s ×6,13 | 53,9/s ×2,43 |

Jamais pris : le Chatoiement ; la Conductivité, la Distillation, le Ferment ; au Chaudron, le
Trop-plein, le Philtre, le Couvercle, la Décoction, les Bulles et la Lie — **le banc ne lance
que le Chaudron**, rien ne s'y verse, il ne déborde jamais. Le Projectile au duel et la
Catalyse sous l'Enzyme montent fort : **à régler quand l'utilisateur le demandera**
(jalon 13, §7).

**Couloirs** (`tests/run.sh balance`) : 20 échecs avant, 20 après, **identiques** ligne à
ligne — aucun personnage fixe ne porte la sorcière.

### La performance

`world/stress_test.tscn` patché sur une copie, 300 grunts collés, vie à 1e9, 240 images de
chauffe puis 1 440 ; trois tours alternés de cinq scénarios (moyenne de la physique) :

| scénario | physique | img/s |
|---|---|---|
| base : Projectile, Prisme 2 | 8,29 ms | 165 |
| Projectile : Prisme, Ricochet 2, Chatoiement, Spectre, Précipité, Équilibre | 8,38 ms | 165 |
| Catalyse (Enzyme, Ferment, Quintessence, Pierre, Autocatalyse) + Projectile + Familier | 8,32 ms | 165 |
| Chaudron (Émulsion, Écume 3, Bulles 2) + Projectile | 8,57 ms | 165 |
| Projectile sous l'Amplification (Incarnation, Aura 2, Métamorphose) | 8,20 ms | 165 |

Tout est dans le bruit du banc (±0,5 ms d'un tour à l'autre, même scénario). Pire image :
11,8 ms.

### Ce qui reste au jalon

- **Les dessins** (`/dessiner-un-effet`, planche choisie par l'utilisateur) : le **chaudron**
  — dessin provisoire, la coupe du Brasero sur la brûlure de son cercle —, la **Becquée** (le
  corbeau ne fond pas encore : le coup part de son épaule), le **Mauvais œil** au sol, l'**Aura**
  de l'Incarnation.
- **Les icônes** : celle du Chaudron (provisoirement celle de la Poupée), et **une vignette par
  nœud** pour les 79 — `tools/node_icons.py`, palette mêlée pour les nœuds des trois éléments.
- **Le guide** (menu Échap), en fin de jalon : l'article « Résistances » ne cite que la
  malédiction comme retrait de résistance ; l'article sur les réactions proposé au jalon 41
  n'existe toujours pas.

## 6. Premiers retours — corrigés avant les planches

### Ce que l'utilisateur a demandé

> « En fait je n'aime pas catalyse, donc je veux un autre sort à la place, ne fait rien pour
> l'instant on verra ça après. »

Puis, dans l'ordre de son message :

- **Partout** : une résistance baissée se voit comme un état, une icône par type de dégâts ;
  l'Amplification et la Trinité ne sont ni des sorts ni des éléments, ce sont des **buffs**.
- **Projectile élémentaire** : le Précipité doit dire ce que fait chaque réaction, et ce que
  veut dire son pourcentage — le détail chiffré dans la fenêtre Alt. La Triade sous
  l'Incarnation : trois boules de son élément. Sous la Triade, les trois mots-clés comptent ;
  sous l'Incarnation, seul celui de son élément.
- **Amplification** : le Contrecoup, un rayon plus grand d'entrée et des dégâts plats qui
  montent avec le niveau et s'additionnent avec le temps que le buff a duré, bornés ; la
  Résonance, une contrepartie qui empêche de rester sous le buff indéfiniment ; sous
  l'Incarnation, l'icône du buff prend la couleur du prochain sort.
- **Chaudron** : « aux trois » et « déborde » ne se comprennent pas, ni le Couvercle.
- **Trinité** : le Tempo à un seul point de 0,1 s ; le Rubato à un seul point ; la Fausse note,
  un rayon bien plus grand, lu sur la fiche ; l'Arpège, « durée des états élémentaires aux
  sorts ».
- **Familier** : l'écho en feu de l'Éclair vif garde l'ancien éclair recoloré en orange —
  chaque sort élémentaire doit avoir un visuel par élément quand une couleur ne suffit pas,
  pour l'instant l'Éclair vif seul.

### Ce qui est fait

| retour | réponse |
|---|---|
| Catalyse | **rien**, comme demandé. Le Précipité emprunte ses réactions (`Catalysis.react()`) : elles devront survivre au sort qui la remplacera |
| résistance baissée | `StatusEffects.opened()` : les natures dont `resistance_lost()` est positif — Équilibre, malédiction, fontes. La barre de vie les dessine après les états, `StatusIcon.lowered()` : une flèche qui descend, **provisoire**. `expose()`, sa fermeture et une première fonte émettent `change` |
| buffs | mot-clé `buff`, donné par la forme `BUFF` à tous les buffs ; `Skill.bare_buff` sur l'Amplification et la Trinité ne garde que lui. Un affixe le vise : **de la Persistance**, durée des buffs, trois paliers, bijoux |
| Précipité | description refaite (les trois cas, élément par élément), ligne « +20 % du trait par réaction » ; la fenêtre Alt du Projectile liste les réactions, à la part du Précipité |
| Triade et Incarnation | **l'Incarnation passe dans `Skill.resolve()`** (`incarnated`) : mots-clés, affixes et fourchettes ajoutées suivent son élément. Une Triade d'une seule nature garde trois comètes d'un tiers. Hors Incarnation, la Triade porte les trois mots-clés |
| Contrecoup | ligne `recoil` : 1 dégât de foudre par seconde brûlée et par point, accru de 10 % par niveau du joueur, compté sur `RECOIL_MOST` = 10 s au plus (`Buff.lived`, que la Résonance ne rembobine pas). Rayon 15 → **30 px par point**. Au niveau 1, trois points et dix secondes : 30, la moyenne de l'ancienne ligne ; au niveau 30, 117 |
| Résonance | chaque prolongation vaut **80 %** de la précédente : trois points (0,9 s) rendent au plus 4,5 s sur toute la vie du buff |
| icône de l'Incarnation | le HUD teinte l'icône et son cadre de l'élément du prochain sort (`Player.lit_incarnation()`) |
| Chaudron | « déborder » devient **exploser** partout où le joueur lit : la description dit « explose une fois les trois éléments lancés », le Couvercle « quand sa durée s'achève, le chaudron explose aussi, dans les éléments lancés depuis sa dernière explosion » |
| Trinité | Tempo 1 point (0,1 s), Rubato 1 point, Fausse note **100 px** au lieu de 40 — ligne « fausse note » sur la fiche —, Arpège « durée d'état élémentaire aux sorts » |
| Éclair vif en feu | **à la planche** : c'est un dessin |

### Les écarts

- **L'Arpège** lit « +4 % durée d'état élémentaire aux sorts » et non « durée des états
  élémentaires » : la forme demandée débordait de 11 px sur la fiche du nœud
  (`test_passive_and_node_sheets_fit_in_both_languages`).
- **La description du Chaudron** est courte pour la même raison : deux lignes de plus
  sortaient sa fiche du cadre de 4 px.
- **Trinité** tombe à **29 points** (34 − 4 du Tempo − 1 du Rubato), sous les 30 de la règle
  du §2. À rattraper à la passe d'équilibrage, ou par un point de plus ailleurs dans l'arbre.
- **Ni sort ni élément**, l'Amplification ne prend plus les affixes « aux sorts » ni ceux de
  foudre, les niveaux en bonus compris, et un ennemi tué par le Contrecoup ne déclenche plus le
  Siphon. Les autres buffs (Soif de sang, Tombeau, Clarté, Électricité statique, Nécrose)
  gardent leur cadence et leur nature, et gagnent `buff`.
- Le **Contrecoup** reste en foudre sous l'Incarnation ; le Triple éclat le répartit toujours.

### Les tests

Neuf de plus ou complétés : `test_the_bare_buffs_wear_buff_alone`,
`test_a_recoil_grows_with_the_time_burned_and_the_level`, `test_an_opened_resistance_is_told_and_listed`,
`test_a_triad_under_the_incarnation_sends_three_comets_of_its_element`, et des affirmations
ajoutées aux tests de la Triade (trois mots-clés), de l'Incarnation (mot-clé, icône du HUD), de
la Résonance (la deuxième s'amenuise), du Contrecoup (ses dégâts au plafond) et des
déclenchements de la sorcière (les réactions du Précipité). Le test du Tempo passe à un point :
la règle a changé, pas la mesure. Campagne : **1 493 tests, tous passent**.

Banc des arbres refait sur les quatre arbres touchés : le Projectile au duel ×10,3 → ×10,8,
le Chaudron ×2,43 → ×2,80, du bruit de tirage ; la Trinité et l'Amplification, des buffs, n'y
sont pas mesurées.

### Ce qui reste au jalon

- ~~La Catalyse~~ : remplacée par les Glyphes, §9.
- ~~Les planches~~ : faites, §7.
- ~~Les icônes~~ : faites, §8, sauf la Catalyse.
- **Le guide**, comme au §5 — l'article « Résistances » dira aussi les icônes.

## 7. Les planches — dessinés

Sept planches (`hns-captures-planches-jalon49` sur le Bureau), quatre à six variantes chacune,
regardées avant d'être montrées : la bulle du chaudron sortait en losange, les flammes sous la
marmite passaient devant elle, l'icône « écu percé » se lisait « + », les petits yeux étaient
trois traits — refaits avant la question. Une variante de feu en langues de flamme y a été
ajoutée.

| sujet | choisi | où |
|---|---|---|
| Chaudron | 1, « marmite à pieds » | `EffectForge.cauldron()`, quatre temps de bulles par teinte, deux grains de vapeur |
| Zone du Chaudron | 5, « couronne de bulles » (planche `08-zone-du-chaudron`, demandée après coup : la brûlure seule ne disait pas où il frappe) | `EffectForge.cauldron_rim()` : une bulle tous les 11 px au rayon, quatre tailles, une sur sept crevée, qui change à chaque temps ; 0,54 ms par temps au rayon 50, 0,86 au rayon 72 |
| Becquée | 1, « piqué » | `EffectForge.crow_dive()`, `Familiar._dive()` : arc de `DIVE_ARC`, aller et retour de `DIVE_TIME`, l'éclat du bec (`EffectForge.strike()`) |
| Mauvais œil | 1, « l'œil au sol » | `Witchcraft.eye()`, posé par `EvilEye` sur le calque du sol |
| Aura | 3, « cercle de runes » | `Buff._aura_ring()` |
| Résistance baissée | 3, « flèche sur disque sombre » | `StatusIcon.LOWERED`, le fond `x` |
| Explosion de foudre | 2, « couronne d'arcs » | `Lightning.ring()`, `Explosion._storm()` |
| Éclair vif en feu / en froid | 6, « javelot ardent » / 7, le javelot de glace | `Fire.javelin()` par `Frost.shaped_javelin()` ; le froid avait déjà le sien |

**Un changement de règle, pas seulement de dessin** : la Becquée frappe désormais **à
l'arrivée** du corbeau, `DIVE_TIME` (0,18 s) après la période, et plus à l'instant où il part.
Le test de la Becquée attend donc le piqué. Le javelot ardent vaut pour **tout tir du joueur
passé au feu** dans `Projectile`, comme le javelot de glace pour le froid depuis le jalon 35.

**Vu à la capture** (`hns-captures-jalon49-en-jeu` sur le Bureau) :

- le premier temps de l'œil, fermé, était un trait de cent pixels qui se lisait comme un rayon
  posé au sol : il s'ouvre maintenant au tiers ;
- au milieu d'un paquet, le piqué fait vingt pixels et ne se voit pas : capturé devant le
  mannequin de la ville, à 90 px, il monte, fond ailes repliées, frappe et revient ;
- l'icône de résistance, posée par la barre de vie, garde ses ailes de flèche à neuf pixels.

**Mesuré** (`tools/planche.sh`, banc headless) : l'anneau de foudre, 0,75 ms par temps au rayon
30, 0,84 au rayon 45, 1,68 au rayon 90 (pire temps 2,37), fabriqué à la première explosion de
chaque rayon puis gardé ; l'œil, 1,7 à 2,8 ms par temps pixel par pixel, **0,04 ms** par
rangées ; la marmite, 0,41 ms ses quatre temps par teinte ; le javelot ardent, 2,5 ms ses 32
caps, chacun à sa première demande.

## 8. Les icônes — posées

Skill par skill (`hns-captures-icones-sorciere` sur le Bureau : la planche des trois tirages,
puis l'arbre en jeu) : **78 vignettes** et les **six icônes de compétence**, toutes par
Qwen-Image et la palette `witch` de `tools/node_icons.py` — les Glyphes (§9) compris, faits
après coup. Le **Chaudron** a enfin la sienne, une marmite violette ;
`rag_doll.png` est supprimée, avec les calques de la Trinité et de la Poupée dans
`tools/icon_layouts.py` et l'option `violet` de `tools/skill_icons.py`, qui ne servaient plus.

Refaits avant d'être posés : la Récurrence (la rune sortait en lettre « R »), les Ailes noires
et le Ressassement (du noir sur le fond violet), la Jettatura (deux yeux sortent en visage), le
Canon, et au Chaudron le Couvercle, l'Émulsion et la Lie. Les pièges vont dans
`resources/icons/LISEZMOI.md`. Gardés : le Diapason et la Dissonance se ressemblent à 32 px ; la Lie reste faible (une
marmite sombre et sa lie violette).

## 9. Les Glyphes — à la place de la Catalyse

L'utilisateur n'aimait pas la Catalyse. Cinq pistes proposées (glyphes, rayon canalisé, balai,
orbes, cercle de protection), **les Glyphes** retenus, et leur arbre accepté tel que proposé.

**Le sort** : un piège tracé au point visé, dans l'élément de son propre tour. Armé en 0,5 s,
il éclate sur le premier ennemi qui entre dans son cercle de déclenchement (16 px), frappe
son cercle (36 px) et pose son état à coup sûr. Trois au plus par lanceur, le corbeau à part ;
les trois éléments armés se relient, et le triangle frappe toutes les 1 s ce qui s'y tient,
à 50 % d'un coup partagé en trois.

| nœud | rôle | ce qu'il fait |
|---|---|---|
| Encre, Paraphe, Craie | simples | dégâts, rayon de l'éclat, durée |
| Calligraphie, Gravure | simples | armement −15 %/pt ; déclenchement +25 %/pt (deux nombres neufs que la forme apporte, `Skill.SHAPE_NUMBERS`) |
| Palimpseste | majeur | l'éclat fait réagir l'état d'un autre élément, 50 % d'un coup par point |
| Entrelacs | majeur | deux glyphes armés se relient : le fil frappe ce qui le traverse, 15 %/pt |
| Leurre | majeur | tire vers le glyphe les ennemis à 40 px/pt, par à-coups |
| Signature | majeur | un coup reçu trace un glyphe à vos pieds, au plus toutes les 3 s |
| Sceau | majeur | un seul grand glyphe ; chaque sort l'emplit de son élément ; relancé ou à sa fin, il éclate de 150 % par élément versé |
| Réécriture, Trame, Contresceau | suites | le glyphe qui a fait réagir se retrace dans l'élément suivant ; les fils posent les deux états ; le Sceau éclaté laisse un glyphe par élément |

**Au moteur** : `Glyph` (`actors/skills/glyph.gd`), la forme `GLYPH` à la place de
`CATALYSIS`, même entier ; les réactions quittent la Catalyse pour **`Reactions`**
(`actors/skills/reactions.gd`), que le Précipité et le Palimpseste partagent — sans la
nappe de la Vapeur, l'Arc fourchu, la Conductivité ni l'Enzyme, partis avec leurs nœuds.
`Player._sign()` (Signature), `Glyph.pour_all()` dans `_after_spell()` (Sceau). Le Leurre
pousse les ennemis plutôt que de passer par `Enemy.foe()` : un ennemi qui s'en prenait au
glyphe s'arrêtait à portée d'attaque, hors du déclenchement, et n'avait pas de hurtbox à frapper.
**Partis** : `Catalysis`, ses dix nombres (`reaction_power`, `primer`, `distillation`…), le
sceau de `Witchcraft`, ses tests, ses textes, et dans les outils d'icônes le calque
(`icon_layouts.py`) qui ne servait plus qu'à elle.

**Les planches** (`hns-captures-planches-jalon49`, 09 à 11) : le **cercle runique** (contre le
cercle d'alchimie, la rune nordique, le pentacle, la craie, le losange), le **fil de lumière**
(contre les pointillés, la trame seule, la chaîne de runes, l'arc crépitant), le Sceau à
**trois logements** (contre les anneaux, les tiers d'anneau, la cire). Captures en jeu :
`hns-captures-glyphes-en-jeu`, a à g. Vu à la capture : l'éclat du Sceau, un anneau d'un pixel,
se perdait au sol — doublé d'un anneau sombre. Le glyphe sous un ennemi est en partie caché :
il est au sol, sous les corps, comme le Mauvais œil.

**Mesuré** (`tools/planche.sh`, banc headless, une fois par morceau puis gardé) : le glyphe
0,3 ms, son éclat 0,5 ; un fil 0,13 ms à 100 px ; la trame du triangle 0,4 ms à 100 px, 1,2 à
200 — 4,1 en balayant tout son cadre, ramenée par rangées sur les seules colonnes gardées ;
le Sceau 0,5 ; son éclat 0,1 ms, 4,2 par `PixelCanvas`.

**Banc des arbres** : sans arbre 225/s au paquet ; meilleur au paquet Encre, Sceau, Contresceau,
Palimpseste, Réécriture, **×7,96** ; jamais pris : Paraphe, Craie, Calligraphie, Gravure,
Entrelacs, Leurre, Signature, Trame. Le Sceau et son Contresceau dominent — l'équilibrage se
fait en dernier (jalon 13, §7).

**Icônes** : 13 vignettes et l'icône du skill, comme les autres arbres (§8). Gardées faibles :
la Gravure, la Trame (un métier à tisser) et le Contresceau.
