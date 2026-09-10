#include "common.h"

void quit(int signo)
{
    (void)signo;
    exit(EXIT_SUCCESS);
}

int main(void)
{
    /* quitte correctement le programme si SIGTERM */
    struct sigaction sa;
    sa.sa_handler = quit;
    sa.sa_flags = 0;
    CHK(sigemptyset(&sa.sa_mask));
    CHK(sigaction(SIGTERM, &sa, NULL));

    /* récupération des paramètres réseaux */
    char *local_port_str = getenv("RECEIV_PORT");
    if (local_port_str == NULL) {
        fprintf(stderr, "Erreur : variable d'environnement RECEIV_PORT non définie\n");
        exit(EXIT_FAILURE);
    }

    /* TODO à compléter */

    return 0;
}
