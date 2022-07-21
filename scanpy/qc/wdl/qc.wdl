version 1.0
workflow main{
        input{
             File infile
             String project_name
           }
         call qc{
            input:
               infile=infile,
               project_name= project_name
           }
         output {
          File h5adfile=qc.outputfile
          Array[File] pngfile=qc.pngfile
          }
}             
task qc{
	input {	
		File    infile
		String  filetype
		String	project_name
		String  docker='swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'
		String  cpu      = '2'
		String  memory   ='4G'
		Int     min_gene = 200
		Int     min_cell = 3
		Int?    genes    
		Int     per_mt   = 5
	}
	command <<<
		set -e
		set -o pipefail
		python << code
		import scanpy as sc
		import numpy as np
		filetype = "~{default="csv" filetype}"
		infile   = "~{infile}"
		if filetype=='csv':
			adata = sc.read_csv(infile, delimiter=",", first_column_names=True).T
		elif filetype=='tsv':
			adata = sc.read_csv(infile, delimiter="\t", first_column_names=True).T
		elif filetype=='10x_mtx':
			adata = sc.read_csv(infile)
		sc.settings.autosave = True
		#filter and QC
		sc.pl.highest_expr_genes(adata, n_top=20, save=".png")
		sc.pp.filter_cells(adata, min_genes=~{min_gene})
		sc.pp.filter_genes(adata, min_cells=~{min_cell})
		adata.var['mt'] = adata.var_names.str.startswith('MT-')
		sc.pp.calculate_qc_metrics(adata, qc_vars=['mt'], percent_top=None, inplace=True)
		sc.pl.violin(adata, ['n_genes_by_counts', 'total_counts', 'pct_counts_mt'], jitter=0.4, multi_panel=True, save=".png")
		sc.pl.scatter(adata, x='total_counts', y='pct_counts_mt', save=".png")
		sc.pl.scatter(adata, x='total_counts', y='n_genes_by_counts', save=".png")
		~{"genes = " + genes}
		if  '~{genes}':
			adata = adata[adata.obs.n_genes < genes, :]
		else:
			yz=np.percentile(adata.obs['n_genes'], (5, 95), interpolation='midpoint')
			adata = adata[adata.obs.n_genes < yz[1], :]
			adata = adata[adata.obs.n_genes > yz[0], :]
		adata = adata[adata.obs.pct_counts_mt < ~{per_mt}, :]
		adata.write("~{project_name}.h5ad", compression="gzip")	
		code
	>>>
	runtime {
		memory: memory
		cpu: cpu
		docker :docker
	}
  output {
    	File outputfile = "${project_name}.h5ad"
 	Array[File] pngfile    = glob("figures/*png")
  }
}

