# Banc d'équilibrage

<!-- Fichier généré par tools/equilibrage.sh — ne pas éditer à la main. -->

Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits
par les règles du jeu à chaque lancement (`BenchProfiles`), et le calcul passe par
les vraies fonctions (`BenchCalculation`). Le banc montre les écarts ; les réglages
restent une décision — voir `JALONS/hack-n-slash-jalon-13.md`.

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

Un profil équipé est tiré 9 fois : coups et survie sont les médianes, chacune
sur son axe ; le détail est celui du tirage médian en coups.

## Niveau attendu

Le niveau atteint en vidant une fois chaque zone de 1 à Z − 1, avec la population
moyenne de l'`EnemySpawner` et le retard de `Enemy.experience_factor()`.

| zone | 1 | 10 | 20 | 40 | 60 | 90 | 120 |
|---|---|---|---|---|---|---|---|
| niveau | 1 | 13 | 19 | 34 | 53 | 100 | 100 |

## Sort — Manuel de la foudre, Esprit d'orage

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,36 · 4,68 s | 🟥 2,27 · 2,20 s | 🟥 4,01 · 1,39 s | 🟥 12,6 · 0,80 s | 🟥 39,8 · 0,56 s | 🟥 226 · 0,39 s | 🟥 1310 · 0,30 s |
| Nu | 🟨 1,36 · 4,68 s | 🟥 0,67 · 2,20 s | 🟥 0,98 · 1,62 s | 🟥 1,65 · 1,21 s | 🟥 4,00 · 1,05 s | 🟥 22,7 · 2,20 s | 🟥 132 · 1,68 s |
| Sous-équipé | 🟩 1,27 · 21,3 s | 🟨 0,66 · 6,13 s | 🟥 0,97 · 3,70 s | 🟥 1,47 · 3,78 s | 🟨 3,35 · 4,31 s | 🟥 16,3 · 7,30 s | 🟥 110 · 4,87 s |
| Équipé | 🟩 1,34 · 20,2 s | 🟨 0,57 · 6,31 s | 🟨 0,94 · 6,50 s | 🟨 1,48 · 5,84 s | 🟨 3,83 · 5,83 s | 🟥 18,0 · 7,96 s | 🟥 116 · 5,24 s |
| Sur-équipé | 🟩 1,02 · ∞ s | 🟦 0,42 · 34,0 s | 🟩 0,67 · 27,0 s | 🟩 1,37 · 10,4 s | 🟨 3,05 · 4,13 s | 🟥 19,0 · 6,53 s | 🟥 108 · 6,16 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,50 | 0,99 | 4,68 |
| Débutant | 10 | 1 | Éclair vif | 2,27 | 1,51 | 4,54 | 0,83 | 1,66 | 2,20 |
| Débutant | 20 | 1 | Éclair vif | 4,01 | 2,68 | 8,03 | 1,47 | 2,93 | 1,39 |
| Débutant | 40 | 1 | Éclair vif | 12,6 | 8,40 | 25,2 | 4,60 | 9,20 | 0,80 |
| Débutant | 60 | 1 | Éclair vif | 39,8 | 26,5 | 79,6 | 14,5 | 29,1 | 0,56 |
| Débutant | 90 | 1 | Éclair vif | 226 | 151 | 452 | 82,6 | 165 | 0,39 |
| Débutant | 120 | 1 | Éclair vif | 1310 | 873 | 2620 | 479 | 957 | 0,30 |
| Nu | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,50 | 0,99 | 4,68 |
| Nu | 10 | 13 | Chaîne d'éclairs | 0,67 | 0,45 | 1,34 | 0,13 | 0,26 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 0,98 | 0,65 | 1,96 | 0,19 | 0,38 | 1,62 |
| Nu | 40 | 34 | Éclair vif | 1,65 | 1,10 | 3,29 | 0,24 | 0,47 | 1,21 |
| Nu | 60 | 53 | Éclair vif | 4,00 | 2,67 | 8,00 | 0,57 | 1,15 | 1,05 |
| Nu | 90 | 100 | Éclair vif | 22,7 | 15,2 | 45,5 | 3,25 | 6,51 | 2,20 |
| Nu | 120 | 100 | Éclair vif | 132 | 87,8 | 263 | 18,9 | 37,7 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,27 | 0,85 | 2,55 | 0,45 | 0,91 | 21,3 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,66 | 0,44 | 1,32 | 0,12 | 0,25 | 6,13 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,97 | 0,64 | 1,93 | 0,18 | 0,36 | 3,70 |
| Sous-équipé | 40 | 34 | Éclair vif | 1,47 | 0,98 | 2,95 | 0,19 | 0,38 | 3,78 |
| Sous-équipé | 60 | 53 | Éclair vif | 3,35 | 2,23 | 6,70 | 0,41 | 0,82 | 4,31 |
| Sous-équipé | 90 | 100 | Éclair vif | 16,3 | 10,8 | 32,5 | 1,98 | 3,96 | 7,30 |
| Sous-équipé | 120 | 100 | Éclair vif | 110 | 73,4 | 220 | 12,9 | 25,7 | 4,87 |
| Équipé | 1 | 1 | Éclair vif | 1,34 | 0,90 | 2,69 | 0,47 | 0,95 | 20,2 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,57 | 0,38 | 1,14 | 0,11 | 0,22 | 6,31 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,94 | 0,63 | 1,89 | 0,17 | 0,34 | 6,50 |
| Équipé | 40 | 34 | Éclair vif | 1,48 | 0,99 | 2,97 | 0,16 | 0,32 | 5,84 |
| Équipé | 60 | 53 | Éclair vif | 3,83 | 2,56 | 7,67 | 0,41 | 0,83 | 5,83 |
| Équipé | 90 | 100 | Éclair vif | 18,0 | 12,0 | 36,1 | 2,17 | 4,34 | 7,96 |
| Équipé | 120 | 100 | Éclair vif | 116 | 77,4 | 232 | 14,1 | 28,2 | 5,24 |
| Sur-équipé | 1 | 1 | Éclair vif | 1,02 | 0,68 | 2,04 | 0,32 | 0,64 | ∞ |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,42 | 0,28 | 0,83 | 0,07 | 0,14 | 34,0 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,67 | 0,44 | 1,33 | 0,10 | 0,20 | 27,0 |
| Sur-équipé | 40 | 34 | Éclair vif | 1,37 | 0,92 | 2,75 | 0,17 | 0,33 | 10,4 |
| Sur-équipé | 60 | 53 | Éclair vif | 3,05 | 2,04 | 6,11 | 0,34 | 0,68 | 4,13 |
| Sur-équipé | 90 | 100 | Éclair vif | 19,0 | 12,7 | 38,0 | 2,31 | 4,62 | 6,53 |
| Sur-équipé | 120 | 100 | Éclair vif | 108 | 72,2 | 217 | 13,2 | 26,4 | 6,16 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,00 · 18,8 s | 🟦 0,43 · 12,2 s | 🟩 0,78 · 15,1 s | 🟩 1,76 · 24,1 s | 🟨 3,04 · 26,3 s | 🟥 14,5 · 21,7 s | 🟥 69,3 · 16,1 s |
| Équipé | 🟩 1,17 · 20,5 s | 🟦 0,40 · 13,1 s | 🟩 0,76 · 27,2 s | 🟩 1,46 · 56,8 s | 🟩 2,69 · 40,0 s | 🟥 11,7 · 20,6 s | 🟥 65,3 · 13,2 s |
| Sur-équipé | 🟩 0,74 · 603 s | 🟦 0,30 · 127 s | 🟩 0,58 · 116 s | 🟩 1,32 · 55,8 s | 🟩 2,47 · 27,2 s | 🟥 13,5 · 18,9 s | 🟥 78,1 · 13,7 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 1,05 | 0,70 | 2,10 | 0,45 | 0,91 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 2,23 | 1,49 | 4,47 | 0,97 | 1,93 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 4,83 | 3,22 | 9,66 | 2,09 | 4,18 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 20,0 | 13,3 | 40,0 | 8,66 | 17,3 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 75,6 | 50,4 | 151 | 32,7 | 65,5 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 506 | 337 | 1012 | 219 | 438 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 3166 | 2111 | 6332 | 1370 | 2740 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 1,05 | 0,70 | 2,10 | 0,45 | 0,91 | 4,68 |
| Nu | 10 | 13 | Frappe lourde | 0,44 | 0,29 | 0,88 | 0,13 | 0,27 | 4,44 |
| Nu | 20 | 19 | Frappe lourde | 0,81 | 0,54 | 1,62 | 0,25 | 0,51 | 6,32 |
| Nu | 40 | 34 | Frappe lourde | 1,88 | 1,25 | 3,75 | 0,66 | 1,32 | 6,05 |
| Nu | 60 | 53 | Frappe lourde | 3,55 | 2,37 | 7,11 | 1,05 | 2,09 | 5,59 |
| Nu | 90 | 100 | Frappe lourde | 19,5 | 13,0 | 38,9 | 5,90 | 11,8 | 4,04 |
| Nu | 120 | 100 | Frappe lourde | 106 | 70,4 | 211 | 32,9 | 65,7 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 1,00 | 0,67 | 2,00 | 0,43 | 0,86 | 18,8 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,43 | 0,28 | 0,85 | 0,13 | 0,25 | 12,2 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,78 | 0,52 | 1,56 | 0,24 | 0,47 | 15,1 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,76 | 1,17 | 3,51 | 0,61 | 1,21 | 24,1 |
| Sous-équipé | 60 | 53 | Frappe lourde | 3,04 | 2,02 | 6,07 | 0,76 | 1,53 | 26,3 |
| Sous-équipé | 90 | 100 | Frappe lourde | 14,5 | 9,67 | 29,0 | 4,06 | 8,11 | 21,7 |
| Sous-équipé | 120 | 100 | Frappe lourde | 69,3 | 46,2 | 139 | 18,4 | 36,7 | 16,1 |
| Équipé | 1 | 1 | Frappe lourde | 1,17 | 0,78 | 2,33 | 0,45 | 0,91 | 20,5 |
| Équipé | 10 | 13 | Frappe lourde | 0,40 | 0,27 | 0,80 | 0,11 | 0,22 | 13,1 |
| Équipé | 20 | 19 | Frappe lourde | 0,76 | 0,51 | 1,52 | 0,23 | 0,47 | 27,2 |
| Équipé | 40 | 34 | Frappe lourde | 1,46 | 0,97 | 2,92 | 0,46 | 0,91 | 56,8 |
| Équipé | 60 | 53 | Frappe lourde | 2,69 | 1,79 | 5,37 | 0,73 | 1,47 | 40,0 |
| Équipé | 90 | 100 | Frappe lourde | 11,7 | 7,83 | 23,5 | 2,77 | 5,54 | 20,6 |
| Équipé | 120 | 100 | Frappe lourde | 65,3 | 43,5 | 131 | 15,6 | 31,1 | 13,2 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,74 | 0,49 | 1,48 | 0,30 | 0,59 | 603 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,30 | 0,20 | 0,60 | 0,07 | 0,14 | 127 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,58 | 0,39 | 1,17 | 0,16 | 0,31 | 116 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,32 | 0,88 | 2,64 | 0,28 | 0,56 | 55,8 |
| Sur-équipé | 60 | 53 | Frappe lourde | 2,47 | 1,65 | 4,95 | 0,59 | 1,17 | 27,2 |
| Sur-équipé | 90 | 100 | Frappe lourde | 13,5 | 8,97 | 26,9 | 2,39 | 4,78 | 18,9 |
| Sur-équipé | 120 | 100 | Frappe lourde | 78,1 | 52,1 | 156 | 17,7 | 35,4 | 13,7 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
