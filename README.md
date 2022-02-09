# node-binary-manager
A crude and relatively untested script for installing and managing nodejs binary installs from https://nodejs.org

```
node-binary-manager version 0.0.1
Usage:  <install|in|update|up|default|def> <version>
  install|in:   Install a given nodejs version to /opt/node-binary-manager
  update|up:    Update an already installed nodejs version
  default|def:  Set a given nodejs version as default by creating symlinks to /usr/local
```

```
syretia@localhost:~> sudo node-binary-manager install latest-fermium
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 21.1M  100 21.1M    0     0  24.7M      0 --:--:-- --:--:-- --:--:-- 24.7M
Installed 'latest-fermium' to '/opt/node-binary-manager/latest-fermium'
syretia@localhost:~> sudo node-binary-manager default latest-fermium
nodejs version 'latest-fermium' set as default version
syretia@localhost:~> node --version
v14.19.0
```
