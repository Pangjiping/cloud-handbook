<h1>1. Token-based Authentication</h1>
<p>在这种验证机制中，用户第一次登录需要POST自己的用户名和密码，在服务器端检验用户名和密码正确之后，就可以签署一个令牌，并将其返回给客户端</p>
<p>在此之后，客户端就可以用这个access_token来访问服务器上的资源，服务器只会验证该令牌是否有效</p>
<p>同时，access_token有一定的生命周期，在这个周期内，客户端都可以通过这个token来访问服务器的资源</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220401104913151-1077069947.png" alt="" width="707" height="409" loading="lazy" /></p>
<p>&nbsp;</p>
<h1>2. JWT</h1>
<p>&nbsp;JWT -- JSON Web Token</p>
<p>&nbsp;</p>
<h2>2.1 JWT简介</h2>
<p>JWT是一个base64编码的字符串，主要由三部分组成：</p>
<ul>
<li>header</li>
<li>payload</li>
<li>verify signature</li>
</ul>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220401105308317-521770516.png" alt="" width="692" height="363" loading="lazy" /></p>
<p>&nbsp;</p>
<p>其中header和payload是base64编码的，而没有加密，这意味着我们可以编码或者解码任意的payload，但是最后的蓝色部分，也就是JWT签名，保证了只有服务器有私钥来签署这个token</p>
<p>JWT提供了很多签名算法，可以分为以下几类：</p>
<ul>
<li>对称秘钥加密算法：适用于共享秘钥的场景，本地，典型的算法有：HS256、HS384、HS512</li>
<li>非对称加密算法：私钥对token签名，公钥验证token，可以提供第三方服务，典型的算法有：RS256、PS256、ES256等</li>
</ul>
<p>&nbsp;</p>
<p>JWT的问题是什么？</p>
<p>（1）不安全的加密算法</p>
<p>　　JWT给开发者提供了很多的加密算法选择，其中就包括了已知的易受攻击的算法</p>
<p>&nbsp;（2）在header中包含了签名算法的种类</p>
<p>　　攻击者只需要将header中的alg字段设置为none就可以绕过签名验证过程</p>
<p>　　在知道服务器使用非对称加密算法的情况下，修改alg为一个对称加密算法</p>
<p>&nbsp;</p>
<h2>2.2 在golang中实现JWT</h2>
<p>首先我们定义一个token maker的接口，在之后会使用PASETO和JWT来实现这个接口</p>
<p>Maker接口包括了两个方法，分别是创建token和验证token：</p>

```golang
type Maker interface {
	// CreateToken 创建一个token
	CreateToken(username string, duration time.Duration) (string, error)
	// VerifyToken 验证token
	VerifyToken(token string) (*Payload, error)
}
```
<p>　　</p>
<p>现在定义token的payload结构体，其中应该包含一些我们需要的字段，一般意义上就是用户名、创建时间、过期时间、tokenID这几个信息：</p>

```golang
type Payload struct {
	ID        uuid.UUID `json:"id" `
	Username  string    `json:"username" `
	IssuedAt  time.Time `json:"issued_at" `
	ExpiredAt time.Time `json:"expired_at" `
}
```

<p>&nbsp;</p>
<p>然后对外提供一个创建payload的函数：</p>

```golang
func NewPayload(username string, duration time.Duration) (*Payload, error) {
	tokenID, err := uuid.NewRandom()
	if err != nil {
		return nil, err
	}

	payload := &amp;Payload{
		ID:        tokenID,
		Username:  username,
		IssuedAt:  time.Now(),
		ExpiredAt: time.Now().Add(duration),
	}
	return payload, nil
}
```
<p>　　</p>
<p>现在我们就可以开始实现JWT token的代码了，其需要实现Maker接口定义的两个方法</p>

```golang
func (maker *JWTMaker) CreateToken(username string, duration time.Duration) (string, error) {
	payload, err := NewPayload(username, duration)
	if err != nil {
		return "", err
	}

	jwtToken := jwt.NewWithClaims(jwt.SigningMethodHS256, payload)
	return jwtToken.SignedString([]byte(maker.secretKey))
}
```
<p>&nbsp;</p>
<p>值得注意的是，在jwt.NewWithClaims()方法中，我们传入payload时会报错，仔细看提示会发现jwt需要我们定义的payload结构体提供一个验证功能，就是一个 func(payload *Payload) Valid() error 签名的函数</p>
<p>我们就可以做一个简单的过期时间验证：</p>

```golang
func (payload *Payload) Valid() error {
    if time.Now().After(payload.ExpiredAt) {
        return ErrExpiredToken
    }
    return nil
}
```

<p>&nbsp;</p>
<p>同样，我们再去实现验证token的方法：</p>

```golang
func (maker *JWTMaker) VerifyToken(token string) (*Payload, error) {
	keyFunc := func(token *jwt.Token) (interface{}, error) {
		_, ok := token.Method.(*jwt.SigningMethodHMAC)
		if !ok {
			return nil, ErrInvalidToken
		}
		return []byte(maker.secretKey), nil
	}
	jwtToken, err := jwt.ParseWithClaims(token, &amp;Payload{}, keyFunc)
	if err != nil {
		verr, ok := err.(*jwt.ValidationError)
		if ok &amp;&amp; errors.Is(verr.Inner, ErrExpiredToken) {
			return nil, ErrExpiredToken
		}
		return nil, ErrInvalidToken
	}

	payload, ok := jwtToken.Claims.(*Payload)
	if !ok {
		return nil, ErrInvalidToken
	}
	return payload, nil
}
```

<p>&nbsp;</p>
<p>&nbsp;在 jwtToken, err := jwt.ParseWithClaims(token, &amp;Payload{}, keyFunc)&nbsp;中</p>
<p>keyFunc需要我们自己实现，其作用是验证header中的签名算法是否合法，防止一些琐碎的攻击</p>
<p>同样err在jwt包内部是被隐藏的，对于验证失败的令牌有两种情况：令牌过期或者令牌不合法</p>
<p>所以我们需要做一次类型断言，找出具体的错误来做返回</p>
<p>&nbsp;</p>
<h1>3. PASETO</h1>
<p>PASETO -- Platform-Agnostic SEcurity TOkens</p>
<p>&nbsp;</p>
<h2>3.1 PASETO简介</h2>
<p>每一个版本的PASETO都包含了强大的加密套件，选择对应的加密算法只需要选择PASETO版本即可</p>
<p>最多只能有两个版本同时处于活跃状态</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220401111020952-116029723.png" alt="" width="757" height="200" loading="lazy" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>相比于JWT，PASETO所做的改变在于：</p>
<ul>
<li>不会向用户开放所有的加密算法</li>
<li>header中不再含有alg字段，也不会有none算法</li>
<li>payload使用加密算法，而不是简单的编码</li>
</ul>
<p>&nbsp;</p>
<p>PASETO的令牌结构：</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220401111449685-754752739.png" alt="" width="749" height="374" loading="lazy" />&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<h2>3.2 在golang中实现PASETO</h2>
<p>PASETO的实现要比JWT简单一些，我们同样还是使用对称加密算法来实现，首先是创建token的方法：</p>

```golang
func (maker *PasetoMaker) CreateToken(username string, duration time.Duration) (string, error) {
	payload, err := NewPayload(username, duration)
	if err != nil {
		return "", err
	}
	return maker.paseto.Encrypt(maker.symmetricKey, payload, nil)
}
```

<p>　　</p>
<p>然后是验证token：</p>

```golang
func (maker *PasetoMaker) VerifyToken(token string) (*Payload, error) {
	payload := &amp;Payload{}

	if err := maker.paseto.Decrypt(token, maker.symmetricKey, payload, nil); err != nil {
		return nil, ErrInvalidToken
	}
	if err := payload.Valid(); err != nil {
		return nil, err
	}

	return payload, nil
}
```

<p>　　</p>
<p>至此我们就完成了PASETO对称加密的token</p>
<p>&nbsp;</p>
<h1>4. 实现token验证中间件</h1>
<p>首先客户端需要提供登录信息，包括了用户名和密码。然后服务器创建一个token返回给客户端，用于之后的身份验证</p>

```golang
const (
	authorizationHeaderKey  = "authorization"
	authorizationTypeBearer = "bearer"
	authorizationPayloadKey = "authorization_payload"
)

func authMiddleware(tokenMaker Maker) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		authorizationHeader := ctx.GetHeader(authorizationHeaderKey)
		if len(authorizationHeader) == 0 {
			err := errors.New("authorization header is not provide")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err})
			return
		}

		fields := strings.Fields(authorizationHeader)
		if len(fields) &lt; 2 {
			err := errors.New("invalid authorization header format")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err})
			return
		}

		authorizationType := strings.ToLower(fields[0])
		if authorizationType != authorizationTypeBearer {
			err := fmt.Errorf("unsupported authorization type %s", authorizationType)
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err})
			return
		}

		accessToken := fields[1]
		payload, err := tokenMaker.VerifyToken(accessToken)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err})
			return
		}

		ctx.Set(authorizationPayloadKey, payload)
		ctx.Next()
	}
}
```

<p>　　</p>
<p>然后我们可以将需要授权的api做一个路由组，使用这个中间件</p>
<p>同时我们在授权阶段可以简单的使用一个ctx.MustGet()方法来取得token中的payload，里面包含有用户名的验证信息，这样就可以保证用户只可以访问自己的相关内容</p>