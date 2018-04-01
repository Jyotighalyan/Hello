public with sharing class CreditBookSetupController {

	public Map<string,Decimal> totalCreditBookSum{get;set;}
	public Contact memberRecord {get; set;}
	public Credit_Book__c creditRecord {get; set;}
	public String currrencySymbol {get; set;}
	public List<Credit_Book__c> membersToAdd {get; set;}
	public boolean noMember {get; set;}
	@TestVisible
	private String fromPage; 


	public CreditBookSetupController() {
		totalCreditBookSum=new  Map<string,Decimal>();
		fromPage = ApexPages.currentPage().getParameters().get('from');
		creditRecord = new Credit_Book__c();
		currrencySymbol = Utility.getcurrencySymbol();
		if(fromPage=='profilePage'){
			Id memberId = ApexPages.currentPage().getParameters().get('Id');
			List<Contact> members = Data.read('Select id, Name from Contact where Id=:memberId', new Map<String, Object> {'memberId' => memberId});
			if(members.size()>0){
				memberRecord = members[0];
				creditRecord.Member_ID__c = memberRecord.id;
			}
			else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Id is not valid.'));
				return;
			}
			for(Schema.PicklistEntry pi :Credit_Book__c.CreditBookType__c.getDescribe().getPicklistValues()){
				totalCreditBookSum.put(pi.getValue(),0.00);
			}

			//get the balances for all the credit types
			for(AggregateResult ar : (List<AggregateResult>) Data.read('SELECT CreditBookType__c, SUM(Balance__c) sum FROM Credit_Book__c where Member_ID__c = :memberId and (Expiry_Dates__c >= :currentDate or Expiry_Dates__c = null) group by CreditBookType__c order by CreditBookType__c ASC', 
				new Map<String, Object> {'memberId' => memberRecord.id, 'currentDate' => Date.today()}
				)){
				totalCreditBookSum.put(String.valueOf(ar.get('CreditBookType__c')), ((Decimal)ar.get('sum')).setScale(2, RoundingMode.HALF_UP));
			}
		}
		else if(fromPage=='financialLandingPage'){
			membersToAdd = new List<Credit_Book__c> {new Credit_Book__c()};
		}
	}

	public static Map<String, Id> getCreditOrDebitCreditFA(){
		Map<String, Id> finAccMap = new Map<String, Id>();
		List<Default_Account__c> finAcList = new List<Default_Account__c>();
		finAcList = Data.read('Select Id, Default_Type_Name__c, Financial_Account__c from Default_Account__c where RecordTypeId=:recId AND Default_Type_Name__c in :creditDefTName',
			new Map<String, Object> {'recId' => Utility.searchRecordType('Default', 'Default_Account__c'), 'creditDefTName' => new List<String> {'Credit Book - Credit Account', 'Credit Book - Debit Account'}}
		);
		for(Default_Account__c defAcc : finAcList){
			finAccMap.put(defAcc.Default_Type_Name__c, defAcc.Financial_Account__c);
		}
		return finAccMap;
	}

	public PageReference save(){
		List<Credit_Book__c> creditsToInsert = new List<Credit_Book__c>();
		PageReference pg;
		noMember = false;
		String name = ApexPages.currentPage().getParameters().get('type');
		System.debug('name'+name);
		Map<String, Id> defAccMap = getCreditOrDebitCreditFA();
		if(!defAccMap.containsKey('Credit Book - Credit Account') || !defAccMap.containsKey('Credit Book - Debit Account')){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please ensure credit book is mapped with financial accounts.'));
			return null;
		}
		if(creditRecord.CreditBookType__c==null || creditRecord.Date__c==null || creditRecord.Description__c==null || creditRecord.Credit_Amount__c==null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Required fields are missing.'));
			return null;
		}
		creditRecord.Credit_Financial_Account__c = defAccMap.get('Credit Book - Credit Account');
		creditRecord.Debit_Financial_Account__c = defAccMap.get('Credit Book - Debit Account');
		if(name=='memberPage'){
			pg = Page.CreditBookSetup;
			pg.getParameters().put('from', 'profilePage');
			pg.getParameters().put('Id', memberRecord.id);
			pg.getParameters().put('message', 'Saved Successfully.');
			creditsToInsert.add(creditRecord);
		}
		else 
		{
			for(Credit_Book__c membersToAddOn : membersToAdd){
				Credit_Book__c credits = creditRecord.clone(false, false, false, false);
				if(membersToAddOn.Member_ID__c!=null){
					credits.Member_ID__c = membersToAddOn.Member_ID__c;
					creditsToInsert.add(credits);
				}
			}
			if(name=='saveFinancial'){
				pg = Page.FinancialLandingPage;
			}
			else if(name=='saveNewFinancial'){
				pg = Page.CreditBookSetup;
				pg.getParameters().put('from', 'financialLandingPage');
				pg.getParameters().put('message', 'Saved Successfully.');
			}
		}
		if(creditsToInsert.size()==0){
			noMember = true;
			return null;
		}
		Data.create(creditsToInsert);
		pg.setRedirect(true);
		return pg;
	}

	public void addMembers(){
		if(membersToAdd.size()<9999){
			membersToAdd.add(new Credit_Book__c());
		}
	}
}