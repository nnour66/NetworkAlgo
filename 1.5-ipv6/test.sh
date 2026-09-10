#!/bin/sh

PROGR=${PROGR:=./ureceiver6}			# chemin de l'exécutable réception
PROGS=${PROGS:=./usender6}			# chemin de l'exécutable émission

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 2.1 3.1

# numéro d'utilisateur courant
MUID=`id -u`

# port de communication
PORT=`expr 1024 + \( $MUID % 64511 \)`

comparer()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE comparer"
    local s1="$1" s2="$2"

    cmp "$s1" "$s2" > "$TMP.diff" || fail "données reçues ≠ données envoyées"
}

##############################################################################
# tests fonctionnement des programmes

def_test 1.1 "émission" 10
f () {
    local pid

    timeout 4 nc -6ul ::1 "$PORT" > "$TMP.msg_r" &
    pid=$!
    sleep 1

    $PROGS "$PORT" > "$TMP.out" 2> "$TMP.err" || fail "code retour du programme invalide"
    wait $pid
    
    est_vide $TMP.err   || fail "la sortie erreur doit être vide"
    est_vide $TMP.out   || fail "la sortie standard doit être vide"    
    est_vide $TMP.msg_r && fail "aucune donnée reçue"

    printf "hello world" > "$TMP.in"
    comparer "$TMP.in" "$TMP.msg_r"
}

def_test 1.2 "réception" 10
f () {
    # Génère un entier 0‑32767 à partir de /dev/urandom
    local rand=$(od -An -N2 -tu2 < /dev/urandom | tr -d ' ')
    local port_nc=$(( ( $rand % 64512 ) + 1024 ))
    local pid

    $PROGR "$PORT" 5 > "$TMP.out" 2> "$TMP.err" || fail "code retour du programme invalide" &
    pid=$!
    sleep 1
    printf "hello world" | nc -6u -w1 ::1 "$PORT" -p "$port_nc"
    wait "$pid"

    verifier_stdout
    
    printf "::1 $port_nc a envoyé : hello world\n" > "$TMP.in"
    comparer "$TMP.in" "$TMP.out"
}

##############################################################################
# test arguments erronés

def_test 2.1 "numéro de port invalide"
f () {
    verifier_erreur "port < 0" $PROGS -1 1
    verifier_erreur "port > 65535" $PROGS 65537 1
    verifier_erreur "port < 0" $PROGR -1 1
    verifier_erreur "port > 65535" $PROGR 65537 1
}

##############################################################################
# tests mémoire

def_test 3.1 "valgrind « émission »"
f () {
    tester_valgrind $PROGS "$PORT"
}

def_test 3.2 "valgrind « réception »" 5
f () {
    (
      sleep 2
      echo "message test" | nc -6u -w1 ::1 "$PORT"
    ) &
      
    tester_valgrind $PROGR "$PORT" 2
}
