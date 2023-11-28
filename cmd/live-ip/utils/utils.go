package utils

import (
	"net"
)

// 获取子网信息
func SubNetGet(subnet string) ([]string, error) {
	var ips []string
	ip, ipNet, err := net.ParseCIDR(subnet)
	if err != nil {
		return ips, err
	}

	// 根据子网网段信息，实现 ip 自增
	for ip := ip.Mask(ipNet.Mask); ipNet.Contains(ip); inc(ip) {
		ips = append(ips, ip.String())
	}
	if len(ips) > 2 {
		ips = ips[1 : len(ips)-1]
	}
	return ips, nil
}

// []byte 加到 255 再加 1 就归零了，利用这个特性来做 ip 自增
// 下面的函数例子：192.168.1.255 + 1 --> 192.168.2.255
func inc(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}
