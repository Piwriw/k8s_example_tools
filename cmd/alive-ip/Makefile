live-ip:
	GOOS=linux GOARCH=amd64  go build -o build/alive-ip-linux.amd64 main.go
	GOOS=linux GOARCH=arm64  go build -o build/alive-ip-linux.arm64 main.go
	GOOS=windows GOARCH=amd64  go build -o build/alive-ip-windows.amd64 main.go
	GOOS=windows GOARCH=arm64  go build -o build/alive-ip-windows.arm64 main.go
	GOOS=darwin GOARCH=amd64  go build -o build/alive-ip-mac.amd64 main.go
	GOOS=darwin GOARCH=arm64  go build -o build/alive-ip-mac.arm64 main.go