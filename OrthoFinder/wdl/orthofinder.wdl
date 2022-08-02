version 1.0
task  orthofinder{
    input {
    Array[File]  fastas
    Int          search_threads=16
    Int          analysis_threads=1
    File?        rooted_tree
    Float        mcl_inflation=1.5
    Boolean?     is_dna
    Boolean?     is_SplitParaClade
    String       cpu
    String       memory
    }
    command {
        mkdir input
        ln -s  ${sep=" " fastas}  ./input/
        orthofinder -f ./input/ ~{true='-y' false='' is_SplitParaClade}  ~{true='-d' false='' is_dna}\
                            ~{" -I " +mcl_inflation}   ~{" -s " +rooted_tree}  \
                            ~{" -t " +search_threads} ~{" -a " +analysis_threads}
         find input/OrthoFinder/Results*/Orthogroup_Sequences/* -type f >/tmp/tmp.file # 避免超过三万个文件报错
         tar -zcvf Orthogroup_Sequences.tar.gz --files-from /tmp/tmp.file
         find input/OrthoFinder/Results*/Orthogroup_Sequences/* -type f >/tmp/tmp.file
         tar -zcvf Gene_Trees.tar.gz  --files-from /tmp/tmp.file
         find input/OrthoFinder/Results*/Orthogroup_Sequences/* -type f >/tmp/tmp.file
         tar -zcvf Resolved_Gene_Trees.tar.gz  --files-from /tmp/tmp.file
         find input/OrthoFinder/Results*/Orthogroup_Sequences/* -type f >/tmp/tmp.file
         tar -zcvf Single_Copy_Orthologue_Sequences.tar.gz  --files-from /tmp/tmp.file
    }
        runtime {
                cpu: cpu
                memory: memory
                docker :"swr.cn-south-1.myhuaweicloud.com/cngbdb/orthofinder:2.4.1"
        }
  output {
        Array[File] Statistics = glob("input/OrthoFinder/Results*/Comparative_Genomics_Statistics/*")
        Array[File] Duplication = glob("input/OrthoFinder/Results*/Gene_Duplication_Events/*")
        File Gene_Trees  = "Gene_Trees.tar.gz"
        Array[File] Orthogroups  = glob("input/OrthoFinder/Results*/Orthogroups/*")
        Array[File] Orthologues  = glob("input/OrthoFinder/Results*/Orthologues/*/*")
        File Orthogroup_Sequences  = "Orthogroup_Sequences.tar.gz"
        Array[File] Phylogenetic_Orthogroups  = glob("input/OrthoFinder/Results*/Phylogenetic_Hierarchical_Orthogroups/*")
        File Resolved_Gene_Trees  = "Resolved_Gene_Trees.tar.gz"
        File Single_Copy_Orthologue_Sequences  = "Single_Copy_Orthologue_Sequences.tar.gz"
        Array[File] Species_Tree  = glob("input/OrthoFinder/Results*/Species_Tree/*")
  }
}
workflow   run_orthofinder{
    input {
        Array[File]  fastas
            String  cpu         = "2"
            String  memory      = "16G"
    }
    call orthofinder{
        input:cpu=cpu,memory=memory,fastas=fastas
    }
    output {
        Array[File] Statistics = orthofinder.Statistics
        Array[File] Duplication = orthofinder.Duplication
        File Gene_Trees  = orthofinder.Gene_Trees
        Array[File] Orthogroups  = orthofinder.Orthogroups
        Array[File] Orthologues  = orthofinder.Orthologues
        File Orthogroup_Sequences  = orthofinder.Orthogroup_Sequences
        Array[File] Phylogenetic_Orthogroups  = orthofinder.Phylogenetic_Orthogroups
        File Resolved_Gene_Trees  = orthofinder.Resolved_Gene_Trees
        File Single_Copy_Orthologue_Sequences  = orthofinder.Single_Copy_Orthologue_Sequences
        Array[File] Species_Tree  = orthofinder.Species_Tree
      }


}
