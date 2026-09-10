#!/bin/sh

PROG=${PROG:=./ureceiver}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 2.1

# numéro d'utilisateur courant
MUID=`id -u`

# port de communication
PORT=`expr 1024 + \( $MUID % 64511 \)`

# vérifie que la sortie du programme est correcte
verifier_sortie ()
{
    [ $# != 0 ] && fatal "SYNTAXE verifier_sortie / $# = $@"

    verifier_stdout

    cmp "$TMP.in" "$TMP.out" > "$TMP.diff" || fail "données reçues ≠ données envoyées"
}

##############################################################################
# test fonctionnement du programme

def_test 1.1 "réception message" 10
f () {
    # Génère un entier 0‑32767 à partir de /dev/urandom
    local rand=$(od -An -N2 -tu2 < /dev/urandom | tr -d ' ')
    local port_nc=$(( ( $rand % 64512 ) + 1024 ))
    local pid

    $PROG "$PORT" 5 > "$TMP.out" 2> "$TMP.err" || fail "code retour du programme invalide" &
    pid=$!
    sleep 1
    printf "127.0.0.1 $port_nc a envoyé : hello world\n" > "$TMP.in"
    printf "hello world" | nc -4u -w1 127.0.0.1 "$PORT" -p "$port_nc"
    wait "$pid"

    verifier_sortie
}

##############################################################################
# tests arguments erronés

def_test 2.1 "numéro de port invalide"
f () {
    verifier_erreur "port < 0" $PROG -1 1
    verifier_erreur "port > 65535" $PROG 65537 1
}


##############################################################################
# test mémoire

def_test 3.1 "valgrind" 5
f () {
    (
      sleep 2
      echo "message test" | nc -4u -w1 127.0.0.1 "$PORT"
    ) &
      
    tester_valgrind $PROG "$PORT" 2
}
