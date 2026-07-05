# Project 2 Quiz: BadStore 中文版

> 剧透提醒:本文件包含官方答案和反馈的中文整理。
> 建议完成 BadStore 实验后再用来核对。

## Question 1: 隐藏的权限字段

**题型:** regular expression

BadStore 的某个页面有一个隐藏表单字段,用于设置新用户的权限级别。这个字段名是什么?

**接受答案:**

- `([Rr]ole)`

**反馈:** 这个字段在创建新用户账号的页面上。

## Question 2: 商品数量

**题型:** numeric

BadStore 数据库中有多少个可购买商品? 使用 quick search 表单字段上的 SQL injection 找出答案。

**接受答案:**

- `16.0`

**其他答案:**

- `15.0` - 如果没有把 Test item 算进去,会得到 15。

**反馈:** SQL injection 显示数据库中还有不只 "What's New?" 页面上列出的商品。

## Question 3: 供应商可执行的操作

**题型:** checkbox, shuffle, partial credit

供应商被允许执行下面哪些操作? 可以用 SQL injection 绕过认证,也可以想办法创建供应商账号。

**正确选项:**

- Upload price list
- View existing price list

**错误选项:**

- Download an activity report
- Submit monthly bill payment
- Cancel contract

**反馈:** 正确选项出现在 "for suppliers only" 页面。

## Question 4: Joe 的信用卡号

**题型:** regular expression

以 `joe@supplier.com` 登录。可以用多种方式做到,包括 SQL injection。然后查看他的历史订单,回答:他购买 `$46.95` 商品时使用的信用卡号是什么? 多个答案都可接受。

**接受答案:**

- `(4111[- ]*1111[- ]*1111[ -]*1111)`
- `(5500[- ]*0000[- ]*0000[ -]*0004)`
- `(3747[- ]*1000[- ]*0000[- ]*0000)`
- `(4217[- ]*6399[- ]*5237[- ]*2130)`

## Question 5: `@whole.biz` 用户

**题型:** text match

获得管理员权限后,使用 `admin` action 查看用户数据库。有两个用户的邮箱格式是 `XXX@whole.biz`;问题要求填写其中任意一个用户的 `XXX` 部分,但不要两个都填。

例如,如果其中一个用户是 `jackie@whole.biz`,正确答案就是 `jackie`。答案区分大小写。

**接受答案:**

- `landon`
- `fred`

**错误答案:**

- `landon fred`
- `fred landon`

**反馈:** 题目要求填其中一个,不是两个都填。

## Question 6: Session Cookie 的 key

**题型:** regular expression

BadStore 使用 cookie 在用户认证后实现 session key,也用 cookie 跟踪购物车内容。可以用多种方式查看这些 cookie。其中一种方法是在 guest book 上做 XSS:

```html
<script>alert(document.cookie)</script>
```

浏览器需要允许弹窗,否则这不会生效。也可以直接用 Firefox developer tools 查看 cookie。Cookie 是 `key=value` 对。Session cookie 的 key 名是什么?

**接受答案:**

- `(SS[O0][iI][dD])`

## Question 7: Cart Cookie 的 key

**题型:** regular expression

BadStore 使用 cookie 跟踪购物车内容。用于购物车的 cookie key 名是什么?

**接受答案:**

- `(Cart[Ii][Dd])`

## Question 8: Session Cookie 字段

**题型:** checkbox, shuffle, partial credit

BadStore 的 session cookie 格式设计很差,因为它使用可预测结构。具体来说,它是一个编码后的字符串,末尾带 URL-encoded newline,中间用冒号拼接多个字段:

```text
XXX:YYY:ZZZ:etc
```

下面哪些字段包含在这个 session cookie 中?

**正确选项:**

- e-mail address
- MD5 hash of password
- full name
- role

**错误选项:**

- SHA1 hash of password
- expiration timeout
- integer that counts the number of times ever logged in
- the number of failed login attempts

**反馈:**

- e-mail address 是第一个字段。
- MD5 password hash 是第二个字段。
- full name 是第三个字段。
- role 是第四个字段。
- 密码哈希使用 MD5,不是 SHA1。
- 其他列出的值不是 cookie 的组成部分。

## Question 9: Cart Cookie 的折扣字段

**题型:** numeric

BadStore 的 cart cookie 也是一个带可预测结构的编码字符串:

```text
XXX:YYY:ZZZ:etc
```

它很可能包含了不该由客户端控制的信息。解码后的字符串中,攻击者可以修改第几个字段来给自己打折? 字段编号从 1 开始。

**接受答案:**

- `3.0`

**反馈:** 第一个字段是整数,第二个字段是购物车中商品数量,第三个字段是这些商品的总价。
