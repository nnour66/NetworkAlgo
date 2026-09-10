#include "common.h"

noreturn void usage(const char *msg)
{
    fprintf(stderr, "usage: %s <duration>\n", msg);
    exit(EXIT_FAILURE);
}

void process_data(void)
{
    sleep(1 + rand() % 3);
    return;
}


int main(int argc, char *argv[])
{
    if (argc != 2)
        usage(argv[0]);

    /* initialisation du générateur pseudo-aléatoire */
    srand(time(NULL));

    char *local_port_str = getenv("RECEIV_PORT");
    if (local_port_str == NULL) {
        fprintf(stderr, "Erreur : variable d'environnement RECEIV_PORT non définie\n");
        exit(EXIT_FAILURE);
    }

    int timeout;
    if (sscanf(argv[1], "%d", &timeout) != 1 || timeout < 1) {
        fprintf(stderr, "erreur : valeur du temporisateur doit être supérieure à 0");
        exit(EXIT_FAILURE);
    }

    /* création d'un socket IPv6 / UDP */
    int sockfd = 0;

    /* ajout d'un timer sur la non réception sur le socket - à ne pas toucher */
    struct timeval tv = {timeout, 0};
    CHK(setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv));

    /* TODO à compléter */

    return 0;
}
