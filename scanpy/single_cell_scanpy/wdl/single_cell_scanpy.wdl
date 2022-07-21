version 1.0
workflow scanpy{
	input{
		File    infile
		String  filetype
		String  project_name
		String embed_method='umap'
		String	cluster_method='leiden'
		String  docker='swr.cn-south-1.myhuaweicloud.com/cngbdb/scanpy_docker:1.4.6'

	}
	call qc{
		input:
			infile       = infile,
			filetype     = filetype,
			docker       = docker,
			project_name = project_name
	}
	call normalize{
		input:
			anndata     = qc.outputfile,
			docker       = docker,
			project_name = project_name
		}

	call  hvg{
		input :
                	anndata       = normalize.outputfile, 
			docker       = docker,
			project_name  = project_name
	}
	call pca{
		input :
			anndata       = hvg.outputfile,
			docker       = docker,
			project_name  = project_name
	}
	call neighbors{
		input :
			anndata       = pca.outputfile,
			docker       = docker,
			project_name  = project_name
		}
	if (embed_method== 'umap'){
		call umap{
			input :
				anndata       = neighbors.outputfile,
				docker       = docker,
				project_name  = project_name
		}
	}
	if (embed_method== 'tsne'){
		call tsne{
			input :
				anndata       = neighbors.outputfile,
				docker       = docker,
				project_name  = project_name
		}
	}
	if (cluster_method =='leiden'){
		call leiden{
			input :
				anndata       = select_first([umap.outputfile,tsne.outputfile]),
				docker       = docker,
				project_name  = project_name
		}
	}
	if (cluster_method =='louvain'){
		call louvain{
			input :
				anndata       = select_first([umap.outputfile,tsne.outputfile]),
				docker       = docker,
				project_name  = project_name
		}
	}
	call marker{
		input : 
			anndata       = select_first([leiden.outputfile,louvain.outputfile]),
			project_name  = project_name,
			docker       = docker,
			groupby      = cluster_method
		}
	output{
	File metadata = select_first([umap.clustfile,umap.clustfile])
	File clust    = select_first([louvain.clustfile,leiden.clustfile])
	File fina_h5ad = marker.outputfile
	}
}
task qc{
	input {	
		File    infile
		String  filetype
		String	project_name
		String   cpu="2"
		String   memory="4 GB"
		String   docker
		Int     min_gene = 200
		Int     min_cell = 3
		Int     genes    = 2500
		Int     per_mt   = 5
	}
	command <<<
		set -e
		set -o pipefail
		python << code
		import scanpy as sc
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
		adata = adata[adata.obs.n_genes < ~{genes}, :]
		adata = adata[adata.obs.pct_counts_mt < ~{per_mt}, :]
		adata.write("~{project_name}.h5ad", compression="gzip")	
		code
	>>>
	runtime {
		cpu: cpu
		memory: memory
		docker :docker
	}
  output {
    	File outputfile = "${project_name}.h5ad"
 	Array[File] pngfile    = glob("figures/*png")
  }
}

task normalize{
	input {	
		File     anndata
		String	 project_name
		Float    target_sum = 10000
		String  memory ="4 GB"
		String   docker
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

task hvg{
	input {	
		File     anndata
		Float    min_mean = 0.125
		String	 project_name
		Float    max_mean = 3
		Float    min_disp = 0.5
		Float?   max_disp
		Float    max_value = 10 
		Int?     n_top_genes
		String?  flavor 
		Boolean? subset
		String   memory ="4 GB"
		String   docker
		String   cpu="2"
	}
	command <<<
		set -e
		set -o pipefail
		python << code
		import scanpy as sc
		infile   = "~{anndata}"
		kwargs = {
			"min_mean" : ~{min_mean},
			"flavor"   : "~{default='seurat' flavor}", 
			"max_mean" : ~{max_mean},
			"min_disp" : ~{min_disp}
			}
		maxdisp=float('~{default='inf' max_disp}')
		adata = sc.read(infile)
		sc.pp.highly_variable_genes(adata,max_disp=maxdisp,subset=bool(~{true=1 false=0 subset}) ~{",n_top_genes=" +n_top_genes}, **kwargs)
		sc.pl.highly_variable_genes(adata, save=".png")
		adata = adata[:, adata.var.highly_variable]
		sc.pp.regress_out(adata, ['total_counts', 'pct_counts_mt'])# log1
		sc.pp.scale(adata, max_value=~{max_value})
		adata.write("~{project_name}_hvg.h5ad", compression="gzip") 
		code
	>>>
	runtime {
		cpu: cpu
		memory: memory
		docker :docker
	}
  output {
    	File outputfile = "${project_name}_hvg.h5ad"
 	Array[File] pngfile    = glob("figures/*png")
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
		String   docker
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
		String   docker
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
		String   docker
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

task tsne{
	input{
		File    anndata
		String  project_name
		Float   perplexity         = 30
		Float   early_exaggeration = 12
		Float   learning_rate      = 1000
		String   memory ="4 GB"
		String   cpu="2"
		String   docker
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
		String   docker
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


task louvain{
	input{
		File    anndata
		String  project_name
		Float   resolution    = 1
		Boolean directed      = true
		Boolean use_weights   = true
		String   flavor       = "vtraag"
		String   docker
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
task marker{
	input{
		File    anndata
		String  project_name
		String method  = 't-test'
		String?  groupby 
		Int?    n_genes = 100
		String   memory ="4 GB"
		String   cpu="2"
		String   docker
		}
	 command <<<
		set -e
		set -o pipefail
		python << code
		import scanpy as sc
		infile   = "~{anndata}"
		adata = sc.read(infile)
		kwargs = {
			"n_genes"  : ~{n_genes},
			"method"   : "~{method}"
		}
		sc.tl.rank_genes_groups(adata,  "~{groupby}",**kwargs)
		sc.pl.rank_genes_groups(adata, n_genes=25, sharey=False,save=".png")
		adata.write("~{project_name}_marker.h5ad", compression="gzip") 
		code
	>>>
	runtime {
		cpu: cpu
		memory: memory
		docker :docker
	}
  output {
 	Array[File] pngfile    = glob("figures/*png")
    	File outputfile = "${project_name}_marker.h5ad"
  }
}
