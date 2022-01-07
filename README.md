![Logo](./doc/resource/vnn_logo.png)

# 简介
VNN是由[欢聚集团(Joyy Inc.)](http://www.huanju.cn/)推出的高性能、轻量级神经网络部署框架。目前已为[Hago](https://www.ihago.net/)、[VOO](https://vooedit.com/)、[VFlyCloud](https://cloud.vflyapp.com/desktop)、[VFly](https://api-web.vflyapp.com/)、[马克水印相机](https://www.markiapp.com/)等App提供20余种AI能力的支持，覆盖直播、短视频、视频编辑等泛娱乐场景和工程场景

**特性**
- 免费：无授权控制，无广告植入
- 安全：零权限需求
- 跨平台一致设计和体验：良好支持Andorid/iOS/Windows/MacOS(Intel & Apple Chip)/Linux系统平台
- 轻盈：全部功能SDK打包体积 Andorid 2.3M(arm64), iOS 2.0M(arm64)
- 易用：API风格简洁、统一

---

# 支持能力
![ability](./doc/resource/ability.png)


---

## 人脸关键点
 | ![face_Img](./doc/resource/face_img.jpg) | ![face_keypoints](./doc/resource/face_keypoints.jpg) | ![face_Img](./doc/resource/face_beautify.png) | ![face278](./doc/resource/face278.gif) |
 | :--------------------------------------: | :--------------------------------------------------: | :-------------------------------------------: | :------------------------------------: |
 |                   原图                   |    [人脸关键点](./doc/face_landmark_detection.md)    |                     美颜                      |                动态效果                |

### 指标对比
![face104compare](./doc/resource/face104compare.png)  ![face278compare](./doc/resource/face278compare.png)
---

# 各功能效果展示

 

 | ![disney_example](./doc/resource/disney_example.gif) | ![3dgame_example](./doc/resource/3dgame_example.gif) |     ![comic_example](./doc/resource/comic_example.gif)     |
 | :--------------------------------------------------: | :--------------------------------------------------: | :--------------------------------------------------------: |
 |  [迪士尼人脸风格化](./doc/disney_face_stylizing.md)  | [3D游戏人脸风格化](./doc/3d_game_face_stylizing.md)  | [油画图像风格化](./doc/cartoonstylizing_comicstylizing.md) |

 | ![portrait_segment_example](./doc/resource/portrait_segment_example.gif) | ![animal_segment_example](./doc/resource/animal_segment_example.gif) | ![sky_segment_example](./doc/resource/sky_segment_example.gif) |
 | :----------------------------------------------------------------------: | :------------------------------------------------------------------: | :------------------------------------------------------------: |
 |                [人像分割](./doc/general_segmentation.md)                 |              [动物分割](./doc/general_segmentation.md)               |           [天空分割](./doc/general_segmentation.md)            |

  | ![clothes_segment_example](./doc/resource/clothes_segment_example.gif) | ![animal_segment_example](./doc/resource/hair_segment_eaxmple.gif) | ![face_reenactment_example](./doc/resource/face_reenactment_example.gif) |
  | :--------------------------------------------------------------------: | :----------------------------------------------------------------: | :----------------------------------------------------------------------: |
  |           [衣物分割（换色）](./doc/general_segmentation.md)            |         [头发分割（换色）](./doc/general_segmentation.md)          |                [人脸表情驱动](./doc/face_reenactment.md)                 |


---

## Demo体验

 | 平台  |                            Andorid                            |         iOS         |                                      Windows                                      |         MacOS         |         Linux         |
 | :---: | :-----------------------------------------------------------: | :-----------------: | :-------------------------------------------------------------------------------: | :-------------------: | :-------------------: |
 |       | [apk](./demos/Android/vnn_demo.apk) / [工程](./demos/Android) | [工程](./demos/iOS) | [exe](./demos/Windows/executable_demo/vnn_win_demo.exe) / [工程](./demos/Windows) | [工程](./demos/MacOS) | [工程](./demos/Linux) |

---

## 集成指引与SDK文档

- [Android集成指引](./demos/Android/readme.md)  
- [iOS集成指引](./demos/iOS/readme.md)  
- [MacOS(Intel & Apple Chip)集成指引](./demos/MacOS/readme.md)   
- [Windows集成指引](./demos/Windows/readme.md)   
- [Linux集成指引](./demos/Linux/readme.md)   
- [SDK文档索引](./doc/doc_index.md)   
- [常见问题](./doc/question_and_answer.md)

---

## Acknowledgement
参考了以下项目：
- [RapidJSON](https://github.com/Tencent/rapidjson)
- [ncnn](https://github.com/Tencent/ncnn)
- [ppl](https://github.com/openppl-public/ppl.nn)
- [MNN](https://github.com/alibaba/MNN)
- [TNN](https://github.com/Tencent/TNN)

---

## 更新计划
- 发布模型转换工具链以及模型调用接口
- 发布libs核心源代码

---
## License

[MIT](./license.txt)

---
## 注明
如果有商用或使用问题可以随时联系我们：  
edenworm@gmail.com, yong1514@gmail.com, fengwu092@gmail.com, ningpeiyang@joyy.com