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
 ### 注意事项：
   CODEPLOT中WDL是在容器内运行，无固定化路径，文件引入，请使用 File 类型进行定义。
