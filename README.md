# 简介
 该仓库说明了在CODEPLOT 开发WDL 相关规则和要求；
## github 文件目录结构标准
   - wdl:存放wdl文件，标准输入和输出模板；
   - docker：wdl文件所引用的镜像的Dockerfile 文件按，及镜像包含测试文件（可选）
   - scripts：wdl中定义的脚本文件；
   - test： wdl进行测试相关的测试文件和测试脚本
   - notebook（可选）： WDL 的notebook 实践
 ## WDL开发说明
 WDL 语法简介 请看说明 https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md#types
 我们推荐开发者尽量使用 WDL version 1.0语法规则进行相应WDL 开发：
 ### WDL开发注意事项：
   禁止在WDL中使用绝对路径文件，CODEPLOT中WDL是在容器内运行，无固定化路径，文件引入，请使用 File 类型进行定义。
 ###WDL 开发流程
 
![未命名文件 (1)](https://user-images.githubusercontent.com/46242303/216245900-e22285a1-0144-43ef-9c20-7a3388b257c3.png)

1.开发WDL流程

2.制作流程运行环境-Docker镜像

3.基于本地测试WDL流程. [cromwell软件下载](https://github.com/broadinstitute/cromwell/tags)

```shell 
java -jar cromwell-xx.jar run demo.wdl -i demo.json

4.准备发布工具元信息
— 流程输入参数描述文件
|  参数名称   | 参数名称  |英文描述 | 中文描述 | 是否必要参数 |默认值|取值范围
|  ----  | ----  |
| 单元格  | 单元格 |
| 单元格  | 单元格 |
