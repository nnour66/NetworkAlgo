#include "common.h"

int main(void)
{
    /* récupération des paramètres réseaux */ 
    char *medium_port_str = getenv("MEDIUM_PORT");
    if (medium_port_str == NULL) {
        fprintf(stderr, "Erreur : variable d'environnement MEDIUM_PORT non définie\n");
        exit(EXIT_FAILURE);
    }
  
    /* TODO à compléter */

    return 0;
}
