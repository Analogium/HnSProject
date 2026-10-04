# Hack'n'slash top-down — jalon 40

Suite des jalons 1 à 39. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 4 octobre 2026.** Les arbres du **Maître de la lumière**.

---

## 1. Ce que l'utilisateur a demandé

« Comme pour le jalon 38 avec le manuel de nécrose » : le dernier manuel repris, le
sacré (`manual_holy`). Même règle qu'aux jalons 38 et 39 — **pas de nœud qui revienne
d'un arbre à l'autre**, avec les mêmes trois exceptions (un nœud de dégâts, de rayon
et de durée par arbre au plus ; un échange ⇄ et le prix d'un nœud qui change le jeu
n'en comptent pas). Le sacré entre dans `UNIQUE_TREES` ; `SHALLOW_TREES`, dont il était
le dernier, disparaît.

## 2. L'état de départ

Le manuel le plus mince : **quatre compétences et un passif**, deux nœuds chiffrés sur
trois d'entre elles, convertis tels quels au jalon 34 (d'où `SHALLOW_TREES`). La Lumière
sacrée n'a pas d'arbre. Rien ne change la façon dont un geste se joue.

| compétence | forme | ce qu'elle fait | nœuds actuels |
|---|---|---|---|
| Frappe sacrée | `BEAM` | trait de 80 px qui frappe une fois tout ce qui est sur sa ligne | Percée (+12 % plus), Allonge du trait (+10 % rayon) |
| Pilier sacré | `PILLAR` | colonne au point visé, frappe son cercle toutes les 0,5 s pendant 2 s | Colonne (+10 % rayon), Jugement (+12 % plus) |
| Pulsation sacrée | `PULSE` | portée par le joueur, frappe son cercle toutes les secondes pendant 5 s | Litanie (+20 % durée), Ferveur (+12 % plus) |
| Lumière sacrée | `BUFF` | entretenue (5 mana/s) : Grâce, +6 rés. sacrée et +12,5 chance de bénir par point | — |
| Onction *(passif)* | — | +0,4 PV/s par point | pas d'arbre, comme Cœur de braise |

**L'identité du sacré** : ce qui **juge** (le trait qui perce, la colonne qui tombe
d'en haut), ce qui **bénit** — le béni inflige 20 % de dégâts en moins, c'est l'état
**défensif** du jeu —, ce qui **monte en puissance** (la litanie) et ce qui **protège
le porteur** (la grâce, le soin). Pas de DoT (la nécrose), pas de critique (la foudre),
pas d'invocation.

## 3. Ce qui se réutilise tel quel

| nombre | sur | pourquoi ça marche déjà |
|---|---|---|
| `status_chance_increase` | Frappe sacrée | le sacré tire la bénédiction (`ROLLED`) ; Entaille la vise déjà au chevalier |
| `damage_vs_blessing` | Frappe sacrée | « contre les bénis » existe (`StatusEffects.AGAINST`) |
| `bounces` | Frappe sacrée | lu par `Projectile` (jalon 35) ; il suffit que `HolyBeam` le lise — le trait n'est pas un projectile, mais « rebond » n'est pas un nombre de projectile (à vérifier contre `test_projectile_numbers_only_on_a_projectile`) |
| `end_burst` | Pilier sacré | lu par le nuage, le vortex, le serpent, les morts-vivants ; `SacredPillar` à son extinction |
| `pull` | Pilier sacré | lu par `IceVortex` et `Cyclone` par `Targets.strike_circle(…, -pull)` ; le pilier frappe par la même fonction |
| `life_on_hit` | Pulsation sacrée | lu par `Player` (jalon 39) ; `HolyPulse._strike()` doit rendre le nombre touché |
| `period`, `duration`, `radius` | Pilier, Pulsation | `strikes_due()` les lit déjà |
| `mana_per_second`, lignes de buff | Lumière sacrée | Sobriété (jalon 35), les nœuds de buff de la Nécrose avancée (jalon 38) |

## 4. Ce qui est neuf

**a. La force de la bénédiction** — `blessing_effect`, le mécanisme `State.strength`
étendu à un cinquième état, la suite notée en mémoire : le béni inflige **`BLESSING` ×
force** de dégâts en moins (20 % → 23 % au premier point). Par `SkillStats.EFFECT_OF`,
donc lue sur la fiche (« béni · ×1.15 ») et dans la fenêtre Alt. Ne restera à force 1
que l'engourdissement.

**b. Des nombres de `SkillStats`** :

| nombre | ce qu'il fait | lu par |
|---|---|---|
| `blessing_effect` | §4a | `StatusEffects`, par `strength_of()` |
| `wave_gain` | chaque onde frappe plus fort que la précédente, en points de pourcentage « plus » par onde déjà partie | `HolyPulse`, comme `jump_gain` pour la chaîne |
| `aureole` | tant que la lumière brûle, les ennemis dans ce rayon sont bénis | `Buff`, une requête de cercle toutes les 0,5 s |

**c. Deux formes neuves** :

- **Croix de lumière** (Frappe sacrée → `HOLY_CROSS`) : le trait part **dans les quatre
  directions** autour de soi, droit sur les axes — il ne vise plus. Même dessin, quatre
  fois ; sur les axes, la rastérisation est au moins cher (le pire cas mesuré, 1,16 ms,
  est la diagonale).
- **Pilier errant** (Pilier sacré → `DRIFT`) : la colonne **glisse vers l'ennemi le plus
  proche** pendant sa durée, au lieu de rester où elle est tombée. Même dessin, qui
  avance.

Plus deux nœuds qui changent le jeu sans être des formes — la pulsation et la lumière
tiennent un état chez le lanceur, comme l'orbite et le cyclone au jalon 39 : le
**Exaltation** et l'**Auréole**. L'Auréole demande un **dessin neuf** (planche).

`IGNORED_BY_SHAPE` : rien d'évident — la Réfraction rebondit depuis chaque bras de la
croix, l'attraction et l'effondrement suivent le pilier errant.

## 5. Les arbres — validés le 4 octobre, tels que livrés

Mêmes conventions qu'aux jalons 34 à 39 : chiffres de **premier réglage** ; « relié à
(n) » = points demandés dans le parent, un lien se prend dans les deux sens (jalon 39) ;
⇄ marque un échange. **21 à 22 points pour un pool de 20** dans chaque arbre.

### Frappe sacrée — la sentence

| nœud | pts | effet | relié à |
|---|---|---|---|
| Percée *(gardé)* | 5 | +12 % dégâts plus | — |
| Allonge du trait *(gardé)* | 3 | +15 % rayon (la longueur) | — |
| Sanctification | 4 | +15 % chance d'état (la bénédiction) | — |
| Réprobation | 3 | +20 % dégâts accrus contre les bénis | Percée (1) |
| Bénédiction profonde | 4 | +15 % effet de la bénédiction | Sanctification (1) |
| Réfraction | 2 | au bout de sa course, le trait repart vers l'ennemi le plus proche, une fois par point | Allonge du trait (1) |
| **Croix de lumière** | 1 | **le trait part dans les quatre directions, sans viser** ⇄ −30 % rayon | Percée (2) ou Réfraction (1) |

### Pilier sacré — le jugement d'en haut

| nœud | pts | effet | relié à |
|---|---|---|---|
| Jugement *(gardé)* | 5 | +12 % dégâts plus | — |
| Colonne *(gardé)* | 3 | +15 % rayon | — |
| Veille | 4 | +20 % durée | — |
| Glas | 3 | −10 % intervalle des impulsions | Jugement (1) |
| Appel céleste | 3 | chaque impulsion attire les ennemis vers le cœur | Colonne (1) |
| Effondrement | 3 | en s'éteignant, la colonne éclate, rayon 15 par point | Veille (1) |
| **Pilier errant** | 1 | **la colonne glisse vers l'ennemi le plus proche** ⇄ −25 % rayon | Jugement (2) ou Veille (2) |

### Pulsation sacrée — la litanie

| nœud | pts | effet | relié à |
|---|---|---|---|
| Ferveur *(gardé)* | 5 | +12 % dégâts plus | — |
| Litanie *(gardé)* | 4 | +20 % durée | — |
| Rayonnement | 3 | +15 % rayon | — |
| Cantique | 3 | ajoute 2 à 5 dégâts sacrés par point | Ferveur (1) |
| Absolution | 3 | chaque ennemi touché rend 1 PV par point | Litanie (1) |
| **Exaltation** | 3 | **chaque onde frappe 4 % plus fort par onde déjà partie, par point** — tenir la litanie jusqu'au bout | Cantique (1) ou Litanie (2) |

Avec Litanie 4, neuf ondes : la dernière à +96 % sous Exaltation 3, +48 % en moyenne.
`period` n'est visé que par Glas : l'intervalle va au Pilier, l'ajout de dégâts à la Pulsation.

### Lumière sacrée — la grâce

La Grâce garde ses lignes ; les nœuds de buff s'y ajoutent tant que la lumière brûle.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Zèle | 5 | +4 % dégâts sacrés accrus (buff) | — |
| Recueillement | 3 | −15 % mana drainé | — |
| Sérénité | 4 | −2 % dégâts subis (buff) | — |
| Cuirasse de foi | 4 | +30 armure (buff) | Sérénité (1) |
| Allégresse | 3 | +4 % vitesse de lancement (buff) | Zèle (1) |
| **Auréole** | 3 | **les ennemis à 20 px par point sont bénis tant que la lumière brûle** | Zèle (2) ou Sérénité (2) |

Toutes ces statistiques existent déjà sur la fiche (`armor`, `damage_taken`,
`cast_speed`) : aucune n'arrive sans son affixe.

## 5 bis. Ce que la livraison a changé à la proposition

Validée par l'utilisateur telle quelle (« ça me va »), le sacré dans `UNIQUE_TREES`.
Ce qui a bougé en chemin :

- **Psaume devient Cantique** (avant la validation) : le premier jet donnait −10 %
  d'intervalle au Pilier (Glas) et à la Pulsation (Psaume), la même ligne dans deux
  arbres. La Pulsation prend des dégâts sacrés ajoutés.
- **Crescendo devient Exaltation**, et son nombre `wave_gain` : « Crescendo » est déjà un
  nœud du manuel de foudre (`jump_gain`). Le nombre de l'Auréole s'appelle `aureole` :
  `Buff.HALO` existait.
- **`SHALLOW_TREES` disparaît** : le sacré en était le dernier ; une liste vide et ses
  deux gardes n'avaient plus rien à excepter.
- **`Player.heal()` devient publique** (ex-`_heal`) : la Pulsation rend ses PV
  d'Absolution depuis son nœud, comme la malédiction rend du mana par `gain_mana()`.
- **`Targets.strike_circle()` prend un facteur** : l'Exaltation multiplie le tirage de
  l'onde sans écrire une seconde fois « un tirage pour tout le cercle ».
- **L'Auréole pose l'état sans coup**, comme la malédiction : l'invariant 5 nomme les
  deux exceptions. Elle bénit pour la durée normale de l'état (4 s) — une durée courte
  aurait raccourci une bénédiction égale posée par la Frappe.

## 5 ter. Le dessin, les captures, les bancs

**L'Auréole, choisie sur planche** (`Bureau\hns-captures-aureole\`, six partis pris en
trois temps, au rayon de 60 px) : « couronne de grains » — un grain de lumière sur deux
et un pixel de son cœur entre eux, sur le cercle où elle bénit, qui tournent lentement —,
contre un anneau tramé au sol, des rayons de gloire, trois arcs qui se poursuivent, une
auréole au-dessus de la tête avec quatre bornes, et des croix semées. Refaites avant de
montrer la planche : les croix (5 et 6) étaient trop petites pour se lire, et douze
grains seulement sortaient en étoiles au hasard. **L'écart entre deux grains est gardé
à tout rayon** (`Buff.CROWN_SPACING`, 10,5 px) : à 20 px (Auréole 1), trente-six grains
feraient un anneau plein.

**Vu à la capture** (`Bureau\hns-captures-holy-jalon40\`, treize images, dans la première
zone) : la couronne se lit autour du joueur, et les ennemis qui y entrent portent l'icône
du béni (01-02) ; la Croix part sur ses quatre axes et frappe (03-04) ; le Pilier errant
glisse d'environ 70 px en une seconde vers le paquet (05-07) ; la Réfraction repart en
zigzag d'un ennemi à l'autre, deux rebonds sur l'image 13. **La première série était en
ville**, sans ennemis : `spawn_pack()` n'y fait rien. Le scénario entre d'abord dans la
première zone (`enter_area(1)`).

**Le banc des arbres** (`docs/ARBRES.md`, le sacré mesuré pour la première fois). Les
meilleurs builds rendent ×3,2 à ×5,1 au paquet, ×2,5 à ×6,1 au duel. Hors des critères
du jalon 37, rapportés au meilleur build sans transformation :

| | paquet | duel | |
|---|---|---|---|
| Croix de lumière | ×1,31 | ×0,63 | quatre bras au paquet ; au duel, un seul touche |
| Pilier errant | ×1,63 | ×1,00 | la colonne rejoint les cibles qu'elle ne couvrait pas |

Jamais pris, faute d'être vus par le banc : Sanctification et Bénédiction profonde (la
bénédiction ne fait que réduire les dégâts reçus), Appel céleste (les cibles du banc sont
immobiles), Rayonnement et Absolution. **Une bizarrerie de la recherche** : à la
Pulsation, le « meilleur au paquet » s'arrête à 8 points (×2,20) quand le meilleur au duel
rend ×3,32 au paquet. La recherche gloutonne s'y arrête alors qu'il reste des points :
pas encore compris, à regarder avec `measure=` avant de régler quoi que ce soit. **`tools/balance.sh trees only=…` réécrivait `ARBRES.md` avec
ses seules sections** : les cinq autres manuels ont été remis depuis git. Corrigé à la
demande de l'utilisateur : chaque compétence garde son numéro de section, et celles hors
de `only=` recopient leur section du rapport précédent (`_previous_sections()`). Vérifié
en remesurant la seule Pulsation : les 307 lignes restent, la section revient identique.

**Le banc de combat** (300 ennemis, la case lancée sans relâche, 240 images de chauffe
puis 1 440, cinq passes alternées) : Frappe sacrée nue **5,41 ms** (écart type 0,26)
contre **5,95** (0,39) en Croix de lumière avec Réfraction 2 — jusqu'à douze traits
rastérisés par lancer, `Holy.lance()` à chacun ; Pilier nu 5,12 (0,25) contre 5,05 (0,82)
en Pilier errant avec Effondrement 3 et Appel céleste, dans le bruit. **165 img/s
partout, 0 % du temps figé** : ni le trait ni la colonne ne gèlent.

**Relevé d'équilibrage** (`tests/run.sh balance`) : 4 couloirs sur 5 en échec, comme aux
jalons 38 et 39. Aucun des personnages fixes du jalon 13 ne porte le manuel sacré (Sort :
la foudre ; Mêlée : le chevalier) : l'avant et l'après sont les mêmes par construction.

## 6. Le déroulé

**Fait** : 1 à 5. **Reste** : le réglage des deux transformations hors critères (§5 ter)
au banc des arbres, quand l'utilisateur le demandera, comme aux jalons 38 et 39.

1. **Ce document**, et la validation du §5 par l'utilisateur — y compris
   `UNIQUE_TREES`.
2. **Le moteur** : la force de la bénédiction (§4a), les nombres (§4b), les lecteurs
   neufs (§3), `HOLY_CROSS` et `DRIFT` — chacun avec son test de forme, sur les vrais
   nœuds (`test_the_knight_transformations_carry_their_shapes`, jalon 39).
3. **Les arbres** dans `holy.tres`, descriptions comprises (relues contre le code).
4. **L'Auréole** sur planche (`/dessiner-un-effet`) ; capture fenêtrée de la Croix, du
   Pilier errant et de la Réfraction.
5. **`/valider`** : la campagne ; le banc de combat (Réfraction, Croix et Effondrement
   multiplient les coups) ; `tools/catalog.sh` ; `tools/balance.sh trees` avec le sacré
   dans `TREE_MANUALS` ; `tests/run.sh balance` relevé, sans correction. Le guide :
   la bénédiction dit que des nœuds du Maître de la lumière la renforcent. ARCHITECTURE
   et RECETTES dans le même geste.
