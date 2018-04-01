public with sharing class ManualDueSetupController {

	public Contact memberRecord {get; set;}
	public Member_Dues__c memDues {get; set;}
	public TXN__c dueRec {get; set;}
	public boolean renderTaxes {get; set;}
	public boolean renderSC {get; set;}
	public taxesAndSCharges taxesAndSC {get; set;}
	public String currencySymbol {get; set;}
	public String SCTaxableStatus {get; set;}
	public String TaxesAppliedOnSC {get; set;}

	public ManualDueSetupController() {
		currencySymbol = Utility.getcurrencySymbol();
		renderSC = false;
		renderTaxes = false;
		Id passedId = ApexPages.currentPage().getParameters().get('id');
		memberRecord = (Contact)Data.read('Select id, Name, Tax_Exempt__c, Tax_Exempt_Number__c from Contact where RecordTypeId=:recId AND Id=:passedId', 
			new Map<String, Object> {'recId' => Utility.searchRecordType('Member', 'Contact'),
									 'passedId'	=> passedId})[0];
		if(memberRecord==null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'The member is not valid.'));
			return;
		}
		dueRec = new TXN__c(RecordTypeId=Utility.searchRecordType('Dues', 'TXN__c'), Date__c = Date.today(), Amount__c=0.00);
	}

	public void changeDueSelected()
	{
		if(dueRec.Member_Dues__c!=null){
		memDues = (Member_Dues__c)Data.read('Select Id, Financial_Account__c, Default_Billing_Frequency__c, Type__c, Subtype__c, Statements_Description__c from Member_Dues__c where Id=:memDueId', 
			new Map<String, Object> {'memDueId' => dueRec.Member_Dues__c})[0];
		dueRec.Statement_Description__c = memDues.Statements_Description__c;
		updateTaxesAndSCList(memDues.Type__c, memDues.Subtype__c, dueRec.Amount__c);
		}
	}

	public void updateTaxesAndSCList(String type, String subtype, Decimal Amount)
	{	
		SCTaxableStatus = '';
		TaxesAppliedOnSC = '';
		renderSC = false;
		renderTaxes = false;
		taxesAndSCharges taxesAndSCL = new taxesAndSCharges(type, subtype, Amount);
		taxesAndSC = new taxesAndSCharges(type, subtype);
		taxesAndSC.serviceCharge = taxesAndSCL.serviceCharge;
		taxesAndSC.SCAmount = taxesAndSCL.SCAmount;
		taxesAndSC.SCPercentage = taxesAndSCL.SCPercentage;
		taxesAndSC.taxesList = new List<TaxesAndServiceCharge.Taxes>();
		for(TaxesAndServiceCharge.Taxes taxesObj :taxesAndSCL.taxesList)
		{
			boolean dupFound = false;
			for(TaxesAndServiceCharge.Taxes taxesObj1 :taxesAndSC.taxesList){
				if(taxesObj.taxName==taxesObj1.taxName){
					SCTaxableStatus = 'Taxable';
					if(TaxesAppliedOnSC=='')
					{
						TaxesAppliedOnSC += taxesObj1.taxName;
					}
					TaxesAppliedOnSC += ','+taxesObj1.taxName;
					taxesObj1.Amount += taxesObj.Amount;
					taxesObj1.taxAppliedOnSC = true;
					dupFound = true;
				}
			}
			if(!dupFound){
				taxesAndSC.taxesList.add(taxesObj);
			}
		}
		if(taxesAndSC.serviceCharge!=null)
		{
			renderSC = true;
		}
		if(taxesAndSC.taxesList.size()>0)
		{
			renderTaxes = true;
		}
	}

	public class taxesAndSCharges extends TaxesAndServiceCharge
	{
		public taxesAndSCharges(String type, String subtype, Decimal Amount)
		{
			super(type, subtype, Amount);
		}

		public taxesAndSCharges(String type, String subtype)
		{
			super(type, subtype);
		}
	}

	public PageReference save()
	{
		Map<String, Tax_To_Account_Mapping__c> mapOfTaxesAndFinAccount = Utility.getTaxAndFinancialAccountMappings();
		Map<Id, Id> contactToBillToMemberMap = Utility.getBillToMember(new List<Id>{memberRecord.Id});
		PageReference pg = Page.ManualDueSetup;
		pg.getParameters().put('id', memberRecord.id);
		pg.getParameters().put('message', 'Saved Successfully');
		if(dueRec.Date__c==null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Post date is required.'));
			return null;
		}
		if(dueRec.Member_Dues__c==null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Due selection is mandatory.'));
			return null;
		}
		Default_Account__c defAcc = Utility.getDefaultFinancialAccount('Accounts Receivable');
		Savepoint sp = Database.setSavepoint();
		try{
			Map<String, Tax_To_Account_Mapping__c> taxesAndSCMap = Utility.getTaxAndFinancialAccountMappings();
			List<TXN__c> txnRecsToInsert = new List<TXN__c>();
			dueRec.Bill_To_Member__c = contactToBillToMemberMap.get(memberRecord.Id);
			dueRec.Customer__c = memberRecord.id;
			dueRec.Tax__c = 0;
			dueRec.Service_Charge__c = 0;
			dueRec.Debit_Financial_Account__c = defAcc.Financial_Account__c;
			dueRec.Credit_Financial_Account__c = memDues.Financial_Account__c;
			txnRecsToInsert.add(dueRec);
			Data.create(txnRecsToInsert);
			txnRecsToInsert = new List<TXN__c>();
			if(taxesAndSC.serviceCharge!=null && taxesAndSC.SCAmount!=null){
			TXN__c SCRec = new TXN__c(RecordTypeId=Utility.searchRecordType('Service Charges', 'TXN__c'));
			SCRec.Debit_Financial_Account__c = defAcc.Financial_Account__c;
			SCRec.Credit_Financial_Account__c = mapOfTaxesAndFinAccount.get(taxesAndSC.serviceCharge).Financial_Accounts__c;
			SCRec.Amount__c = taxesAndSC.SCAmount;
			SCRec.Service_Charge_Name__c = taxesAndSC.serviceCharge;
			SCRec.Bill_To_Member__c = contactToBillToMemberMap.get(memberRecord.Id);
			SCRec.Customer__c = memberRecord.id;
			SCRec.Related_To__c = dueRec.id;
			SCRec.Date__c = dueRec.Date__c;
			dueRec.Service_Charge__c = SCRec.Amount__c;
			txnRecsToInsert.add(SCRec);
			}
			Boolean taxExempt = false;
			for(TaxesAndServiceCharge.Taxes taxesObj :taxesAndSC.taxesList)
			{
				if(taxesObj.taxExemption==null || !taxesObj.taxExemption)
				{
					TXN__c taxes = new TXN__c(RecordTypeId=Utility.searchRecordType('Taxes', 'TXN__c'));
					taxes.Amount__c =  taxesObj.Amount;
					taxes.Debit_Financial_Account__c = defAcc.Financial_Account__c;
					taxes.Credit_Financial_Account__c = mapOfTaxesAndFinAccount.get(taxesObj.taxName).Financial_Accounts__c;
					taxes.Tax_Name__c = taxesObj.taxName;
					taxes.Bill_To_Member__c = contactToBillToMemberMap.get(memberRecord.Id);
					taxes.Customer__c = memberRecord.id;
					taxes.Date__c = dueRec.Date__c;
					taxes.Related_To__c = dueRec.id;
					if(taxesObj.taxAppliedOnSC!=null && taxesObj.taxAppliedOnSC){
						taxes.Tax_Applied_On_Service_Charge__c = taxesObj.taxAppliedOnSC;
					}
					dueRec.Tax__c += taxes.Amount__c;
					txnRecsToInsert.add(taxes);
				}
				else
				{
					taxExempt = true;
				}
			}
			if(taxExempt)
			{
				if(memberRecord.Tax_Exempt__c==false){
					Database.rollback(sp);
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please set Tax Exempt status on member profile page.'));
					return null;
				}
			}
			Data.modify(dueRec);
			Data.create(txnRecsToInsert);
			pg.setRedirect(true);
			return pg;
		}
		catch(Exception ex)
		{
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Failed - '+ex.getMessage()));
			return null;
		}
	}
}