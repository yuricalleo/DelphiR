# Common words removed by delphi_words(): articles, prepositions,
# conjunctions, pronouns, auxiliary and modal verbs, and frequent adverbs.
# The lists are written for DelphiR and stored in R/sysdata.rda.

en <- c(
  "a", "about", "above", "after", "again", "against", "all", "also", "although",
  "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been",
  "before", "being", "below", "between", "both", "but", "by", "can", "cannot",
  "could", "did", "do", "does", "doing", "done", "down", "during", "each", "either",
  "else", "even", "ever", "every", "few", "for", "from", "further", "had", "has",
  "have", "having", "he", "her", "here", "hers", "herself", "him", "himself", "his",
  "how", "however", "i", "if", "in", "into", "is", "it", "its", "itself", "just",
  "let", "may", "maybe", "me", "might", "more", "most", "much", "must", "my",
  "myself", "neither", "no", "nor", "not", "now", "of", "off", "often", "on", "once",
  "one", "only", "or", "other", "others", "otherwise", "our", "ours", "ourselves",
  "out", "over", "own", "per", "perhaps", "quite", "rather", "really", "same", "shall",
  "she", "should", "since", "so", "some", "such", "than", "that", "the", "their",
  "theirs", "them", "themselves", "then", "there", "therefore", "these", "they",
  "this", "those", "though", "through", "thus", "to", "too", "under", "until", "up",
  "upon", "us", "very", "was", "we", "were", "what", "when", "where", "whether",
  "which", "while", "who", "whom", "whose", "why", "will", "with", "within",
  "without", "would", "yet", "you", "your", "yours", "yourself", "yourselves",
  # Fragments left by splitting contractions at the apostrophe
  "don", "doesn", "didn", "isn", "wasn", "weren", "won", "wouldn", "couldn",
  "shouldn", "haven", "hasn", "hadn", "aren", "ll", "ve", "re"
)

it <- c(
  # Articles and articulated prepositions
  "il", "lo", "la", "i", "gli", "le", "un", "uno", "una",
  "di", "a", "da", "in", "con", "su", "per", "tra", "fra",
  "del", "dello", "della", "dei", "degli", "delle",
  "al", "allo", "alla", "ai", "agli", "alle",
  "dal", "dallo", "dalla", "dai", "dagli", "dalle",
  "nel", "nello", "nella", "nei", "negli", "nelle",
  "sul", "sullo", "sulla", "sui", "sugli", "sulle",
  "col", "coi",
  # Elided forms, split at the apostrophe
  "l", "d", "c", "s", "m", "t", "v", "dell", "all", "dall", "nell", "sull",
  "quest", "quell", "un", "po",
  # Conjunctions and adverbs
  "e", "ed", "o", "od", "ma", "che", "se", "anche", "come", "quando", "dove",
  "perché", "perche", "poiché", "poiche", "quindi", "dunque", "però",
  "pero", "invece", "mentre", "oppure", "cioè", "cioe", "infatti", "inoltre",
  "pertanto", "sia", "né", "ne", "non", "sì", "si", "no", "più", "piu",
  "meno", "molto", "molti", "molta", "molte", "poco", "pochi", "poca", "poche",
  "tanto", "tanti", "tanta", "tante", "troppo", "già", "gia", "ancora",
  "sempre", "mai", "ora", "oggi", "poi", "prima", "dopo", "qui", "qua", "lì",
  "li", "là", "solo", "soltanto", "proprio", "forse", "comunque", "almeno",
  "circa", "bene", "male", "così", "cosi", "tuttavia", "ovvero", "ossia",
  "affinché", "affinche", "bensì", "bensi", "nonché", "nonche",
  "nonostante", "secondo", "senza", "verso", "sotto", "sopra", "dentro", "fuori",
  "attraverso", "durante", "entro", "presso", "contro", "oltre",
  # Pronouns and determiners
  "io", "tu", "lui", "lei", "noi", "voi", "loro", "mi", "ti", "ci", "vi", "me",
  "te", "se", "sé", "lo", "gli", "mio", "mia", "miei", "mie", "tuo", "tua",
  "tuoi", "tue", "suo", "sua", "suoi", "sue", "nostro", "nostra", "nostri",
  "nostre", "vostro", "vostra", "vostri", "vostre", "questo", "questa", "questi",
  "queste", "quello", "quella", "quelli", "quelle", "quel", "quei", "quegli",
  "stesso", "stessa", "stessi", "stesse", "tutto", "tutta", "tutti", "tutte",
  "ogni", "ciascuno", "ciascuna", "qualche", "alcuni", "alcune", "altro", "altra",
  "altri", "altre", "chi", "cui", "quale", "quali", "quanto", "quanta", "quanti",
  "quante", "nessuno", "nessuna", "niente", "nulla", "qualcosa", "qualcuno",
  "tale", "tali",
  # Auxiliary and modal verbs
  "essere", "sono", "sei", "è", "siamo", "siete", "era", "erano", "ero",
  "eravamo", "fu", "furono", "sarà", "sara", "saranno", "sarebbe",
  "sarebbero", "sia", "siano", "fosse", "fossero", "stato", "stata", "stati",
  "state", "essendo", "avere", "ho", "hai", "ha", "abbiamo", "avete", "hanno",
  "aveva", "avevano", "avrà", "avra", "avranno", "avrebbe", "avrebbero",
  "abbia", "abbiano", "avesse", "avuto", "avendo", "fare", "fa", "fanno", "fatto",
  "potere", "può", "puo", "possono", "potrebbe", "potrebbero", "potrà",
  "potra", "dovere", "deve", "devono", "dovrebbe", "dovrebbero", "dovrà",
  "dovra", "volere", "vuole", "vogliono", "viene", "vengono", "venire", "stare",
  "sta", "stanno"
)

stopword_lists <- list(en = sort(unique(en)), it = sort(unique(enc2utf8(it))))
save(stopword_lists, file = "R/sysdata.rda", compress = "bzip2", version = 2)
