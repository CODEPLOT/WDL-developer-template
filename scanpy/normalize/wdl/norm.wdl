version 1.0
workflow main{
        input{
             File anndata
             String project_name
           }
         call normalize{
            input:
               anndata=anndata,
               project_name= project_name
           }
         output {
          File h5adfile=normalize.outputfile
          }
}            
task normalize{
        input { 
                File     anndata
                String   project_name
                Float    target_sum = 10000
                String  memory  = "4 GB"
                String   docker = 'swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'
                String  cpu="2"
        }
        command <<<
                set -e
                set -o pipefail
                python << code
                import scanpy as sc
                infile   = "~{anndata}"
                adata = sc.read(infile)
                sc.pp.normalize_total(adata, target_sum=~{target_sum})
                sc.pp.log1p(adata)
                adata.raw = adata
                adata.write("~{project_name}_norm.h5ad", compression="gzip") 
                code
        >>>
        runtime {
                cpu: cpu
                memory: memory
                docker :docker
        }
  output {
        File outputfile = "${project_name}_norm.h5ad"
  }
}

