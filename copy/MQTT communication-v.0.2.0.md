## communication between gateway and server


[TOC]


###  Topic:/gw/{gatewayMac}/status

| Fields         | Type   | Remark                |
| -------------- | ------ | ------------------- |
| mac            | string | mac address |
| rssi           | int    | RSSI |
|  raw            | string |raw data |

exeample:

```json
[ {
  "mac" : "000102030405",
  "rssi" : -72,
  "raw" : "xxxxxxxx"
} ]
```


### Topic:/gw/{gatewayMac}/action

| Action                      | Remark                                                       |
| --------------------------- | ------------------------------------------------------------ |
| [deviceData](#deviceData)   | send image data to ESL                                       |
| [wakeDevices](#wakeDevices) | wake and scan ESL devices                                    |
| [reboot](#reboot)           | reboot the gateway to gain a better experience               |
| [heartBeat](#heartBeat)     | test the gateway  on-line or not                             |
| [config](#config)           | configure the parameter of the gateway                       |
| [getVersions](#getVersions) | get the current version of gateway and the available version list |
| [upgrade](#upgrade)         | upgrade the gateway's firmware  to the given version         |
| [batchMBP](#batchMBP)       | configure the MBP batch by batch                             |
| [cnnMBP](#cnnMBP)           | connect the MBP                                              |
| [cmdMBP](#cmdMBP)           | control the MBP via the given command                        |
| [disCnnMBP](#disCnnMBP)     | disconnect the MBP                                           |









#### deviceData

| Fields    | type   | Required | Remark             |
| --------- | ------ | -------- | ------------------ |
| mac       | string/array | YES      | target mac address |
| key       | string | YES      | authentication key |
| screenSize | int | YES | screen size:0x29 or 0x42 |
| image     | string | YES      | image data         |
| imageid   | int | YES      | id of image data |
| requestId | string | NO       | request id       |

example:

```json
{
	"deviceData":[{
		"mac":"ac1122334401",
		"key":"3141592653589793",
		"screenSize": 41,
		"imageId":123456789,
		"image":"xxxxxxxxx"
	},{
		"mac":"ac1122334402",
		"key":"3141592653589793",
		"screenSize": 41,
		"imageId":987654321,
		"image":"xxxxxxxxx"
	}],
	"requestId":"xxxxxxxxxx"
}
```

If multi-devices with same image

```json
{
	"deviceData":[{
		"mac":["ac1122334407","ac1122334408","ac1122334405","ac1122334403"],
		"key":"3141592653589793",
		"screenSize": 41,
		"imageId":123456789,
		"image":"xxxxxxxx"
	}],
	"requestId":"xxxxxxxxxx"
}

```











#### wakeDevices

| Fields    | Type   | Required                       | Remark                                                      |
| --------- | ------ | ------------------------------ | ----------------------------------------------------------- |
| grade     | int    | NO                             | 唤醒等级，有效值范围：1~8,表示分2的grade次方批来唤醒，默认4 |
| interval  | int    | NO                             | 每批唤醒的时间间隔, 默认15000                               |
| mac       | array  | YES(required if grade equal 0) | The mac list you wanna wake up                              |
| requestId | string | NO                             | request ID                                                  |


example:

```json
{
	"wakeDevices":{
		"grade":1,
		"interval":20000
	},
	"requestId":"xxxxxxxxxx"
}
{
    "wakeDevices":{
        "grade":0,
        "interval":20000,
        "mac":[
            "ac1122334403",
            "ac1122334405",
            "ac1122334407",
            "ac1122334408",
            "ac112233440a",
            "ac1122334404"
        ]
    }   
}
```



#### reboot

| Fields    | Type   | Required | Remark                        |
| --------- | ------ | -------- | ----------------------------- |
| reboot    | object | YES      | Key word to recognize command |
| requestId | string | NO       | request id                    |

example:

```json
{
    "reboot":{},
    "requestId":"xxxx"
}
```



#### heartBeat

| Fields    | Type   | Required | Remark                        |
| --------- | ------ | -------- | ----------------------------- |
| heartBeat | object | YES      | Key word to recognize command |
| requestId | string | NO       | request id                    |

example:

```json
{
    "heartBeat":{},
    "requestId":"xxxx"
}
```



#### config



The actually configuration need `TBD`

Part history configuration of G1 is as follow.



| Fields                | Type   | Required | Remark                                                       |
| --------------------- | ------ | -------- | ------------------------------------------------------------ |
| config                | object | YES      | key word to recognize command                                |
| takeEffectImmediately | string | NO       | Whether to take effect immediately after setting ;<br>optional value:YES,NO; <br>when this field is not included,the default value is NO;<br>You need to reboot the gateway manually to take effect if this value is NO. |
| proto                 | string | NO       | Optional value : MQTT,HTTP;<br>Default value is MQTT.        |
| uploadInterval        | string | NO       | The unit of time is milliseconds.<br>Default value is 1000.  |
| isFilterDupData       | string | NO       | Duplicate data within the time interval be filtered to upload or not |





#### getVersions

| Fields      | Type   | Required | Remark                        |
| ----------- | ------ | -------- | ----------------------------- |
| getVersions | object | YES      | Key word to recognize command |
| requestId   | string | NO       | request id                    |

control example:

```json
{
    "getVersions":{},
    "requestId":"xxxx"
}
```



response example:

```json
{
  "stage" : 0,
  "code" : 0,
  "message" : "success",
  "requestId" : "xxxx",
  "availableBLENumber" : 3,
  "currentWiFiVersion" : "v0.1.0",
  "currentBLEVersion" : "v2.0.1",
  "availableWiFiVersions" : [ "v1.0.0", "v1.0.1", "v1.0.2" ],
  "availableBLEVersions" : [ "v1.0.0", "v2.0.1", "v2.0.2", "v2.0.3" ]
}
```

 

#### upgrade

| Fields    | Type   | Required                          | Remark                                                       |
| --------- | ------ | --------------------------------- | ------------------------------------------------------------ |
| upgrade   | object | YES                               | Key word to recognize command                                |
| type      | string | NO                                | Optional value:public,self;<br>default value:  public;<br>public: means download firmware from the public HTTP server;<br>self: means download firmware from the self given HTTP server. |
| target    | string | NO                                | Optional value:WiFi,BLE;<br>default value:  WiFi;<br>WiFi: means upgrade WiFi firmware;<br>BLE: means upgrade BLE firmware. |
|   isSave  | string | NO        | Whether to save the configuration |
| version   | string | YES(required in public type and BLE type) | The version you wanna upgrade to                             |
| urlpath   | string | YES(only required in self type)   | The URL path of self HTTP server,where for the gateway to download firmware |
| filename  | string | YES(only required in self type)   | filename of firmware in self given HTTP server               |
| requestId | string | NO                                | request id                                                   |

example of upgrading the WiFi firmware with public type:

```json
{
    "upgrade":{
        "type":"public",
        "target":"WiFi",
        "isSave":"YES",
        "version":"v1.3.9"
    },
    "requestId":"xxx"
}
```
example of upgrading the BLE firmware with public type:

```json
{
    "upgrade":{
        "type":"public",
        "target":"BLE",
        "version":"v2.0.1"
    },
    "requestId":"xxx"
}
```


example of upgrading WiFi firmware with self type:

```json
{
    "upgrade":{
        "type":"self",
        "target":"WiFi",
        "isSave":"YES",
        "urlpath":"http://192.168.0.3/download/fimwareDir/",
        "filename":"xxxxxxx.bin"
    },
    "requestId":"xxxx"
}
```


example of upgrading BLE firmware with self type:

```json
{
    "upgrade":{
        "type":"self",
        "target":"BLE",
        "urlpath":"http://192.168.0.3/download/fimwareDir/",
        "filename":"xxxx.zip",
        "version":"v2.0.1"//如果是升级BLE固件这个version一定要，用于检验BLE固件是否升级成功
    },
    "requestId":"xxxx"
}
```


#### batchMBP

| Fields    | Type                   | Required | Remark                        |
| --------- | ---------------------- | -------- | ----------------------------- |
| batchMBP  | object array           | YES      | key word to recognize command |
| mac       | string array or string | YES      | target MBP mac address        |
| password  | string                 | YES      | the password to access MBP    |
| cmd       | string/array           | YES      | the command to configure MBP  |
| requestId | string                 | NO       | request  id                   |



example of configure MBP batch by batch:



```json
{
	"batchMBP":[{
		"mac":["ad1122334403","ad1122334404"],
		"password":"minew123",
		"cmd":[
			"01081500020160000b1700ff0000000084030001ffffff067502016000077503016003200675040160040675050160c919750a01648010a0ff112233444556677889900aabbccddeef0e750a0164c105a0ff00010050c91500020160000d15000001030203030304030503ff",
		"01071500020160000b1700ff0000000084030001ffffff067502016001077503016001f40675040160040675050160c619750a0164001000ff112233445566778899111122334455661500020160000d15000001030203030304030503ff",
			"01081500020160000b1700ff0000000084030001ffffff067502016002077503016001f40675040160000675050160e819750a0155801010ff016d696e6577746563680000000000000c750a0132c10310ff0000001500020160000d15000001030203030304030503ff",
			"01071500020160000b1700ff00000000a00f0001ffffff06750201600307750301600fa00675040160040675050160e809750a0155000020001500020160000d15000001030203030304030503ff"
		]
	}，
    {
          ......      
    }
	],
	"requestId":"xxxxxxxxxx"
}
```



注意：

- batchMBP 命令相当于cnnMBP，cmdMBP和disCnnMBP的组合。

- 上面的例子中，是将4条通道的参数拆分成了4条命令，理论上如果正常的话，一条命令会返回一条code=100的消息，如果中间有失败的情况，但由于网关有重试机制，code=100的消息可能会返回多次。为了避免这种 code=100的消息条数>cmd的条数的情况，可以将多条命令都和成一条命令发给网关。

- code=101时返回原始参数是有>1的情况的，因为网关有重试机制。







#### cnnMBP

| Fields    | Type   | Required | Remark                        |
| --------- | ------ | -------- | ----------------------------- |
| cnnMBP    | object | YES      | key word to recognize command |
| mac       | string | YES      | target MBP mac address        |
| password  | string | YES      | the password to access MBP    |
| requestId | string | NO       | request id                    |

注意：

- cnnMBP,cmdMBP,disCnnMBP命令用于长连接

- 发起cnnMBP命令如果成功连接就会返回Code=101的消息，否则直接返回code=300，网关会保持一定时间（3分钟）的长连接（保持的时间从最后一条命令开始算，暂定3分钟）

- 发起cmdMBP之前一定要先cnnMBP（如果之前发起过cnnMBP，但是由于时间超过了保持连接的时间，一样会返回失败）

example of connect MBP:

```json
{
	"cnnMBP":{
		"mac":"ad1122334403",
		"password":"minew123"
	},
	"requestId":"xxxxxxxxxx"
}

```



#### cmdMBP

| Fields    | Type   | Required | Remark                        |
| --------- | ------ | -------- | ----------------------------- |
| cmdMBP    | object | YES      | key word to recognize command |
| mac       | string | YES      | target MBP mac address        |
| cmd       | string | YES      | the command to configure MBP  |
| requestId | string | NO       | request id                    |

注意：

- 发起cmdMBP之前一定要先cnnMBP（如果之前发起过cnnMBP，但是由于时间超过了保持连接的时间，一样会返回失败）

example of sending command to MBP:

```json
{
	"cmdMBP":{
		"mac":"ad1122334402",
		"cmd":"01081500020128000b1700ff0000000084030001ffffff067502012801077503012803200675040128040675050128c919750a01648010a0ff112233444556677889900aabbccddeef0e750a0164c105a0ff00010050c91500020128000d15000001030203030304030503ff"
	},
	"requestId":"xxxxxxxxxx"
}

```








#### disCnnMBP

| Fields    | Type   | Required | Remark                 |
| --------- | ------ | -------- | ---------------------- |
| disCnnMBP | object | YES      | key word to recogni    |
| mac       | string | YES      | target MBP mac address |
| requestId | string | NO       | request id             |



example of disconnect MBP:

```json
{
	"disCnnMBP":{
		"mac":"ad1122334404"
	},
	"requestId":"xxxxxxxxxx"
}
```










### Topic:/gw/{gatewayMac}/response

#### common response fields

| Fields    | Type   |Required |Remark                      |
| --------- | ------ |---------|--------------------------- |
| stage     | int    | YES     |response stage: 0 for receive stage，1 for control stage               |
| code      | int    | YES     |response code               |
| message   | string | YES     |response message            |
| requestId | string | NO      |request id,same as request  |



#### specific reponse fields

说明：下面是getVersions命令的返回，并且在第一个阶段（stage=0）返回。

| Fields                | Type    | Required                                  | Remark                      |
| --------------------- | ------- | ----------------------------------------- | --------------------------- |
| currentWiFiVersion    | string  | YES(only for [getVersions](#getVersions)) | current version of WiFi     |
| availableWiFiVersions | string  | YES(only for [getVersions](#getVersions)) | available WiFi version list |
| currentBLEVersion     | string  | YES(only for [getVersions](#getVersions)) | current version of BLE      |
| availableBLEVersions  | string  | YES(only for [getVersions](#getVersions)) | available BLE version list  |
| availableBLENumber    | integer | YES(only for [getVersions](#getVersions)) | available BLE module number |

说明：下面是MBP所有命令的在第二个阶段（stage=1）的返回。

| Fields  | Type   | Required | Remark                     |
| ------- | ------ | -------- | -------------------------- |
| mac     | string | YES      | target MBP mac address     |
| payload | string | NO       | payload,code=101,200时存在 |

#### code table

#### response code for  stage 0


| Code | Message                                     | Remark                                                       |
| ---- | ------------------------------------------- | ------------------------------------------------------------ |
| 0    | [success](#success)                         | success response                                             |
| -1   | [invalid json format](#invalid json format) | error json format                                            |
| -2   | [unrecognized action](#unrecognized action) | invalid action key                                           |
| -3   | [parameter error](#parameter error)         | invalid parameter                                            |
| -4   | [network error](#network error)             | network error(only in [getVersions](#getVersions) [upgrade](#upgrade)) |

#### response code  for stage 1



| Code    | Message                                                      | Remark                                                      |
| ------- | ------------------------------------------------------------ | ----------------------------------------------------------- |
| 100     | [Success to execute command](#Success to execute command)    | Success to execute command(可能返回多次，因为网关重试机制)  |
| 101     | [Raw parameter of MBP](#Raw parameter of MBP)                | Raw parameter of MBP，raw parameter is at the payload field |
| 102     | [Success to execute central DFU](#Success to execute central DFU) | 主端DFU成功返回                                             |
| 103~199 | xxx                                                          | reserved for successful return                              |
| 200     | [Check at the server side](#Check at the server side)        | You need to check the payload at the server side            |
| 201~299 | xxx                                                          | reserved for vague return                                   |
| 300     | [Fail to execute command](#Fail to execute command)          | Fail to execute command, in ESL or MBP                      |
| 301     | [Fail to execute central DFU](#Fail to execute central DFU)  | 主端DFU失败                                                 |
| 302~399 | xxx                                                          | reserved for failure return                                 |
| 400     | [APP restarted](#APP restarted)                              | 网关主程序刚启动，刚开机或者崩溃重启都会发                  |







#### response example at stage 0



##### success 

```json
{
    "stage":0,
    "code":0,
    "message":"success",
    "requestId":"xxx"
}
```

##### invalid json format

```json
{
    "stage":0,
    "code":-1,
    "message":"invalid json format",
    "requestId":"xxx"
}
```



##### unrecognized action

```json
{
    "stage":0,
    "code":-2,
    "message":"unrecognized action",
    "requestId":"xxx"
}
```


##### parameter error

```json
{
    "stage":0,
    "code":-3,
    "message":"parameter error",
    "requestId":"xxx"
}
```


##### network error

```json
{
    "stage":0,
    "code":-4,
    "message":"network error",
    "requestId":"xxx"
}
```



#### response example at stage 1





##### Success to execute command

```json
{
    "stage":1,
    "code":100,
    "message":"Success to execute command",
    "mac":"ad1122334404"
}
```





##### Raw parameter of MBP

```json
{
    "stage":1,
    "code":101,
    "message":"Raw parameter of MBP",
    "mac":"ad1122334404",
    "payload":"2a294d696e657720546563682a24426561636f6e20506c75732a254144313132323333343430340a2a274d5337315346365f56312e302e302a26322e332e31312a286e524635322d53444b31332e30750200750303207504047505c9750aa0ff112233444556677889900aabbccddeef00010050750201750301f47504047505c6750a00ff11223344556677889911112233445566750202750301f47504007505e8750a10ff016d696e6577746563680075020375030fa07504047505e8750a2000750204750300007504047505c9750affff750205750301f47504007505e8750affff000201031c0600a637360ae3d5902e8d04dc0002010b1800ff00000000a00f00014ceae40002010b1801ff00000000d00700011d892d0002010b1802ff00000000d0070001bb48d90002010b1803ff00000000a00f00012cdb0d0002010b1804ff00000000a00ff8010ff29c0002010b1805ff0000000000000001d618fc0002010d1600000103020303030403050359"
}

```





##### Check at the server side

```json
{
    "stage":1,
    "code":200,
    "message":"Check at the server side",
    "mac":"ad1122334404",
    "payload":"xxxx(主端返回的内容)"
}
```





##### Fail to execute command

ESL或者MBP操作失败

```json
{
    "stage":1,
    "code":300,
    "message":"Fail to execute command",
    "mac":"ad1122334404"
}
```


##### Success to execute central DFU
```json
{
    "stage":1,
    "code":102,
    "message":"Success to execute central DFU"
}
```


##### Fail to execute central DFU
```json
{
    "stage":1,
    "code":301,
    "message":"Fail to execute central DFU"
}
```

##### APP restarted
```json
{
    "stage":1,
    "code":400,
    "message":"APP restarted"
}
```





