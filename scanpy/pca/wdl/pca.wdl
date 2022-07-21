version 1.0
workflow main{
        input{
             File anndata
             String project_name
           }
         call pca{
            input:
               anndata=anndata,
               project_name= project_name
           }
         output {
          File h5adfile=pca.outputfile
          Array[File] pngfile=pca.pngfile
          }
}              
task pca{
        input {
                File     anndata
                Int?     n_comps
                String   svd_solver  = 'arpack'
                Boolean  zero_center = true
                Boolean?  use_highly_variable
                String   project_name
                String   docker = 'swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'
                String   memory ="4 GB"
                String   cpu="2"
        }
        command <<<
                set -e
                set -o pipefail
                python << code
                import scanpy as sc
                infile   = "~{anndata}"
                adata = sc.read(infile)
                sc.pp.pca(adata ~{ ",n_comps=" +n_comps},svd_solver="~{svd_solver}",zero_center=bool(~{true=1 false=0 zero_center}),\
                        ~{true=",use_highly_variable=True" false=",use_highly_variable=False" use_highly_variable}
                        )
                sc.pl.pca_variance_ratio(adata, log=True, save=".png")
                adata.write("~{project_name}_pca.h5ad", compression="gzip") 
                code
        >>>
        runtime {
                cpu: cpu
                memory: memory
                docker :docker
        }
  output {
        File outputfile = "${project_name}_pca.h5ad"
        Array[File] pngfile    = glob("figures/*png")
  }
}
