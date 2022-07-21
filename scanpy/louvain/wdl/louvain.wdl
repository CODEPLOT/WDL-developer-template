version 1.0
workflow main{
        input{
             File anndata
             String project_name
           }
         call louvain{
            input:
               anndata=anndata,
               project_name= project_name
           }
         output {
          File h5adfile=louvain.outputfile
          File clustfile=louvain.clustfile
          }
}              
task louvain{
        input{
                File    anndata
                String  project_name
                Float   resolution    = 1
                Boolean directed      = true
                Boolean use_weights   = true
                String   flavor       = "vtraag"
                String   docker       = 'swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'
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
                        "resolution"  : ~{resolution},
                        "directed"    : bool(~{true=1 false=0 directed}),
                        "use_weights"     : bool(~{true=1 false=0 use_weights}),
                        "flavor"    : "~{flavor}",
                        }
                sc.tl.louvain(adata, **kwargs)
                if 'louvain' not in adata.obs.keys():
                        raise KeyError('louvain is not a valid `.uns` key')
                adata.obs['louvain'].reset_index(level=0).rename(columns={'index': 'cells'}).to_csv('~{project_name}_louvain_clust.tsv', sep='\t', header=True)
                adata.write("~{project_name}_leiden.h5ad", compression="gzip") 
                code
        >>>
        runtime {
                cpu: cpu
                memory: memory
                docker :docker
        }
   output {
        File outputfile = "${project_name}_leiden.h5ad"
        File clustfile  =  "${project_name}_louvain_clust.tsv"
  }
}

