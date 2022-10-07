<h1>1. 什么是sqlc？</h1>
<p>google sqlc doc可以看到sqlc官网对于自己的定位，其主要作用就是从SQL生成可直接调用的go接口</p>
<p>我们使用sqlc可以简单分为以下三个步骤：</p>
<ul>
<li>写SQL</li>
<li>run sqlc生成我们所需要的go查询接口</li>
<li>使用这些接口与数据库交互</li>
</ul>
<p>sqlc doc：https://docs.sqlc.dev/en/stable/index.html</p>
<p>&nbsp;</p>
<h1>2. sqlc安装</h1>
<p>macos安装</p>
<pre class="language-bash"><code>brew install sqlc</code></pre>
<p>&nbsp;</p>
<p>go install (go version&gt;=1.17)</p>
<pre class="language-bash"><code>go install github.com/kyleconroy/sqlc/cmd/sqlc@latest</code></pre>
<p>&nbsp;</p>
<p>ubuntu</p>
<pre class="language-bash"><code>sudo snap install sqlc</code></pre>
<p>&nbsp;</p>
<p>docker（这种工具安装在docker上启动有些不方便）</p>
<pre class="language-bash"><code>docker pull kjconroy/sqlc</code></pre>
<p>&nbsp;</p>
<h1>3. 从SQL到golang code</h1>
<p>现在sqlc支持的数据库包括了MySQL和PostgreSQL，用法基本是一样的，下面我们就以postgres来看怎样让sqlc为我们生成sql查询的go code</p>
<p>首先我们cd到项目文件主目录，执行下面的指令生成sqlc.yaml文件，这个文件会配置一些sqlc的信息</p>
<pre class="language-bash"><code>sqlc init</code></pre>
<p>&nbsp;</p>
<p>在yaml文件中我们可以编写一些sqlc的初始化配置信息：</p>
<pre class="language-yaml"><code>version: "1"
packages:
  - name: "db"                 # package name
    path: "./db/sqlc"          # 生成的go code路径
    queries: "./db/query/"     # sql语句路径
    schema: "./db/migration/"  # 数据库架构
    engine: "postgresql"       # 什么数据库
    emit_json_tags: true
    emit_prepared_queries: false
    emit_interface: true       #生成一个所有query的接口文档
    emit_exact_table_names: false
    emit_empty_slices: true</code></pre>
<p>&nbsp;</p>
<p>当然在写ymal文件之前，我们需要做好一些准备工作：</p>
<ul>
<li>创建上面用到的所有文件目录</li>
<li>创建数据库架构文件</li>
</ul>
<p>&nbsp;</p>
<p>然后我们就可以在query目录下编写我们需要的SQL语句了，让我们看看使用sqlc和我们自己写正常的sql有什么区别？</p>
<p>看官网的一个案例：</p>
<pre class="language-sql"><code>-- name: GetAuthor :one
SELECT * FROM authors
WHERE id = $1 LIMIT 1;

-- name: ListAuthors :many
SELECT * FROM authors
ORDER BY name;

-- name: CreateAuthor :one
INSERT INTO authors (
  name, bio
) VALUES (
  $1, $2
)
RETURNING *;

-- name: DeleteAuthor :exec
DELETE FROM authors
WHERE id = $1;</code></pre>
<p>我们可以看到这和我们自己写sql并无不同，最大的区别就是每一句sql上面都会有一个注释</p>
<p>name: 后面的是我们要生成的那个go查询接口的方法名，再后后面的one、many、exec都有不同的含义：</p>
<ul>
<li>one：只有一个返回值</li>
<li>many：多个返回值</li>
<li>exec：没有返回值</li>
</ul>
<p>&nbsp;</p>
<p>好了，我们现在知道query.sql的简单编写规则了，我们可以根据自己的需求去修改：</p>
<pre class="language-sql"><code>-- name: CreateEntry :one
INSERT INTO entries (
  account_id,
  amount
) VALUES (
  $1, $2
) RETURNING *;

-- name: GetEntry :one
SELECT * FROM entries
WHERE id = $1 LIMIT 1;

-- name: ListEntries :many
SELECT * FROM entries
WHERE account_id = $1
ORDER BY id
LIMIT $2
OFFSET $3;</code></pre>
<p>可以看到我需要三个接口：</p>
<ul>
<li>CreateEntry：向entries表中插入数据，传入参数为account_id, amount，返回值是我们插入的这条数据</li>
<li>GetEntry：获取指定id的信息，传入参数为id，返回值是我们需要的这一条信息</li>
<li>ListEntries：获取一个account_id下多条转账信息，传入参数是account_id, limit, offest，返回值是多条符合要求的数据</li>
</ul>
<p>&nbsp;</p>
<p>现在让我们生成需要go code</p>
<pre class="language-bash"><code>sqlc generate</code></pre>
<p>&nbsp;</p>
<p>现在可以在db/sqlc文件夹下查看生成的go code</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220322102501786-1120887521.png" alt="" width="738" height="418" loading="lazy" /></p>
<p>&nbsp;</p>
<p>其实除了我们需要的entry.sql.go，还会生成三个.go文件，可以简单看一下里面都是些什么内容：</p>
<p>db.go：初始化了一个Queries结构，我们需要传入一个自己的db连接对象</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220322102933845-482471177.png" alt="" width="731" height="414" loading="lazy" /></p>
<p>models.go：就是将我们每个表的字段都做了一次结构体的封装</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220322103245931-1217449582.png" alt="" width="724" height="410" loading="lazy" /></p>
<p>querier.go：定义一个接口，封装所有的sql查询接口</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220322103406624-352253381.png" alt="" width="723" height="410" loading="lazy" />&nbsp;</p>
<p>entry.sql.go：用go实现了我们刚才写的那些sql语句，一些输入和输出结构都用了struct来定义</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220322102744273-580441242.png" alt="" width="739" height="464" loading="lazy" /></p>
<p>&nbsp;</p>
<p>至此我们就完全可以用go来与数据库实现交互了，sqlc的优势也很明显了，我们只需要写sql，而不需要关心go如何与sql进行交互的</p>
<p>同时sqlc还支持了语法错误的判断，而不存在我们在运行程序是因为sql出错而panic的情况</p>