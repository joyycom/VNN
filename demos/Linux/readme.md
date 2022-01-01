- [1. Linux端demo的第三方依赖](#1-Linux端demo的第三方依赖)
- [2. Linux工程](#2-Linux工程)
- [3. 其它](#3-其它)
# 1. Linux端demo的第三方依赖
opencv3.4.6,  [安装教程](https://docs.opencv.org/3.4.6/d7/d9f/tutorial_linux_install.html)
# 2. Linux工程
## 2.1 头文件
拷贝根目录下 ```libs/headers``` 文件夹中的头文件放入```vnn_linux_demo/prebuilt/inc``` 文件夹中。
## 2.2 库文件
解压缩 ```libs/Linux/vnn_linux_libs.zip```,将解压缩后得到的so文件拷贝到 ```vnn_linux_demo/prebuilt/lib``` 文件夹中。
## 2.3 编译
vnn_linux_demo文件夹中新建build文件夹，mkdir build
cd build
cmake ..
make
此时会生成一个bin文件夹
## 2.4 拷贝模型文件
上一步生成的bin文件夹中新建文件夹，命名vnn_models, 拷贝根目录下models文件夹中的内容放入```vnn_models```文件夹中。
## 2.5 运行demo
cd bin
./vnn_linux_demo
## 2.6 运行界面
Linux端的运行界面和[Windows](./../Windows/readme.md)端基本一致。

# 3. 其它
## (1) Demo使用Ubuntu16.04开发，仅用来展示如何调用VNN SDK 。
## (2) 只提供64位的sdk 。
## (3) opencv版本仅供参考，可以安装自己需要的版本，修改CMakeLists.txt指定需要的opencv路径。