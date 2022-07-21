version 1.0
workflow main{
        input{
             File anndata
             String project_name
           }
         call tsne{
            input:
               anndata=anndata,
               project_name= project_name
           }
         output {
          File h5adfile=tsne.outputfile
          }
}             
task tsne{
        input{
                File    anndata
                String  project_name
                Float   perplexity         = 30
                Float   early_exaggeration = 12
                Float   learning_rate      = 1000
                String   memory ="4 GB"
                String   cpu="2"
                String   docker='swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'
        }
        command <<<
                set -e
                set -o pipefail
                python << code
                import scanpy as sc
                infile   = "~{anndata}"
                adata = sc.read(infile)
                kwargs = {
                        "perplexity"  : ~{perplexity},
                        "early_exaggeration"    : ~{early_exaggeration},
                        "learning_rate"     : ~{learning_rate}
                        }
                sc.tl.tsne(adata, **kwargs)
                adata.obsm.to_df()[['X_tsne1','X_tsne2']].to_csv('~{project_name}_Scanpy_X_tsne.tsv',sep='\t', header=True)
                adata.write("~{project_name}_tsne.h5ad", compression="gzip") 
                code
        >>>
        runtime {
                cpu: cpu
                memory: memory
                docker :docker
        }
  output {
        File outputfile = "${project_name}_tsne.h5ad"
        File clustfile  = "${project_name}_Scanpy_X_tsne.tsv"
  }
}
