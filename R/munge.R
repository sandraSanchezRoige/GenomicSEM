



munge <- function(files,hm3,trait.names=NULL,N,info.filter = .9,maf.filter=0.01){
  
  length <- length(files)
  filenames <- as.vector(files)
  
  print("Reading summary statistics")
  files = lapply(files, read.table,header=T, quote="\"",fill=T,na.string=c(".","NA",""))
  print("Reading in reference file")
  ref <- fread(hm3,header=T,data.table=F)
  print("All files loaded into R!")
  
  
  
  
  for(i in 1:length){
    print(paste("Munging file:", filenames[i]))
    hold_names <- names(files[[i]])
    

    hold_names[hold_names %in% c("snp","SNP","snpid","rsID","SNPID","rsid","RSID","RS_NUMBER","rs_number","RS_NUMBERS","rs_numbers","MarkerName","Markername", "markername", "MARKERNAME")] <- "SNP"
    hold_names[hold_names %in%c("a1","A1","allele1","Allele1", "ALLELE1","EFFECT_ALLELE","INC_ALLELE","REFERENCE_ALLELE","EA","Effect_allele", "Effect_Allele")] <- "A1"
    hold_names[hold_names %in%c("a2","A2","allele2","Allele2","ALLELE2","ALLELE0","OTHER_ALLELE","NON_EFFECT_ALLELE","DEC_ALLELE","OA","NEA","Other_allele", "Other_Allele", "Non_Effect_allele", "Non_Effect_Allele")]  <- "A2"
    hold_names[hold_names %in%c("OR","or","B","Beta","beta","BETA","LOG_ODDS","EFFECTS","Effect_Beta","EFFECT","SIGNED_SUMSTAT", "Effect","Z","Zscore","b")] <- "effect"
    hold_names[hold_names %in%c("INFO","info")] <- "INFO"
    hold_names[hold_names %in%c("P","p","PVALUE","Pval","pvalue","P_VALUE","P_value","P-value","p-value","P.value","p_value","PVAL","pval","P_VAL","p_val","GC_PVALUE","gc_pvalue", "P_Value", "Pvalue")] <- "P"
    hold_names[hold_names %in%c("N","WEIGHT","nCompleteSamples", "TotalSampleSize", "TotalN", "Total_N")] <- "N"
    hold_names[hold_names %in%c("NCASE","N_CASE","N_CASES","N_CAS")] <- "N_CAS"
    hold_names[hold_names %in%c("NCONTROL","N_CONTROL","N_CONTROLS","N_CON","CONTROLS_N")] <- "N_CON"
    

    # Print a message for misisng P value, rs, effect or allele columns

    
    if(sum(hold_names %in% "P") == 0) print(paste0('Cannot find P-value column, try renaming it P in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "A1") == 0) print(paste0('Cannot find effect allele column, try renaming it A1 in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "A2") == 0) print(paste0('Cannot find other allele column, try renaming it A2 in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "effect") == 0) print(paste0('Cannot find beta or effect column, try renaming it effect in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "SNP") == 0) print(paste0('Cannot rs-id column, try renaming it"SNP in the summary statistics file for:',filenames[i]))
                                                           
    
    # Throw warnings for misisng P valuue, rs, effect or allele columns
  
    
    if(sum(hold_names %in% "P") == 0) warning(paste0('Cannot find P-value column, try renaming it P in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "A1") == 0) warning(paste0('Cannot find effect allele column, try renaming it A1 in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "A2") == 0) warning(paste0('Cannot find other allele column, try renaming it A2 in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "effect") == 0) warning(paste0('Cannot find beta or effect column, try renaming it effect in the summary statistics file for:',filenames[i]))
    if(sum(hold_names %in% "SNP") == 0) warning(paste0('Cannot rs-id column, try renaming it SNP in the summary statistics file for:',filenames[i]))
                                                           
                                             
    ##rename common MAF labels
    hold_names[hold_names %in%c("MAF","maf", "CEUaf", "Freq1", "EAF", "Freq1.Hapmap", "FreqAllele1HapMapCEU", "Freq.Allele1.HapMapCEU", "EFFECT_ALLELE_FREQ", "Freq.A1")] <- "MAF"
   
    #Replace the origonal names
    names(files[[i]]) <- hold_names
    
    
     if("MAF" %in% colnames(files[[i]])) {
    ##make sure MAF is actually MAF (i.e., max value is .5)
    files[[i]]$MAF<-ifelse(files[[i]]$MAF <= .5, files[[i]]$MAF, (1-files[[i]]$MAF))
    }
    
    # Compute N is N cases and N control is reported:
    if("N_CAS" %in% colnames(files[[i]])) {
      files[[i]]$N <- files[[i]]$N_CAS + files[[i]]$N_CON
      
    }
    
    
    ##make sure all alleles are upper case for matching
    files[[i]]$A1 <- factor(toupper(files[[i]]$A1), c("A", "C", "G", "T"))
    files[[i]]$A2 <- factor(toupper(files[[i]]$A2), c("A", "C", "G", "T"))
    
    ##merge with ref file
    files[[i]] <- merge(ref,files[[i]],by="SNP",all.x=F,all.y=F)
    
    ##remove any rows with missing p-values
     if("P" %in% colnames(files[[i]])) {
   files[[i]]<-subset(files[[i]], !(is.na(files[[i]]$P)))
    }
    
    ##determine whether it is OR or logistic/continuous effect based on median effect size 
    files[[i]]$effect<-ifelse(rep(round(median(files[[i]]$effect,na.rm=T)) == 1,nrow(files[[i]])), log(files[[i]]$effect),files[[i]]$effect)
    
    # Flip effect to match ordering in ref file
    files[[i]]$effect <-  ifelse(files[[i]]$A1.x != (files[[i]]$A1.y) & files[[i]]$A1.x == (files[[i]]$A2.y),files[[i]]$effect*-1,files[[i]]$effect)
    
    ##remove SNPs that don't match A1 OR A2 in ref. confirm this works
    files[[i]]<-subset(files[[i]], !(files[[i]]$A2.x != (files[[i]]$A2.y)  & files[[i]]$A2.x !=  (files[[i]]$A1.y)))
    files[[i]]<-subset(files[[i]], !(files[[i]]$A1.x != (files[[i]]$A1.y)  & files[[i]]$A1.x != (files[[i]]$A2.y)))
    
    # Validity checks
    
    if((sum(files[[i]]$P > 1) + sum(files[[i]]$P < 0)) > 100){
      
      print("in excess of 100 SNPs have P val above 1 or below 0, column may be mislabled!")
      
    }
    
    #Compute Z score
    files[[i]]$Z <- sign(files[[i]]$effect) * sqrt(qchisq(files[[i]]$P,1,lower=F))
    
    
    
    
    if("INFO" %in% colnames(files[[i]])) {
      files[[i]] <- files[[i]][files[[i]]$INFO >= info.filter,]
      
    }else{print("No INFO column, cant filter on INFO, may influence results")}
    
    if("MAF" %in% colnames(files[[i]])) {
      files[[i]]$MAF<-as.numeric(as.character(files[[i]]$MAF))
      files[[i]] <- files[[i]][files[[i]]$MAF >= maf.filter,]
      
    }else{print("No MAF column, cant filter on MAF, may influence results")}
    
    
    
    if("N" %in% colnames(files[[i]])) {
    output <- cbind.data.frame(files[[i]]$SNP,files[[i]]$N,files[[i]]$Z,files[[i]]$A1.x,files[[i]]$A2.x)
    }else{output <- cbind.data.frame(files[[i]]$SNP,N[i],files[[i]]$Z,files[[i]]$A1.x,files[[i]]$A2.x) }
    
    
    
    colnames(output) <- c("SNP","N","Z","A1","A2")
    
    
    write.table(x = output,file = paste0(trait.names[i],".sumstats"),sep="\t", quote = FALSE, row.names = F)
    gzip(paste0(trait.names[i],".sumstats"))
    print(paste("I am done munging file:", filenames[i]))
  }
  
  
  
  
}
