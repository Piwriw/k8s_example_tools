#  nvidia-device-plugin.md
```bash
vim /etc/docker/daemon.json 
{
     "default-runtime": "nvidia", 
     "runtimes": { 
        "nvidia": { 
            "path": "/usr/bin/nvidia-container-runtime", 
            "runtimeArgs": [] 
        } 
    }
}
```