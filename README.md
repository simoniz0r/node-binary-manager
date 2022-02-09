# node-binary-manager
A crude and relatively untested script for installing and managing nodejs binary installs from https://nodejs.org

```
syretia@localhost:~> node-binary-manager
node-binary-manager version 0.0.1
Usage:  <install|in|update|up|default|def|remove|rm|list|ls> <version>
  install|in:   Install a given nodejs version to /opt/node-binary-manager
  update|up:    Update an already installed nodejs version
  default|def:  Set a given nodejs version as default by creating symlinks to /usr/local
  remove|rm:    Remove an installed nodejs version from /opt/node-binary-manager
  list|ls:      List installed and available nodejs versions

x86_64 Linux binaries are downloaded by default.
To download binaries for another platform, set the 'NSB_PLATFORM' environment variable.
Examples: 'export NSB_PLATFORM="linux-arm64"', 'export NSB_PLATFORM="darwin-x64"'

syretia@localhost:~> node-binary-manager list
Versions available from 'https://nodejs.org':
latest
latest-argon
latest-boron
latest-carbon
latest-dubnium
latest-erbium
latest-fermium
latest-gallium
latest-v0.10.x
latest-v0.12.x
latest-v10.x
latest-v11.x
latest-v12.x
latest-v13.x
latest-v14.x
latest-v15.x
latest-v16.x
latest-v17.x
latest-v4.x
latest-v5.x
latest-v6.x
latest-v7.x
latest-v8.x
latest-v9.x

Use 'list all' to see all available versions
syretia@localhost:~> sudo node-binary-manager install latest-fermium
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 21.1M  100 21.1M    0     0  24.7M      0 --:--:-- --:--:-- --:--:-- 24.7M
Installed 'latest-fermium' to '/opt/node-binary-manager/latest-fermium'
syretia@localhost:~> sudo node-binary-manager default latest-fermium
nodejs version 'latest-fermium' set as default version
syretia@localhost:~> node --version
v14.19.0
syretia@localhost:~> sudo node-binary-manager update latest-fermium
nodejs version 'latest-fermium' is up to date.
```
