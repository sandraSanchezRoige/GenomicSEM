
sumstats <- function(files,ref,trait.names=NULL,se.logit,OLS=NULL,linprob=NULL,prop=NULL,N=NULL,info.filter = .6,maf.filter=0.01){
  
  length <- length(files)
  

   if(is.null(OLS)){

    OLS<-rep(FALSE,length)
  }
  
  if(is.null(linprob)){
    linprob<-rep(FALSE,length)
  }
  
  if(is.null(trait.names)){
    
    names.beta <- paste0("beta.",1:length)
    names.se <- paste0("se.",1:length)
    
  }else{
    
    names.beta <- paste0("beta.",trait.names)
    names.se <- paste0("se.",trait.names)
    
  }
  
  print("Reading summary statistics")
  files = lapply(files, read.table, header=T, quote="\"",fill=T,na.string=c(".",NA,"NA",""))

  ref <- fread(ref,header=T,data.table=F)
  
  ##filter ref file on user provided maf.filter
  ref<-subset(ref, ref$MAF >= maf.filter)
  
  data.frame.out <- ref
  
  for(i in 1:length){
    
    hold_names <- names(files[[i]])

    hold_names[hold_names %in%c("snp","SNP","snpid","SNPID","rsID","rsid","RSID","RS_NUMBER","rs_number","RS_NUMBERS","rs_numbers","MarkerName","Markername", "markername", "MARKERNAME")] <- "SNP"
    hold_names[hold_names %in%c("a1","A1","allele1","Allele1", "ALLELE1","EFFECT_ALLELE","INC_ALLELE","REFERENCE_ALLELE","EA","Effect_allele", "Effect_Allele")] <- "A1"
    hold_names[hold_names %in%c("a2","A2","allele2","Allele2","ALLELE2","OTHER_ALLELE","NON_EFFECT_ALLELE","DEC_ALLELE","OA","NEA","Other_allele", "Other_Allele", "Non_Effect_Allele")]  <- "A2"
    hold_names[hold_names %in%c("OR","or","B","Beta","beta","BETA","LOG_ODDS","EFFECTS","EFFECT","SIGNED_SUMSTAT", "Effect","Z","Zscore","b", "Effect_Beta")] <- "effect"
    hold_names[hold_names %in%c("INFO","info")] <- "INFO"
    hold_names[hold_names %in%c("se","StdErr","SE")] <- "SE"
    hold_names[hold_names %in%c("P","p","PVALUE","Pval","pvalue","P_VALUE","P_value","P-value","p-value","P.value","p_value","PVAL","pval","P_VAL","p_val","GC_PVALUE","gc_pvalue", "P_Value", "Pvalue")] <- "P"
    hold_names[hold_names %in%c("N","WEIGHT","nCompleteSamples", "TotalSampleSize")] <- "N"
    hold_names[hold_names %in%c("NCASE","N_CASE","N_CASES","N_CAS")] <- "N_CAS"
    hold_names[hold_names %in%c("NCONTROL","N_CONTROL","N_CONTROLS","N_CON","CONTROLS_N")] <- "N_CON"

    # Print a message for misisng P value, rs, effect or allele columns
    
     
    
    if(sum(hold_names %in% "P") == 0) print(paste0('Cannot find P-value column, try renaming it P in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "A1") == 0) print(paste0('Cannot find effect allele column, try renaming it A1 in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "A2") == 0) print(paste0('Cannot find other allele column, try renaming it A2 in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "effect") == 0) print(paste0('Cannot find beta or effect column, try renaming it effect in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "SNP") == 0) print(paste0('Cannot rs-id column, try renaming it"SNP in the summary statistics file for:',trait.names[i]))
                                                           
                                               
    
    # Throw warnings for misisng P valuue, rs, effect or allele columns
  
    
    if(sum(hold_names %in% "P") == 0) warning(paste0('Cannot find P-value column, try renaming it P in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "A1") == 0) warning(paste0('Cannot find effect allele column, try renaming it A1 in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "A2") == 0) warning(paste0('Cannot find other allele column, try renaming it A2 in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "effect") == 0) warning(paste0('Cannot find beta or effect column, try renaming it effect in the summary statistics file for:',trait.names[i]))
    if(sum(hold_names %in% "SNP") == 0) warning(paste0('Cannot rs-id column, try renaming it SNP in the summary statistics file for:',trait.names[i]))
                                                          
    ##rename common MAF labels to MAF_Other so MAF from ref file is used across traits for conversions
    hold_names[hold_names %in%c("MAF","maf", "CEUaf", "Freq1", "EAF", "Freq1.Hapmap", "FreqAllele1HapMapCEU", "Freq.Allele1.HapMapCEU", "EFFECT_ALLELE_FREQ", "Freq.A1")] <- "MAF_Other"
   
    
    names(files[[i]]) <- hold_names
    
     #if user provides N then add it in
    if(!(is.null(N))){
      files[[i]]$N<-N[i]
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
    files[[i]]$effect<-ifelse(rep(round(median(files[[i]]$effect)) == 1,nrow(files[[i]])), log(files[[i]]$effect),files[[i]]$effect)
    


      if(OLS[i] == T){
      
      files[[i]]$Z <- sign(files[[i]]$effect) * sqrt(qchisq(files[[i]]$P,1,lower=F))
      
      if("N" %in% colnames(files[[i]])){
      files[[i]]$effect <- files[[i]]$Z/ sqrt(files[[i]]$N * 2 * (files[[i]]$MAF *(1-files[[i]]$MAF)))}else{print("ERROR: A Sample Size (N) is needed for OLS Standardization")}}
    
    
      if(linprob[i] == T){
      files[[i]]$Z <- sign(files[[i]]$effect) * sqrt(qchisq(files[[i]]$P,1,lower=F))
      
      if("N" %in% colnames(files[[i]])){
      files[[i]]$effect <- files[[i]]$Z/sqrt((prop[i]*(1-prop[i])*(2*files[[i]]$N*files[[i]]$MAF*(1-files[[i]]$MAF))))
      files[[i]]$SE<-1/sqrt((prop[i]*(1-prop[i])*(2*files[[i]]$N*files[[i]]$MAF*(1-files[[i]]$MAF))))}else{print("ERROR: A Sample Size (N) is needed for LPM Standardization")}}
    
    
    # Flip effect to match ordering in ref file
    files[[i]]$effect <-  ifelse(files[[i]]$A1.x != (files[[i]]$A1.y) & files[[i]]$A1.x == (files[[i]]$A2.y),files[[i]]$effect*-1,files[[i]]$effect)
    
    ##remove SNPs that don't match A1 OR A2 in ref. confirm this works
    files[[i]]<-subset(files[[i]], !(files[[i]]$A2.x != (files[[i]]$A2.y)  & files[[i]]$A2.x !=  (files[[i]]$A1.y)))
    files[[i]]<-subset(files[[i]], !(files[[i]]$A1.x != (files[[i]]$A1.y)  & files[[i]]$A1.x != (files[[i]]$A2.y)))
    
    if("INFO" %in% colnames(files[[i]])) {
      files[[i]] <- files[[i]][files[[i]]$INFO >= info.filter,]
      
    }
    
    varSNP<-2*files[[i]]$MAF*(1-files[[i]]$MAF)  
   
    if(OLS[i] == T){
      output <- cbind.data.frame(files[[i]]$SNP,
                                 files[[i]]$effect,
                                 abs(files[[i]]$effect/files[[i]]$Z))
      output<-na.omit(output)                           
      colnames(output) <- c("SNP",names.beta[i],names.se[i])                           
      
      
    }
    
    if(linprob[i] == T){
      output<-cbind.data.frame(files[[i]]$SNP,
      (files[[i]]$effect)/((files[[i]]$effect^2) * varSNP + (pi^2)/3)^.5,
      (files[[i]]$SE)/(((files[[i]]$effect)^2) * varSNP + (pi^2)/3)^.5)  
      output<-na.omit(output)
      output<-output[apply(output!=0, 1, all),]
      colnames(output) <- c("SNP",names.beta[i],names.se[i])                                         
    }
    
    if(linprob[i] == F){
    if(OLS[i] == F){                                     
      if(se.logit[i] == F){
        output <- cbind.data.frame(files[[i]]$SNP,
                                   (files[[i]]$effect)/((files[[i]]$effect^2) * varSNP + (pi^2)/3)^.5,
                                   (files[[i]]$SE/exp(files[[i]]$effect))/(((files[[i]]$effect)^2 * varSNP + (pi^2)/3)^.5))
        output<-na.omit(output)  
        colnames(output) <- c("SNP",names.beta[i],names.se[i])}}}
      
    if(se.logit[i]== T){
        output <- cbind.data.frame(files[[i]]$SNP,
                                   (files[[i]]$effect)/((files[[i]]$effect^2) * varSNP + (pi^2)/3)^.5,
                                   (files[[i]]$SE)/(((files[[i]]$effect)^2) * varSNP + (pi^2)/3)^.5)  
        output<-na.omit(output)  
        colnames(output) <- c("SNP",names.beta[i],names.se[i])}
    
    
    if(i ==1){
      data.frame.out <- merge(data.frame.out,output,by=1,all.x=F,all.y=F)
    }else{
      data.frame.out <- merge(data.frame.out,output,by=1,all.x=F,all.y=F) 
    }
    
  }
  
  data.frame.out<-data.frame.out[!duplicated(data.frame.out$BP),]
  
  data.frame.out
  
}

