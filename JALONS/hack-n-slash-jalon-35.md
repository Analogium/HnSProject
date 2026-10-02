# Hack'n'slash top-down — jalon 35

Suite des jalons 1 à 34. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 1er octobre 2026.** Les arbres du **Maître de la foudre**.

---

## 1. Ce que l'utilisateur a demandé

Dans la continuité du jalon 34 : le manuel suivant, la foudre. Le système (pool par
compétence, réseau sans paliers, transformations, description obligatoire) ne bouge
pas ; on remplit cinq arbres.

## 2. L'état de départ

Deux ou trois nœuds chiffrés par compétence, convertis tels quels au jalon 34 (§6
nonies) : Surcharge, Fourche, Trait de glace ; Ramification, Haute tension,
Court-circuit ; Front orageux, Orage durable, Grêle ; Persistance, Sans répit.
**Électricité statique n'a pas d'arbre.** Aucun ne change la façon dont le sort se joue.

**L'identité de la foudre**, celle que les arbres doivent creuser : des coups
nombreux et rapides, le **saut** d'un ennemi à l'autre, le **critique**, et
l'**engourdissement** (+10 % de dégâts subis) avec la **charge statique** qu'il porte.

## 3. Ce qui se réutilise tel quel

Le vocabulaire du jalon 34 sert d'abord. Lus par des formes déjà écrites, donc
gratuits :

| nombre | sur | pourquoi ça marche déjà |
|---|---|---|
| `pierce`, `splits` | Éclair vif | lus par `Projectile`, quelle que soit la scène du tir |
| `kill_burst` | tous | `Player._on_slew()` ; la foudre tire l'engourdissement (`rolled_by()`) : « un engourdi tué éclate » |
| `end_burst` | Ruée d'orage | déjà lu par `_dash()` |
| chance critique, chance d'état, temps du geste, recharge | tous | lignes ordinaires |
| lignes de buff | Ruée d'orage, Électricité statique | `Skill.is_buff_line()` : une ligne qui ne vise pas un nombre du lancer va au buff |

## 4. Ce qui est neuf

**a. Des nombres de `SkillStats`** :

| nombre | ce qu'il fait | lu par |
|---|---|---|
| `bounces` | à l'impact, le tir repart vers l'ennemi non touché le plus proche, à portée de saut | `Projectile` (toute boule pourra s'en servir) |
| `jump_reach` | portée d'un saut de la chaîne, en plus de `ChainLightning.JUMP` | `ChainLightning` |
| `jump_gain` | chaque saut frappe plus fort que le précédent (« plus », cumulé) | `ChainLightning` |
| `trail_charges` | la ruée sème N charges statiques le long du trajet | `_dash()`, réutilise `StaticCharge` |

**b. `end_burst` et `seek_radius` lus par deux formes de plus** : la **dernière cible**
d'une chaîne éclate (`ChainLightning`) ; le nuage **éclate en se dissipant** et
**dérive vers l'ennemi le plus proche** (`StormCloud`).

**c. Trois transformations**, chacune sur une forme neuve :

- **Orbe statique** (Éclair vif → `ORB`) : un orbe lent qui foudroie ce qui passe
  près de lui pendant sa course. **Le seul visuel neuf** — par `/dessiner-un-effet`.
- **Toile d'arcs** (Chaîne d'éclairs → `WEB`) : plus de saut ; la décharge frappe d'un
  coup les N ennemis les plus proches, chacun depuis le lanceur. Le trait brisé
  existe déjà (`Lightning.chain()`), un par cible.
- **Orage portatif** (Nuage d'orage → `TEMPEST`) : le nuage se pose sur le lanceur et
  le suit. Même dessin que le nuage.

`IGNORED_BY_SHAPE` : `jump_reach` et `jump_gain` sous Toile ; `seek_radius` sous Orage
portatif ; `bounces` sous Orbe statique.

## 5. Les arbres — validés le 1er octobre

Mêmes conventions qu'au jalon 34 : chiffres de **premier réglage**, l'équilibrage en
dernier ; « relié à (n) » = points demandés dans le parent, un seul lien payé suffit ;
⇄ marque un échange. Environ 25 points pour 20 dans chaque arbre.

### Éclair vif — la mitrailleuse qui rebondit

| nœud | pts | effet | relié à |
|---|---|---|---|
| Surcharge *(gardé, réglé comme Attisement)* | 4 | +8 % dégâts plus | — |
| Célérité | 3 | +20 % vitesse de projectile | — |
| Point chaud | 3 | +25 % chance critique de base | — |
| Fourche *(gardé)* | 2 | +1 projectile ⇄ −10 % dégâts | Surcharge (1) |
| Étincelles | 3 | +15 % chance d'état | Surcharge (2) ou Point chaud (1) |
| Transpercement | 2 | traverse 1 ennemi par point | Célérité (1) |
| **Rebond** | 3 | rebondit sur 1 ennemi de plus par point | Célérité (2) ou Fourche (1) |
| Éclats | 2 | 1 éclat par point en fin de course, à 40 % | Transpercement (1) |
| Trait de glace *(gardé)* | 1 | devient froid | Point chaud (2) |
| Surtension | 1 | un engourdi tué éclate (50 %) | Étincelles (3) |
| **Orbe statique** | 1 | **un orbe lent qui foudroie autour de lui** pendant sa course ⇄ −50 % vitesse, ne frappe plus à l'impact | Rebond (2) ou Point chaud (3) |

### Chaîne d'éclairs — la longueur ou la largeur

| nœud | pts | effet | relié à |
|---|---|---|---|
| Haute tension *(gardé, réglé)* | 4 | +8 % dégâts plus | — |
| Ramification *(gardé)* | 2 | +1 cible | — |
| Réflexe | 2 | −10 % temps du geste | — |
| Court-circuit *(gardé)* | 1 | −1 cible ⇄ +35 % dégâts plus | Haute tension (2) |
| Arc tendu | 2 | +25 px de portée de saut | Ramification (1) |
| Étincelles | 3 | +15 % chance d'état | Haute tension (1) ou Réflexe (1) |
| **Crescendo** | 3 | +10 % dégâts plus par saut déjà fait | Ramification (2) |
| Point chaud | 3 | +25 % chance critique de base | Réflexe (1) |
| Foudre au bout | 3 | la dernière cible éclate, rayon 10 par point | Arc tendu (1) ou Crescendo (1) |
| Surtension | 1 | un engourdi tué éclate (50 %) | Étincelles (3) |
| **Toile d'arcs** | 1 | **frappe d'un coup les N plus proches**, sans saut ⇄ −20 % dégâts | Ramification (2) ou Court-circuit (1) |

### Nuage d'orage — posé, errant ou porté

| nœud | pts | effet | relié à |
|---|---|---|---|
| Cumulonimbus | 4 | +8 % dégâts plus | — |
| Front orageux *(gardé, réglé)* | 3 | +15 % rayon | — |
| Orage durable *(gardé, réglé)* | 3 | +20 % durée | — |
| Averse | 2 | −15 % d'intervalle entre les frappes ⇄ −10 % durée | Cumulonimbus (1) |
| Étincelles | 3 | +15 % chance d'état | Front orageux (1) ou Cumulonimbus (1) |
| **Orage errant** | 1 | le nuage dérive vers l'ennemi le plus proche | Orage durable (1) |
| Coup de tonnerre | 3 | éclate en se dissipant, rayon 12 par point | Orage durable (2) ou Front orageux (2) |
| Point chaud | 3 | +25 % chance critique de base | Averse (1) |
| Grêle *(gardé)* | 1 | devient froid | Front orageux (2) |
| **Orage portatif** | 1 | **le nuage vous suit** : +100 % durée ⇄ −25 % rayon | Orage errant (1) ou Averse (2) |

### Ruée d'orage — se battre en arrivant

Le buff « Appel du tonnerre » garde sa ligne de vitesse ; les nœuds de buff s'y
ajoutent tant qu'il brûle.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Persistance *(gardé, réglé)* | 3 | +25 % durée du buff | — |
| Élan | 2 | −10 % recharge | — |
| Foulée | 3 | +4 % vitesse (buff) | — |
| Réflexes | 3 | +4 % vitesse d'incantation (buff) | Persistance (1) |
| Insaisissable | 2 | +10 % esquive accrue (buff) | Foulée (1) |
| **Coup de tonnerre** | 3 | explose à l'arrivée : ajoute 6 à 14 foudre, rayon 10 par point | Élan (1) |
| Étincelles | 3 | +15 % chance d'état | Coup de tonnerre (1) |
| **Sillage statique** | 2 | sème 2 charges statiques par point sur le trajet | Coup de tonnerre (1) ou Foulée (2) |
| Sans répit *(gardé)* | 1 | −100 % recharge ⇄ +400 % temps du geste | Élan (2) |

### Électricité statique — un buff, comme Ignition

Que des lignes de buff, comme l'arbre d'Ignition : ce sort ne lance rien.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Charge vive | 4 | +3 % chance de charge statique | — |
| Potentiel | 3 | +6 % dégâts de foudre accrus | — |
| Isolant | 3 | +8 % rés. foudre | — |
| Choc | 3 | +12 % dégâts accrus contre les engourdis | Potentiel (2) |
| Sobriété | 2 | −25 % mana drainé | Isolant (1) |
| Influx | 2 | +0,5 mana/s | Sobriété (1) ou Charge vive (1) |
| Réflexes | 2 | +4 % vitesse d'incantation | Potentiel (1) |
| Orage intérieur | 1 | +20 % dégâts de foudre amplifiés | Choc (2) ou Charge vive (4) |

## 5 bis. Ce que la livraison a changé à la proposition

Validé par l'utilisateur tel quel (« Électricité statique peut rester un arbre de
nombres, fais au mieux »). Ce qui a bougé en chemin :

- **Choc** (+12 % contre les engourdis, sur les compétences de foudre) débordait la fiche
  de survol de 39 px (`test_largeurs`) : remplacé par **Haute fréquence**, +6 points de
  récupération de recharge.
- **Sobriété ne faisait rien** : `Buff` drainait le mana de la compétence, pas du lancer
  résolu. Il lit désormais les deux — brûlure et drain — sur le lancer, et
  `mana_per_second` devient un nombre que les nœuds visent (`LOWER_IS_BETTER`).
- **Le Rebond n'a pas de portée de saut** (demandé par l'utilisateur) : à 90 px, celle de
  la chaîne, il échouait dès que les ennemis s'espaçaient. Il prend l'ennemi non frappé
  le plus proche dans tout le reste de la course du tir, dans toutes les directions.
  En chemin : `core/` qui lisait `ChainLightning.JUMP` pour la description faisait
  échouer l'import entier sur un cycle de dépendances — la description ne cite plus
  de chiffre.
- **L'orbe** apporte sa durée, son rayon et son rythme par `Skill.SHAPE_NUMBERS`
  (2,5 s, 28, 0,25 s) : par une ligne de nœud, « +0,25 intervalle des frappes »
  s'écrivait en rouge. À −50 % de vitesse il ne frappait qu'une fois un ennemi en
  passant : **−60 %**, deux à trois décharges.
- **Sillage statique** n'est relié qu'au Coup de tonnerre : sans lui la ruée n'a pas de
  dégâts, et ses charges n'en porteraient pas.
- **Vu à la capture** (`Bureau\hns-captures-foudre-jalon35\`) : la Toile se lit — un arc
  par ennemi ; l'Orage portatif cachait la tête du personnage, relevé à
  `HEIGHT_CARRIED` ; **l'orbe se confondait avec une charge statique**, dont il reprenait
  l'étoile en provisoire.

**L'orbe, choisi sur planche** (`Bureau\hns-captures-orbe-statique\1-orbe-variantes.png`,
six partis pris en geste : boule de plasma, cage d'arcs, nuage miniature, noyau et
satellites, boule et halo au sol, l'étoile actuelle) : **« boule de plasma »** —
`Lightning.orb()`, une boule pleine au cœur blanc, deux ou trois arcs longs et maigres
qui changent d'une forme à l'autre. Refaites avant de montrer la planche : le nuage
miniature sortait en rocher fissuré (l'écueil du Météore), la boule et son halo en
sucette au-dessus d'un trou puis en grillage — un halo tramé se peint sans contour —, la
boule de plasma en microbe à quatre pattes courtes. **0,134 ms la forme**, fabriquée une
fois. Vu en jeu : `Bureau\hns-captures-orbe-statique-jeu\`.

**Le Trait de glace, choisi sur planche** (`Bureau\hns-captures-trait-de-glace\1-trait-de-glace-variantes.png`,
six partis pris en trois caps : javelot, éclat et flocons, flèche de givre, flocon
tournoyant, l'éclair du jeu en cyan, pointe et sillage cristallisé) — demandé par
l'utilisateur : l'Éclair vif converti retombait sur le glyphe tracé et additif de
`Projectile`, « l'ancien Éclair vif en bleu ». **« Javelot »**, `Frost.javelin()`, au cap
exact parmi 32, **0,093 ms le cap**, fabriqué une fois. Le tir de froid des casters reste
tracé, au choix de l'utilisateur, pour qu'on le distingue du sien. Refaits avant de
montrer la planche : le javelot en tube se lisait en crayon, le flocon tournoyant n'était
qu'une croix, et l'éclair cyan retracé à la main sortait en ver — remplacé par le vrai
`Lightning.dart`. Vu en jeu : `Bureau\hns-captures-trait-de-glace-jeu\`.

**Le banc de combat** (300 ennemis tenus, 240 images de chauffe puis 1 440, cinq paires
alternées) : l'Éclair vif nu contre le même avec Fourche 2, Transpercement 2, Rebond 3,
Éclats 2, Étincelles 3 et Surtension. **Physique 5,33 → 5,27 ms en moyenne**, dans le
bruit ; **164 img/s des deux côtés** ; 11 à 14 tirs en vol en fin de mesure contre 27 à 39.

**Relevé d'équilibrage** : `tests/run.sh balance` au commit du jalon 34 puis ici, **les
quatre mêmes échecs, messages identiques à la ligne** — aucun profil du banc ne prend un
nœud de foudre.

## 6. Le déroulé

**Fait** : 1 à 5. **Reste** : l'équilibrage, en dernier.

1. **Ce document**, et la validation du §5 par l'utilisateur.
2. **Le moteur** : les quatre nombres du §4a, les lectures du §4b, les trois formes —
   chacune avec son test de forme.
3. **Les arbres** dans `lightning.tres`, descriptions comprises (relues contre le code).
4. **L'Orbe statique** sur planche (`/dessiner-un-effet`) ; capture fenêtrée de la
   Toile, de l'Orage portatif et de l'explosion de foudre.
5. **`/valider`** : la campagne ; le banc de combat — rebonds, éclats et explosions
   en chaîne multiplient les coups ; `tools/catalog.sh` ; `tests/run.sh balance`
   relevé avant → après, sans correction. ARCHITECTURE et RECETTES dans le même geste.
