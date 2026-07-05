# Project 3 Quiz 中文版: White Box and Black Box Fuzz Testing

> 剧透提醒:本文件包含官方答案和反馈的中文整理。
> 建议完成 Radamsa fuzzing 和 KLEE symbolic execution 练习后再用来核对。

## Question 1: Fuzzing `wisdom-alt`

**题型:** multiple choice, shuffle

`fuzz.py` 是否能在 `wisdom-alt` 中识别出 crash? 需要多少轮?

**正确选项:**

- Identifies a crash, one iteration

**错误选项:**

- Does not identify a crash
- Identifies a crash, 103 iterations
- Identifies a crash, 44 iterations

**反馈:** Radamsa 很快就生成了错误输入。实际上,任何不是 `1` 或 `2` 的输入都会造成问题。

## Question 2: Fuzzing `wisdom-alt2`

**题型:** multiple choice, shuffle

`fuzz.py` 是否能在 `wisdom-alt2` 中识别出 crash? 需要多少轮?

**正确选项:**

- Does not identify a crash

**错误选项:**

- Identifies a crash, 1 iteration
- Identifies a crash, 800 iterations
- Identifies a crash, 133 iterations

**反馈:** 第一个问题修掉之后,Radamsa 更难找到会溢出缓冲区的输入,也就是文件里的第二个 bug。它尝试了很多输入,但没有成功。

## Question 3: KLEE 路径条件变量

**题型:** text match

说出一个 KLEE 识别出的、会让 `wisdom-alt2` 崩溃的路径条件中设置过的符号变量。

**接受答案:**

- `buf`
- `r`

## Question 4: 另一个 KLEE 路径条件变量

**题型:** text match

再说出另一个 KLEE 识别出的、会让 `wisdom-alt2` 崩溃的路径条件中设置过的符号变量。

**接受答案:**

- `buf`
- `r`

## Question 5: `buf` 对象数据

**题型:** multiple choice, shuffle

`buf` 对象的数据内容是什么?

**正确选项:**

```text
'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
```

**错误选项:**

```text
'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\x00\x00\x00\x00\x00\x00\x00\x00\xAA'
'\xFF\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
'\x00\x00\x00\xFF\x00\x00\x00\x00\x00\x00\xBB\x00\x00\x00\x00\x00\x00\x00\x00\xEE'
```

**反馈:** 这是 KLEE 生成的内容。具体内容没有长度重要,但 quiz 问的是 KLEE 选择的数据。

## Question 6: Symbolic Maze 的 `program` 数据

**题型:** text match

执行 symbolic maze 后,`program` 对象的数据值是什么? 它会是一串小写字母 `s`、`d`、`w`、`a`。

**接受答案:**

- `ssssddddwwaawwddddssssddwwww`
- `ssssddddwwaawwddddsddw`
- `sddwddddssssddwwww`
- `sddwddddsddw`

**反馈:** `program` 对象包含迷宫解,但这个解受到 bug 影响。任何一个解都可接受;具体答案取决于 KLEE 搜索路径。

## Question 7: Symbolic Maze 解的数量

**题型:** numeric

如果运行 symbolic maze 程序并让它找出所有解,而不是只找一个,一共有多少个?

**接受答案:**

- `4.0`

## Question 8: Maze 穿墙 bug 行号

**题型:** numeric

maze 程序中有一个 bug 允许玩家穿墙。这个 bug 在 `maze-sym.c` 的哪一行? 如果涉及多行,选其中一行。

**接受答案:**

- `113.0`
- `112.0`

**反馈:** 覆盖 111-113 行的 conditional 中,额外条件是错的,但第 111 行那部分本身不是错的。应该注释掉 112-113 行,并关闭条件保护,这样问题就会消失。
