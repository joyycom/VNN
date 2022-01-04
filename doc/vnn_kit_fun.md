# VNN 工具函数
- [VNN 工具函数](#vnn-工具函数)
  - [概述](#概述)
  - [日志设置](#日志设置)
  - [数据结构变换（旋转、翻转）](#数据结构变换旋转翻转)
  - [其他](#其他)

## 概述

本身是VNN提供的全部工具函数的参考。工具函数分为三类
- 日志设置
- 数据结构变换（旋转、翻转）
- 其他

功能函数的执行情况（是否成功、错误原因等）参考 ```VNN_Result``` 对应的[状态码表](./status_code.md)

---

## 日志设置
日志支持设置等级的枚举值如下

    typedef enum _VNN_LogLevel {
        VNN_LOG_LEVEL_VERBOSE   = 0x00000001, // 0b 0...00000001
        VNN_LOG_LEVEL_DEBUG     = 0x00000002, // 0b 0...00000010
        VNN_LOG_LEVEL_INFO      = 0x00000004, // 0b 0...00000100
        VNN_LOG_LEVEL_WARN      = 0x00000008, // 0b 0...00001000
        VNN_LOG_LEVEL_ERROR     = 0x00000010, // 0b 0...00010000
        VNN_LOG_LEVEL_ALL       = 0x000000ff, // 0b 0...11111111 (Easy setting to enable all log-level informations)
    } VNN_LogLevel;

支持函数如下

| 函数               | 用途                 | 完整函数签名                                             |
| ------------------ | -------------------- | -------------------------------------------------------- |
| VNN_SetLogTag      | 设置日志Tag          | VNN_Result VNN_SetLogTag(const char *i_tag)              |
| VNN_SetLogCallback | 设置日志回调函数     | VNN_Result VNN_SetLogCallback(VNNLOGCALLBACK i_callback) |
| VNN_SetLogLevel    | 设置日志打印等级     | VNN_Result VNN_SetLogLevel(VNNUInt32 i_level)            |
| VNN_GetLogLevel    | 获取当前日志打印等级 | VNN_Result VNN_GetLogLevel(VNNUInt32* o_level)           |

---

## 数据结构变换（旋转、翻转）
如果输入SDK图像与显示图像存在旋转和镜像关系，可使用以下函数对[VNN数据结构](./vnn_data_structure.md)进行相应的变换，以保证显示正确   
```旋转支持角度：0、90、180、270、360```   
如同时需要做 ```旋转``` 和  ```翻转``` 处理，处理先后顺序请参考[链接](./how_to_use_vnn_image.md#朝向描述-ori_fmt-及其类型-vnn_orient_fmt)   

| 函数                                  | 用途                                         | 完整函数签名                                                                                |
| ------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------- |
| VNN_FaceFrameDataArr_Result_Rotate    | 旋转VNN_FaceFrameDataArr 结果                | VNN_Result VNN_FaceFrameDataArr_Result_Rotate(VNN_FaceFrameDataArr* data, int rotate);      |
| VNN_FaceFrameDataArr_Result_Mirror    | 镜像（水平翻转）VNN_FaceFrameDataArr 结果    | VNN_Result VNN_FaceFrameDataArr_Result_Mirror(VNN_FaceFrameDataArr* data)                   |
| VNN_FaceFrameDataArr_Result_FlipV     | 垂直翻转 VNN_FaceFrameDataArr 结果           | VNN_Result VNN_FaceFrameDataArr_Result_FlipV(VNN_FaceFrameDataArr* data)                    |
| VNN_GestureFrameDataArr_Result_Rotate | 旋转 VNN_GestureFrameDataArr 结果            | VNN_Result VNN_GestureFrameDataArr_Result_Rotate(VNN_GestureFrameDataArr* data, int rotate) |
| VNN_GestureFrameDataArr_Result_Mirror | 镜像（水平翻转）VNN_GestureFrameDataArr 结果 | VNN_Result VNN_GestureFrameDataArr_Result_Mirror(VNN_GestureFrameDataArr* data)             |
| VNN_GestureFrameDataArr_Result_FlipV  | 垂直翻转 VNN_GestureFrameDataArr 结果        | VNN_Result VNN_GestureFrameDataArr_Result_FlipV(VNN_GestureFrameDataArr* data)              |
| VNN_ObjCountDataArr_Result_Rotate     | 旋转 VNN_ObjCountDataArr 结果                | VNN_Result VNN_ObjCountDataArr_Result_Rotate(VNN_ObjCountDataArr* data, int rotate)         |
| VNN_ObjCountDataArr_Result_Mirror     | 镜像（水平翻转）VNN_ObjCountDataArr 结果     | VNN_Result VNN_ObjCountDataArr_Result_Mirror(VNN_ObjCountDataArr* data)                     |
| VNN_ObjCountDataArr_Result_FlipV      | 垂直翻转 VNN_ObjCountDataArr 结果            | VNN_Result VNN_ObjCountDataArr_Result_FlipV(VNN_ObjCountDataArr* data)                      |
| VNN_Rect2D_Result_Rotate              | 旋转 VNN_Rect2D 结果                         | VNN_Result VNN_Rect2D_Result_Rotate(VNN_Rect2D* data, int rotate)                           |
| VNN_Rect2D_Result_Mirror              | 镜像（水平翻转）VNN_Rect2D 结果              | VNN_Result VNN_Rect2D_Result_Mirror(VNN_Rect2D* data)                                       |
| VNN_Rect2D_Result_FlipV               | 垂直翻转 VNN_Rect2D 结果                     | VNN_Result VNN_Rect2D_Result_FlipV(VNN_Rect2D* data)                                        |
| VNN_BodyFrameDataArr_Result_Rotate    | 旋转 VNN_BodyFrameDataArr 结果               | VNN_Result VNN_BodyFrameDataArr_Result_Rotate(VNN_BodyFrameDataArr* data, int rotate)       |
| VNN_BodyFrameDataArr_Result_Mirror    | 镜像（水平翻转） VNN_BodyFrameDataArr 结果   | VNN_Result VNN_BodyFrameDataArr_Result_Mirror(VNN_BodyFrameDataArr* data)                   |
| VNN_BodyFrameDataArr_Result_FlipV     | 垂直翻转 VNN_BodyFrameDataArr 结果           | VNN_Result VNN_BodyFrameDataArr_Result_FlipV(VNN_BodyFrameDataArr* data)                    |

---

## 其他
| 函数                                | 用途                                                                                                                                       | 完整函数签名                                                                                                           |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| VNN_Get_VNNImage_Bytes               | 获取 VNN_Image 中图像数据占用字节数                                                                                                        | VNN_Result VNN_Get_VNNImage_Bytes(const void * i_image, unsigned int * o_bytes)                                         |
| VNN_ObjCountDataArr_Free            | 使用ObjCountDataArr类型的SDK会动态申请内存，用于记录不确定个数的检测位置信息。在信息处理完成后需调用此函数以释放申请的内存，以避免内存泄露 | void VNN_ObjCountDataArr_Free(VNN_ObjCountDataArr *obj)                                                                |
