/**
* @Description : controller for TxnChargeAdjustment page
* @Date : 2017
*/
public with sharing class TxnChargesAdjustmentController {

	public String recordTypeName {
		get{
			if(txnRecord!=null){
				return txnRecord.RecordType.Name;
			}
			else{
				return null;
			}
		}
	}

	public TXN__c txnRecord {
		get {
			if(txnRecord==null)
			{
				List<TXN__c> txnRecordsList = (List<TXN__c>) Data.read('Select Name, Amount__c, Customer__c, Bill_To_Member__c, Dues_Summary__r.Member_Dues__c, Member_Dues__c, Tax__c, Service_Charge__c, RecordType.Name, Related_To__c, Total_Amount__c from TXN__c where id=:recIdPassed', 
				new Map<String, Object> {'recIdPassed' => ApexPages.currentPage().getParameters().get('Id')});
				if(txnRecordsList.size()>0)
				{
					txnRecord = txnRecordsList[0];
				}
			}
			return txnRecord;
		}	
		set;
	}

	// variable storing all taxes and service charge recs related to incoming record
	private List<TXN__c> taxesAndSCRecords;

	// adjustment record
	public TXN__c adjustmentTxnRecord {get; set;}
	public boolean alreadyAdjusted {get; set;}

	public TxnChargesAdjustmentController() {
		if(recordTypeName == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Cannot procced further, Id passed is invalid.'));
			return;
		}
		if(recordTypeName!='Charge' && recordTypeName!='Dues')
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Adjustment can be performed on either charge or due.'));
			return;
		}

		// check if due is already adjusted
		if(recordTypeName=='Dues'){
			List<TXN__c> ajustedRecs = Data.read('Select id from TXN__c where Related_To__c=:txnRecordId AND RecordTypeId=:adjustmentRecId',
				new Map<String, Object> {'txnRecordId' => txnRecord.id,
										 'adjustmentRecId' => Utility.searchRecordType('Adjustment','TXN__c')}
				);	
			if(ajustedRecs.size()>0){
				alreadyAdjusted = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'This due is already adjusted.'));
				return;
			}
		}

		taxesAndSCRecords = Data.read('Select Id, Customer__c,Amount__c, Service_Charge_Name__c, Tax_Name__c from TXN__c where Related_To__c=:txnId',
				new Map<String, Object> {'txnId' => txnRecord.id}
				);	
		adjustmentTxnRecord = new TXN__c(RecordTypeId=Utility.searchRecordType('Adjustment', 'TXN__c'), Related_To__c=txnRecord.id, Customer__c=txnRecord.Customer__c, Bill_To_Member__c=txnRecord.Bill_To_Member__c, Date__c=Date.today(), Amount__c=-txnRecord.Amount__c);
		adjustmentTxnRecord.Member_Dues__c = txnRecord.Member_Dues__c;
		if(adjustmentTxnRecord.Member_Dues__c==null)
		{
			adjustmentTxnRecord.Member_Dues__c = txnRecord.Dues_Summary__r.Member_Dues__c;
		}
	}

	public PageReference saveDueAdjust()
	{
		if(adjustmentTxnRecord.Date__c==null || adjustmentTxnRecord.Statement_Description__c==null || adjustmentTxnRecord.Adjustment_Reason__c==null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Required field is missing.'));
			return null;
		}
		Data.create(adjustmentTxnRecord);
		List<TXN__c> adjustmentTaxesRecords = new List<TXN__c>();
		for(TXN__c taxesSC : taxesAndSCRecords)
		{
			TXN__c taxObj = new TXN__c(RecordTypeId = Utility.searchRecordType('Adjustment','TXN__c'), Related_To__c = txnRecord.id);
			taxObj.Service_Charge_Name__c = taxesSC.Service_Charge_Name__c;
			taxObj.Tax_Name__c = taxesSC.Tax_Name__c;
			taxObj.Member_Dues__c = adjustmentTxnRecord.Member_Dues__c;
			taxObj.Amount__c = -taxesSC.Amount__c;
			taxObj.Date__c = adjustmentTxnRecord.Date__c;
			taxObj.Customer__c = adjustmentTxnRecord.Customer__c;
			taxObj.Statement_Description__c = adjustmentTxnRecord.Statement_Description__c;
			taxObj.Adjustment_Reason__c = adjustmentTxnRecord.Adjustment_Reason__c;
			adjustmentTaxesRecords.add(taxObj);
		}
		Data.create(adjustmentTaxesRecords);
		PageReference pg = new PageReference('/'+txnRecord.id);
		pg.setRedirect(true);
		return pg;
	}
}