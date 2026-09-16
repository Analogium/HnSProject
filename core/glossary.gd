class_name Glossary

## Les mots du joueur qui ont une définition : « accru », « amplifié »… Un terme s'écrit
## **par `term()` seulement**, entouré d'une marque invisible que le dessin lit pour le
## mettre en gras et ouvrir son encadré. Chercher le mot dans le texte trouverait aussi
## « Réduit les dégâts de froid », qui n'est pas le terme. Une feuille.

## La marque : début, identifiant, séparateur, mot, fin. Des caractères de contrôle,
## qu'aucune clé de traduction ne contient.
const START := ""
const SEPARATOR := ""
const END := ""

## L'ordre des formes d'un terme : masculin, féminin, singulier puis pluriel.
const AGREEMENTS := ["ms", "fs", "mp", "fp"]

## Chaque terme, l'encadré qui l'explique et ses formes françaises — les clés.
## **Identifiants définitifs** : ils voyagent dans la marque.
const TERMS := {
	"increased": {"entry": "additive", "forms": ["accru", "accrue", "accrus", "accrues"]},
	"reduced": {"entry": "additive", "forms": ["réduit", "réduite", "réduits", "réduites"]},
	"more": {"entry": "multiplicative", "forms": ["amplifié", "amplifiée", "amplifiés", "amplifiées"]},
	"less": {"entry": "multiplicative", "forms": ["atténué", "atténuée", "atténués", "atténuées"]},
}

## Un encadré par sens : accru et réduit se lisent ensemble.
const ENTRIES := {
	"additive": {
		"title": "Accru, réduit",
		"text": "Les bonus accrus et réduits d'une même statistique s'additionnent, puis s'appliquent ensemble. Deux fois +10 % accrus font +20 %.",
	},
	"multiplicative": {
		"title": "Amplifié, atténué",
		"text": "Chaque bonus amplifié ou atténué multiplie le résultat à lui seul, après les accrus. Deux fois +10 % amplifiés font +21 %.",
	},
}


## Le mot accordé et traduit, marqué.
static func term(id: String, agreement: String) -> String:
	var forms: Array = TERMS[id]["forms"]
	var word := Texts.t(forms[maxi(AGREEMENTS.find(agreement), 0)])
	return START + id + SEPARATOR + word + END


## Sans marque : pour ce qui ne se dessine pas en jeu — catalogue, forge, messages.
static func plain(text_value: String) -> String:
	var out := ""
	var i := 0
	while i < text_value.length():
		var c := text_value[i]
		if c == START:
			i = text_value.find(SEPARATOR, i)
			if i < 0:
				break
		elif c != END:
			out += c
		i += 1
	return out


## Les encadrés que ce texte appelle, dans l'ordre d'apparition, sans doublon.
static func terms(text_value: String) -> PackedStringArray:
	var out := PackedStringArray()
	var at := text_value.find(START)
	while at >= 0:
		var separator := text_value.find(SEPARATOR, at)
		if separator < 0:
			break
		var id := text_value.substr(at + 1, separator - at - 1)
		if TERMS.has(id):
			var entry: String = TERMS[id]["entry"]
			if not out.has(entry):
				out.append(entry)
		at = text_value.find(START, separator)
	return out


static func title(entry: String) -> String:
	return Texts.t(ENTRIES[entry]["title"])


static func definition(entry: String) -> String:
	return Texts.t(ENTRIES[entry]["text"])
