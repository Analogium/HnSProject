class_name UiPalette

## Les couleurs que **plusieurs** panneaux emploient ; une couleur propre à un seul
## reste chez lui.

## Fond de panneau. L'opacité vaut pour une fenêtre posée sur le décor.
const BACK := Color(0.082, 0.075, 0.106, 0.97)
## Opaque, pour les écrans plein cadre : le bandeau de débogage transparaîtrait.
const BACK_PLEIN := Color(BACK, 1.0)
## Plus sombre et opaque qu'un panneau, sur lequel elle se pose.
const TIP_BACK := Color(0.055, 0.051, 0.075, 0.98)
const BORDER := Color(0.29, 0.27, 0.35)
## Les lignes d'aide, présentes sans attirer l'œil.
const HINT := Color(0.52, 0.50, 0.60)
## Les intitulés, plus sombres que le texte qu'ils annoncent.
const LABEL := Color(0.42, 0.40, 0.50)
## Le texte courant des panneaux dessinés : noms, valeurs, entrées de menu.
const TEXTE := Color(0.90, 0.88, 0.95)
## Le titre en tête d'une fenêtre : « SAC », « PERSONNAGE », « MANUELS ».
const TITRE := Color(0.80, 0.77, 0.86)
## Les points à placer : un gain en attente, pas un avertissement.
const A_PLACER := Color(0.52, 0.88, 0.48)
