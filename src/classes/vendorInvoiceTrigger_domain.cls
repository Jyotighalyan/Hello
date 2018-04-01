public class vendorInvoiceTrigger_domain extends fflib_SObjectDomain {
    public vendorInvoiceTrigger_domain(List<Vendor_Invoice__c> records) {
        super(records);
    }
    
    public override void onBeforeInsert() {
        //check new records if anyone of them exist in database
        for (Vendor_Invoice__c existingRecord : (List<Vendor_Invoice__c>) records) {
            //send one by one in voice number and check if its exist in db
            List<Vendor_Invoice__c> checkForDuplicateInvoice = new cmsft_vendorInvoiceTriggerSelector().checkExistingRecord(existingRecord.Invoice_Number__c,existingRecord.Vendor__c);
            if(checkForDuplicateInvoice.size()>0){
                //if exist then give error message.
                existingRecord.Invoice_Number__c.addError('There is already an Invoice on this Vendor with that number, please update the field and click Save again.');
            }
        }
    }
    
  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
  public fflib_SObjectDomain construct(List<SObject> sObjectList) {
   return new vendorInvoiceTrigger_domain(sObjectList);
  }

  public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
   return new vendorInvoiceTrigger_domain(sObjectList);
  }
}
}