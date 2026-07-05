#!/usr/bin/env python3
"""一个最小登录程序(故意写得不安全)。

运行:python3 app.py
输入用户名、密码;正确则登录。admin 的密码是启动时生成的强随机值。
"""
import os
import secrets
import sqlite3

DB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "users.db")


def init_db():
    # 每次运行重建数据库:admin 密码随机,排除"猜/爆破密码"这条路
    if os.path.exists(DB):
        os.remove(DB)
    con = sqlite3.connect(DB)
    cur = con.cursor()
    cur.execute("CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, pass TEXT, role TEXT)")
    cur.executemany(
        "INSERT INTO users(name, pass, role) VALUES(?, ?, ?)",
        [
            ("admin", secrets.token_hex(16), "admin"),
            ("guest", "guest", "user"),
        ],
    )
    con.commit()
    con.close()


def login(user, pw):
    con = sqlite3.connect(DB)
    cur = con.cursor()
    query = "SELECT name, role FROM users WHERE name='%s' AND pass='%s'" % (user, pw)
    cur.execute(query)
    row = cur.fetchone()
    con.close()
    return row


def main():
    init_db()
    user = input("username: ")
    pw = input("password: ")
    row = login(user, pw)
    if row:
        print("Welcome %s! role=%s" % (row[0], row[1]))
    else:
        print("Login failed.")


if __name__ == "__main__":
    main()
