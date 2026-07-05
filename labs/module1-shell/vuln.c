#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void shell(void) {
    system("/bin/sh");
}

void vulnerable(void) {
    char buf[16];
    printf("input> ");
    fflush(stdout);
    ssize_t n = read(0, buf, 256);
    if (n > 0) buf[n < 256 ? n : 255] = '\0';
    printf("you said: %s\n", buf);
}

int main(void) {
    vulnerable();
    puts("bye");
    return 0;
}
