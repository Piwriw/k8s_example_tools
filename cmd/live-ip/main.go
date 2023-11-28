package main

import (
	"live-ip/utils"
	"log"
	"net"
	"sync"
	"time"

	"github.com/pkg/errors"
)

type TcpScaner struct {
	Zone           string
	Subnet         string
	Ports          []string
	Timeout        string
	Limit          int
	ReachableIps   []string
	UnreachableIps []string
	WG             sync.WaitGroup
	Lock           sync.Mutex
}

func NewTcpScaner(zone, subnet string, ports []string, limit int) *TcpScaner {
	return &TcpScaner{
		Zone:           zone,
		Subnet:         subnet,
		Ports:          ports,
		Limit:          limit,
		ReachableIps:   make([]string, 0),
		UnreachableIps: make([]string, 0),
	}
}

func (ts *TcpScaner) StoreUnreachableIps(ip string) {
	ts.Lock.Lock()
	ts.UnreachableIps = append(ts.UnreachableIps, ip)
	ts.Lock.Unlock()
}

func (ts *TcpScaner) StoreReachableIps(ip string) {
	ts.Lock.Lock()
	ts.ReachableIps = append(ts.ReachableIps, ip)
	ts.Lock.Unlock()
}

func (ts *TcpScaner) Scan() error {
	ips, err := utils.SubNetGet(ts.Subnet)
	if err != nil {
		return errors.Wrap(err, "解析网段失败，请提供类似 192.168.1.0/24 格式的网段。")
	}
	// 利用 channel 限速
	limit := make(chan bool, ts.Limit)

	// 循环取 ip ，再循环对给定的 port 探测
	for _, ip := range ips {
		limit <- true
		ts.WG.Add(1)
		go func(ip string, wg *sync.WaitGroup) {
			// 每个端口都失败，则主机不存在，只要有一个成功就是主机存活的
			errResult := make([]error, 0)
			okResult := make([]bool, 0)
			for _, port := range ts.Ports {
				ok, err := tcpAlive(ip + ":" + port)
				if err != nil {
					errResult = append(errResult, err)
				}
				okResult = append(okResult, ok)
			}
			if len(errResult) == len(ts.Ports) {
				ts.StoreUnreachableIps(ip)
			}
			for _, o := range okResult {
				if o {
					ts.StoreReachableIps(ip)
					continue
				}
			}
			wg.Done()
			<-limit
		}(ip, &ts.WG)
	}
	ts.WG.Wait()

	log.Printf("探测局域网 ip 完成， 机器总共有 %v 台。\n", len(ts.ReachableIps))
	return nil
}

//func (ts *TcpScaner) Upload() {
//	ctx := context.Background()
//	// 拿到 redis 连接
//	conn := common.DB
//	defer conn.Close()
//
//	// 数据组合，zone 区域标识 + 地区指定的所有 ips
//	data := map[string][]string{
//		ts.Zone: ts.ReachableIps,
//	}
//
//	// 转成 []byte 存入 redis
//	bdata, _ := json.Marshal(data)
//
//	err := conn.Publish(ctx, "idc:subnet:ips", bdata).Err()
//
//	if err != nil {
//		errors.Wrapf(err, "redis 写入失败： %s", err.Error())
//	}
//	log.Println("已将机器组信息上传至 redis 服务器。")
//}

// 扫描 ip 和传入 redis
//func (ts *TcpScaner) ScanAndUpload() {
//	err := ts.Scan()
//	if err != nil {
//		errors.Wrapf(err, "扫描 ip 失败： %s", err.Error())
//	}
//	ts.Upload()
//}

// tcp 探测
func tcpAlive(ip string) (bool, error) {
	tcpTimeOut, err := time.ParseDuration("1s")
	if err != nil {
		panic(err)
	}
	conn, err := net.DialTimeout("tcp", ip, tcpTimeOut)
	if err != nil {
		return false, errors.Wrapf(err, "%s tcp 探测失败: %s", ip, err.Error())
	}
	conn.Close()
	return true, nil
}
func main() {
	scaner := NewTcpScaner("Asia/Shanghai", "10.0.40.4/24", []string{"22"}, 10)
	scaner.Scan()
}
