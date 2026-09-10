#!/bin/sh

#
# Définitions de fonctions et de variables communes à tous les
# scripts de tests.
#
# Note sur l'utilisation des scripts de tests (scripts test*.sh dans les
# répertoires des exercices) :
# Syntaxe :
# 	./test.sh [-h] [-v] [-t ...] [-k] [-d] [-s] [numtest ...]
#
# Par défaut, le script exécute tous les tests et doit afficher
# "Tests ok" à la fin. Dans le cas contraire, le nom du tests
# échoué s'affiche, et les fichiers utilisés par le test sont
# laissés dans /tmp/test*. Il est alors possible de les examiner.
#
# Il est également possible d'exécuter un ou plusieurs tests
# spécifiques. Par exemple, pour exécuter les tests 1.3 et 4.2
# il faut faire :
# 	./test.sh 1.3 4.2
#
# Pour avoir plus de détails sur ce que fait chaque test, il
# faut utiliser l'option -v (verbose). Il est conseillé de l'utiliser
# avec un test spécifique. Par exemple, pour examiner en détail
# ce que fait le test 2.5, il faut faire :
# 	./test -v 2.5
#
# L'option -h (help) rappelle la syntaxe
# L'option -t (terse) affiche le résultat des tests de façon sobre
#	ou très sobre avec -t -t
# L'option -k (keep) conserve les fichiers même si le dernier test réussit
# L'option -d (duration) n'exécute pas les tests, mais retourne une estimation
# 	de la durée maximum, pour utilisation par des scripts appelants
# L'option -s (score) affiche le score à la fin de l'exécution
#

TMP=${TMP:=/tmp/test.$USER}		# chemin des logs de test
umask 0077				# permissions des fichiers temporaires

# Durée maximum (par défaut) de chaque test individuel
MAXDUR=${MAXDUR:=2}			# en secondes

# Conserver la locale d'origine
OLDLOCALE=$(locale)

# Pour éviter les différences de comportement suivant la locale courante
LC_ALL=POSIX
export LC_ALL

set -u					# erreur si accès variable non définie

# aucun test n'est en cours
CURTEST=""			# sinon : numéro de test

# aucun test n'a (encore) échoué
FAILNUM=""				# sinon : numéro de test

# nombre de tests dans ce script (pour le calcul du score)
TOTTESTS=0				# total (y.c. les ignorés)
TOTTESTSOK=0				# réussis (y.c. les ignorés)
NBTESTS=0				# total (non ignorés)
NBTESTSOK=0				# réussis (non ignorés)

# \n (ASCII NL pour new-line)
NL="
"

# fonction à appeler pour le nettoyage à la fin de chaque test (réussi)
NETTOYER=nettoyer

# durée estimée (pour l'option -d)
DUREE_ESTIMEE=0

# tests à ignorer pour le calcul du score : il s'agit des tests qui
# passent même s'il n'y a eu aucune modification des fichiers fournis.
TESTS0=""

if [ "${BASH:=heureusement-non}" != "heureusement-non" ]
then
    (
	echo "Vous exécutez ce script avec 'bash', non compatible avec POSIX"
	echo "Il y a des problèmes d'affichage avec ce Shell."
	echo "Préférez 'dash' ou un autre shell : dash ./test.sh ...."
    ) >&2
fi

#
# Analyser les options éventuelles, y compris les numéros des
# tests spécifiés
#

TESTS_TOUS=oui			# faire tous les tests...
TESTS_A_FAIRE=""		# ... ou bien seulement certains
TESTS_VUS=""			# les tests qu'on a déjà vus (pour cohérence)
VERBOSE=non			# affiche le détail d'un test
TERSE=0				# affichage des résultats des tests
KEEP=non			# nettoyer après le dernier test
DO=oui				# faire les tests
DUREE=non			# ne pas faire les tests, mais estimer la durée
SCORE=non			# résumer le score à la fin

while getopts "hvtkds" opt
do
    case "$opt" in
	(v)			# -v : verbose
	    VERBOSE=oui
	    ;;
	(t)			# -t : terse
	    TERSE=$((TERSE + 1))
	    ;;
	(k)			# -k : keep
	    KEEP=oui
	    ;;
	(d)			# -d : durée maximum estimée
	    DO=non
	    DUREE=oui
	    ;;
	(s)			# -s : résumer le score à la fin
	    SCORE=oui
	    ;;
	(h|*)			# -h : help ou *: non reconnu
	    echo "usage: $0 [-h][-v][-t][-k][-d][-s] [num...]" >&2
	    echo "exemple : $0 -v 2.1 2.3" >&2
	    exit 1
	    ;;
    esac
done

#
# Incompatbilités
#

if [ $DUREE = oui -a $SCORE = oui ]
then echo "options incompatibles : -d et -s" >&2 ; exit 1
fi

#
# Numéros de tests demandés
#

shift $((OPTIND - 1))
for num
do
    if echo "$num" | grep -q "^[0-9][0-9]*\.[0-9][0-9]*$"
    then
	TESTS_TOUS=non
	if [ -z "$TESTS_A_FAIRE" ]
	then TESTS_A_FAIRE="${num}"
	else TESTS_A_FAIRE="${TESTS_A_FAIRE}${NL}${num}"
	fi
    else
	echo "Numéro de test '$num' invalide" >&2
	exit 1
    fi
done

##############################################################################
# Fonction d'erreur

# Cette fonction est à appeler lorsqu'un élément de l'infrastructure
# de test rencontre une erreur "impossible" : elle a pour but de
# détecter des problèmes de rédaction des scripts de test si un test
# de cohérence est effectué (erreurs internes, non liées à la qualité
# du programme à tester).
# La fonction retourne un code de retour spécifique (= 120)
# $1 = message d'erreur (normalement, une erreur interne)
fatal ()
{
    echo "${NL}FATAL: $1" >&2
    trap "" EXIT		# annuler l'action automatique de fin
    exit 120
}

##############################################################################
# Mécanique de gestion des tests : échec, réussite, tests à ne pas faire, etc.

# Il ne faudrait jamais appeler cette fonction...
# Note : cette fonction ne doit être appelée que dans le contexte
# du sous-shell qui exécute la fonction "f" de test
# $1 : message d'erreur
# Code de retour : 1 (échec du test) ou 120 (appel à fatal => erreur interne)
fail ()
{
    local msg="$1"

    if [ -z "$CURTEST" ]
    then fatal "'fail' appelée sans test en cours${NL}MESSAGE : $msg" >&2
    else echo "$msg" > "$TMP.fail"
    fi
    exit 1			# seulement si on arrive ici avec un test
}

# Une fausse fonction "fail" destinée à être appelée hors contexte de
# du sous-shell de la fonction de test, c'est-à-dire ici pour la
# vérification de l'existence du ou des programmes
failcc ()
{
    local msg="$1"

    if [ "$TERSE" = 0 ]
    then
	echo $msg
    elif [ "$TERSE" = 1 ]
    then echo "fail cc"
    else :				# rien du tout si >= 2
    fi
    PROGCOMPILE=non
    FAILNUM="cc"
    DO=non
    # on passe ensuite par les autres tests (ignorés), puis on arrive
    # dans "fin" (via trap) pour effectuer le calcul du score
}

# Action implicite à la fin "normale" du script
# Cette fonction est appelée automatiquement en fin "normale" (ok ou
# fail, mais pas fatal) d'exécution du script.
fin ()
{
    [ $# != 0 ] && fatal "SYNTAXE fin / $# = $*"

    local exitcode=0

    if [ ! -z "$CURTEST" ]
    then run_test
    fi

    if [ "$DO" = oui ]
    then
	if [ ! -z "$CURTEST" ]
	then
	    # faut-il conserver les fichiers ?
	    if [ "$KEEP" = non ]
	    then
		# La fonction "nettoyer", ou bien la fonction spécifiée
		# dans le script de test, au cas où on veuille en faire
		# plus que "nettoyer"
		$NETTOYER
	    fi
	fi
	if [ ! -z "$TESTS_A_FAIRE" ]
	then
	    if [ $(echo "$TESTS_A_FAIRE" | wc -l) = 1 ]
	    then s=""
	    else s="s"
	    fi
	    echo "Test$s non trouvé$s :" $(echo $TESTS_A_FAIRE) >&2
	    exit 2
	fi
	if [ "$TESTS_TOUS" = oui ] && [ "$TERSE" = 0 ]
	then echo "Tests ok"
	fi
    elif [ "$DUREE" = oui ]
    then
	# afficher la durée estimée (on n'a pas fait les tests)
	echo $DUREE_ESTIMEE
	exit 0
    fi

    if [ "FAILNUM" != "" ]
    then exitcode=1
    fi

    if [ "$TERSE" = 2 ]
    then
	if [ "$FAILNUM" = "" ]
	then echo "OK"
	else echo "FAIL $FAILNUM"
	fi
    fi

    if [ "$SCORE" = oui ]
    then
	resultat=""
	suite=""
	if [ "$FAILNUM" = "" ]
	then
	    resultat=OK
	    score=100
	    brut=100
	elif test_ignore "$FAILNUM"
	then
	    resultat="FAIL $FAILNUM"
	    score=0
	    brut=$((100 * TOTTESTSOK / TOTTESTS))
	    suite=" REGRESSION"
	else
	    resultat="FAIL $FAILNUM"
	    if [ "$PROGCOMPILE" = oui ] && ! test_ignore "cc"
	    then
		# il faut comptabiliser une compilation réussie dans le score
		NBTESTS=$((NBTESTS+1))
		NBTESTSOK=$((NBTESTSOK+1))	# le programme compile
	    fi
	    brut=$((100 * TOTTESTSOK / TOTTESTS))	# score brut (hors cc)
	    score=$((100 * NBTESTSOK / NBTESTS))	# score affiché
	fi
	echo "SCORE $score $brut $resultat$suite"
    fi

    exit $exitcode
}

# Introduit un nouveau test, mais ne l'exécute pas immédiatement
# (le test sera exécuté soit lorsqu'on appellera à nouveau "def_test",
# soit à la fin du script, dans "fin").
# Cette fonction pourrait être intégrée dans "run_test", mais
# c'est surtout un moyen de placer le numéro et le nom du test avant
# la fonction "f".
# $1 = numéro du test
# $2 = intitulé
# $3 (optionnel) = durée maximum autorisée pour le test (défaut = $MAXDUR)
# Les variables "globales" CURTEST, TITTEST et DURTEST
# sont initialisées pour utilisation dans "run_test"
def_test ()
{
    [ $# != 2 -a $# != 3 ] && fatal "SYNTAXE def_test / $# = $*"

    if [ ! -z "$CURTEST" ]
    then run_test
    fi

    CURTEST="$1"			# variable "globale" numéro test courant
    TITTEST="$2"			# variable "globale" titre du test

    # a-t-on défini une limite de temps ou faut-il utiliser celle par défaut ?
    DURTEST=$MAXDUR			# variable "globale" durée du test
    if [ $# = 3 ]
    then DURTEST="$3"
    fi

    local last omaj omin nmaj nmin

    # vérifications de la cohérence de la numérotation des tests
    local regexp="^$(echo "$CURTEST" | sed 's/\./\\./')$"
    local last=$(echo "$TESTS_VUS" | tail -n 1)	# dernier test vu

    # on ne devrait pas avoir deux fois le même numéro
    if echo "$TESTS_VUS" | grep -q "$regexp"
    then fatal "def_test : test $CURTEST redondant"
    else TESTS_VUS="$TESTS_VUS${NL}$CURTEST"
    fi

    # on ne devrait pas avoir de trou dans les numéros
    if [ ! -z "$last" ]
    then
	omaj=$(echo "$last" | sed 's/\([^.]*\)\.\([^.]*\)/\1/')
	omin=$(echo "$last" | sed 's/\([^.]*\)\.\([^.]*\)/\2/')
	nmaj=$(echo "$CURTEST" | sed 's/\([^.]*\)\.\([^.]*\)/\1/')
	nmin=$(echo "$CURTEST" | sed 's/\([^.]*\)\.\([^.]*\)/\2/')
	if [ "$nmaj" = "$omaj" ]
	then
	    if [ "$nmin" != $((omin + 1)) ]
	    then fatal "def_test : test $CURTEST ne suit pas $last"
	    fi
	elif [ "$nmaj" != $((omaj + 1)) -o "$nmin" != 1 ]
	then fatal "def_test : test $CURTEST ne suit pas $last"
	fi
    fi

    # comptage des tests pris en compte dans le calcul du score
    TOTTESTS=$((TOTTESTS+1))
    if ! test_ignore "$CURTEST"
    then NBTESTS=$((NBTESTS+1))
    fi
}

# Longueur (en nb de caractères, pas d'octets) d'une chaîne UTF-8
# Note : la locale doit être en UTF-8
strlen ()
{
    [ $# != 1 ] && fatal "SYNTAXE strlen / $# = $*"
    local str="$1"
    (
	eval $OLDLOCALE
	printf "%s" "$str" | wc -m
    )
}

# Annonce le test (numéro et message)
# $1 = numéro du test
# $2 = msg
annoncer_test ()
{
    [ $# != 2 ] && fatal "SYNTAXE annoncer_test / $# = $*"
    local num="$1" msg="$2"

    local debut nbcar ntirets points cols

    # largeur du terminal (si pas de terminal, on prend 80 par défaut)
    if [ "$(tty)" != "not a tty" ] && stty size > /dev/null 2>&1
    then cols=$(stty size | sed 's/.* //')
    else cols=80
    fi

    # echo '\c', bien que POSIX, n'est pas supporté sur tous les Shell
    # POSIX recommande d'utiliser printf
    # Par contre, printf ne gère pas correctement les caractères Unicode
    # donc on est obligé de recourir à un subterfuge pour préserver
    # l'alignement des "OK"
    debut="Test $num - $msg"
    nbcar=$(strlen "$debut")
    ntirets=$((cols - 6 - nbcar))
    points=$(awk -v c=$ntirets 'END { for (i=0;i<c;i++) printf "." }' /dev/null)
    printf "%s%s " "$debut" "$points"
}

# Appelle la fonction "f" dans un sous-shell, avec le timeout indiqué.
# $1 = numéro du test (pour passer à la fonction si jamais elle en avait besoin)
# $2 = timeout
# $3 = "oui" si le mode "verbose" a été activé, ou "non"
execute_fonction ()
{
    [ $# != 3 ] && fatal "SYNTAXE execute_fonction / $# = $*"
    local num="$1" maxdur="$2" verbose="$3"
    local sig=FPE

    rm -f "$TMP.fail"
    CURTEST="$num"

    # lancer la fonction du test en arrière plan, dans un sous-shell
    # toutes les variables seront ainsi locales, et la fonction
    # pourra appeler "exit"
    (
	trap "fail 'timeout de $maxdur secondes expiré'" $sig
	if [ $verbose = "oui" ]
	then set -x
	fi
	f $num
	# On n'arrive ici que si f se termine sans "fail"
	r=$?
	if [ $r = 0 -a $KEEP = non ]
	then $NETTOYER		# contexte du processus => accès aux variables
	fi
	# Le code de retour du processus shell est celui de f, qui est par
	# défaut le code de retour de la dernière commande exécutée par f
	exit $r
    ) &
    pidftest=$!

    # lancer le chien de garde (watchdog) en arrière plan
    (
	trap 'exit 127' $sig	# supprimer les affichages intempestifs
	sleep $maxdur
	kill -$sig $pidftest
	sleep 0.2		# attendre avant de sortir l'arme atomique
	if ps_existe $pidftest
	then
	    kill -KILL $pidftest	# arme atomique
	    fail "timeout de $maxdur secondes expiré"
	fi
    ) > /dev/null 2>&1 &
    pidsleep=$!

    # attendre la fin du test (et seulement le test)
    wait $pidftest
    exitcode=$?

    if [ "$exitcode" -ge 127 ]	# commande terminée par un signal ?
    then
	if ps_existe $pidsleep
	then
	    # la commande a été terminée par un signal autre que
	    # le nôtre, puisque sleep n'est pas terminé
	    kill -$sig $pidsleep >/dev/null 2>/dev/null
	    # note : après l'avoir terminé, on ne peut pas
	    # faire un wait car sur certaines plateformes,
	    # XXX
	    exitcode=130	# valeur arbitraire 130 (> 127)
	else
	    # la commande a été interrompue par notre signal et
	    # notre sleep est terminé
	    wait $pidsleep
	    exitcode=124	# cf man timeout sur Linux
	fi
    fi
    return $exitcode
}

# Appelle la fonction "f" dans le contexte d'un sous-shell pour exécuter
# le test indiqué. La fonction f retourne 0 si le test s'est bien passé
# ou une valeur != 0 s'il a échoué
# Cette fonction n'est normalement pas appelée directement, mais par
# "def_test" (annonce du test suivant) ou "fin" lorsque le script
# de test se termine
run_test ()
{
    [ $# != 0 ] && fatal "SYNTAXE run_test / $# = $*"

    local regexp="^$(echo "$CURTEST" | sed 's/\./\\./')$"

    # Faire ou ne pas faire (le test), telle est la question...
    if [ "$DO" = non ]
    then
	# Il ne faut pas exécuter le test. Alors, que faut-il faire ?
	if [ "$DUREE" = oui ]
	then DUREE_ESTIMEE=$((DUREE_ESTIMEE + DURTEST))
	fi

    elif [ $TESTS_TOUS = oui ] || echo "$TESTS_A_FAIRE" | grep -q "$regexp"
    then
	# ok, il faut faire le test. Le retirer des tests à faire
	TESTS_A_FAIRE="$(echo "$TESTS_A_FAIRE" | grep -v "$regexp")"

	# démarrer un test avec un espace vierge
	$NETTOYER			# fct "nettoyer", ou celle du script

	# Le test doit être exécuté
	if [ "$TERSE" = 0 ]
	then annoncer_test  "$CURTEST" "$TITTEST"
	fi

	execute_fonction "$CURTEST" "$DURTEST" "$VERBOSE"
	r=$?

	# Analyser le code de retour
	case $r in
	    (0)				# on a gagné !
		if [ -f "$TMP.fail" ]
		then fatal "Test ok, mais $TMP.fail existe !"
		fi

		if [ "$TERSE" = 0 ]
		then echo "OK"
		elif [ "$TERSE" = 1 ]
		then echo "success $CURTEST"
		else :				# rien du tout si >= 2
		fi

		# Calculer le nb de tests (non ignorés) réussis
		TOTTESTSOK=$((TOTTESTSOK+1))
		if ! test_ignore "$CURTEST"
		then NBTESTSOK=$((NBTESTSOK+1))
		fi
		;;
	    (120)			# sortie via "fatal"
		fatal "appel à 'fatal' dans le test"
		;;
	    (*)				# échec du test (erreur ou timeout)
		if [ ! -f "$TMP.fail" ]
		then fatal "Echec test $CURTEST, mais $TMP.fail absent !"
		fi

		# récupérer le message placé par "fail" dans $TMP.fail
		msgerr=$(cat "$TMP.fail")
		rm -f "$TMP.fail"

		if [ "$TERSE" = 0 ]
		then
		    echo "FAIL"
		    echo "Echec du test $CURTEST"

		    echo "$msgerr"
		    if ls -dp "$TMP"* > /dev/null 2>&1
		    then
			echo "Voir les fichiers suivants :"
			ls -dp "$TMP"* 2> /dev/null
		    fi
		elif [ "$TERSE" = 1 ]
		then echo "fail $CURTEST"
		else :				# rien du tout si >= 2
		fi
		FAILNUM="$CURTEST"
		DO=non
		;;
	esac
    fi
    CURTEST=""
}

# Le nettoyage façon karscher : il ne reste plus une trace des
# fichiers après...
# Chaque script de test peut créer sa propre fonction de nettoyage
# et mettre son nom dans la variable NETTOYER. Ainsi, chaque script
# peut faire des nettoyages complémentaires (terminer des processus
# par exemple), l'infrastructure de test appellera cette nouvelle
# fonction par l'intérmédiaire de la variable NETTOYER.
nettoyer ()
{
    rm -rf "$TMP".*
}

##############################################################################
# Tests à ignorer

# Les numéros des tests qui doivent être ignorés dans le calcul
# du score (car ces tests passent même si aucune modification n'est
# apportée aux programmes fournis) sont placés dans une variable
# TESTS0, initialisée à vide au début de ce fichier. Ces numéros
# sont ensuite rangés un par ligne, afin de faciliter l'exploitation.
# Si la compilation ne doit pas être comptabilisée dans le score (i.e.
# le fichier tel que fourni compile sans erreur), il faut ajouter "cc"
# dans les numéros de tests.
#

# $* = liste des tests (y.c. "cc") qui sont censés passer dans tous les cas
tests0 ()
{
    local i

    TESTS0=""
    for i
    do
	if [ -z "$TESTS0" ]
	then TESTS0="${i}"
	else TESTS0="${TESTS0}${NL}${i}"
	fi
    done
}

# Le numéro de test figure-t-il dans les tests à ignorer ?
test_ignore ()
{
    [ $# != 1 ] && fatal "SYNTAXE test_ignore / $# = $*"
    local num="$1"
    echo "$TESTS0" | grep -q "^$num$"
}

##############################################################################
# Fonctions souvent utilisées par les scripts de test

# Teste si le fichier est vide (ne fait que tester, pas d'erreur renvoyée)
est_vide ()
{
    [ $# != 1 ] && fatal "SYNTAXE est_vide / $# = $*"
    local fichier="$1"
    test $(wc -c < "$fichier") = 0		# 0 octet
}

# Vérifie que le résultat est envoyé sur la sortie standard
# et non sur la sortie d'erreur
verifier_stdout ()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_stdout / $# = $*"
    est_vide "$TMP.out" && fail "Le résultat devrait être sur stdout"
    est_vide "$TMP.err" || fail "Rien ne devrait être affiché sur stderr"
}

# Vérifie que le message d'erreur est envoyé sur la sortie d'erreur
# et non sur la sortie standard
verifier_stderr ()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_stderr / $# = $*"
    est_vide "$TMP.err" && fail "Le message d'erreur devrait être sur stderr"
    est_vide "$TMP.out" || fail "Rien ne devrait être affiché sur stdout"
}

# Vérifie qu'il y a un message d'erreur et qu'il indique la bonne syntaxe
verifier_usage ()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_usage / $# = $*"
    verifier_stderr
    grep -q "usage *: " "$TMP.err" \
	|| fail "Le message d'erreur devrait indiquer 'usage:...'"
}

# Vérifie que le programme sort en erreur
# $1 = message
# $2 et suivants : commande
verifier_erreur ()
{
    [ $# -lt 2 ] && fatal "SYNTAXE verifier_erreur / $# = $*"
    local msg="$1" prog="$2"
    shift 2
    $prog "$@" > "$TMP.out" 2> "$TMP.err" \
	&& fail "$msg${NL}'$prog $*' a renvoyé un code de retour nul"
    verifier_stderr		# le message devrait être sur stderr
}

# Vérifie les erreurs de nombre ou de qualité d'arguments
# $1 = message
# $2 et suivants : commande
verifier_args ()
{
    [ $# -lt 2 ] && fatal "SYNTAXE verifier_args / $# = $*"
    local msg="$1" prog="$2"
    shift 2
    verifier_erreur "$msg" $prog "$@" > "$TMP.out" 2> "$TMP.err"
    verifier_usage
}

# Récupère la durée en ms à partir de /usr/bin/time -p (POSIX)
# $1 = nom du fichier contenant le résultat de time -p
duree ()
{
    [ $# != 1 ] && fatal "SYNTAXE duree / $# = $*"
    local fichier="$1"
    local duree_s
    duree_s=$(sed -n 's/real *//p' "$fichier" | sed 's/,/\./')
    echo "$duree_s*1000" | bc | sed 's/\..*//'
}

# Vérifie que le temps d'exécution est dans l'intervalle indiqué
# $1 = durée mesurée en ms (résultat de la fonction duree)
# $2 = durée attendue min
# $3 = durée attendue max
verifier_duree ()
{
    [ $# != 3 ] && fatal "SYNTAXE verifer_duree / $# = $*"
    local duree_ms="$1" min="$2" max="$3"

    if [ "$duree_ms" -lt "$min" ] || [ "$duree_ms" -gt "$max" ]
    then fail "durée incorrecte ($duree_ms ms) pas dans [$min,$max]"
    fi
}

# Génère un fichier pseudo-aléatoire
# $1 = nom
# $2 = taille (en multiples de 4 kio)
generer_fichier_aleatoire ()
{
    [ $# != 2 ] && fatal "SYNTAXE generer_fichier_aleatoire / $# = $*"
    local nom="$1" taille="$2"
    local random=/dev/urandom

    if [ ! -c $random ]
    then fatal "Pas de driver '$random'. Arrêt"
    fi

    dd if=$random of="$nom" bs=4k count="$taille" 2> /dev/null
}

CMD_TIMEOUT=$(command -v timeout)
if [ -z "$CMD_TIMEOUT" ]
then
    # La commande timeout n'est pas POSIX, elle peut exister
    # sur certains systèmes (Linux, FreeBSD), mais pas sur d'autres
    # (ex : MacOS). Comme elle n'a pas été trouvée, il faut la simuler
    timeout ()
    {
	[ $# -le 1 ] && fatal "SYNTAXE timeout / $# = $*"
	local delai="$1" ; shift
	local pidcmd pidsleep exitcmd exitkill
	local sig=TERM

	# lancer la commande en arrière plan
	"$@" &
	pidcmd=$!

	# lancer le chien de garde (watchdog) en arrière plan
	(
	    trap 'exit 127' $sig	# supprimer les affichages intempestifs
	    sleep $delai
	    kill -$sig $pidcmd
	) > /dev/null 2>&1 &
	pidsleep=$!

	# attendre la commande (et seulement la commande)
	wait $pidcmd
	exitcmd=$?

	if [ "$exitcmd" -ge 127 ]	# commande terminée par un signal ?
	then
	    if ps_existe $pidsleep
	    then
		# la commande a été terminée par un signal autre que
		# le nôtre, puisque sleep n'est pas terminé
		kill -$sig $pidsleep >/dev/null 2>/dev/null
		# note : après l'avoir terminé, on ne peut pas
		# faire un wait car sur certaines plateformes,
		exitcmd=130		# valeur arbitraire 130 (> 127)
	    else
		# la commande a été interrompue par notre signal et
		# notre sleep est terminé
		wait $pidsleep
		exitcmd=124		# cf man timeout sur Linux
	    fi
	fi
	return $exitcmd
    }
fi

# Lance la commande indiquée en bornant la durée d'exécution.
# $1 = délai max en secondes
# $2 = code de retour attendu pour la commande : ok (= 0) ou nok (!= 0)
# $3 ... := commande et arguments
lancer_timeout ()
{
    [ $# -le 1 ] && fatal "SYNTAXE lancer_timeout / $# = $*"
    local delai="$1" att="$2" ; prog="$3" ; shift 3

    [ "$att" != ok -a "$att" != nok ] && fatal "ERREUR lancer_timeout ok/nok"

    local r
    timeout "$delai" "$prog" "$@" > "$TMP.out" 2> "$TMP.err"
    r=$?
    [ $r = 124 ] && fail "Timeout de $delai s dépassé pour $prog $*"
    [ $r != 0 -a $att = "ok" ] && fail "exit code = $r (!= 0) pour $*"
    [ $r = 0 -a $att = "nok" ] && fail "$prog $* aurait dû se terminer en erreur"
    return 0
}

# Teste si un processus existe
# $1 = pid
ps_existe ()
{
    [ $# != 1 ] && fatal "SYNTAXE ps_existe / $# = $*"

    local pid="$1"
    local r

    if kill -0 $pid 2> /dev/null
    then r=0
    else r=1
    fi
    return $r
}

# Lancer valgrind avec toutes les options
tester_valgrind ()
{
    local stdin_file=""
    local r

    if [ "$1" = "--stdin" ]; then
        stdin_file=$2
        shift 2
    fi

    if [ -n "$stdin_file" ]; then
	valgrind \
	    --leak-check=full \
	    --errors-for-leak-kinds=all \
	    --show-leak-kinds=all \
	    --error-exitcode=100 \
	    --log-file="$TMP.valgrind" \
	    "$@" > "$TMP.out" 2> "$TMP.err" < "$stdin_file"
    else
	valgrind \
	    --leak-check=full \
	    --errors-for-leak-kinds=all \
	    --show-leak-kinds=all \
	    --error-exitcode=100 \
	    --log-file="$TMP.valgrind" \
	    "$@" > "$TMP.out" 2> "$TMP.err"
    fi

    r=$?
    if [ $r = 100 ]
    then fail "pb mémoire (cf $TMP.valgrind)"
    elif [ $r != 0 ]
    then fail "erreur programme (code=$r) avec valgrind"
    fi
    return $r
}

##############################################################################
# Fonctions spécialisées pour les exercices Zorglub33

# Chercher un exécutable z33-cli quelque part dans les commandes ou
# dans le répertoire courant ou les répertoires parents
# Cette fonction n'est pas appelée par les scripts mais lors
# de l'initialisation (dans ce fichier)
# $1 = contenu de la variable Z33 (nom de l'exécutable ou chemin)
z33_find ()
{
    [ $# != 1 ] && fatal "SYNTAXE z33_find / $# = $*"
    local z33="$1"

    local exe dir

    if echo "$z33" | grep -q /
    then
	# il y a un "/" dans la variable Z33 : on essaye donc de trouver
	# ce chemin tel quel
	exe="$z33"
	if [ ! -x "$exe" ]
	then fail "Exécutable '$exe' non trouvé (ou non exécutable)"
	fi
    else
	# pas de / dans la variable Z33 : ce doit donc être le nom d'une
	# commande, ou alors le nom d'un fichier 
	exe=$(command -v "$z33")
	if [ -z "$exe" ]
	then
	    # ce n'est pas une commande : rechercher l'exécutable
	    # dans le répertoire courant ou les répertoires parents
	    dir="$PWD"
	    while [ "$dir" != "" ]
	    do
		exe="$dir/$z33"
		if [ -x "$exe" ]
		then break
		else dir=$(echo "$dir" | sed 's:/[^/]*$::')
		fi
	    done
	    if [ "$dir" = "" ]
	    then
		fatal "Exécutable '$exe' non trouvé (PATH ou répertoires parents)"
	    fi
	fi
    fi
    Z33EXE="$exe"
}

# Vérifier la version minimale de z33-cli
# Cette fonction n'est pas appelée par les scripts mais lors
# de l'initialisation (dans ce fichier)
# $1 : chemin de l'exécutable z33-cli
z33_check_version ()
{
    local v1 v2 v3
    local vmin="0 8 4" m1 m2 m3

    set $vmin
    m1=$1 ; m2=$2 ; m3=$3
    set $("$Z33EXE" -V | sed -e 's/.* //' -e 's/\./ /g')
    v1=$1 ; v2=$2 ; v3=$3
    if [ "$v1" -lt $m1 ]
    then fatal "Version $Z33EXE = $v1.*.* insuffisante, min=$m1.$m2.$m3"
    elif [ "$v2" -lt $m2 ]
    then fatal "Version $Z33EXE = $v1.$v2.* insuffisante, min=$m1.$m2.$m3"
    elif [ "$v3" -lt $m3 ]
    then fatal "Version $Z33EXE = $v1.$v2.$v3 insuffisante, min=$m1.$m2.$m3"
    fi
}

# Chercher un label dans le fichier
# $1 = label à chercher
z33_chercher_label ()
{
    [ $# != 1 ] && fatal "SYNTAXE chercher_label / $# = $*"
    local label="$1"
    grep -q "^$label[ 	]*:" "$PROG" || fail "Label '$label' non trouvé"
}

# Chercher un reset dans le programme assembleur
z33_chercher_reset ()
{
    [ $# != 0 ] && fatal "SYNTAXE chercher_reset / $# = $*"
    grep -q "^[ 	]*reset" "$PROG" || fail "Instruction 'reset' non trouvée"
}

# Lancer l'émulateur sur le point d'entrée
# $* = instructions (au moins une)
z33_run ()
{
    [ $# = 0 ] && fatal "SYNTAXE z33_run / $# = $*"

    local z33timeout=2			# secondes
    local r
    (
	cat "$PROG"
	echo
	echo "// ce qui suit est ajouté par le script de test"
        echo "// '_' : pour éviter des conflits avec les labels existants"
        echo "_test:"
	for i
	do
	    echo "$i" | sed 's/.*[^:]$/	&/'	# bien indenter les labels
	done
    ) > "$TMP.s"
    timeout $z33timeout "$Z33EXE" run "$TMP.s" "_test" \
	    > "$TMP.out" 2> "$TMP.err"
    r=$?
    [ $r = 124 ] && fail "Timeout de $z33timeout s dépassé"
    [ $r != 0 ] && fail "erreur de z33-cli => cf $TMP.s, $TMP.out et $TMP.err"
    return $r
}

# Vérifier le résultat de l'exécution
# $1 = registre
# $2 = valeur
# $3 = msg d'erreur
z33_check ()
{
    [ $# != 3 ] && fatal "SYNTAXE z33_check / $# = $*"
    local reg="$1" val="$2" msg="$3"
    local v

    v=$(sed -n "/End of program/s/.*%$reg = \([^ ]*\) .*/\1/p" "$TMP.out")
    [ x"$v" = x"$val" ] || fail "$msg, valeur trouvée = $v (attendue = $val) pour registre %$reg${NL}  => regarder $TMP.s et $TMP.out"
}

##############################################################################
# Fonctions appelées systématiquement au début du script

# Chercher la commande "time" POSIX et la mettre dans la variable TIME
commande_time ()
{
    TIME=$(command -v time)
    if [ -z "$TIME" ]
    then fatal "Commande 'time' non trouvée"
    fi
}

# Vérifier l'existence des programmes cités dans les variables PROG*
# et pour le cas des sources en assembleur (fichiers avec le suffixe ".s"),
# teste l'existence de l'émulateur Zorglub33 (z33-cli) dont le chemin
# doit figurer dans la variable Z33 ou alors dans PATH ou dans les
# répertoires parents
verifier_prog ()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_prog / $# = $*"
    local listevars v prog z33

    if [ "$DO" = non ]		# cas spécial pour l'option -d par exemple
    then return 0
    fi

    listevars=$(set | sed -n 's/^\(PROG[^=]*\)=.*/\1/p')
    z33=non
    for v in $listevars
    do
	prog=$(eval echo \$$v)
	case x"$prog" in
	    (*.s)
		z33=oui
		if [ ! -f "$prog" ]
		then
		    failcc "Fichier '$prog' (variable $v) non trouvé"
		    return
		fi
		;;
	    (*)
		if [ ! -x "$prog" ]
		then
		    failcc "Exécutable '$prog' (variable $v) non trouvé"
		    return
		fi
		;;
	esac
    done
    if [ $z33 = oui ]
    then
	z33_find "$Z33"			# trouve Z33EXE utilisé par la suite
	z33_check_version
	PROGCOMPILE=non			# ne pas compter la compil dans le score
    else
	PROGCOMPILE=oui			# compter la compilation dans le score
    fi
}

##############################################################################
# Actions effectuées pour tous les tests, lors du chargement de ce fichier


# Vérifier l'existence des programmes indiqués dans les variables "PROG*"
verifier_prog

# Chercher la commande "time"
commande_time

# Préparer l'action à réaliser automatiquement à la fin du script de test
trap "fin ; exit 0" EXIT
