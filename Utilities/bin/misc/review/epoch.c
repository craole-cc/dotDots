#include <sys/time.h>
#include <stdio.h>
int main(int argc, char **argv) {
    struct timeval time;
    gettimeofday(&time, NULL);
    printf("%li.%06i", time.tv_sec, time.tv_usec);
}