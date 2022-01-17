# 手势检测
- [手势检测](#手势检测)
- [一、SDK功能](#一sdk功能)
- [二、技术规格](#二技术规格)
  - [移动端](#移动端)
  - [PC端](#pc端)
- [三、资源依赖](#三资源依赖)
  - [3.1 头文件](#31-头文件)
  - [3.2 模型文件](#32-模型文件)
  - [3.3 动态库](#33-动态库)
- [四、相关说明](#四相关说明)
  - [4.1 Demo示例](#41-demo示例)
  - [4.2 视频流检测和图像检测的设置区别](#42-视频流检测和图像检测的设置区别)
  - [4.3 手势类型标签](#43-手势类型标签)
- [五、API文档](#五api文档)
  - [5.1 初始化 VNN_Create_Gesture](#51-初始化-vnn_create_gesture)
  - [5.2 手势检测 VNN_Apply_Gesture_CPU](#52-手势检测-vnn_apply_gesture_cpu)
  - [5.3 资源释放 VNN_Destroy_Gesture](#53-资源释放-vnn_destroy_gesture)
  - [5.4 设置参数 VNN_Set_Gesture_Attr](#54-设置参数-vnn_set_gesture_attr)
  - [5.5 获取参数 VNN_Get_Gesture_Attr](#55-获取参数-vnn_get_gesture_attr)
- [六、更新记录](#六更新记录)

# 一、SDK功能

实时检测图像或视频中的手势，支持多个手势检测，返回每个手势所在区域与手势识别结果   

API的输入、输出对象可参考[VNN 数据结构](./vnn_data_structure.md)   
API的执行情况（是否成功、错误原因等）可参考 ```VNN_Result``` 对应的[状态码表](./status_code.md)

---

# 二、技术规格

## 移动端

| 指标               | 参数                                |
| ------------------ | ----------------------------------- |
| 支持图片格式       | BGRA、RGBA、RGB、NV12、NV21、YUV420 |
| 支持架构           | armeabi-v7、arm64-v8a               |
| Android系统版本    | 5.0+                                |
| iOS系统版本        | 9.0+                                |
| 最大支持手势检测数 | 15                                  |

## PC端

| 指标               | 参数                                     |
| ------------------ | ---------------------------------------- |
| 支持图片格式       | BGRA、RGBA、YUV420F (暂不支持RGB)        |
| 支持架构           | x86(Win Only)、x86_64、arm64(MacOS Only) |
| Windows系统版本    | Win 7+                                   |
| MacOS系统版本      | 10.10+                                   |
| 最大支持手势检测数 | 15                                       |

---

# 三、资源依赖
## 3.1 头文件

```
vnn_gesture.h
vnn_kit.h
vnn_define.h
```
## 3.2 模型文件
```
gesture[1.0.0].vnnmodel
```
## 3.3 动态库
Android/Linux
```
libvnn_core.so
libvnn_kit.so
libvnn_gestrue.so
```
iOS
```
Accelerate.framework
CoreVideo.framework
Foundation.framework
vnn_core_ios.framework
vnn_kit_ios.framework
vnn_gesture_ios.framework
```
MacOS
```
Accelerate.framework
CoreVideo.framework
Cocoa.framework
vnn_core_osx.framework
vnn_kit_osx.framework
vnn_gesture_osx.framework
```
Windows
```
vnn_core.dll
vnn_kit.dll
vnn_gestrue.dll
```

---

# 四、相关说明
## 4.1 Demo示例   
Android: [链接](../demos/Android/vnn_android_demo/app/src/main/java/com/duowan/vnndemo/CameraActivity.java)   
iOS: [链接](../demos/iOS/vnn_ios_demo/ios/CameraViewctrls/ViewCtrl_Camera_Gesture.mm)   
Windows: [链接](../demos/Windows/vnn_win_demo/demo/src/vnn_helper.cpp)   
MaoOS: [链接](../demos/MacOS/vnn_macos_demo/osx/CameraWindowCtrls/WindowCtrl_Camera_Gesture.mm)   
Linux: [链接](../demos/Linux/vnn_linux_demo/demo/src/vnn_helper.cpp)   

## 4.2 视频流检测和图像检测的设置区别   
出于保证视频流检测的实时性考虑，本SDK采用了“跟踪+检测”的设计。为避免**单张**图像检测受影响，在设置输入图像VNN_Image时，应作如下设置
``` cpp
VNN_Image input;
input.mode_fmt = VNN_MODE_FMT_PICTURE; // 用于图像检测
input.mode_fmt = VNN_MODE_FMT_VIDEO; // 用于视频流检测
// 设置VNN_Image其他属性
```
## 4.3 手势类型标签
**手势类型枚举值**
``` cpp
typedef enum _VNN_GestureType {
    VNN_GestureType_Unknow       = 0x00, // 检测到手但手势不明
    VNN_GestureType_V            = 0x01, // 剪刀手
    VNN_GestureType_ThumbUp      = 0x02, // 点赞
    VNN_GestureType_OneHandHeart = 0x03, // 单手比心
    VNN_GestureType_SpiderMan    = 0x04, // 蜘蛛侠
    VNN_GestureType_Lift         = 0x05, // 托举
    VNN_GestureType_666          = 0x06, // “666”
    VNN_GestureType_TwoHandHeart = 0x07, // 双手比心
    VNN_GestureType_PalmTogether = 0x08, // 抱拳
    VNN_GestureType_PalmOpen     = 0x09, // 张开手掌
    VNN_GestureType_ZuoYi        = 0x0a, // 作揖
    VNN_GestureType_OK           = 0x0b, // “OK”
    VNN_GestureType_ERROR        = 0xff, // 异常情况
} VNN_GestureType;
```

---
# 五、API文档
## 5.1 初始化 VNN_Create_Gesture
说明: 输入模型路径，完成SDK的初始化，获得用于调用后续功能的Handle
```cpp
VNN_Result VNN_Create_Gesture( VNNHandle * handle, const int argc, const void * argv[] )
```
| 参数   | 含义                                                                                              |
| ------ | ------------------------------------------------------------------------------------------------- |
| handle | 函数调用成功后记录合法的索引，用于调用后续功能，类型为VNN_Handle，调用成功后handle数值大于0，输出 |
| argc   | 输入模型文件数，类型为const int，输入                                                             |
| argv   | 每个模型文件的具体路径，类型为const char*[ ]，输入                                                |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Handle _handle;

std::string model = _modelpath + "/gesture[1.0.0].vnnmodel";

const char* argv[] = {
	model.c_str(),
};

const int argc = sizeof(argv)/sizeof(argv[0]);

VNN_Result ret = VNN_Create_Gesture(&_handle, argc, argv);
```
## 5.2 手势检测 VNN_Apply_Gesture_CPU
说明: 输入包含人脸的图像，输出检测结果
```cpp
VNN_Result VNN_Apply_Gesture_CPU( VNNHandle handle, const void * input, void * output )
```
| 参数   | 含义                                           |
| ------ | ---------------------------------------------- |
| handle | SDK实例索引，类型为VNN_Handle，输入            |
| input  | 被检测图像，类型为 VNN_Image，输入             |
| output | 检测结果，类型为 VNN_GestureFrameDataArr，输出 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Image input;
// 设置VNN_Image属性
VNN_GestureFrameDataArr output; 
memset(&output, 0x00, sizeof(VNN_GestureFrameDataArr));
VNN_Apply_DocRect_CPU(_handle, &input, output);
```

## 5.3 资源释放 VNN_Destroy_Gesture
说明: 不再使用SDK，释放内存等资源
```cpp
VNN_Result VNN_Destroy_Gesture( VNNHandle* handle)
```
| 参数   | 含义                                                                          |
| ------ | ----------------------------------------------------------------------------- |
| handle | SDK实例索引，成功释放资源后将被修改为0（无效值），类型为VNN_Handle，输入&输出 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Result ret = VNN_Destroy_Gesture(&_handle);
```

## 5.4 设置参数 VNN_Set_Gesture_Attr
说明: 设定SDK实例的运行参数
```cpp
VNN_Result VNN_Set_Gesture_Attr( VNNHandle handle, const char * name, const void * value )
```
| 参数   | 含义                                |
| ------ | ----------------------------------- |
| handle | SDK实例索引，类型为VNN_Handle，输入 |
| name   | 属性名，类型const char*，输入       |
| value  | 属性值，类型参见下表，输入          |

 **合法属性名和属性值**  

 | 属性名   | 属性含义 | 属性值 | 属性值类型 |
 | -------- | -------- | ------ | ---------- |
 | 暂时为空 |
   
返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 暂时为空
```

## 5.5 获取参数 VNN_Get_Gesture_Attr
说明: 获取SDK实例的运行参数
```cpp
VNN_Result VNN_Get_Gesture_Attr( VNNHandle handle, const char * name, const void * value )
```
| 参数   | 含义                                |
| ------ | ----------------------------------- |
| handle | SDK实例索引，类型为VNN_Handle，输入 |
| name   | 属性名，类型const char*，输入       |
| value  | 属性值，类型参见下表，输出          |

 **合法属性名和属性值**  

 | 属性名   | 属性含义 | 属性值 | 属性值类型 |
 | -------- | -------- | ------ | ---------- |
 | 暂时为空 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 暂时为空
```
---

# 六、更新记录
| 版本   | 日期       | 更新说明 |
| ------ | ---------- | -------- |
| v1.0.0 | 2021.12.07 | 初次发布 |
