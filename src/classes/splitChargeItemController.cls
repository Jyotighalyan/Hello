public with sharing class splitChargeItemController {
    public Revenue_Split__c revSplit {get; set;}
    public Charge_Item__c  chargeItem {get; set;}
    public boolean isEditBoolean{get;set;}
    public double total{get;set;}
    // service class variable
    public splitChargeItemService service;
    
    public splitChargeItemController(ApexPages.StandardController std) {
        service =new splitChargeItemService();
        revSplit = (Revenue_Split__c)std.getRecord();
        isEditBoolean=false;
        
        if(ApexPages.currentPage().getParameters().get('id')!=null){
            isEditBoolean = true;
            revSplit = service.getRevenueSplitFullRecordService(ApexPages.currentPage().getParameters().get('id'));
            chargeItem = service.getChargeItemFullRecordService(revSplit.Charge_Item__c);
            total=service.getTotalAmountSplitService(revSplit.Charge_Item__c);
        }
        else if(std.getRecord()!=null && revSplit.Charge_Item__c!=null){
            chargeItem = service.getChargeItemFullRecordService(revSplit.Charge_Item__c);
            total=service.getTotalAmountSplitService(revSplit.Charge_Item__c);
        }else if(ApexPages.currentPage().getParameters().get('sid')!=null){
            revSplit = new Revenue_Split__c(Charge_Item__c = ApexPages.currentPage().getParameters().get('sid'));
            chargeItem = service.getChargeItemFullRecordService(ApexPages.currentPage().getParameters().get('sid'));
        }
    }
    public PageReference save(){
        if(revSplit.Split_Amount__c == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Split amount should be more then 0'));
            return null;
        }
        return service.saveNewService(new List<Revenue_Split__c> {revSplit}, new List<Charge_Item__c> {chargeItem},  new List<String> {'save'});
    }
    public pageReference savenew(){
        if(revSplit.Split_Amount__c == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Split amount should be more then 0'));
            return null;
        }
        try{
            return service.saveNewService(new List<Revenue_Split__c> {revSplit}, new List<Charge_Item__c> {chargeItem}, new List<String> {'saveNew'});
        }
        catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,ex.getMessage()));
            return null;
        }
    }
    /**
* @Description : cancel method overriding
*/
    public PageReference cancel()
    {
        PageReference pg = new PageReference(URL.getSalesforceBaseUrl().toExternalForm() + '/'+chargeItem.id);
        pg.setRedirect(true);
        return pg;
    }
}