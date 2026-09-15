class_name Texts

## La traduction d'un texte affiché, **le seul endroit qui la demande**. Le français
## est la clé, `i18n/en.po` donne l'anglais. `TranslationServer` et non `tr()`, qui
## n'existe pas en statique. Un nom court : il enveloppe chaque texte, et les tests le
## relèvent dans les sources. Une feuille.


## Le contexte sépare deux sens d'un même mot (« vitesse »).
static func t(text_value: String, context := "") -> String:
	if text_value.is_empty():
		return text_value
	return TranslationServer.translate(text_value, context)


## Le pluriel : la règle de chaque langue est dans `en.po`, jamais chez l'appelant.
static func tn(singular: String, plural: String, count: int, context := "") -> String:
	return TranslationServer.translate_plural(singular, plural, count, context)
