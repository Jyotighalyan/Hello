public with sharing class splitChargeItemService {
    
    /**
* @Description : get revenue split complete record service with passed id
* @return : returns revenue split object after querying
*/
    public Revenue_Split__c  getRevenueSplitFullRecordService(string recId){
        return (Revenue_Split__c)Data.read(
            'Select Name,Charge_Item__c, Financial_Account__c ,Split_Amount__c  from Revenue_Split__c where Id=:Value ',
            new Map<String,Object> {
                'Value'=>recId
                    }
        ).get(0); 
    }
    
    /**
* @Description : get Charge_Item__c complete record service with passed id
* @return : returns Charge_Item__c object after querying
*/
    public Charge_Item__c  getChargeItemFullRecordService(string recId){
        return (Charge_Item__c)Data.read(
            'Select Name,Price__c, Price_Split__c   from Charge_Item__c where Id=:Value ',
            new Map<String,Object> {
                'Value'=>recId
                    }
        ).get(0); 
    }
    /*
* @Description : get total split amount complete record service with passed id
* @return : returns total split object after querying
*/
    public double  getTotalAmountSplitService(string recId){
        AggregateResult[] TotalAmountQryResult = (AggregateResult[])Data.read(
            'Select sum(Price__c) total  from Revenue_Split__c where Charge_Item__c=:Value',
            new Map<String,Object> {
                'Value'=>recId
                    }
        );
        return double.valueOf(TotalAmountQryResult[0].get('total')); 
    }
    public pageReference saveNewService(List<Revenue_Split__c> revSplit, List<Charge_Item__c> chargeItem, List<string> saveOrSaveNew){
        try{
            Data.upsurt(revSplit, Revenue_Split__c.Id.getDescribe().getSObjectField(), new Set<String>());    
        }catch (Exception e){
            return null;
        }
        
        if(saveOrSaveNew.get(0)=='save')
        {
            return new PageReference('/'+chargeItem.get(0).id);
        }
        else {
            PageReference pg = page.splitChargeItem;
            pg.getParameters().put('sid', chargeItem.get(0).id);
            pg.setRedirect(true);
            return pg;
        }
    }
}