# Banc d'équilibrage

<!-- Fichier généré par tools/equilibrage.sh — ne pas éditer à la main. -->

Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits
par les règles du jeu à chaque lancement (`BenchProfiles`), et le calcul passe par
les vraies fonctions (`BenchCalculation`). Le banc montre les écarts ; les réglages
restent une décision — voir `hack-n-slash-jalon-13.md`.

| verdict | coups pour tuer un grunt | survie au contact |
|---|---|---|
| 🟦 trivial | moins de 0,50 | plus de 10,0 s |
| 🟩 confortable | 0,50 à 3,00 | plus de 10,0 s |
| 🟨 tendu | 3,00 à 8,00 | 4,00 à 10,0 s |
| 🟥 mur | plus de 8,00 | moins de 4,00 s |

Le verdict est le pire des deux axes. Pour lire les nombres :

- **coups** : avec la compétence de la barre qui en demande le moins, critique en
  moyenne, après les défenses de l'ennemi ;
- **secondes** : par `average_per_second()`, *si tout touche* — les traits d'une
  nova comptent tous sur la même cible — et sans compter la réserve de mana ;
- **survie** : au contact de 3 grunts et 1 caster sans affixe, après armure,
  résistances et esquive, régénération déduite. ∞ : la régénération suffit.

## Niveau attendu

Le niveau atteint en vidant une fois chaque zone de 1 à Z − 1, avec la population
moyenne de l'`EnemySpawner` et le retard de `Enemy.experience_factor()`.

| zone | 1 | 10 | 20 | 40 | 60 | 90 | 120 |
|---|---|---|---|---|---|---|---|
| niveau | 1 | 13 | 19 | 34 | 53 | 100 | 133 |

## Sort — Manuel de la foudre, intelligence

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,36 · 4,68 s | 🟥 2,27 · 2,20 s | 🟥 4,01 · 1,39 s | 🟥 12,6 · 0,80 s | 🟥 39,8 · 0,56 s | 🟥 226 · 0,39 s | 🟥 1310 · 0,30 s |
| Nu | 🟨 1,36 · 4,68 s | 🟥 1,11 · 2,20 s | 🟥 1,66 · 1,39 s | 🟥 4,96 · 0,80 s | 🟥 15,7 · 0,56 s | 🟥 89,0 · 0,39 s | 🟥 516 · 0,30 s |
| Sous-équipé | 🟩 1,24 · 13,5 s | 🟨 0,92 · 4,84 s | 🟥 1,60 · 2,74 s | 🟥 3,47 · 2,54 s | 🟥 6,46 · 1,34 s | 🟥 16,9 · 1,70 s | 🟥 182 · 0,81 s |
| Équipé | 🟩 1,28 · 11,8 s | 🟨 0,99 · 6,11 s | 🟨 1,44 · 5,88 s | 🟥 2,27 · 2,78 s | 🟥 13,0 · 6,11 s | 🟥 79,9 · 3,14 s | 🟥 327 · 3,92 s |
| Sur-équipé | 🟩 0,95 · ∞ s | 🟨 0,65 · 8,52 s | 🟨 0,89 · 6,16 s | 🟨 4,45 · 5,33 s | 🟥 11,2 · 1,98 s | 🟥 45,1 · 1,35 s | 🟥 463 · 1,63 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,55 | 1,10 | 4,68 |
| Débutant | 10 | 1 | Éclair vif | 2,27 | 1,51 | 4,54 | 0,92 | 1,83 | 2,20 |
| Débutant | 20 | 1 | Éclair vif | 4,01 | 2,68 | 8,03 | 1,62 | 3,24 | 1,39 |
| Débutant | 40 | 1 | Éclair vif | 12,6 | 8,40 | 25,2 | 5,09 | 10,2 | 0,80 |
| Débutant | 60 | 1 | Éclair vif | 39,8 | 26,5 | 79,6 | 16,1 | 32,1 | 0,56 |
| Débutant | 90 | 1 | Éclair vif | 226 | 151 | 452 | 91,3 | 183 | 0,39 |
| Débutant | 120 | 1 | Éclair vif | 1310 | 873 | 2620 | 529 | 1058 | 0,30 |
| Nu | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,55 | 1,10 | 4,68 |
| Nu | 10 | 13 | Chaîne d'éclairs | 1,11 | 0,74 | 2,22 | 0,18 | 0,35 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 1,66 | 1,11 | 3,32 | 0,25 | 0,50 | 1,39 |
| Nu | 40 | 34 | Chaîne d'éclairs | 4,96 | 3,31 | 9,93 | 0,65 | 1,30 | 0,80 |
| Nu | 60 | 53 | Chaîne d'éclairs | 15,7 | 10,4 | 31,3 | 1,77 | 3,54 | 0,56 |
| Nu | 90 | 100 | Chaîne d'éclairs | 89,0 | 59,4 | 178 | 7,52 | 15,0 | 0,39 |
| Nu | 120 | 133 | Chaîne d'éclairs | 516 | 344 | 1032 | 37,0 | 74,0 | 0,30 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,24 | 0,82 | 2,47 | 0,43 | 0,85 | 13,5 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,92 | 0,61 | 1,84 | 0,12 | 0,25 | 4,84 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 1,60 | 1,07 | 3,20 | 0,21 | 0,41 | 2,74 |
| Sous-équipé | 40 | 34 | Chaîne d'éclairs | 3,47 | 2,31 | 6,93 | 0,39 | 0,78 | 2,54 |
| Sous-équipé | 60 | 53 | Chaîne d'éclairs | 6,46 | 4,31 | 12,9 | 0,51 | 1,02 | 1,34 |
| Sous-équipé | 90 | 100 | Chaîne d'éclairs | 16,9 | 11,3 | 33,9 | 0,93 | 1,86 | 1,70 |
| Sous-équipé | 120 | 133 | Chaîne d'éclairs | 182 | 121 | 364 | 9,33 | 18,7 | 0,81 |
| Équipé | 1 | 1 | Éclair vif | 1,28 | 0,86 | 2,57 | 0,44 | 0,87 | 11,8 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,99 | 0,66 | 1,98 | 0,13 | 0,27 | 6,11 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 1,44 | 0,96 | 2,89 | 0,17 | 0,35 | 5,88 |
| Équipé | 40 | 34 | Chaîne d'éclairs | 2,27 | 1,51 | 4,53 | 0,23 | 0,46 | 2,78 |
| Équipé | 60 | 53 | Chaîne d'éclairs | 13,0 | 8,67 | 26,0 | 1,10 | 2,19 | 6,11 |
| Équipé | 90 | 100 | Chaîne d'éclairs | 79,9 | 53,3 | 160 | 4,74 | 9,49 | 3,14 |
| Équipé | 120 | 133 | Chaîne d'éclairs | 327 | 218 | 654 | 16,3 | 32,7 | 3,92 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,95 | 0,63 | 1,90 | 0,24 | 0,49 | ∞ |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,65 | 0,43 | 1,30 | 0,07 | 0,15 | 8,52 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,89 | 0,60 | 1,79 | 0,09 | 0,18 | 6,16 |
| Sur-équipé | 40 | 34 | Chaîne d'éclairs | 4,45 | 2,97 | 8,91 | 0,37 | 0,74 | 5,33 |
| Sur-équipé | 60 | 53 | Chaîne d'éclairs | 11,2 | 7,46 | 22,4 | 0,86 | 1,73 | 1,98 |
| Sur-équipé | 90 | 100 | Chaîne d'éclairs | 45,1 | 30,0 | 90,1 | 2,77 | 5,55 | 1,35 |
| Sur-équipé | 120 | 133 | Chaîne d'éclairs | 463 | 309 | 926 | 23,5 | 46,9 | 1,63 |

</details>

## Mêlée — Manuel du chevalier, force

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,30 · 4,68 s | 🟥 2,92 · 2,20 s | 🟥 6,55 · 1,39 s | 🟥 28,2 · 0,80 s | 🟥 109 · 0,56 s | 🟥 740 · 0,39 s | 🟥 4672 · 0,30 s |
| Nu | 🟨 1,30 · 4,68 s | 🟥 0,89 · 3,53 s | 🟥 1,62 · 3,78 s | 🟥 4,09 · 2,89 s | 🟥 11,3 · 2,54 s | 🟥 44,0 · 2,68 s | 🟥 196 · 2,53 s |
| Sous-équipé | 🟩 1,06 · 12,1 s | 🟨 0,77 · 7,61 s | 🟨 1,45 · 8,45 s | 🟨 3,30 · 9,71 s | 🟨 7,92 · 6,30 s | 🟥 36,3 · 6,96 s | 🟥 137 · 14,8 s |
| Équipé | 🟩 1,21 · 14,0 s | 🟨 0,81 · 8,63 s | 🟩 1,46 · 11,1 s | 🟩 2,28 · 17,2 s | 🟨 6,88 · 7,34 s | 🟥 24,3 · 14,6 s | 🟥 136 · 6,09 s |
| Sur-équipé | 🟩 1,07 · 39,1 s | 🟩 0,57 · 11,9 s | 🟨 1,42 · 7,64 s | 🟩 2,51 · 69,3 s | 🟥 8,22 · 18,4 s | 🟥 23,3 · 24,4 s | 🟥 128 · 16,7 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 1,30 | 0,87 | 2,60 | 0,56 | 1,12 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 2,92 | 1,95 | 5,84 | 1,26 | 2,53 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 6,55 | 4,36 | 13,1 | 2,83 | 5,66 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 28,2 | 18,8 | 56,3 | 12,2 | 24,4 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 109 | 72,5 | 217 | 47,0 | 94,0 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 740 | 493 | 1479 | 320 | 640 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 4672 | 3115 | 9345 | 2022 | 4043 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 1,30 | 0,87 | 2,60 | 0,56 | 1,12 | 4,68 |
| Nu | 10 | 13 | Frappe lourde | 0,89 | 0,60 | 1,79 | 0,29 | 0,59 | 3,53 |
| Nu | 20 | 19 | Frappe lourde | 1,62 | 1,08 | 3,24 | 0,54 | 1,07 | 3,78 |
| Nu | 40 | 34 | Frappe lourde | 4,09 | 2,73 | 8,19 | 1,57 | 3,13 | 2,89 |
| Nu | 60 | 53 | Frappe lourde | 11,3 | 7,53 | 22,6 | 4,16 | 8,31 | 2,54 |
| Nu | 90 | 100 | Frappe lourde | 44,0 | 29,3 | 88,0 | 14,0 | 28,0 | 2,68 |
| Nu | 120 | 133 | Frappe lourde | 196 | 131 | 393 | 58,3 | 117 | 2,53 |
| Sous-équipé | 1 | 1 | Frappe lourde | 1,06 | 0,71 | 2,12 | 0,42 | 0,85 | 12,1 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,77 | 0,51 | 1,54 | 0,20 | 0,40 | 7,61 |
| Sous-équipé | 20 | 19 | Frappe lourde | 1,45 | 0,97 | 2,90 | 0,36 | 0,72 | 8,45 |
| Sous-équipé | 40 | 34 | Frappe lourde | 3,30 | 2,20 | 6,60 | 0,99 | 1,99 | 9,71 |
| Sous-équipé | 60 | 53 | Frappe lourde | 7,92 | 5,28 | 15,8 | 2,16 | 4,32 | 6,30 |
| Sous-équipé | 90 | 100 | Frappe lourde | 36,3 | 24,2 | 72,5 | 7,21 | 14,4 | 6,96 |
| Sous-équipé | 120 | 133 | Frappe lourde | 137 | 91,1 | 273 | 24,5 | 49,0 | 14,8 |
| Équipé | 1 | 1 | Frappe lourde | 1,21 | 0,80 | 2,41 | 0,44 | 0,87 | 14,0 |
| Équipé | 10 | 13 | Frappe lourde | 0,81 | 0,54 | 1,62 | 0,20 | 0,40 | 8,63 |
| Équipé | 20 | 19 | Frappe lourde | 1,46 | 0,98 | 2,93 | 0,35 | 0,69 | 11,1 |
| Équipé | 40 | 34 | Frappe lourde | 2,28 | 1,52 | 4,55 | 0,56 | 1,12 | 17,2 |
| Équipé | 60 | 53 | Frappe lourde | 6,88 | 4,59 | 13,8 | 1,86 | 3,72 | 7,34 |
| Équipé | 90 | 100 | Frappe lourde | 24,3 | 16,2 | 48,5 | 4,46 | 8,93 | 14,6 |
| Équipé | 120 | 133 | Frappe lourde | 136 | 90,5 | 272 | 26,3 | 52,5 | 6,09 |
| Sur-équipé | 1 | 1 | Frappe lourde | 1,07 | 0,71 | 2,14 | 0,30 | 0,60 | 39,1 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,57 | 0,38 | 1,14 | 0,14 | 0,27 | 11,9 |
| Sur-équipé | 20 | 19 | Frappe lourde | 1,42 | 0,95 | 2,84 | 0,34 | 0,67 | 7,64 |
| Sur-équipé | 40 | 34 | Frappe lourde | 2,51 | 1,67 | 5,02 | 0,43 | 0,86 | 69,3 |
| Sur-équipé | 60 | 53 | Frappe lourde | 8,22 | 5,48 | 16,4 | 1,51 | 3,02 | 18,4 |
| Sur-équipé | 90 | 100 | Frappe lourde | 23,3 | 15,5 | 46,6 | 3,96 | 7,92 | 24,4 |
| Sur-équipé | 120 | 133 | Frappe lourde | 128 | 85,5 | 257 | 30,9 | 61,9 | 16,7 |

</details>

## Simulation

Un robot dans `world/zone.tscn`, graine 4242, plafond de 180 s de jeu : il marche vers
l'ennemi le plus proche et lance toute sa barre dès que la recharge le permet. Un joueur
médiocre, et c'est voulu : un plancher. Une mort recharge la zone.

| build | profil | construit pour | zone jouée | niveau | tués/min | morts | sous 30 % | vidée en |
|---|---|---|---|---|---|---|---|---|
| Sort | Débutant | 1 | 1 | 1 | 22,0 | 20 | 21,7 s | — |
| Sort | Nu | 40 | 40 | 34 | 35,3 | 57 | 42,7 s | — |
| Sort | Sous-équipé | 40 | 40 | 34 | 31,7 | 31 | 19,7 s | — |
| Sort | Équipé | 40 | 40 | 34 | 58,0 | 29 | 13,6 s | — |
| Sort | Sur-équipé | 40 | 40 | 34 | 16,7 | 23 | 20,5 s | — |
| Sort | Équipé | 40 | 20 | 34 | 65,0 | 19 | 18,4 s | — |
| Sort | Équipé | 40 | 60 | 34 | 27,7 | 38 | 41,6 s | — |
| Mêlée | Débutant | 1 | 1 | 1 | 54,7 | 17 | 33,6 s | — |
| Mêlée | Nu | 40 | 40 | 34 | 18,0 | 34 | 34,9 s | — |
| Mêlée | Sous-équipé | 40 | 40 | 34 | 27,7 | 13 | 42,5 s | — |
| Mêlée | Équipé | 40 | 40 | 34 | 25,7 | 3 | 37,5 s | — |
| Mêlée | Sur-équipé | 40 | 40 | 34 | 18,3 | 0 | 0,00 s | — |
| Mêlée | Équipé | 40 | 20 | 34 | 14,3 | 0 | 0,00 s | — |
| Mêlée | Équipé | 40 | 60 | 34 | 18,7 | 15 | 39,4 s | — |

