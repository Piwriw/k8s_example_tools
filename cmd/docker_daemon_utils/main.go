package main

import (
	"encoding/json"
	"os"
)

type DockerConfig struct {
	ExecOpts           []string `json:"exec-opts"`
	InsecureRegistries []string `json:"insecure-registries"`
	RegistryMirrors    []string `json:"registry-mirrors"`
}

const DockerDaemonPath = "/etc/docker/daemon.json"

func main() {
	dockerConfig, daemonSourceMap, err := readJSONFile(DockerDaemonPath)
	if err != nil {
		panic(err)
	}
	dockerConfig.ExecOpts = CheckConfig(dockerConfig.ExecOpts, "native.cgroupdriver=systemd")
	dockerConfig.InsecureRegistries = CheckConfig(dockerConfig.InsecureRegistries, "0.0.0.0/0")
	HARBOR_ADDR := os.Getenv("HARBOR_ADDR")
	if HARBOR_ADDR != "" {
		dockerConfig.RegistryMirrors = CheckConfig(dockerConfig.RegistryMirrors, os.Getenv("HARBOR_ADDR"))
	}

	daemonSourceMap["exec-opts"] = dockerConfig.ExecOpts
	daemonSourceMap["insecure-registries"] = dockerConfig.InsecureRegistries
	daemonSourceMap["registry-mirrors"] = dockerConfig.RegistryMirrors
	bytes, err := json.MarshalIndent(daemonSourceMap, "", "    ")
	if err != nil {
		panic(err)
	}
	if err = os.WriteFile(DockerDaemonPath, bytes, 452); err != nil {
		panic(err)
	}

}
func CheckConfig(configs []string, target string) []string {
	found := false
	for _, registry := range configs {
		if registry == target {
			found = true
			break
		}
	}
	if !found {
		configs = append(configs, target)
	}
	return configs
}
func readJSONFile(dirPath string) (*DockerConfig, map[string]interface{}, error) {
	// 读取目录
	daemonSource, err := os.ReadFile(dirPath)
	if err != nil {
		return nil, nil, err
	}
	dockerConf := &DockerConfig{}
	var daemonSourceMap map[string]interface{}
	if err := json.Unmarshal(daemonSource, &daemonSourceMap); err != nil {
		return nil, nil, err
	}
	if err = json.Unmarshal(daemonSource, dockerConf); err != nil {
		return nil, nil, err
	}
	return dockerConf, daemonSourceMap, err
}
