version 1.0
workflow main{
        input{
             File anndata
             String project_name
           }
         call umap{
            input:
               anndata      =  anndata,
               project_name = project_name
           }
         output {
          File h5adfile  = umap.outputfile
          File clustfile = umap.clustfile
          }
}             
task umap{
        input{
                File    anndata
                Float   min_dist = 0.5
                Float   spread   = 1.0
                Float   alpha    = 1.0
                Float   gamma    = 1.0
                Int     n_components = 2
                Int     negative_sample_rate =5
                String  init_pos  = 'spectral'
                String  project_name
                String   docker='swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'
                String   memory ="4 GB"
                String  cpu="2"
        }
        command <<<
                set -e
                set -o pipefail
                python << code
                import scanpy as sc
                infile   = "~{anndata}"
                adata = sc.read(infile)
                kwargs = {
                        "min_dist"  : ~{min_dist},
                        "spread"    : ~{spread},
                        "alpha"     : ~{alpha},
                        "gamma"     : ~{gamma},
                        "n_components" : ~{n_components},
                        "negative_sample_rate" : ~{negative_sample_rate},
                        "init_pos"  : "~{init_pos}"
                        }
                sc.tl.umap(adata, **kwargs)
                adata.obsm.to_df()[['X_umap1','X_umap2']].to_csv('~{project_name}_Scanpy_X_umap.tsv',sep='\t', header=True)
                adata.write("~{project_name}_umap.h5ad", compression="gzip") 
                code
        >>>
        runtime {
                cpu: cpu
                memory: memory
                docker :docker
        }
  output {
        File outputfile = "${project_name}_umap.h5ad"
        File clustfile  = "${project_name}_Scanpy_X_umap.tsv"
  }
}

