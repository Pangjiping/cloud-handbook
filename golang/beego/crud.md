# **golang beego后端开发框架（八）：CRUD与高级查询**

## **1. 对象的CRUD操作**

如果已知主键的值，那么可以使用这些方法进行CRUD操作

对object操作的四个方法Read/Insert/Updata/Delete

<br>

### **1.1 Read**

Read默认通过查询主键赋值，如果Read()不带第二个参数的话，是主键查询

```golang
o := orm.NewOrm()
user := User{Id: 1}
err := o.Read(&user)
if err == orm.ErrNoRows {
    fmt.Println("查询不到")
} else if err == orm.ErrMissPK {
    fmt.Println("找不到主键")
} else {
    fmt.Println(user.Id, user.Name)
}
```
 

当然可以查询指定的列名，需要在`Read()`中指定第二个参数

```golang
user := User{Name: "slene"}
err = o.Read(&user, "Name")
```

<br>

### **1.2 ReadOrCreate**

尝试从数据库读取，不存在的话就创建一个

它的实现机制和具体的数据库有关，默认必须传入一个参数作为条件字段，同时也支持多个参数多个条件字段

```golang
o := orm.NewOrm()
user := User{Name: "slene"}
// 三个返回参数依次为：是否新创建的，对象 Id 值，错误
if created, id, err := o.ReadOrCreate(&user, "Name"); err == nil {
    if created {
        fmt.Println("New Insert an object. Id:", id)
    } else {
        fmt.Println("Get an object. Id:", id)
    }
}
```

<br>

### **1.3 Insert**

插入数据，返回值为自增ID的值

失败的情况可能是违反了唯一约束或者外键约束，或者是internal错误

```golang
o := orm.NewOrm()
var user User
user.Name = "slene"
user.IsActive = true
id, err := o.Insert(&user)
if err == nil {
    fmt.Println(id)
}
```
 
<br>

### **1.4 InsertMulti**

同时插入多个对象，类似于如下的SQL语句

```sql
insert into table (name, age) values("slene", 28),("astaxie", 30),("unknown", 20)
```
 

第一个参数bulk为并列插入的数量，第二个胃对象的slice

bulk=1时，将会顺序插入slice中的数据

返回值是成功插入的数量

```golang
users := []User{
    {Name: "slene"},
    {Name: "astaxie"},
    {Name: "unknown"},
    ...
}
successNums, err := o.InsertMulti(100, users)
```

<br>

### **1.5 Update**

第一个返回值为影响的行数

```golang
o := orm.NewOrm()
user := User{Id: 1}
if o.Read(&user) == nil {
    user.Name = "MyName"
    if num, err := o.Update(&user); err == nil {
        fmt.Println(num)
    }
}
```

Update默认更新所有的字段，可以更新指定的字段

```golang
// 只更新 Name
o.Update(&user, "Name")
// 指定多个字段
// o.Update(&user, "Field1", "Field2", ...)
...
```

<br>

### **1.6 Delete**

`Delete` 操作会对反向关系进行操作，此例中 `Post` 拥有一个到 `User` 的外键。删除 `User` 的时候。如果 `on_delete` 设置为默认的级联操作，将删除对应的 `Post`

第一个返回值是影响的行数

```golang
o := orm.NewOrm()
if num, err := o.Delete(&User{Id: 1}); err == nil {
    fmt.Println(num)
}
```

<br>

## **2. 高级查询**

ORM以`QuerySeter`来组织查询，每个返回`QuerySeter`的方法都会获得一个新的`QuerySeter`对象

基本使用方法：

```golang
o := orm.NewOrm()
 
// 获取 QuerySeter 对象，user 为表名
qs := o.QueryTable("user")
 
// 也可以直接使用 Model 结构体作为表名
qs = o.QueryTable(&User)
 
// 也可以直接使用对象作为表名
user := new(User)
qs = o.QueryTable(user) // 返回 QuerySeter
```

<br>

### **2.1 expr**

QuerySeter中用户描述字段和SQL操作符，使用简单的expr查询方法

字段组合的前后顺序依照表的关系，比如 User 表拥有 Profile 的外键，那么对 User 表查询对应的 Profile.Age 为条件，则使用 Profile__Age 注意，字段的分隔符号使用双下划线 __，除了描述字段， expr 的尾部可以增加操作符以执行对应的 sql 操作。比如 Profile__Age__gt 代表 Profile.Age > 18 的条件查询

注释后面将描述对应的 sql 语句，仅仅是描述 expr 的类似结果，并不代表实际生成的语句

```golang
qs.Filter("id", 1) // WHERE id = 1
qs.Filter("profile__age", 18) // WHERE profile.age = 18
qs.Filter("Profile__Age", 18) // 使用字段名和 Field 名都是允许的
qs.Filter("profile__age__gt", 18) // WHERE profile.age > 18
qs.Filter("profile__age__gte", 18) // WHERE profile.age >= 18
qs.Filter("profile__age__in", 18, 20) // WHERE profile.age IN (18, 20)
qs.Filter("profile__age__in", 18, 20).Exclude("profile__lt", 1000)
// WHERE profile.age IN (18, 20) AND NOT profile_id < 1000
```

<br>

### **2.2 operators**

当前支持的操作符号

* exact/iexact 等于
* contains/icontains 包含
* gt/gte 大于/大于等于
* lt/lte 小于/小于等于
* startswith/istartswith 以...开始
* endswith/iendswith 以...结束
* in
* isnull

后面以 i 开头的表示对大小写不敏感

<br>

#### **2.2.1 exact**

Filter / Exclude / Condition expr的默认值

```golang
qs.Filter("name", "slene") // WHERE name = 'slene'
qs.Filter("name__exact", "slene") // WHERE name = 'slene'
// 使用 = 匹配，大小写是否敏感取决于数据表使用的 collation
qs.Filter("profile_id", nil) // WHERE profile_id IS NULL
```

<br>
 

#### **2.2.2 iexact**

大小写不敏感，匹配后面的任意形式

```golang
qs.Filter("name__iexact", "slene")
// WHERE name LIKE 'slene'
// 大小写不敏感，匹配任意 'Slene' 'sLENE'
```

<br> 

#### **2.2.3 contains**

匹配包含关系

```golang
qs.Filter("name__contains", "slene")
// WHERE name LIKE BINARY '%slene%'
// 大小写敏感, 匹配包含 slene 的字符
```

<br>

#### **2.2.4 icontains**

```golang
qs.Filter("name__icontains", "slene")
// WHERE name LIKE '%slene%'
// 大小写不敏感, 匹配任意 'im Slene', 'im sLENE'
```

<br>

#### **2.2.5 in**

```golang
qs.Filter("age__in", 17, 18, 19, 20)
// WHERE age IN (17, 18, 19, 20)
ids:=[]int{17,18,19,20}
qs.Filter("age__in", ids)
// WHERE age IN (17, 18, 19, 20)
```

<br>

#### **2.2.6 gt/gte**

```golang
qs.Filter("profile__age__gt", 17)
// WHERE profile.age > 17
qs.Filter("profile__age__gte", 18)
// WHERE profile.age >= 18
```

<br>

#### **2.2.7 lt/lte**

```golang
qs.Filter("profile__age__lt", 17)
// WHERE profile.age < 17
qs.Filter("profile__age__lte", 18)
// WHERE profile.age <= 18
```

<br>

#### **2.2.8 startswith**

```golang
qs.Filter("name__startswith", "slene")
// WHERE name LIKE BINARY 'slene%'
// 大小写敏感, 匹配以 'slene' 起始的字符串
```

<br>

#### **2.2.9 istartswith**

```golang
qs.Filter("name__istartswith", "slene")
// WHERE name LIKE 'slene%'
// 大小写不敏感, 匹配任意以 'slene', 'Slene' 起始的字符串
```

<br>

#### **2.2.10 endswith**

```golang
qs.Filter("name__endswith", "slene")
// WHERE name LIKE BINARY '%slene'
// 大小写敏感, 匹配以 'slene' 结束的字符串
```

<br>

#### **2.2.11 iendswith**

```golang
qs.Filter("name__iendswithi", "slene")
// WHERE name LIKE '%slene'
// 大小写不敏感, 匹配任意以 'slene', 'Slene' 结束的字符串
```

<br>

#### **2.2.12 isnull**

```golang
qs.Filter("profile__isnull", true)
qs.Filter("profile_id__isnull", true)
// WHERE profile_id IS NULL
qs.Filter("profile__isnull", false)
// WHERE profile_id IS NOT NULL
```

<br>

### **2.3 高级查询接口使用**

QuerySeter是高级查询使用的接口，它所包含的接口方法有：

```golang
type QuerySeter interface {
Filter(string, ...interface{}) QuerySeter
 
FilterRaw(string, string) QuerySeter
 
Exclude(string, ...interface{}) QuerySeter
 
SetCond(*Condition) QuerySeter
 
GetCond() *Condition
 
Limit(limit interface{}, args ...interface{}) QuerySeter
 
Offset(offset interface{}) QuerySeter
 
GroupBy(exprs ...string) QuerySeter
 
OrderBy(exprs ...string) QuerySeter
 
ForceIndex(indexes ...string) QuerySeter
 
UseIndex(indexes ...string) QuerySeter
 
IgnoreIndex(indexes ...string) QuerySeter
 
RelatedSel(params ...interface{}) QuerySeter
 
Distinct() QuerySeter
 
ForUpdate() QuerySeter
 
Count() (int64, error)
 
Exist() bool
 
Update(values Params) (int64, error)
 
Delete() (int64, error)
 
PrepareInsert() (Inserter, error)
 
All(container interface{}, cols ...string) (int64, error)
 
One(container interface{}, cols ...string) error
 
Values(results *[]Params, exprs ...string) (int64, error)
 
ValuesList(results *[]ParamsList, exprs ...string) (int64, error)
 
ValuesFlat(result *ParamsList, expr string) (int64, error)
 
RowsToMap(result *Params, keyCol, valueCol string) (int64, error)
 
RowsToStruct(ptrStruct interface{}, keyCol, valueCol string) (int64, error)
}
```

注意到很多方法都返回了一个`QuerySeter`，需要注意的是：

每个返回`QuerySeter`的api调用时都会创建一个新的`QuerySeter`，不会影响之前创建的
高级查询使用 Filter 和 Exclude 来做常用的条件查询

<br>

#### **2.3.1 Filter**

用来过滤查询结果，起到包含条件的作用

多个 Filter 之间用 . 连接

```golang
qs.Filter("profile__isnull", true).Filter("name", "slene")
// WHERE profile_id IS NULL AND name = 'slene'
```

<br>

#### **2.3.2 Exclude**

用来过滤查询结果，起到排除条件的作用，相当于NOT

```golang
qs.Exclude("profile__isnull", true).Filter("name", "slene")
// WHERE NOT profile_id IS NULL AND name = 'slene'
```

<br>

#### **2.3.3 SetCond**

自定义条件表达式

```golang
cond := orm.NewCondition()
cond1 := cond.And("profile__isnull", false).AndNot("status__in", 1).Or("profile__age__gt", 2000)
qs := orm.QueryTable("user")
qs = qs.SetCond(cond1)
// WHERE ... AND ... AND NOT ... OR ...
cond2 := cond.AndCond(cond1).OrCond(cond.And("name", "slene"))
qs = qs.SetCond(cond2).Count()
// WHERE (... AND ... AND NOT ... OR ...) OR ( ... )
```

<br>

#### **2.3.4 Limit**

限制最大返回数据行数，第二个参数可以设置 offset

```golang
var DefaultRowsLimit = 1000 // ORM 默认的 limit 值为 1000
// 默认情况下 select 查询的最大行数为 1000
// LIMIT 1000
qs.Limit(10)
// LIMIT 10
qs.Limit(10, 20)
// LIMIT 10 OFFSET 20 注意跟 SQL 反过来的
qs.Limit(-1)
// no limit
qs.Limit(-1, 100)
// LIMIT 18446744073709551615 OFFSET 100
// 18446744073709551615 是 1<<64 - 1 用来指定无 limit 限制 但有 offset 偏移的情况
```

<br>

#### **2.3.5 Offset**

设置偏移行数

```golang
qs.Offset(20)
// LIMIT 1000 OFFSET 20
```

<br>

#### **2.3.6 GroupBy**

```golang
qs.GroupBy("id", "age")
// GROUP BY id,age
```

<br>

#### **2.3.7 OrderBy**

参数使用 expr

在expr前面使用减号 - 表示 DESC 的排列

```golang
qs.OrderBy("id", "-profile__age")
// ORDER BY id ASC, profile.age DESC
qs.OrderBy("-profile__age", "profile")
// ORDER BY profile.age DESC, profile_id ASC
```

<br>

#### **2.3.8 ForceIndex**

强迫走索引，使用该选项请确认数据库支持该特性

```golang
qs.ForceIndex(`idx_name1`,`idx_name2`)
```

<br>

#### **2.3.9 UseIndex**

使用索引

使用该特性的时候需要确认数据库是否支持该特性，以及该特性的具体含义

例如，部分数据库对于该选项是当成一种建议来执行的。即，即便用户使用了UseIndex方法，但是数据库在具体执行的时候，也可能不会使用设定的索引

```golang
qs.UseIndex(`idx_name1`,`idx_name2`)
```

<br>

#### **2.3.10 IgnoreIndex**

忽略索引，请确认数据库是否支持索引

```golang
qs.IgnoreIndex(`idx_name1`,`idx_name2`)
```

<br>

#### **2.3.11 Distinct**

对应SQL的 distinct 语句，返回指定字段不重复的值

```golang
qs.Distinct()
// SELECT DISTINCT
```

<br>

#### **2.3.12 RelatedSel**

关系查询，参数使用expr

```golang
var DefaultRelsDepth = 5 // 默认情况下直接调用 RelatedSel 将进行最大 5 层的关系查询
qs := o.QueryTable("post")
qs.RelatedSel()
// INNER JOIN user ... LEFT OUTER JOIN profile ...
qs.RelatedSel("user")
// INNER JOIN user ...
// 设置 expr 只对设置的字段进行关系查询
// 对设置 null 属性的 Field 将使用 LEFT OUTER JOIN
```

<br>

#### **2.3.13 Count**

依据当前的查询条件，返回结果行数

```golang
cnt, err := o.QueryTable("user").Count() // SELECT COUNT(*) FROM USER
fmt.Printf("Count Num: %s, %s", cnt, err)
```

<br>

#### **2.3.14 Exist**

```golang
exist := o.QueryTable("user").Filter("UserName", "Name").Exist()
fmt.Printf("Is Exist: %s", exist)
```

<br>

#### **2.3.15 Update**

根据当前查询条件，进行批量更新操作

```golang
num, err := o.QueryTable("user").Filter("name", "slene").Update(orm.Params{
    "name": "astaxie",
})
fmt.Printf("Affected Num: %s, %s", num, err)
// SET name = "astaixe" WHERE name = "slene"
```

原子操作增加字段值

```golang
// 假设 user struct 里有一个 nums int 字段
num, err := o.QueryTable("user").Update(orm.Params{
    "nums": orm.ColValue(orm.ColAdd, 100),
})
// SET nums = nums + 100
```

orm.ColValue支持以下操作
* ColAdd      // 加
* ColMinus    // 减
* ColMultiply // 乘
* ColExcept   // 除

<br>

#### **2.3.16 Delete**

根据当前查询条件，进行批量删除操作

```golang
num, err := o.QueryTable("user").Filter("name", "slene").Delete()
fmt.Printf("Affected Num: %s, %s", num, err)
// DELETE FROM user WHERE name = "slene"
```

<br>

#### **2.3.17 PrepareInsert**

用于一次prepare多次insert插入，提高批量插入的速度

```golang
var users []*User
...
qs := o.QueryTable("user")
i, _ := qs.PrepareInsert()
for _, user := range users {
    id, err := i.Insert(user)
    if err == nil {
        ...
    }
}
// PREPARE INSERT INTO user (`name`, ...) VALUES (?, ...)
// EXECUTE INSERT INTO user (`name`, ...) VALUES ("slene", ...)
// EXECUTE ...
// ...
i.Close() // 别忘记关闭 statement
```

<br>

#### **2.3.18 All**

返回对应的结果集对象

All 的参数支持 []Type 和 []*Type 两种形式的 slice

```golang
var users []*User
num, err := o.QueryTable("user").Filter("name", "slene").All(&users)
fmt.Printf("Returned Rows Num: %s, %s", num, err)
```

All / Values / ValuesList / ValueFlat 受到 Limit 的限制，默认最大行数为1000

可以指定返回的字段，对象的其他未指定字段值将会是对应类型的默认值

```golang
type Post struct {
    Id      int
    Title   string
    Content string
    Status  int
}
// 只返回 Id 和 Title
var posts []Post
o.QueryTable("post").Filter("Status", 1).All(&posts, "Id", "Title")
```

<br>

#### **2.3.19 One**

尝试返回单条记录

```golang
var user User
err := o.QueryTable("user").Filter("name", "slene").One(&user)
if err == orm.ErrMultiRows {
    // 多条的时候报错
    fmt.Printf("Returned Multi Rows Not One")
}
if err == orm.ErrNoRows {
    // 没有找到记录
    fmt.Printf("Not row found")
}
```

可以指定返回的字段：

```golang
// 只返回 Id 和 Title
var post Post
o.QueryTable("post").Filter("Content__istartswith", "prefix string").One(&post, "Id", "Title")
```

<br>

#### **2.3.20 Values**

返回结果集的key -> value

key 为Model里的Field name, value的值是interface{}类型,例如，如果你要将value赋值给struct中的某字段，需要根据结构体对应字段类型使用断言获取真实值

举例:`Name : m["Name"].(string)`

返回指定的Field数据

```golang
var maps []orm.Params
num, err := o.QueryTable("user").Values(&maps)
if err == nil {
    fmt.Printf("Result Nums: %d\n", num)
    for _, m := range maps {
        fmt.Println(m["Id"], m["Name"])
    }
}
```

指定expr级联返回需要的数据

```golang
var maps []orm.Params
num, err := o.QueryTable("user").Values(&maps, "id", "name", "profile", "profile__age")
if err == nil {
    fmt.Printf("Result Nums: %d\n", num)
    for _, m := range maps {
        fmt.Println(m["Id"], m["Name"], m["Profile"], m["Profile__Age"])
        // map 中的数据都是展开的，没有复杂的嵌套
    }
}
```

<br>

#### **2.3.21 ValuesList**

返回的结果集以 slice 存储

结果的排列与Model中定义的Field顺序一致

返回的每个元素值以 string 保存

```golang
var lists []orm.ParamsList
num, err := o.QueryTable("user").ValuesList(&lists)
if err == nil {
    fmt.Printf("Result Nums: %d\n", num)
    for _, row := range lists {
        fmt.Println(row)
    }
}
```

当然可以指定expr返回指定的Field

```golang
var lists []orm.ParamsList
num, err := o.QueryTable("user").ValuesList(&lists, "name", "profile__age")
if err == nil {
    fmt.Printf("Result Nums: %d\n", num)
    for _, row := range lists {
        fmt.Printf("Name: %s, Age: %s\m", row[0], row[1])
    }
}
```

<br>

#### **2.3.22 ValuesFlat**

只返回特定的Field值，将结果集展开到单个 slice 里

```golang
var list orm.ParamsList
num, err := o.QueryTable("user").ValuesFlat(&list, "name")
if err == nil {
    fmt.Printf("Result Nums: %d\n", num)
    fmt.Printf("All User Names: %s", strings.Join(list, ", "))
}
```

<br>
 

### **2.4 关系查询**

以模型 User-Profile-Post-Tag为例讲解关系查询

<br>

#### **2.4.1 OneToOne**

user表和profile表是一对一关系，已经取得了user对象，查询profile：

```golang
user := &User{Id: 1}
o.Read(user)
if user.Profile != nil {
    o.Read(user.Profile)
}
```

直接关联查询

```golang
user := &User{}
o.QueryTable("user").Filter("Id", 1).RelatedSel().One(user)
// 自动查询到 Profile
fmt.Println(user.Profile)
// 因为在 Profile 里定义了反向关系的 User，所以 Profile 里的 User 也是自动赋值过的，可以直接取用。
fmt.Println(user.Profile.User)
// [SELECT T0.`id`, T0.`name`, T0.`profile_id`, T1.`id`, T1.`age` FROM `user` T0 INNER JOIN `profile` T1 ON T1.`id` = T0.`profile_id` WHERE T0.`id` = ? LIMIT 1000] - `1`
```

通过user反向查询profile

```golang
var profile Profile
err := o.QueryTable("profile").Filter("User__Id", 1).One(&profile)
if err == nil {
    fmt.Println(profile)
}
```

<br>

#### **2.4.2 ManyToOne**

post和user是多对一关系，也就是post的外键约束是user

```golang
type Post struct {
    Id    int
    Title string
    User  *User  `orm:"rel(fk)"`
    Tags  []*Tag `orm:"rel(m2m)"`
}
var posts []*Post
num, err := o.QueryTable("post").Filter("User", 1).RelatedSel().All(&posts)
if err == nil {
    fmt.Printf("%d posts read\n", num)
    for _, post := range posts {
        fmt.Printf("Id: %d, UserName: %d, Title: %s\n", post.Id, post.User.UserName, post.Title)
    }
}
// [SELECT T0.`id`, T0.`title`, T0.`user_id`, T1.`id`, T1.`name`, T1.`profile_id`, T2.`id`, T2.`age` FROM `post` T0 INNER JOIN `user` T1 ON T1.`id` = T0.`user_id` INNER JOIN `profile` T2 ON T2.`id` = T1.`profile_id` WHERE T0.`user_id` = ? LIMIT 1000] - `1`
```

根据 Post.Title 查询对应的 User：

RegisterModel 时，ORM 也会自动建立 User 中 Post 的反向关系，所以可以直接进行查询

```golang
var user User
err := o.QueryTable("user").Filter("Post__Title", "The Title").Limit(1).One(&user)
if err == nil {
    fmt.Printf(user)
}
```

<br>

#### **2.4.3 ManyToMany**

post和tag是多对多关系，二者存在一个中间表

```golang
type Post struct {
    Id    int
    Title string
    User  *User  `orm:"rel(fk)"`
    Tags  []*Tag `orm:"rel(m2m)"`
}
type Tag struct {
    Id    int
    Name  string
    Posts []*Post `orm:"reverse(many)"`
}
```

一条 Post 纪录可能对应不同的 Tag 纪录，一条 Tag 纪录可能对应不同的 Post 纪录，所以 Post 和 Tag 属于多对多关系，通过 tag name 查询哪些 post 使用了这个 tag

```golang
var posts []*Post
num, err := dORM.QueryTable("post").Filter("Tags__Tag__Name", "golang").All(&posts)
```

通过 post title 查询这个 post 有哪些 tag

```golang
var tags []*Tag
num, err := dORM.QueryTable("tag").Filter("Posts__Post__Title", "Introduce Beego ORM").All(&tags)
```

<br>

### **2.5 载入关系字段**

LoadRelated 用于载入模型的关系字段，包括所有的 rel/reverse - one/many 关系

ManyToMany 关系字段载入

```golang
// 载入相应的 Tags
post := Post{Id: 1}
err := o.Read(&post)
num, err := o.LoadRelated(&post, "Tags")
// 载入相应的 Posts
tag := Tag{Id: 1}
err := o.Read(&tag)
num, err := o.LoadRelated(&tag, "Posts")
```

User 是 Post 的 ForeignKey，对应的 ReverseMany 关系字段载入

```golang
type User struct {
    Id    int
    Name  string
    Posts []*Post `orm:"reverse(many)"`
}
user := User{Id: 1}
err := dORM.Read(&user)
num, err := dORM.LoadRelated(&user, "Posts")
for _, post := range user.Posts {
    //...
}
```

<br>

### **2.6 多对多关系操作**

创建一个QueryM2Mer对象：

```golang
o := orm.NewOrm()
post := Post{Id: 1}
m2m := o.QueryM2M(&post, "Tags")
// 第一个参数的对象，主键必须有值
// 第二个参数为对象需要操作的 M2M 字段
// QueryM2Mer 的 api 将作用于 Id 为 1 的 Post
```

<br>

#### **2.6.1 Add**

```golang
tag := &Tag{Name: "golang"}
o.Insert(tag)
num, err := m2m.Add(tag)
if err == nil {
    fmt.Println("Added nums: ", num)
}
```

Add支持多种类型：Tag *Tag []Tag []*Tag []interface{}

```golang
var tags []*Tag
...
// 读取 tags 以后
...
num, err := m2m.Add(tags)
if err == nil {
    fmt.Println("Added nums: ", num)
}
// 也可以多个作为参数传入
// m2m.Add(tag1, tag2, tag3)
```

<br>

#### **2.6.2 Remove**

从M2M关系中删除tag

Remove支持多种类型：Tag *Tag []Tag []*Tag []interface{}

```golang
var tags []*Tag
...
// 读取 tags 以后
...
num, err := m2m.Remove(tags)
if err == nil {
    fmt.Println("Removed nums: ", num)
}
// 也可以多个作为参数传入
// m2m.Remove(tag1, tag2, tag3)
```

<br>

#### **2.6.3 Exist**

判断tag是否存在于M2M关系中

```golang
if m2m.Exist(&Tag{Id: 2}) {
    fmt.Println("Tag Exist")
}
```

<br>

#### **2.6.4 Clear**

清除所有M2M关系

```golang
nums, err := m2m.Clear()
if err == nil {
    fmt.Println("Removed Tag Nums: ", nums)
}
```

<br>

#### **2.6.5 Count**

计算Tag的数量

```golang
nums, err := m2m.Count()
if err == nil {
    fmt.Println("Total Nums: ", nums)
}
```

<br>