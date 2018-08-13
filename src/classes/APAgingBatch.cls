/**
* @Description : Batch class for updating aging fields on vendor Account
* @Author : Jyotig@mobifyi.com
* @Date : 7th June - 2017
*/

sghdgfdgdfjhfhdfgdhfgdhgfdhsg ssdee e e e 
public with sharing class APAgingBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	@TestVisible
	private Date endDate;
	@TestVisible
	private List<Database.SaveResult> dbSaveResultList;
	
	/**
	* @Description : constructor of the class setting effective date value
	*/
	public APAgingBatch() 
	{
		this.endDate = [select Effective_Date__c from AP_Aging__c where name='Effective Date Record'].Effective_Date__c;
	}
	
	/**
	* @Description : query all the vendors
	*/
	public Database.QueryLocator start(Database.BatchableContext BC) {
			return Database.getQueryLocator(new cmsft_AccountSelector().getAllAccounts(' recordTypeId=\''+Utility.searchRecordType('Vendor', 'Account')+'\''));
	}

	/**
	* @Description : execute method of the batch
	*/
   	public void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
		Map<ID, Account> vendorMap = new Map<ID, Account>((List<Account>) scope);
		updateAgingFieldsOnVendor(vendorMap, endDate);
	}
	
	/**
	* @Description : send email after batch completion to the user who just runned the batch
	*/
	public void finish(Database.BatchableContext BC) 
	{
		AsyncApexJob a = (AsyncApexJob) Data.read('Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :jobId', new Map<String, Object> {'jobId' => BC.getJobId()}).get(0); 

		if(a.TotalJobItems != 0){
		// collect failure results
		List<Database.SaveResult> successRecs = new List<Database.SaveResult>();
		
		if(dbSaveResultList!=null){
			for(integer i =0; i<dbSaveResultList.size();i++){
	        	If(dbSaveResultList[i].isSuccess()){
	             	successRecs.add(dbSaveResultList[i]);
	        	}
	    	}
    	}

        // Send an email to the Apex job's submitter notifying of job completion.                                          
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();         
        String[] toAddresses = new String[] {a.CreatedBy.Email};         
        mail.setToAddresses(toAddresses); 
        mail.setSubject('Salesforce APAgingBatch ' + a.Status);
	        if(dbSaveResultList!=null && successRecs!=null){
	            mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors + ' failures.' 
	        	+ '\n Total Number of Records Processed :'+dbSaveResultList.size()
	        	+ '\n Number of Records that are successfully updated : '+successRecs.size()
	    	);
    	} 
    	else
    	{
    		mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors + ' failures.');
    	}     
       
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
	}

	/**
	* @Description : method contains the bussiness logic behinf filling the aging fields in account object
	* @param vendorMap contains the id of vendor as key and vendor record as value
	*/
	@TestVisible
	private void updateAgingFieldsOnVendor(Map<Id, Account> vendorMap, Date eDate)
	{
		List<Vendor_Invoice__c> vendInvoicesListBeforeEndDate = new cmsft_vendorInvoiceTriggerSelector().selectVendorInvoicesWithPassedCondition('Invoice_Date__c <= '+String.valueOf(eDate).split(' ').get(0)+' AND Posted__c=true');
		List<Vendor_Invoice_Check__c> vendorInvoiceChecksWithChildPaymentRecords = new cmsft_VendorInvoiceCheckSelector().getVendorInvoiceCheckWithPayments('Check_Date__c <= '+String.valueOf(eDate).split(' ').get(0));
		Map<Id, List<Vendor_Invoice__c>> vendorIdWithVendorInvoicesMap = new Map<Id, List<Vendor_Invoice__c>>();
		Map<Id, List<Vendor_Invoice_Check__c>> vendorIdWithVendorInvCheckMap = new Map<Id, List<Vendor_Invoice_Check__c>>();
		
		// loop over vendor invoice list to fill the map
		for(Vendor_Invoice__c vendInvObj :vendInvoicesListBeforeEndDate)
		{
			// check if key exists in vendorIdWithVendorInvoicesMap then add new element in list
			if(!vendorIdWithVendorInvoicesMap.containsKey(vendInvObj.Vendor__c))
				vendorIdWithVendorInvoicesMap.put(vendInvObj.Vendor__c, new List<Vendor_Invoice__c>());	
			vendorIdWithVendorInvoicesMap.get(vendInvObj.Vendor__c).add(vendInvObj);
		} // end of for loop

		// loop over vendor invoice check records to fill in the map
		for(Vendor_Invoice_Check__c vendInvCheckObj :vendorInvoiceChecksWithChildPaymentRecords) 
		{
			// check if key exists in vendorInvoiceChecksWithChildPaymentRecords then add new element in list
			if(!vendorIdWithVendorInvCheckMap.containsKey(vendInvCheckObj.Vendor__c))
				vendorIdWithVendorInvCheckMap.put(vendInvCheckObj.Vendor__c, new List<Vendor_Invoice_Check__c>());
			vendorIdWithVendorInvCheckMap.get(vendInvCheckObj.Vendor__c).add(vendInvCheckObj);				
		} // end of for loop

		//prepare the dates
		Date days30 = eDate.addDays(-30);
		Date days31 = eDate.addDays(-31);
		Date days60 = eDate.addDays(-60);
		Date days61 = eDate.addDays(-61);
		Date days90 = eDate.addDays(-90);
		Date days91 = eDate.addDays(-91);

		// loop over all vendor to update the aging fields
		for(Account vendorObj :vendorMap.Values())
		{

			// update the fields
			vendorObj.Aging_Effective_Date__c = eDate;
			vendorObj.X0_30__c = 0;
			vendorObj.X31_60__c = 0;
			vendorObj.X61_90__c = 0;
			vendorObj.X91__c = 0;

			// check if there are invoices related to current vendor then only proceed for loop
			if(vendorIdWithVendorInvoicesMap.get(vendorObj.id)!=null && vendorIdWithVendorInvoicesMap.get(vendorObj.id).size()>0)
			
			//loop over all invoices of this vendor
			for(Vendor_Invoice__c vendInv :vendorIdWithVendorInvoicesMap.get(vendorObj.id))
			{
				if(vendInv.Invoice_Date__c <= eDate && vendInv.Invoice_Date__c >= days30)
					vendorObj.X0_30__c += vendInv.Amount__c;
				else if(vendInv.Invoice_Date__c <= days31 && vendInv.Invoice_Date__c >= days60)
						vendorObj.X31_60__c += vendInv.Amount__c;
					 else if(vendInv.Invoice_Date__c <= days61 && vendInv.Invoice_Date__c >= days90)	
							vendorObj.X61_90__c += vendInv.Amount__c;
						  else if(vendInv.Invoice_Date__c <= days91)
						 		vendorObj.X91__c += vendInv.Amount__c;	
			}

			// check if there are payments related to current vendor then only proceed for loop
			if(vendorIdWithVendorInvCheckMap.get(vendorObj.id)!=null && vendorIdWithVendorInvCheckMap.get(vendorObj.id).size()>0)
			
			//loop over all vendor invoices check to subtract the amount paid
			for(Vendor_Invoice_Check__c vendInvCheckObj :vendorIdWithVendorInvCheckMap.get(vendorObj.id))
			{
				//loop over all the payment related to this check
				if(vendInvCheckObj.Vendor_Invoice_Payments__r.size()>0)
				for(Vendor_Invoice_Payment__c vendInvPayObj : vendInvCheckObj.Vendor_Invoice_Payments__r)
				{
					if(vendInvPayObj.Vendor_Invoice__r.Invoice_Date__c <= eDate && vendInvPayObj.Vendor_Invoice__r.Invoice_Date__c >= days30)
						vendorObj.X0_30__c -= vendInvPayObj.Amount_Paid__c;
						else if(vendInvPayObj.Vendor_Invoice__r.Invoice_Date__c <= days31 && vendInvPayObj.Vendor_Invoice__r.Invoice_Date__c >= days60)
							vendorObj.X31_60__c -= vendInvPayObj.Amount_Paid__c;
							else if(vendInvPayObj.Vendor_Invoice__r.Invoice_Date__c <= days61 && vendInvPayObj.Vendor_Invoice__r.Invoice_Date__c >= days90)
								vendorObj.X61_90__c -= vendInvPayObj.Amount_Paid__c;
								else if(vendInvPayObj.Vendor_Invoice__r.Invoice_Date__c <= days91)
									vendorObj.X91__c -= vendInvPayObj.Amount_Paid__c;
				} // end of vendor invoice payment loop
			} // end of vendor invoice check loop
		} // end of vendor loop

		// update the vendors list with aging fields
		if(vendorMap.values().size()>0)
			dbSaveResultList = Data.modify(vendorMap.values());
	} // end of the updateAgingFieldsOnVendor method
}
