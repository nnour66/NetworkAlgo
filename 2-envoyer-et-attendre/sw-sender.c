#include "common.h"


int main(void)
{
    char *receiv_port_str = getenv("RECEIV_PORT");
    if (receiv_port_str == NULL) {
        fprintf(stderr, "Erreur : variable d'environnement RECEIV_PORT non définie\n");
        exit(EXIT_FAILURE);
    }

    /* TODO à compléter */

    return 0;
}
