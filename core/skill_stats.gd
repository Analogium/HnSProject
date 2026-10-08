class_name SkillStats
extends RefCounted

## Ce qu'un lancer fait vraiment : les nombres de la compétence après modificateurs.
## Le résultat d'un lancer, jamais gardé, donc jamais périmé. Hors de
## `CharacterStats` : c'est la propriété d'un geste, pas d'un corps.

## Ce qu'un modificateur peut viser, et son nom à l'écran — en plus des dégâts
## ajoutés `damage_<nature>`. `damage` ne se vise qu'en pourcentage et multiplie
## toutes les parts. Pas de coût. **`use_time` et `recharge` y sont depuis le
## jalon 23** : la cadence et la récupération du porteur les tiennent déjà, mais un
## nœud change ce que la compétence demande — « plus de recharge » se dit par −100 %
## de `recharge`. `interval` n'y est pas : il se déduit des deux. Depuis le jalon 34,
## les **nombres de mécanique** — zéro sur la compétence, un nœud les allume, la forme
## les lit — et `period`, `self_burn`, `status_chance_increase`, que ses échanges visent ;
## `mana_per_second` depuis le jalon 35, `self_heal` depuis le 36, que le buff draine et
## rend depuis son lancer résolu ; `self_wither` et `inflict_chance` depuis le 38.
const LABELS := {
	DAMAGE: "dégâts",
	LEVELS: "niveaux de compétence",
	"projectiles": "nombre de projectiles",
	"projectile_speed": "vitesse de projectile",
	"targets": "nombre de cibles",
	"duration": "durée",
	"radius": "rayon",
	"simultaneous": "maximum simultané",
	CRIT_CHANCE: "chance critique de base",
	# La page du manuel dit « temps d'attaque » ou « temps d'incantation » : elle
	# connaît la cadence de la compétence, une ligne de modificateur non.
	"use_time": "temps du geste",
	"recharge": "recharge",
	"period": "intervalle des frappes",
	"self_burn": "brûlure subie",
	"status_chance_increase": "chance d'état",
	"mana_per_second": "mana drainé",
	"self_heal": "soin",
	"self_wither": "vie rongée",
	"inflict_chance": "chance de l'état posé",
	"mana_cost": "coût en mana",
	CHILL_EFFECT: "effet du transi",
	PIERCE: "nombre d'ennemis traversés",
	SPLITS: "nombre d'éclats",
	GROUND: "secondes de sol laissé",
	END_BURST: "rayon de l'explosion finale",
	KILL_BURST: "rayon de l'explosion des tués",
	SEEK: "rayon de chasse",
	BROOD: "nombre de serpents",
	CRAWL_SPEED: "vitesse de reptation",
	HATCHLINGS: "nombre de petits",
	BOUNCES: "nombre de rebonds",
	JUMP_REACH: "portée des sauts",
	JUMP_GAIN: "dégâts en plus par saut",
	TRAIL_CHARGES: "charges statiques semées",
	PULL: "force d'aspiration",
	DECAY_EFFECT: "effet de la décomposition",
	WILTING_WEAKNESS: "affaiblissement du flétri",
	CURSE_EFFECT: "effet de la malédiction",
	CONTAGION: "rayon de contagion",
	MINION_LIFE: "PV des morts-vivants",
	BONE_WALL: "dégâts subis retirés par mort-vivant",
	COLOSSUS: "rayon de frappe du colosse",
	TRIBUTE: "mana par ennemi maudit",
	SHARED_BURDEN: "rayon du fardeau partagé",
	BLEED_EFFECT: "effet du saignement",
	KNOCKBACK: "recul",
	LIFE_ON_HIT: "PV par ennemi touché",
	MANA_ON_HIT: "mana par ennemi touché",
	BLADE_WARD: "dégâts subis retirés par épée",
	SWORD_VOLLEY: "portée de la volée d'épées",
	WAVES: "nombre de vagues",
	EXTRA_SWORDS: "nombre d'épées en plus par lancer",
	BLESSING_EFFECT: "effet de la bénédiction",
	WAVE_GAIN: "dégâts en plus par onde",
	AUREOLE: "rayon de l'auréole",
	NUMB_EFFECT: "effet de l'engourdi",
	RESONANCE: "secondes gagnées par sort",
	SIPHON: "mana par ennemi tué",
	STACK_HOLD: "secondes de tenue des charges",
	DISSONANCE: "nombre de charges",
	TEMPO: "secondes de recharge rendues",
	PERFECT_CHORD: "dégâts en plus de l'accord",
	REACTION_POWER: "puissance des réactions",
	PRIMER: "état prêté",
	DOLL_LIFE: "PV de la poupée",
	GRUDGE: "dégâts encaissés rendus",
	TRANSFER: "dégâts subis détournés",
	LURE: "portée de l'appeau",
	ECHO_POWER: "dégâts rejoués",
	ECHOES: "nombre d'échos",
	COUNTERSONG: "élément d'avance de l'écho",
	SWELL: "dégâts et rayon par 100 px",
	OVERHEAT: "dégâts en plus par surchauffe",
	STOKED: "dégâts et rayon attisés",
	METEOR_SHOWER: "nombre de mini-météorites",
	SPLIT_CASCADE: "cascade d'éclats",
	POWDER_KEG: "état assuré aux explosions",
	CONVERGE: "convergence des boules",
	WIDE_BLAST: "zone appliquée au rayon",
	GIRTH: "taille en plus par 100 px",
	GLUTTONY: "dégâts en plus par proie",
	GROWTH_MOLT: "mue à la dernière proie",
	CONSTRICT: "étreinte de la proie",
	VISE: "proie immobilisée",
	OUROBOROS: "anneau de feu",
	SPIRAL: "anneau qui se resserre",
	SPIT: "dégâts du crachat",
	SPIT_FAN: "boules crachées en plus",
	HATCHLING_TIME: "secondes de vie des petits",
	HATCHLING_BITE: "dégâts des petits",
	ROT_HOLD: "secondes de pourriture rendues",
	IGNITE_EFFECT: "effet de l'embrasement",
	MELT: "résistance au feu fondue",
	CAMPFIRE: "montée du feu de camp",
	EMBERS: "nombre d'escarbilles",
	REBIRTH: "renaissance",
	PHOENIX_ASHES: "cendres du phénix",
	VIGIL: "PV rendus par seconde",
	EYE: "dégâts en plus au cœur",
	SOUL_FEAST: "PV rendus par tué",
	FLYING_START: "explosion au départ",
	WICK: "dégâts de la mèche",
	SHORT_FUSE: "mèche à l'arrivée",
	SECOND_STRIDE: "seconde ruée gratuite",
	STRIDE_FIRE: "dégâts de la seconde ruée",
	CHARMER: "serpent à l'arrivée",
	SNAKE_DANCE: "serpents rappelés",
	BURNING_WAVE: "dégâts de l'onde brûlante",
	SIGHT: "portée de visée",
	REKINDLE: "secondes rendues par tué",
	BEACON: "phare",
	LAST_BREATH: "dégâts des dernières braises",
	HEARTH: "foyer du mage",
	HELPING_HAND: "main d'appoint",
	TRIANGULATION: "triangulation",
	QUICKFIRE: "tirs ravivés par seconde",
	RAMP: "vitesse d'incantation par cumul",
	FULL_THROTTLE: "tir double à plein régime",
	LIGHTNING_ROD: "paratonnerre",
	ELECTROCUTE: "engourdi sûr au critique",
	ROD_HEIR: "paratonnerre hérité",
	STORM_TARGET: "orage sur le paratonnerre",
	CAROMS: "nombre de rebonds sur les murs",
	SATELLITE: "orbe en orbite",
	CHARGED_ORB: "rayon en plus par ennemi frappé",
	LIVE_ICE: "dégâts de foudre contre les transis",
	CONDUCTANCE: "sauts gratuits vers les engourdis",
	BIFURCATION: "chance de bifurquer par saut",
	GROUNDING: "mana rendu par ennemi touché",
	RELAY: "sauts sur les charges statiques",
	RELAY_REFUND: "saut rendu par charge prise",
	WEB_BRANCH: "dégâts du saut de chaque arc",
	OVERVOLT: "dégâts de la chaîne relancée",
	ACCUMULATION: "dégâts en plus par charge",
	BREAKING_POINT: "frappe large à pleines charges",
	OVERFLOW: "dégâts de l'arc qui déborde",
	TWIN_STRIKE: "chance de frapper deux fois",
	HUNT: "traque de la proie",
	MOVING_FRONT: "frappes en plus en marchant",
	BOLT_DASH: "éclair du départ à l'arrivée",
	CHARGED_RUN: "dégâts du sort suivant par 100 px",
	REARM: "secondes de recharge par engourdi",
	ROUND_TRIP: "retour au départ",
	ROLLING_THUNDER: "dégâts des grondements",
	STATIC_MINES: "charges en mines",
	GALLOP: "appel du tonnerre cumulé",
	IONIZE: "chance d'engourdir autour de vous",
	CAPACITY: "secondes de vie des charges",
	BACKLASH: "coup rendu au contact",
	CONDENSER: "dégâts du sort condensé",
	TOTAL_DISCHARGE: "décharge du condensateur",
	FARADAY: "cage de Faraday",
	AFTERSHOCK: "dégâts de la réplique",
	TREMORS: "répliques en plus",
	GROVE: "cercles de pics en plus",
	GLACIER: "glacier",
	SERAC: "glacier un lancer sur deux",
	CRYSTALLIZE: "vortex nourri par les pics",
	CREVASSE: "crevasse au bout du sillon",
	DEEP_COLD: "dégâts en plus par transi proche",
	RIME: "secondes de transi en plus",
	BLACK_ICE: "vitesse sur le sol gelé",
	STARTLE: "nova de sursaut",
	ALERT: "sursaut plus vif",
	EBB: "anneau qui revient",
	FROST_SKIN: "force du transi au contact",
	HIBERNATION: "recharges plus rapides",
	REFUGE: "états éteints en entrant",
	RIME_HALO: "force du halo de givre",
	ENDLESS_WINTER: "temps rendu par tué",
	ICE_HEART: "éclatement qui transit",
	ICEBREAKER: "dégâts par seconde restante",
	SNOWBALL: "rayon en plus par ennemi frappé",
	SLIDE: "coulée vers le point visé",
	LULL: "dégâts subis en moins dans l'œil",
	FROSTING: "force du transi par impulsion",
	SUPERCONDUCT: "engourdis transis et aspirés",
	SINGULARITY: "éclatement à deux rayons",
	RUT: "secondes de sol de la coulée",
	MILL: "dégâts au cœur du vortex",
	TOP: "éclats crachés en plus par seconde",
	SHARD_RAIN: "éclats en plus à l'éclatement",
	ORB_BITE: "dégâts de l'orbe qui passe",
	FRACTURE: "chance de se briser sur un transi",
	GUIDED: "orbe guidée au curseur",
	STASIS: "orbe arrêtée au point visé",
	KALEIDOSCOPE: "morceaux qui se brisent encore",
	CRYSTALLINE: "dégâts en plus par seconde d'arrêt",
	AIMED_SPIT: "éclats crachés vers l'ennemi",
}

## L'accord de chaque libellé, comme `StatMod.AGREEMENT`.
const AGREEMENT := {
	DAMAGE: "mp",
	LEVELS: "mp",
	"projectiles": "ms",
	"projectile_speed": "fs",
	"targets": "ms",
	"duration": "fs",
	"radius": "ms",
	"simultaneous": "ms",
	CRIT_CHANCE: "fs",
	"use_time": "ms",
	"recharge": "fs",
	"period": "ms",
	"self_burn": "fs",
	"status_chance_increase": "fs",
	"mana_per_second": "ms",
	"self_heal": "ms",
	"self_wither": "fs",
	"inflict_chance": "fs",
	"mana_cost": "ms",
	CHILL_EFFECT: "ms",
	PIERCE: "ms",
	SPLITS: "ms",
	GROUND: "fp",
	END_BURST: "ms",
	KILL_BURST: "ms",
	SEEK: "ms",
	BROOD: "ms",
	CRAWL_SPEED: "fs",
	HATCHLINGS: "ms",
	BOUNCES: "ms",
	JUMP_REACH: "fs",
	JUMP_GAIN: "mp",
	TRAIL_CHARGES: "fp",
	PULL: "fs",
	DECAY_EFFECT: "ms",
	WILTING_WEAKNESS: "ms",
	CURSE_EFFECT: "ms",
	CONTAGION: "ms",
	MINION_LIFE: "mp",
	BONE_WALL: "mp",
	COLOSSUS: "ms",
	TRIBUTE: "ms",
	SHARED_BURDEN: "ms",
	BLEED_EFFECT: "ms",
	KNOCKBACK: "ms",
	LIFE_ON_HIT: "mp",
	MANA_ON_HIT: "ms",
	BLADE_WARD: "mp",
	SWORD_VOLLEY: "fs",
	WAVES: "ms",
	EXTRA_SWORDS: "ms",
	BLESSING_EFFECT: "ms",
	WAVE_GAIN: "mp",
	AUREOLE: "ms",
	NUMB_EFFECT: "ms",
	RESONANCE: "fp",
	SIPHON: "ms",
	STACK_HOLD: "fp",
	DISSONANCE: "ms",
	TEMPO: "fp",
	PERFECT_CHORD: "mp",
	REACTION_POWER: "fs",
	PRIMER: "ms",
	DOLL_LIFE: "mp",
	GRUDGE: "mp",
	TRANSFER: "mp",
	LURE: "fs",
	ECHO_POWER: "mp",
	ECHOES: "ms",
	COUNTERSONG: "ms",
	SWELL: "mp",
	OVERHEAT: "mp",
	STOKED: "mp",
	METEOR_SHOWER: "ms",
	SPLIT_CASCADE: "fs",
	POWDER_KEG: "ms",
	CONVERGE: "fs",
	WIDE_BLAST: "fs",
	GIRTH: "fs",
	GLUTTONY: "mp",
	GROWTH_MOLT: "fs",
	CONSTRICT: "fs",
	VISE: "fs",
	OUROBOROS: "ms",
	SPIRAL: "ms",
	SPIT: "mp",
	SPIT_FAN: "fp",
	HATCHLING_TIME: "fp",
	HATCHLING_BITE: "mp",
	ROT_HOLD: "fp",
	IGNITE_EFFECT: "ms",
	MELT: "fs",
	CAMPFIRE: "fs",
	EMBERS: "ms",
	REBIRTH: "fs",
	PHOENIX_ASHES: "fp",
	VIGIL: "mp",
	EYE: "mp",
	SOUL_FEAST: "mp",
	FLYING_START: "fs",
	WICK: "mp",
	SHORT_FUSE: "fs",
	SECOND_STRIDE: "fs",
	STRIDE_FIRE: "mp",
	CHARMER: "ms",
	SNAKE_DANCE: "mp",
	BURNING_WAVE: "mp",
	SIGHT: "fs",
	REKINDLE: "fp",
	BEACON: "ms",
	LAST_BREATH: "mp",
	HEARTH: "ms",
	HELPING_HAND: "fs",
	TRIANGULATION: "fs",
	QUICKFIRE: "mp",
	RAMP: "fs",
	FULL_THROTTLE: "ms",
	LIGHTNING_ROD: "ms",
	ELECTROCUTE: "ms",
	ROD_HEIR: "ms",
	STORM_TARGET: "ms",
	CAROMS: "ms",
	SATELLITE: "ms",
	CHARGED_ORB: "ms",
	LIVE_ICE: "mp",
	CONDUCTANCE: "mp",
	BIFURCATION: "fs",
	GROUNDING: "ms",
	RELAY: "mp",
	RELAY_REFUND: "ms",
	WEB_BRANCH: "mp",
	OVERVOLT: "mp",
	ACCUMULATION: "mp",
	BREAKING_POINT: "fs",
	OVERFLOW: "mp",
	TWIN_STRIKE: "fs",
	HUNT: "fs",
	MOVING_FRONT: "fp",
	BOLT_DASH: "ms",
	CHARGED_RUN: "mp",
	REARM: "fp",
	ROUND_TRIP: "ms",
	ROLLING_THUNDER: "mp",
	STATIC_MINES: "fp",
	GALLOP: "ms",
	IONIZE: "fs",
	CAPACITY: "fp",
	BACKLASH: "ms",
	CONDENSER: "mp",
	TOTAL_DISCHARGE: "fs",
	FARADAY: "fs",
	AFTERSHOCK: "mp",
	TREMORS: "fp",
	GROVE: "mp",
	GLACIER: "ms",
	SERAC: "ms",
	CRYSTALLIZE: "ms",
	CREVASSE: "fs",
	DEEP_COLD: "mp",
	RIME: "fp",
	BLACK_ICE: "fs",
	STARTLE: "fs",
	ALERT: "ms",
	EBB: "ms",
	FROST_SKIN: "fs",
	HIBERNATION: "fp",
	REFUGE: "mp",
	RIME_HALO: "fs",
	ENDLESS_WINTER: "ms",
	ICE_HEART: "ms",
	ICEBREAKER: "mp",
	SNOWBALL: "ms",
	SLIDE: "fs",
	LULL: "mp",
	FROSTING: "fs",
	SUPERCONDUCT: "mp",
	SINGULARITY: "ms",
	RUT: "fp",
	MILL: "mp",
	TOP: "mp",
	SHARD_RAIN: "mp",
	ORB_BITE: "mp",
	FRACTURE: "fs",
	GUIDED: "fs",
	STASIS: "fs",
	KALEIDOSCOPE: "mp",
	CRYSTALLINE: "mp",
	AIMED_SPIT: "mp",
}

## Les nombres de mécanique (jalon 34). Chacun est lu par les formes qui en ont l'usage,
## et **seulement par elles** : ARCHITECTURE, « Que pose un lancer », dit lesquelles.
const PIERCE := "pierce"
const SPLITS := "splits"
const GROUND := "ground_duration"
const END_BURST := "end_burst"
const KILL_BURST := "kill_burst"
const SEEK := "seek_radius"
## Ceux du serpent, **pas ceux des projectiles** : il n'en est pas un, et « +1 projectile »
## sur un serpent ferait croire que les affixes de projectile le touchent. Des serpents en
## plus du premier, sa vitesse accrue en points de pourcentage, ses petits à sa mort.
const BROOD := "brood"
const CRAWL_SPEED := "crawl_speed"
const HATCHLINGS := "hatchlings"
## Ceux de la foudre (jalon 35) : les rebonds d'un tir, la portée d'un saut de chaîne et
## ce que chaque saut ajoute en « plus » (en points de pourcentage), les charges statiques
## qu'une ruée sème sur son trajet.
const BOUNCES := "bounces"
const JUMP_REACH := "jump_reach"
const JUMP_GAIN := "jump_gain"
const TRAIL_CHARGES := "trail_charges"
## Ceux du froid (jalon 36) : la force du transi posé, en points de pourcentage, et la
## vitesse vers le cœur que donne chaque impulsion du vortex (un recul inversé).
const CHILL_EFFECT := "chill_effect"
const PULL := "pull"
## Ceux de la nécrose (jalon 38). La force de l'état **posé** par le lancer, en points de
## pourcentage — `StatusEffects.State.strength`, comme le transi —, une par état : chacun
## n'est visé que par un arbre. Puis la décomposition qui gagne les voisins (un rayon),
## les morts-vivants (PV accrus, abri par tête, le cercle du colosse), le tribut de la malédiction
## (mana par maudit) et le fardeau de la Nécrose (le rayon où frappe ce qu'elle ronge).
const DECAY_EFFECT := "decay_effect"
const WILTING_WEAKNESS := "wilting_weakness"
const CURSE_EFFECT := "curse_effect"
const CONTAGION := "contagion"
const MINION_LIFE := "minion_life"
const BONE_WALL := "bone_wall"
const COLOSSUS := "colossus"
const TRIBUTE := "tribute"
const SHARED_BURDEN := "shared_burden"
## Ceux du chevalier (jalon 39) : la force du saignement tiré, le recul d'un coup (une
## vitesse, comme `knockback_force`), ce que rend chaque ennemi touché, l'abri par épée
## de la couronne (comme le Rempart d'os), la portée de la volée de ses épées, les épées
## qu'un lancer fait naître en plus, et des vagues en plus — pas des projectiles, une vague
## n'en est pas un.
const BLEED_EFFECT := "bleed_effect"
const KNOCKBACK := "knockback"
const LIFE_ON_HIT := "life_on_hit"
const MANA_ON_HIT := "mana_on_hit"
const BLADE_WARD := "blade_ward"
const SWORD_VOLLEY := "sword_volley"
const WAVES := "waves"
const EXTRA_SWORDS := "extra_swords"
## Ceux du sacré (jalon 40) : la force de la bénédiction tirée, ce que chaque onde de la
## pulsation ajoute en « plus » (en points de pourcentage, comme `jump_gain`), et le rayon
## où la Lumière bénit tant qu'elle brûle.
const BLESSING_EFFECT := "blessing_effect"
const WAVE_GAIN := "wave_gain"
const AUREOLE := "aureole"
## Ceux de la sorcière (jalon 41) : la force de l'engourdi tiré, ce que chaque sort lancé
## rend de durée à l'Amplification, le mana que rend chaque ennemi tué d'un sort sous elle.
const NUMB_EFFECT := "numb_effect"
const RESONANCE := "resonance"
const SIPHON := "siphon"
## Ceux des arbres de Trinité, de la Catalyse, de la Poupée et du Familier (jalon 41). En
## points de pourcentage : l'accord, les réactions, les PV de la poupée, ce qu'elle rend et
## détourne, la part d'un écho.
const STACK_HOLD := "stack_hold"
const DISSONANCE := "dissonance"
const TEMPO := "tempo"
const PERFECT_CHORD := "perfect_chord"
const REACTION_POWER := "reaction_power"
const PRIMER := "primer"
const DOLL_LIFE := "doll_life"
const GRUDGE := "grudge"
const TRANSFER := "transfer"
const LURE := "lure"
const ECHO_POWER := "echo_power"
const ECHOES := "echoes"
const COUNTERSONG := "countersong"
## Ceux de la Boule de feu (jalon 42). La Prise d'air et la Surchauffe en points de
## pourcentage « plus », par 100 px volés et par charge ; le Feu nourri, ce que la boule
## gagne en dégâts et en rayon sous l'Immolation. Les trois derniers sont des drapeaux.
const SWELL := "swell"
const OVERHEAT := "overheat"
const STOKED := "stoked"
const METEOR_SHOWER := "meteor_shower"
const SPLIT_CASCADE := "split_cascade"
const POWDER_KEG := "powder_keg"
const CONVERGE := "converge"
## Les deux suites de la Prise d'air : la Déflagration, un drapeau que `Skill.resolve()` lit
## avant les lignes d'objet, et le Gonflement, la taille gagnée par 100 px volés.
const WIDE_BLAST := "wide_blast"
const GIRTH := "girth"
## Ceux du Serpent infernal (jalon 42). La Gloutonnerie en points de pourcentage « plus »
## par proie, le Crachat en part d'une morsure, la Morsure nécrosante en secondes ; le
## Venin d'hydre, la vie et les dégâts « plus » des petits. Les autres sont des drapeaux.
const GLUTTONY := "gluttony"
const GROWTH_MOLT := "growth_molt"
const CONSTRICT := "constrict"
const VISE := "vise"
const OUROBOROS := "ouroboros"
const SPIRAL := "spiral"
const SPIT := "spit"
const SPIT_FAN := "spit_fan"
const HATCHLING_TIME := "hatchling_time"
const HATCHLING_BITE := "hatchling_bite"
const ROT_HOLD := "rot_hold"
## Ceux de l'Immolation (jalon 42). La force de l'embrasement en points de pourcentage, la
## Fonte en points de résistance ; le Feu de camp, la Veillée, l'Œil du brasier et les
## Âmes consumées en points de pourcentage ; les escarbilles en nombre ; deux drapeaux.
const IGNITE_EFFECT := "ignite_effect"
const MELT := "melt"
const CAMPFIRE := "campfire"
const EMBERS := "embers"
const REBIRTH := "rebirth"
const PHOENIX_ASHES := "phoenix_ashes"
const VIGIL := "vigil"
const EYE := "eye"
const SOUL_FEAST := "soul_feast"
## Ceux de la Ruée ardente (jalon 42). Le Départ en trombe, la Mèche, la Foulée de feu et
## l'Onde brûlante en points de pourcentage d'un coup ; les autres sont des drapeaux.
const FLYING_START := "flying_start"
const WICK := "wick"
const SHORT_FUSE := "short_fuse"
const SECOND_STRIDE := "second_stride"
const STRIDE_FIRE := "stride_fire"
const CHARMER := "charmer"
const SNAKE_DANCE := "snake_dance"
const BURNING_WAVE := "burning_wave"
## Ceux du Brasero (jalon 42) : sa portée de visée en px, ce qu'un tué lui rend en
## secondes, les Dernières braises en points de pourcentage d'un tir, les tirs ravivés par
## seconde au plus ; le Phare, le Foyer du mage, la Main d'appoint et la Triangulation
## sont des drapeaux.
const SIGHT := "sight"
const REKINDLE := "rekindle"
const BEACON := "beacon"
const LAST_BREATH := "last_breath"
const HEARTH := "hearth"
const HELPING_HAND := "helping_hand"
const TRIANGULATION := "triangulation"
const QUICKFIRE := "quickfire"
## Ceux de l'Éclair vif (jalon 43). L'Emballement en points de pourcentage de vitesse par
## cumul, l'Orbe chargé de rayon par ennemi, la Glace vive de foudre ajoutée ; les
## rebonds sur les murs en nombre ; les autres sont des drapeaux.
const RAMP := "ramp"
const FULL_THROTTLE := "full_throttle"
const LIGHTNING_ROD := "lightning_rod"
const ELECTROCUTE := "electrocute"
const ROD_HEIR := "rod_heir"
const STORM_TARGET := "storm_target"
const CAROMS := "caroms"
const SATELLITE := "satellite"
const CHARGED_ORB := "charged_orb"
const LIVE_ICE := "live_ice"
## Ceux de la Chaîne d'éclairs (jalon 43). La Bifurcation en chance par saut, la Ramure et
## le Survoltage en points de pourcentage d'un coup, le Retour par la masse en mana par
## ennemi ; les autres sont des drapeaux.
const CONDUCTANCE := "conductance"
const BIFURCATION := "bifurcation"
const GROUNDING := "grounding"
const RELAY := "relay"
const RELAY_REFUND := "relay_refund"
const WEB_BRANCH := "web_branch"
const OVERVOLT := "overvolt"
## Ceux du Nuage d'orage (jalon 43). L'Accumulation en points de pourcentage « plus » par
## charge, le Débordement en part d'une frappe, la Foudre jumelle en chance, le Front
## mobile en points de pourcentage de cadence ; deux drapeaux.
const ACCUMULATION := "accumulation"
const BREAKING_POINT := "breaking_point"
const OVERFLOW := "overflow"
const TWIN_STRIKE := "twin_strike"
const HUNT := "hunt"
const MOVING_FRONT := "moving_front"
## Ceux de la Ruée d'orage (jalon 43). La Tension accumulée en points de pourcentage
## « plus » par 100 px courus, le Réarmement en secondes par engourdi, le Tonnerre roulant
## en part du coup d'arrivée ; les autres sont des drapeaux.
const BOLT_DASH := "bolt_dash"
const CHARGED_RUN := "charged_run"
const REARM := "rearm"
const ROUND_TRIP := "round_trip"
const ROLLING_THUNDER := "rolling_thunder"
const STATIC_MINES := "static_mines"
const GALLOP := "gallop"
## Ceux de l'Électricité statique (jalon 43), lus sur le buff allumé (`Player.lit_number()`).
## L'Ionisation en chance par seconde, la Capacité en secondes, le Choc en retour en part du
## coup reçu, le Condensateur en « plus » ; deux drapeaux.
const IONIZE := "ionize"
const CAPACITY := "capacity"
const BACKLASH := "backlash"
const CONDENSER := "condenser"
const TOTAL_DISCHARGE := "total_discharge"
const FARADAY := "faraday"
## Ceux des Pics de glace (jalon 44). La Réplique en points de pourcentage du coup, les
## Secousses et le Bosquet en nombre ; les autres sont des drapeaux. Le Plein centre lit
## `EYE`, le cœur de l'Œil du brasier ; le Grésil, `SEEK`.
const AFTERSHOCK := "aftershock"
const TREMORS := "tremors"
const GROVE := "grove"
const GLACIER := "glacier"
const SERAC := "serac"
const CRYSTALLIZE := "crystallize"
const CREVASSE := "crevasse"
## Ceux de la Nova de glace (jalon 44). Le Grand froid en « plus » par transi, le Frimas en
## secondes, la Glace noire en points de pourcentage de vitesse ; trois drapeaux. La Gelée
## blanche est la Poudrière du feu, `POWDER_KEG` ; le Repoussoir, `KNOCKBACK`.
const DEEP_COLD := "deep_cold"
const RIME := "rime"
const BLACK_ICE := "black_ice"
const STARTLE := "startle"
const ALERT := "alert"
const EBB := "ebb"
## Ceux du Tombeau de glace (jalon 44), lus sur le buff allumé ou à sa sortie. La Peau de
## givre et le Halo en force du transi, l'Hibernation en points de pourcentage de vitesse
## des recharges, le Brise-glace en « plus » par seconde restante ; trois drapeaux.
const FROST_SKIN := "frost_skin"
const HIBERNATION := "hibernation"
const REFUGE := "refuge"
const RIME_HALO := "rime_halo"
const ENDLESS_WINTER := "endless_winter"
const ICE_HEART := "ice_heart"
const ICEBREAKER := "icebreaker"
## Ceux du Désastre hivernal (jalon 44), lus par `IceVortex`. La Boule de neige en points de
## pourcentage de rayon par ennemi frappé, l'Accalmie en dégâts subis en moins, le Givrage
## en force du transi par impulsion, la Meule en « plus », l'Ornière en secondes ; trois
## drapeaux.
const SNOWBALL := "snowball"
const SLIDE := "slide"
const LULL := "lull"
const FROSTING := "frosting"
const SUPERCONDUCT := "superconduct"
const SINGULARITY := "singularity"
const RUT := "rut"
const MILL := "mill"
## Ceux de l'Orbe gelée (jalon 44), lus par `FrozenOrb` et ses éclats. La Toupie en points de
## pourcentage d'éclats par seconde, la Pluie d'éclats en nombre, l'Orbe mordante en part
## d'un coup, la Fracture en chance, le Cristallin en « plus » par seconde ; quatre drapeaux.
const TOP := "top"
const SHARD_RAIN := "shard_rain"
const ORB_BITE := "orb_bite"
const FRACTURE := "fracture"
const GUIDED := "guided"
const STASIS := "stasis"
const KALEIDOSCOPE := "kaleidoscope"
const CRYSTALLINE := "crystalline"
const AIMED_SPIT := "aimed_spit"
## Ceux qui changent **ce que fait** le lancer, pas combien : l'octogone d'un nœud les
## signale avant qu'on le survole.
const MECHANICS := [
	PIERCE, SPLITS, GROUND, END_BURST, KILL_BURST, SEEK, BROOD, HATCHLINGS,
	BOUNCES, JUMP_GAIN, TRAIL_CHARGES, PULL, CONTAGION, BONE_WALL, COLOSSUS, TRIBUTE,
	SHARED_BURDEN, KNOCKBACK, LIFE_ON_HIT, MANA_ON_HIT, BLADE_WARD, SWORD_VOLLEY, WAVES,
	EXTRA_SWORDS, WAVE_GAIN, AUREOLE, RESONANCE, SIPHON, DISSONANCE, TEMPO, PERFECT_CHORD,
	PRIMER, GRUDGE, TRANSFER, LURE, ECHOES, COUNTERSONG, SWELL, OVERHEAT, STOKED,
	METEOR_SHOWER, SPLIT_CASCADE, POWDER_KEG, CONVERGE, WIDE_BLAST, GIRTH, GLUTTONY,
	GROWTH_MOLT, CONSTRICT, VISE, OUROBOROS, SPIRAL, SPIT, SPIT_FAN, ROT_HOLD, MELT,
	CAMPFIRE, EMBERS, REBIRTH, PHOENIX_ASHES, VIGIL, EYE, SOUL_FEAST, FLYING_START, WICK,
	SHORT_FUSE, SECOND_STRIDE, STRIDE_FIRE, CHARMER, SNAKE_DANCE, BURNING_WAVE, REKINDLE,
	BEACON, LAST_BREATH, HEARTH, HELPING_HAND, TRIANGULATION, QUICKFIRE, RAMP,
	FULL_THROTTLE, LIGHTNING_ROD, ELECTROCUTE, ROD_HEIR, STORM_TARGET, CAROMS, SATELLITE,
	CHARGED_ORB, LIVE_ICE, CONDUCTANCE, BIFURCATION, GROUNDING, RELAY, RELAY_REFUND, WEB_BRANCH,
	OVERVOLT, ACCUMULATION, BREAKING_POINT, OVERFLOW, TWIN_STRIKE, HUNT, MOVING_FRONT, BOLT_DASH,
	CHARGED_RUN, REARM, ROUND_TRIP, ROLLING_THUNDER, STATIC_MINES, GALLOP, IONIZE, CAPACITY,
	BACKLASH, CONDENSER, TOTAL_DISCHARGE, FARADAY, AFTERSHOCK, TREMORS, GROVE, GLACIER,
	SERAC, CRYSTALLIZE, CREVASSE, DEEP_COLD, RIME, BLACK_ICE, STARTLE, ALERT, EBB,
	FROST_SKIN, HIBERNATION, REFUGE, RIME_HALO, ENDLESS_WINTER, ICE_HEART, ICEBREAKER,
	SNOWBALL, SLIDE, LULL, FROSTING, SUPERCONDUCT, SINGULARITY, RUT, MILL, TOP, SHARD_RAIN,
	ORB_BITE, FRACTURE, GUIDED, STASIS, KALEIDOSCOPE, CRYSTALLINE, AIMED_SPIT,
]
## Le nombre qui accroît la force de chaque état, quand un arbre en a un : **le seul
## lien** entre un état et sa force, que `strength_of()` et la fiche lisent.
const EFFECT_OF := {
	StatusEffects.Kind.IGNITE: IGNITE_EFFECT,
	StatusEffects.Kind.CHILL: CHILL_EFFECT,
	StatusEffects.Kind.NUMB: NUMB_EFFECT,
	StatusEffects.Kind.BLEED: BLEED_EFFECT,
	StatusEffects.Kind.BLESSING: BLESSING_EFFECT,
	StatusEffects.Kind.DECAY: DECAY_EFFECT,
	StatusEffects.Kind.WILTING: WILTING_WEAKNESS,
	StatusEffects.Kind.CURSED: CURSE_EFFECT,
}

## Le sol brûlant : sa part des dégâts par impulsion, son rythme, son rayon. Et la part
## d'un coup que rend l'explosion d'un tué.
const GROUND_PART := 0.25
const GROUND_PERIOD := 0.5
const GROUND_RADIUS := 14.0
const KILL_BURST_PART := 0.5
const SPLIT_PART := 0.4
## La part d'un coup de la ruée que porte chaque charge de son sillage statique.
const TRAIL_CHARGE_PART := 0.5
## La Prise d'air : le pas de vol qui donne un gain. La Surchauffe : ses charges au plus.
## La Pluie de météorites : la part et le rayon d'une mini-météorite, l'écart au point
## d'impact en part du rayon. La Convergence : l'écart entre deux boules au départ.
const SWELL_STEP := 100.0
const OVERHEAT_MOST := 3
const SHOWER_PART := 0.3
const SHOWER_RADIUS := 1.0 / 3.0
const SHOWER_SPREAD := 0.7
const CONVERGE_GAP := 10.0
## Le Gonflement : la taille la plus grande qu'une boule atteint, en multiple de la sienne.
const GIRTH_MOST := 2.0
## La chance d'état ajoutée par la Poudrière, en points de pourcentage : ×6 sur les 20 %
## de base, de quoi passer 100 %.
const SURE_STATE := 500.0
## La Gloutonnerie : la vie gagnée et la taille prise par proie, et les proies au plus. La
## Mue de croissance : le rayon de sa gerbe. Le Crachat : son rythme, sa portée, le rayon
## de sa petite explosion, l'écart de deux boules de la Gerbe (en radians).
const GLUTTONY_LIFE := 0.5
const GLUTTONY_GROWTH := 0.08
const GLUTTONY_MOST := 5
const MOLT_RADIUS := 40.0
const SPIT_PERIOD := 1.5
const SPIT_REACH := 100.0
const SPIT_SPREAD := 0.35
## Le rayon de la petite explosion d'une étincelle (`Fireball.spark()`) : crachat, escarbille,
## boule du Brasero.
const SPARK_RADIUS := 12.0
## Le Feu de camp : les secondes d'immobilité qui le montent au plus. Les Escarbilles : leur
## part d'une impulsion, et leur portée en multiple du rayon. L'Œil du brasier : la part
## centrale du rayon. La Renaissance : son attente, la vie qu'elle laisse, la portée de son
## explosion en multiple du rayon ; les Cendres du phénix : leur durée, leur « plus ».
const CAMPFIRE_MOST := 3.0
const EMBER_PART := 0.4
const EMBER_REACH := 2.0
const EYE_PART := 1.0 / 3.0
const REBIRTH_PERIOD := 60.0
const REBIRTH_HEALTH := 0.2
const REBIRTH_REACH := 2.0
const ASHES_TIME := 4.0
const ASHES_MORE := 50.0
## La Seconde foulée : la fenêtre où la ruée se relance gratuite. Le Charmeur : la compétence
## qu'il fait surgir. L'Onde brûlante : sa portée, en multiple du rayon de l'atterrissage.
const STRIDE_WINDOW := 1.5
const CHARMED_SKILL := "hell_snake"
const BURNING_WAVE_REACH := 2.0
## Le Brasero : sa portée de visée avant la Vigie ; la part des PV max du lanceur qu'il reçoit
## sous le Phare ; les boules de ses Dernières braises ; la compétence que tire le Foyer du mage ;
## le demi-largeur du trait de la Triangulation.
const TURRET_SIGHT := 150.0
const BEACON_LIFE := 0.5
const LAST_BREATH_BALLS := 8
const HEARTH_SKILL := "fireball"
const LINK_RADIUS := 8.0
## L'Emballement : l'écart au lancer précédent qui garde les cumuls, et leur nombre au plus ;
## le Plein régime : un tir sur combien part double, et l'écart entre ses deux éclairs.
const RAMP_HOLD := 1.0
const RAMP_MOST := 5
const THROTTLE_EVERY := 4
const THROTTLE_GAP := 0.08
## Le Paratonnerre : sa durée, la portée où les éclairs s'incurvent vers lui, leur virage en
## radians par seconde — celui des éclats du Grésil aussi (jalon 44) ; celle où la Cible de
## l'orage le frappe depuis un nuage.
const ROD_LIFE := 3.0
const ROD_REACH := 200.0
const ROD_TURN := 9.0
const STORM_ROD_REACH := 300.0
## Le Satellite : le rayon de son orbite. L'Orbe chargé : les ennemis comptés au plus.
const SATELLITE_RADIUS := 60.0
const CHARGED_ORB_MOST := 5
## Le Survoltage : les sauts de la chaîne qu'il relance. Les sauts au plus d'une décharge,
## chaque branche à part : la Conductance et le Réamorçage en rendent, et une meute
## engourdie ne doit pas lui faire traverser l'écran.
const OVERVOLT_JUMPS := 2
const CHAIN_JUMPS_MOST := 12
## L'Accumulation : ses charges au plus ; le Point de rupture, sa portée en multiple du
## rayon, comme celle du Débordement. La Foudre jumelle : l'écart entre ses deux frappes.
## La Traque : la vitesse du nuage, en multiple de celle de l'errance.
const ACCUMULATION_MOST := 5
const BREAK_REACH := 2.0
const OVERFLOW_REACH := 2.0
const TWIN_DELAY := 0.1
const HUNT_SPEED := 2.0
## La Ruée d'orage. Le Trait d'éclair : la largeur de son trait. La Tension accumulée : le
## pas de course, la course comptée au plus, le temps de lancer le sort qu'elle charge.
## L'Aller-retour : son attente. Le Tonnerre roulant : ses grondements et leur écart. Les
## Mines statiques : leur force et leur rayon, en multiples d'une charge. Le Galop : ses
## charges au plus.
const BOLT_DASH_WIDTH := 16.0
const CHARGED_RUN_STEP := 100.0
const CHARGED_RUN_MOST := 300.0
const CHARGED_RUN_WINDOW := 3.0
const ROUND_TRIP_DELAY := 1.5
const ROLLING_COUNT := 2
const ROLLING_GAP := 0.4
const MINE_FACTOR := 3.0
const MINE_REACH := 2.0
const GALLOP_MOST := 3
## L'Électricité statique. L'Ionisation : son rythme et sa portée. Le Condensateur : ses
## cumuls ; la Décharge totale, le rayon de sa nova. La Cage de Faraday : sa durée, et
## l'attente avant la suivante.
const IONIZE_PERIOD := 1.0
const IONIZE_RADIUS := 60.0
const CONDENSER_MOST := 10
const DISCHARGE_RADIUS := 50.0
const FARADAY_TIME := 1.0
const FARADAY_PERIOD := 5.0
## Les Pics de glace. La Réplique : l'écart entre deux. Le Glacier : un lancer sur combien,
## sous le Sérac aussi, son rayon et son « plus ». La Cristallisation : ce qu'un lancer rend
## au vortex, qui ne dépasse pas deux fois sa durée. La Crevasse : son rayon.
const AFTERSHOCK_GAP := 0.4
const GLACIER_EVERY := 3
const SERAC_EVERY := 2
const GLACIER_RADIUS := 1.5
const GLACIER_MORE := 40.0
const CRYSTALLIZE_TIME := 0.3
const CREVASSE_RADIUS := 2.0
## La Nova de glace. Le Grand froid : les transis comptés au plus. Le Sursaut : la
## compétence qu'il relance, la part des PV max qu'un coup doit ôter, son attente — et
## sous le Qui-vive.
const DEEP_COLD_MOST := 5
const STARTLE_SKILL := "ice_nova"
const STARTLE_LOSS := 0.10
const STARTLE_PERIOD := 4.0
const ALERT_LOSS := 0.05
const ALERT_PERIOD := 2.0
## Le Tombeau de glace. Le Halo : sa portée et son rythme. L'Hiver sans fin : ce qu'un tué
## rend. Le Cœur de glace : l'effet du transi qu'il ajoute — sa force doublée.
const TOMB_SKILL := "frost_tomb"
const HALO_RADIUS := 40.0
const HALO_PERIOD := 1.0
const ENDLESS_TIME := 0.3
const ICE_HEART_EFFECT := 100.0
## Le Désastre hivernal. La Boule de neige : le rayon gagné au plus, en part. La Coulée : sa
## vitesse. Le Givrage : ses renforts au plus par ennemi. La Meule : le cœur, en px. La
## Singularité : la portée de l'éclatement, en rayons. L'Accalmie lit `EYE_PART`.
const SNOWBALL_MOST := 0.4
const SLIDE_SPEED := 50.0
const FROSTING_MOST := 3
const MILL_CORE := 15.0
const SINGULARITY_REACH := 2.0
## L'Orbe gelée. Ses éclats à l'éclatement, et leur vitesse ; la portée de sa morsure. La
## Fracture : la part d'un éclat que garde chaque morceau, et leur écart en radians. Le
## Guidage : son virage en radians par seconde. Le Viseur : la portée où il cherche.
const FROST_ORB_BURST := 8
const SHARD_SPEED := 200.0
const ORB_REACH := 9.0
const FRACTURE_PART := 0.5
const FRACTURE_SPREAD := 0.5
const GUIDE_TURN := 3.0
const SPIT_SIGHT := 160.0
## La recharge d'un geste affranchi (l'Armure de givre), **fixe** : ni nœud ni
## récupération ne la bougent. Le prix de marcher sous sa protection.
const FREED_RECHARGE := 5.0
## La vie des petits qu'un serpent relâche (`SPLITS` sur `HellSnake`).
const HATCHLING_LIFE := 2.0
## Le Colosse d'os : ses PV, en multiple de ceux d'un mort-vivant, et son échelle. Le
## cercle qu'il frappe est le nombre lui-même ; ses dégâts, une ligne du nœud.
const COLOSSUS_LIFE := 3.0
const COLOSSUS_SCALE := 1.7
## Le fardeau partagé : ce que la Nécrose ronge, rendu à ce multiple aux ennemis proches,
## tous les combien.
const BURDEN_FACTOR := 4.0
const BURDEN_PERIOD := 1.0
## La Marque de mort : combien elle maudit plus fort qu'un sceau.
const MARK_FACTOR := 2.0
## L'Auréole : tous les combien elle bénit ce qui est dans son cercle.
const AUREOLE_PERIOD := 0.5

const DAMAGE := "damage"
## Le seul nombre du lancer qu'un modificateur **sans portée** atteint : sa base est sur
## la compétence, pas sur la fiche.
const CRIT_CHANCE := "crit_chance"
## Des points de compétence en plus de ceux placés, à plat et **toujours portés par un
## mot-clé** : la fiche n'a pas de niveau de compétence.
const LEVELS := "skill_levels"

## Le début du nom d'une statistique de dégâts ajoutés : `damage_` puis
## l'identifiant d'une nature.
const ADDED_PREFIX := "damage_"

## Le début du nom d'une statistique de dégâts contre un état : `damage_vs_` puis
## l'identifiant de l'état (`StatusEffects.IDS`).
const AGAINST_PREFIX := "damage_vs_"

## L'écart minimal entre deux traits voisins, en degrés : sans lui, « +1 projectile »
## sur un trait droit en superposerait deux.
const MIN_SPREAD := 8.0

## L'identifiant de la compétence, pour le compteur de DPS.
var skill_id := ""

## Les dégâts **par nature et en fourchette**, indexés par `DamageType.Kind`.
var damage_min: Array[float] = DamageType.empty_parts()
var damage_max: Array[float] = DamageType.empty_parts()
## Réels pendant la résolution, arrondis par `finalize()` : arrondir à chaque
## modificateur ferait dépendre le résultat de leur ordre.
var projectiles := 1.0
var spread_in_degrees := 0.0
var projectile_speed := 0.0
## Réels puis arrondis, comme `projectiles`.
var targets := 1.0
var simultaneous := 0.0
var duration := 0.0
var radius := 0.0
var period := 0.0
var self_burn := 0.0
var mana_per_second := 0.0
var self_heal := 0.0
var self_wither := 0.0
## Ce que ce lancer accroît à la chance de poser son état, en points de pourcentage.
var status_chance_increase := 0.0
## L'état qu'il pose à ce qu'il touche, et sa chance (`Skill.inflicted_state`).
var inflicted_state := -1
var inflict_chance := 1.0
## Les coups d'un geste, que la forme décide.
var hits := 1
## Celle de la compétence, ou celle qu'un nœud lui a substituée : **le lancer se pose
## par elle**, jamais par `Skill.shape`.
var shape := 0
## Les nombres de mécanique, à zéro tant qu'aucun nœud ne les allume.
var pierce := 0.0
var splits := 0.0
var ground_duration := 0.0
var end_burst := 0.0
var kill_burst := 0.0
var seek_radius := 0.0
var brood := 0.0
var crawl_speed := 0.0
var hatchlings := 0.0
var bounces := 0.0
var jump_reach := 0.0
var jump_gain := 0.0
var trail_charges := 0.0
var chill_effect := 0.0
var pull := 0.0
var decay_effect := 0.0
var wilting_weakness := 0.0
var curse_effect := 0.0
var contagion := 0.0
var minion_life := 0.0
var bone_wall := 0.0
var colossus := 0.0
var tribute := 0.0
var shared_burden := 0.0
var bleed_effect := 0.0
var knockback := 0.0
var life_on_hit := 0.0
var mana_on_hit := 0.0
var blade_ward := 0.0
var sword_volley := 0.0
var waves := 0.0
var extra_swords := 0.0
var blessing_effect := 0.0
var wave_gain := 0.0
var aureole := 0.0
var numb_effect := 0.0
var resonance := 0.0
var siphon := 0.0
var stack_hold := 0.0
var dissonance := 0.0
var tempo := 0.0
var perfect_chord := 0.0
var reaction_power := 0.0
var primer := 0.0
var doll_life := 0.0
var grudge := 0.0
var transfer := 0.0
var lure := 0.0
var echo_power := 0.0
var echoes := 0.0
var countersong := 0.0
var swell := 0.0
var overheat := 0.0
var stoked := 0.0
var meteor_shower := 0.0
var split_cascade := 0.0
var powder_keg := 0.0
var converge := 0.0
var wide_blast := 0.0
var girth := 0.0
var gluttony := 0.0
var growth_molt := 0.0
var constrict := 0.0
var vise := 0.0
var ouroboros := 0.0
var spiral := 0.0
var spit := 0.0
var spit_fan := 0.0
var hatchling_time := 0.0
var hatchling_bite := 0.0
var rot_hold := 0.0
var ignite_effect := 0.0
var melt := 0.0
var campfire := 0.0
var embers := 0.0
var rebirth := 0.0
var phoenix_ashes := 0.0
var vigil := 0.0
var eye := 0.0
var soul_feast := 0.0
var flying_start := 0.0
var wick := 0.0
var short_fuse := 0.0
var second_stride := 0.0
var stride_fire := 0.0
var charmer := 0.0
var snake_dance := 0.0
var burning_wave := 0.0
var sight := 0.0
var rekindle := 0.0
var beacon := 0.0
var last_breath := 0.0
var hearth := 0.0
var helping_hand := 0.0
var triangulation := 0.0
var quickfire := 0.0
var ramp := 0.0
var full_throttle := 0.0
var lightning_rod := 0.0
var electrocute := 0.0
var rod_heir := 0.0
var storm_target := 0.0
var caroms := 0.0
var satellite := 0.0
var charged_orb := 0.0
var live_ice := 0.0
var conductance := 0.0
var bifurcation := 0.0
var grounding := 0.0
var relay := 0.0
var relay_refund := 0.0
var web_branch := 0.0
var overvolt := 0.0
var accumulation := 0.0
var breaking_point := 0.0
var overflow := 0.0
var twin_strike := 0.0
var hunt := 0.0
var moving_front := 0.0
var bolt_dash := 0.0
var charged_run := 0.0
var rearm := 0.0
var round_trip := 0.0
var rolling_thunder := 0.0
var static_mines := 0.0
var gallop := 0.0
var ionize := 0.0
var capacity := 0.0
var backlash := 0.0
var condenser := 0.0
var total_discharge := 0.0
var faraday := 0.0
var aftershock := 0.0
var tremors := 0.0
var grove := 0.0
var glacier := 0.0
var serac := 0.0
var crystallize := 0.0
var crevasse := 0.0
var deep_cold := 0.0
var rime := 0.0
var black_ice := 0.0
var startle := 0.0
var alert := 0.0
var ebb := 0.0
var frost_skin := 0.0
var hibernation := 0.0
var refuge := 0.0
var rime_halo := 0.0
var endless_winter := 0.0
var ice_heart := 0.0
var icebreaker := 0.0
var snowball := 0.0
var slide := 0.0
var lull := 0.0
var frosting := 0.0
var superconduct := 0.0
var singularity := 0.0
var rut := 0.0
var mill := 0.0
var top := 0.0
var shard_rain := 0.0
var orb_bite := 0.0
var fracture := 0.0
var guided := 0.0
var stasis := 0.0
var kaleidoscope := 0.0
var crystalline := 0.0
var aimed_spit := 0.0
## Le morceau de la Fracture, une fois fabriqué : un cache, que `echoed()` ne recopie pas.
var _fragment: SkillStats
## Celui de la compétence, sauf un nœud qui l'affranchit (`TalentNode.frees`).
var binds_caster := false
## Vrai pour ce qui n'a pas de fin — l'aura, le buff, le cyclone : pas de « par lancer ».
var sustained := false
var mana_cost := 0.0
## Le temps du geste et la recharge, séparés parce que **rien ne les change ensemble** :
## la cadence du lanceur agit sur le premier, la récupération sur la seconde.
var use_time := 0.0
var recharge := 0.0

## Ce que la case attend : le plus long des deux, calculé et jamais rangé — une seule
## vérité (`Skill.interval()` dit la même chose avant résolution).
var interval: float:
	get:
		return maxf(use_time, recharge)
## Tirés à chaque coup par `DamageInfo.roll()`. Le multiplicateur est celui de la fiche.
var crit_chance := 0.0
var crit_multiplier := 1.0

## Les mots-clés que ce lancer porte vraiment, nœuds compris : c'est cette liste
## qui a filtré les modificateurs.
var keywords := PackedStringArray()

## Ce que `LEVELS` a ajouté aux points placés, pour la page du manuel.
var bonus_levels := 0

## Par état de la cible, indexés par `StatusEffects.Kind` : la somme des accrus en
## points de pourcentage, et le produit des « plus ». Lus au coup, par la hurtbox.
var against_increased: Array[float] = []
var against_more: Array[float] = []

## La nature du lancer : celle de la compétence, ou celle où une conversion l'a
## emmenée (jalon 34 : tout ou rien). Ce qu'un objet ajoute garde la sienne.
var nature := int(DamageType.Kind.PHYSICAL)

## La décomposition pour la fiche du manuel, **écrite par les appels qui calculent**
## les dégâts : recomposée à côté, elle finirait par mentir.
var base_damage := 0.0
var added_min: Array[float] = DamageType.empty_parts()
var added_max: Array[float] = DamageType.empty_parts()
## Les « % dégâts » portés, en facteurs : les accrus sommés (deux « +10 % » font 1,20),
## puis le produit des « plus » (deux font 1,21).
var increased := 1.0
var more := 1.0


func _init() -> void:
	against_increased.resize(StatusEffects.Kind.size())
	against_increased.fill(0.0)
	against_more.resize(StatusEffects.Kind.size())
	against_more.fill(1.0)


## La nature ajoutée par cette statistique, ou -1.
static func added_nature(stat: String) -> int:
	if not stat.begins_with(ADDED_PREFIX):
		return -1
	return DamageType.IDS.find(stat.trim_prefix(ADDED_PREFIX))


static func added_stat(nature: DamageType.Kind) -> String:
	return ADDED_PREFIX + DamageType.IDS[nature]


## « 3–7 », ou « 23 » quand les deux bornes s'arrondissent au même nombre : des
## dégâts résolus sont des réels, et « 29–29 » se lirait comme une faute.
static func readable_range(low: float, top: float) -> String:
	var b := roundi(low)
	var h := roundi(top)
	return str(b) if b == h else "%d–%d" % [b, h]


## L'état visé par cette statistique, ou -1.
static func against(stat: String) -> int:
	if not stat.begins_with(AGAINST_PREFIX):
		return -1
	return StatusEffects.IDS.find(stat.trim_prefix(AGAINST_PREFIX))


static func against_stat(kind: StatusEffects.Kind) -> String:
	return AGAINST_PREFIX + StatusEffects.IDS[kind]


## Un nombre nommé, des dégâts ajoutés d'une nature connue, ou contre un état connu.
static func modifiable(stat: String) -> bool:
	return LABELS.has(stat) or added_nature(stat) >= 0 or against(stat) >= 0


func projectile_count() -> int:
	return int(projectiles)


func target_count() -> int:
	return int(targets)


func max_simultaneous() -> int:
	return int(simultaneous)


## Une impulsion à la pose, puis une par période ; l'epsilon absorbe l'arrondi d'une
## durée modifiée. **Le nuage compte ses frappes par ici**, comme la fiche.
func strikes_over_duration() -> int:
	if duration <= 0.0 or period <= 0.0:
		return 1
	return maxi(floori(duration / period + 0.0001), 1)


## Combien d'impulsions un geste qui dure doit avoir données à cet âge : la n-ième part
## à n périodes, jusqu'à `strikes_over_duration()`. Le nuage, le pilier, la pulsation,
## le vortex, la trace d'une ruée et le portail l'écrivaient chacun.
func strikes_due(age: float) -> int:
	var total := strikes_over_duration()
	var due := 0
	while due < total and age >= float(due) * period:
		due += 1
	return due


## « Projectile · Foudre · Sort », nœuds compris.
func keywords_label() -> String:
	return Keywords.line(keywords)


## Les dégâts propres de la compétence, dans sa nature, bornes égales.
func place_the_base(nature: int, amount: float) -> void:
	base_damage = amount
	damage_min[nature] += amount
	damage_max[nature] += amount


## La borne haute ne descend jamais sous la basse.
func add_to(nature: int, low: float, top: float) -> void:
	var top_point := maxf(top, low)
	added_min[nature] += low
	added_max[nature] += top_point
	damage_min[nature] += low
	damage_max[nature] += top_point


## Toutes les parts, une fois. Un accru sous −100 % ne rend pas les dégâts négatifs.
func scale_damage(increased_percent: float, more_factor: float) -> void:
	increased = maxf(1.0 + increased_percent * 0.01, 0.0)
	more = more_factor
	for i in damage_min.size():
		damage_min[i] *= increased * more
		damage_max[i] *= increased * more


## Le facteur d'un coup sur cette cible : l'accru d'un état **s'ajoute aux accrus du
## lancer** (§2 du jalon 14), le « plus » multiplie. Un pour une cible sans état, et
## pour un lancer qui ne vise aucun état — le cas de presque tous les coups.
func against_factor(states: StatusEffects) -> float:
	if states == null or states.is_clear:
		return 1.0
	var added := 0.0
	var product := 1.0
	for kind in against_increased.size():
		if (against_increased[kind] != 0.0 or against_more[kind] != 1.0) and states.active(kind):
			added += against_increased[kind]
			product *= against_more[kind]
	# La Surchauffe : un « plus » par charge, lu avant que ce coup n'en pose une autre.
	if overheat > 0.0:
		product *= 1.0 + overheat * 0.01 * states.strength(StatusEffects.Kind.OVERHEAT)
	if increased <= 0.0:
		return product
	return maxf(increased + added * 0.01, 0.0) / increased * product


## La part de chaque nature, somme à un ; toute dans sa nature sans dégâts.
## Ce qu'un objet ajoute compte.
func distribution() -> Array[float]:
	var out := DamageType.empty_parts()
	var total := total_min() + total_max()
	if total <= 0.0:
		out[nature] = 1.0
		return out
	for i in out.size():
		out[i] = (damage_min[i] + damage_max[i]) / total
	return out


func total_min() -> float:
	var total := 0.0
	for part in damage_min:
		total += part
	return total


func total_max() -> float:
	var total := 0.0
	for part in damage_max:
		total += part
	return total


## Les chiffres des mécaniques, pour les descriptions des nœuds (`{part_sol}`…) : lus
## ici, sur les constantes mêmes qui les appliquent.
static func facts() -> Dictionary:
	return {
		"part_sol": roundi(GROUND_PART * 100.0),
		"rythme_sol": GROUND_PERIOD,
		"rayon_sol": roundi(GROUND_RADIUS),
		"part_eclat": roundi(SPLIT_PART * 100.0),
		"part_tue": roundi(KILL_BURST_PART * 100.0),
		"vie_petit": roundi(HATCHLING_LIFE),
		"part_charge": roundi(TRAIL_CHARGE_PART * 100.0),
		"recharge_libre": roundi(FREED_RECHARGE),
		"vie_colosse": roundi(COLOSSUS_LIFE),
		"fardeau": roundi(BURDEN_FACTOR),
		"rythme_fardeau": BURDEN_PERIOD,
		"force_marque": roundi(MARK_FACTOR),
		"pas_vol": roundi(SWELL_STEP),
		"charges_surchauffe": OVERHEAT_MOST,
		"duree_surchauffe": roundi(StatusEffects.DURATIONS[StatusEffects.Kind.OVERHEAT]),
		"part_pluie": roundi(SHOWER_PART * 100.0),
		"taille_max": roundi(GIRTH_MOST * 100.0),
		"vie_proie": GLUTTONY_LIFE,
		"proies_max": GLUTTONY_MOST,
		"rayon_mue": roundi(MOLT_RADIUS),
		"rythme_crachat": SPIT_PERIOD,
		"portee_crachat": roundi(SPIT_REACH),
		"montee_max": roundi(CAMPFIRE_MOST),
		"part_escarbille": roundi(EMBER_PART * 100.0),
		"portee_escarbille": roundi(EMBER_REACH),
		"attente_renaissance": roundi(REBIRTH_PERIOD),
		"vie_renaissance": roundi(REBIRTH_HEALTH * 100.0),
		"portee_renaissance": roundi(REBIRTH_REACH),
		"duree_cendres": roundi(ASHES_TIME),
		"plus_cendres": roundi(ASHES_MORE),
		"fenetre_foulee": STRIDE_WINDOW,
		"portee_onde": roundi(BURNING_WAVE_REACH),
		"portee_brasero": roundi(TURRET_SIGHT),
		"vie_phare": roundi(BEACON_LIFE * 100.0),
		"boules_souffle": LAST_BREATH_BALLS,
		"tenue_emballement": roundi(RAMP_HOLD),
		"cumuls_emballement": RAMP_MOST,
		"tir_double": THROTTLE_EVERY,
		"duree_paratonnerre": roundi(ROD_LIFE),
		"portee_paratonnerre": roundi(ROD_REACH),
		"portee_orage": roundi(STORM_ROD_REACH),
		"orbite": roundi(SATELLITE_RADIUS),
		"traverses_max": CHARGED_ORB_MOST,
		"sauts_survoltage": OVERVOLT_JUMPS,
		"sauts_max": CHAIN_JUMPS_MOST,
		"charges_accumulation": ACCUMULATION_MOST,
		"portee_rupture": roundi(BREAK_REACH),
		"portee_debordement": roundi(OVERFLOW_REACH),
		"pas_course": roundi(CHARGED_RUN_STEP),
		"course_max": roundi(CHARGED_RUN_MOST),
		"fenetre_course": roundi(CHARGED_RUN_WINDOW),
		"attente_retour": ROUND_TRIP_DELAY,
		"grondements": ROLLING_COUNT,
		"force_mine": roundi(MINE_FACTOR),
		"rayon_mine": roundi(MINE_REACH),
		"galop_max": GALLOP_MOST,
		"portee_ionisation": roundi(IONIZE_RADIUS),
		"cumuls_condensateur": CONDENSER_MOST,
		"duree_cage": roundi(FARADAY_TIME),
		"rythme_cage": roundi(FARADAY_PERIOD),
		"ecart_replique": AFTERSHOCK_GAP,
		"glacier_tous": GLACIER_EVERY,
		"serac_tous": SERAC_EVERY,
		"rayon_glacier": GLACIER_RADIUS,
		"plus_glacier": roundi(GLACIER_MORE),
		"temps_cristal": CRYSTALLIZE_TIME,
		"rayon_crevasse": roundi(CREVASSE_RADIUS),
		"transis_max": DEEP_COLD_MOST,
		"perte_sursaut": roundi(STARTLE_LOSS * 100.0),
		"rythme_sursaut": roundi(STARTLE_PERIOD),
		"perte_vive": roundi(ALERT_LOSS * 100.0),
		"rythme_vif": roundi(ALERT_PERIOD),
		"portee_halo": roundi(HALO_RADIUS),
		"temps_hiver": ENDLESS_TIME,
		"neige_max": roundi(SNOWBALL_MOST * 100.0),
		"vitesse_coulee": roundi(SLIDE_SPEED),
		"givrage_max": FROSTING_MOST,
		"coeur_meule": roundi(MILL_CORE),
		"portee_singularite": roundi(SINGULARITY_REACH),
		"eclats_orbe": FROST_ORB_BURST,
		"part_morceau": roundi(FRACTURE_PART * 100.0),
		"portee_viseur": roundi(SPIT_SIGHT),
	}


## Le lancer du sol brûlant qu'il laisse : un lancer dérivé, rythmé comme un sillage.
## `GROUND_RADIUS` sous un impact ; la nova pose le sien à sa taille (jalon 36).
func ground(p_radius := GROUND_RADIUS) -> SkillStats:
	var g := _derived(GROUND_PART)
	g.duration = ground_duration
	g.period = GROUND_PERIOD
	g.radius = p_radius
	return g


## La chaîne que relance le Survoltage depuis un engourdi tué : une part du coup, deux
## sauts, sans rien de ce qui relancerait — `_derived()` ne recopie ni l'explosion des tués
## ni le Survoltage.
func surged() -> SkillStats:
	var g := _derived(overvolt * 0.01)
	g.shape = Skill.Shape.CHAIN
	g.targets = float(OVERVOLT_JUMPS)
	g.jump_reach = jump_reach
	g.jump_gain = jump_gain
	return g


## Le lancer d'un éclat : la moitié du rayon, pour qu'une explosion d'éclat ne se lise pas
## comme celle du tir. En cascade, il éclate à son tour — une fois : `_derived()` ne
## recopie pas la cascade.
func shard() -> SkillStats:
	var g := _derived(SPLIT_PART)
	g.projectile_speed = projectile_speed
	g.radius = radius * 0.5
	if split_cascade > 0.0:
		g.splits = splits
	# Le Grésil (jalon 44) : les éclats des pics cherchent.
	g.seek_radius = seek_radius
	return g


## La Réplique des pics (jalon 44) : un pic entier — ses éclats, son sol, son cœur —, à une
## part du coup ; seule la Réplique ne se recopie pas, sinon elle répliquerait sans fin.
func aftershock_of() -> SkillStats:
	var g := echoed(aftershock * 0.01)
	g.aftershock = 0.0
	g.tremors = 0.0
	return g


## Un morceau de la Fracture (jalon 44) : une part de l'éclat, qui ne se brise plus — sauf
## une fois de plus sous le Kaléidoscope. Fabriqué une fois par lancer : la copie entière
## coûte 0,27 ms, et une orbe brise des dizaines d'éclats par seconde.
func fragment() -> SkillStats:
	if _fragment == null:
		_fragment = echoed(FRACTURE_PART)
		if kaleidoscope > 0.0:
			_fragment.kaleidoscope = 0.0
		else:
			_fragment.fracture = 0.0
	return _fragment


## Le Glacier et la Crevasse (jalon 44) : le lancer entier, plus large et plus fort.
func swollen(part: float, radius_factor: float) -> SkillStats:
	var g := echoed(part)
	g.radius *= radius_factor
	return g


## Un petit de l'Hydre : un éclat qui vit `HATCHLING_LIFE`, plus longtemps et plus fort
## sous le Venin d'hydre — et ne se divise pas, `_derived()` ne recopiant pas les petits.
func hatchling() -> SkillStats:
	var g := _derived(SPLIT_PART * (1.0 + hatchling_bite * 0.01))
	g.duration = HATCHLING_LIFE + hatchling_time
	g.period = period
	return g


## Une étincelle (`Fireball.spark()`) : une part du coup — le crachat du serpent, les
## escarbilles du brasier. Son explosion est `SPARK_RADIUS`, quel que soit le lancer.
func spark(part: float) -> SkillStats:
	return _derived(part)


## Une mini-météorite de la Pluie : une part des dégâts, un tiers du rayon, et rien qui en
## ferait tomber d'autres.
func shower() -> SkillStats:
	var g := _derived(SHOWER_PART)
	g.radius = radius * SHOWER_RADIUS
	return g


## Un lancer né d'un autre, à une part de ses dégâts : ce qui qualifie un coup —
## mots-clés, critique, chances d'état, bonus contre un état — et **rien de ce qui en
## ferait naître un autre** (ni sol, ni éclat, ni explosion, ni état posé), sinon un sol
## en poserait un autre.
func _derived(part: float) -> SkillStats:
	var g := SkillStats.new()
	g.skill_id = skill_id
	g.nature = nature
	g.shape = shape
	g.keywords = keywords
	for i in damage_min.size():
		g.damage_min[i] = damage_min[i] * part
		g.damage_max[i] = damage_max[i] * part
	g.increased = increased
	g.against_increased = against_increased.duplicate()
	g.against_more = against_more.duplicate()
	g.crit_chance = crit_chance
	g.crit_multiplier = crit_multiplier
	g.status_chance_increase = status_chance_increase
	g.chill_effect = chill_effect
	g.rime = rime
	g.ignite_effect = ignite_effect
	g.numb_effect = numb_effect
	g.crawl_speed = crawl_speed
	return g


## Le même lancer à une part de ses dégâts, **tout compris** : ce que rejoue le Familier
## (jalon 41) est le sort entier, son sol, ses éclats et son état posé avec.
func echoed(part: float) -> SkillStats:
	var g := SkillStats.new()
	for p in get_property_list():
		# `interval` se déduit, et un cache ne vaut que pour son lancer.
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and p["name"] != "interval" \
				and not String(p["name"]).begins_with("_"):
			var value: Variant = get(p["name"])
			g.set(p["name"], value.duplicate() if value is Array else value)
	for i in damage_min.size():
		g.damage_min[i] *= part
		g.damage_max[i] *= part
	return g


## Les dégâts répartis à parts égales entre ces natures : la Triade, dont les trois comètes
## portent chacune son élément (jalon 41). La fiche et le tirage des états lisent ces parts.
func blend(natures: Array[int]) -> void:
	var low := total_min() / float(natures.size())
	var top := total_max() / float(natures.size())
	damage_min.fill(0.0)
	damage_max.fill(0.0)
	for n in natures:
		damage_min[n] += low
		damage_max[n] += top


## Le multiplicateur d'effet de cet état quand ce lancer le pose : 1, plus ce que l'arbre
## y ajoute — le transi qu'il tire, l'état qu'il pose (jalon 38) —, fois deux sous la
## Marque de mort. **Le seul calcul** : la fiche l'affiche, le coup et le sceau le posent.
func strength_of(kind: int) -> float:
	var effect := float(get(EFFECT_OF[kind])) if EFFECT_OF.has(kind) else 0.0
	var factor := 1.0 + effect * 0.01
	if kind == inflicted_state and shape == Skill.Shape.MARK:
		factor *= MARK_FACTOR
	return factor


## Le milieu de chaque fourchette.
func average_per_hit() -> float:
	return (total_min() + total_max()) * 0.5


## Un lancer entier **si tout touche**, avant défenses et sans critique :
## projectiles × vagues × cibles × coups × frappes dans la durée. Zéro pour une aura.
func average_per_cast() -> float:
	if sustained:
		return 0.0
	var strikes := 0.0
	for i in strikes_over_duration():
		strikes += wave_factor(i)
	var count := projectile_count() * (1 + int(waves)) * target_count() * hits
	return average_per_hit() * float(count) * strikes


## Ce que porte la frappe `index` d'un geste qui dure, sous l'Exaltation (jalon 40) :
## chaque onde déjà partie ajoute son gain. Le seul calcul, que la pulsation et
## l'estimation lisent.
func wave_factor(index: int) -> float:
	return 1.0 + wave_gain * 0.01 * float(index)


## Par l'intervalle entre deux lancers, sans compter la réserve ; pour une aura, un
## coup par période. Une orbite est bornée par son maximum simultané.
func average_per_second() -> float:
	if sustained:
		return average_per_hit() / period if period > 0.0 else 0.0
	if interval <= 0.0:
		return 0.0
	var per_second := average_per_cast() / interval
	if max_simultaneous() > 0 and period > 0.0:
		per_second = minf(per_second, average_per_hit() * float(max_simultaneous()) / period)
	return per_second


## Les parts d'**un** coup : un tirage par fourchette ouverte, quel que soit le
## résultat (invariant 3).
func roll(rng: RandomNumberGenerator) -> Array[float]:
	var parts := DamageType.empty_parts()
	for i in parts.size():
		parts[i] = damage_min[i]
		if damage_max[i] > damage_min[i]:
			parts[i] = rng.randf_range(damage_min[i], damage_max[i])
	return parts


## Les bornes, une fois tous les modificateurs appliqués : dispersion bornée au tour
## complet, et une chaîne garde au moins une cible.
func finalize() -> void:
	var n := maxi(roundi(projectiles), 1)
	projectiles = float(n)
	spread_in_degrees = clampf(
		maxf(spread_in_degrees, MIN_SPREAD * float(n - 1)), 0.0, 360.0
	)
	targets = float(maxi(roundi(targets), 1))
	simultaneous = float(maxi(roundi(simultaneous), 0))
	pierce = float(maxi(roundi(pierce), 0))
	splits = float(maxi(roundi(splits), 0))
	meteor_shower = float(maxi(roundi(meteor_shower), 0))
	spit_fan = float(maxi(roundi(spit_fan), 0))
	embers = float(maxi(roundi(embers), 0))
	bounces = float(maxi(roundi(bounces), 0))
	trail_charges = float(maxi(roundi(trail_charges), 0))
	waves = float(maxi(roundi(waves), 0))
	extra_swords = float(maxi(roundi(extra_swords), 0))
	duration = maxf(duration, 0.0)
	radius = maxf(radius, 0.0)
	period = maxf(period, 0.0)
	self_burn = maxf(self_burn, 0.0)
	self_wither = maxf(self_wither, 0.0)
	inflict_chance = clampf(inflict_chance, 0.0, 1.0)
	crit_chance = clampf(crit_chance, 0.0, 1.0)
