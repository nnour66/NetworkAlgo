#include "common.h"
#include <poll.h>

#define BIGBUF (2 * BUFSIZE)

noreturn void usage(const char *msg)
{
    fprintf(stderr, "usage: %s <taux_de_perte>\n", msg);
    exit(EXIT_FAILURE);
}

void perte(double error, int sockfd, char *buffer, ssize_t n, struct sockaddr_in6 sin6)
{
    double r = (double)rand() / RAND_MAX;
    if (r > error) {
        CHK(sendto(sockfd, buffer, n, 0, (struct sockaddr*)&sin6, sizeof sin6));
        printf("transmis\n");
    } else {
        printf("perte\n");
    }
    fflush(stdout);
}

void main_loop(double error, int sock_send, int sock_recv, struct sockaddr_in6 sin6_recv)
{
    /* deux sockets entrantes : E et R */
    struct pollfd pfds[2];
    pfds[0].fd = sock_send;
    pfds[0].events = POLLIN;
    pfds[1].fd = sock_recv;
    pfds[1].events = POLLIN;

    ssize_t n;
    char buffer[BIGBUF];

    struct sockaddr_in6 sin6_send = {0};
    socklen_t addrlen = sizeof sin6_send;

    while (1) {
        /* attente de données sur l'un des deux sockets */
        CHK(poll(pfds, 2, -1));

        /* données de l'émetteur */
        if (pfds[0].revents & POLLIN) {
            CHK(n = recvfrom(sock_send, buffer, BIGBUF, 0, (struct sockaddr *)&sin6_send, &addrlen));
            if (n > 0) {
                printf("E->R, seq=%d -> ", buffer[0]);
                perte(error, sock_recv, buffer, n, sin6_recv);
            }
        }

        /* données du récepteur (contrôle) */
        if (pfds[1].revents & POLLIN) {
            CHK(n = recvfrom(sock_recv, buffer, BIGBUF, 0, NULL, NULL));
            printf("R->E, seq=%d -> ", buffer[0]);
            perte(error, sock_send, buffer, n, sin6_send);
        }
    }
}

void quit(int signo)
{
    (void)signo;
    exit(EXIT_SUCCESS);
}

int main(int argc, char *argv[])
{
    if (argc != 2)
        usage(argv[0]);

    /* init générateur pseudo aléatoire */
    srand(time(NULL));

    /* quitte correctement le programme si SIGTERM */
    struct sigaction sa;
    sa.sa_handler = quit;
    sa.sa_flags = 0;
    CHK(sigemptyset(&sa.sa_mask));
    CHK(sigaction(SIGTERM, &sa, NULL));

    /* taux de pertes */
    double erreur;
    if (sscanf(argv[1], "%lf", &erreur) != 1 || erreur > 1.0 || erreur < 0.0) {
        fprintf(stderr, "usage : le taux d'erreur doit être compris dans l'intervalle [0,1]\n");
        exit(EXIT_FAILURE);
    }

    /* récupération des paramètres réseaux */
    char *receiv_port_str = getenv("RECEIV_PORT");
    char *local_port_str  = getenv("MEDIUM_PORT");
    if (receiv_port_str == NULL || local_port_str == NULL) {
        fprintf(stderr, "Erreur : variables d'environnement XXX_PORT non définies\n");
        exit(EXIT_FAILURE);
    }

    uint16_t receiv_port = conversion(receiv_port_str),
      local_port = conversion(local_port_str);

    /* création des sockets */
    int sock_local, sock_recv;
    CHK(sock_local = socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP));
    CHK(sock_recv  = socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP));

    /* adresse locale */
    struct sockaddr_in6 s6 = {
        .sin6_family = AF_INET6,
        .sin6_port   = htons(local_port),
        .sin6_addr   = in6addr_loopback
    };
    CHK(bind(sock_local, (struct sockaddr *)&s6, sizeof s6));

    /* adresse du récepteur */
    s6.sin6_port = htons(receiv_port);

    /* attente des messages */
    main_loop(erreur, sock_local, sock_recv, s6);

    /* fermeture des sockets */
    CHK(close(sock_local));
    CHK(close(sock_recv));

    return 0;
}
