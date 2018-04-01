public class GenerateDuesBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	@TestVisible
	private Set<Id> dueIdList;
	@TestVisible
	private Date postDate;
	@TestVisible
	private String billingMonth;
	@TestVisible
	private boolean saved;
	@TestVisible
	private Map<Id, Dues_Summary__c> txnDueSummaryRecs;
	@TestVisible
	private List<Database.SaveResult> dbSaveResultList;
	@TestVisible
	private List<Apply_due_on_members__c> failedRecs; 
	
	public GenerateDuesBatch(Set<Id> dueIds, Date postDate, String billingMonth) 
	{
		failedRecs = new List<Apply_due_on_members__c>();
		txnDueSummaryRecs = new Map<Id, Dues_Summary__c>();
		saved = false;
		dueIdList = dueIds;
		this.postDate = postDate;
		this.billingMonth = billingMonth;
		dbSaveResultList = new List<Database.SaveResult>();
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) 
	{
		return Data.locator('select id, Member_Dues__c, Contact__r.Status__c, Membership_Type__c, Contact__r.Relationship__c, Member_Dues__r.Type__c, Member_Dues__r.Subtype__c  from Apply_due_on_members__c where Member_Dues__c in :dueIds AND Contact__r.Hold_Dues__c=:holdStatus AND Contact__r.Status__c in:memStatus', 
			new Map<String, Object> {'dueIds'=> dueIdList, 
									 'holdStatus' => false,
									 'memStatus' => new List<String> {'Active','Reinstated'}});
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) 
	{

		List<dueStructure> dueStructureListToInsert = new List<dueStructure>();
		Map<Id, List<Apply_due_on_members__c>> applyDueOnTheseMembers = new Map<Id, List<Apply_due_on_members__c>>();
		Map<Id, List<Billing_Custom_Distribution__c>> distributionMap = new Map<Id, List<Billing_Custom_Distribution__c>>();
		Set<String> typeList = new Set<String>();
		Set<String> subtypeList = new Set<String>();
		List<Dues_Summary__c> txnObjListToInsert = new List<Dues_Summary__c>();
		List<Dues_Summary__c> taxesList = new List<Dues_Summary__c>();

		try{
			if(!saved)
			{
				for(Id dueId :dueIdList)
				{
					Dues_Summary__c dueSum = new Dues_Summary__c(RecordTypeId=Utility.searchRecordType('Due Summary','Dues_Summary__c'));
					dueSum.Member_dues__c = dueId;
					dueSum.Amount__c = 0.00;
					dueSum.Post_Date__c = postDate;
					String month = billingMonth.split('_')[0];
					dueSum.Billing_Period__c = month; 
					txnObjListToInsert.add(dueSum);
					txnDueSummaryRecs.put(dueId, dueSum);
				}
				saved = true;
			}

			for(Apply_due_on_members__c appDueOnMemObj :(List<Apply_due_on_members__c>) (scope))
			{
				typeList.add(appDueOnMemObj.Member_Dues__r.Type__c);
				subtypeList.add(appDueOnMemObj.Member_Dues__r.SubType__c);
				if(!applyDueOnTheseMembers.containsKey(appDueOnMemObj.Member_Dues__c)) 
				{
					applyDueOnTheseMembers.put(appDueOnMemObj.Member_Dues__c, new List<Apply_due_on_members__c>());
				}
				applyDueOnTheseMembers.get(appDueOnMemObj.Member_Dues__c).add(appDueOnMemObj);
			}

			distributionMap = getCustomDistributions(applyDueOnTheseMembers.keySet());
			List<TxnChargeToTaxMapping__c> chargeAndTaxMapping = Data.read('SELECT Type__c, Subtype__c, TaxId__c, Service_Charge_applicable__c, Service_Charge_Name__c, Tax_Name_applicable_on_service_charge__c, Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE Type__c in :dueType AND SubType__c in :dueSubtype', new Map<String, Object>{'dueType'=> typeList, 'dueSubtype' => subtypeList});	

		// loop on all selected dues to get members on which this due is to apply
		for(Id dueId :applyDueOnTheseMembers.keySet())
		{
			List<dueStructure1> dueRecs = new List<dueStructure1>();
			
			// loop on apply due on members list
			for(Apply_due_on_members__c appDueOnMemObj :applyDueOnTheseMembers.get(dueId))
			{ 
				boolean isAdd = true;
				if(appDueOnMemObj.Contact__r.Status__c=='Active' || appDueOnMemObj.Contact__r.Status__c=='Reinstated')
				{
					Dues_Summary__c applyDueTxnRec = new Dues_Summary__c(RecordTypeId=Utility.searchRecordType('Dues','Dues_Summary__c'));
					applyDueTxnRec.Contact__c = appDueOnMemObj.Contact__c;
					String month = billingMonth.split('_')[0];
					applyDueTxnRec.Billing_Period__c = month;
					applyDueTxnRec.Post_Date__c = postDate;
					applyDueTxnRec.Amount__c = 0.00;

					if(appDueOnMemObj.Contact__r.Relationship__c=='Dependent')
					{
						if((Decimal)distributionMap.get(dueId)[0].get(billingMonth)>0) 
						{
							applyDueTxnRec.Amount__c = (Decimal)distributionMap.get(dueId)[0].get(billingMonth);
						}
						else
						{
							isAdd = false;
						}
					}
					else if(appDueOnMemObj.Contact__r.Relationship__c=='Primary')
					{
						if((Decimal)distributionMap.get(dueId)[1].get(billingMonth)>0) 
						{
							applyDueTxnRec.Amount__c = (Decimal)distributionMap.get(dueId)[1].get(billingMonth);
						}
						else
						{
							isAdd = false;
						}
					}
					else if(appDueOnMemObj.Contact__r.Relationship__c=='Spouse/Partner')
					{
						if((Decimal)distributionMap.get(dueId)[2].get(billingMonth)>0)
						{
							applyDueTxnRec.Amount__c = (Decimal)distributionMap.get(dueId)[2].get(billingMonth);
						}
						else 
						{
							isAdd = false;
						}
					}
					dueStructure1 dueStrucWithTax;
					if(isAdd)
					{
						dueStrucWithTax = SaveTaxesForPassedTypeSubtype(appDueOnMemObj.Member_Dues__r.Type__c, appDueOnMemObj.Member_Dues__r.Subtype__c, applyDueTxnRec.Amount__c, chargeAndTaxMapping);	
						dueStrucWithTax.txnRec = applyDueTxnRec;
						dueRecs.add(dueStrucWithTax);
						for(Dues_Summary__c taxObj :dueStrucWithTax.taxes)
						{
							taxesList.add(taxObj);
							if(taxObj.Service_Charge_Name__c==null && taxObj.Amount__c !=null)
							{
								if(applyDueTxnRec.Tax_Amount__c==null) 
								{
									applyDueTxnRec.Tax_Amount__c=0.00;
								}
								applyDueTxnRec.Tax_Amount__c += taxObj.Amount__c;
							}
							else if(taxObj.Service_Charge_Name__c!=null || (taxObj.Service_Charge_Name__c!=null && taxObj.Tax_Applied_On_Service_Charge__c!=null))
							{
								if(applyDueTxnRec.Service_Charge__c==null)
								{
									applyDueTxnRec.Service_Charge__c=0.00;
								}
								applyDueTxnRec.Service_Charge__c += taxObj.Amount__c;
							}							
						}
						txnObjListToInsert.add(applyDueTxnRec);
					}	
				}
			}
			dueStructureListToInsert.add(new dueStructure(dueRecs, txnDueSummaryRecs.get(dueId)));
		}
		if(txnObjListToInsert!=null)
		{
			List<Database.SaveResult> recs = Data.create(txnObjListToInsert);
			dbSaveResultList.addAll(recs);
		}

		if(taxesList!=null)
		{
			Data.create(taxesList);
		}

		txnObjListToInsert = new List<Dues_Summary__c>();
		taxesList = new List<Dues_Summary__c>();

		for(dueStructure dueStrucObj :dueStructureListToInsert)
		{
			for(dueStructure1 dueSturc1Obj :dueStrucObj.dueRecs)
			{
				dueSturc1Obj.txnRec.Due_Summary__c = dueStrucObj.txnDueRec.id;
				txnObjListToInsert.add(dueSturc1Obj.txnRec);
				for(Dues_Summary__c taxObj :dueSturc1Obj.taxes)
				{
					taxObj.Due_Summary__c = dueSturc1Obj.txnRec.id;
					taxesList.add(taxObj);
				}				
			}
		}

		if(txnObjListToInsert!=null) 
		{
			Data.modify(txnObjListToInsert);
		}
		if(taxesList!=null) 
		{
			Data.modify(taxesList);
		}

	}
	catch(Exception ex)
	{
		failedRecs.addAll((List<Apply_due_on_members__c>) scope);
		throw ex;
	}
}

public void finish(Database.BatchableContext BC) {
	AsyncApexJob a = (AsyncApexJob) Data.read('Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :jobId', new Map<String, Object> {'jobId' => BC.getJobId()}).get(0); 

		if(a.TotalJobItems != 0)
		{
		// collect failure results
		List<Database.SaveResult> successRecs = new List<Database.SaveResult>();
		
		for(integer i =0; i<dbSaveResultList.size();i++)
		{
			If(dbSaveResultList[i].isSuccess())
			{
				successRecs.add(dbSaveResultList[i]);
			}
		}

		// Send an email to the Apex job's submitter notifying of job completion.                                          
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();         
		String[] toAddresses = new String[] {a.CreatedBy.Email};         
		mail.setToAddresses(toAddresses);
		mail.setSubject('Generate Dues Batch ' + a.Status);
		if(!(successRecs.size()>0 && dueIdList!=null && dueIdList.size()>0))
		{
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors + ' failures.'); 
		}
		else
		{ 
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors + ' failures. '
				+'\nThe Number of dues generated are '+(successRecs.size() - dueIdList.size())
				+'\nThe Number of failed dues are '+failedRecs.size()
				);
		}
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
		if(a.NumberOfErrors == 0)
		{
			String effecDateRec = 'Effective Date Record';
			List<AP_Aging__c> ApAging = [select Effective_Date__c, Last_Generate_Due_Batch_Run_Date__c  from AP_Aging__c where name =:effecDateRec];
			if(ApAging.size()==0)
			{
				AP_Aging__c ap = new AP_Aging__c(Name='Effective Date Record', Last_Generate_Due_Batch_Run_Date__c=postDate, Last_Generate_Due_Billing_Period__c=billingMonth.split('_')[0]);
				Data.create(ap);
			}
			else
			{
				ApAging[0].Last_Generate_Due_Batch_Run_Date__c=postDate;
				ApAging[0].Last_Generate_Due_Billing_Period__c=billingMonth.split('_')[0];
				Data.modify(ApAging);
			} 
		}
	}

	@TestVisible
	private class dueStructure
	{
		Dues_Summary__c txnDueRec;
		List<dueStructure1> dueRecs;

		dueStructure(List<dueStructure1> txnNTaxes, Dues_Summary__c txnRec)
		{
			dueRecs = txnNTaxes;
			txnDueRec = txnRec;
		}
	}

	@TestVisible
	private class dueStructure1
	{
		Dues_Summary__c txnRec;
		List<Dues_Summary__c> taxes;

		dueStructure1(List<Dues_Summary__c> taxList)
		{
			taxes = taxList;
		}

		dueStructure1(Dues_Summary__c txnRec, List<Dues_Summary__c> taxesList)
		{
			this.txnRec = txnRec;
			taxes = taxesList;
		}

		void setTaxesList(List<Dues_Summary__c> taxList)
		{
			taxes = taxList;
		}
	}
	
	@TestVisible
	private dueStructure1 SaveTaxesForPassedTypeSubtype(String type, String subtype, Decimal amountOnWhichSCalculate, List<TxnChargeToTaxMapping__c> taxesList)
	{
		List<TxnChargeToTaxMapping__c> taxesWithPassedTypeSubtype = new List<TxnChargeToTaxMapping__c>();
		for (TxnChargeToTaxMapping__c mappedTaxes : taxesList)
		{
			if(mappedTaxes.Type__c==type && mappedTaxes.Subtype__c==subtype)
			{
				taxesWithPassedTypeSubtype.add(mappedTaxes);
			}
		}

		if(!(taxesWithPassedTypeSubtype.size()>0)) 
		{
			for (TxnChargeToTaxMapping__c mappedTaxes : taxesList) {
				if(mappedTaxes.Type__c==type && mappedTaxes.Subtype__c==null){
					taxesWithPassedTypeSubtype.add(mappedTaxes);
				}
			}
		}

		if(taxesWithPassedTypeSubtype.size()>0) 
		{
			return getTaxesOnTypeSOrType(taxesWithPassedTypeSubtype, amountOnWhichSCalculate);
		}
		else 
		{
			return null;
		}
	}

	@TestVisible
	private dueStructure1 getTaxesOnTypeSOrType(List<TxnChargeToTaxMapping__c> taxList, Decimal amountOnWhichSCalculate)
	{
		Decimal taxAmount = 0;
		dueStructure1 alltaxesNServCharges;
		List<Dues_Summary__c> taxesList = new List<Dues_Summary__c>();
		Boolean isServiceChargeCalculated = false;
		Decimal serviceChargeAmount = 0;
		String sCName;

		for(TxnChargeToTaxMapping__c mappedTaxes :taxList){
			if(mappedTaxes.Service_Charge_applicable__c){
				sCName =Utility.getNameOfServiceCharge(mappedTaxes.Service_Charge_Name__c); 
			}

			//Check if the service charge is applicable on the amount and taxes? if yes than get and set serviceCharge setting
			if (mappedTaxes.Service_Charge_applicable__c && !isServiceChargeCalculated) 
			{
				Decimal serviceChargePercantage;
				serviceChargePercantage = Utility.getPercentageOfServiceCharge(mappedTaxes.Service_Charge_Name__c);
				isServiceChargeCalculated = true;
				serviceChargeAmount = ((amountOnWhichSCalculate / 100) * serviceChargePercantage).setScale(2, RoundingMode.HALF_UP);
				Dues_Summary__c taxObj = new Dues_Summary__c(RecordTypeId=Utility.searchRecordType('Taxes','Dues_Summary__c'));
				taxObj.Amount__c = serviceChargeAmount;
				taxObj.Service_Charge_Name__c = sCName;
				taxesList.add(taxObj);
			}

			//Calculate all applicable taxes on the amount
			if (mappedTaxes.TaxId__c != null) 
			{
				Decimal taxPercantage = Utility.getPercentageOfTax(mappedTaxes.TaxId__c);
				Dues_Summary__c taxObj = new Dues_Summary__c(RecordTypeId=Utility.searchRecordType('Taxes','Dues_Summary__c'));
				taxObj.Amount__c = ((amountOnWhichSCalculate / 100) * taxPercantage).setScale(2, RoundingMode.HALF_UP);
				taxObj.Tax_Name__c = Utility.getNameOfTax(mappedTaxes.TaxId__c);
				taxesList.add(taxObj);
			}
			if(mappedTaxes.TaxId__c!=null && mappedTaxes.Tax_Name_applicable_on_service_charge__c!=null && isServiceChargeCalculated)
			{
				Decimal taxPercantage = Utility.getPercentageOfTax(mappedTaxes.TaxId__c);
				Dues_Summary__c taxObj = new Dues_Summary__c(RecordTypeId=Utility.searchRecordType('Taxes','Dues_Summary__c'));
				taxObj.Amount__c = ((serviceChargeAmount / 100) * taxPercantage).setScale(2, RoundingMode.HALF_UP);
				taxObj.Tax_Name__c = Utility.getNameOfTax(mappedTaxes.TaxId__c);
				taxObj.Tax_Applied_On_Service_Charge__c = true;
				taxesList.add(taxObj);
			}
		}
		alltaxesNServCharges = new dueStructure1(taxesList);
		return alltaxesNServCharges;
	}

	@TestVisible
	private Map<Id, List<Billing_Custom_Distribution__c>> getCustomDistributions(Set<Id> dueIdsSet)
	{
		Map<Id, List<Billing_Custom_Distribution__c>> distributionMap = new Map<Id, List<Billing_Custom_Distribution__c>>();
		for(Billing_Custom_Distribution__c billCusDis : (List<Billing_Custom_Distribution__c>) Data.read('select id, January__c, February__c, March__c, April__c, May__c, June__c, July__c, August__c, September__c, October__c, November__c, December__c, Member_Dues__c from Billing_Custom_Distribution__c where Member_Dues__c in :dueIds order by Type__c ASC', new Map<String, Object> {'dueIds'=> dueIdsSet})){
			if(!distributionMap.containsKey(billCusDis.Member_Dues__c)) {
				distributionMap.put(billCusDis.Member_Dues__c, new List<Billing_Custom_Distribution__c>());
			}
			distributionMap.get(billCusDis.Member_Dues__c).add(billCusDis);
		}
		return distributionMap;
	}
}