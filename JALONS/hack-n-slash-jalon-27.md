# Hack'n'slash top-down — jalon 27

Suite des jalons 1 à 26. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 26 septembre 2026.** Le jalon des **nouveaux ennemis** : quatre archétypes,
chacun porteur d'une attaque qui n'existait pas — jusqu'ici le grunt frappait au
contact et le caster tirait droit, et c'était tout.

---

## 1. Ce que l'utilisateur a demandé

« De nouveaux ennemis avec de nouvelles sortes d'attaques. » Quatre propositions,
quatre retenues :

| Ennemi | Id | Attaque | Ce qu'elle demande au joueur |
|---|---|---|---|
| **Chevalier bélier** | `charger` | S'arrête, montre un couloir, charge en ligne droite ; un mur l'étourdit | S'écarter **de côté** |
| **Gobelin cuivré** | `mortar` | Garde ses distances et tire un obus en cloche, par-dessus les murs, là où se tenait sa victime | Ne pas rester immobile |
| **Champignon** | `bloater` | Fonce, enfle au contact, éclate ; tué, il éclate aussi | Le tuer de loin, ou s'écarter |
| **Colosse en armure** | `brute` | Lent et épais ; se plante et abat ses poings dans un cône | Frapper puis sortir du cône |

Et une consigne de méthode : **tout d'un coup** — les visuels de chaque ennemi et de
chaque télégraphe choisis sur planche avant d'implémenter.

## 2. Ce qui s'est choisi sur planche

Planches et captures sur le Bureau : `hns-captures-ennemis-jalon27` (01 à 06) et
`hns-captures-ennemis-jalon27-jeu`, plus les `hns-<id>-*.png|gif` de l'outil.

- **Des grilles à la main, refusées.** Seize silhouettes en grilles texte, 32 px, à
  côté du grunt et du caster : « refais-les, plus de style et de détails ». C'est la
  limite qui avait déjà fait passer les classes jouables par
  `tools/character_forge.py` au jalon 25 ; les ennemis y passent à leur tour, en case
  de 48, sans arme.
- **Les concepts** — trois ou quatre partis pris francs par ennemi, un prompt chacun
  et non quatre graines d'un même prompt. Le LoRA pixel-art sort des **feuilles de
  personnages** sur certains sujets (sanglier, nain, porteur de baril), même avec
  « solo » et en négatif : ces variantes ont été retirées plutôt que montrées en
  doublon. Retenus : chevalier bélier (103), gobelin aux tuyaux (211), champignon
  violet (303), colosse aux lames dorsales (403).
- **Les vues** sortaient **maigres** : le squelette OpenPose est celui, fin, des
  personnages joueurs, et le prompt n'obtient pas une carrure que le squelette
  dément. Écrire « very bulky, wide shoulders » dans le prompt épaissit bien le
  corps, mais fait sortir le **profil de face**. D'où `width`, qui élargit le
  squelette sous la tête, pour les vues comme pour les gestes (§4). Le dos portait
  un visage sur presque toutes les graines : quatre graines de plus pour le dos seul,
  en négatif « face, eyes », et chaque vue retenue sur sa meilleure graine.
- **Le gobelin**, retenu, sortait filiforme une fois réduit à 30 px ; élargir à la
  réduction (`slim` > 1) ne changeait presque rien, le corps étant maigre dès la
  source. Refait avec `width` 1,45, mêmes graines.
- **Les gestes** : la marche pour tous ; le coup (armé, frappé) pour le chevalier et
  le colosse ; le lancer pour le gobelin ; rien d'autre pour le champignon, dont
  l'attaque est d'enfler. Retenus sur proposition : chevalier 4242, gobelin 777,
  champignon 777, colosse marche 4242 et coup 777.
- **Le télégraphe** : cinq partis pris d'une **zone de danger unique**, chacun en
  disque, couloir et cône. Retenu : **le plein monte** — un front part de l'attaquant
  et avance jusqu'au bord ; quand il l'atteint, ça frappe. Écartés : le tramé qui se
  densifie (l'instant de la frappe se devine mal), les tirets, les fissures (les
  moins lisibles en mêlée), l'anneau qui se referme.

## 3. Ce que les captures ont montré

- **À 48 px, les visages disparaissent** — ceux du gobelin et du champignon, la
  visière du chevalier. Retouches (`patches`) : les yeux et la bouche du gobelin, ses
  **tuyaux recopiés de la pose** sur chaque image (la marche générée les perdait),
  les yeux et les crocs du champignon, les yeux du chevalier, et **le dos de son
  heaume** peint par-dessus le visage que gardait la vue de dos.
- **Le plein de la zone se lit moins fort en jeu** que sur la planche agrandie :
  c'est le contour et le front clair qui portent le signal. Laissé tel quel ; à
  reprendre si l'utilisateur le juge trop discret.
- **Deux défauts connus des gestes générés**, montrés et acceptés : le dos du
  champignon change de taille de chapeau d'une image à l'autre, et le casque du
  colosse dérive pendant son coup.

## 4. Le système

- **`DangerZone`** (`actors/enemies/danger_zone.gd`) : la zone et sa frappe.
  **Elle frappe elle-même** quand le plein atteint le bord — l'obus tombe même si le
  mortier est mort entre-temps. Un disque frappe par `Explosion.put()`, qui prête son
  souffle dessiné (le brasier pour l'obus de feu, le mur de gaz pour le champignon
  nécrotique) et sa frappe unique ; un cône par sa propre requête. Le couloir ne
  frappe pas : c'est la charge qui touche. `bound` la lie à son ennemi : le coup du
  colosse tombe avec lui.
- **Dessinée par un shader** (`fx/danger_zone.gdshader`), au pixel du monde. Le nœud
  ne tourne pas, la forme se calcule dans le sens de `facing` : la grille reste
  droite, comme le veut la règle des planches. Aucun coût processeur, quel que soit
  le nombre de zones. `DangerZone.contains()` en est le miroir côté jeu, et les tests
  vérifient que la frappe suit la forme — ce qui est dessiné est ce qui est frappé.
- **Le sol a un étage.** Une zone posée avec les projectiles se trierait avec les
  corps ; d'où un nœud `Ground` entre le sol et les entités, dans la zone et dans
  l'arène, lu par `EnemyManager.ground()`. **Lu à l'emploi**, et non replié dans
  `_ready` : la scène règle les conteneurs du manager *après* son `_ready`, et le
  repli y aurait pointé sur le manager lui-même.
- **Le camp du joueur** : `Targets.PLAYER_SIDE`, et un `mask` sur `in_circle()` et
  `Explosion.put()`. Les morts-vivants de la Relève sont sur ce calque : les attaques
  de zone les frappent aussi, sans une ligne de plus.
- **La marche d'approche** du grunt est passée dans `Enemy._close_in()`, avec la
  séparation : quatre archétypes de plus l'auraient recopiée.
- **Le mortier est un caster** : il en garde l'orbite et la distance, et ne change que
  son tir (`_fire`) et sa ligne de vue (aucune : il tire en cloche). L'obus est la
  planche de la boule de feu, posée sur une parabole — aucun dessin de plus.
- **Le peuplement** tient dans une table, `EnemySpawner.POPULATION`, que le banc
  d'équilibrage lit aussi. Avant : deux scènes et deux poids recopiés dans la zone
  et dans le banc.
- **Les planches ne varient pas** : `SpriteForge.frames()` ramène toute variante à 0
  pour un archétype en planche, sinon chaque ennemi coûtait quatre fabrications.

## 5. Ce qui a été tranché sans l'utilisateur

À revoir sur pièce ; aucun n'engage la suite.

- **Les chiffres** (fiches `resources/stats/<id>_stats.tres` et constantes des
  scripts) sont des premiers réglages : chevalier 45 PV, charge de 170 px à 280 px/s
  après 0,6 s, 16 dégâts et un fort recul, étourdi 0,9 s contre un mur ; gobelin 22 PV,
  obus de feu de 14 en 26 px après 1,1 s ; champignon 16 PV et rapide, 24 dégâts
  nécrotiques en 38 px après 0,7 s d'enflure, 0,35 s de mèche s'il est tué ;
  colosse 110 PV, lent, cône de 54 px et 0,6 rad, 22 dégâts après 0,8 s.
- **Les natures** : l'obus est du **feu**, l'éclatement du **nécrotique**, la charge
  et la frappe du **physique**. Les résistances du joueur comptent donc pour la
  première fois contre autre chose que le trait du caster.
- **Les poids** : grunt 50, caster 17, chargeur 9, gonfle 9, mortier 8, colosse 7 —
  les quatre **dès la zone 1**. Une apparition graduelle par niveau de zone serait
  une ligne de plus dans la table.
- **L'éclatement du champignon ne rapporte rien** s'il n'a pas été tué : ni
  expérience ni butin. Tué pendant qu'il enfle, il rapporte, et son explosion part
  quand même.
- **Le vol de vie** des affixes ne passe pas par les zones : un ennemi mort n'a plus
  de vie à reprendre, et la zone lui survit.
- **Un ennemi vidé** (touche K, rechargement de zone) n'éclate pas : sa zone
  hériterait d'une explosion dans la carte suivante.

## 6. Ce que ça coûte

Mesuré le 26 septembre 2026 sur `world/stress_test.tscn` (grunts et casters
seulement), 300 ennemis en combat dont ~250 simulés, fenêtré, 240 images de chauffe
puis 1 440 mesurées, **dix paires en alternance** avant / après : **5,15 ms** de
physique contre **5,68**, 165 img/s des deux côtés. L'écart (+0,5 ms, erreur type
~0,26) touche le seul tick du grunt : un appel de fonction de plus par grunt, sa
marche passée dans `Enemy._close_in()`. Il reste sous la variation déjà vue entre
deux tirs du même arbre (0,9 ms, jalon 26). Les zones, en shader, ne coûtent rien
au processeur.

## 7. L'équilibrage

Pas touché — il vient en dernier (jalon 13, §7). Deux effets à connaître :

- **L'expérience d'une zone monte** : les nouveaux ennemis ont plus de PV, donc
  rapportent plus. Le niveau attendu à l'arrivée passe de 13 à 14 en zone 10, de 53
  à 58 en zone 60 (`docs/EQUILIBRAGE.md`).
- **Les couloirs ne modèlent que le grunt et le caster** : leurs coups pour tuer et
  leur survie ignorent les quatre nouveaux. `tests/run.sh balance` : 4 tests sur 5 en
  échec avant comme après, **les mêmes 19 couloirs**, seuls les chiffres bougent.
