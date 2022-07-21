version 1.0
workflow main{
	input{
	     File anndata
	     String project_name
	   }
	 call leiden{
	    input:
	       anndata=anndata,
	       project_name= project_name
	   }
	 output {
	  File h5adfile=leiden.outputfile
	  File clustfile=leiden.clustfile
	  }
}	       
task leiden{
        input{
                File    anndata
                String  project_name
                Float   resolution          = 1
                Boolean directed            = true
                Boolean   use_weights         = true
                Float   n_iterations       = -1
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
                        "resolution"  : ~{resolution},
                        "directed"    : bool(~{true=1 false=0 directed}),
                        "use_weights"     : bool(~{true=1 false=0 use_weights}),
                        "n_iterations"    : ~{n_iterations},
                        }
                sc.tl.leiden(adata, **kwargs)
                if 'leiden' not in adata.obs.keys():
                        raise KeyError('leiden is not a valid key')
                #adata.obs['leiden'].reset_index(level=0).rename(columns={'index': 'cells'}).to_csv('leiden_clust.tsv', sep='\t', header=True)
                adata.obs[['leiden']].to_csv('~{project_name}_leiden_clust.tsv', sep='\t', header=True)
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
        File clustfile  =  "${project_name}_leiden_clust.tsv"
  }
}


