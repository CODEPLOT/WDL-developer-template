# 简介
BLAST(Basic Local Alignment Search Tool)是生物序列相似性比较及区域查找的分析工具。可用于推断序列之间的功能和进化关系，以及帮助鉴定基因家族的成员。

该BLAST WDL 工作流程采用 ncbi-BLAST+ 2.13.0 软件
其主要包括以子程序：
- blastp：蛋白序列与蛋白库做比对。
- blastx：核酸序列对蛋白库的比对。
- blastn：核酸序列对核酸库的比对。
- tblastn：蛋白序列对核酸库的比对，将给定的氨基酸序列与核酸数据库中的序列（双链）按不同的阅读框进行比对。
- tblastx: 核酸序列对核酸库的比对，检索的序列和核酸序列数据库中的序列按不同的阅读框全部翻译成蛋白质序列，然后进行蛋白质序列比对。
 
 可以通过`method`参数切换不同子程序，默认 为blastn。
 
 BLAST详细说明请查阅[NCBI 说明文档](https://www.ncbi.nlm.nih.gov/books/NBK153387/)
 
# 使用案例

## 1.使用预设BLAST Database 

  目前该流程收纳了国家基因库新冠数据库数据，未来我们会收纳更多国家基因库归档数据，您可以配置通过 input 中`dbname` 参数，选择不同数据库。
  
## 2. 自定义BLAST Database
   你可以通过 File 类型参数 `custom_db` 及 String 类型参数 `custom_db_dbtype`  分别定义您需要检索自定义数据库序列文件和文件类型。


除此之外，我们支持用户个性化修改不同子程序的默认参数，从而达到理想的结果。

如：修改`Task name` 中 blast.runtblastn 的 `Attribute name` 为word_size即修改blast工作流中blastn中特异的word_size 参数。

  详细参数介绍查看下文input参数。
## 联系我们
该工具由国家基因库团队提供。如有任何问题或疑虑，请联系CNGBdb@cngb.org
