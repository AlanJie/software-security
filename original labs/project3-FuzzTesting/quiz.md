# Project 3 Quiz: White Box and Black Box Fuzz Testing

> Spoiler warning: this file contains the official answers and feedback.
> Use it after completing the fuzzing and KLEE exercises, or when checking your work.

## Question 1: Fuzzing `wisdom-alt`

**Type:** multiple choice, shuffle

Does `fuzz.py` identify a crash in `wisdom-alt`? In how many iterations?

**Correct option:**

- Identifies a crash, one iteration

**Incorrect options:**

- Does not identify a crash
- Identifies a crash, 103 iterations
- Identifies a crash, 44 iterations

**Feedback:** Radamsa immediately generates a bogus input; indeed, any input that
is not a `1` or a `2` is going to cause problems.

## Question 2: Fuzzing `wisdom-alt2`

**Type:** multiple choice, shuffle

Does `fuzz.py` identify a crash in `wisdom-alt2`? In how many iterations?

**Correct option:**

- Does not identify a crash

**Incorrect options:**

- Identifies a crash, 1 iteration
- Identifies a crash, 800 iterations
- Identifies a crash, 133 iterations

**Feedback:** Now that the first problem is fixed, it is much harder for Radamsa
to find an input that overruns the buffer, which is the second bug in the file.
It tried many inputs, to no avail.

## Question 3: KLEE Path Condition Variable

**Type:** text match

Name one symbolic variable that was set in the path condition identified by KLEE
that crashes `wisdom-alt2`.

**Accepted answers:**

- `buf`
- `r`

## Question 4: Another KLEE Path Condition Variable

**Type:** text match

Name another symbolic variable set in the path condition identified by KLEE that
crashes `wisdom-alt2`.

**Accepted answers:**

- `buf`
- `r`

## Question 5: `buf` Object Data

**Type:** multiple choice, shuffle

What was the data content of the `buf` object?

**Correct option:**

```text
'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
```

**Incorrect options:**

```text
'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\x00\x00\x00\x00\x00\x00\x00\x00\xAA'
'\xFF\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
'\x00\x00\x00\xFF\x00\x00\x00\x00\x00\x00\xBB\x00\x00\x00\x00\x00\x00\x00\x00\xEE'
```

**Feedback:** This is the content that KLEE generates. The contents do not matter
as much as its length matters, but the quiz asks what KLEE selected.

## Question 6: Symbolic Maze `program` Data

**Type:** text match

After executing the symbolic maze, what was the data value of the `program`
object? It will be a string of the lowercase letters `s`, `d`, `w`, and `a`.

**Accepted answers:**

- `ssssddddwwaawwddddssssddwwww`
- `ssssddddwwaawwddddsddw`
- `sddwddddssssddwwww`
- `sddwddddsddw`

**Feedback:** The `program` object contains the solution to the maze, modulo the
bug. Any solution is an acceptable answer; it depends on the paths that KLEE
takes in its search.

## Question 7: Number of Symbolic Maze Solutions

**Type:** numeric

If you run the symbolic maze program so that it finds all solutions, not just
one, how many are there?

**Accepted answer:**

- `4.0`

## Question 8: Maze Wall-Walking Bug Line

**Type:** numeric

There was a bug in the maze program that allows the player to walk through
walls. What line in `maze-sym.c` is the bug on? If there are multiple lines, pick
one of them.

**Accepted answers:**

- `113.0`
- `112.0`

**Feedback:** The extra condition in the conditional whose guard covers lines
111-113 is incorrect, but the part of the conditional on line 111 is not wrong.
Lines 112-113 should be commented out and the conditional guard closed off to
make the problem go away.
