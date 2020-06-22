[注册微软 Azure 账号](https://signup.azure.com/)

Openwrt、x86Linux及交叉编译Azure IoT Hub SDK

### 下载azure及其子项目：

```shell
git clone --recursive  https://github.com/Azure/azure-iot-sdk-c.git
```

或者

```shell
git clone  https://github.com/Azure/azure-iot-sdk-c.git
cd azure-iot-sdk-c
git submodule update --init
```

#### 在x86 Linux中本机构建Azure IoT Hub SDK：

可以参考[https://github.com/Azure/azure-iot-sdk-c/blob/master/doc/devbox_setup.md](https://github.com/Azure/azure-iot-sdk-c/blob/master/doc/devbox_setup.md)


```shell
cd ~/azure-iot-sdk-c/build_all/linux
#安装依赖
#./setup.sh
#修改build.sh文件 选择是否编译各个子项目以及修改生成SDK路径
#如 build_folder=$build_root"/linux_sdk"
./build.sh
```



#### 交叉编译 Azure IoT Hub SDK

可以参考<https://github.com/Azure/azure-iot-sdk-c/blob/master/doc/SDK_cross_compile_example.md>

```shell
cd ~/azure-iot-sdk-c/build_all/linux
```

**创建工具链文件**


```shell
#vi cross.cmake

INCLUDE(CMakeForceCompiler)
 
SET(CMAKE_SYSTEM_NAME Linux)     # this one is important
SET(CMAKE_SYSTEM_VERSION 1)     # this one not so much
 
# this is the location of the cross toolchain targeting your device
SET(CMAKE_C_COMPILER /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/toolchain-mipsel_24kc_gcc-7.4.0_musl/bin/mipsel-openwrt-linux-musl-gcc)

# this is the file system root of the target
SET(CMAKE_FIND_ROOT_PATH /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl)

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)

# system location of target device
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```
**修改build.sh文件** 选择是否编译各个子项目以及修改生成SDK路径 如：`build_folder=$build_root"/cross_sdk"`

```shell
cd ~/Source/azure-iot-sdk-c/build_all/linux
./build.sh --toolchain-file cross.cmake -cl  --sysroot=/home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl
```

```sh
#出现警告 mipsel-openwrt-linux-musl-gcc: warning: environment variable 'STAGING_DIR' not defined
export STAGING_DIR=/home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir
```

#### 在Openwrt中编译 Azure IoT Hub SDK

官方提供的openwrt编译方法在`azure-iot-sdk-c/build_all/arduino`路径

如下几个脚本：

`setup.sh`   设置下载openwrt_sdk的目录，默认为 `$HOME`

`setup_sdk.sh ` 由setup.sh调用来下载openwrt的脚本

`build.sh`  编译脚本核心内容如下

```shell
#vi build.sh

#设置openwrt的路径
sdk_root="$HOME"
openwrt_folder="openwrt"
openwrt_sdk_folder="gateway_openwrt_19.07_g1"
working_dir=$PWD
iot_dir="azure-iot-sdk-c"
....

build_iot()
{
    echo "Building IoT"
    rm -d -f -r $sdk_root/$openwrt_folder/$openwrt_sdk_folder/package/$iot_dir
    mkdir $sdk_root/$openwrt_folder/$openwrt_sdk_folder/package/$iot_dir
    mkdir $sdk_root/$openwrt_folder/$openwrt_sdk_folder/package/$iot_dir/src
    cp -f "$working_dir/Makefile.iot" "$sdk_root/$openwrt_folder/$openwrt_sdk_folder/package/$iot_dir/Makefile"
    cd "$working_dir/../../.."
    cp -R -f . "$sdk_root/$openwrt_folder/$openwrt_sdk_folder/package/$iot_dir/src"
    cd "$sdk_root/$openwrt_folder/$openwrt_sdk_folder"
    #可以先注释，修改根据需要修改Makefile后再编译
    #make V=s "package/$iot_dir/compile"
}
```

在Makefile文件：

```shell
#define Build/Configure中可以选择需要编译的模块
cmake -DCMAKE_FIND_ROOT_PATH="$(TOOLCHAIN_DIR)" $(PKG_BUILD_DIR)/CMakeLists.txt -DIN_OPENWRT=1 -Duse_amqp:bool=ON -Duse_http:bool=ON     -Duse_mqtt:bool=on -Duse_floats:bool=OFF -Duse_condition:bool=OFF

```

如果没有openwrt包先执行`setup.sh`下载，有则执行`./build.sh`