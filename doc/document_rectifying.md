# 文档矫正
- [文档矫正](#文档矫正)
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
  - [4.2 图像不存在文档的判断](#42-图像不存在文档的判断)
- [五、API文档](#五api文档)
  - [5.1 初始化 VNN_Create_DocRect](#51-初始化-vnn_create_docrect)
  - [5.2 文档矫正 VNN_Apply_DocRect_CPU](#52-文档矫正-vnn_apply_docrect_cpu)
  - [5.3 资源释放 VNN_Destroy_DocRect](#53-资源释放-vnn_destroy_docrect)
  - [5.4 设置参数 VNN_Set_DocRect_Attr](#54-设置参数-vnn_set_docrect_attr)
  - [5.5 获取参数 VNN_Get_DocRect_Attr](#55-获取参数-vnn_get_docrect_attr)
- [六、更新记录](#六更新记录)

# 一、SDK功能

实时检测图像或视频中的纸质文档，返回的4个角点在图像中的坐标，根据坐标将拍摄倾斜的文档调整为正面图   

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
| 最大支持检测文档数 | 1                                   |

## PC端

适配中，待更新

---

# 三、资源依赖
## 3.1 头文件

```
vnn_docrect.h
vnn_kit.h
vnn_define.h
```
## 3.2 模型文件
```
document_rectification[1.0.0].vnnmodel
```
## 3.3 动态库
Android
```
libvnn_core.so
libvnn_kit.so
libvnn_docrect.so
```
iOS
```
Accelerate.framework
CoreVideo.framework
Foundation.framework
vnn_core_ios.framework
vnn_kit_ios.framework
vnn_docrect_ios.framework
```
MacOS/Windows/Linux
```
适配中，待更新
```

---

# 四、相关说明
## 4.1 Demo示例   
Android: [链接](../demos/Android/vnn_android_demo/app/src/main/java/com/duowan/vnndemo/CameraActivity.java)   
iOS: [链接](../demos/iOS/vnn_ios_demo/ios/CameraViewctrls/ViewCtrl_Camera_DocRect.mm)   
Windows/MacOS/Linux: 适配中，待更新

## 4.2 图像不存在文档的判断   
当检测不到文档时，SDK的输出结果为全0的坐标值（即4个角点均在图像左上角）。

---
# 五、API文档
## 5.1 初始化 VNN_Create_DocRect
说明: 输入模型路径，完成SDK的初始化，获得用于调用后续功能的Handle
```cpp
VNN_Result VNN_Create_DocRect( VNNHandle * handle, const int argc, const void * argv[] )
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

std::string model = _modelpath + "/document_rectification[1.0.0].vnnmodel";

const char* argv[] = {
	model.c_str(),
};

const int argc = sizeof(argv)/sizeof(argv[0]);

VNN_Result ret = VN_Create_DocRect(&_handle, argc, argv);
```
## 5.2 文档矫正 VNN_Apply_DocRect_CPU
说明: 输入包含人脸的图像，输出检测结果
```cpp
VNN_Result VNN_Apply_DocRect_CPU( VNNHandle handle, const void * input, void * output )
```
| 参数   | 含义                                  |
| ------ | ------------------------------------- |
| handle | SDK实例索引，类型为VNN_Handle，输入   |
| input  | 被检测图像，类型为 VNN_Image，输入    |
| output | 检测结果，类型为 VNN_Point2D[4]，输出 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Image input; // 需补充设置VNN_Image属性
VNN_Point2D outputs[4];
memset(outputs, 0x00, sizeof(VNN_Point2D) * 4);
VNN_Apply_DocRect_CPU(_handle, &input, outputs);
```

## 5.3 资源释放 VNN_Destroy_DocRect
说明: 不再使用SDK，释放内存等资源
```cpp
VNN_Result VNN_Destroy_DocRect( VNNHandle* handle)
```
| 参数   | 含义                                                                          |
| ------ | ----------------------------------------------------------------------------- |
| handle | SDK实例索引，成功释放资源后将被修改为0（无效值），类型为VNN_Handle，输入&输出 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Result ret = VNN_Destory_DocRect(&_handle);
```

## 5.4 设置参数 VNN_Set_DocRect_Attr
说明: 设定SDK实例的运行参数
```cpp
VNN_Result VNN_Set_DocRect_Attr( VNNHandle handle, const char * name, const void * value )
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

## 5.5 获取参数 VNN_Get_DocRect_Attr
说明: 获取SDK实例的运行参数
```cpp
VNN_Result VNN_Get_DocRect_Attr( VNNHandle handle, const char * name, const void * value )
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
