# Server Configuration

## SSH

## UFW

```bash
nano /etc/ufw/applications.d/openssh-server
```

``` bash
ufw app update openssh
ufw allow openssh
```
