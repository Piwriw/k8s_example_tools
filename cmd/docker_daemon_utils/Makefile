# 编译目标架构
ARCHS = amd64 arm64 386 arm

# 编译输出目录
OUTPUT_DIR = bin

# Go 源文件
GO_SRC = main.go

# 编译输出文件名
OUTPUT_FILE =docker_daemon_utils

.PHONY: all clean

all: $(ARCHS)

$(ARCHS):
	GOOS=linux GOARCH=$@ go build -o $(OUTPUT_DIR)/$(OUTPUT_FILE)_$@ $(GO_SRC)

clean:
	rm -rf $(OUTPUT_DIR)