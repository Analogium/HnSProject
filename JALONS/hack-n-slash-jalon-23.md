# Hack'n'slash top-down — jalon 23

Suite des jalons 1 à 22. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé et livré le 19 septembre 2026.** L'arbre de passifs du jalon 19 avait 418
nœuds et 56 clusters, et deux défauts jumeaux : il ne disait **nulle part ce qu'un nœud
vaut**, si bien que deux clusters au même thème donnaient 5 et 10 % ; et il penchait
vers le **spécifique**, au point qu'une nature entière — le froid — n'avait aucun nœud
de dégâts. Ce jalon écrit l'échelle, puis étend l'arbre avec elle.

---

## 1. Le défaut

Relevé sur les petits nœuds de dégâts d'avant ce jalon :

| Portée | Ce qu'on y trouvait |
|---|---|
| `attack` | 5, 6 et 8 % |
| `melee` | 6 et 8 % |
| `area` | 6 et 8 % |
| `fire`, `lightning` | 8 et 10 % |
| `damage_vs_<état>` | 8, 10 et 12 % |

Aucune de ces variations ne suivait la profondeur : `damage@attack` valait **8 %** à
onze cases du départ (`strike`) et **5 %** à quarante-cinq (`whirl`). Chaque cluster
avait choisi son chiffre, et le dernier écrit gagnait.

Conséquence de jeu : un nœud **conditionnel** — « dégâts de feu accrus contre les
embrasés », qui n'agit que si la cible brûle — pouvait valoir **moins** qu'un nœud sans
condition. Le joueur qui lisait bien prenait toujours le large ; le thématique était un
piège.

Et les trous : **aucun** nœud `damage@cold` alors que le jeu a trois compétences de
froid, **aucun** nœud pour `cooldown_recovery` (créée au jalon 22), `damage_taken`,
`ignite_chance`, `chill_chance`, `blessing_chance` ni `static_charge_chance`.

---

## 2. La règle : l'échelle de spécificité

**Un petit nœud vaut ce que sa portée exige.** Plus elle est étroite, moins il sert
souvent, plus il donne.

| Palier | Ce que la ligne exige | Valeur |
|---|---|---|
| **large** | `attack` ou `spell` — la moitié du jeu | **8 %** |
| **étroit** | une nature ou une forme : `fire`, `cold`, `lightning`, `melee`, `projectile`, `area` | **10 %** |
| **conditionnel** | `damage_vs_<état>`, quelle que soit la portée | **12 %** |

Le sens de l'échelle est celui que la demande décrit : le conditionnel est **plus fort
mais moins utilisable**, le large est **plus faible mais toujours vrai**. La prime du
conditionnel est volontairement **petite** (+20 % sur l'étroit) : un build qui prend
`damage_vs_chill` prend aussi de quoi transir, donc la condition est tenue la plupart
du temps. Un écart plus large se mesurerait — or le banc ne compte pas les dégâts
contre un état (`docs/ARCHITECTURE.md`, « Quand un bonus contre un état s'applique-t-il
? ») : le chiffre est un arbitrage, pas une mesure, et il est écrit ici pour qu'on
sache lequel remettre en cause si le froid devient le meilleur build du jeu.

**Le notable en est libre.** Il porte deux lignes et vaut à peu près deux petits et
demi, répartis comme son thème le demande ; une table qui lui dirait sa première ligne
lui interdirait sa seconde. `test_each_small_damage_line_sits_on_the_specificity_scale`
ne juge donc que `Kind.SMALL`.

**Ce qui n'est pas des dégâts n'a pas de palier** : une résistance, une vitesse, une
chance d'état se calibrent sur l'affixe ou le passif qui donne la même statistique —
`chill_chance` vaut 10 par point dans le passif *Morsure du gel*, il vaut 10 sur un
petit nœud.

### La normalisation

**Vers le haut seulement** (décidé avec l'utilisateur) : aucun nœud existant ne perd de
valeur, **61 lignes** remontent à leur palier. Le plus gros écart comblé est
`whirl` et `spellblade`, à 5 et 6 % d'`attack`, montés à 8.

Aucun nœud n'était **au-dessus** de son palier : l'échelle reprend le haut de ce que
l'arbre disait déjà, elle ne l'invente pas. L'assertion qui l'a vérifié est dans le
script de migration, pas dans le dépôt — c'est le test qui garde la porte désormais.

---

## 3. Dix clusters de plus

418 → **476 nœuds**, 56 → **66 clusters**. Six sont des **hexagones** — six petits
nœuds autour de leur notable, la forme des clusters du troisième anneau (`rod`,
`guard`, `blight`) ; quatre sont des **chaînes** de trois petits nœuds finissant sur
leur notable, la forme d'`ember`, `shock` et `word`. Le placeur prend la seconde quand
la première ne tient pas sans serrer ses voisins (§4).

| Cluster | Forme · ancre | Petits nœuds | Notable |
|---|---|---|---|
| `drill` | hex · `inner_dex_str_2` | `damage@attack` 8 % | **Discipline** — 20 % d'attaque, +8 % de vitesse d'attaque |
| `creed` | chaîne · `far_str_int_2` | `damage@spell` 8 % | **Conviction** — 20 % de sort, +8 % de vitesse d'incantation |
| `hardening` | hex · `far_str_int_3` | −3 % de dégâts subis, rés. nécrotique et sacré, PV | **Cuir épais** — −7 % de dégâts subis, +8 % de PV |
| `respite` | chaîne · `far_int_dex_9` | `cooldown_recovery` +4 | **Reprise** — +10 de récupération, +10 % de mana |
| `floe` | chaîne · `dex_8` | `damage@cold` 10 % | **Cœur de glacier** — 20 % de froid, +15 % de chance de transir |
| `hoar` | hex · `far_int_dex_7` | `damage_vs_chill@cold` 12 % | **Givre profond** — 25 % contre les transis, +10 % de froid |
| `kindle` | hex · `far_str_int_6` | `ignite_chance` +10, `damage@fire` 10 % | **Brandon** — +20 % d'embrasement, 20 % de feu |
| `spark` | hex · `far_dex_str_1` | `static_charge_chance` +5, `damage@lightning` 10 % | **Décharge** — +10 % de charge statique, 20 % de foudre |
| `bless` | chaîne · `far_dex_str_2` | `blessing_chance` +10, rés. sacré | **Onction** — +20 % de bénédiction, 20 % contre les bénis |
| `relic` | hex · `far_str_int_9` | `damage_vs_blessing@spell` 12 % | **Jugement** — 25 % contre les bénis, ajoute 3 à 7 dégâts sacrés aux sorts |

Ils sont choisis pour ce qui manquait, dans cet ordre :

1. **Les statistiques sans un seul nœud** — `cooldown_recovery`, `damage_taken`, les
   quatre chances d'état. Ce sont les plus **génériques** de l'arbre : ils servent
   quel que soit le build, ce qui est exactement ce que la demande appelait « moins
   spécifique mais plus utilisable ».
2. **Le froid**, seule nature de mot-clé sans nœud de dégâts, avec ses deux clusters :
   l'inconditionnel (`floe`) et le conditionnel (`hoar`).
3. **Le large**, sous-représenté : six petits `damage@spell` dans tout l'arbre avant,
   neuf après ; dix `damage@attack`, seize après.
4. **La boucle chance d'état → dégâts contre l'état**. `kindle` donne de quoi embraser,
   `blaze` et `ember` donnent de quoi frapper l'embrasé : un thème se construit
   maintenant en deux gestes au lieu d'un.

**Deux clusters sont posés en deçà du troisième anneau** — `drill` à huit cases du
départ, `floe` à vingt et une : un nœud générique ne sert à rien s'il faut le niveau 60
pour l'atteindre. Les huit autres pendent du troisième anneau, faute de place ailleurs
(§4).

---

## 4. Arbitrages

**Pourquoi pas de portée « globale ».** « Dégâts accrus » sans mot-clé n'existe pas :
`SkillStats.DAMAGE` ne s'atteint qu'à travers une portée, et la fiche n'a pas de champ
de dégâts (invariant du jalon 19, repris dans `test_each_line_targets_the_sheet_or_a_cast_number`).
Ce n'est pas une limite gênante : **toute compétence porte `attack` ou `spell`**, donc
le palier large *est* le palier global, vu du build qui le prend. Ajouter un mot-clé
fourre-tout n'aurait donné qu'un second nom pour la même chose.

**Pourquoi pas de mot-clé `holy` ni `necrotic`.** Le manuel sacré vient d'arriver et
ses dégâts ne se ciblent que par `damage_holy@<portée>` et `damage_vs_blessing`.
Ajouter deux natures à `Keywords` demande de les poser sur chaque `.tres` de
compétence, de leur écrire leur `RECIPIENTS` et `QUALIFIERS`, et de leur donner un
affixe pour que la réserve reste honnête : c'est un jalon, pas une ligne. `bless` et
`relic` couvrent le sacré par ce qui existe.

**Pourquoi pas de clé de voûte.** Trois « plus » suffisent (jalon 17, §8), et un
quatrième aurait été le premier à ne pas terminer un axe.

**Pourquoi un hexagone.** Les clusters du troisième anneau en sont déjà un : six petits
autour d'un notable, reliés en boucle. La boucle a une vertu de règle, pas seulement de
dessin — `can_release()` rend un nœud du milieu d'une boucle, jamais une feuille seule,
donc un cluster en anneau se retouche sans être vidé. Là où il ne tient pas, la chaîne
de quatre nœuds prend sa place : elle est large de deux cases au lieu de six, et se
glisse entre deux clusters existants.

**Le placement a été cherché, pas dessiné.** Un script jetable essaie, pour chaque ancre
libre, chaque forme, distance et rotation, jusqu'à en trouver une qui tienne. Ce qu'il
refuse est **mesuré sur l'arbre du jalon 19**, jamais inventé :

| Plancher | Valeur | Ce qui casse en dessous |
|---|---|---|
| nœud ↔ nœud | **2 cases** | les pastilles font 6 px de rayon pour une case de 10 : à une case, elles se touchent |
| nœud ↔ lien étranger | **1 case** | les deux traits se confondent à l'œil |
| lien d'attache | **7,5 cases** au plus | le plus long lien d'avant en faisait 7,2 |

Plus une règle de forme : le centre du cluster est plus loin du départ que son ancre —
un cul-de-sac ne se replie pas vers l'intérieur.

**Le plancher nœud ↔ nœud n'était gardé par rien**, et une première passe a posé six
paires sous deux cases — dont deux à une seule case, où les pastilles se touchent.
`test_two_nodes_never_share_a_place` ne refusait que la **même case**, c'est-à-dire le
seul cas où le problème se voit déjà dans les données. Il devient
`test_two_nodes_never_crowd_each_other` et mesure la distance : la case partagée n'en
est plus que le cas extrême.

**Onze clusters étaient prévus, dix sont livrés.** Le onzième était un cluster de
résistances ; aucune ancre libre ne l'acceptait sans allonger son lien d'attache
au-delà de ce que l'arbre fait ailleurs. Ses résistances sont entrées dans `hardening`,
qui devient le cluster défensif générique au lieu de deux moitiés.

---

## 5. Un nœud qui troque sa recharge

Le jalon 22 avait laissé ceci en « Non fait » : *« Une recharge par nœud de talent :
aucun nœud ne vise `cooldown`, et la fiche ne l'annoncerait pas comme un nombre de
lancer. »* C'est fait.

**`use_time` et `recharge` entrent dans `SkillStats.LABELS`.** C'était toute la
serrure : `Skill._store()` ne range un modificateur que si ce dictionnaire connaît son
nom, et `StatMod.apply()` écrit ensuite le champ par son nom. `interval` n'y entre
**pas** — il se déduit des deux par un getter, le viser écrirait un nombre que
personne ne relit.

**Le nœud : « Sans répit »**, sur la Ruée d'orage (`storm_dash_unbound`, un seul point,
ouvert à deux points dans la compétence).

| Ligne | Effet |
|---|---|
| `recharge` −100 % | la recharge de 2,00 s **disparaît** |
| `use_time` +400 % | le geste passe de 0,35 s à 1,75 s |

**Effacer se dit par −100 %**, jamais par un plat négatif : l'accru annule la recharge
quelle qu'elle soit, là où un `−2,00 s` la ferait passer sous zéro sur une autre
compétence. Et rien de plus n'a été écrit pour cela : `interval = max(use_time,
recharge)` rend le geste seul dès que la recharge vaut zéro, et la page du manuel
n'affiche déjà sa ligne « recharge » que si elle est non nulle.

**Ce que le nœud échange**, et pourquoi c'est un échange :

| Vitesse d'incantation | Sans le nœud | Avec |
|---|---|---|
| ×1,0 | 2,00 s | 1,75 s |
| ×1,5 | 2,00 s | 1,17 s |
| ×2,0 | 2,00 s | 0,88 s |

La case quitte `cooldown_recovery` — qui ne peut plus rien pour elle — pour la vitesse
d'incantation, qui ne pouvait rien pour elle avant. Un personnage qui n'investit dans
ni l'une ni l'autre gagne 12 %, ce qui ne vaut pas le point ; c'est un nœud pour qui
monte la cadence, et c'est le propos.

**Un défaut d'affichage est tombé avec.** `SkillBarPanel` divisait la recharge restante
par `Skill.interval()` — **la compétence nue**, qui ne connaît pas les nœuds de la
case. Le voile aurait décrit une attente que personne n'avait. `Player` garde
maintenant ce que valait la recharge **au lancer** et rend la part lui-même
(`cooldown_ratio()`) ; les deux écritures passent par `_start_recharge()`, pour que le
total ne puisse pas cesser de décrire le reste.

---

## 6. Ce qui refusera un oubli

- `test_each_small_damage_line_sits_on_the_specificity_scale` (neuf) : la table des
  trois paliers, sur `Kind.SMALL`. **Une valeur hors table est une régression** — la
  corriger en changeant la table est exactement ce que le test existe pour empêcher.
- `test_each_node_has_its_icon` : les cinq statistiques de fiche neuves
  (`cooldown_recovery`, `damage_taken`, `ignite_chance`, `static_charge_chance`,
  `blessing_chance`) et le mot-clé `cold` ont demandé leur entrée dans
  `PassiveIcon.SHEET` et `SCOPED`, avec deux masques de plus (`frost`, `halo`, repris
  des icônes d'état).
- `test_two_nodes_never_crowd_each_other` (**renforcé**) : la même case est devenue
  « moins de deux cases », le plancher mesuré de l'arbre. C'est lui qui aurait refusé
  la première passe de ce jalon (§4).
- `test_no_two_links_cross`, `test_each_node_is_reachable_from_the_start` : les
  cinquante-huit nœuds neufs.
- `test_each_displayed_text_has_its_english` : les dix noms de notables et « Sans
  répit » dans `i18n/en.po`, plus le libellé « temps du geste ».
- `test_a_node_may_trade_the_cooldown_for_a_longer_gesture` (neuf) : le nœud lu **dans
  le manuel** et non recopié dans le test — le jour où ses lignes changeront, il le
  dira. Il vérifie les deux promesses : la récupération ne touche plus rien, la vitesse
  d'incantation coupe l'attente.
- `test_each_label_has_its_agreement` : les deux libellés neufs de `SkillStats`.

---

## 7. Livré le 19 septembre 2026

**La suite : 824 tests, 824 passent** (822 avant, plus celui de l'échelle et celui du
nœud de la Ruée d'orage ; le test d'encombrement est un renommage, pas un ajout).

**L'équilibrage n'a pas bougé d'un caractère.** `docs/EQUILIBRAGE.md` régénéré est
**identique** au précédent, et `tests/run.sh balance` rend les **mêmes quatre échecs
sur cinq, aux mêmes chiffres** (vérifié en relançant le banc sur l'arbre d'avant) :
aucun des 61 nœuds remontés n'est sur un chemin de `BenchProfiles.builds()`, qui
passent par `strike` (8 %, déjà au palier), `spells` (8 %), `storm` (10 %) et `wound`
(12 %). Les quatre échecs sont ceux des jalons 18 et 20 à 22.

**Le dessin a été vérifié en capture réelle**, en fenêtré, à 1280×720 : l'arbre entier
au cran large, puis des gros plans sur les clusters neufs et leurs voisins. L'arbre
passe de 91×91 à **92×91 cases**, soit 322 px de large au cran large contre 360 de
cadre.

**Le banc n'a pas été relancé** : rien de ce jalon n'est dans une boucle chaude.
`Player.recompute_stats()` parcourt les nœuds **pris** (99 au plus), pas les 476 ;
`PassiveTreePanel.node_at()` les parcourt tous, mais seulement sur un mouvement de
souris, panneau ouvert, jeu en pause. Le test d'encombrement, lui, est en O(n²) :
113 000 assertions de plus, sans effet visible sur la durée de la campagne (113 s
contre 115 avant).

### Non fait

- **Les mots-clés `holy` et `necrotic`** (voir §4).
- **Le palier d'un notable** : laissé au jugement, avec « deux petits et demi » pour
  seule boussole. Une table le figerait au prix de sa seconde ligne.
- **`chill_chance` n'a pas son cluster** : il est la seconde ligne du *Cœur de
  glacier*, là où les trois autres chances d'état ont chacune le leur. `floe` et `hoar`
  occupaient déjà les deux ancres froides disponibles.
- **`attack_time` et `attack_range`** restent sans cluster dédié ; le second a ses
  trois petits nœuds de `reach`, le premier n'a rien — c'est la face « temps » de
  `attack_speed`, et lui en donner ferait deux chemins vers le même nombre.
