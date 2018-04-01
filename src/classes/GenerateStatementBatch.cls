public class GenerateStatementBatch implements Database.Batchable<sObject>, Database.Stateful{
	
	@TestVisible	
	private Date fromDate;
	@TestVisible
	private Date toDate;
	@TestVisible
	private Statements__c stmtSummary;
	@TestVisible
	private Integer failedRecs;
	@TestVisible
	private List<Statements__c> stmtSummaries;

	public GenerateStatementBatch(Date fromDate, Date toDate, Statements__c stmtSummary, List<Statements__c> stmtSummaries) {
		this.fromDate = fromDate;
		this.toDate = toDate;
		this.stmtSummary = stmtSummary;
		this.stmtSummaries = stmtSummaries;
		failedRecs = 0;
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		if(stmtSummary.id==null)
   		{
   			Data.create(stmtSummary);
   		}
		return Data.locator('Select Id from Contact where RecordTypeId=:recId order by Name ASC', new Map<String, Object> {'recId' => Utility.searchRecordType('Member' ,'Contact')});
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<Statements__c> statementToInsert = new List<Statements__c>();
   		Map<Id, List<TXN__c>> mapofMemIdAndTxn = new Map<Id, List<TXN__c>>();
   		Map<Id, statementStructure> stmtListToUpdateLocal = new Map<Id, statementStructure>();
   		Set<Id> RelatedTos = new Set<Id>();
   		Map<Id, Statements__c> memIdAndStatement = new Map<Id, Statements__c>();
   		Set<Id> memIds = new Set<Id>();

   		for(Contact memObj : (List<Contact>)scope){
   			memIds.add(memObj.id);
   		}
   		List<Id> taxesAndSCList = new List<Id> {Utility.searchRecordType('Taxes','TXN__C'), Utility.searchRecordType('Service Charges','TXN__C')};
   		Map<Id, TXN__C> mapOfIdAndTXN = new Map<Id, TXN__C> ((List<TXN__C>)Data.read('Select Description__c, Related_To__r.RecordType.Name, Related_To__r.Date__c, Related_To__c, Related_To__r.Name, Related_To__r.Related_To__c, Related_To__r.Related_To__r.Name, Date__c, Reservation__c,  Reservation__r.Name, Reservation__r.Event_Date__c, Statement_Description__c, Statement__c, Amount__c, RecordType.Name, Bill_To_Member__c, Customer__c, (Select Id, Date__c, Amount__c, Statement__c, RecordType.Name from Transactions2__r where RecordTypeId in : taxesRecs) from TXN__C where Bill_To_Member__c in :memberIds AND Date__c>=:fromDate AND Date__c<=:toDate AND RecordTypeId !=:depRecId AND RecordTypeId not in:taxesRecs order by Customer__c', new Map<String, Object>{
			'memberIds' => memIds,
			'fromDate' => fromDate,
			'toDate' => toDate,
			'depRecId' =>Utility.searchRecordType('Deposit','TXN__C'),
			'taxesRecs' => taxesAndSCList
		}));
		mapOfIdAndTXN.putAll(getPreviousUnmapped(stmtSummaries, memIds, taxesAndSCList, fromDate));

   		for(TXN__c txnObj : mapOfIdAndTXN.values()){
   			if(!mapofMemIdAndTxn.containsKey(txnObj.Bill_To_Member__c)){
   				mapofMemIdAndTxn.put(txnObj.Bill_To_Member__c, new List<TXN__c>());
   			}
   			mapofMemIdAndTxn.get(txnObj.Bill_To_Member__c).add(txnObj);
   			RelatedTos.add(txnObj.id);
   		}

   		if(stmtSummary.Statement__c!=null)
   		{
   			// all mem statements
   			List<Statements__c> stmt = Data.read('Select id, Statement_Balance__c, Member__c from Statements__c where RecordTypeId=:recId AND Member__c in :memIds AND Statement__c =:previousStmtSumm',
   				new Map<String, Object> {'recId' => Utility.searchRecordType('Member Statement','Statements__c'),
   										 'memIds' => memIds,
   										 'previousStmtSumm' => stmtSummary.Statement__c
   				});
   			for(Statements__c memStatements :stmt){
   				memIdAndStatement.put(memStatements.Member__c, memStatements);
   			}
   		}

   		// loop over all members
   		for(Id memId :memIds)
   		{
   			statementStructure stmtStrcut = new statementStructure();
			Statements__c memberStatement = new Statements__c(RecordTypeId=Utility.searchRecordType('Member Statement','Statements__c'), Statement__c=stmtSummary.id);
			memberStatement.Billing_Period__c = stmtSummary.Billing_Period__c;
			memberStatement.Member__c = memId;
			statementToInsert.add(memberStatement);
			stmtStrcut.memStatement = memberStatement;
   			memberStatement.Statement_Balance__c = 0;

   			// all txns records for the current member
   			if(mapofMemIdAndTxn.containsKey(memId)){
	   			for(TXN__c txnObjOne :mapofMemIdAndTxn.get(memId))
	   			{
	   				statementToInsert.addAll(createStatementStructure(txnObjOne, stmtStrcut, mapOfIdAndTXN));	
	   			}
   			}
   			if(memIdAndStatement.containsKey(memId)){
   				Statements__c carryFStmt = new Statements__c(RecordTypeId=Utility.searchRecordType('Statement Line','Statements__c'));
   				carryFStmt.Description__c = 'Carry Forward Balance';
   				carryFStmt.Date__c = fromDate;
   				carryFStmt.Amount__c = memIdAndStatement.get(memId).Statement_Balance__c;
   				carryFStmt.Total_Amount__c = carryFStmt.Amount__c;
   				carryFStmt.Type__c = 'Carry Forward';
   				carryFStmt.Bill_To_Member__c = memId;
   				carryFStmt.Customer__c = memId;
   				stmtStrcut.carryForwardStatementLine = carryFStmt;
   				statementToInsert.add(carryFStmt);
   			}
   			stmtListToUpdateLocal.put(memId, stmtStrcut);
   		}

   		if(statementToInsert.size()>0){
   			List<Database.UpsertResult> upsrtRes = Data.upsurt(statementToInsert,Statements__c.Id.getDescribe().getSObjectField(), new Set<String> {''});
   			for(Database.UpsertResult upRec : upsrtRes)
   			{
   				if(!upRec.isSuccess()){
   					failedRecs += 1;
   				}
   			}
   		}

   		statementToInsert = new List<Statements__c>();
   		List<TXN__c> txnsListToUpdate = new List<TXN__c>();
   		for(statementStructure stmtStructueObj :stmtListToUpdateLocal.values())
   		{
   			if(stmtStructueObj.mainTxnIdAndStatementLine.values().size()>0){
	   			for(statementLinesTxnStruc stmtTxns :stmtStructueObj.mainTxnIdAndStatementLine.values())
	   			{
	   				stmtStructueObj.memStatement.Statement_Balance__c += stmtTxns.statementLine.Total_Amount__c;
	   				stmtTxns.statementLine.Statement__c = stmtStructueObj.memStatement.id;
	   				statementToInsert.add(stmtTxns.statementLine);
	   				for(TXN__c txns :stmtTxns.txnsList){
	   					txns.Statement__c = stmtTxns.statementLine.id;
	   					txnsListToUpdate.add(txns);
	   				}
	   			}
   			}
   			if(stmtStructueObj.adjustmentTxnAndStatementLine.values().size()>0){
	   			for(statementLinesTxnStruc stmtTxns :stmtStructueObj.adjustmentTxnAndStatementLine.values())
	   			{
	   				stmtStructueObj.memStatement.Statement_Balance__c += stmtTxns.statementLine.Total_Amount__c;
	   				stmtTxns.statementLine.Statement__c = stmtStructueObj.memStatement.id;
	   				statementToInsert.add(stmtTxns.statementLine);
	   				for(TXN__c txns :stmtTxns.txnsList){
	   					txns.Statement__c = stmtTxns.statementLine.id;
	   					txnsListToUpdate.add(txns);
	   				}
	   			}
   			}
   			if(stmtStructueObj.eventsMap.values().size()>0){
	   			for(List<statementLinesTxnStruc> stmtList :stmtStructueObj.eventsMap.values())
	   			{
	   				for(statementLinesTxnStruc stmtObj :stmtList){
		   				stmtStructueObj.memStatement.Statement_Balance__c += stmtObj.statementLine.Total_Amount__c;
		   				stmtObj.statementLine.Statement__c = stmtStructueObj.memStatement.id;
		   				statementToInsert.add(stmtObj.statementLine);
		   				for(TXN__c txns :stmtObj.txnsList){
		   					txns.Statement__c = stmtObj.statementLine.id;
		   					txnsListToUpdate.add(txns);
		   				}
	   				}
	   			}
   			}
   			if(stmtStructueObj.carryForwardStatementLine!=null){
   				stmtStructueObj.carryForwardStatementLine.Statement__c = stmtStructueObj.memStatement.id;
   				statementToInsert.add(stmtStructueObj.carryForwardStatementLine);
   				stmtStructueObj.memStatement.Statement_Balance__c += stmtStructueObj.carryForwardStatementLine.Total_Amount__c;
   			}
   			statementToInsert.add(stmtStructueObj.memStatement);
   		}
   		Data.modify(txnsListToUpdate);
   		Data.modify(statementToInsert);
	}
	
	public void finish(Database.BatchableContext BC) {
		AsyncApexJob a = (AsyncApexJob) Data.read('Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email, ExtendedStatus from AsyncApexJob where Id = :jobId', new Map<String, Object> {'jobId' => BC.getJobId()}).get(0); 

		if(a.TotalJobItems != 0)
		{
		// Send an email to the Apex job's submitter notifying of job completion.                                          
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();         
		String[] toAddresses = new String[] {a.CreatedBy.Email};         
		mail.setToAddresses(toAddresses);
		mail.setSubject('Generate Statement Batch ' + a.Status);
		if(a.NumberOfErrors>0)
		{
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors 
				+' failures. \n'+a.ExtendedStatus); 
		}
		else 
		{ 
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors + ' failures. '
				+'\n Number of failed statements : '+failedRecs
				);
		}
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}

	@TestVisible
	public class statementStructure
	{ 
		public Statements__c memStatement;
		public Map<Id, statementLinesTxnStruc> mainTxnIdAndStatementLine;
		public Map<Id, statementLinesTxnStruc> adjustmentTxnAndStatementLine;
		public Map<Id, List<statementLinesTxnStruc>> eventsMap;
		public Statements__c carryForwardStatementLine;

		public statementStructure()
		{
			mainTxnIdAndStatementLine = new Map<Id, statementLinesTxnStruc>();
			adjustmentTxnAndStatementLine = new Map<Id, statementLinesTxnStruc>();
			eventsMap = new Map<Id, List<statementLinesTxnStruc>>();
		}
	}

	@TestVisible
	public class statementLinesTxnStruc
	{
		public Date eventDate;
		public Statements__c statementLine;
		public List<TXN__c> txnsList;
		public statementLinesTxnStruc(Statements__c statementLine)
		{
			this.statementLine = statementLine;
			txnsList = new List<TXN__c>();
		}
	}

	public static statementLinesTxnStruc createNewStatementLine(TXN__c txnObj)
	{
		Statements__c statementLine = new Statements__c(RecordTypeId=Utility.searchRecordType('Statement Line','Statements__c'));
		statementLine.Amount__c = txnObj.Amount__c;
		statementLine.Total_Amount__c = txnObj.Amount__c;
		if(statementLine.Total_Amount__c==null)
		{
			statementLine.Amount__c = 0;
			statementLine.Total_Amount__c = 0;
		}
		statementLine.Description__c = txnObj.Statement_Description__c;
		statementLine.Date__c = txnObj.Date__c;
		statementLine.Bill_To_Member__c = txnObj.Bill_To_Member__c;
		statementLine.Customer__c = txnObj.Customer__c;
		statementLine.Type__c = txnObj.RecordType.Name;
		statementLinesTxnStruc stmtStruct = new statementLinesTxnStruc(statementLine);
		stmtStruct.txnsList.add(txnObj);
		updateTaxesSC(txnObj, stmtStruct);
		return stmtStruct;
	}

	/**
	* create stmt line for parent record if it is in current billing cycle else create its own stmt line
 	*/
 	public static statementLinesTxnStruc createNewStatementLine(Id parenttxnObj, TXN__c childtxnObj, Map<Id, TXN__C> mapOfIdAndTXNL, statementStructure stmtStrcut){
 		statementLinesTxnStruc parentStmtLine;
 		if(mapOfIdAndTXNL.containsKey(parenttxnObj)){
			// if child records have parent in this billing cycle then create a stmt line for the parent first and store that in stmtStrcut.mainTxnIdAndStatementLine map
			TXN__c txnObj = (TXN__c)mapOfIdAndTXNL.get(parenttxnObj);
			parentStmtLine = createNewStatementLine(txnObj);
			stmtStrcut.mainTxnIdAndStatementLine.put(txnObj.id, parentStmtLine);
			parentStmtLine.txnsList.add(childtxnObj);
		}
		else{
			// if child records don't have parent in this billing cycle then directly create stmt line for them
			parentStmtLine = createNewStatementLine(childtxnObj);
			stmtStrcut.mainTxnIdAndStatementLine.put(childtxnObj.id, parentStmtLine);
		}
		updateTaxesSC(childtxnObj, parentStmtLine);
		return parentStmtLine;
	}

	public static void updateTaxesSC(TXN__C txnObjMain, statementLinesTxnStruc stmtLine){
		// check for child taxes records on coming parent
		if(txnObjMain.Transactions2__r.size()>0){
		for(TXN__C taxesSC : txnObjMain.Transactions2__r){
			stmtLine.statementLine.Total_Amount__c += taxesSC.Amount__c;
			if(stmtLine.statementLine.Tax__c==null){
				stmtLine.statementLine.Tax__c = 0;
			}
			if(stmtLine.statementLine.Service_Charge__c==null){
				stmtLine.statementLine.Service_Charge__c = 0;
			}
			if(taxesSC.RecordType.Name=='Taxes'){
				stmtLine.statementLine.Tax__c += taxesSC.Amount__c;
			}
			else{
				stmtLine.statementLine.Service_Charge__c += taxesSC.Amount__c;
			}
			stmtLine.txnsList.add(taxesSC);
		}
		}
	}

	public static void updateTaxesSC(TXN__C txnObjMain, statementLinesTxnStruc stmtLine, statementStructure stmtStrcut){
		// check for child taxes records on coming parent
		if(txnObjMain.Transactions2__r.size()>0){
		for(TXN__C taxesSC : txnObjMain.Transactions2__r){
			stmtLine.statementLine.Total_Amount__c += taxesSC.Amount__c;
			stmtStrcut.memStatement.Statement_Balance__c += taxesSC.Amount__c;
			if(stmtLine.statementLine.Tax__c==null){
				stmtLine.statementLine.Tax__c = 0;
			}
			if(stmtLine.statementLine.Service_Charge__c==null){
				stmtLine.statementLine.Service_Charge__c = 0;
			}
			if(taxesSC.RecordType.Name=='Taxes'){
				stmtLine.statementLine.Tax__c += taxesSC.Amount__c;
			}
			else{
				stmtLine.statementLine.Service_Charge__c += taxesSC.Amount__c;
			}
			stmtLine.txnsList.add(taxesSC);
		}
		}
	}

	public List<Statements__c> createStatementStructure(TXN__C txnObjOne, statementStructure stmtStrcut, Map<Id, TXN__C> mapOfIdAndTXN)
	{
		List<Statements__c> statementToInsert = new List<Statements__c>();
		statementLinesTxnStruc stementLineObj;
		if(txnObjOne.Reservation__c==null){

			/*
				for any txn having relatedTo field empty create new stmt line and for refunds create new stmt line and storing it 
				stmtStrcut.mainTxnIdAndStatementLine map so that if next txn is related to this txn then the same stmt line can be used 
				to store that child record as well
			**/
			if(txnObjOne.Related_To__c==null)
			{
				if(!stmtStrcut.mainTxnIdAndStatementLine.containsKey(txnObjOne.id)){
					stementLineObj = createNewStatementLine(txnObjOne);
					statementToInsert.add(stementLineObj.statementLine);
					stmtStrcut.mainTxnIdAndStatementLine.put(txnObjOne.id, stementLineObj);
				}
			}
			else if(txnObjOne.RecordType.Name=='Adjustment' || txnObjOne.RecordType.Name=='Refund')
			{
				/*
					for all adjustments related to a charge 
					storing chargeId and stmt line in stmtStrcut.adjustmentTxnAndStatementLine
				**/
				if(txnObjOne.Related_To__r.Related_To__c==null){
					if(!stmtStrcut.adjustmentTxnAndStatementLine.containsKey(txnObjOne.Related_To__c)){
						stementLineObj = createNewStatementLine(txnObjOne);
						stementLineObj.statementLine.RelatedTo_For_Adjustment__c = txnObjOne.Related_To__r.Name;
						statementToInsert.add(stementLineObj.statementLine);
						stmtStrcut.adjustmentTxnAndStatementLine.put(txnObjOne.Related_To__c, stementLineObj);
					}
					else
					{
						stementLineObj = stmtStrcut.adjustmentTxnAndStatementLine.get(txnObjOne.Related_To__c);
						stementLineObj.statementLine.Amount__c += txnObjOne.Amount__c;
						stementLineObj.statementLine.Total_Amount__c += txnObjOne.Amount__c;
						stementLineObj.txnsList.add(txnObjOne);
					}
				}
				else{
					/**
					* case of split adjustments
					*/
					if(!stmtStrcut.adjustmentTxnAndStatementLine.containsKey(txnObjOne.Related_To__r.Related_To__c)){
						stementLineObj = createNewStatementLine(txnObjOne);
						stementLineObj.statementLine.RelatedTo_For_Adjustment__c = txnObjOne.Related_To__r.Related_To__r.Name;
						statementToInsert.add(stementLineObj.statementLine);
						stmtStrcut.adjustmentTxnAndStatementLine.put(txnObjOne.Related_To__r.Related_To__c, stementLineObj);
					}
					else
					{
						stementLineObj = stmtStrcut.adjustmentTxnAndStatementLine.get(txnObjOne.Related_To__r.Related_To__c);
						stementLineObj.statementLine.Amount__c += txnObjOne.Amount__c;
						stementLineObj.statementLine.Total_Amount__c += txnObjOne.Amount__c;
						stementLineObj.txnsList.add(txnObjOne);
					}
					stementLineObj.statementLine.Type__c = 'Charge Split Dated - '+String.valueOf(txnObjOne.Related_To__r.Date__c).split(' ')[0]+' Adjustments';
				}
			}
			else 
			{
				/*
					for all child records splits
					check if the parent stmt line exist in stmtStrcut.mainTxnIdAndStatementLine then get it and include this child txn amount
					in it
				**/
				if(!stmtStrcut.mainTxnIdAndStatementLine.containsKey(txnObjOne.Related_To__c)){
					stementLineObj = createNewStatementLine(txnObjOne.Related_To__c, txnObjOne, mapOfIdAndTXN, stmtStrcut);
					statementToInsert.add(stementLineObj.statementLine);
				}
				else {
					// parent record id is already present in stmtStrcut.mainTxnIdAndStatementLine
					stementLineObj = stmtStrcut.mainTxnIdAndStatementLine.get(txnObjOne.Related_To__c);
					stementLineObj.txnsList.add(txnObjOne);
					updateTaxesSC(txnObjOne, stementLineObj);
				}
				stementLineObj.statementLine.Type__c = txnObjOne.Related_To__r.RecordType.Name+' Split Dated - '+String.valueOf(txnObjOne.Related_To__r.Date__c).split(' ')[0];
				stementLineObj.statementLine.Amount__c += txnObjOne.Amount__c;
				stementLineObj.statementLine.Total_Amount__c += txnObjOne.Amount__c;
			}
		}
		else{

			// if the txn is related to events then summarize all having a particular date in 1 stmt line
			if(!stmtStrcut.eventsMap.containsKey(txnObjOne.Reservation__c)){
				stementLineObj = createNewStatementLine(txnObjOne);
				stementLineObj.statementLine.Type__c = 'Event';
				stementLineObj.statementLine.Description__c = txnObjOne.Reservation__r.Name+' - '+String.valueOf(txnObjOne.Reservation__r.Event_Date__c).split(' ')[0];
				stementLineObj.eventDate = txnObjOne.Date__c;
				statementToInsert.add(stementLineObj.statementLine);
				stmtStrcut.eventsMap.put(txnObjOne.Reservation__c, new List<statementLinesTxnStruc>{stementLineObj});
			}
			else{
				for(statementLinesTxnStruc statementLineObjOne :stmtStrcut.eventsMap.get(txnObjOne.Reservation__c)){
					if(statementLineObjOne.eventDate==txnObjOne.Date__c){
						stementLineObj = statementLineObjOne;
					}
				}
				// check if stementLineObj got populated from the above for loop
				if(stementLineObj!=null){
					stementLineObj.statementLine.Amount__c += txnObjOne.Amount__c;
					stementLineObj.statementLine.Total_Amount__c += txnObjOne.Amount__c;
					stementLineObj.txnsList.add(txnObjOne);
					updateTaxesSC(txnObjOne, stementLineObj);
				}
				else{
					stementLineObj = createNewStatementLine(txnObjOne);
					stementLineObj.statementLine.Type__c = 'Event';
					stementLineObj.statementLine.Description__c = txnObjOne.Reservation__r.Name+' - '+String.valueOf(txnObjOne.Reservation__r.Event_Date__c).split(' ')[0];
					statementToInsert.add(stementLineObj.statementLine);
					stementLineObj.eventDate = txnObjOne.Date__c;
					stmtStrcut.eventsMap.get(txnObjOne.Reservation__c).add(stementLineObj);
				}
			}			
		}
		return statementToInsert;
	}

	/**
	* @Description : fill a map of all txns of previous dates
	*/
	public static Map<Id, TXN__C> getPreviousUnmapped(List<Statements__c> stmtSummList, Set<Id> memberIds, List<Id> taxesIds, Date fromDate){
		Map<Id, TXN__C> stmtMap = new Map<Id, TXN__C>();
		for(TXN__C txnRec : (List<TXN__C>)Data.read('Select Description__c, Related_To__r.RecordType.Name, Related_To__r.Date__c, Related_To__c, Related_To__r.Name, Related_To__r.Related_To__r.Date__c, Related_To__r.Related_To__c, Related_To__r.Related_To__r.Name, Date__c, Reservation__c,  Reservation__r.Name, Reservation__r.Event_Date__c, Statement_Description__c, Statement__c, Amount__c, RecordType.Name, Bill_To_Member__c, Customer__c, (Select Id, Date__c, Amount__c, Statement__c, RecordType.Name from Transactions2__r where RecordTypeId in : taxesRecs) from TXN__C where Bill_To_Member__c in :memberIds AND Date__c<:fromDate AND Statement__c=:stmtStatus AND RecordTypeId !=:depRecId AND RecordTypeId not in:taxesRecs order by Customer__c', 
			new Map<String, Object>{
			'memberIds' => memberIds,
			'fromDate' => fromDate,
			'depRecId' =>Utility.searchRecordType('Deposit','TXN__C'),
			'taxesRecs' => taxesIds,
			'stmtStatus' => null
		})){
			Boolean isSmmaryExist = false;
			for(Statements__c stmt :stmtSummList){
				if(txnRec.Date__c>=stmt.Date__c && txnRec.Date__c<=stmt.To_Date__c){
					isSmmaryExist = true;
				}
			}
			if(!isSmmaryExist){
				stmtMap.put(txnRec.id, txnRec);
			}
		}
		return stmtMap;
	}
}