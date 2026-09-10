#!/bin/sh

PROGS=${PROGS:=./abp-sender}
PROGR=${PROGR:=./abp-receiver}
PROGM=${PROGM:=./medium}

# numéro d'utilisateur courant
MUID=`id -u`

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 3.1

# port de communication
RECEIV_PORT=`expr 1024 + \( $MUID % 64511 \)`
MEDIUM_PORT=`expr $RECEIV_PORT + 1`
export RECEIV_PORT
export MEDIUM_PORT

# verifier que les sorties de abp-* sont correctes
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

def_test 1.1 "transmission sans erreur" 20
f() {
    local pidr pidm

    $PROGR > "$TMP.receiver.out" 2> "$TMP.receiver.err" &
    pidr=$!
    $PROGM 0 > "$TMP.medium.out" 2> "$TMP.medium.err" &
    pidm=$!

    generer_fichier_aleatoire "$TMP.in" 1
    $PROGS < "$TMP.in" > "$TMP.sender.out" 2> "$TMP.sender.err"
    kill $pidm $pidr 2> /dev/null
    wait $pidm $pidr

    verifier_sortie
}

def_test 1.2 "transmission avec erreur" 30
f() {
    local pidr pidm

    $PROGR > "$TMP.receiver.out" 2> "$TMP.receiver.err" &
    pidr=$!
    $PROGM 0.3 > "$TMP.medium.out" 2> "$TMP.medium.err" &
    pidm=$!

    generer_fichier_aleatoire "$TMP.in" 1
    $PROGS < "$TMP.in" > "$TMP.sender.out" 2> "$TMP.sender.err"
    kill $pidm $pidr 2> /dev/null
    wait $pidm $pidr

    verifier_sortie
}

#####################################################################
# test adr + port déjà utilisés

def_test 2.1 "adresse déjà utilisée" 10
f () {
    local pid
    
    timeout 4 nc -6ul ::1 $RECEIV_PORT > /dev/null &
    pid=$!

    sleep 2

    verifier_erreur "adresse déjà utilisée" $PROGR
    wait $pid

    :
}

#####################################################################
# tests mémoire

def_test 3.1 "valgrind « émetteur »" 30
f () {
    local pidr pidm

    $PROGR > /dev/null 2>&1 &
    pidr=$!
    $PROGM 0.2 > /dev/null 2>&1 &
    pidm=$!

    generer_fichier_aleatoire "$TMP.in" 1
    tester_valgrind --stdin "$TMP.in" $PROGS

    kill $pidr $pidm 2> /dev/null
    wait $pidr $pidm
    :
}

def_test 3.2 "valgrind « récepteur »" 30
f () {
    local pids pidm pidr

    $PROGM 0.2 > /dev/null 2>&1 &
    pidm=$!

    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file="$TMP.valgrind" \
	$PROGR > /dev/null 2>&1 &
    pidr=$!

    generer_fichier_aleatoire "$TMP.in" 1
    $PROGS < "$TMP.in" > /dev/null 2>&1

    kill $pidm $pidr 2> /dev/null
    wait $pidr
    r=$?
    [ $r = 100 ] && fail "pb mémoire (cf $TMP.valgrind_r)"
    [ $r != 0 ]  && fail "erreur programme (code=$r) avec valgrind (cf $TMP.*)"

    :
}
