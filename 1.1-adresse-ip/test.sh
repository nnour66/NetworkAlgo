#!/bin/sh

PROG=${PROG:=./conv}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# tel que fourni initialement, cet exercice passe les tests suivants :
tests0 cc 3.1

# teste une adresse
# $1 = addr
# $2 = valeur attendue
tester_adresse ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE tester_adresse"
    local a="$1" att="$2"

    $PROG "$a" > "$TMP.out" 2> "$TMP.err" || fail "échec $a"
    verifier_stdout
    printf "$att" | diff - "$TMP.out" || fail "résultat != attendu pour '$a'"
    return 0
}

##############################################################################
# test fonctionnement du programme

def_test 1.1 "conversion adresse"
f () {
    tester_adresse 0.0.0.0 "petit-boutiste : octet[0] = 0x00 | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x00 | \ngros-boutiste :  octet[0] = 0x00 | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x00 | \n"
    tester_adresse 127.0.0.1 "petit-boutiste : octet[0] = 0x01 | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x7F | \ngros-boutiste :  octet[0] = 0x7F | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x01 | \n"
    tester_adresse 130.79.200.2 "petit-boutiste : octet[0] = 0x02 | octet[1] = 0xC8 | octet[2] = 0x4F | octet[3] = 0x82 | \ngros-boutiste :  octet[0] = 0x82 | octet[1] = 0x4F | octet[2] = 0xC8 | octet[3] = 0x02 | \n"
}

##############################################################################
# test valeurs invalides

def_test 2.1 "adresse mal formée"
f () {
    verifier_erreur "adresse trop courte" $PROG 127
    verifier_erreur "adresse trop longue" $PROG 130.79.90.1.2
    verifier_erreur "octet > 255"         $PROG 666.666.666.666
    verifier_erreur "octet < 0"           $PROG 3.-1.2.1
    verifier_erreur "mauvais délimiteur"  $PROG 127,0,0,1
}

##############################################################################
# test mémoire

def_test 3.1 "valgrind"
f () {
    nettoyer
    tester_valgrind $PROG 127.0.0.1
}
