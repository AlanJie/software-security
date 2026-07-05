#!/usr/bin/env python3
import os
import select
import subprocess
import sys


def read_until_prompt(proc, timeout=2.0):
    out = bytearray()
    while proc.poll() is None:
        ready, _, _ = select.select([proc.stdout], [], [], timeout)
        if not ready:
            break
        chunk = proc.stdout.read(1)
        if not chunk:
            break
        out.extend(chunk)
        if chunk == b">" or b"Enter some wisdom" in out:
            break
    return bytes(out)


def main():
    if len(sys.argv) != 2:
        print("usage: fuzz3.py ./target", file=sys.stderr)
        return 2

    target = sys.argv[1]
    max_iter = int(os.environ.get("FUZZ_MAX", "1000"))
    seed = int(os.environ.get("FUZZ_SEED", "12458341"))

    proc = subprocess.Popen(
        [target],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=0,
    )

    last_input = b""
    for i in range(max_iter):
        if proc.poll() is not None:
            break

        print(f"{i}/{max_iter}")
        fuzzer = subprocess.Popen(
            ["radamsa", "-s", str(seed), "fuzzinput"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        last_input, fuzz_err = fuzzer.communicate()
        if fuzzer.returncode != 0:
            sys.stderr.write(fuzz_err.decode("utf-8", errors="replace"))
            return fuzzer.returncode

        seed += 1
        print("trying %r" % last_input)
        read_until_prompt(proc)

        if proc.stdin is None:
            break
        try:
            proc.stdin.write(last_input + b"\n")
            proc.stdin.flush()
        except BrokenPipeError:
            break

        proc.poll()
        if proc.returncode is not None:
            break

    proc.poll()
    if proc.returncode is None:
        print("did not crash")
        proc.terminate()
        try:
            proc.wait(timeout=1)
        except subprocess.TimeoutExpired:
            proc.kill()
        return 0

    print("crashed with %r" % last_input)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
