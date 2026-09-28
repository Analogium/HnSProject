# Hack'n'slash top-down — jalon 32

Suite des jalons 1 à 31. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 28 septembre 2026.** Le jalon des **flacons**.

---

## 1. Ce que l'utilisateur a demandé

- Le **système de flacons de PoE**, « rien de bien nouveau » : même fonctionnement.
- Les emplacements supplémentaires **sous la ceinture**, dans la fenêtre de personnage :
  la place y est déjà.

## 2. Le système

Celui de PoE 1, ramené à ce que le jeu sait faire.

- **Cinq emplacements**, `flask_1` à `flask_5`, famille `flask`, 1 × 2 cases — sous la
  ceinture, centrés sur l'axe de la poupée. Un flacon **ne compte pas tant qu'on ne le boit
  pas** : `Player.recompute_stats()` saute ces emplacements et reçoit à la place les lignes
  des flacons en cours (`Player.flask_mods()`).
- **Les charges.** Chaque flacon porté en gagne à chaque mise à mort — une, plus une par
  affixe de l'ennemi, la rareté d'un monstre de PoE —, en consomme à chaque gorgée, et se
  **remplit en ville**. Elles vivent sur l'exemplaire (`Item.charges`) et **ne s'écrivent
  pas** : on arrive toujours en ville, donc plein.
- **Une touche par emplacement**, 1 à 5, rebindables (`flask_1` … `flask_5`), liées **par
  position** comme les déplacements : sur un AZERTY, la rangée des chiffres se tape sans
  majuscule.
- **Les flacons de vie et de mana** rendent leur quantité **étalée sur leur durée**. Deux
  gorgées se cumulent, comme dans PoE 1. Deux lignées de cinq paliers.
- **Les flacons utilitaires** donnent leur implicite **pendant l'effet** — vif-argent
  (vitesse), granit (armure), jade (esquive), rubis, saphir, topaze, améthyste (résistances
  au feu, au froid, à la foudre, à la nécrose). Un seul palier chacun : leur effet ne dépend
  pas du niveau. On ne reboit pas un utilitaire dont l'effet dure encore.
- **Les affixes**, comme dans PoE : les « préfixes » montent le flacon lui-même — quantité
  rendue, durée, charges maximales, charges consommées, charges gagnées — et sont
  **locaux**, comme la chance critique d'une arme (`ItemBase.FLASK_STATS`) ; les
  « suffixes » donnent une ligne de fiche **pendant l'effet** — vitesse, armure, esquive.
  Un flacon ne tire que ses affixes, jamais les universels, et reste **magique** : deux
  affixes au plus (`ItemAffixPool.max_count()`), donc ni pièce d'argent ni pièce d'or.
- **Le bandeau** : les cinq flacons en bas à gauche, en miroir de la barre de compétences,
  à la taille du sac. Un voile descend sur les charges manquantes ; une barre sous le
  flacon dit ce qui reste de l'effet.

## 3. Ce qui a été tranché sans l'utilisateur

À revoir sur pièce ; aucun n'engage la suite.

- **Pas de flacon hybride**, ni d'affixe « instantané », ni de suffixe qui retire un état
  (« de l'Étanchement », « de la Chaleur »…). Ils se greffent sans rien changer au système.
- **Pas d'effets globaux sur les flacons** (ceinture « charges gagnées accrues », nœuds de
  l'arbre) : il faudrait les mettre sur la fiche, qui n'a plus la place.
- **Les charges d'une mise à mort** : 1 + 1 par affixe. Provisoire, comme toute la table.
- **Un flacon neuf est plein.**
- **Un flacon retiré en cours d'effet garde son effet** jusqu'au bout.
- **Mourir vide les gorgées en cours.**
- **Les flacons tombent comme n'importe quelle base** : une chance égale par base
  disponible. Au niveau 30, neuf flacons sur une trentaine de bases — un objet sur quatre.
  À revoir à l'équilibrage, qui se fait en dernier.
- **Les chiffres** — quantités, durées, charges — sont ceux de PoE ramenés aux PV du jeu
  (un personnage de niveau 1 en a ~120) : provisoires.
- **Les touches 1 à 5 du banc et de l'arène** (touches de réglage lues par leur code)
  boivent aussi un flacon si le personnage en porte. Sans conséquence : ces scènes n'en
  équipent pas.

## 4. Ce qui reste à dessiner

Les flacons ont un **dessin provisoire** : la forge peint une fiole (`kind` `flask`), la
même pour tous — comme les pièces, c'est l'image qui dira le contenu. Les images passent par
leur planche (`/dessiner-un-effet`, `tools/item_icons.py`) avant d'avoir leur version.

## 5. Ce que la capture et la campagne ont corrigé

Captures sur le Bureau : `hns-captures-jalon32-flacons` (1 à 4).

- **L'onglet des touches débordait** : vingt-trois actions sur deux colonnes poussaient
  « Retour » hors du cadrage. Trois colonnes de huit (`ui/pause_menu.tscn`, `Keys/Rows`).
- **Sur un AZERTY, la touche 1 s'écrivait « Ampersand »** : une touche liée par position
  est traduite dans la disposition du joueur. La rangée des chiffres garde ses chiffres
  (`Keybinds._keycode_label()`).
- **`test_deeper_zones_add_rare_coins_without_taking_common_ones` tombait**, sans que la
  règle des pièces ait bougé : son dénominateur était le compte de diamants au niveau 1,
  une quinzaine sur 60 000 chutes, que les tirages des nouvelles bases déplaçaient —
  ×4,5 à ×8,6 selon la graine, mesuré. Il prend l'espérance au niveau 1 ; la borne et la
  graine n'ont pas changé.
- **Les deux derniers paliers des fioles** ouvraient à 48 et 75 : `test_every_base_drops_…`
  ne cherche que jusqu'au niveau 60, où s'arrête tout le contenu. Ramenés à 36 et 54,
  l'échelle des affixes.
