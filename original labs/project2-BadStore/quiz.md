# Project 2 Quiz: BadStore

> Spoiler warning: this file contains the official answers and feedback.
> Use it after completing the BadStore exercise, or when checking your work.

## Question 1: Hidden Privilege Field

**Type:** regular expression

One of the BadStore pages has a hidden form field that establishes a new user's
privilege level. What is the name of this field?

**Accepted answer:**

- `([Rr]ole)`

**Feedback:** This field is on the page used to make a new user account.

## Question 2: Number of Store Items

**Type:** numeric

How many items for purchase are in BadStore's database? Use SQL injection on the
quick search form field to find out.

**Accepted answer:**

- `16.0`

**Other answer:**

- `15.0` — You would get 15 if you did not count the Test item.

**Feedback:** SQL injection shows there are more items than just those shown on
the "What's New?" page.

## Question 3: Supplier Operations

**Type:** checkbox, shuffle, partial credit

Which of the following operations are suppliers permitted to do? Use SQL
injection to bypass authentication, or find a way to create an account as a
supplier.

**Correct options:**

- Upload price list
- View existing price list

**Incorrect options:**

- Download an activity report
- Submit monthly bill payment
- Cancel contract

**Feedback:** The correct options are on the "for suppliers only" page.

## Question 4: Joe's Credit Card Number

**Type:** regular expression

Log in as `joe@supplier.com`. This is possible in a variety of ways, including
SQL injection. Then look at his previous orders and answer the question: what
credit card number did he use to make a purchase of `$46.95`? Multiple answers
are possible, and all of the following are accepted.

**Accepted answers:**

- `(4111[- ]*1111[- ]*1111[ -]*1111)`
- `(5500[- ]*0000[- ]*0000[ -]*0004)`
- `(3747[- ]*1000[- ]*0000[- ]*0000)`
- `(4217[- ]*6399[- ]*5237[- ]*2130)`

## Question 5: `@whole.biz` Users

**Type:** text match

Get admin privileges and then use the `admin` action to look at the user
database. There are two users whose emails have the form `XXX@whole.biz`; what
is the `XXX` portion of either, but not both, of the two users?

For example, if one of the users is `jackie@whole.biz`, the right answer is
`jackie`. The answer is case-sensitive.

**Accepted answers:**

- `landon`
- `fred`

**Incorrect answers:**

- `landon fred`
- `fred landon`

**Feedback:** The question asks for one of them, not both.

## Question 6: Session Cookie Key

**Type:** regular expression

BadStore uses cookies to implement session keys once you've authenticated, and
to track the contents of the cart once you've added something to it. You can
inspect these cookies in various ways. One way is to do an XSS attack on the
guest book:

```html
<script>alert(document.cookie)</script>
```

Be sure popups are enabled in your browser, or this will not work. Alternatively,
you can examine the cookies directly using Firefox developer tools. Cookies are
pairs of `key=value`. What is the key name of the session cookie?

**Accepted answer:**

- `(SS[O0][iI][dD])`

## Question 7: Cart Cookie Key

**Type:** regular expression

BadStore uses cookies to track the contents of the cart once you've added
something to it. What is the key name of the cookie used for the cart?

**Accepted answer:**

- `(Cart[Ii][Dd])`

## Question 8: Session Cookie Fields

**Type:** checkbox, shuffle, partial credit

BadStore's session cookie format is poorly designed because it uses a predictable
structure. In particular, it is an encoded string, with a URL-encoded newline at
the end, of concatenated fields separated by colons:

```text
XXX:YYY:ZZZ:etc
```

Which of the following are the fields that it uses?

**Correct options:**

- e-mail address
- MD5 hash of password
- full name
- role

**Incorrect options:**

- SHA1 hash of password
- expiration timeout
- integer that counts the number of times ever logged in
- the number of failed login attempts

**Feedback:**

- The e-mail address is the first field.
- The MD5 password hash is the second field.
- The full name is the third field.
- The role is the fourth field.
- The password hash uses MD5, not SHA1.
- The other listed values are not part of the cookie.

## Question 9: Cart Cookie Discount Field

**Type:** numeric

BadStore's cart cookie is also an encoded string with a predictable structure:

```text
XXX:YYY:ZZZ:etc
```

It probably contains information it should not. Which field, where fields are
numbered starting at 1, of the decoded string could an attacker change to give
himself a discount on an item's price?

**Accepted answer:**

- `3.0`

**Feedback:** The first field is an integer, the second is the number of items
in the cart, and the third is the total price of those items.
