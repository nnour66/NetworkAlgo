#!/bin/sh

PROG=${PROG:=./usender}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 3.1

# numéro d'utilisateur courant
MUID=`id -u`

# Port de communication
PORT=`expr 1024 + \( $MUID % 64511 \)`

# vérifie que la sortie du programme est correcte
verifier_sortie ()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_sortie / $# = $@"

    est_vide "$TMP.out" || fail "Rien ne devrait être affiché sur stdout"
    est_vide "$TMP.err" || fail "Rien ne devrait être affiché sur stderr"

    printf "hello world" > "$TMP.in"
    cmp "$TMP.in" "$TMP.msg_r" > "$TMP.diff" || fail "données reçues ≠ données envoyées"
}

##############################################################################
# test fonctionnement du programme

def_test 1.1 "envoi message" 5
f () {
    timeout 3 nc -4ul 127.0.0.1 "$PORT" > "$TMP.msg_r" &
    pid=$!
    sleep 1
    $PROG 127.0.0.1 "$PORT" 0 > "$TMP.out" 2> "$TMP.err" || fail "code retour du programme invalide"

    wait $pid

    verifier_sortie
}

##############################################################################
# test arguments erronés

def_test 2.1 "numéro de port invalide"
f () {
    verifier_erreur "port < 0" $PROG 127.0.0.1 -1 0
    verifier_erreur "port > 65535" $PROG 127.0.0.1 65537 0
}


##############################################################################
# test mémoire

def_test 3.1 "valgrind"
f () {
    tester_valgrind $PROG 127.0.0.1 "$PORT" 0
}
