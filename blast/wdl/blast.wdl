workflow blast {
	String? blast_docker_override
	String  blast_docker= select_first([blast_docker_override,"swr.cn-north-4.myhuaweicloud.com/cngbdb/blast:1.2"])
	File    queryfa
	File?   custom_db
	Boolean is_db = defined(custom_db)
	String? custom_db_dbtype = 'nucl'
	String  method      = 'blastn'
	Int     outfmt      = 7
	Float   evalue      = 10
	String  Outfile     =basename(queryfa)+'.blast_result.txt'
	Int     threads     = 8
	String?  dbname 
  if (is_db){
      call makeblastdb{
         input:
		custom_db  = custom_db,
		custom_db_dbtype = custom_db_dbtype,
   }
   String custom_db_path = makeblastdb.blastdb[0]+"/blastdb"
}
  #String?  dbpath_spe = "/sfs/blastdb/"+dbname
	String  dbpath = select_first([custom_db_path,dbname])     
	  
	if ( method == 'blastp'){ 
	  call runblastp{
	    input:
		dbpath      = dbpath,
		Queryfa    = queryfa,
		docker     = blast_docker,
		outfmt     = outfmt,
		evalue     = evalue,
		Outfile    = Outfile,
		threads	   = threads,
		}		
	  }
	if ( method == 'blastn'){
	  call runblastn{
	     input:
		dbpath      = dbpath,
		Queryfa    = queryfa,
		docker     = blast_docker,
		outfmt     = outfmt,
		evalue     = evalue,
		Outfile    = Outfile,
		threads    = threads,
	     }
 	 }
	if ( method == 'blastx'){
	  call runblastx{
	    input:
		dbpath      = dbpath,
                Queryfa    = queryfa,
                docker     = blast_docker,
                outfmt     = outfmt,
                evalue     = evalue,
                Outfile    = Outfile,
                threads    = threads,
	    }
	}
	if ( method == 'queryfa'){
	  call runtblastn{
            input:
		dbpath      = dbpath,
                Queryfa    = queryfa,
                docker     = blast_docker,
                outfmt     = outfmt,
                evalue     = evalue,
                Outfile    = Outfile,
                threads    = threads,
		}
	   }
	if ( method == 'tblastx'){
          call runtblastx{
            input:
                dbpath      = dbpath,
                Queryfa    = queryfa,
                docker     = blast_docker,
                outfmt     = outfmt,
                evalue     = evalue,
                Outfile    = Outfile,
                threads    = threads,
                }
           }

		
	output {
	  File fina_output =select_first([runtblastx.out,runblastp.out,runblastn.out,runblastx.out,runtblastn.out])
	}

}
task makeblastdb{
	File custom_db
	String custom_db_dbtype
	String docker
    command {
    set -e 
    pwd
    # default blastdb as name
    makeblastdb -in ${custom_db} -dbtype ${custom_db_dbtype} -out blastdb -title "blastdb" -parse_seqids -blastdb_version 5 
   }
    runtime{
         docker : docker
         cpu    : "2"
         memory : "4G"
  }
    output {
        Array[String] blastdb = read_lines(stdout())
    }
}

task runblastn {
	String  docker
	File    Queryfa
	String  dbpath
	String  Outfile 
	Int	threads
#blast optional 
	Int     outfmt
	Int     max_target_seqs = 100 
	Float   evalue         
	Int     word_size       = 28
	Int     reward          = 1
	Int     penalty         = -2
	String  strand          = 'both'
        Int     gapopen         = 0
	Int     gapextend       = 0
	String  dust            = "'20 64 1'"
	Int?    max_hsps       
	String  tasks           = "megablast"
	String?   taxids          
	String? negative_taxids
	Boolean lcase_masking   = false
    command {
	set -e
	blastn -db "${dbpath}" \
		-show_gis \
		-query ${Queryfa} \
		-outfmt ${outfmt} \
		-out	 ${Outfile} \
		-max_target_seqs ${max_target_seqs} \
		-evalue ${evalue} \
		-word_size ${word_size} \
		-penalty ${penalty} \
		-reward  ${reward} \
		-dust ${dust} \
		-gapopen ${gapopen} \
		-gapextend ${gapextend} \
		-task ${tasks} \
		-strand  ${strand} \
		-num_threads ${threads} \
		${true='-lcase_masking' false='' lcase_masking} ${"-max_hsps "+max_hsps} ${"-taxids " +taxids} ${"-negative_taxids " +negative_taxids}\
		
    }
    runtime{
	docker : docker
	cpu    : "2"
	memory : "4G"
	}
    output {
        File out = "${Outfile}"
    }
}
task runblastp {
	String  docker
	File    Queryfa
	String  dbpath
#blast optional 
	Int     outfmt
	String  Outfile
	Float   evalue            
	Int	threads
	Int     max_target_seqs  = 100 
	Int     word_size        = 6
        String seg               = "no"
        String comp_based_stats  = "2"
        String matrix            = "BLOSUM62"
        Int     gapopen          = 11
	Int     gapextend        = 1
	Int?    max_hsps         
        String?   taxids
        String? negative_taxids
	Boolean lcase_masking    = false
    command {
	set -e
	blastp -db "${dbpath}" \
		-query ${Queryfa} \
		-outfmt ${outfmt} \
		-out	 ${Outfile} \
		-max_target_seqs ${max_target_seqs} \
		-comp_based_stats ${comp_based_stats} \
		-evalue ${evalue} \
		-word_size ${word_size} \
		-matrix   ${matrix} \
                -seg     ${seg} \
		-gapopen ${gapopen} \
		-gapextend ${gapextend} \
		-num_threads ${threads} \
		${true='-lcase_masking' false='' lcase_masking} ${"-max_hsps "+max_hsps} ${"-taxids " +taxids} ${"-negative_taxids " +negative_taxids} \
		
    }
    runtime{
	docker : docker
	cpu    : "2"
	memory : "4G"
	}
    output {
        File out = "${Outfile}"
    }
}
task runblastx {
	File   Queryfa
	String dbpath
	Int    outfmt
	Float  evalue
	String Outfile
	String docker
	Int     threads
	Int    max_target_seqs  =  100 
	Int    word_size        =  6
	String seg              =  "'12 2.2 2.5'"
	String comp_based_stats =  "2"
	String matrix           =  "BLOSUM62"
        Int    gapopen          =  11
	Int    gapextend        =  1
        String?   taxids
        String? negative_taxids
	Int?    max_hsps
	Boolean lcase_masking    = false
    command {
	set -e
	blastx -db "${dbpath}" \
		-query ${Queryfa} \
		-outfmt ${outfmt} \
		-out	 ${Outfile} \
		-max_target_seqs ${max_target_seqs} \
		-comp_based_stats ${comp_based_stats} \
		-evalue ${evalue} \
		-word_size ${word_size} \
		-matrix   ${matrix} \
		-seg     ${seg} \
		-gapopen ${gapopen} \
		-gapextend ${gapextend} \
		-num_threads ${threads} \
		${true='-lcase_masking' false='' lcase_masking} ${"-max_hsps "+max_hsps} ${"-taxids " +taxids} ${"-negative_taxids " +negative_taxids}\
		
    }
    runtime{
	docker : docker
	cpu   : "2"
        memory : "4G"

	}
    output {
        File out = "$${Outfile}"
    }
}
task runtblastn {
	File   Queryfa
	String dbpath
	Int    outfmt
	Float  evalue
	String Outfile         
	String docker
	Int    threads
	Int    max_target_seqs  = 100 
	Int    word_size        = 6
	String seg              = "'12 2.2 2.5'"
	String comp_based_stats = "2"
	String matrix           = "BLOSUM62"
        Int    gapopen          = 11
	Int    gapextend        = 1
	Boolean lcase_masking   = false
	Int?    max_hsps
	String?   taxids
        String? negative_taxids
    command {
	set -e
	tblastn -db "${dbpath}" \
		-query ${Queryfa} \
		-outfmt ${outfmt} \
		-out	${Outfile} \
		-max_target_seqs ${max_target_seqs} \
		-comp_based_stats ${comp_based_stats} \
		-evalue ${evalue} \
		-word_size ${word_size} \
		-matrix   ${matrix} \
		-seg     ${seg} \
		-gapopen ${gapopen} \
		-gapextend ${gapextend} \
		-num_threads ${threads} \
		${true='-lcase_masking' false='' lcase_masking} ${"-max_hsps "+max_hsps} ${"-taxids " +taxids} ${"-negative_taxids " +negative_taxids}\
		
    }
    runtime{
	docker :docker
        cpu    : "2"
        memory : "4G"

	}
    output {
        File out = "${Outfile}"
    }
}
task runtblastx {
	File   Queryfa
	String dbpath
	Int    outfmt
	String Outfile   
	String threads        
	Float  evalue
	String docker
        String?   taxids
	Int    word_size        = 3
	Int    max_target_seqs  = 100
	String seg              = "'12 2.2 2.5'"
	String matrix           = "BLOSUM62"
	Boolean lcase_masking   = false
        String? negative_taxids
	Int?    max_hsps
    command {
	set -e
	tblastx -db "${dbpath}" \
		-query ${Queryfa} \
		-outfmt ${outfmt} \
		-out	 ${Outfile} \
		-max_target_seqs ${max_target_seqs} \
		-evalue ${evalue} \
		-word_size ${word_size} \
		-matrix   ${matrix} \
		-seg     ${seg} \
		-num_threads ${threads} \
		${true='-lcase_masking' false='' lcase_masking} ${"-max_hsps "+max_hsps} ${"-taxids " +taxids} ${"-negative_taxids " +negative_taxids}\
		
    }
    runtime{
	docker :docker
        cpu    : "2"
        memory : "4G"
	}
    output {
        File out = "${Outfile}"
    }
}

