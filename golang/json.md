# **golang自定义json序列化规则**

golang中的原生包`endcoding/json`提供了序列化和反序列化json数据的功能

我们可以使用`encoding/json`中的`Encoder.Encode()`和`Marshal()`实现json序列化；使用`Decoder.Decode()`和`Unmarshal()`实现json反序列化

```golang
type Metric struct {
	Name  string `json:"name"`
	Value int64  `json:"value"`
}
 
func main() {
	_ = json.NewEncoder(os.Stdout).Encode(
		[]*Metric{
			{"vv", 12},
			{"tz", 9},
			{"ss", 89},
		},
	)
}
```

输出结果为：

```bash
$ go run main.go
[{"name":"vv","value":12},{"name":"tz","value":9},{"name":"ss","value":89}]
```

在上述代码中，结构体`Metric`代表了一个待序列化的结构体，我们只需要生成一个encoder就可以将其序列化为json格式数据

如果存在这样一种情况，我们需要接收另外一个进程传入的json数据，进行反序列化，我们都知道json反序列化到指定结构体时，需要遵循这个结构体对数据类型的定义

比如上述的`Metric`结构体两个数据类型分别为string和int64，如果我们传入一个浮点数，将会发生什么？

```golang
func main() {
	var metric Metric
	err := json.Unmarshal([]byte(`{"name":"tq","value":1.1}`), &metric)
	if err != nil {
		panic(err)
	}
	fmt.Println(metric)
}
```

很显然会panic(err)，因为我们的数据类型不匹配，当然通常情况下在程序设计是是不会出现这种情况的，但是如果发生这种情况，如何在不修改`Metric`结构体定义的情况下成功反序列化这条json数据呢？

在encoding/json包中有两个非常重要的接口：

```golang
// Marshaler is the interface implemented by types that
// can marshal themselves into valid JSON.
type Marshaler interface {
 MarshalJSON() ([]byte, error)
}
 
// Unmarshaler is the interface implemented by types
// that can unmarshal a JSON description of themselves.
// The input can be assumed to be a valid encoding of
// a JSON value. UnmarshalJSON must copy the JSON data
// if it wishes to retain the data after returning.
//
// By convention, to approximate the behavior of Unmarshal itself,
// Unmarshalers implement UnmarshalJSON([]byte("null")) as a no-op.
type Unmarshaler interface {
 UnmarshalJSON([]byte) error
}
```

如果任意自定义类型实现了`Marshaler`或者`Unmarshaler`接口，就能实现自定义的序列化或者反序列化规则

对于上面反序列化失败的情况，我们可以让`Metric`结构体实现`Unmarshaler`接口，就可以实现自定义的反序列化规则：

```golang
func (m *Metric) UnmarshalJSON(data []byte) error {
	type AliasMetric Metric
	t := &struct {
		Value float64 `json:"value"`
		*AliasMetric
	}{
		Value:       float64(m.Value),
		AliasMetric: (*AliasMetric)(m),
	}
 
	if err := json.Unmarshal(data, &t); err != nil {
		return err
	}
	m.Value = int64(t.Value)
	return nil
}
```

核心思想就是以结构体新类型，让新类型获得原始结构体的所有字段属性，但是却不会继承原有结构体的方法

我们就可以将浮点数序列化到`Metric`结构体中，当然会存在数据丢失的情况，因为传入浮点数本身就是不合理的，这么做只是为了增强程序的健壮性

```golang
func main() {
	metric := &Metric{}
	//err := json.Unmarshal([]byte(`{"name":"tq","value":1.1}`), &metric)
	if err := metric.UnmarshalJSON([]byte(`{"name":"tq","value":1.1}`)); err != nil {
		panic(err)
	}
	fmt.Println(*metric)
}
```

输出结果为：

```golang
$ go run main.go
{tq 1}
```