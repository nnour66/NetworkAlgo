#!/bin/sh

PROG=${PROG:=./client}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 3.1

# numéro d'utilisateur courant
UID=`id -u`

# port de communication
PORT=`expr 1024 + \( $UID % 64511 \)`

# verifier que la sortie de gbn-receiver est correcte
verifier_sortie()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_sortie / $# = $@"
    est_vide "$TMP.out" || fail "Rien ne devrait être affiché sur stdout"
    est_vide "$TMP.err" || fail "Rien ne devrait être affiché sur stderr"
    est_vide $TMP.msg_r && fail "aucune donnée reçue"
    printf "hello world" > "$TMP.in"
    cmp "$TMP.in" "$TMP.msg_r" > "$TMP.diff" || fail "données reçues ≠ données envoyées"
}

##############################################################################
# tests fonctionnement du programme

def_test 1.1 "envoi message IPv4" 6
f () {
    timeout 4 nc -4l 127.0.0.1 "$PORT" > "$TMP.msg_r" &
    pid=$!
    sleep 1
    $PROG 127.0.0.1 "$PORT" > "$TMP.out" 2> "$TMP.err" || fail "code retour du programme invalide"
    wait $pid

    verifier_sortie
}

def_test 1.2 "envoi message IPv6" 6
f () {
    timeout 4 nc -6l ::1 "$PORT" > "$TMP.msg_r" &
    pid=$!
    sleep 1
    $PROG ::1 "$PORT" > "$TMP.out" 2> "$TMP.err" || fail "code retour du programme invalide"
    wait $pid

    verifier_sortie
}

##############################################################################
# test arguments erronés

def_test 2.1 "numéro de port invalide"
f () {
    verifier_erreur "port < 0" $PROG 127.0.0.1 -1
    verifier_erreur "port > 65535" $PROG 127.0.0.1 65537
}

##############################################################################
# test mémoire

def_test 3.1 "valgrind" 6
f () {
    timeout 4 nc -4l 127.0.0.1 "$PORT" > /dev/null &
    pid=$!
    sleep 1

    tester_valgrind $PROG 127.0.0.1 "$PORT"
    
    wait $pid
    :
}
