# 状态码表

 | 状态码                          | 值  | 含义                                                                  |
 | ------------------------------- | --- | --------------------------------------------------------------------- |
 | VNN_Result_Success              | 0   | 执行正常                                                              |
 | VNN_Result_Failed               | -1  | 预计以外的异常（除下述以外的异常），结合日志分析或向我们反馈          |
 | VNN_Result_InvalidModel         | -2  | 当前VNN SDK版本不符合模型的要求                                       |
 | VNN_Reuslt_InvalidHandle        | -3  | 所调用SDK的初始化未成功或已被释放资源                                 |
 | VNN_Result_InvalidInputData     | -4  | 输入数据异常，例如数据指针指向NULL、图像宽或高为0、data指针指向NULL等 |
 | VNN_Result_BadMalloc            | -5  | 内存申请失败                                                          |
 | VNN_Result_InvalidParamName     | -6  | 错误的参数名，或参数名为NULL                                          |
 | VNN_Result_InvalidParamValue    | -7  | 错误的参数值，或参数值为NULL                                          |
 | VNN_Result_Not_Implemented      | -8  | 接口未实现                                                            |
 | VNN_Result_FileOpenFailed       | -9  | 模型或配置的路径错误、文件损坏、 后缀名被更改、没有读文件的权限       |
 | VNN_Result_UnsupportFormat      | -10 | 不支持的图像格式（需要手动转换为可接受的格式）                        |
 | VNN_Result_Failed_GLVersion     | -11 | 内部使用                                                              |
 | VNN_Result_Failed_GLEnvironment | -12 | 内部使用                                                              |