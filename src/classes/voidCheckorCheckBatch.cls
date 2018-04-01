public with sharing class voidCheckorCheckBatch {
    public string batchId{get;set;}
    public string checkId{get;set;}
    public Vendor_Invoice_Check__c checkDetail{get;set;}
    public Vendor_Invoice_Check_Batch__c batchDetail{get;set;}
    public voidCheckorCheckBatchService serviceObj;
    public boolean alreadyVoided{get;set;}
    public voidCheckorCheckBatch(){
        serviceObj = new voidCheckorCheckBatchService();
        if(ApexPages.CurrentPage().GetParameters().Get('batchId')!='' && ApexPages.CurrentPage().GetParameters().Get('batchId')!=null){
            batchId=ApexPages.CurrentPage().GetParameters().Get('batchId');
            batchDetail=serviceObj.getBatchDetail(batchId);
            alreadyVoided=false;
            if(batchDetail.Void__c == true){
                alreadyVoided=true;
            }
        }else{
            checkId=ApexPages.CurrentPage().GetParameters().Get('checkId');
            checkDetail = serviceObj.getCheckDetail(checkId);
            alreadyVoided=false;
            if(checkDetail.Void__c == true){
                alreadyVoided=true;
            }
        }
        
    }
    public PageReference VoidCheck(){
        serviceObj.VoidCheck(new List<Vendor_Invoice_Check__c>{checkDetail},date.today());
        PageReference pg = new PageReference('/'+checkId);
        pg.setRedirect(true);
        return pg;
    }
    public PageReference VoidBatch(){
        List<Vendor_Invoice_Check__c> allChecks = serviceObj.getAllChecks(batchId);
        for(Vendor_Invoice_Check__c check : allChecks){
            if(check.Void__c != true){
                serviceObj.VoidCheck(new List<Vendor_Invoice_Check__c>{check},batchDetail.Batch_Date__c);
            }
        }
        batchDetail.Void__c=true;
        Data.modify(batchDetail);
        PageReference pg = new PageReference('/'+batchId);
        pg.setRedirect(true);
        return pg;
    }
    public PageReference returnToCheckPage(){
        PageReference pg = new PageReference('/'+checkId);
        pg.setRedirect(true);
        return pg;
    }
    public PageReference returnToBatchPage(){
        PageReference pg = new PageReference('/'+batchId);
        pg.setRedirect(true);
        return pg;
    }
}