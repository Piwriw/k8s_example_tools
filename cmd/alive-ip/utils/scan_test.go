package test

import (
	"fmt"
	"testing"
)

func TestScanPing(t *testing.T) {
	fmt.Println(pingAlive("192.168.1.3"))

}
