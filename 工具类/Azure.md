

[注册微软 Azure 账号](https://signup.azure.com/)

#### 在x86 Linux中本机构建Azure sdk：

可以参考[https://github.com/Azure/azure-iot-sdk-c/blob/master/doc/devbox_setup.md]( https://github.com/Azure/azure-iot-sdk-c/blob/master/doc/devbox_setup.md )

检查是否安装:

`sudo apt-get install -y git cmake build-essential curl libcurl4-openssl-dev libssl-dev uuid-dev`

克隆azure及其子项目：

`git clone --recursive  https://github.com/Azure/azure-iot-sdk-c.git`

or

```sh
git clone  https://github.com/Azure/azure-iot-sdk-c.git
cd azure-iot-sdk-c
git submodule update --init
```



进入azure sdk文件夹，创建包含生成的二进制文件的文件夹，并调用cmake配置设置：

```bash
cd azure-iot-sdk-c
mkdir x86_64
cd x86_64
cmake ..
cmake --build . -- -j4   #或者 "make-j4"
```

进入azure-iot-sdk-c/x86_64/serializer/samples/simplesample_mqtt文件夹，运行simplesample_mqtt，它将生成假数据并将其发送到云：

```shell
 ./simplesample_mqtt 
Error: Time:Tue Feb 25 01:21:47 2020 File:/home/hzlarm/azure/azure-iot-sdk-c/iothub_client/src/iothub_client_core_ll.c Func:IoTHubClientCore_LL_CreateFromConnectionString Line:1362 Tokenizer error
Error: Time:Tue Feb 25 01:21:47 2020 File:/home/hzlarm/azure/azure-iot-sdk-c/iothub_client/src/iothub_client_core_ll.c Func:IoTHubClientCore_LL_CreateFromConnectionString Line:1505 iotHubName is not found
Failed on IoTHubClient_LL_Create
```

问题很明显，设备id、密钥和主机名都应该写在代码中。

编辑文件azure-iot-sdk-c/serializer/samples/simplesample_mqtt/simplesample_mqtt.c（不在x86_64文件夹下），修改关于第36行的代码：

```c
/*String containing Hostname, Device Id & Device Key in the format:             */
/*  "HostName=<host_name>;DeviceId=<device_id>;SharedAccessKey=<device_key>"    */
//static const char* connectionString = "[device connection string]";
static const char* connectionString = \
                    "HostName=test-0-remote-monitor23fea.azure-devices.net;" \
                    "DeviceId=CoolingSampleDevice_2656;" \
                    "SharedAccessKey=3OuqHv7YyejvxVdsYcV2OIZSof5scZRIBnKVq61Sy6s=";
```



字符串中不应有空格，否则发送操作将不会成功。

重建（可以在azure-iot-sdk-c/x86_64/serializer/samples/simplesample_mqtt文件夹中键入make）并再次运行，命令行显示：

```shell
gaiger@i5-3210M:~/azure-iot-sdk-c/x86_64/serializer/samples/simplesample_mqtt$ ./simplesample_mqtt 
Info: IoT Hub SDK for C, version 1.1.18
IoTHubClient accepted the message for delivery
Message Id: 0 Received.
Result Call Back Called! Result is: IOTHUB_CLIENT_CONFIRMATION_OK 
```

数据已成功发送。

到云站点，结果已被记录：

（别忘了在Azure网站的垂直角将“设备查看”设置为与设置的设备id相同！！）



如果你觉得很糟糕为什么你的记录只有一个数据而我只有三个，不要担心，因为我已经运行了三次二进制。

现在，为了便于调试，修改文件azure-iot-sdk-c/serializer/samples/simplesample_mqtt/simplesample_mqtt.c以保持每两秒钟生成一次数据，大约215行：

```c
/* wait for commands */
while (1)
{
    IoTHubClient_LL_DoWork(iotHubClientHandle);
    #if(0)                            
    ThreadAPI_Sleep(100);
    #else
    ThreadAPI_Sleep(2*1000);
    //myWeather->DeviceId = "myFirstDevice";
    myWeather->WindSpeed = avgWindSpeed + (rand() % 4 + 2);
    myWeather->Temperature = minTemperature + (rand() % 10);
    myWeather->Humidity = minHumidity + (rand() % 20);
    printf("WindSpeed = %d, Temperature = %3.1f, Humidity = %3.1f\r\n", 
           myWeather->WindSpeed, myWeather->Temperature, myWeather->Humidity);
    {
        unsigned char* destination;
        size_t destinationSize;
        if (SERIALIZE(&destination, &destinationSize, 
                      myWeather->DeviceId, myWeather->WindSpeed, 
                      myWeather->Temperature, myWeather->Humidity) != CODEFIRST_OK)
        {
            (void)printf("Failed to serialize\r\n");
        }
        else
        {
            sendMessage(iotHubClientHandle, destination, destinationSize, myWeather);
            free(destination);
        }
    }
    #endif
}
```



重新构建并再次运行，您将不断发现从客户端到云的数据：

```
./azure-iot-sdk-c/x86_64/serializer/samples/simplesample_mqtt$ ./simplesample_mqtt 
Info: IoT Hub SDK for C, version 1.1.18
IoTHubClient accepted the message for delivery
WindSpeed = 12, Temperature = 22.0, Humidity = 72.0
IoTHubClient accepted the message for delivery
WindSpeed = 14, Temperature = 26.0, Humidity = 71.0
IoTHubClient accepted the message for delivery
WindSpeed = 13, Temperature = 29.0, Humidity = 77.0
IoTHubClient accepted the message for delivery
WindSpeed = 13, Temperature = 26.0, Humidity = 78.0
IoTHubClient accepted the message for delivery
WindSpeed = 13, Temperature = 20.0, Humidity = 74.0
IoTHubClient accepted the message for delivery
WindSpeed = 13, Temperature = 25.0, Humidity = 61.0
IoTHubClient accepted the message for delivery
WindSpeed = 13, Temperature = 21.0, Humidity = 73.0
IoTHubClient accepted the message for delivery
WindSpeed = 15, Temperature = 22.0, Humidity = 61.0
IoTHubClient accepted the message for delivery
Message Id: 0 Received.
:
```

在这里，基于x86的客户端已经完成。



####  Build Azure SDK for OpenWrt. 

返回到azure SDK文件夹，作为x86，创建一个文件夹来保存为目标OpenWrt构建的二进制文件。

新建文件夹命名为mips_24kc。在/azure-iot-sdk-c/mips_24kc下创建文件名为mipskc.cmake，以配置cmake使用的交叉编译信息：

```Makefile
INCLUDE(CMakeForceCompiler)
 
SET(CMAKE_SYSTEM_NAME Linux)     # this one is important
SET(CMAKE_SYSTEM_VERSION 1)     # this one not so much
 
# this is the location of the amd64 toolchain targeting your device
SET(CMAKE_C_COMPILER /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/toolchain-mipsel_24kc_gcc-7.4.0_musl/bin/mipsel-openwrt-linux-musl-gcc)
SET(CMAKE_FIND_ROOT_PATH /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl)
 
# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
 
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
# system location of target device
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

您只需更改CMAKE_C_编译器行作为从OpenWrt包构建的交叉编译器的位置，并将CMAKE_FIND_ROOT_PATH行修改为刚构建的系统的OpenWrt路径。

注意：一个是位置，另一个是路径。


下一个操作是配置：

```shell
cmake .. \        
-DCMAKE_TOOLCHAIN_FILE=mips_24kc.cmake

-- The C compiler identification is GNU 7.4.0
-- The CXX compiler identification is GNU 7.4.0
-- Check for working C compiler: /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/toolchain-mipsel_24kc_gcc-7.4.0_musl/bin/mipsel-openwrt-linux-musl-gcc
：
：
：
-- target architecture: GENERIC
-- iothub architecture: GENERIC
-- Configuring done
-- Generating done
-- Build files have been written to: /home/hzlarm/azure/azure-iot-sdk-c/mips_24kc
```



现在是建立库的时候了：

但是，当您键入“make”时，将出现错误：

```shell
 make 
:
:
mipsel-openwrt-linux-musl-gcc: warning: environment variable 'STAGING_DIR' not defined
cc1: all warnings being treated as errors
c-utility/CMakeFiles/aziotsharedutil.dir/build.make:1118: recipe for target 'c-utility/CMakeFiles/aziotsharedutil.dir/src/dns_resolver_sync.c.o' failed
make[2]: *** [c-utility/CMakeFiles/aziotsharedutil.dir/src/dns_resolver_sync.c.o] Error 1
CMakeFiles/Makefile2:1091: recipe for target 'c-utility/CMakeFiles/aziotsharedutil.dir/all' failed
make[1]: *** [c-utility/CMakeFiles/aziotsharedutil.dir/all] Error 2
Makefile:138: recipe for target 'all' failed
make: *** [all] Error 2
```

可选：您可以在终端中设置bash变量STAGING_DIR来禁用编译警告。

` export STAGING_DIR=/home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir`

再make：又出错

```
[  1%] Built target parson
[  7%] Built target umock_c
[  7%] Building C object c-utility/CMakeFiles/aziotsharedutil.dir/src/dns_resolver_sync.c.o
In file included from /home/hzlarm/azure/azure-iot-sdk-c/c-utility/pal/linux/socket_async_os.h:13:0,
                 from /home/hzlarm/azure/azure-iot-sdk-c/c-utility/src/dns_resolver_sync.c:11:
/home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/toolchain-mipsel_24kc_gcc-7.4.0_musl/include/sys/errno.h:1:2: error: #warning redirecting incorrect #include <sys/errno.h> to <errno.h> [-Werror=cpp]
 #warning redirecting incorrect #include <sys/errno.h> to <errno.h>
  ^~~~~~~
cc1: all warnings being treated as errors
...
make: *** [all] Error 2
```

这里是因为将所有警告改成了错误，要么就是把Makefile中的Werror干掉或者 修改/home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/toolchain-mipsel_24kc_gcc-7.4.0_musl/include/sys/errno.h文件把第一行注释掉即可



在链接阶段生成二进制文件时出错。打开simplesample_mqtt的链接描述文件，该文件位于生成文件夹azure-iot-sdk-c/mips_24kc/serializer/samples/simplesample_mqtt/CMakeFiles/simplesample_mqtt.dir/link.txt下：



与完整路径形式的libssl.so和libcrypto.so相比，libcurl和libuuid的链接是用缩写形式写的。手动修改全路径形式的链接库是解决这个错误的一种简便方法 同时把-rpath改为-rpath-link（这是一种极端而原始的方法）：



```shell
/home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/toolchain-mipsel_24kc_gcc-7.4.0_musl/bin/mipsel-openwrt-linux-musl-gcc  -fPIC  -Werror   CMakeFiles/simplesample_mqtt.dir/simplesample_mqtt.c.o CMakeFiles/simplesample_mqtt.dir/linux/main.c.o  -o simplesample_mqtt -rdynamic ../../../iothub_client/libiothub_client_mqtt_transport.a ../../libserializer.a ../../../iothub_client/libiothub_client.a ../../../iothub_client/libiothub_client_mqtt_transport.a ../../../libparson.a ../../../iothub_client/libiothub_client_http_transport.a ../../../iothub_client/libiothub_client_amqp_transport.a ../../../iothub_client/libiothub_client_amqp_ws_transport.a ../../../iothub_client/libiothub_client_mqtt_ws_transport.a ../../../umqtt/libumqtt.a ../../../c-utility/libaziotsharedutil.a /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl/usr/lib/libcurl.so  /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl/usr/lib/libssl.so /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl/usr/lib/libcrypto.so -lpthread -lm -lrt /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl/usr/lib/libuuid.so -Wl,-rpath-link /home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl/usr/lib 
```



并在azure-iot-sdk-c/mips-24kc/serializer/samples/simplesample_mqtt文件夹下键入make：

```
 make
[  1%] Built target parson
[ 10%] Built target serializer
[ 51%] Built target aziotsharedutil
[ 55%] Built target umqtt
[ 58%] Built target iothub_client_mqtt_transport
[ 62%] Built target iothub_client_mqtt_ws_transport
[ 73%] Built target iothub_client_amqp_ws_transport
[ 83%] Built target iothub_client_amqp_transport
[ 87%] Built target iothub_client_http_transport
[ 98%] Built target iothub_client
[ 98%] Linking C executable simplesample_mqtt
[100%] Built target simplesample_mqtt
```

编译已通过。



这个解决方案只是一个解决方案：手动替换字符串不是一个好方法（但它有效），更好的方法是修复CMake脚本，或者自动编写bash脚本来修改所有link.txt文件。



我准备了一个脚本来实现替换。

在路径azure-iot-sdk-c/mips kc下创建名为dornlink.sh的文件：

```shell
# bin/bash
#fix azure sdk error in linking stage
 
echo Back up file as link.txt in the same folders
 
find -name link.txt -exec cp {} {}.bak -f \
#find -name link.txt -exec rm {}.bak -f \;
#find . -ipath "*link.txt" -type f  -exec cp {} {}.bak \;
#find . -ipath "*link.txt" -type f  -exec rm {}.bak \;
 
FOUND_LINKINK_TXT=$(find -name link.txt)
 
OPENWRT_LIB_PATH=""
 
echo "$FOUND_LINKINK_TXT" | while read LINE_CONTENT
do
	if [ -z "$OPENWRT_LIB_PATH" ]; then
		OPENWRT_LIB_PATH=$(sed -rn 's/.* (.*)\/libssl.so .*/\1/p' "$LINE_CONTENT")
		echo "$OPENWRT_LIB_PATH"
	fi
 
	echo fix file: "$LINE_CONTENT"
	sed -i "s|-lcurl|$OPENWRT_LIB_PATH/libcurl.so|g" "$LINE_CONTENT"
	sed -i "s|-luuid|$OPENWRT_LIB_PATH/libuuid.so|" "$LINE_CONTENT"
done # while read LINE_CONTENT
 
 
FILE_NUM=$(echo "$FOUND_LINKINK_TXT" | wc -l)
echo "$FILE_NUM" files have been fixed.
```

在键入chmod 777 dornlink.sh之后，运行脚本然后重新生成，链接错误应该全部消失。


在这里，交叉编译已经完成。













./build.sh --toolchain-file mips_24kc.cmake -cl --sysroot=/home/hzlarm/openwrt/gateway_openwrt_19.07_g1/staging_dir/target-mipsel_24kc_musl











[Azure_Linux](https://github.com/Azure/azure-iot-sdk-c/blob/master/doc/devbox_setup.md#linux)

## 设置Linux开发环境

本节介绍如何在[Ubuntu](http://www.ubuntu.com/desktop)上为C SDK设置开发环境。[CMake](https://cmake.org/)将创建makefile，[make](https://www.gnu.org/software/make/)将使用它们通过[gcc](https://gcc.gnu.org/)编译器编译C SDK源代码。

- 在构建SDK之前，请确保已安装所有依赖项。对于Ubuntu，可以使用apt-get安装正确的软件包：

  ```
  sudo apt-get update
  sudo apt-get install -y git cmake build-essential curl libcurl4-openssl-dev libssl-dev uuid-dev
  ```

- 验证CMake至少是**2.8.12**版本：

  ```
  cmake --version
  ```

  > 有关如何在Ubuntu 14.04上将CMake版本升级到3.x的信息，请阅读[如何在Ubuntu 14.04上安装CMake 3.2？](http://askubuntu.com/questions/610291/how-to-install-cmake-3-2-on-ubuntu-14-04)。

- 确认gcc至少是**4.4.7**版本：

  ```
  gcc --version
  ```

  > 有关如何在Ubuntu 14.04上升级gcc版本的信息，请阅读[如何在Ubuntu 14.04上使用最新的GCC 4.9？](http://askubuntu.com/questions/466651/how-do-i-use-the-latest-gcc-4-9-on-ubuntu-14-04)。

- 将CURL修补到可用的最新版本。

  > 所需的最小卷曲版本为7.56，因为最近的先前版本存在[严重故障](https://github.com/Azure/azure-iot-sdk-c/issues/308)。要升级，请参见下面的“在Mac OS上升级CURL”。

- 找到[最新版本](https://github.com/Azure/azure-iot-sdk-c/releases/latest)的SDK 的标签名称。

  > 我们的发行标签名称是`yyyy-mm-dd`格式的日期值。

- 使用找到的标记名称将最新版本的SDK克隆到本地计算机：

  ```
  git clone -b <yyyy-mm-dd> https://github.com/Azure/azure-iot-sdk-c.git
  cd azure-iot-sdk-c
  git submodule update --init
  ```

  > 如果您使用的是2019-04-15之前的版本，则需要使用`--recursive`参数来指示git克隆此SDK依赖的其他GitHub存储库。依赖性在[这里](https://github.com/Azure/azure-iot-sdk-c/blob/master/.gitmodules)列出。

### 在Linux上构建C SDK

要构建SDK：

```
cd azure-iot-sdk-c
mkdir cmake
cd cmake
cmake ..
cmake --build .  # append '-- -j <n>' to run <n> jobs in parallel
```

> 要构建调试二进制文件，请将相应的CMake选项添加到上面的项目生成命令中，例如：

```
cmake -DCMAKE_BUILD_TYPE=Debug ..
```

有许多CMake配置选项可用于构建SDK。例如，您可以通过向CMake项目生成命令添加一个参数来禁用可用的协议栈之一：

```
cmake -Duse_amqp=OFF ..
```

另外，您可以构建和运行单元测试：

```
cmake -Drun_unittests=ON ..
cmake --build .
ctest -C "debug" -V
```

> 注意：您构建的任何样本都必须使用有效的IoT中心设备连接字符串进行配置，然后才能使用。有关更多信息，请参见下面的[示例部分](https://github.com/Azure/azure-iot-sdk-c/blob/master/doc/devbox_setup.md#samplecode)。

