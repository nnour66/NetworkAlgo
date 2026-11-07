#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>

#define CHK(op)                                                                \
    do {                                                                       \
        if ((op) == -1) {                                                      \
            perror(#op);                                                       \
            exit(1);                                                           \
        }                                                                      \
    } while (0)

#define BUFSIZE 1024

noreturn void usage(const char *msg)
{
    fprintf(stderr, "usage: %s <ip_dest> <port_dest> <duration>\n", msg);
    exit(EXIT_FAILURE);
}

long int conversion(char *s)
{
    char *endptr;
    long int v = strtol(s, &endptr, 10);

    if ((v == LONG_MAX || v == LONG_MIN) && errno == ERANGE) {
        perror("strtol: ");
        exit(EXIT_FAILURE);
    }
    if (*endptr != '\0') {
        fprintf(stderr, "strtol: junk in %s\n", s);
        exit(EXIT_FAILURE);
    }

    return v;
}

uint32_t convip(const char *ip)
{
    char *ip_copy = strdup(ip);
    if (ip_copy == NULL) {
        perror("strdup");
        exit(EXIT_FAILURE);
    }

    uint32_t addr = 0;
    char *token;
    int i = 0;

    token = strtok(ip_copy, ".");
    while (token != NULL) {
        if (i >= 4) {
            fprintf(stderr, "Erreur : adresse trop longue\n");
            free(ip_copy);
            exit(EXIT_FAILURE);
        }

        long int val = conversion(token);

        if (val < 0 || val > 255) {
            fprintf(stderr, "Erreur : octet hors intervalle [0, 255]\n");
            free(ip_copy);
            exit(EXIT_FAILURE);
        }

        addr |= ((uint32_t)val << ((3 - i) * 8));

        i++;
        token = strtok(NULL, ".");
    }

    if (i != 4) {
        fprintf(stderr, "Erreur : adresse trop courte\n");
        free(ip_copy);
        exit(EXIT_FAILURE);
    }

    free(ip_copy);
    return addr;
}


int main(int argc, char *argv[])
{
    if (argc != 4)
        usage(argv[0]);

    long int port_num = conversion(argv[2]);
    long int timer= conversion(argv[3]);


    int fd;
    CHK(fd = socket(AF_INET, SOCK_DGRAM, 0));

    struct sockaddr_in dest_addr;
    memset(&dest_addr, 0, sizeof(dest_addr));
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons((uint16_t)port_num);
    dest_addr.sin_addr.s_addr = htonl(convip(argv[1]));

    const char* msg = "hello world";
    CHK(sendto(fd, msg, strlen(msg), 0, (const struct sockaddr*)&dest_addr, sizeof(dest_addr)));
    
    
    sleep(timer); 
    CHK(close(fd));
    

    return 0;
}
