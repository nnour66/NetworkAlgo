#!/bin/sh

PROGS=${PROGS:=./server}			# chemin des exécutables
PROGC=${PROGC:=./client}

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 4.1 4.2

# numéro d'utilisateur courant
UID=`id -u`

# port de communication
PORT=`expr 1024 + \( $UID % 64511 \)`

# compare le contenu de deux fichiers
# $1 : le fichier source
# $2 : le fichier destination
comparer()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE comparer"
    local s1="$1" s2="$2"

    cmp "$s1" "$s2" > "$TMP.diff" || fail "données reçues ≠ données envoyées"
}


# verifier que la sortie des programmes est correcte
# $1 : le code de retour du serveur
verifier_sortie()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local s1="$1"

    [ $s1 = 124 ]      && fail "timeout de 10 sec dépassé sur server"
    [ $s1 != 0 ]       && fail "code de retour du server invalide"

    est_vide $TMP.server.err  || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.server.out  && fail "aucune donnée reçue par le serveur"
    est_vide $TMP.client.out  && fail "aucune donnée reçue sur le client"

    # vérifier ce qu'à reçu le serveur
    printf "hello worldhello world" > "$TMP.in1"
    comparer "$TMP.in1" "$TMP.server.out"

    # vérifier ce qu'à reçu le client
    printf "hello world" > "$TMP.in2"
    comparer "$TMP.in2" "$TMP.client.out"
}

##############################################################################
# test fonctionnement des programmes

def_test 1.1 "diffusion message" 10
f () {
    local r msg pid1 pid2

    # serveur
    $PROGS "$PORT" > "$TMP.server.out" 2> "$TMP.server.err" &
    pid1=$!
    sleep 1

    # crée un tube nommé puis l'ouvre en R/W
    # ferme le côté W après 5 sec.
    mkfifo "$TMP.input"
    (
	exec 3<> "$TMP.input"
	sleep 5
	exec 3>&-
    ) &

    # client 1 en attente
    $PROGC 127.0.0.1 "$PORT" < "$TMP.input" > "$TMP.client.out" 2> "$TMP.client.err" &
    pid2=$!
    sleep 1

    # client 2
    printf "hello world" | nc -w1 -6 ::1 "$PORT"
    sleep 1

    # débloque client 1
    printf "hello world" > "$TMP.input"
    sleep 1

    wait $pid2 ; wait $pid1

    verifier_sortie $?
}

##############################################################################
# test limite nombre de clients

def_test 2.1 "limite nombre de clients" 10
f () {
    local pid1 pid2 pid3

    $PROGS "$PORT" > /dev/null 2> "$TMP.server.err" &
    pid1=$!
    sleep 1

    # crée un tube nommé puis l'ouvre en R/W
    # ferme le côté W après 5 sec.
    mkfifo "$TMP.input"
    (
	exec 3<> "$TMP.input"
	sleep 5
	exec 3>&-
    ) &

    # 2 clients en attente
    $PROGC ::1 "$PORT"       < "$TMP.input" > /dev/null 2>&1 &
    pid2=$!
    sleep 1
    $PROGC 127.0.0.1 "$PORT" < "$TMP.input" > /dev/null 2>&1 &
    pid3=$!
    sleep 1

    # 3e client
    $PROGC ::1 "$PORT"       < "$TMP.input" > "$TMP.out" 2> "$TMP.err"
    r=$?

    wait $pid1 $pid2 $pid3

    [ $r != 1 ] && fail "client doit se terminer en erreur"

    verifier_stderr
}

##############################################################################
# test arguments erronés

def_test 3.1 "arguments invalides"
f () {
    verifier_erreur "server port < 0"     $PROGS -1
    verifier_erreur "server port > 65535" $PROGS 65537
    verifier_erreur "client adr < -1"     $PROGC -1 "$PORT"
    verifier_erreur "client port < 0"     $PROGC ::1 -1
}


##############################################################################
# test mémoire

def_test 4.1 "valgrind « client »" 6
f () {
    printf "message test" > "$TMP.in"
    timeout 3 nc -6l ::1 "$PORT" > /dev/null &
    sleep 1
    tester_valgrind --stdin "$TMP.in" $PROGC ::1 "$PORT"
}

def_test 4.2 "valgrind « serveur »" 6
f () {
    (
      sleep 2
      printf "message test" | nc -6 -w1 ::1 "$PORT" 
    ) &
      
    tester_valgrind $PROGS "$PORT"
}
