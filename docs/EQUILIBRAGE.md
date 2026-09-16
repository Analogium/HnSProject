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
| Sous-équipé | 🟩 1,01 · 13,1 s | 🟨 0,92 · 4,58 s | 🟥 1,60 · 2,83 s | 🟥 3,86 · 2,54 s | 🟥 6,17 · 1,64 s | 🟥 16,3 · 5,55 s | 🟥 306 · 1,22 s |
| Équipé | 🟩 1,28 · 11,8 s | 🟨 0,99 · 5,61 s | 🟨 1,60 · 5,88 s | 🟥 3,20 · 3,78 s | 🟥 13,0 · 6,11 s | 🟥 79,9 · 2,42 s | 🟥 327 · 2,89 s |
| Sur-équipé | 🟩 0,82 · 809 s | 🟨 0,65 · 7,46 s | 🟨 0,78 · 5,13 s | 🟨 4,45 · 4,34 s | 🟥 11,2 · 2,98 s | 🟥 45,1 · 1,35 s | 🟥 463 · 1,98 s |

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
| Sous-équipé | 1 | 1 | Éclair vif | 1,01 | 0,67 | 2,02 | 0,18 | 0,35 | 13,1 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,92 | 0,61 | 1,84 | 0,12 | 0,25 | 4,58 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 1,60 | 1,07 | 3,20 | 0,20 | 0,40 | 2,83 |
| Sous-équipé | 40 | 34 | Chaîne d'éclairs | 3,86 | 2,57 | 7,72 | 0,44 | 0,87 | 2,54 |
| Sous-équipé | 60 | 53 | Chaîne d'éclairs | 6,17 | 4,11 | 12,3 | 0,54 | 1,09 | 1,64 |
| Sous-équipé | 90 | 100 | Chaîne d'éclairs | 16,3 | 10,9 | 32,7 | 0,94 | 1,89 | 5,55 |
| Sous-équipé | 120 | 133 | Chaîne d'éclairs | 306 | 204 | 612 | 14,8 | 29,5 | 1,22 |
| Équipé | 1 | 1 | Éclair vif | 1,28 | 0,86 | 2,57 | 0,44 | 0,87 | 11,8 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,99 | 0,66 | 1,98 | 0,14 | 0,27 | 5,61 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 1,60 | 1,07 | 3,20 | 0,18 | 0,36 | 5,88 |
| Équipé | 40 | 34 | Chaîne d'éclairs | 3,20 | 2,13 | 6,39 | 0,32 | 0,63 | 3,78 |
| Équipé | 60 | 53 | Chaîne d'éclairs | 13,0 | 8,67 | 26,0 | 1,10 | 2,19 | 6,11 |
| Équipé | 90 | 100 | Chaîne d'éclairs | 79,9 | 53,3 | 160 | 4,74 | 9,49 | 2,42 |
| Équipé | 120 | 133 | Chaîne d'éclairs | 327 | 218 | 654 | 16,3 | 32,7 | 2,89 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,82 | 0,54 | 1,63 | 0,21 | 0,42 | 809 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,65 | 0,43 | 1,30 | 0,07 | 0,15 | 7,46 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,78 | 0,52 | 1,57 | 0,08 | 0,16 | 5,13 |
| Sur-équipé | 40 | 34 | Chaîne d'éclairs | 4,45 | 2,97 | 8,91 | 0,37 | 0,74 | 4,34 |
| Sur-équipé | 60 | 53 | Chaîne d'éclairs | 11,2 | 7,46 | 22,4 | 0,86 | 1,73 | 2,98 |
| Sur-équipé | 90 | 100 | Chaîne d'éclairs | 45,1 | 30,0 | 90,1 | 2,77 | 5,55 | 1,35 |
| Sur-équipé | 120 | 133 | Chaîne d'éclairs | 463 | 309 | 926 | 21,4 | 42,7 | 1,98 |

</details>

## Mêlée — Manuel du chevalier, force

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,30 · 4,68 s | 🟥 2,92 · 2,20 s | 🟥 6,55 · 1,39 s | 🟥 28,2 · 0,80 s | 🟥 109 · 0,56 s | 🟥 740 · 0,39 s | 🟥 4672 · 0,30 s |
| Nu | 🟨 1,30 · 4,68 s | 🟥 0,89 · 3,53 s | 🟥 1,62 · 3,78 s | 🟥 4,09 · 2,89 s | 🟥 11,3 · 2,54 s | 🟥 44,0 · 2,68 s | 🟥 196 · 2,53 s |
| Sous-équipé | 🟩 1,06 · 12,1 s | 🟨 0,74 · 7,61 s | 🟨 1,32 · 7,60 s | 🟨 3,16 · 9,50 s | 🟥 8,34 · 6,46 s | 🟥 36,3 · 6,96 s | 🟥 150 · 13,8 s |
| Équipé | 🟩 1,21 · 14,0 s | 🟨 0,76 · 7,46 s | 🟩 1,46 · 11,1 s | 🟩 2,34 · 24,7 s | 🟨 6,88 · 7,34 s | 🟥 16,0 · 11,8 s | 🟥 159 · 7,78 s |
| Sur-équipé | 🟩 1,07 · 39,1 s | 🟩 0,57 · 11,9 s | 🟨 1,42 · 7,64 s | 🟩 2,79 · 35,3 s | 🟨 7,76 · 21,3 s | 🟥 21,0 · 28,3 s | 🟥 128 · 13,8 s |

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
| Sous-équipé | 10 | 13 | Frappe lourde | 0,74 | 0,50 | 1,49 | 0,20 | 0,41 | 7,61 |
| Sous-équipé | 20 | 19 | Frappe lourde | 1,32 | 0,88 | 2,64 | 0,34 | 0,68 | 7,60 |
| Sous-équipé | 40 | 34 | Frappe lourde | 3,16 | 2,11 | 6,32 | 0,95 | 1,90 | 9,50 |
| Sous-équipé | 60 | 53 | Frappe lourde | 8,34 | 5,56 | 16,7 | 2,27 | 4,54 | 6,46 |
| Sous-équipé | 90 | 100 | Frappe lourde | 36,3 | 24,2 | 72,5 | 8,61 | 17,2 | 6,96 |
| Sous-équipé | 120 | 133 | Frappe lourde | 150 | 100 | 300 | 27,0 | 54,1 | 13,8 |
| Équipé | 1 | 1 | Frappe lourde | 1,21 | 0,80 | 2,41 | 0,44 | 0,87 | 14,0 |
| Équipé | 10 | 13 | Frappe lourde | 0,76 | 0,51 | 1,52 | 0,19 | 0,39 | 7,46 |
| Équipé | 20 | 19 | Frappe lourde | 1,46 | 0,98 | 2,93 | 0,35 | 0,69 | 11,1 |
| Équipé | 40 | 34 | Frappe lourde | 2,34 | 1,56 | 4,69 | 0,58 | 1,16 | 24,7 |
| Équipé | 60 | 53 | Frappe lourde | 6,88 | 4,59 | 13,8 | 1,86 | 3,72 | 7,34 |
| Équipé | 90 | 100 | Frappe lourde | 16,0 | 10,7 | 32,1 | 2,83 | 5,67 | 11,8 |
| Équipé | 120 | 133 | Frappe lourde | 159 | 106 | 318 | 32,2 | 64,4 | 7,78 |
| Sur-équipé | 1 | 1 | Frappe lourde | 1,07 | 0,71 | 2,14 | 0,33 | 0,67 | 39,1 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,57 | 0,38 | 1,14 | 0,14 | 0,27 | 11,9 |
| Sur-équipé | 20 | 19 | Frappe lourde | 1,42 | 0,95 | 2,84 | 0,34 | 0,67 | 7,64 |
| Sur-équipé | 40 | 34 | Frappe lourde | 2,79 | 1,86 | 5,57 | 0,66 | 1,31 | 35,3 |
| Sur-équipé | 60 | 53 | Frappe lourde | 7,76 | 5,17 | 15,5 | 1,37 | 2,73 | 21,3 |
| Sur-équipé | 90 | 100 | Frappe lourde | 21,0 | 14,0 | 41,9 | 3,59 | 7,17 | 28,3 |
| Sur-équipé | 120 | 133 | Frappe lourde | 128 | 85,5 | 257 | 30,9 | 61,9 | 13,8 |

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

