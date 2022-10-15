# **MYSQL内连接、左连接、右连接**

## **1. 建表**

建立两个表，`a_table`和`b_table`

```sql
CREATE TABLE `a_table` (
  `a_id` int(11) DEFAULT NULL,
  `a_name` varchar(10) DEFAULT NULL,
  `a_part` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8

CREATE TABLE `b_table` (
  `b_id` int(11) DEFAULT NULL,
  `b_name` varchar(10) DEFAULT NULL,
  `b_part` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8
```

```sql
mysql> show tables;
+----------------+
| Tables_in_test |
+----------------+
| a_table        |
| b_table        |
+----------------+
2 rows in set (0.00 sec)
```

插入测试数据:

```sql
INSERT INTO `test`.`a_table` (`a_id`, `a_name`, `a_part`) VALUES (1, 'jack', 'ceo');
INSERT INTO `test`.`a_table` (`a_id`, `a_name`, `a_part`) VALUES (2, 'mary', 'dev');
INSERT INTO `test`.`a_table` (`a_id`, `a_name`, `a_part`) VALUES (3, 'ming', 'dev');
INSERT INTO `test`.`a_table` (`a_id`, `a_name`, `a_part`) VALUES (4, 'tom', 'hr');
INSERT INTO `test`.`b_table` (`b_id`, `b_name`, `b_part`) VALUES (2, 'mary', 'dev');
INSERT INTO `test`.`b_table` (`b_id`, `b_name`, `b_part`) VALUES (3, 'ming', 'dev');
INSERT INTO `test`.`b_table` (`b_id`, `b_name`, `b_part`) VALUES (5, 'hong', 'dev');
INSERT INTO `test`.`b_table` (`b_id`, `b_name`, `b_part`) VALUES (6, 'james', 'test');
```

现在的表结构是这样子的:

```sql
mysql> select * from a_table;
+------+--------+--------+
| a_id | a_name | a_part |
+------+--------+--------+
|    1 | jack   | ceo    |
|    2 | mary   | dev    |
|    3 | ming   | dev    |
|    4 | tom    | hr     |
+------+--------+--------+
4 rows in set (0.00 sec)
```

```sql
mysql> select * from b_table;
+------+--------+--------+
| b_id | b_name | b_part |
+------+--------+--------+
|    2 | mary   | dev    |
|    3 | ming   | dev    |
|    5 | hong   | dev    |
|    6 | james  | test   |
+------+--------+--------+
4 rows in set (0.00 sec)
```

<br>

## **2. 内连接 [inner join on]**

```sql
mysql> select * from a_table a inner join b_table b on a.a_id=b.b_id;
+------+--------+--------+------+--------+--------+
| a_id | a_name | a_part | b_id | b_name | b_part |
+------+--------+--------+------+--------+--------+
|    2 | mary   | dev    |    2 | mary   | dev    |
|    3 | ming   | dev    |    3 | ming   | dev    |
+------+--------+--------+------+--------+--------+
2 rows in set (0.00 sec)
```

从结果中可以看到，内连接可以组合两个表中的所有字段，同时返回两个表的交集部分。

![img](https://img-blog.csdn.net/20171209135846780?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcGxnMTc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

<br>

## **3. 左连接 [left join on]**

左连接也可以写成`left outer join on`

```sql
mysql> select * from a_table a left join b_table b on a.a_id=b.b_id;
+------+--------+--------+------+--------+--------+
| a_id | a_name | a_part | b_id | b_name | b_part |
+------+--------+--------+------+--------+--------+
|    1 | jack   | ceo    | NULL | NULL   | NULL   |
|    2 | mary   | dev    |    2 | mary   | dev    |
|    3 | ming   | dev    |    3 | ming   | dev    |
|    4 | tom    | hr     | NULL | NULL   | NULL   |
+------+--------+--------+------+--------+--------+
4 rows in set (0.00 sec)
```

在左连接中，左表作为主表会将记录全部展示出来，而右表则只展示符合筛选条件的记录，不符合的地方均为NULL

![img](https://img-blog.csdn.net/20171209142610819?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcGxnMTc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

<br>

## **4. 右连接 [right join on]**

```sql
mysql> select * from a_table a right join b_table b on a.a_id=b.b_id;
+------+--------+--------+------+--------+--------+
| a_id | a_name | a_part | b_id | b_name | b_part |
+------+--------+--------+------+--------+--------+
|    2 | mary   | dev    |    2 | mary   | dev    |
|    3 | ming   | dev    |    3 | ming   | dev    |
| NULL | NULL   | NULL   |    5 | hong   | dev    |
| NULL | NULL   | NULL   |    6 | james  | test   |
+------+--------+--------+------+--------+--------+
4 rows in set (0.00 sec)
```

与左连接正好相反，右连接是以右表作为主表显示所有记录，而左表只展示符合条件的记录

![img](https://img-blog.csdn.net/20171209144056668?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcGxnMTc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

<br>