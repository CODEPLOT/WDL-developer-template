version 1.0
workflow main{
        input{
             File anndata
             String project_name
           }
         call neighbors{
            input:
               anndata=anndata,
               project_name= project_name
           }
         output {
          File h5adfile=neighbors.outputfile
          }
}
task neighbors{
        input {
                File      anndata
                Int       n_neighbors = 10
                Int?      n_pcs
                String?   use_rep
                Boolean   knn = true
                String    method = 'umap'
                String?    key_added
                String   project_name
                String   docker = 'swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'
                String   memory = "4 GB"
                String   cpu    = "2"
        }
        command <<<
                set -e
                set -o pipefail
                python << code
                import scanpy as sc
                infile   = "~{anndata}"
                adata = sc.read(infile)
                kwargs = {
                        "n_neighbors"  : ~{n_neighbors},
                        "method"       : "~{method}"
                        }
                sc.pp.neighbors(adata, knn=bool(~{true=1 false=0 knn}) 
                        ~{   ",n_pcs="  + n_pcs} \
                        ~{ ",use_rep="  + use_rep}\
                        ~{",key_added="  + key_added}\
                        ,**kwargs)
                adata.write("~{project_name}_neighbor.h5ad", compression="gzip") 
                code
        >>>
        runtime {
                cpu: cpu
                memory: memory
                docker :docker
        }
  output {
        File outputfile = "${project_name}_neighbor.h5ad"
  }
}


