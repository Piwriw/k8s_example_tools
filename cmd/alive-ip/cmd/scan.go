/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	utils "alive-ip/utils"
	"fmt"
	"github.com/spf13/cobra"
)

var ZONE string
var SUBNET string
var PORTS []string
var LIMIT int

// scanCmd represents the scan command
var scanCmd = &cobra.Command{
	Use:   "scan",
	Short: "Staring to scan for net",
	Long: `Staring to scan for net:
 	Need  -s 192.168.1.4/24 -p 22 .`,
	Run: func(cmd *cobra.Command, args []string) {
		scaner := utils.NewTcpScaner(ZONE, SUBNET, PORTS, LIMIT)
		if err := scaner.ScanPING(); err != nil {
			panic(err)
		}

		fmt.Printf("扫描时区:%s，网段:%s,扫描端口：%s\n", ZONE, SUBNET, PORTS)
		if err := scaner.Scan(); err != nil {
			panic(err)
		}
		fmt.Println("Scanning... Down")
	},
}

func init() {
	rootCmd.AddCommand(scanCmd)
	scanCmd.PersistentFlags().StringVarP(&ZONE, "zone", "z", "Asia/Shanghai", "Zone description")
	scanCmd.PersistentFlags().StringVarP(&SUBNET, "subnet ", "s", "", "Subnet description")
	scanCmd.PersistentFlags().StringSliceVarP(&PORTS, "ports", "p", []string{}, "Ports description")
	scanCmd.PersistentFlags().IntVarP(&LIMIT, "limit", "l", 50, "Limit description")
	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// scanCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// scanCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
