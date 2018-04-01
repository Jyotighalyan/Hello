public class vendorInvoiceLineTrigger_domain extends fflib_SObjectDomain {
	public vendorInvoiceLineTrigger_domain(List<Vendor_Invoice_Line__c > records) {
        super(records);
	}
   
    //check before insert
    public override void onBeforeInsert() {
         //check sum of invoice lines amount should not be more then invoice total amount
        check_invoice_lines_total_amount(records,null,'insert');
    }

    public void check_invoice_lines_total_amount(List<Vendor_Invoice_Line__c > records,Map<Id, SObject> existingRecords,string type){

        for (Vendor_Invoice_Line__c  newRecord : (List<Vendor_Invoice_Line__c >) records) {
            double totalInvoiceAmount = new cmsft_vendorInvoiceLineTriggerSelector().getTotalInvoiceAmount(newRecord.Vendor_Invoice__c);
            //send one by one in voice number and check if its exist in db
            double checkForDuplicateInvoice = new cmsft_vendorInvoiceLineTriggerSelector().getInvoiceLineAmountTotal(newRecord.Vendor_Invoice__c);
            if(checkForDuplicateInvoice != null){ 
            	checkForDuplicateInvoice = checkForDuplicateInvoice + newRecord.Amount__c;
            }else{
                checkForDuplicateInvoice=newRecord.Amount__c;
            }
            Vendor_Invoice_Line__c oldRecord= null;
             if(type == 'update'){
                 //if updating then use new amount for checking the total amount
                oldRecord = (Vendor_Invoice_Line__c) existingRecords.get(newRecord.id);
            	checkForDuplicateInvoice = checkForDuplicateInvoice - oldRecord.Amount__c;
             }
            if(checkForDuplicateInvoice > totalInvoiceAmount){
                //if exist then give error message.
                newRecord.Amount__c.addError('Invoice lines total amount should not be more then invoice total amount');
            }
        }
    }
    //check before update
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
         //check sum of invoice lines amount should not be more then invoice total amount
        check_invoice_lines_total_amount(records,existingRecords,'update');      
    }
    
     public class Constructor implements fflib_SObjectDomain.IConstructable2 {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new vendorInvoiceLineTrigger_domain(sObjectList);
		}

		public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
			return new vendorInvoiceLineTrigger_domain(sObjectList);
		}
	}  
    
}