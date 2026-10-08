# Hack'n'slash top-down — jalon 43

Suite des jalons 1 à 42. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 7 octobre 2026.** Les arbres du **manuel de la foudre** repris comme ceux des
flammes au jalon 42.

---

## 1. Ce que l'utilisateur a demandé

« À la manière du manuel des flammes dans le précédent jalon, un nouveau jalon qui cette
fois va se charger du manuel de la foudre. » Les demandes du jalon 42, §1, valent telles
quelles : un peu plus de nœuds, aucun nœud qui revient d'un arbre à l'autre, des nœuds
originaux par compétence, des **suites** derrière ce qui change le jeu, quelques
interactions, quelques leviers simples. Et ce que le feu a ajouté en route : **une vignette
par nœud** (jalon 42, §14), arbre par arbre.

## 2. La règle du jalon

Celle du jalon 42, §2 : la foudre entre dans `UNIQUE_TREES` quand ses cinq arbres sont
repris — **aucun nom ni aucune ligne** ne revient d'un arbre à l'autre, sauf un nœud de
dégâts, de rayon et de durée par arbre, et les échanges entiers. Une suite n'a qu'un parent,
et ne lit que des nombres que ce parent fait servir.

**Un nom ne double pas non plus un autre manuel.** Cinq noms de la foudre sont déjà pris
ailleurs : ils changent ici (tableau ci-dessous). Le froid reprendra les siens au jalon
suivant.

**Cible** : celle du feu — 13 à 21 nœuds par arbre, 30 à 40 points pour un pool de 20,
deux à quatre nœuds que seule la compétence a, une à deux suites par nœud qui change le jeu,
une interaction dans deux arbres sur cinq au plus.

Inspirations relevées : dans PoE, l'*Arc* qui ne s'use pas sur un ennemi électrocuté et le
*Galvanic Field*, le *Storm Brand* qui revient sur sa cible, la *Ball Lightning* qui foudroie
en passant ; dans Last Epoch, le *Teleport* qui laisse sa trace et se recharge sur ce qu'il
touche, le *Static* qui se charge en courant ; dans Diablo II, le *Charged Bolt* qui part en
grappe et le *Thunder Storm* qui frappe ce qui approche ; dans Torchlight Infinite, les
décharges qui bifurquent.

## 3. Le manuel de la foudre — la proposition

### Ce qui se répète aujourd'hui

| ligne | arbres qui la portent | où elle reste |
|---|---|---|
| Étincelles (chance d'état) | Éclair vif, Chaîne, Nuage, Ruée | **Chaîne**, renommée — la Surtension et la Conductance en ont besoin |
| Point chaud (critique) | Éclair vif, Chaîne, Nuage | **Éclair vif** — le tireur, celui qui tire le plus de dés |
| Surtension (explosion des tués) | Éclair vif, Chaîne | **Chaîne** — l'arbre de la meute |
| explosion finale | Chaîne (Foudre au bout), Nuage (Coup de tonnerre), Ruée (Coup de tonnerre) | **Ruée** — son arrivée est son seul coup, comme l'Atterrissage du feu |
| vitesse d'incantation (buff) | Ruée, Électricité statique | **Ruée** |

### Noms pris ailleurs

| nom | pris par | devient |
|---|---|---|
| Étincelles | Boule de feu | **Fourmillements** |
| Éclats | Pics de glace | **Esquilles** |
| Réflexe / Réflexes | Pics et Nova de glace | **Vif-argent** (Chaîne), **Vivacité** (Ruée) |
| Élan | Ruée ardente, Frappe lourde | **Impulsion** |
| Isolant, Sobriété | Carapace de givre | **Mise à la terre**, **Faible courant** |

Conventions du jalon 42 : chiffres de **premier réglage**, « relié à (n) » = points demandés
dans le parent, ⇄ marque un échange, **neuf** = un nombre de `SkillStats` à écrire, 🔗 =
interaction avec une autre compétence, **↳** = suite, accessible par son seul parent.

### Éclair vif — le tireur *(11 → 19 nœuds, 37 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Surcharge *(gardé)* | 4 | +8 % dégâts plus | — |
| Célérité *(gardé)* | 3 | +20 % vitesse de projectile | — |
| Point chaud *(gardé)* | 3 | +25 % chance critique — **le seul critique du manuel** | — |
| Fourche *(gardé)* | 2 | +1 éclair en éventail ⇄ −10 % plus | Surcharge (1) |
| Transpercement *(gardé)* | 2 | traverse un ennemi de plus | Célérité (1) |
| Rebond *(gardé)* | 3 | repart vers l'ennemi le plus proche | Célérité (2) ou Fourche (1) |
| **Esquilles** *(les Éclats)* | 2 | se brise en éclats en fin de course | Transpercement (1) |
| Trait de glace *(gardé)* | 1 | conversion au froid | Surcharge (2) |
| Orbe statique *(gardé)* | 1 | transformation : l'orbe lent qui foudroie en passant | Point chaud (3) |
| **Emballement** *(neuf)* | 3 | **tirer sans relâche fait chauffer le canon** : chaque lancer à moins de 1 s du précédent donne +4 % de vitesse d'incantation par point, cinq fois au plus ; une pause plus longue fait tout retomber | Surcharge (1) |
| **Paratonnerre** *(neuf)* | 1 | **le premier ennemi touché devient un paratonnerre pendant 3 s** : les éclairs suivants s'incurvent vers lui, à 200 px — viser une fois, puis tirer en courant | Point chaud (2) |
| **Électrocution** *(neuf)* | 1 | **un coup critique de l'éclair engourdit à coup sûr** | Point chaud (2) |
| ↳ **Plein régime** *(neuf)* | 1 | **à cinq cumuls d'Emballement, un tir sur quatre part double** : deux éclairs l'un derrière l'autre, au même cap | Emballement (3) |
| ↳ **Foudre héritée** *(neuf)* | 1 | quand le paratonnerre meurt, **la marque passe à l'ennemi le plus proche**, avec le temps qui lui restait | Paratonnerre (1) |
| ↳ **Cible de l'orage** 🔗 *(neuf)* | 1 | **chaque frappe de vos Nuages d'orage tombe aussi sur le paratonnerre**, où qu'il soit à 300 px du nuage | Paratonnerre (1) |
| ↳ **Carambolage** *(neuf)* | 2 | **l'éclair rebondit aussi sur les murs**, une fois par point, sans user de rebond | Rebond (1) |
| ↳ **Satellite** *(neuf)* | 1 | **l'orbe ne file plus droit : il tourne autour de vous** à 60 px le temps de sa course, et foudroie ce qui approche | Orbe statique (1) |
| ↳ **Orbe chargé** *(neuf)* | 2 | chaque ennemi traversé **grossit l'orbe** : +10 % de rayon de ses décharges par ennemi et par point, cinq fois au plus | Orbe statique (1) |
| ↳ **Glace vive** *(neuf)* | 3 | le trait de glace **ajoute 10 % de ses dégâts en foudre par point contre les transis** | Trait de glace (1) |

*Retirés* : Étincelles (Chaîne), Surtension (Chaîne).

### Chaîne d'éclairs — la meute *(11 → 16 nœuds, 31 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Haute tension *(gardé)* | 4 | +8 % dégâts plus | — |
| Ramification *(gardé)* | 2 | +1 cible | — |
| **Vif-argent** *(le Réflexe)* | 2 | −10 % temps du geste | — |
| Court-circuit *(gardé)* | 1 | −1 cible ⇄ +35 % plus | Haute tension (2) |
| Arc tendu *(gardé)* | 2 | +25 px de portée des sauts | Ramification (1) |
| Crescendo *(gardé)* | 3 | +10 % par saut | Ramification (2) |
| **Fourmillements** *(les Étincelles)* | 3 | +15 % chance d'état — **la seule du manuel** | Haute tension (1) ou Vif-argent (1) |
| Surtension *(gardé)* | 1 | un engourdi tué explose — **la seule explosion des tués du manuel** | Fourmillements (3) |
| Toile d'arcs *(gardé)* | 1 | transformation : un arc par ennemi proche | Ramification (2) ou Court-circuit (1) |
| **Conductance** *(neuf)* | 1 | **un saut vers un engourdi ne compte pas** : la chaîne le traverse sans s'user — plus la meute est engourdie, plus elle court | Fourmillements (1) |
| **Bifurcation** *(neuf)* | 3 | **à chaque saut, 10 % de chance par point que la décharge se divise** : une seconde chaîne part vers un autre ennemi avec les sauts qui restaient ; une branche ne bifurque plus | Arc tendu (1) ou Crescendo (1) |
| **Retour par la masse** *(neuf)* | 2 | **après sa dernière cible, la décharge revient à vous** et rend 1 mana par ennemi touché, par point | Vif-argent (1) |
| **Relais** 🔗 *(neuf)* | 1 | **la chaîne saute aussi sur vos charges statiques** (Électricité statique, Sillage statique) comme sur des ennemis : chaque charge prise éclate aussitôt, à la force du saut | Arc tendu (2) |
| ↳ **Ramure** *(neuf)* | 2 | **chaque arc de la toile saute encore une fois** depuis sa cible, à 40 % par point | Toile d'arcs (1) |
| ↳ **Survoltage** *(neuf)* | 2 | **l'explosion d'un engourdi tué relance une chaîne** de deux sauts depuis lui, à 30 % par point ; elle ne relance rien à son tour | Surtension (1) |
| ↳ **Réamorçage** 🔗 *(neuf)* | 1 | **chaque charge prise par le Relais rend un saut** à la chaîne | Relais (1) |

*Retirés* : Point chaud (Éclair vif), Foudre au bout (l'explosion finale va à la Ruée).

### Nuage d'orage — la tempête *(10 → 15 nœuds, 31 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Cumulonimbus *(gardé)* | 4 | +8 % dégâts plus | — |
| Front orageux *(gardé)* | 3 | +15 % rayon | — |
| Orage durable *(gardé)* | 3 | +20 % durée | — |
| Averse *(gardé)* | 2 | frappe plus souvent ⇄ dure moins | Cumulonimbus (1) |
| Orage errant *(gardé)* | 1 | dérive vers l'ennemi le plus proche | Orage durable (1) |
| Grêle *(gardé)* | 1 | conversion au froid | Cumulonimbus (2) |
| Orage portatif *(gardé)* | 1 | transformation : l'orage vous suit | Orage durable (2) |
| **Accumulation** *(neuf)* | 3 | **une frappe qui ne trouve personne charge le nuage** : la suivante qui touche frappe 20 % plus fort par point et par charge, cinq au plus — poser le nuage d'avance | Cumulonimbus (1) |
| **Appel d'air** | 3 | **l'orage aspire** : chaque frappe attire les ennemis vers son centre (`pull`, déjà lu par `Targets.strike_circle`) | Front orageux (1) |
| **Débordement** *(neuf)* | 2 | **chaque frappe déborde** : un arc part de la zone vers un ennemi hors du cercle, jusqu'à deux fois son rayon, à 40 % par point | Front orageux (2) |
| **Foudre jumelle** *(neuf)* | 2 | **chaque frappe a 10 % de chance par point de tomber deux fois**, la seconde 0,1 s plus tard | Averse (1) |
| ↳ **Point de rupture** *(neuf)* | 1 | **à cinq charges, la frappe suivante tombe sur tout ce qui est à deux fois le rayon** | Accumulation (3) |
| ↳ **Traque** *(neuf)* | 1 | **l'orage errant ne lâche plus sa proie** : il la suit deux fois plus vite jusqu'à sa mort, et n'en change qu'alors | Orage errant (1) |
| ↳ **Front mobile** *(neuf)* | 2 | l'orage porté frappe 8 % plus souvent par point **tant que vous marchez** | Orage portatif (1) |
| ↳ **Verglas** | 2 | **la grêle gèle plus fort** : +15 % d'effet du transi par point, qui ralentit d'autant | Grêle (1) |

*Retirés* : Étincelles (Chaîne), Point chaud (Éclair vif), Coup de tonnerre (l'explosion
finale va à la Ruée).

**Le nuage n'a pas de limite simultanée** (pas de `simultaneous` dans `storm_cloud.tres`).
Débordement et Foudre jumelle multiplient ses frappes, le Familier le rejoue : proposé,
**trois nuages par lanceur**, les plus anciens se dissipent sans coup final — la règle des
invocations (jalon 41).

### Ruée d'orage — l'éclair qui court *(9 → 15 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Persistance *(gardé)* | 3 | +25 % durée de l'Appel du tonnerre | — |
| **Impulsion** *(l'Élan)* | 2 | −10 % recharge | — |
| Foulée *(gardé)* | 3 | +4 % vitesse de déplacement (buff) | — |
| **Vivacité** *(les Réflexes)* | 3 | +4 % vitesse d'incantation (buff) — **la seule du manuel** | Persistance (1) |
| Insaisissable *(gardé)* | 2 | +10 % esquive (buff) | Foulée (1) |
| Coup de tonnerre *(gardé)* | 3 | explosion à l'arrivée — **la seule explosion finale du manuel** | Impulsion (1) |
| Sillage statique *(gardé)* | 2 | sème des charges statiques sur le trajet | Coup de tonnerre (1) |
| Sans répit *(gardé)* | 1 | plus de recharge ⇄ geste bien plus long | Impulsion (2) |
| **Trait d'éclair** *(neuf)* | 1 | **vous devenez l'éclair** : un éclair relie votre départ à votre arrivée et frappe tout ce qu'il traverse, de ses propres dégâts de foudre ajoutés ⇄ l'Appel du tonnerre dure moitié moins | Coup de tonnerre (2) ou Impulsion (2) |
| **Tension accumulée** *(neuf)* | 3 | **la course charge vos mains** : votre prochain sort de foudre, dans les 3 s, inflige 5 % de dégâts plus par point et par 100 px parcourus, 300 px au plus | Foulée (2) |
| **Réarmement** *(neuf)* | 2 | **chaque engourdi que frappe l'arrivée raccourcit la recharge** de 0,15 s par point | Coup de tonnerre (1) |
| ↳ **Aller-retour** *(neuf)* | 1 | **1,5 s après un trait d'éclair, vous revenez à votre départ** par le même éclair, qui refrappe sa ligne | Trait d'éclair (1) |
| ↳ **Tonnerre roulant** *(neuf)* | 2 | l'arrivée **gronde encore deux fois**, à 0,4 s d'écart, 30 % du coup par point | Coup de tonnerre (2) |
| ↳ **Mines statiques** *(neuf)* | 1 | **les charges du sillage attendent** : elles ne mordent qu'un ennemi, mais trois fois plus fort et dans deux fois leur rayon | Sillage statique (1) |
| ↳ **Galop** *(neuf)* | 1 | **sous Sans répit, l'Appel du tonnerre se cumule** : chaque ruée en ajoute un, trois au plus | Sans répit (1) |

*Retiré* : Étincelles (Chaîne).

### Électricité statique — le champ *(9 → 14 nœuds, 31 points)*

Le champ garde ses lignes de buff. **À confirmer avant de l'écrire** : c'est un buff, comme
l'Ignition qui est partie au jalon 42 (§10) — s'il ne doit pas rester, il vaut mieux le
remplacer que lui faire un arbre.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Charge vive *(gardé)* | 4 | +3 % chance de charge statique | — |
| Potentiel *(gardé)* | 3 | +6 % dégâts de foudre accrus (buff) | — |
| **Mise à la terre** *(l'Isolant)* | 3 | +8 résistance à la foudre (buff) | — |
| Haute fréquence *(gardé)* | 3 | +6 % récupération de recharge (buff) | Potentiel (2) |
| **Faible courant** *(la Sobriété)* | 2 | −25 % de mana drainé | Mise à la terre (1) |
| Influx *(gardé)* | 2 | +0,5 mana/s (buff) | Faible courant (1) |
| Arc brûlant *(gardé)* | 2 | +10 % dégâts critiques (buff) | Haute fréquence (2) |
| Orage intérieur *(gardé)* | 1 | +20 % dégâts de foudre plus (buff) | Charge vive (4) ou Ionisation (2) |
| **Ionisation** *(neuf)* | 3 | **le champ engourdit autour de vous** : chaque seconde, 10 % de chance par point d'engourdir chaque ennemi à 60 px — de quoi semer des charges sans autre sort | Charge vive (1) ou Mise à la terre (1) |
| **Capacité** *(neuf)* | 2 | les charges statiques vivent 0,5 s de plus par point (`StaticCharge.LIFE` devient un nombre) | Charge vive (2) |
| **Choc en retour** *(neuf)* | 2 | **un ennemi qui vous frappe au corps à corps prend un arc de foudre**, des dégâts d'une charge statique par point | Mise à la terre (2) |
| **Condensateur** *(neuf)* | 2 | **chaque charge statique qui mord vous donne un cumul** ; à dix, votre prochain sort de foudre part avec +25 % de dégâts plus par point | Potentiel (1) |
| ↳ **Décharge totale** *(neuf)* | 1 | **à dix cumuls, le condensateur se vide de lui-même** en une nova de foudre autour de vous, sans attendre de sort | Condensateur (1) |
| ↳ **Cage de Faraday** *(neuf)* | 1 | **après un choc en retour, plus rien ne vous atteint pendant 1 s**, une fois toutes les 5 s | Choc en retour (1) |

*Retiré* : Réflexes (la vitesse d'incantation va à la Ruée).

### Récapitulatif

- **50 → 79 nœuds**, dont **20 suites** ; ~30 nombres neufs dans `SkillStats`. Deux arbres
  sur cinq ont une interaction : l'Éclair vif (Cible de l'orage, vers le Nuage) et la
  Chaîne (Relais et Recharge, vers les charges de l'Électricité statique et de la Ruée).
- **Pas d'interaction avec un autre manuel** : le Trait de glace et la Grêle, avec Glace
  vive et Verglas, touchent déjà au froid par leur conversion. L'interaction entre manuels
  ira plus naturellement au jalon du froid, qui pourra lire l'engourdi.
- **Chaque arbre a son rôle** : l'Éclair vif le critique et le tir soutenu, la Chaîne
  l'engourdi et la meute, le Nuage la zone tenue, la Ruée le placement et l'explosion
  finale, le champ les charges statiques.
- **Ce qui se réutilise** : `Lightning.chain()` pour tout arc neuf (Débordement, Retour par
  la masse, Bifurcation, Survoltage, Choc en retour, Trait d'éclair) ; l'orbe de
  `Lightning.orb()` pour le Satellite ; `pull` pour l'Appel d'air ; le buff à charges de la
  Soif de sang pour le Galop et le Condensateur ; `StaticCharge` pour le Relais et les Mines.
- **Dessin** (`/dessiner-un-effet`) : la marque du paratonnerre, le sol de verglas, la
  jauge du condensateur. Les vignettes des 79 nœuds passent par `tools/node_icons.py`, avec
  la palette `lightning` (jalon 42, §14).
- **Ce qui se multiplie** : Bifurcation, Relais, Survoltage et Foudre jumelle font naître des
  arcs depuis des arcs. Chacun est borné (une branche ne bifurque plus, un survoltage ne
  relance rien) ; à remesurer sur `world/stress_test.tscn` une fois la Chaîne livrée.
- **Livraison** arbre par arbre, chacun avec ses tests et ses vignettes, dans l'ordre :
  Éclair vif, Chaîne, Nuage, Ruée, puis le champ s'il reste. La foudre entre dans
  `UNIQUE_TREES` au dernier. **`docs/ARBRES.md` se régénère** ; les couloirs d'équilibrage
  se relèvent avant → après, sans les corriger (jalon 13, §7).

## 4. Les réponses

L'utilisateur, sur la proposition : « ok ». Et sur les trois questions :

- **l'Électricité statique reste**, avec l'arbre du §3 ;
- **trois nuages par lanceur** au plus, les plus anciens se dissipent sans coup final ;
- **la Chaîne perd Foudre au bout** : l'explosion finale reste à la Ruée.

## 5. L'Éclair vif — livré

L'arbre du §3, **19 nœuds, 37 points**. Étincelles et Surtension sont parties (leurs points
reviennent à placer, comme ceux de l'Ignition) ; les Éclats s'appellent Esquilles. Deux
écarts au §3 :

- **l'Emballement n'a qu'un seuil** : un lancer à moins de `RAMP_HOLD` (1 s) du précédent
  ajoute un cumul, au-delà tout retombe. Deux seuils (0,6 s pour monter, 1 s pour retomber)
  ne se seraient pas lus ;
- **le Paratonnerre s'ouvre par le Point chaud (2)**, au-dessus de lui, au lieu de la
  Célérité : à côté d'elle, il coupait le lien de l'Orbe statique au Point chaud. Le
  détourner par le Transpercement en faisait une suite à l'écran — un petit rond —, ses
  deux parents changeant le jeu (`ManualCell.is_suite()`), vu à la capture
  (`hns-captures-arbre-foudre`).

```
                 Cible de l'orage  Paratonnerre  Foudre héritée          Orbe chargé
                  Électrocution    Point chaud                  Orbe statique  Satellite
 Plein régime  Emballement  Surcharge  [ÉCLAIR VIF]  Célérité  Transpercement  Esquilles
 Glace vive  Trait de glace            Fourche      Rebond     Carambolage
```

**Le paratonnerre est une classe à lui**, `LightningRod` : une marque par lanceur, qui suit
sa cible et que le projectile vise d'un virage borné (`ROD_TURN`, 9 rad/s) — un tir qui la
croise de loin la manque. La Cible de l'orage la lit depuis `StormCloud._strike()`.
**Sa marque est provisoire** (la charge statique au-dessus de la tête) : elle attend sa
planche, avec le reste du dessin de la foudre.

**La limite des trois nuages** est livrée avec : `StormCloud.put()` tient la liste et
dissipe les plus anciens du même lanceur. Sur la fiche, elle a rejoint la ligne de la
durée — « 3.0 s · 3 à la fois » — : une ligne de plus sortait la fiche du nuage de son
cadre de 5 px (`test_the_sheet_stays_in_frame`). Le serpent, le brasero et l'épée spirale
gagnent la même ligne.

Un test par mécanique (`test_shapes.gd`, « Éclair vif (jalon 43) »), et celui de la limite.

**Le banc** (`only=swift_bolt`), relevé après, sans correction (jalon 13, §7) :

| | avant | après |
|---|---|---|
| meilleur au paquet | ×11,9 | **×23,2** |
| meilleur au duel | ×3,13 | **×9,83** |

Les deux triplent ou presque. Au duel, l'Emballement, le Plein régime et la Glace vive ;
au paquet, **le Satellite** (×23,2, et zéro au duel : l'orbe tourne autour du lanceur, la
cible du banc est hors de son orbite). À reprendre à l'équilibrage, avec le reste du
manuel. Jamais pris : Transpercement, Esquilles, Paratonnerre, Électrocution, Foudre
héritée, Cible de l'orage, Carambolage — le banc ne voit ni les morts, ni les nuages, ni
les murs, et ne vise qu'une cible.

Le Nuage (`only=storm_cloud`) ne bouge qu'à l'Orage portatif au duel, ×3,37 → ×3,15 : porté
et prolongé, il dépassait trois nuages à la fois.

## 6. Les retours sur l'Éclair vif

1. **L'Orbe statique ne s'ouvre plus par le Rebond** : « l'un ne fonctionne pas si l'autre
   est alloué ». Le Point chaud (3) seul y mène.
2. **Le Plein régime ne doublait que l'éclair** : devenu orbe, rien ne partait. Il rejoue
   désormais le lancer entier (`Player._pose()`), orbe compris — et un Satellite double.
3. **Les satellites se répartissent autour du lanceur** : avec la Fourche, ils partaient
   en éventail à 8° et tournaient collés. Leur vitesse ne change pas — l'orbe fait les deux
   tiers d'un tour sur sa vie, et c'est voulu.   Au banc, le meilleur build au paquet passe de ×23,2 à ×19,7, et **touche enfin au duel**
   (×7,19, zéro avant) : un des satellites passe désormais sur la cible.

## 7. Le lag des satellites

L'utilisateur : « ça lag vraiment énormément s'il y a trop d'ennemis avec le petit éclair,
et encore plus avec le corbeau ». Mesuré sur `world/stress_test.tscn` en fenêtré, **300
grunts collés au joueur et rendus immortels** (des casters restaient à distance, hors de
l'anneau), le joueur lançant sans relâche un Éclair vif devenu orbe — Fourche 2,
Emballement 3, Plein régime, Satellite, Orbe chargé 2. 1 440 images après 240 de chauffe,
40 s au plus.

Trois coûts, chacun isolé en le coupant sur une copie :

| ce qui coûtait | mesure | remède |
|---|---|---|
| **le nombre d'orbes** : sans limite, ~40 au joueur, ~80 avec le corbeau | 8 771 coups/s, 5 img/s | **une limite d'orbes par lanceur** (`Skill.SHAPE_NUMBERS`), le Familier à part, les plus anciens se dissolvent |
| **un arc dessiné par cible touchée**, redessiné 18 fois par seconde | 467 ms par seconde de jeu à six orbes | **`Lightning.ARCS_MOST`, trois arcs par frappe** d'orbe ou de nuage ; les dégâts, à toutes |
| **un nombre et une gerbe par coup**, sans plafond | corbeau : 29 img/s, 164 sans retour visuel | **`HitFeedback.NUMBERS_MOST` (80) et `PARTICLES_MOST` (960)** |

Les coups eux-mêmes — atténuation, signaux, états — ne coûtaient que 24 ms par seconde.

| | avant | après |
|---|---|---|
| Satellite | 7 img/s | **164 img/s** |
| Satellite et corbeau | bloqué (moins de 1 680 images en 3 min) | **151 img/s**, aucune image au-delà de 25 ms |
| Éclair simple (référence) | 165 img/s | 165 img/s |

Avec les deux autres remèdes en place, douze orbes au lieu de six donnent 86 img/s avec le
corbeau, et sans limite 5 img/s : la limite reste nécessaire. Le plafond du retour visuel
vaut pour tout le jeu — un combat ordinaire ne l'atteint pas.

Au banc des arbres, la limite ramène le meilleur build au paquet de ×19,7 à **×16,1** à six orbes, **×17,2** à douze.

**Six orbes, c'était peu** pour l'utilisateur. Mesuré au même pire cas :

| orbes au plus | seul | avec le corbeau |
|---|---|---|
| 6 | 164 img/s | 151 img/s |
| 9 | 165 | 149 |
| 12 | 151 | 114 (86 à une autre mesure) |
| 16 | 164 | 55, avec des à-coups |

Retenu : **douze**. Une zone jouée compte ~70 ennemis, qui meurent : la marge y est large.

## 8. La Chaîne d'éclairs — livrée

L'arbre du §3, **16 nœuds, 31 points**. Point chaud et Foudre au bout sont partis — la
Chaîne ne lit plus l'explosion finale —, le Réflexe s'appelle Vif-argent, les Étincelles
Fourmillements. Un écart : **la Recharge devient le Réamorçage** — « recharge » est déjà
le mot du temps d'attente d'une compétence, la fiche les aurait confondus.

```
                       Conductance
 Survoltage  Surtension  Fourmillements  Vif-argent  Retour par la masse     Réamorçage
                       Haute tension  [CHAÎNE]  Ramification  Arc tendu  Relais
                       Court-circuit  Toile d'arcs  Crescendo  Bifurcation
                                      Ramure
```

**La décharge se fait en trajets** (`ChainLightning.Run`) : le tronc, puis ses branches,
tous choisis avant le premier coup, comme avant. Un saut gratuit — un engourdi sous la
Conductance, une charge sous le Réamorçage — ne s'use pas ; **douze sauts au plus** par
trajet (`CHAIN_JUMPS_MOST`), qu'une meute engourdie ne traverse pas l'écran. Une charge
prise par le Relais éclate en explosion de 20 px, de la force du saut. Le Survoltage passe
par `Player._on_slew()`, après l'explosion du tué, et relance en différé une chaîne de deux
sauts qui ne porte plus ni explosion ni Survoltage.

Sous la Toile d'arcs, les nœuds des sauts ne servent plus (`IGNORED_BY_SHAPE`) ; la Ramure
saute à la portée d'un saut ordinaire, sans Arc tendu, que la fiche dit sans effet.

Sept tests (« Chaîne d'éclairs (jalon 43) ») ; celui de Foudre au bout est parti avec elle.
Capture : `hns-captures-arbre-foudre\3-arbre-chaine.png`.

**Le banc** (`only=chain_lightning`), relevé sans correction :

| | avant | après |
|---|---|---|
| meilleur au paquet | ×6,30 | ×5,26 |
| meilleur au duel | ×2,20 | ×2,31 |

Le paquet perd Foudre au bout et le critique ; la Ramure prend leur place. Jamais pris :
Arc tendu, Crescendo, Conductance, Bifurcation, Retour par la masse, Relais, Survoltage,
Réamorçage — la Toile d'arcs et sa Ramure passent devant tout ce qui saute, et le banc ne
voit ni le mana, ni les charges statiques, ni les morts.

## 9. Le Nuage d'orage — livré

L'arbre du §3, **15 nœuds, 31 points**. Étincelles, Point chaud et Coup de tonnerre sont
partis : le nuage ne lit plus l'explosion finale, qui reste à la Ruée seule. Un écart :
**le Verglas n'est pas un sol**, c'est la force du transi que la grêle pose déjà
(`chill_effect`) — le transi ralentit selon sa force, et un sol neuf n'aurait rien dit de
plus.

```
 Point de rupture  Accumulation  Débordement  Front orageux  Appel d'air
 Foudre jumelle    Averse       Cumulonimbus  [NUAGE]  Orage durable  Orage portatif  Front mobile
                                Grêle                  Orage errant
                                Verglas                Traque
```

**La frappe est coupée en deux** : `_strike()`, celle de la période — où errer, les charges
de l'Accumulation, le tirage de la Foudre jumelle —, et `_hit()`, l'impulsion, que la
seconde frappe rejoue sans recharger ni retirer. **Le Front mobile accélère l'horloge des
frappes**, et cette horloge-là n'est pas plafonnée par la durée : sans quoi le nuage
porté aurait frappé plus tôt, pas plus souvent.

Sept tests (« Nuage d'orage (jalon 43), ses nœuds ») ; celui du coup de tonnerre final est
parti. Capture : `hns-captures-arbre-foudre\5-arbre-nuage.png`.

**Le banc** (`only=storm_cloud`), relevé sans correction :

| | avant | après |
|---|---|---|
| meilleur au paquet | ×7,99 | **×15,4** |
| meilleur au duel | ×2,89 | ×3,68 |

Le paquet double : le Débordement et l'Accumulation y sont. Jamais pris : Appel d'air,
Point de rupture, Traque — le banc ne déplace pas les ennemis et ne compte pas le
regroupement.

## 10. Les retours sur le Nuage d'orage

1. **L'Appel d'air ne sert à rien sous l'Orage portatif** : porté, le nuage est centré sur
   son lanceur, et l'aspiration n'attire les ennemis que là où ils marchent déjà. Il ne
   mène plus à l'Orage portatif, et la forme le déclare ignoré (`IGNORED_BY_SHAPE`) : sa
   fiche dit « sans effet avec Orage portatif ».

## 11. La Ruée d'orage — livrée

L'arbre du §3, **15 nœuds, 30 points**. Les Étincelles sont parties ; l'Élan s'appelle
Impulsion, les Réflexes Vivacité. Deux écarts :

- **le Trait d'éclair n'est pas une transformation** : la Ruée d'orage est déjà un saut
  instantané, il n'y avait rien à transformer. C'est une mécanique — l'éclair du départ à
  l'arrivée —, qui porte **ses propres dégâts de foudre ajoutés** (6 à 14, ceux du Coup de
  tonnerre) : la ruée n'a pas de table de dégâts, et ouvert par l'Impulsion, il n'aurait
  rien frappé. Ouvert par le seul Coup de tonnerre, il se serait lu comme une suite ;
- **le Trait d'éclair est au-dessus du Coup de tonnerre**, pas à sa droite : son lien vers
  l'Impulsion passait sous lui.

```
                          Tension accumulée     Aller-retour
            Vivacité   Foulée   Insaisissable   Trait d'éclair   Réarmement
            Persistance  [RUÉE]  Impulsion      Coup de tonnerre Tonnerre roulant
                         Galop   Sans répit     Sillage statique
                                                Mines statiques
```

**Le Galop** reprend les charges de l'appel relancé, plus une. La première version en
posait deux dès la première ruée — le test l'a vu : `Player.buff_mods()` multiplie bien les
lignes par les charges, l'erreur était dans leur compte.

Sept tests (« Ruée d'orage (jalon 43) »). Capture : `hns-captures-arbre-foudre\7-arbre-ruee.png`.
La Ruée ne frappe pas d'elle-même : le banc des arbres ne la mesure pas.

Une incompatibilité sans chemin : **le Réarmement ne sert à rien sous Sans répit**, qui n'a
plus de recharge. Les deux ne se relient pas — l'un part du Coup de tonnerre, l'autre de
l'Impulsion — mais rien ne le dit sur la fiche ; Sans répit n'est pas une transformation.

## 12. L'Électricité statique — livrée, et le manuel entier

L'arbre du §3, **14 nœuds, 31 points**. Les Réflexes sont partis ; l'Isolant s'appelle
Mise à la terre, la Sobriété Faible courant. Deux écarts :

- **la Cage de Faraday rend intouchable**, plus « à l'abri de la foudre » : presque aucun
  ennemi ne frappe en foudre, le nœud n'aurait rien fait ;
- **le Choc en retour rend une part du coup reçu** (30 % par point), plutôt que « les
  dégâts d'une charge », qui n'ont pas de base fixe : une charge vaut une part du coup qui
  l'a laissée.

```
                     Cage de Faraday  Choc en retour
                     Ionisation  Mise à la terre  Faible courant  Influx
 Orage intérieur     Charge vive  [STATIQUE]  Potentiel  Haute fréquence  Arc brûlant
                     Capacité                 Condensateur
                                              Décharge totale
```

**Un buff lit ses nombres de mécanique sur son lancer résolu.** `Player.lit_number()` les
additionne sur les gestes allumés ; on ne l'appelle qu'à un événement rare — une charge qui
naît ou qui mord, un coup reçu au contact —, jamais à chaque coup porté. Les charges du
Sillage statique de la Ruée comptent pour le Condensateur et la Capacité comme celles du
champ.

Cinq tests (« Électricité statique (jalon 43) »). Capture :
`hns-captures-arbre-foudre\9-arbre-statique.png`. Un buff ne frappe pas : le banc des
arbres ne le mesure pas.

**La foudre entre dans `UNIQUE_TREES`** : aucun nom ni aucune ligne d'un arbre à l'autre,
et le test le confirme du premier coup. Il ne reste que le froid hors de la règle.

**Les couloirs d'équilibrage** (`tests/run.sh balance`) échouent comme avant le jalon, et
`docs/EQUILIBRAGE.md` n'a pas bougé : ils mesurent un personnage contre une zone, pas un
arbre.

### Ce qui reste au jalon

- ~~les vignettes des 79 nœuds et des cinq icônes~~ : faites, §14 ;
- **l'équilibrage**, en dernier : l'Éclair vif (×17 au paquet, ×10 au duel), le Nuage (×15
  au paquet) et la Chaîne, dont la Toile et la Ramure passent devant tout ce qui saute.

## 13. La marque du paratonnerre — dessinée

**Choisie sur planche** (`hns-captures-paratonnerre\1-planche-paratonnerre.png`, sept
partis pris en trois temps sur un grunt : une tige qui crache, un signe ⚡ qui flotte, une
cible au sol, des arcs autour du corps, trois étincelles en couronne, un losange, un éclair
qui tombe) : **la 7, « la foudre appelée »** — un éclair tombe du ciel sur la tête marquée
et y éclate, puis l'éclat seul, puis un autre éclair.

`Lightning.rod()`, à côté de la charge et de l'orbe : quatre formes gardées, l'éclair aux
formes paires, l'éclat seul aux impaires. **Huit formes par seconde** (`ROD_HZ`) et non
dix-huit comme le grésillement : l'alternance éclair-éclat y clignotait. Fabriquée une
fois, **0,12 ms la forme**.

**Vu à la capture** (`hns-captures-paratonnerre\17-marque-en-jeu.png`) :

- la première planche posait toutes les marques trop haut — le grunt a du vide au-dessus
  de la tête dans sa case — et la tige de la variante 1 était trop maigre pour se lire ;
- le gabarit de capture arrive **en ville**, où aucun paquet ne naît : une étape `area`
  l'envoie en zone ; les grunts de la zone 1 meurent au premier éclair et la marque avec
  eux — un grunt seul, immobile et sans fin de vie, les a remplacés pour la capture ;
- **l'éclair passe derrière la barre de vie** et l'icône d'état, qui restent lisibles.
  Gardé : par-dessus, il cacherait les PV. L'éclat se pose sur le haut du crâne
  (`LightningRod.HEAD`, 10 px au-dessus de `Hurtbox.overhead()`).


## 14. Une vignette par nœud — le manuel de la foudre

Les 79 nœuds et les cinq icônes de compétence, par le tuyau du feu (jalon 42, §14 ;
recette : `resources/icons/LISEZMOI.md`, « Icônes de nœuds ») avec la palette `lightning`.
**Arbre par arbre**, à la demande de l'utilisateur : chaque arbre posé, capturé en jeu et
validé avant le suivant. Captures sur le Bureau, `hns-captures-noeuds-foudre\` : les arbres
en `01`, `03`, `06`, `08`, `11`, les planches d'icône en `02`, `04`-`05`, `07`, `09`-`10`, `12`.

**Treize nœuds reprennent un tirage** (`from`), l'utilisateur préférant reprendre que
refaire : trois du feu — le Trait de glace le Givre, le Verglas le Gel intense (même effet),
l'Orbe statique l'Électrisé — et dix de la foudre même (le sablier de l'Orage durable pour la
Persistance et la Capacité, la Surcharge pour Haute tension et Potentiel, etc.).

**Ce qui a raté, et le remède** :

- **les personnages** — Satellite, Orage portatif, Front mobile, Choc en retour, et les
  icônes de la Ruée : une silhouette détaillée devient une bouillie à 24-32 px. Remplacés
  par un objet (une planète cerclée, un chapeau de mage sous son nuage, un bouclier hérissé)
  ou par le sujet sur deux jambes (le nuage qui court, l'éclair qui sprinte). L'icône de la
  Ruée garde une silhouette, au choix de l'utilisateur, en noir plein cerné d'éclairs ;
- **les nuages sombres** — Qwen les pose dans un ciel violet à l'horizon, que le détourage ne
  prend pas pour du fond : Cumulonimbus, Front orageux, Averse, Point de rupture et l'icône
  du Nuage refaits en nuage clair isolé. Cinq majeurs gardent leur nuage sombre, lisible en
  32 : l'utilisateur n'a pas voulu les refaire ;
- **l'icône de la Chaîne** — « un arc qui enchaîne trois points » sortait un éclair seul,
  le jumeau de l'Éclair vif ; refaite sur planche de quatre sujets (`05`), trois crânes
  qu'un arc relie ;
- Transpercement (l'éclair posé sur le bouclier, et non au travers : une planche fendue),
  Paratonnerre (le pylône sur sa maison, puis une tige trop fine : une pointe épaisse
  frappée, une étoile à l'impact), Coup de tonnerre (une botte boueuse : l'impact au sol).

Gardés faibles : le Rebond, le Satellite (sans sa lune), le Vif-argent (une main floue).

**Le tuyau a changé sur deux points** : `done_before()` relit le dossier de sortie de
ComfyUI, où chaque PNG porte son prompt — un redémarrage de la machine a vidé le cache
temporaire au milieu de l'Éclair vif, et rien n'a été recalculé ; `vignette()` reprend la
vignette posée d'un nœud repris dont le tirage a disparu. `skill_icons.py` passe la `nature`
au tuyau Qwen, qui ne connaissait que le feu.

**La carte a ralenti d'un facteur 15** au début du travail : 12 s par pas, 2 min par tirage.
Ni iCUE (5 Go de mémoire vidéo), ni le redémarrage de ComfyUI n'y ont rien changé ; le
redémarrage de la machine, si — 11-16 s par tirage ensuite.
