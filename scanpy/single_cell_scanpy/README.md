# 简介
[Scanpy](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-017-1382-0) 是单细胞转录组常用且主流的分析Python工具包，用于分析与anndata联合构建的单细胞基因表达数据。它包括预处理、可视化、聚类、轨迹推断和差异表达测试。能够有效地处理超过一百万个单元的数据集。
 
本工作流基于Scanpy 3k PBMC官方教程归纳扩展的WDL工作流，并提取常调整参数以供针对不同个性化数据进行调整。同时按下图步骤拆分10小流程供用户单独调试单个步骤结果。可在工具集搜索对应工作流，使用对应输出H5AD文件进行调试。你也可以根据我们提供的Scanpy Notebook工具进行代码调试。

详细参数说明见下文input介绍，
![image](https://db.cngb.org/cdcp/img/analysis.e4a092e9.png)

##### 3.1.1qc.wdl
this workflow load files and calculate quality control metrics by `scanpy.pp.calculate_qc_metrics`。

这个工作流是加载文件并通过`scanpy.pp.calculate_qc_metrics`计算质量指标同时可选择的过滤原始矩阵中基因表达较少的细胞和在细胞中检测较少的基因。

#### 3.1.2norm.wdl
this workflow normalize counts per cell and logarithmize the data matrix .

标准化每个单元的计数并将数据矩阵对数变化。



##### 3.1.3hvg.wdl
this workflow accepts h5fd file and annotate highly variable genes ,regress out (mostly) unwanted sources of variation then cale data to unit variance and zero mean  with *sc.pp.highly_variable_genes* ,*sc.pp.regress_out* and *sc.pp.scale*.

接受h5fd文件作为输入，注释高度可变的基因，回归出（大部分）不需要的变异源，然后将数据缩放到单位方差和零均值


##### 3.1.4pca.wdl

Principal component analysis

主成分分析


##### 3.1.5neighbors.wdl

Compute a neighborhood graph of observations 


计算观测值的邻域图


## umap.wdl/tsne.wdl

this workflow embed the neighborhood graph using umap or tsne  

非线性降维
## leiden.wdl/louvain.wdl

 cluster cells into subgroups  
 
 细胞聚类


## maker.wdl
this workflow rank genes for characterizing groups

对每个 cluster 中高度差异基因的排名


# 联系我们
该工具由国家基因库团队提供。如有任何问题或疑虑，请联系 CNGBdb@cngb.org

