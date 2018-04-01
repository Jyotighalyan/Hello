/**
* @Description : controller to change membership types
*/
public with sharing class ChangeMembershipTypeController {
	public List<contactWrapper> listToShow {get; set;}
	public Map<Id, contactWrapper> mapOfSelectedMembers {get; set;}
	public Integer size{get; set;}
	public Boolean isSelectAll {get; set;}
	public Contact contactRecord {get; set;}
	public List<SelectOption> membershipTypes {get; set;}
	public List<SelectOption> paginationSizeOptions{get;set;}
	public String selectedMemType {get; set;}
	public Boolean isSearchSelected {get; set;}
	private String query;
	private String membershipType;
	private String relationship;
	private String status;
	private String substatus;
	private Map<String, Object> queryMap;
	private List<Contact> allContactsList;
	private String queryBackup;

	public ChangeMembershipTypeController() {
		paginationSizeOptions = new List<SelectOption>();
     	paginationSizeOptions.add(new SelectOption('5','5'));
     	paginationSizeOptions.add(new SelectOption('10','10'));
     	paginationSizeOptions.add(new SelectOption('20','20'));
     	paginationSizeOptions.add(new SelectOption('50','50'));
     	paginationSizeOptions.add(new SelectOption('100','100'));
		isSearchSelected = false;
		contactRecord = (Contact)Contact.SObjectType.newSObject(Id.valueOf(Utility.searchRecordType('Member','Contact')), true);
		membershipTypes = getMembershipTypes();
		if(membershipTypes.size()>0){
			selectedMemType = membershipTypes[0].getValue();
		}
		mapOfSelectedMembers = new Map<Id, contactWrapper>();
		size = 10;
		searchMembers();
		isSelectAll = false;
	}

	public ApexPages.StandardSetController fullContactsList {
		get{
			if(fullContactsList==null){
				fullContactsList = new ApexPages.StandardSetController(Data.locator(query, queryMap));
				fullContactsList.setPageSize(size);
			}
			return fullContactsList;
		}
		set;
	}

	public void init() {
 		listToShow = new List<contactWrapper>();
 		for (Contact cont : (List<Contact>)fullContactsList.getRecords()) {
 			if(mapOfSelectedMembers != null && mapOfSelectedMembers.containsKey(cont.id)){
 				listToShow.add(mapOfSelectedMembers.get(cont.id));
 			}
 			else{
   				listToShow.add(new contactWrapper(cont));
 			}
 		}
 	}

 	public void doSort()
 	{
 		String columnName = ApexPages.currentPage().getParameters().get('columnName');
 		String description = ApexPages.currentPage().getParameters().get('description');
 		query = queryBackup;
 		query += ' ORDER BY '+columnName+' '+description+' limit :querylimit';
 		fullContactsList = null;
 		init();
 	}

 	public void searchMembers()
 	{
 		isSearchSelected = true;
 		fullContactsList = null;
 		mapOfSelectedMembers = new Map<Id, contactWrapper>();
 		if(contactRecord.Membership_Type__c==null && contactRecord.Relationship__c==null && contactRecord.Status__c==null && contactRecord.Substatus__c==null)
 		{
 			isSearchSelected = false;
 			listToShow = new List<contactWrapper>();
 			return;
 		}
 		query = 'Select Id, Name, Membership_Type__c, Substatus__c, Customer_Id__c, Email, Relationship__c, Status__c from Contact where RecordTypeId=:recId';
 		queryMap = new Map<String, Object> {'recId' => Utility.searchRecordType('Member','Contact'), 'querylimit' => 10000};

 		membershipType = contactRecord.Membership_Type__c;
 		relationship = contactRecord.Relationship__c;
 		status = contactRecord.Status__c;
 		substatus = contactRecord.Substatus__c;
 		if(membershipType!=null)
 		{
 			membershipType = String.escapeSingleQuotes(membershipType);
 			query += ' AND Membership_Type__c=: membershipType';
 			queryMap.put('membershipType', membershipType);
 		}
 		if(relationship!=null)
 		{
 			relationship = String.escapeSingleQuotes(relationship);
 			query += ' AND Relationship__c=: relationship';
 			queryMap.put('relationship', relationship);
 		}
 		if(status!=null)
 		{
 			status = String.escapeSingleQuotes(status);
 			query += ' AND Status__c=: state';
 			queryMap.put('state', status);
 		}
 		if(substatus!=null)
 		{
 			substatus = String.escapeSingleQuotes(substatus);
 			query += ' AND Substatus__c=: substats';
 			queryMap.put('substats', substatus);
 		}
 		queryBackup = query;
 		query += ' limit :querylimit';
 		allContactsList = Data.read(query, queryMap);
 		init();
 	}

 	public void selectAll()
 	{
 		mapOfSelectedMembers = new Map<Id, contactWrapper>();
 		if(isSelectAll && allContactsList!=null && allContactsList.size()>0){
 			for(Contact mem : allContactsList)
 			{
 				mapOfSelectedMembers.put(mem.id, new contactWrapper(mem, true));
 			}
 			for(contactWrapper conWrap :listToShow)
 			{
 				conWrap.isUpdate = true;
 			}
 		}
 		else if(!isSelectAll)
 		{
 			mapOfSelectedMembers = new Map<Id, contactWrapper>();
 			for(contactWrapper conWrap :listToShow)
 			{
 				conWrap.isUpdate = false;
 			}
 		}
 	}

 	public PageReference changeMT()
 	{
 		PageReference pg = page.ChangeMembershipType;
 		List<Contact> memListToUpdate = new List<Contact>();
 		if(listToShow.size()>0){
 			for(contactWrapper currentCont : listToShow)
 			{
 				if(currentCont.isUpdate)
 				{
 					mapOfSelectedMembers.put(currentCont.member.id, currentCont);
 				}
 			}
 		}
 		if(mapOfSelectedMembers.size()<1){
 			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select members to be updated.'));
 			return null;
 		}
 		for(contactWrapper conWrap : mapOfSelectedMembers.values())
 		{
 			conWrap.member.Membership_Type__c = selectedMemType;
 			memListToUpdate.add(conWrap.member);
 		}
 		Data.modify(memListToUpdate);
 		pg.setRedirect(true);
 		return pg;
 	}

 	public void first() {
   		updateSearchItemsMap();
   		fullContactsList.first();
   		init();
 	}

 	public void last() {
   		updateSearchItemsMap();
   		fullContactsList.last();
   		init();
 	}

 	public PageReference refreshPageSize() {
        fullContactsList.setPageSize(size);
        init();
        return null;
    }

	/**
	* @Description : indicates whether there are more records after the current page set.
	*/
	public Boolean hasNext {
	 	get {
	   		return fullContactsList.getHasNext();
	 	}
	 		set;
 	} 

 	/**
	* @Description : indicates whether there are more records before the current page set.
	*/
	public Boolean hasPrevious {
	 	get {
	   		return fullContactsList.getHasPrevious();
	 	}
	 		set;
 	}

 	public void previous() {
	   updateSearchItemsMap();
	   fullContactsList.previous();
	   init();
 	}

 	public void next() {
	   updateSearchItemsMap();
	   fullContactsList.next();
	   init();
 	}

 	public Integer pageNumber {
 	get {
   		return fullContactsList.getPageNumber();
 	}
 		set;
 	}

	Public Integer getTotalPages(){
		Decimal totalSize = fullContactsList.getResultSize();
	 	Decimal pageSize = fullContactsList.getPageSize();
	 	Decimal pages = totalSize/pageSize;
	 	return (Integer)pages.round(System.RoundingMode.CEILING);
 	}

 	private void updateSearchItemsMap()
 	{
 		for(contactWrapper conWrp : listToShow){
			if(conWrp.isUpdate){
	 			mapOfSelectedMembers.put(conWrp.member.id, conWrp);
			}
			if(!conWrp.isUpdate && mapOfSelectedMembers.containsKey(conWrp.member.id)){
	 			mapOfSelectedMembers.remove(conWrp.member.id);
			}
 		}
 	}  

	public class contactWrapper
	{
		public Contact member {get; set;}
		public Boolean isUpdate { get; set; }
		public contactWrapper(Contact member)
		{
			this.member = member;
			isUpdate = false;
		}
		public contactWrapper(Contact member, Boolean isUpdate)
		{
			this.member = member;
			this.isUpdate = isUpdate;
		}
	}

	public List<SelectOption> getMembershipTypes()
	{
		List<SelectOption> memType = new List<SelectOption>();
		List<Schema.PicklistEntry> picklistValues = Schema.SObjectType.Contact.fields.Membership_Type__c.getPicklistValues();
		for(Schema.PicklistEntry picklistVal : picklistValues)
		{
			memType.add(new SelectOption(picklistVal.getValue(), picklistVal.getValue()));
		}
		return memType;
	}
}