# 人物属性识别
- [人物属性识别](#人物属性识别)
- [一、SDK功能](#一sdk功能)
- [二、技术规格](#二技术规格)
  - [移动端](#移动端)
  - [PC端](#pc端)
- [三、资源依赖](#三资源依赖)
  - [3.1 头文件](#31-头文件)
  - [3.2 模型文件](#32-模型文件)
  - [3.3 动态库](#33-动态库)
- [四、相关说明](#四相关说明)
  - [4.1 属性标签](#41-属性标签)
  - [4.2 处理流程](#42-处理流程)
  - [4.3 Demo示例](#43-demo示例)
- [五、API文档](#五api文档)
  - [5.1 初始化 VNN_Create_Classifying](#51-初始化-vnn_create_classifying)
  - [5.2 人物属性识别 VNN_Apply_Classifying_CPU](#52-人物属性识别-vnn_apply_classifying_cpu)
  - [5.3 资源释放 VNN_Destroy_Classifying](#53-资源释放-vnn_destroy_classifying)
  - [5.4 设置参数 VNN_Set_Classifying_Attr](#54-设置参数-vnn_set_classifying_attr)
  - [5.5 获取参数 VNN_Get_Classifying_Attr](#55-获取参数-vnn_get_classifying_attr)
  - [5.6 人脸关键点检测相关API](#56-人脸关键点检测相关api)
- [六、更新记录](#六更新记录)
# 一、SDK功能

根据图像或视频中的人脸，解析性别、颜值、年龄等信息。支持解析多张人脸   

API的输入、输出对象可参考[VNN 数据结构](./vnn_data_structure.md)   
API的执行情况（是否成功、错误原因等）可参考 ```VNN_Result``` 对应的[状态码表](./status_code.md)

---

# 二、技术规格

## 移动端

| 指标            | 参数                                |
| --------------- | ----------------------------------- |
| 支持图片格式    | BGRA、RGBA、RGB、NV12、NV21、YUV420 |
| 支持架构        | armeabi-v7、arm64-v8a               |
| Android系统版本 | 5.0+                                |
| iOS系统版本     | 9.0+                                |
| 最大解析人脸数  | 5                                   |

## PC端

| 指标            | 参数                                       |
| --------------- | ------------------------------------------ |
| 支持图片格式    | BGRA、RGBA、RGB、YUV420F                   |
| 支持架构        | x86(Win Only)、x86_64、arm64(MacOS Only) |
| Windows系统版本 | Win 7+                                     |
| MacOS系统版本   | 10.10+                                     |
| 最大解析人脸数  | 5                                          |

---

# 三、资源依赖
## 3.1 头文件

```
vnn_face.h
vnn_classifying.h
vnn_kit.h
vnn_define.h
```
## 3.2 模型文件
```
person_attribute[1.0.0].vnnmodel
person_attribute_label.json
```
## 3.3 动态库
Android/Linux
```
libvnn_core.so
libvnn_kit.so
libvnn_face.so
libvnn_classifying.so
```
iOS
```
Accelerate.framework
CoreVideo.framework
Foundation.framework
vnn_core_ios.framework
vnn_kit_ios.framework
vnn_face_ios.framework
vnn_classifying_ios.framework
```
MacOS
```
Accelerate.framework
CoreVideo.framework
Cocoa.framework
vnn_core_osx.framework
vnn_kit_osx.framework
vnn_face_osx.framework
vnn_classifying_osx.framework
```
Windows
```
vnn_core.dll
vnn_kit.dll
vnn_face.dll
vnn_classifying.dll
```

---

# 四、相关说明
## 4.1 属性标签

**性别（gender）**  

| 序号  | 标签   | 中文标签 |
| :---: | :----- | :------- |
|   0   | male   | 男性     |
|   1   | female | 女性     |
|   1   | unsure | 不确定   |

**颜值（beauty）**  

| 序号  | 标签   | 中文标签 |
| :---: | :----- | :------- |
|   0   | high   | 高       |
|   1   | middle | 中       |
|   2   | low    | 低       |

**年龄（age）**  

| 序号  | 标签   | 中文标签   |
| :---: | :----- | :--------- |
|   0   | 0-2    | 0至2岁     |
|  1-2  | 3-12   | 3至12岁    |
|  2-3  | 13-30  | 13至30岁   |
|   4   | 31-50  | 31至50岁   |
|   5   | 51+    | 51岁及以上 |
|   6   | unsure | 不确定     |

## 4.2 处理流程   

![pipline](./resource/pipline_person_attribute_recognition.png)

## 4.3 Demo示例   
Android: [链接](../demos/Android/vnn_android_demo/app/src/main/java/com/duowan/vnndemo/CameraActivity.java)   
iOS: [链接](../demos/iOS/vnn_ios_demo/ios/CameraViewctrls/ViewCtrl_Camera_GeneralClassification.mm)   
Windows: [链接](../demos/Windows/vnn_win_demo/demo/src/vnn_helper.cpp)   
MaoOS: [链接](../demos/MacOS/vnn_macos_demo/osx/CameraWindowCtrls/WindowCtrl_Camera_GeneralClassification.mm)   
Linux: [链接](../demos/Linux/vnn_linux_demo/demo/src/vnn_helper.cpp)   

---
# 五、API文档
## 5.1 初始化 VNN_Create_Classifying
说明: 输入模型路径，完成SDK的初始化，获得用于调用后续功能的Handle
```cpp
VNN_Result VNN_Create_Classifying( VNNHandle * handle, const int argc, const void * argv[] )
```
| 参数   | 含义                                                                                               |
| ------ | -------------------------------------------------------------------------------------------------- |
| handle | 函数调用成功后记录合法的索引，用于调用后续功能，类型为VNN_Handle*，调用成功后handle数值大于0，输出 |
| argc   | 输入模型文件数，类型为const int，输入                                                              |
| argv   | 每个模型文件的具体路径，类型为const char*[ ]，输入                                                 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Handle _handle;

std::string model = _modelpath + "/person_attribute[1.0.0].vnnmodel";

const char* argv[] = {
	model.c_str(),
};

const int argc = sizeof(argv)/sizeof(argv[0]);

VNN_Result ret = VNN_Create_Classifying(&_handle, argc, argv);
```
## 5.2 人物属性识别 VNN_Apply_Classifying_CPU
说明: 输入包含人脸的图像，输出检测结果
```cpp
VNN_Result VNN_Apply_Classifying_CPU(VNNHandle handle, const void* input, const void* face_data, void* output)
```
| 参数      | 含义                                                         |
| --------- | ------------------------------------------------------------ |
| handle    | SDK实例索引，类型为VNN_Handle，输入                          |
| input     | 输入图像，类型为 VNN_Image*，输入                            |
| face_data | 每张人脸的关键点检测信息，类型为 VNN_FaceFrameDataArr*，输入 |
| output    | 分类结果，类型为 VNN_MultiClsTopNAccArr*，输出               |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 运行前，需调用 VNN_Set_Classifying 设置分类标签

// input：完整的图像或视频帧，类型VNN_Image

// 获取人脸关键点检测结果的同时，获取含相对人脸适当扩大的检测框的检测结果
VNN_FaceFrameDataArr faceArr, detectionArr;
memset(&faceArr, 0x00, sizeof(VNN_FaceFrameDataArr));
memset(&detectionArr, 0x00, sizeof(VNN_FaceFrameDataArr));
VNN_Result ret = VNN_Apply_Face_CPU(_handle_face, &input, &faceArr);
// 注意：在VNN_Apply_Face_CPU之后调用
VNN_Result ret = VNN_Get_Face_Attr(_handle_face, "_detection_data", &detectionArr);

VNN_MultiClsTopNAccArr output;
// 注意：这里的输入数据来自 detectionArr，而不是faceArr
VNN_Result ret = VNN_Apply_Classifying_CPU(_handle, &input, &detectionArr, &output);
```

## 5.3 资源释放 VNN_Destroy_Classifying
说明: 不再使用SDK，释放内存等资源
```cpp
VNN_Result VNN_Destroy_Classifying(VNNHandle* handle)
```
| 参数   | 含义                                                                           |
| ------ | ------------------------------------------------------------------------------ |
| handle | SDK实例索引，成功释放资源后将被修改为0（无效值），类型为VNN_Handle*，输入&输出 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Result ret = VNN_Destroy_Classifying(&_handle);
// VNN_Result ret = VNN_Destory_Face(&_handle_face); // 如不再使用人脸关键点检测SDK，也一并释放资源
```

## 5.4 设置参数 VNN_Set_Classifying_Attr
说明: 设定SDK实例的运行参数
```cpp
VNN_Result VNN_Set_Classifying_Attr( VNNHandle handle, const char * name, const void * value )
```
| 参数   | 含义                                |
| ------ | ----------------------------------- |
| handle | SDK实例索引，类型为VNN_Handle，输入 |
| name   | 属性名，类型const char*，输入       |
| value  | 属性值，类型参见下表，输入          |

 **合法属性名和属性值**  

 | 属性名          | 属性含义           | 属性值           | 属性值类型  |
 | --------------- | ------------------ | ---------------- | ----------- |
 | _classLabelPath | 分类标签的文件路径 | 有效的路径字符串 | const char* |
   
返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 设置人物属性识别的标签路径
std::string label = basePath + "/person_attribute_label.json"
VNN_Set_Classifying(_handle, "_classLabelPath", label.c_str());
```

## 5.5 获取参数 VNN_Get_Classifying_Attr
说明: 获取SDK实例的运行参数
```cpp
VNN_Result VNN_Get_Classifying_Attr( VNNHandle handle, const char * name, const void * value )
```
| 参数   | 含义                                |
| ------ | ----------------------------------- |
| handle | SDK实例索引，类型为VNN_Handle，输入 |
| name   | 属性名，类型const char*，输入       |
| value  | 属性值，类型参见下表，输出          |

 **合法属性名和属性值**  

 | 属性名   | 属性含义 | 属性值 | 属性值类型 |
 | -------- | -------- | ------ | ---------- |
 | 暂时空白 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 暂时空白
```
## 5.6 人脸关键点检测相关API
参考 [链接](./face_landmark_detection.md)

---

# 六、更新记录
| 版本   | 日期       | 更新说明 |
| ------ | ---------- | -------- |
| v1.0.0 | 2021.12.07 | 初次发布 |
