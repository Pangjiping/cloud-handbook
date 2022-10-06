<p>首先需要导入依赖</p>
<pre class="language-bash"><code>go get gopkg.in/amz.v1/aws
go get gopkg.in/amz.v1/s3</code></pre>
<p>&nbsp;</p>
<h2>1. 初始化ceph连接</h2>
<p>在初始化连接之前，我们需要创建一个用户得到accessKey和secretKey，新增用户的指令如下：</p>
<pre class="language-bash"><code>docker exec ceph-rgw radosgw-admin user create --uid="test" --display-name="test user"</code></pre>
<p>&nbsp;</p>
<p>下面就是初始化ceph客户端的操作，和一些数据库的连接一样的，都是授权+地址：</p>

```golang
func init() {
	auth := aws.Auth{
		AccessKey: accessKey,
		SecretKey: secretKey,
	}

	region := aws.Region{
		Name:                 "default",
		EC2Endpoint:          url, // "http://&lt;ceph-rgw ip&gt;:&lt;ceph-rgw port&gt;"
		S3Endpoint:           url,
		S3BucketEndpoint:     "",    // Not needed by AWS S3
		S3LocationConstraint: false, // true if this region requires a LocationConstraint declaration
		S3LowercaseBucket:    false, // true if the region requires bucket names to be lower case
		Sign:                 aws.SignV2,
	}

	CephConn = s3.New(auth, region)
}
```

<p>下面是针对ceph的一些简单操作，因为项目原因只需要一些文件上传下载的操作，其他操作可以参见amz.v1的doc</p>
<p>&nbsp;</p>
<h2>2. 获取一个桶</h2>

```golang
func GetCephBucket(bucket string) *s3.Bucket {
    return CephConn.Bucket(bucket)
}
```
<p>&nbsp;</p>
<h2>3. 将本地文件上传到ceph的一个bucket中</h2>

```golang
func put2Bucket(bucket *s3.Bucket, localPath, cephPath string) (*s3.Bucket, error) {
    err := bucket.PutBucket(s3.PublicRead)
    if err != nil {
        log.Fatal(err.Error())
        return nil, err
    }

    bytes, err := ioutil.ReadFile(localPath)
    if err != nil {
        log.Fatal(err.Error())
        return nil, err
    }

    err = bucket.Put(cephPath, bytes,  "octet-stream" , s3.PublicRead)
    return bucket, err
}
```

<h2>4. 从ceph下载文件</h2>

```golang
func downloadFromCeph(bucket *s3.Bucket, localPath, cephPath string) error {
    data, err := bucket.Get(cephPath)
    if err != nil {
        log.Fatal(err.Error())
        return err
    }
    return ioutil.WriteFile(localPath, data, 0666)
}
```
<p>&nbsp;</p>
<h2>5. 删除指定的文件</h2>

```golang
func delCephData(bucket *s3.Bucket, cephPath string) error {
    err := bucket.Del(cephPath)
    if err != nil {
        log.Fatal(err.Error())
    }
    return err
}
```

<p>&nbsp;</p>
<h2>6. 删除桶</h2>
<p>删除桶时要保证桶内文件已经被删除</p>

```golang
func delBucket(bucket *s3.Bucket) error {
    err := bucket.DelBucket()
    if err != nil {
        log.Fatal(err.Error())
    }
    return err
}
```
<p>&nbsp;</p>
<h2>7. 批量获取文件信息</h2>

```golang
func getBatchFromCeph(bucket *s3.Bucket, prefixCephPath string) []string {
    maxBatch := 100

    // bucket.List() 返回桶内objects的信息，默认1000条
    resultListResp, err := bucket.List(prefixCephPath,  "" ,  "" , maxBatch)
    if err != nil {
        log.Fatal(err.Error())
        return nil
    }

    keyList := make([]string, 0)
    for _, key :=  range resultListResp.Contents {
        keyList = append(keyList, key.Key)
    }

    return keyList
}
```

<h2>&nbsp;</h2>
<h2>8. 测试</h2>
<p>编写一个main.go来测试这些接口，尝试上传和下载一个文件</p>

```golang
func main() {
    bucketName := "bucket_test"
    filename := "C:\\Users\\dell\\Desktop\\ieee.jpg"
    cephPath := "/static/default/bucket_test/V1/" + "ieee_ceph.jpg"

    // 获取指定桶
    bucket := GetCephBucket(bucketName)

    // 上传
    bucket, err := put2Bucket(bucket, filename, cephPath)
    if err != nil {
        return
    }

    // 下载
    localPath := "C:\\Users\\dell\\Desktop\\download.jpg"
    err = downloadFromCeph(bucket, localPath, cephPath)
    if err != nil {
        return
    }

    // 获得url
    url := bucket.SignedURL(cephPath, time.Now().Add(time.Hour))
    fmt.Println(url)

    // 批量查找
    prefixCephpath := "static/default/bucket_test/V1"
    lists := getBatchFromCeph(bucket, prefixCephpath)
    for _, list :=  range lists {
        fmt.Println(list)
    }

    // 删除数据
    delCephData(bucket, cephPath)

    // 删除桶
    delBucket(bucket)

}
```

<p>&nbsp;</p>
<h2>9. 上传ceph的简单优化</h2>
<p>选择将本地服务器文件上传ceph应该是异步操作，无论是采用chan通知一个上传的协程还是晚上的定时任务</p>
<p>异步任务的操作可以选择简单的chan，或者使用消息队列，如果吞吐量大的情况下就要使用rabbitmq等消息中间件了</p>