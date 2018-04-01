public with sharing class ApproveStatementsController {
	public List<StatementWrapper> listToShow {get; set;}
	public Map<Id, StatementWrapper> mapOfSelectedStmts {get; set;}
	public List<SelectOption> paginationSizeOptions{get;set;}
	public List<Statements__c> unapprovedStmts {get; set;}
	public Boolean approveAll {get; set;}
	public Integer size{get; set;}
	public List<SelectOption> unapprovedStmtsOptions {get; set;}
	public Id selectedStatement {get; set;}
	public Boolean showDetails {get; set;}
	public List<SelectOption> availableMemTypes {get; set;}
	public List<SelectOption> selectedMemTypes {get; set;}
	public Integer memIdFrom {get; set;}
	public Integer memIdTo {get; set;}
	public String currencySymbol {get; set;}
	public Id batchId {get; set;}
	public Boolean noStmtsSelected {get; set;}
	private String query;
	private String queryBackup;

	public ApproveStatementsController() {
		showDetails = true;
		unapprovedStmtsOptions = new List<SelectOption>();
		currencySymbol = Utility.getcurrencySymbol();
		query = 'Select id, Billing_Period__c, Approved__c, Date__c, CreatedDate,To_Date__c, Statement_Summary_Name__c from Statements__c where RecordtypeId =:recId AND Approved__c=:apprStatus';
		paginationSizeOptions = new List<SelectOption>();
     	paginationSizeOptions.add(new SelectOption('5','5'));
     	paginationSizeOptions.add(new SelectOption('10','10'));
     	paginationSizeOptions.add(new SelectOption('20','20'));
		mapOfSelectedStmts = new Map<Id, StatementWrapper>();
		size = 5;
		availableMemTypes = new List<SelectOption>();
		selectedMemTypes = new List<SelectOption>();
		for(Schema.PicklistEntry pickEnt :Contact.Membership_Type__c.getDescribe().getPicklistValues())
		{	
			availableMemTypes.add(new SelectOption(pickEnt.getLabel(), pickEnt.getLabel()));
		}
		unapprovedStmts = getUnapprovedStatements();
		if(unapprovedStmts.size()>0){
			for(Statements__c statement : unapprovedStmts){
				unapprovedStmtsOptions.add(new SelectOption(statement.id, statement.Statement_Summary_Name__c+' - '+statement.Billing_Period__c));
			}
			selectedStatement = unapprovedStmtsOptions[0].getValue();
		}
		else{
			showDetails = false;
		}
		init();
	}

	private List<Statements__c> getUnapprovedStatements()
	{
		queryBackup = query;
		return Data.read(query+' order by Date__c', new Map<String, Object> {
			'recId' => Utility.searchRecordtype('Statement Summary','Statements__c'),
			'apprStatus' => false
			});
	}

	public void doSort()
 	{
 		String columnName = ApexPages.currentPage().getParameters().get('columnName');
 		String description = ApexPages.currentPage().getParameters().get('description');
 		query = queryBackup;
 		query += ' ORDER BY '+columnName+' '+description;
 		listOfStatements = null;
 		init();
 	}

	public ApexPages.StandardSetController listOfStatements {
		get{
			if(listOfStatements==null){
				listOfStatements = new ApexPages.StandardSetController(Data.locator(query, new Map<String, Object> {
					'recId' => Utility.searchRecordtype('Statement Summary','Statements__c'),
					'apprStatus' => false
					}));
				listOfStatements.setPageSize(size);
			}
			return listOfStatements;
		}
		set;
	}

	public class StatementWrapper
	{
		public Statements__c stmt {get; set;}
		public Boolean isUpdate { get; set; }
		public StatementWrapper(Statements__c stmt)
		{
			this.stmt = stmt;
			isUpdate = false;
		}
		public StatementWrapper(Statements__c stmt, Boolean isUpdate)
		{
			this.stmt = stmt;
			this.isUpdate = isUpdate;
		}
	}

	public void approveAllStatements()
 	{
 		mapOfSelectedStmts = new Map<Id, StatementWrapper>();
 		if(approveAll && unapprovedStmts!=null && unapprovedStmts.size()>0){
 			for(Statements__c stmt : unapprovedStmts)
 			{
 				mapOfSelectedStmts.put(stmt.id, new StatementWrapper(stmt, true));
 			}
 			for(StatementWrapper stmtWrap :listToShow)
 			{
 				stmtWrap.isUpdate = true;
 			}
 		}
 		else if(!approveAll)
 		{
 			mapOfSelectedStmts = new Map<Id, StatementWrapper>();
 			for(StatementWrapper stmtWrap :listToShow)
 			{
 				stmtWrap.isUpdate = false;
 			}
 		}
 	}

 	public void init() {
 		listToShow = new List<StatementWrapper>();
 		for (Statements__c cont : (List<Statements__c>)listOfStatements.getRecords()) {
 			if(mapOfSelectedStmts != null && mapOfSelectedStmts.containsKey(cont.id)){
 				listToShow.add(mapOfSelectedStmts.get(cont.id));
 			}
 			else{
   				listToShow.add(new StatementWrapper(cont));
 			}
 		}
 	}

 	private void updateSearchItemsMap()
 	{
 		for(StatementWrapper conWrp : listToShow){
			if(conWrp.isUpdate){
	 			mapOfSelectedStmts.put(conWrp.stmt.id, conWrp);
			}
			if(!conWrp.isUpdate && mapOfSelectedStmts.containsKey(conWrp.stmt.id)){
	 			mapOfSelectedStmts.remove(conWrp.stmt.id);
			}
 		}
 	} 

 	public void first() {
   		updateSearchItemsMap();
   		listOfStatements.first();
   		init();
 	}

 	public void last() {
   		updateSearchItemsMap();
   		listOfStatements.last();
   		init();
 	}

 	public PageReference refreshPageSize() {
        listOfStatements.setPageSize(size);
        init();
        return null;
    }

	/**
	* @Description : indicates whether there are more records after the current page set.
	*/
	public Boolean hasNext {
	 	get {
	   		return listOfStatements.getHasNext();
	 	}
	 		set;
 	} 

 	/**
	* @Description : indicates whether there are more records before the current page set.
	*/
	public Boolean hasPrevious {
	 	get {
	   		return listOfStatements.getHasPrevious();
	 	}
	 		set;
 	}

 	public void previous() {
	   updateSearchItemsMap();
	   listOfStatements.previous();
	   init();
 	}

 	public void next() {
	   updateSearchItemsMap();
	   listOfStatements.next();
	   init();
 	}

 	public Integer pageNumber {
 	get {
   		return listOfStatements.getPageNumber();
 	}
 		set;
 	}

	Public Integer getTotalPages(){
		Decimal totalSize = listOfStatements.getResultSize();
	 	Decimal pageSize = listOfStatements.getPageSize();
	 	Decimal pages = totalSize/pageSize;
	 	return (Integer)pages.round(System.RoundingMode.CEILING);
 	}

 	public void renderStatementTable()
 	{

 	}

 	public void approveStatemets()
 	{
 		updateSearchItemsMap();
 		noStmtsSelected = false;
 		List<Statements__c> stmtsList = new List<Statements__c>();
 		if(mapOfSelectedStmts.values().size()>0){
 			for(StatementWrapper stmtWrap : mapOfSelectedStmts.values()){
 				stmtsList.add(stmtWrap.stmt);
 			}
 			ApproveRejectStatements approve = new ApproveRejectStatements(stmtsList, 'Approve');
 			batchId = Database.executeBatch(approve, 9000);
 		}
 		else{
 			noStmtsSelected = true;
 			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Select statements to approve.'));
 		}
 	}
}