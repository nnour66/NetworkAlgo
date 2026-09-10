#!/bin/sh

PROG=${PROG:=./usocket}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 3.1

# numéro d'utilisateur courant
MUID=`id -u`

# port de communication
PORT=`expr 1024 + \( $MUID % 64511 \)`

# teste si un socket est ouvert sur le système
# $1 = port
# $2 = durée attente
tester_socket ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE tester_socket"
    local port="$1" t="$2"

    $PROG "$port" "$t" > "$TMP.out" 2> "$TMP.err" & 
    local pid=$!

    # Attendre que le socket apparaisse (si nécessaire)
    sleep 0.1

    ss -uapn | grep "usocket" | grep "$port" > /dev/null || fail "socket non visible"

    wait $pid 2> /dev/null
    local code=$?

    [ $code -ne 0 ] && fail "échec programme terminé avec le code $code"

    return 0
}

##############################################################################
# test fonctionnement du programme

def_test 1.1 "socket avec port valide" 5
f () {
    # Génère un entier 0‑32767 à partir de /dev/urandom
    local rand=$(od -An -N2 -tu2 < /dev/urandom | tr -d ' ')
    local rport=$(( ( $rand % 64512 ) + 1024 ))
    
    tester_socket "$PORT"  1
    tester_socket "$rport" 1
    tester_socket 0 1
}

##############################################################################
# test valeurs invalides

def_test 2.1 "numéro de port réservé"
f () {
    verifier_erreur "port < 1024" $PROG 123 1
    verifier_erreur "port < 1024" $PROG 443 1
    verifier_erreur "port < 1024" $PROG 1023 1
}

##############################################################################
# test mémoire

def_test 3.1 "valgrind" 5
f () {
    tester_valgrind $PROG "$PORT" 1
}
