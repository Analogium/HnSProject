class_name Textes

## La traduction d'un texte affiché, et **le seul endroit du jeu qui la demande**.
##
## Le français est la langue source : ce que le code écrit **est** la clé, et
## `i18n/en.po` en donne l'anglais. Un texte montré au joueur sans passer par ici
## reste donc en français, quelle que soit la langue choisie — c'est le défaut que
## le filet des lettres accentuées cherche.
##
## `TranslationServer` et non `tr()` : `tr()` est une méthode d'objet, et la
## moitié des lectures de libellés du jeu sont des fonctions **statiques**. Deux
## façons de traduire, c'est déjà une de trop.
##
## Un nom court, contrairement au reste du projet : il enveloppe chaque texte
## affiché, et un verbe de huit lettres noierait la phrase qu'il porte. C'est
## aussi la marque que les tests relèvent dans les sources pour vérifier que
## chaque texte a bien son anglais.
##
## Une feuille : elle ne dépend de rien, comme `DamageType` et `Tirage`.


## Le texte dans la langue courante. Le contexte sépare deux sens d'un même mot
## français — « vitesse » de déplacement et « vitesse » d'un trait — qui ne se
## traduisent pas pareil.
static func t(texte: String, contexte := "") -> String:
	if texte.is_empty():
		return texte
	return TranslationServer.translate(texte, contexte)


## Le pluriel : « 1 point à placer », « 3 points à placer ». Chaque langue a sa
## règle — le français met le singulier à zéro, l'anglais le pluriel — et c'est
## `en.po` qui la porte, jamais l'appelant.
static func tn(singulier: String, pluriel: String, nombre: int, contexte := "") -> String:
	return TranslationServer.translate_plural(singulier, pluriel, nombre, contexte)
