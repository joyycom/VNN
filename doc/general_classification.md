# 场景与天气分类/Vlog场景物品分类
- [场景与天气分类/Vlog场景物品分类](#场景与天气分类vlog场景物品分类)
- [一、SDK功能](#一sdk功能)
- [二、技术规格](#二技术规格)
  - [移动端](#移动端)
  - [PC端](#pc端)
- [三、资源依赖](#三资源依赖)
  - [3.1 头文件](#31-头文件)
  - [3.2 模型文件](#32-模型文件)
  - [3.3 动态库](#33-动态库)
- [四、相关说明](#四相关说明)
  - [4.1 Vlog场景物品分类标签](#41-vlog场景物品分类标签)
  - [4.2 场景与天气分类标签](#42-场景与天气分类标签)
  - [4.3 处理流程](#43-处理流程)
  - [4.4 Demo示例](#44-demo示例)
- [五、API文档](#五api文档)
  - [5.1 初始化 VNN_Create_Classifying](#51-初始化-vnn_create_classifying)
  - [5.2 执行分类功能 VNN_Apply_Classifying_CPU](#52-执行分类功能-vnn_apply_classifying_cpu)
  - [5.3 资源释放 VNN_Destroy_Classifying](#53-资源释放-vnn_destroy_classifying)
  - [5.4 设置参数 VNN_Set_Classifying_Attr](#54-设置参数-vnn_set_classifying_attr)
  - [5.5 获取参数 VNN_Get_Classifying_Attr](#55-获取参数-vnn_get_classifying_attr)
- [六、更新记录](#六更新记录)
# 一、SDK功能

识别图片或视频中的包含的物体、场景等信息。目前支持场景与天气分类，Vlog场景物品分类   

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
vnn_classifying.h
vnn_kit.h
vnn_define.h
```
## 3.2 模型文件
场景与天气分类
```
scene_weather[1.0.0].vnnmodel
scene_weather[1.0.0]_label.json
```
Vlog场景物品分类
```
object_classification[1.0.0].vnnmodel
object_classification[1.0.0]_label.json
```
## 3.3 动态库
Android/Linux
```
libvnn_core.so
libvnn_kit.so
libvnn_classifying.so
```
iOS
```
Accelerate.framework
CoreVideo.framework
Foundation.framework
vnn_core_ios.framework
vnn_kit_ios.framework
vnn_classifying_ios.framework
```
MacOS
```
Accelerate.framework
CoreVideo.framework
Cocoa.framework
vnn_core_osx.framework
vnn_kit_osx.framework
vnn_classifying_osx.framework
```
Windows
```
vnn_core.dll
vnn_kit.dll
vnn_classifying.dll
```

---

# 四、相关说明
## 4.1 Vlog场景物品分类标签

| 序号  | 标签                     | 中文标签     |
| :---: | :----------------------- | :----------- |
|   0   | other                    | 其他         |
|   1   | cat                      | 猫           |
|   2   | dog                      | 狗           |
|   3   | panda                    | 熊猫         |
|   4   | aquarium_fish            | 观赏鱼       |
|   5   | other_animal             | 其他动物     |
|   6   | flower                   | 花朵         |
|   7   | leaf                     | 叶子         |
|   8   | other_plant              | 其他植物     |
|   9   | computer                 | 电脑         |
|  10   | mobile_phone             | 手机         |
|  11   | other_digital_product    | 其他电子产品 |
|  12   | great_food_show          | 美食         |
|  13   | food_making              | 烹饪         |
|  14   | text_shooting            | 文字拍摄     |
|  15   | football                 | 足球         |
|  16   | badminton                | 羽毛球       |
|  17   | table_tennis             | 乒乓球       |
|  18   | basketball               | 篮球         |
|  19   | billiards                | 台球         |
|  20   | body_building            | 健美         |
|  21   | other_sport              | 其他运动     |
|  22   | instrumental_performance | 乐器演奏     |

## 4.2 场景与天气分类标签   

**室内外场景**  

| 序号  | 标签             | 中文标签 |
| :---: | :--------------- | :------- |
|   0   | street_corner    | 街头     |
|   1   | palace           | 宫殿     |
|   2   | pavilion         | 园林     |
|   3   | old_buildings    | 古楼     |
|   4   | modern_buildings | 现代建筑 |
|   5   | concert          | 演唱会   |
|   6   | competition      | 比赛现场 |
|   7   | office           | 办公区   |
|   8   | home             | 居家     |
|   9   | other_indoor     | 室内其他 |
|  10   | snow_mountain    | 雪山     |
|  11   | beach            | 沙滩     |
|  12   | waterfalls       | 瀑布     |
|  13   | fireworks        | 烟花     |
|  14   | antumn_leaves    | 秋叶     |
|  15   | sea              | 大海     |
|  16   | mountain         | 山       |
|  17   | desert           | 沙漠     |
|  18   | aurora           | 极光     |
|  19   | starry_sky       | 星空     |
|  20   | other            | 其他     |

**室外天气**  

| 序号  | 标签        | 中文标签 |
| :---: | :---------- | :------- |
|   0   | sunrise     | 日出日落 |
|   1   | sunny       | 晴天     |
|   2   | rain_cloudy | 阴雨     |
|   3   | snow        | 下雪     |
|   4   | foggy       | 起雾     |
|   5   | night       | 夜晚     |
|   6   | thunder     | 打雷     |
|   7   | other       | 其他     |

## 4.3 处理流程

![pipline](./resource/pipline_general_classification.png)

## 4.4 Demo示例   
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
| 参数   | 含义                                                                    |
| ------ | ----------------------------------------------------------------------- |
| handle | 函数调用成功后记录合法的索引，用于调用后续功能，类型为VNN_Handle*，调用成功后handle数值大于0，输出 |
| argc   | 输入模型文件数，类型为const int，输入                                   |
| argv   | 每个模型文件的具体路径，类型为const char*[ ]，输入                      |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 以场景与天气为例
VNN_Handle _handle;

std::string model = _modelpath + "/scene_weather[1.0.0].vnnmodel";

const char* argv[] = {
	model.c_str(),
};

const int argc = sizeof(argv)/sizeof(argv[0]);

VNN_Result ret = VNN_Create_Classifying(&_handle, argc, argv);
```
## 5.2 执行分类功能 VNN_Apply_Classifying_CPU
说明: 输入包含人脸的图像，输出检测结果
```cpp
VNN_Result VNN_Apply_Classifying_CPU(VNNHandle handle, const void* input, const void* face_data, void* output)
```
| 参数      | 含义                                                  |
| --------- | ----------------------------------------------------- |
| handle    | SDK实例索引，类型为VNN_Handle，输入                   |
| input     | 输入图像，类型为 VNN_Image*，输入                     |
| face_data | 对于场景与天气分类/Vlog场景物品分类，该参数固定为NULL |
| output    | 分类结果，类型为 VNN_MultiClsTopNAccArr*，输出        |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
// 运行前，需调用 VNN_Set_Classifying 设置分类标签

// input：完整的图像或视频帧，类型VNN_Image
VNN_MultiClsTopNAccArr output;
// 对于场景与天气分类/Vlog场景物品分类，接口第三个参数固定为NULL
VNN_Result ret = VNN_Apply_Classifying_CPU(_handle, &input, NULL, &output);
```

## 5.3 资源释放 VNN_Destroy_Classifying
说明: 不再使用SDK，释放内存等资源
```cpp
VNN_Result VNN_Destroy_Classifying(VNNHandle* handle)
```
| 参数   | 含义                                                                  |
| ------ | --------------------------------------------------------------------- |
| handle | SDK实例索引，成功释放资源后将被修改为0（无效值），类型为VNN_Handle*，输入&输出 |

返回值: VNN_Result，具体值参见 状态码表  
调用示例:  
``` cpp
VNN_Result ret = VNN_Destroy_Classifying(&_handle);
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
// 设置场景与天气分类的分类标签路径
std::string label = basePath + "/scene_weather[1.0.0]_label.json"
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
---

# 六、更新记录
| 版本   | 日期       | 更新说明 |
| ------ | ---------- | -------- |
| v1.0.0 | 2021.12.07 | 初次发布 |
