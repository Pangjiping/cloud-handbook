<h1>1. ORM模型</h1>
<p>beego ORM模型是一个强大的Go语言ORM框架</p>
<p>已经支持的数据库包括MySQL、PostgreSQL、Sqlite3</p>
<p>首先需要安装ORM</p>
<pre class="language-bash"><code>go get github.com/beego/beego/v2/client/orm</code></pre>
<p>&nbsp;</p>
<p>ORM的快速入门案例：</p>
<pre class="language-go"><code>import (
	"fmt"
	"github.com/beego/beego/v2/client/orm"
	_ "github.com/go-sql-driver/mysql"
)

type User struct {
	Id   int
	Name string `orm:"size(100)"`
}

func init() {
	orm.RegisterDataBase("default",
		"mysql",
		"root:123456@tcp(127.0.0.1:3306)/db_test?charset=utf8&amp;loc=Local")
	orm.RegisterModel(new(User))
	orm.RunSyncdb("default", false, true)
}

func main() {
	o := orm.NewOrm()
	user := User{Name: "slene"}

	id, err := o.Insert(&amp;user)
	fmt.Printf("ID: %d, ERR: %v\n", id, err)

	user.Name = "astaxie"
	num, err := o.Update(&amp;user)
	fmt.Printf("NUM: %d, ERR: %v\n", num, err)

	u := User{Id: user.Id}
	err = o.Read(&amp;u)
	fmt.Printf("ERR: %v\n", err)

	num, err = o.Delete(&amp;u)
	fmt.Printf("NUM: %d, ERR: %v\n", num, err)
}</code></pre>
<p>&nbsp;</p>
<h2>1.1 关联查询</h2>
<pre class="language-go"><code>type Post struct {
    Id    int    `orm:"auto"`
    Title string `orm:"size(100)"`
    User  *User  `orm:"rel(fk)"`
}
var posts []*Post
qs := o.QueryTable("post")
num, err := qs.Filter("User__Name", "slene").All(&amp;posts)</code></pre>
<p>&nbsp;</p>
<h2>1.2 SQL查询</h2>
<p>当无法使用ORM来达到需求时，也可以直接使用SQL来完成查询、映射操作</p>
<pre class="language-go"><code>var maps []orm.Params
num, err := o.Raw("SELECT * FROM user").Values(&amp;maps)
for _,term := range maps{
    fmt.Println(term["id"],":",term["name"])
}</code></pre>
<p>&nbsp;</p>
<h2>1.3 事务操作</h2>
<pre class="language-go"><code>tx, err := o.Begin()
if err != nil {
	log.Fatal(err.Error())
}
user = User{Name: "slene"}
id, err = tx.Insert(&amp;user)
if err == nil {
	tx.Commit()
} else {
	tx.Rollback()
}</code></pre>
<p>&nbsp;</p>
<h2>1.4 调试查询日志</h2>
<p>在开发环境下，可以使用以下指令来开启查询调试模式：</p>
<pre class="language-go"><code>func main() {
    orm.Debug = true
...</code></pre>
<p>&nbsp;</p>
<p>开启后将会输出所有查询语句，包括执行、准备、事务等</p>
<p>例如：</p>
<pre class="language-bash"><code>[ORM] - 2013-08-09 13:18:16 - [Queries/default] - [    db.Exec /     0.4ms] -     [INSERT INTO `user` (`name`) VALUES (?)] - `slene`
...</code></pre>
<p>&nbsp;</p>
<h1>2. ORM的使用</h1>
<h2>2.1 表模型</h2>
<p>models.go定义了表模型，我们会在main.go中将其注册到数据库中</p>
<pre class="language-go"><code>type User struct {
	Id      int
	Name    string
	Profile *Profile `orm:"rel(one)"`      // OneToOne relation
	Post    []*Post  `orm:"reverse(many)"` // 设置一对多的反向关系
}
type Profile struct {
	Id   int
	Age  int16
	User *User `orm:"reverse(one)"` // 设置一对一反向关系(可选)
}
type Post struct {
	Id    int
	Title string
	User  *User  `orm:"rel(fk)"` //设置一对多关系
	Tags  []*Tag `orm:"rel(m2m)"`
}
type Tag struct {
	Id    int
	Name  string
	Posts []*Post `orm:"reverse(many)"` //设置多对多反向关系
}</code></pre>
<p>&nbsp;</p>
<p>init()方法，将表注册到数据库</p>
<pre class="language-go"><code>var o orm.Ormer

func init() {
	orm.RegisterDriver("mysql", orm.DRMySQL)

	// 注册数据库
	orm.RegisterDataBase("default", "mysql", "root:123456@(123.57.33.149:3306)/orm_test?charset=utf8")

	// 注册模型，对于使用orm.QuerySeter进行高级查询是必须的
	orm.RegisterModel(new(User), new(Profile), new(Post), new(Tag))

	// 使用表名前缀和后缀
	//orm.RegisterModelWithPrefix("prefix_", new(User))
	//orm.RegisterModelWithSuffix("_suffix", new(User))

	// 自动建表
	orm.RunSyncdb("default", true, true)

	// 最大连接数
	orm.SetMaxOpenConns("default", 30)

	// 最大空闲连接
	orm.SetMaxIdleConns("default", 30)

	// 设置时区
	orm.DefaultTimeLoc = time.UTC

	// 初始化ormer
	o = orm.NewOrm()

	// 初始化数据
	datainit()
}</code></pre>
<p>&nbsp;</p>
<p>我们关注其中几个函数：</p>
<ul>
<li><code>orm.RegisterDriver()</code>注册数据库驱动。第一个参数为driverName；第二个参数为数据库类型</li>
<li><code><span class="pln">orm</span><span class="pun">.</span><span class="typ">RegisterDataBase()</span></code>注册数据库。第一个参数为数据库的别名；第二个参数为driveName；第三个参数为数据库连接URL</li>
<li><code><span class="pln">orm</span><span class="pun">.</span><span class="typ">SetMaxIdleConns()</span></code>根据数据库的别名，设置最大空闲连接数</li>
<li><code><span class="pln">orm</span><span class="pun">.</span><span class="typ">SetMaxOpenConns()</span></code>根据数据库的别名，设置最大连接数</li>
<li><code><span class="pln">orm</span><span class="pun">.</span><span class="typ">DefaultTimeLoc</span></code>设置时区</li>
<li><code><span class="pln">orm</span><span class="pun">.</span><span class="typ">RegisterModel()</span></code>注册数据库模型，需要传入指针类型，一般就是<code>new(Type)</code>，数据库名称默认结构体的小写</li>
<li><code><span class="pln">orm</span><span class="pun">.</span><span class="typ">RegisterModelWithPrefix()</span></code>使用表名前缀，比如prefix_user</li>
<li><code>orm.RunSyncdb("default", true, true)</code>数据库同步。第一个参数为数据库别名；第二个参数为true时会自动建表，但如果表存在的话会被覆盖；第三个参数是否更新表</li>
<li><code>orm.NewOrm()</code>初始化一个orm对象，默认是全局唯一的</li>
</ul>
<p>&nbsp;</p>
<p>看起来orm的标签挺抽象的，我们可以简单看一下表结构是什么</p>
<p>首先是user表：</p>
<pre class="language-bash"><code>mysql&gt; desc user;
+------------+--------------+------+-----+---------+----------------+
| Field      | Type         | Null | Key | Default | Extra          |
+------------+--------------+------+-----+---------+----------------+
| id         | int          | NO   | PRI | NULL    | auto_increment |
| name       | varchar(255) | NO   |     |         |                |
| profile_id | int          | NO   | UNI | NULL    |                |
+------------+--------------+------+-----+---------+----------------+
3 rows in set (0.00 sec)
</code></pre>
<p>我们可以得出几个关键信息：</p>
<ul>
<li>Id就是自增主键</li>
<li><code>`orm:"rel(one)"`</code>的含义就是profile表的ID是user表的唯一索引，即二者是一对一关系，可以理解为一个用户只有一个账户信息</li>
<li>user表中的<code>`orm:"rel(one)"`</code>和profile表中的<code>`orm:"reverse(one)"`</code>应该成对出现（optional）</li>
</ul>
<p>&nbsp;</p>
<p>然后再看profile表：</p>
<pre class="language-bash"><code>mysql&gt; desc profile;
+-------+----------+------+-----+---------+----------------+
| Field | Type     | Null | Key | Default | Extra          |
+-------+----------+------+-----+---------+----------------+
| id    | int      | NO   | PRI | NULL    | auto_increment |
| age   | smallint | NO   |     | 0       |                |
+-------+----------+------+-----+---------+----------------+
2 rows in set (0.01 sec)</code></pre>
<p>看起来profile没有任何来自其他表的约束，而我们在go中写的一个标签<code>`orm:"reverse(one)"`</code>应该就是和<code>`orm:"rel(one)"`</code>成对使用的</p>
<p>&nbsp;</p>
<p>然后看post表：</p>
<pre class="language-bash"><code>mysql&gt; desc post;
+---------+--------------+------+-----+---------+----------------+
| Field   | Type         | Null | Key | Default | Extra          |
+---------+--------------+------+-----+---------+----------------+
| id      | int          | NO   | PRI | NULL    | auto_increment |
| title   | varchar(255) | NO   |     |         |                |
| user_id | int          | NO   |     | NULL    |                |
+---------+--------------+------+-----+---------+----------------+
3 rows in set (0.00 sec)</code></pre>
<p>看起来是和user表存在外联约束，所以猜测<code>`orm:"rel(fk)"`</code>就是外键约束</p>
<p>而且一个user_id可以对应多个post，即一个用户可以拥有多个邮件，所以二者的对应关系应该是一对多的，所以这里user_id不是唯一索引</p>
<p>&nbsp;</p>
<p>最后是tag表：</p>
<pre class="language-bash"><code>mysql&gt; desc tag;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int          | NO   | PRI | NULL    | auto_increment |
| name  | varchar(255) | NO   |     |         |                |
+-------+--------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)
</code></pre>
<p>看起来没有任何约束，所以<code>`orm:"rel(m2m)"`</code>和<code>`orm:"reverse(many)"`</code>到底干啥用的？？</p>
<p>注意：最新的orm包中<code>`orm:"rel(m2m)"`</code>会报错！测试的话选择另一个orm --"github.com/astaxie/beego/orm"</p>
<p>更新了依赖之后我们重新生成了数据库模型，会发现比之前多个一个表，就是<code>`orm:"rel(m2m)"`</code>对应的表！</p>
<pre class="language-bash"><code>mysql&gt; show tables;
+--------------------+
| Tables_in_orm_test |
+--------------------+
| post               |
| post_tags          |
| profile            |
| tag                |
| user               |
+--------------------+
5 rows in set (0.00 sec)</code></pre>
<p>&nbsp;</p>
<p>我们都知道多对多关系下，关联两个表是需要一个中间表的，其实这个表 post_tags 就是一个中间表</p>
<pre class="language-bash"><code>mysql&gt; desc post_tags;
+---------+--------+------+-----+---------+----------------+
| Field   | Type   | Null | Key | Default | Extra          |
+---------+--------+------+-----+---------+----------------+
| id      | bigint | NO   | PRI | NULL    | auto_increment |
| post_id | int    | NO   |     | NULL    |                |
| tag_id  | int    | NO   |     | NULL    |                |
+---------+--------+------+-----+---------+----------------+
3 rows in set (0.00 sec)</code></pre>
<p>&nbsp;</p>
<p>&nbsp;</p>
<h2>2.2 ORM接口</h2>
<h3>2.2.1 QueryTable</h3>
<p>传入一个表名或者Model对象，返回一个QuerySeter</p>
<pre class="language-go"><code>o := orm.NewOrm()
var qs orm.QuerySeter
qs = o.QueryTable("user")
// 如果表没有定义过，会立刻 panic</code></pre>
<p>&nbsp;</p>
<h3>2.2.2 Raw</h3>
<p>使用sql语句直接进行操作</p>
<p>Raw函数，返回一个Rawseter用以对设置的sql语句和参数进行操作</p>
<pre class="language-go"><code>o := orm.NewOrm()
var r orm.RawSeter
r = o.Raw("UPDATE user SET name = ? WHERE name = ?", "testing", "slene")
r.Exec()</code></pre>
<p>&nbsp;</p>
<h3>2.2.3 Driver</h3>
<p>返回当前ORM使用的db信息</p>
<pre class="language-go"><code>type Driver interface {
    Name() string
    Type() DriverType
}</code></pre>
<pre class="language-go"><code>orm.RegisterDataBase("db1", "mysql", "root:root@/orm_db2?charset=utf8")
orm.RegisterDataBase("db2", "sqlite3", "data.db")
o1 := orm.NewOrmUsingDB("db1")
dr := o1.Driver()
fmt.Println(dr.Name() == "db1") // true
fmt.Println(dr.Type() == orm.DRMySQL) // true
o2 := orm.NewOrmUsingDB("db2")
dr = o2.Driver()
fmt.Println(dr.Name() == "db2") // true
fmt.Println(dr.Type() == orm.DRSqlite) // true</code></pre>
<p>&nbsp;</p>