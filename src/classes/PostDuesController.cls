public with sharing class PostDuesController {
	public List<SelectOption> billingMonthList {get; set;}
	public String selectedBillingMonth {get; set;}
	public List<SelectOption> dueDatesList {get; set;}
	public String selectedDueDate {get; set;}
	public List<SelectOption> unSelectedDues {get; set;}
	public List<SelectOption> selectedDuesListToBePosted {get; set;}
	public List<SelectOption> allDuesToView {get; set;}
	public string dueIdToView {get; set;}
	public String currencySymbol {get; set;}
	public Boolean isShowDueChecked {get; set;}
	public String postReject {get; set;}
	public String status {get; set;}
	public String confirmDuePostings {get; set;}
	public Set<Id> dueIdsListToBePosted {get; set;}
	public Id batchId {get; set;}
	public Boolean isDuesToBePostedBlank {get; set;}

	public PostDuesController() 
	{
		batchId = GenerateDuesController.getStatusOfBatch('PostDuesBatch');
		dueIdsListToBePosted = new Set<Id>();
		currencySymbol = Utility.getcurrencySymbol();
		selectedDuesListToBePosted = new List<SelectOption>();
		billingMonthList = getBillingMonths();
		if(billingMonthList.size()>0){
			selectedBillingMonth = billingMonthList[0].getValue();
			renderPostDate();
		}
	}

	public List<SelectOption> getBillingMonths()
	{
		List<SelectOption> billingMonths = new List<SelectOption>();
		AggregateResult[] allBillM = Data.read('select Billing_Period__c from Dues_Summary__c where Posted__c=:postStatus AND recordTypeId=:recId group by Billing_Period__c', new Map<String, Object> {'postStatus' => false, 'recId' => Utility.searchRecordType('Due Summary','Dues_Summary__c')});
		for(AggregateResult ag :allBillM)
		{
			billingMonths.add(new SelectOption(String.valueOf(ag.get('Billing_Period__c')), String.valueOf(ag.get('Billing_Period__c'))));
		}
		return billingMonths;
	}

	public void renderPostDate()
	{
		dueDatesList = getDueDates(selectedBillingMonth);
		selectedDueDate = dueDatesList[0].getValue();
		unSelectedDues = getAllAvailableDues(Date.valueOf(selectedDueDate), selectedBillingMonth);
		allDuesToView = unSelectedDues.clone();
		dueIdToView = allDuesToView[0].getValue();
		selectedDuesListToBePosted = new List<SelectOption>();
	}

	public List<SelectOption> getDueDates(String billingMonthName)
	{
		List<SelectOption> dueDates = new List<SelectOption>();
		AggregateResult[] allDueSum = Data.read('select Post_Date__c from Dues_Summary__c where Posted__c=:postStatus AND Billing_Period__c=:billMonth AND RecordTypeId=:recId group by Post_Date__c', 
			new Map<String, Object> {'postStatus' => false, 'billMonth' => billingMonthName, 'recId' => Utility.searchRecordType('Due Summary','Dues_Summary__c')});

		for(AggregateResult ag :allDueSum)
		{
			dueDates.add(new SelectOption(String.valueOf(ag.get('Post_Date__c')), Datetime.valueOf(String.valueOf(ag.get('Post_Date__c'))).format('dd-MMM-yyyy')));
		}
		return dueDates;
	}

	public void renderDues()
	{
		unSelectedDues = getAllAvailableDues(Date.valueOf(selectedDueDate), selectedBillingMonth);
		allDuesToView = unSelectedDues.clone();
		dueIdToView = allDuesToView[0].getValue();
		selectedDuesListToBePosted = new List<SelectOption>();
	}

	public List<SelectOption> getAllAvailableDues(Date postDate, String billingMonthName)
	{
		List<SelectOption> availableDues = new List<SelectOption>();
		List<Dues_Summary__c> allDueSumm = Data.read('Select Member_Dues__r.Id, Member_Dues__r.Name from Dues_Summary__c where Billing_Period__c=:monthName AND Post_Date__c=:selectedDueDate AND Posted__c=:poststatus AND RecordTypeId=:recId',
			new Map<String, Object> {'monthName' => billingMonthName, 
									'selectedDueDate' => postDate,
									'poststatus' => false,
									'recId' => Utility.searchRecordType('Due Summary','Dues_Summary__c')
								});
		for(Dues_Summary__c dueSumObj :allDueSumm)
		{
			availableDues.add(new SelectOption(dueSumObj.Member_Dues__r.Id, dueSumObj.Member_Dues__r.Name));
		}
		return availableDues;
	}

	public void renderViewTable()
	{

	}

public void PostRejectDues()
{
	isDuesToBePostedBlank = false;
	if(postReject=='post' && status=='confirm')
	{
		for(SelectOption selOp :selectedDuesListToBePosted)
		{
			dueIdsListToBePosted.add(selOp.getValue());
		}
		confirmDuePostings = '';
		List<Dues_Summary__c> dueSummPosted = getPostedDueSummForBillingMonthAndYear(dueIdsListToBePosted);
		if(dueSummPosted.size()>0)
		{
			for(Integer i=0; i<dueSummPosted.size(); i++)
			{
				dueIdsListToBePosted.remove(dueSummPosted[i].Member_Dues__c);
				if(i<(dueSummPosted.size()-1))
				confirmDuePostings += dueSummPosted[i].Member_Dues__r.Name +', ';
				else
				confirmDuePostings += dueSummPosted[i].Member_Dues__r.Name;	
			}
		}
		if(dueIdsListToBePosted.size()==0)
			isDuesToBePostedBlank = true;
		return;
	}

	if(postReject=='post' && status=='post')
	{
		if(dueIdsListToBePosted.size()==0){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select a valid due to post or reject.'));
			return;
		}
		Map<Id, Dues_Summary__c> dueSummMap = new Map<Id, Dues_Summary__c> (getUnpostedDues(dueIdsListToBePosted));
		Default_Account__c defAccount = Utility.getDefaultFinancialAccount('Accounts Receivable');

		if(defAccount!=null){
			PostDuesBatch postDues = new PostDuesBatch(defAccount, Utility.getTaxAndFinancialAccountMappings(), dueSummMap.keySet(), 'Post');
			batchId = Database.executeBatch(postDues, 150);
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Default AR Account mapping does not exist. Please add that and try again.'));
			return;
		}
	}

	if(postReject=='Reject' && status=='Reject')
	{
		for(SelectOption selOp :selectedDuesListToBePosted)
		{
			dueIdsListToBePosted.add(selOp.getValue());
		}
		if(dueIdsListToBePosted.size()==0){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select dues.'));
			return;
		}
		Map<Id, Dues_Summary__c> dueSummMap = new Map<Id, Dues_Summary__c> (getUnpostedDues(dueIdsListToBePosted));
		PostDuesBatch postDues = new PostDuesBatch(null, null, dueSummMap.keySet(), 'Reject');
		batchId = Database.executeBatch(postDues, 200);
	}
}

	public List<Dues_Summary__c> getPostedDueSummForBillingMonthAndYear(Set<Id> dueIds)
	{
		List<Dues_Summary__c> allDueSumm = Data.read('Select Id, Member_Dues__r.Name, Member_Dues__c from Dues_Summary__c where RecordTypeId=:recId AND Member_Dues__c in :dueIds AND Billing_Period__c=:selectedBillingMonth AND CALENDAR_YEAR(Post_Date__c)=:postDateYear AND Posted__c=:poststatus',
			new Map<String, Object> {'recId' => Utility.searchRecordType('Due Summary', 'Dues_Summary__c'),
									 'dueIds' => dueIds,
									 'selectedBillingMonth' => selectedBillingMonth,
									 'postDateYear' => Date.valueOf(selectedDueDate).year(),
									 'poststatus' => true});
		return allDueSumm;
	}

	public List<Dues_Summary__c> getUnpostedDues(Set<Id> dueIds)
	{
		List<Dues_Summary__c> allDueSumm = Data.read('Select Id, Member_Dues__r.Name, Member_Dues__c from Dues_Summary__c where RecordTypeId=:recId AND Member_Dues__c in :dueIds AND Billing_Period__c=:selectedBillingMonth AND Post_Date__c=:postDate AND Posted__c=:poststatus',
			new Map<String, Object> {'recId' => Utility.searchRecordType('Due Summary', 'Dues_Summary__c'),
									 'dueIds' => dueIds,
									 'selectedBillingMonth' => selectedBillingMonth,
									 'postDate' => Date.valueOf(selectedDueDate),
									 'poststatus' => false});
		return allDueSumm;
	}	
}