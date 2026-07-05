#include <stdint.h>
#include <stddef.h>
#include <string.h>

/* libFuzzer 入口:每次喂入一段随机字节 (Data, Size)。
 * 里面藏着一个会崩溃的解析逻辑——你的任务是让 fuzzer 自己找到它。 */
int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    char buf[16];

    if (Size >= 4 && memcmp(Data, "FUZZ", 4) == 0) {
        memcpy(buf, Data, Size);      /* Size 可远大于 16 */
        return buf[Size % 16];
    }
    return 0;
}
