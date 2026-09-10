#!/bin/sh

PROGS=${PROGS:=./sw-sender}
PROGR=${PROGR:=./sw-receiver}

# numéro d'utilisateur courant
MUID=`id -u`

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 2.1 3.1

# port du récepteur
RECEIV_PORT=`expr 1024 + \( $MUID % 64511 \)`
export RECEIV_PORT

# verifier que la sortie de sw-* sont correctes
verifier_sortie()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_stdout / $# = $@"
    est_vide "$TMP.sender.err"   || fail "Rien ne devrait être affiché sur stderr (émetteur)"
    est_vide "$TMP.receiver.err" || fail "Rien ne devrait être affiché sur stderr (récepteur)"
    est_vide "$TMP.receiver.out" && fail "Aucune donnée reçue par le récepteur"

    cmp "$TMP.in" "$TMP.receiver.out" > "$TMP.diff" || fail "données reçues ≠ données envoyées"
}

#####################################################################
# test fonctionnement des programmes

def_test 1.1 "fiabilité de la transmission" 20
f() {
    local pid

    generer_fichier_aleatoire "$TMP.in" 1

    $PROGR 2 > "$TMP.receiver.out" 2> "$TMP.receiver.err" &
    pid=$!
    sleep 1
    $PROGS < "$TMP.in" > "$TMP.sender.out" 2> "$TMP.sender.err"
    wait $pid

    verifier_sortie
}

#####################################################################
# test adr + port déjà utilisés

def_test 2.1 "adresse déjà utilisée" 10
f () {
    local pid
    
    timeout 4 nc -6ul ::1 $RECEIV_PORT > /dev/null 2>&1 &
    pid=$!

    sleep 2

    verifier_erreur "adresse déjà utilisée" $PROGR 1

    wait $pid
    :
}

#####################################################################
# tests mémoire

def_test 3.1 "valgrind « émetteur »" 30
f () {
    if [ "$(uname)" = "Darwin" ]; then
	echo "ABORT\nvalgrind non disponible sous OSX"
	exit 0
    fi

    local pid

    generer_fichier_aleatoire "$TMP.in" 1

    $PROGR 2 > /dev/null 2>&1 &
    pid=$!

    tester_valgrind --stdin "$TMP.in" $PROGS

    wait $pid
    :
}

def_test 3.2 "valgrind « récepteur »" 30
f () {
    if [ "$(uname)" = "Darwin" ]; then
	echo "ABORT\nvalgrind non disponible sous OSX"
	exit 0
    fi

    generer_fichier_aleatoire "$TMP.in" 1

    (
      sleep 2
      $PROGS < "$TMP.in"
    ) &
      
    tester_valgrind $PROGR 2
}
