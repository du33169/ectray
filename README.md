# ECtray: A Podman EasyConnect Wrapper

本项目是一个适用于Windows系统的外部图形界面包装器，为在[podman](https://podman.io/)容器中安装的[docker-easyconnect](https://github.com/Hagb/docker-easyconnect):cli提供便于适用的图形界面。

## 声明

本项目中的ec_on.ico与ec_off.ico为EasyConnect的图标，仅用于指示容器内EasyConnect程序本身的运行状态。该图标及EasyConnect的一切权利属深信服所有。

## 前置条件

### podman安装与配置

Windows系统需要[开启WSL](https://learn.microsoft.com/zh-cn/windows/wsl/install)，但是不必安装发行版。

1. 安装podman：[Github下载安装包](https://github.com/containers/podman/releases)（linux也可用包管理工具）

2. [从github下载rootfs](https://github.com/containers/podman-wsl-fedora/releases)

3. 在rootfs.tar.xz所在目录下打开powershell窗口

4. 键入如下命令，初始化machine并启动：
   
   ```powershell
   podman machine init --image-path .\rootfs.tar.xz
   podman machine start
   ```

### 运行[docker-easyconnect](https://github.com/Hagb/docker-easyconnect)

首先拉取镜像：

```powershell
podman pull docker.io/hagb/docker-easyconnect:cli
```

然后运行一次（其中`${xxx}`表示的变量请自行替换，dns参数必须指定一个能解析服务器域名的DNS服务器，否则会无法连接）：

```powershell
podman run --device /dev/net/tun --cap-add NET_ADMIN --dns 114.114.114.114 -ti -p ${SOCKS5_PORT}:1080 -p ${HTTP_PORT}:8888 `
  -e EC_VER=7.6.3 -v ${accountFile}:/root/.easyconn hagb/docker-easyconnect:cli
```

第一次运行时会提示输入服务器、用户名和密码。当出现如下输出时表示成功连接：

```
user "[用户名]" auto login successfully
```

前面的的-v选项就是将登录信息保存到前面配置的`$accountFile`。后面再运行就可以自动登录。断线会自动重连，Ctrl+C可以退出。

**安全提示：**`$accountFile`保存格式为**二进制明文**，请注意不要泄露。

## 使用

双击ectray.exe，运行时会自动创建托盘图标、启动podman machine，当右键托盘图标并点击Enable时，会在后台自动执行前面的podman run指令启动EasyConnect。之后就可以正常使用EasyConnect代理。需要停止时同样右键托盘图标取消Enable复选框即可。

没有写登录界面，所以在使用前请通过终端手动运行一次前面的podman run指令并生成`accountFile`。

程序的本质是调用终端命令，所以请确保podman和docker-easyconnect的镜像安装与配置无误。

## 构建

本项目通过[PS2EXE](https://github.com/MScholtes/PS2EXE)将powershell脚本编译为exe。因此，如果需要自行尝试构建，请首先安装ps2exe。

在Powershell中执行：

```powershell
Install-Module ps2exe
```

而后即可运行构建脚本（同样使用Powershell）：

```powershell
./build.ps1
```

该脚本会使用ps2exe将ectray.ps1编译为exe，并与其他所需文件一起压缩，输出为release目录下具有日期后缀的压缩包文件。

<!--
## TODO

- 增加闪烁状态
- 检查登录文件存在，否则弹出窗口用于输入用户名和密码
- docker兼容性？
- GBK中文化？ 
- -->
