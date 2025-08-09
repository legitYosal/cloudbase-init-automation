# Cloudbase-init one-click installation script

This will simply install cloudbase-init on your windows server without needing to use GUI or even getting to work with power shell, it simply does all the work for you, and installs the official version on your windows server.

You only need to simple run:
```
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/legitYosal/cloudbase-init-automation/master/install-cloudbaseinit.ps1' -UseBasicParsing).Content"
```
