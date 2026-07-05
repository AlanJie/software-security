# Project 1 Quiz

> Spoiler warning: this file contains the official answers and feedback.
> Use it after completing `wisdom-alt.c`, or when checking your work.

The original quiz asks for answers from UMD Software Security Project 1.
To match the course grader, avoid extra whitespace in text answers.

## Question 1: Stack Overflow Buffer

**Type:** math expression

Complete this quiz when you have completed project 1. The questions for the quiz
were presented in the description of the project, so you should just have to
enter your answers here.

There is a stack-based overflow in the program. What is the name of the
stack-allocated variable that contains the overflowed buffer?

**Accepted answer:**

- `wis`

**Feedback:** The `wis` variable is allocated on the stack and can get overflowed
by the call to `gets`.

## Question 2: Overflow Line for `wis`

**Type:** numeric

Consider the buffer you just identified: Running what line of code will overflow
the buffer? We want the line number, not the code itself.

**Accepted answer:**

- `62.0`

**Feedback:** Due to the `gets` overrunning the target buffer.

## Question 3: Non-Stack Buffer

**Type:** math expression

There is another vulnerability, not dependent at all on the first, involving a
non-stack-allocated buffer that can be indexed outside its bounds, which is
broadly construed as a kind of buffer overflow. What variable contains this
buffer?

**Accepted answer:**

- `ptrs`

**Feedback:** Note that `l->data` can be overflowed, but only if `wis` is
overflowed, so it would be dependent on the first.

## Question 4: Overflow Line for `ptrs`

**Type:** text match

Consider the buffer you just identified: Running what line of code overflows the
buffer? We want the number here, not the code itself.

**Accepted answers:**

- `100`
- `101`
- `102`

**Feedback:** This overflow happens by allowing the index variable to be too
large. Properly, this is at line 102, but you can make arguments that earlier
lines set this up to happen.

## Question 5: Address of `buf`

**Type:** text match

What is the address of `buf`, the local variable in the `main` function? Enter
the answer in either hexadecimal format, with `0x` followed by 8 digits, or
decimal format. We want the address of `buf`, not its contents.

**Accepted answers:**

- `3221221680`
- `0xbffff130`

**Feedback:** Break at `wisdom-alt.c:100` and print `&buf`.

## Question 6: Address of `ptrs`

**Type:** text match

What is the address of `ptrs`, the global variable? As with the previous
question, use hex or decimal format.

**Accepted answers:**

- `0x804a0d4`
- `0x0804a0d4`
- `134521044`

**Feedback:** Again, at the first breakpoint you can print `&ptrs` to get the
answer.

## Question 7: Address of `write_secret`

**Type:** text match

What is the address of `write_secret`, the function? Use hex or decimal.

**Accepted answers:**

- `0x8048534`
- `0x08048534`
- `134513972`

**Feedback:** Easy: print `&write_secret` from GDB.

## Question 8: Address of `p`

**Type:** text match

What is the address of `p`, the local variable in the `main` function? Use hex
or decimal format.

**Accepted answers:**

- `0xbffff534`
- `3221222708`

**Feedback:** Same drill as the earlier questions.

## Question 9: Make `ptrs[s]` Read `p`

**Type:** numeric

What input do you provide to the program so that `ptrs[s]` reads, and then tries
to execute, the contents of stack variable `p` instead of a function pointer
stored in the buffer pointed to by `ptrs`? As a hint, you can determine the
answer by performing a little arithmetic on the addresses you have already
gathered. If successful, you will end up executing the `pat_on_back` function.
Provide the smallest positive integer.

**Accepted answer:**

- `7.71675416E8`

**Feedback:** This is the result of doing
`(unsigned int)((int *)&p - (int *)&ptrs)` in GDB. Doing
`(unsigned int)&p - (unsigned int)&ptrs` will not work because the difference
will be in bytes, not pointer-sized words. We need the difference to be in words
so using `s` in `ptrs[s]` does the right thing.

## Question 10: Make `ptrs[s]` Read `buf[64]`

**Type:** numeric

What do you enter so that `ptrs[s]` reads, and then tries to execute, starting
from the 65th byte in `buf`, i.e. the location at `buf[64]`? Enter your answer
as an unsigned integer.

**Accepted answer:**

- `7.71675175E8`

**Feedback:** Use `(unsigned int)((int *)&buf[64] - (int *)&ptrs)` in GDB. Same
process as the previous question, but now you are using a different starting
point.

## Question 11: Little-Endian `write_secret` Address

**Type:** text match

What do you replace `\xEE\xEE\xEE\xEE` with in the following input to the
program, which due to the overflow will be filling in the 65th through 68th
bytes of `buf`, so that the `ptrs[s]` operation executes the `write_secret`
function and dumps the secret? Be sure to take endianness into account.

```text
771675175\x00AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xEE\xEE\xEE\xEE
```

**Accepted answer:**

- `\x34\x85\x04\x08`

**Feedback:** This is the address of `write_secret`, which is `0x08048534`, but
entered as hex bytes and accounting for little endianness.

## Question 12: Stack-Smashing Offset

**Type:** numeric

Suppose you wanted to overflow the `wis` variable to perform a stack smashing
attack. You could do this by entering `2` to call `put_wisdom`, and then enter
enough bytes to overwrite the return address of that function, replacing it with
the address of `write_secret`. How many bytes do you need to enter prior to the
address of `write_secret`?

**Accepted answer:**

- `148.0`

**Feedback:** This number comes from the following calculation:

- 128 bytes for the buffer
- 12 bytes for the three local variables: `r`, `l`, and `v`
- 4 bytes for saved EBP
- 4 bytes for saved EDI
- Then the return address, to be overflowed
