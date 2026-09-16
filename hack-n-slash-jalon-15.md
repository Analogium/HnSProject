# Hack'n'slash top-down — jalon 15

Suite des jalons 1 à 14. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé le 16 septembre 2026.** Le jalon 14 a introduit deux sortes de pourcentage,
qui s'écrivent aujourd'hui « +20 % dégâts » et « 20 % de dégâts en plus ». En anglais,
*increased* et *more* sont clairs ; en français, « en plus » ne dit rien du calcul. Avant
que l'arbre de passifs (jalon 16) n'en écrive des dizaines, ce jalon fixe **le
vocabulaire du joueur** et ajoute **un glossaire dans les infobulles** : un mot en gras
fait apparaître, à côté du texte, un encadré qui l'explique.

---

## 1. Périmètre

**Dedans :**

- **Le vocabulaire**, en quatre mots, et leur accord en français :

  | Calcul | Gain | Perte | Anglais |
  |---|---|---|---|
  | additif | **accru** | **réduit** | *increased* / *reduced* |
  | multiplicatif | **amplifié** | **atténué** | *more* / *less* |

- **Toutes les lignes en pourcentage** passent à cette forme : infobulle d'objet, page
  du manuel, établi, fiche, catalogue.
- **Le glossaire** : un terme marqué s'affiche en gras, et son encadré apparaît à côté
  de l'interface qui le montre, **dès qu'elle l'affiche**, un encadré par terme
  différent.
- **Les quatre termes ci-dessus** comme premières entrées, en deux définitions
  (accru/réduit, amplifié/atténué).

**Dehors :**

- **D'autres termes** (états, mots-clés, armure, esquive). Le système les accueillera
  par une ligne de table chacun ; les choisir est un travail de contenu, jalon à part.
- **Des mots à survoler** : les encadrés ne suivent pas la souris (décidé, §9).
- **Une police** : le gras est la police actuelle épaissie.

---

## 2. Les lignes

### Français

| Mode | Forme | Exemples |
|---|---|---|
| accru | `+{valeur} de {stat} {accru}` | +20 % de dégâts **accrus** · +10 % d'armure **accrue** · +15 % de résistances **accrues** |
| réduit | `−{valeur} de {stat} {réduit}` | −15 % de vitesse d'attaque **réduite** |
| amplifié | `+{valeur} de {stat} {amplifié}` | +25 % de dégâts **amplifiés** |
| atténué | `−{valeur} de {stat} {atténué}` | −20 % de PV **atténués** |

- **Le terme s'accorde avec la statistique.** `StatMod.LABELS` et `SkillStats.LABELS`
  gagnent chacun une table d'accord (`ms`, `fs`, `mp`, `fp`) sur les mêmes clés ; un test
  refuse un libellé sans accord.
- **« de » s'élide** devant une voyelle ou un h muet : « d'armure », « d'esquive ». La
  règle de `StatMod.label()` du jalon 14 reste la seule.
- **Le terme se place avant le complément** : « +30 % de dégâts **accrus** contre les
  embrasés (Sort) ». `StatusEffects.AGAINST` devient donc un complément seul (« contre
  les embrasés »), et le nom « dégâts » vient de `SkillStats.LABELS`.
- **Le signe dit gain ou perte**, le terme aussi : une valeur négative prend réduit ou
  atténué, et s'écrit avec sa valeur absolue derrière le signe moins.

### Anglais

`+20% increased damage` · `-15% reduced attack speed` · `+25% more damage` ·
`-20% less HP`. L'anglais n'accorde rien : les quatre variantes d'accord d'une clé
française ont la même traduction.

### Sur la page du manuel

Les lignes « dégâts accrus » et « dégâts en plus » deviennent « dégâts **accrus** » et
« dégâts **amplifiés** », terme en gras, encadrés à côté de la page.

---

## 3. Le marquage

**Le texte porte le terme, pas la clé de traduction.**

- **`Glossary`** (une feuille, `core/glossary.gd`) : pour chaque terme, un identifiant
  (`increased`, `reduced`, `more`, `less`), ses quatre formes accordées en français, son
  titre et sa définition.
- **`Glossary.term(id, agreement)`** rend le mot accordé et traduit, **entouré d'une
  marque invisible** (deux caractères de contrôle et l'identifiant). C'est la seule façon
  d'écrire un terme : aucune clé de `en.po` ne contient de marque, et un traducteur ne
  peut pas la casser.
- **Les gabarits ont une place `{terme}`** : `"+{valeur} de {stat} {terme}"`, traduit
  `"+{valeur} {terme} {stat}"`.
- **`Glossary.plain(text)`** retire les marques, pour ce qui n'est pas dessiné en jeu :
  catalogue, forge, messages de test.
- **`Glossary.terms(text)`** rend les identifiants présents, dans l'ordre, sans doublon.

**Pourquoi une marque et pas une recherche des mots.** Chercher « réduit » dans le texte
trouverait aussi « Réduit les dégâts de froid » de `StatHelp`, qui n'est pas le terme.

---

## 4. Le dessin

### Le texte

- **`RichText`** (`ui/rich_text.gd`, une feuille) : `draw()`, `width()` et `fold()` d'une
  ligne marquée. Les segments marqués sont dessinés avec une `FontVariation` épaissie
  (`variation_embolden`) de la police actuelle, dans la même couleur que la ligne.
- **Tout ce qui dessine une ligne de `StatMod` passe par lui** : l'infobulle du sac,
  la page et l'infobulle du manuel, l'établi, l'aide de la fiche. Une largeur mesurée
  sans lui compterait les caractères de marque.
- `StatsPanel._fold()` rejoint `RichText.fold()` : deux découpages finiraient par ne
  plus couper au même endroit.

### Les encadrés

- **`GlossaryBoxes.draw(canvas, anchor, ids)`** (`ui/glossary_boxes.gd`) : un encadré par
  terme, empilés, contre `anchor` — le rectangle de l'infobulle ou du panneau qui montre
  le texte.
- **Du côté qui a la place**, à droite d'abord ; bornés au cadrage et au-dessus des
  jauges (`Hud.gauges_top()`).
- **Largeur fixe** (~120 px), titre en gras, définition pliée par `RichText.fold()`.
- **Couleurs** : un fond parchemin sombre et un cadre beige, dans `UiPalette` — lisibles
  sur le décor et distincts d'une infobulle d'objet.
- **Dessinés en dernier**, par le panneau qui dessine le texte : ils passent au-dessus
  de tout le reste, comme les infobulles aujourd'hui.

### Les définitions, premier jet

- **Accru, réduit** — « Les bonus accrus et réduits d'une même statistique
  s'additionnent, puis s'appliquent ensemble. Deux fois +10 % accrus font +20 %. »
- **Amplifié, atténué** — « Chaque bonus amplifié ou atténué multiplie le résultat à lui
  seul, après les accrus. Deux fois +10 % amplifiés font +21 %. »

---

## 5. Arbitrages

**Une marque dans le texte, et non des lignes structurées.** Transporter partout un
tableau de segments demanderait de réécrire chaque appelant de `StatMod.label()`, du
catalogue aux tests. Une chaîne marquée passe par les mêmes chemins, et seuls ceux qui
dessinent ou mesurent ont à la lire.

**L'accord dans une table, pas dans le libellé.** « armure|fs » dans `LABELS` casserait
la clé de traduction et chaque lecture du libellé.

**Des encadrés sans survol.** En 640×360 un mot fait ~8 px de haut, et une infobulle
d'objet disparaît dès que la souris quitte l'objet : ses mots seraient inatteignables.

**Réduit et atténué plutôt qu'un accru négatif.** « −15 % de vitesse d'attaque accrue »
se lit comme une contradiction. PoE fait le même choix (*reduced*, *less*).

---

## 6. Étapes

Chaque étape se livre seule et passe la suite.

1. **`Glossary` et les lignes** : les termes, la marque, `plain()` et `terms()`, les
   tables d'accord, les nouveaux gabarits de `StatMod.label()`, `en.po`. Le catalogue
   passe par `plain()`.
2. **`RichText`** : dessin en gras, largeur, pliage ; les quatre panneaux dessinent leurs
   lignes par lui. Capture réelle en fenêtré.
3. **Les encadrés** : `GlossaryBoxes`, branchés sur l'infobulle du sac, la page et
   l'infobulle du manuel, l'établi, l'aide de la fiche. Capture réelle.
4. **La doc** : ARCHITECTURE (« Comment un terme s'écrit-il ? », « Qui dessine un
   encadré ? »), RECETTES (« Ajouter un terme au glossaire »).

---

## 7. Ce qui refusera un oubli

- `tests/unit/test_glossary.gd` — chaque terme a ses quatre formes, son titre et sa
  définition ; `plain()` et `terms()` sur une ligne à deux termes ; une clé de `en.po` ne
  contient jamais de marque.
- `tests/unit/test_stat_mod.gd` — les quatre modes, accord et élision, en français et
  en anglais ; chaque libellé de `StatMod.LABELS` et de `SkillStats.LABELS` a son accord.
- `tests/integration/test_widths.gd` — les largeurs mesurées sans les marques.
- `tests/integration/test_item_sheet.gd`, `test_manual_panel.gd` — les encadrés
  présents quand une ligne porte un terme, absents sinon, dans le cadrage.
- `tests/unit/test_translations.gd` — les titres, les définitions et les formes.

---

## 8. À trancher avant de commencer

1. **Réduit / atténué** pour les pertes : mon choix faute d'avis, calqué sur PoE. Une
   autre paire possible : diminué / affaibli.
2. **Les définitions** du §4 : à relire, ce sont les phrases que le joueur lira.

---

## 9. Décidé le 16 septembre 2026

- **Accru / amplifié**, accordés avec la statistique.
- **Les encadrés apparaissent dès que le texte est affiché**, à côté de l'interface, un
  par terme différent.

---

## 10. Ce qui a été fait, et comment

### Livré le 16 septembre 2026

- **`Glossary`** (`core/`), **`RichText`** et **`GlossaryBoxes`** (`ui/`), deux couleurs
  dans `UiPalette`. `StatMod.label()`, `readable_value()` et le nouveau `term_label()`
  écrivent le terme ; `StatMod.AGREEMENT` et `SkillStats.AGREEMENT` portent l'accord ;
  `StatusEffects.AGAINST` n'est plus qu'un complément. `SkillStats.label_key()` a
  disparu dans `StatMod._noun()` / `_complement()`, et `StatsPanel._fold()` dans
  `RichText.fold()`.
- **Dessinés par `RichText`** : l'infobulle du sac, la page et les fiches du manuel,
  l'établi, l'aide de la fiche. **Encadrés** : l'infobulle du sac, les fiches du
  manuel, l'aide de la fiche.

**Écarts avec le plan :**

- **L'établi n'a pas d'encadré**, seulement le gras : c'est un outil de réglage en
  français seul, qui occupe presque tout le cadrage — un encadré ne trouverait sa place
  que par-dessus ses propres lignes.
- **Le signe reste devant la valeur** en anglais aussi (`-15% reduced`) : la même
  fonction écrit les deux langues.
- **La place d'un encadré** cherche aussi **dessous et dessus**. Vu sur capture : la
  fiche d'un nœud touche le manuel d'un côté et le bord de l'écran de l'autre, et
  l'encadré couvrait l'arbre.

**Tests qui ont changé parce que le libellé a changé** : `test_stat_mod.gd`,
`test_talents.gd`, `test_skills.gd` comparent le texte sans marque et le nouveau
vocabulaire ; `test_manual_panel.gd` lit ses lignes par `Glossary.plain()` (« dégâts
amplifiés », « dégâts accrus contre les engourdis ») ; `test_widths.gd` mesure par
`RichText.width()`. Ajoutés : `test_glossary.gd` (termes, marque, pliage, largeur,
placement des encadrés), les quatre termes et l'anglais, l'accord de chaque libellé.

**Vu sur capture en fenêtré** : l'infobulle de gants (terme en gras, encadré à gauche,
du côté libre), la fiche d'un nœud (encadré dessous) et celle d'une compétence
(encadré dessus). **Défaut connu, antérieur** : le bandeau d'aide de débogage de la
zone (H) est dessiné par-dessus les panneaux, donc par-dessus un encadré qui tombe sur
lui.
