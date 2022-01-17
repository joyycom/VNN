# 卡通图像风格化
- [卡通图像风格化](#卡通图像风格化)
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
- [五、API文档](#五api文档)
  - [5.1 初始化 VNN_Create_General](#51-初始化-vnn_create_general)
  - [5.2 卡通图像风格化 VNN_Apply_General_CPU](#52-卡通图像风格化-vnn_apply_general_cpu)
  - [5.3 资源释放 VNN_Destroy_General](#53-资源释放-vnn_destroy_general)
  - [5.4 设置参数 VNN_Set_General_Attr](#54-设置参数-vnn_set_general_attr)
  - [5.5 获取参数 VNN_Get_General_Attr](#55-获取参数-vnn_get_general_attr)
  - [5.6 优化人脸区域的图像生成质量](#56-优化人脸区域的图像生成质量)
- [六、更新记录](#六更新记录)

# 一、SDK功能

对图像或视频进行卡通风格转换处理   

![cartoon_stylizing_example](./resource/cartoon_stylizing_example.png)

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

## PC端

| 指标            | 参数                                       |
| --------------- | ------------------------------------------ |
| 支持图片格式    | BGRA、RGBA、RGB、YUV420F                   |
| 支持架构        | x86(Win Only)、x86_64、arm64(MacOS Only) |
| Windows系统版本 | Win 7+                                     |
| MacOS系统版本   | 10.10+                                     |

---

# 三、资源依赖
## 3.1 头文件

```
vnn_general.h
vnn_kit.h
vnn_define.h
```
## 3.2 模型文件

卡通风格化
```
stylize_cartoon[1.0.0].vnnmodel
stylize_cartoon[1.0.0]_proceess_config.json
```

## 3.3 动态库
Android/Linux
```
libvnn_core.so
libvnn_kit.so
libvnn_general.so
```
iOS
```
Accelerate.framework
CoreVideo.framework
Foundation.framework
vnn_core_ios.framework
vnn_kit_ios.framework
vnn_general_ios.framework
```
MacOS
```
Accelerate.framework
CoreVideo.framework
Cocoa.framework
vnn_core_osx.framework
vnn_kit_osx.framework
vnn_general_osx.framework
```
Windows
```
vnn_core.dll
vnn_kit.dll
vnn_genral.dll
```

---

# 四、相关说明
## 4.1 Demo示例   
Android: [链接](../demos/Android/vnn_android_demo/app/src/main/java/com/duowan/vnndemo/CameraActivity.java)   
iOS: [链接](../demos/iOS/vnn_ios_demo/ios/CameraViewctrls/ViewCtrl_Camera_CartoonStylizing_ComicStylizing.mm)   
Windows: [链接](../demos/Windows/vnn_win_demo/demo/src/vnn_helper.cpp)   
MaoOS: [链接](../demos/MacOS/vnn_macos_demo/osx/CameraWindowCtrls/WindowCtrl_Camera_CartoonStylizing_ComicStylizing.mm)   
Linux: [链接](../demos/Linux/vnn_linux_demo/demo/src/vnn_helper.cpp)   

---
# 五、API文档
## 5.1 初始化 VNN_Create_General
说明: 输入模型路径，完成SDK的初始化，获得用于调用后续功能的Handle
```cpp
VNN_Result VNN_Create_General( VNNHandle * handle, const int argc, const void * argv[] )
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

std::string model = _modelpath + "/stylize_cartoon[1.0.0].vnnmodel";
std::string cfg = _modelpath + "/stylize_cartoon[1.0.0]_proceess_config.json";

const char* argv[] = {
	model.c_str(),
  cfg.c_str()
};

const int argc = sizeof(argv)/sizeof(argv[0]);

VNN_Result ret = VNN_Create_General(&_handle, argc, argv);
```
## 5.2 卡通图像风格化 VNN_Apply_General_CPU
说明: 输入需要风格转换的图像，输出风格转换后的图像
```cpp
VNN_Result VNN_Apply_General_CPU(VNNHandle handle, const void* in_image, const void* face_data, void* output)
```
| 参数      | 含义                                                |
| --------- | --------------------------------------------------- |
| handle    | SDK实例索引，类型为VNN_Handle，输入                 |
| in_image  | 输入图像，类型为 VNN_Image*，输入                   |
| face_data | 对于卡通图像风格化，该参数固定为NULL |
| output    | 检测结果，类型为 VNN_ImageArr*，输出                |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// input：完整的图像或视频帧，类型VNN_IMAGE

// 卡通风格化的输出图像参数
#define IMG_CHANNEL (3) 
#define IMG_HEIGHT  (512)
#define IMG_WIDTH   (512)

// 申请Buffer
if (!_imgBuffer) {
    _imgBuffer = (unsigned char *) malloc(IMG_CHANNEL * IMG_HEIGHT * IMG_WIDTH);
}

// 设置用于接收输出结果的对象
VNN_ImageArr output;
output.imgsNum = 1;
output.imgsArr[0].width = IMG_WIDTH; // 输出图像的宽
output.imgsArr[0].height = IMG_HEIGHT; // 输出图像的高
output.imgsArr[0].channels = IMG_CHANNEL; // 输出图像的通道
output.imgsArr[0].pix_fmt = VNN_PIX_FMT_RGB888; // 输出图像格式为RGB,CHW
output.imgsArr[0].data = _imgBuffer;

// 对于卡通图像风格化，接口第三个参数固定为NULL
VNN_Apply_General_CPU(_handle, input, NULL, output);
```

## 5.3 资源释放 VNN_Destroy_General
说明: 不再使用SDK，释放内存等资源
```cpp
VNN_Result VNN_Destroy_General(VNNHandle* handle)
```
| 参数   | 含义                                                                           |
| ------ | ------------------------------------------------------------------------------ |
| handle | SDK实例索引，成功释放资源后将被修改为0（无效值），类型为VNN_Handle*，输入&输出 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Result ret = VNN_Destroy_General(&_handle);
```

## 5.4 设置参数 VNN_Set_General_Attr
说明: 设定SDK实例的运行参数
```cpp
VNN_Result VNN_Set_General_Attr( VNNHandle handle, const char * name, const void * value )
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

## 5.5 获取参数 VNN_Get_General_Attr
说明: 获取SDK实例的运行参数
```cpp
VNN_Result VNN_Get_General_Attr( VNNHandle handle, const char * name, const void * value )
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
   
返回值: 类型为VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 暂时为空
```
## 5.6 优化人脸区域的图像生成质量   
如果需要卡通风格转换的图像包含人脸，建议按下述步骤优化图像质量：    

(1) 将 ```stylize_cartoon[1.0.0]_proceess_config.json```复制一份并命名为```stylize_cartoon[1.0.0]_face_proceess_config.json```      
(2) 打开```stylize_cartoon[1.0.0]_face_proceess_config.json``` ，将其中的 ```netW```字段和```netH```字段修改为256     
(3) 用新的json文件初始化VNN_Create_General， 得到一个新的handle(vnnmodel文件不变)。  
(4) 调用人脸关键点得到人脸框,对人脸框放大约1.3倍, 然后将人脸剪切出来。  
(5) 剪切出来的图走VNN_Apply_General_CPU得到人脸部分的卡通图像效果，注意输出大小为256*256。  
(6) 将原图得到的卡通图像和人脸部分的卡通图像进行融合。(注意，直接resize人脸部分图像，覆盖掉原图对应的卡通风格，会有色差，在边界处进行过度，会得到比较自然的图像)  

人脸区域图像质量优化后的效果，可参考上文的例图

---

# 六、更新记录
| 版本   | 日期       | 更新说明 |
| ------ | ---------- | -------- |
| v1.0.0 | 2021.12.31 | 初次发布 |
