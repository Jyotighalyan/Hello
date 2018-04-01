public class PostDuesBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	@TestVisible
	private Default_Account__c defAcc;
	@TestVisible
	private Map<String, Tax_To_Account_Mapping__c> mapOfTaxes;
	@TestVisible
	private Set<Id> dueSummIds;
	@TestVisible
	private List<DueChargesStructure> chargesStructure;
	@TestVisible
	private Boolean isdueSummPosted;
	@TestVisible
	private Map<Id, Dues_Summary__c> duesSummaryObjs;
	@TestVisible
	private String postOrReject;

	public PostDuesBatch(Default_Account__c defAcc, Map<String, Tax_To_Account_Mapping__c> taxesMap, Set<Id> dueSummIds, String postOrReject) {
		
		chargesStructure = new List<DueChargesStructure>();
		this.defAcc = defAcc;
		this.mapOfTaxes = taxesMap;
		this.dueSummIds = dueSummIds;
		isdueSummPosted = false;
		duesSummaryObjs = new Map<Id, Dues_Summary__c>();
		this.postOrReject = postOrReject;
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Data.locator('Select Amount__c, Contact__c, Due_Summary__c, Post_Date__c, Service_Charge__c,' 
							+ ' Service_Charge_Name__c, Tax_Amount__c, Tax_Applied_On_Service_Charge__c, Total_Amount__c'
							+ ' FROM Dues_Summary__c'
							+ ' WHERE RecordTypeId=:recId AND Due_Summary__c in :dueSummId'
			, new Map<String, Object> {'recId' => Utility.searchRecordType('Dues','Dues_Summary__c'),
									   'dueSummId' => dueSummIds});
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		Set<Id> duesMasterRecs = new Set<Id> ();
		List<Id> duesIds = new List<Id>();

		// store all incoming dues ids in a list
		// id of all incoming dues to fetch taxes related to each due
		for(Dues_Summary__c dueSummObj :(List<Dues_Summary__c>)scope)
		{
			duesMasterRecs.add(dueSummObj.Due_Summary__c);
			duesIds.add(dueSummObj.id);
		}
		Map<Id, List<Dues_Summary__c>> mapOfDueIdAndTaxes = new Map<Id, List<Dues_Summary__c>>();
		for(Dues_Summary__c dueSummObj :(List<Dues_Summary__c>) Data.Read('Select Id, Service_Charge__c, Due_Summary__c, Service_Charge_Name__c, Tax_Name__c, Amount__c, Tax_Applied_On_Service_Charge__c from Dues_Summary__c where Due_Summary__c in :duesIds AND RecordTypeId=:recId',
			new Map<String, Object> {'duesIds' => duesIds, 'recId' => Utility.searchRecordType('Taxes','Dues_Summary__c')}))
		{
			if(!mapOfDueIdAndTaxes.containsKey(dueSummObj.Due_Summary__c))
				mapOfDueIdAndTaxes.put(dueSummObj.Due_Summary__c,new List<Dues_Summary__c>());
			mapOfDueIdAndTaxes.get(dueSummObj.Due_Summary__c).add(dueSummObj);	
		}
		if(postOrReject=='Post'){
		List<Financial_Journal_Line__c> finJournalLineToUpdate = new List<Financial_Journal_Line__c>();
		List<TXN__c> txnListToUpdate = new List<TXN__c>();
		if(!isdueSummPosted)
		{
			List<Dues_Summary__c> dueSummList = Data.read('Select Id, Member_Dues__r.Financial_Account__c, Member_Dues__r.Financial_Account__r.Debit_Credit__c, Post_Date__c, Member_Dues__r.Name, Member_Dues__r.Statements_Description__c, Member_Dues__r.Include_Billing_Period_On_SD__c, Billing_Period__c from Dues_Summary__c where id in :dueSummIds', new Map<String, Object> {'dueSummIds' => dueSummIds});
			List<Dues_Summary__c> dueSummToUpdate = new List<Dues_Summary__c>();
			for(Dues_Summary__c dueSummObj :dueSummList)
			{
				dueSummObj.Posted__c = true;
				dueSummToUpdate.add(dueSummObj);
				duesSummaryObjs.put(dueSummObj.id, dueSummObj);
			}
			Data.modify(dueSummToUpdate);
			isdueSummPosted = true;
		}
		List<Id> customers = new List<Id>();
		
		for(Dues_Summary__c dueSummObj :(List<Dues_Summary__c>)scope){
			customers.add(dueSummObj.Contact__c);
		}
		Map<Id, Id> billToMembersToCustomerMap = Utility.getBillToMember(customers);
		List<Dues_Summary__c> dueSummObjsToUpdate = new List<Dues_Summary__c>();
		for(Dues_Summary__c dueSummObj :(List<Dues_Summary__c>)scope)
		{
			String statementDescription;
			if(duesSummaryObjs.get(dueSummObj.Due_Summary__c).Member_Dues__r.Include_Billing_Period_On_SD__c){
				statementDescription = duesSummaryObjs.get(dueSummObj.Due_Summary__c).Member_Dues__r.Statements_Description__c+' - '+duesSummaryObjs.get(dueSummObj.Due_Summary__c).Billing_Period__c;
			}
			else{
				statementDescription = duesSummaryObjs.get(dueSummObj.Due_Summary__c).Member_Dues__r.Statements_Description__c;
			}
			dueSummObj.Posted__c = true;
			dueSummObjsToUpdate.add(dueSummObj);
			TXN__c txnDueCharge = new TXN__c(RecordTypeId=Utility.searchRecordType('Dues','TXN__c'));
			txnDueCharge.Amount__c = dueSummObj.Amount__c;
			txnDueCharge.Statement_Description__c = statementDescription;
			if(dueSummObj.Tax_Amount__c==null){
				dueSummObj.Tax_Amount__c = 0.00;
			}
			if(dueSummObj.Service_Charge__c==null){
				dueSummObj.Service_Charge__c = 0.00;
			}
			txnDueCharge.Credit_Financial_Account__c = duesSummaryObjs.get(dueSummObj.Due_Summary__c).Member_Dues__r.Financial_Account__c;
			txnDueCharge.Debit_Financial_Account__c = defAcc.Financial_Account__c;
			txnDueCharge.Dues_Summary__c = dueSummObj.Due_Summary__c;
			txnDueCharge.Tax__c = dueSummObj.Tax_Amount__c;
			txnDueCharge.Service_Charge__c =dueSummObj.Service_Charge__c;
			txnDueCharge.Amount_Remaining__c = dueSummObj.Amount__c;
			if(billToMembersToCustomerMap.containskey(dueSummObj.Contact__c)){
				txnDueCharge.Bill_To_Member__c = billToMembersToCustomerMap.get(dueSummObj.Contact__c);
			}else{
				txnDueCharge.Bill_To_Member__c = dueSummObj.Contact__c;
			}	
				
			txnDueCharge.Customer__c = dueSummObj.Contact__c;
				
			txnDueCharge.Member_Dues__c = duesSummaryObjs.get(dueSummObj.Due_Summary__c).Member_Dues__c;	
			txnListToUpdate.add(txnDueCharge);
			DueChargesStructure dueStrucObj = new DueChargesStructure(txnDueCharge);

			// create taxes
			if(mapOfDueIdAndTaxes.containsKey(dueSummObj.id)){
				for(Dues_Summary__c taxesObj :mapOfDueIdAndTaxes.get(dueSummObj.id))
				{
					Txn__c taxTxn = new TXN__c();
					taxTxn.Debit_Financial_Account__c = defAcc.Financial_Account__c;
					taxTxn.Amount__c = taxesObj.Amount__c;
					taxTxn.Amount_Remaining__c = taxTxn.Amount__c;
					taxTxn.Dues_Summary__c = dueSummObj.Due_Summary__c;
					taxTxn.Customer__c = dueSummObj.Contact__c;
					if(billToMembersToCustomerMap.containskey(dueSummObj.Contact__c)){
						taxTxn.Bill_To_Member__c = billToMembersToCustomerMap.get(dueSummObj.Contact__c);
					}else{
						taxTxn.Bill_To_Member__c = dueSummObj.Contact__c;						
					}	
					taxTxn.Member_Dues__c = duesSummaryObjs.get(dueSummObj.Due_Summary__c).Member_Dues__c;
					if(taxesObj.Service_Charge_Name__c!=null || taxesObj.Tax_Applied_On_Service_Charge__c)
					{
						taxTxn.RecordTypeId = Utility.searchRecordType('Service Charges','TXN__c');
						if(taxesObj.Service_Charge_Name__c!=null){
							taxTxn.Service_Charge_Name__c = taxesObj.Service_Charge_Name__c;
							taxTxn.Credit_Financial_Account__c = mapOfTaxes.get(taxesObj.Service_Charge_Name__c).Financial_Accounts__c;
						}
						else{
							taxTxn.Tax_Name__c = taxesObj.Tax_Name__c;
							taxTxn.Credit_Financial_Account__c = mapOfTaxes.get(taxesObj.Tax_Name__c).Financial_Accounts__c;
						}
						taxTxn.Tax_Applied_On_Service_Charge__c = taxesObj.Tax_Applied_On_Service_Charge__c;
						dueStrucObj.taxes.add(taxTxn);
					}
					else
					{
						taxTxn.RecordTypeId = Utility.searchRecordType('Taxes','TXN__c');
						taxTxn.Tax_Name__c = taxesObj.Tax_Name__c;
						taxTxn.Credit_Financial_Account__c = mapOfTaxes.get(taxesObj.Tax_Name__c).Financial_Accounts__c;
						dueStrucObj.taxes.add(taxTxn);
					}
					taxTxn.Statement_Description__c = statementDescription;
					txnListToUpdate.add(taxTxn);
				}
			}
			chargesStructure.add(dueStrucObj);
		}

		Data.modify(dueSummObjsToUpdate);
		Data.create(txnListToUpdate);

		txnListToUpdate = new List<TXN__c>();

		for(DueChargesStructure charges :chargesStructure)
		{
			for(TXN__c chargeObj :charges.taxes)
			{
				chargeObj.Related_To__c = charges.dueCharge.id;
				txnListToUpdate.add(chargeObj);
			}
		}

		Data.modify(txnListToUpdate);
	}
	else if(postOrReject=='Reject')
	{
		List<Dues_Summary__c> duesAndTaxesToBeDeleted = new List<Dues_Summary__c> ();
		for(List<Dues_Summary__c> dueSummListObj :mapOfDueIdAndTaxes.values())
		{
			duesAndTaxesToBeDeleted.addAll(dueSummListObj);
		}
		if(!isdueSummPosted)
		{
			List<Dues_Summary__c> dueSummList = Data.read('Select Id, Member_Dues__r.Financial_Account__c, Member_Dues__r.Financial_Account__r.Debit_Credit__c, Post_Date__c, Member_Dues__r.Name, Member_Dues__r.Statements_Description__c, Billing_Period__c from Dues_Summary__c where id in :dueSummIds', new Map<String, Object> {'dueSummIds' => dueSummIds});
			Data.remove(dueSummList);
			isdueSummPosted = true;
		}
		duesAndTaxesToBeDeleted.addAll((List<Dues_Summary__c>)scope);
		Data.remove(duesAndTaxesToBeDeleted);
	}
	}
	
	public void finish(Database.BatchableContext BC) {
		AsyncApexJob a = (AsyncApexJob) Data.read('Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :jobId', new Map<String, Object> {'jobId' => BC.getJobId()}).get(0); 
		if(a.TotalJobItems != 0)
		{
			// Send an email to the Apex job's submitter notifying of job completion.                                          
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();         
			String[] toAddresses = new String[] {a.CreatedBy.Email};         
			mail.setToAddresses(toAddresses);
			mail.setSubject('Post Dues Batch ' + a.Status);
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors + ' failures.');
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}

	@TestVisible
	private class DueChargesStructure
	{
		TXN__c dueCharge;
		List<TXN__c> taxes;
		DueChargesStructure(TXN__c charges)
		{
			this.dueCharge = charges;
			taxes = new List<TXN__c>();
		}
	}
}