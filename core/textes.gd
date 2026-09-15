class_name Textes

## La traduction d'un texte affiché, **le seul endroit qui la demande**. Le français
## est la clé, `i18n/en.po` donne l'anglais. `TranslationServer` et non `tr()`, qui
## n'existe pas en statique. Un nom court : il enveloppe chaque texte, et les tests le
## relèvent dans les sources. Une feuille.


## Le contexte sépare deux sens d'un même mot (« vitesse »).
static func t(texte: String, contexte := "") -> String:
	if texte.is_empty():
		return texte
	return TranslationServer.translate(texte, contexte)


## Le pluriel : la règle de chaque langue est dans `en.po`, jamais chez l'appelant.
static func tn(singulier: String, pluriel: String, nombre: int, contexte := "") -> String:
	return TranslationServer.translate_plural(singulier, pluriel, nombre, contexte)
