#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* 模拟 TLS "心跳" 的最小服务:内存里 payload 缓冲区紧邻一段 secret。
 *
 * 请求格式(从 stdin 读):
 *   [1 字节 type][2 字节 length,大端][payload...]
 * 服务把 payload 原样回显 length 字节。
 */
struct {
    char payload[32];
    char secret[48];
} hb;

int main(void) {
    strcpy(hb.secret, "FLAG{heartbleed_overread}");

    unsigned char hdr[3];
    if (read(0, hdr, 3) != 3) return 1;
    unsigned int length = ((unsigned int)hdr[1] << 8) | hdr[2];

    memset(hb.payload, 0, sizeof(hb.payload));
    read(0, hb.payload, sizeof(hb.payload));

    write(1, hb.payload, length);
    return 0;
}
