version 1.0
task  spotlight{
    input {
    File  sc_matrix
    File  sp_matrix
    }
    command 
{  
       Rscript /opt/script/run_SPOTlight.r --sc ~{sc_matrix} --st ~{sp_matrix} 
    }
  runtime{
        docker : "swr.cn-south-1.myhuaweicloud.com/cngbdb/spotlight:v1"
        cpu    : "4"
        memory : "8G"
        }

  output {
				File prop_heatmap="prop_heatmap.png"
				File result="result.tsv"
				File prop_jaccard="prop_jaccard.png"
				File TopicProfiles_dsri= 'TopicProfiles_dsri.png'
				File TopicProfiles = 'TopicProfiles.png'
  }
}
workflow   run_spotlight{
    call spotlight
    output {
				File prop_heatmap=spotlight.prop_heatmap
				File result=spotlight.result
				File prop_jaccard=spotlight.prop_jaccard
				File TopicProfiles_dsri= spotlight.TopicProfiles_dsri
				File TopicProfiles = spotlight.TopicProfiles
      }

}
