public class UpdateStatementsBatch implements Database.Batchable<sObject> {
	
	@TestVisible
	private Statements__c stmtSummaryTo;
	@TestVisible
	private Set<Id> memIds;
	@TestVisible
	private Map<Id, Statements__c> memStmtMap;
	@TestVisible
	private List<Statements__c> memStatements;
	@TestVisible
	private List<Statements__c> allStatementSummaries;
	@TestVisible
	private Statements__c latestSumm;

	public UpdateStatementsBatch(Statements__c stmtSummaryTo, Set<Id> memIds, Map<Id, Statements__c> memStmtMap, List<Statements__c> allStatementSummaries, Statements__c latestSumm) {
		this.stmtSummaryTo = stmtSummaryTo;
		if(this.stmtSummaryTo!=null && this.stmtSummaryTo.id!=null){
			Data.modify(this.stmtSummaryTo);
		}
		this.memIds = memIds;
		this.memStmtMap = memStmtMap;
		memStatements = new List<Statements__c>();
		this.allStatementSummaries = allStatementSummaries;
		this.latestSumm = latestSumm;
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Data.locator('Select id, Name from Contact where Id in : memIds', new Map<String, Object> {'memIds' => memIds});
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		
		List<TXN__c> allTxns;

		//map contains summary from date and all new txns having date in that summary
		Map<Date, List<TXN__c>> txnsWithCorrSummDate = new Map<Date, List<TXN__c>>();

		// date list so the order is preserved - specially in case of summary to update is not defined
		List<Date> dateList = new List<Date>();

		// from date and corresponding stmt summary id
		Map<Date, Id> stmtSummWithFromDate = new Map<Date, Id>();

		// map contains id of stmt summary and member statement record
		Map<Id, Statements__c> memStmtAndSummMap = new Map<Id, Statements__c>();

		// map contains id of memberStatement and list of all stmtLines
		Map<Id, List<Statements__c>> memstmtIdAndStmtLines = new Map<Id, List<Statements__c>>();

		// map contains id of memberStatement and list of all stmtLines
		Map<Id, GenerateStatementBatch.statementStructure> stmtIdAndStructure = new Map<Id, GenerateStatementBatch.statementStructure>();

		List<Statements__c> stmtListToUpdate = new List<Statements__c>();

		List<TXN__c> txnsa = new List<TXN__c>();
		

		// query all txn record for which the statements not yet generated if starting summary not defined
		List<Id> taxAndServChargeIds = new List<Id> {Utility.searchRecordType('Taxes','TXN__c'), Utility.searchRecordType('Service Charges','TXN__c')};
		String txnQuery = 'Select Id, Amount__C, Related_To__c, Date__c, Statement__c, Related_To__r.RecordType.Name, Related_To__r.Related_To__r.Date__c, Related_To__r.Date__c, Related_To__r.Name, Related_To__r.Related_To__c, Related_To__r.Related_To__r.Name, Reservation__c, Reservation__r.Name, Reservation__r.Event_Date__c, Statement_Description__c, RecordType.Name, Bill_To_Member__c, Customer__c, (Select Id, Amount__c, RecordType.Name from Transactions2__r where RecordTypeId in : taxAndServChargeIds) from TXN__c where RecordTypeId!=:recId AND  RecordTypeId Not in :taxAndServChargeIds ';
		if(stmtSummaryTo==null){
			txnQuery += 'AND Statement__c= :stmtId AND Bill_To_Member__c =:memId AND Date__c!=:dte order by Date__c DESC'; 
			allTxns = Data.read(txnQuery, new Map<String, Object> {'stmtId' => null, 
																   'memId' => scope[0].id, 
																   'recId' => Utility.searchRecordType('Deposit', 'TXN__c'),
																   'dte' => null,
																   'taxAndServChargeIds' => taxAndServChargeIds
																   });
		}
		else{

			// query all txn record for which the statements not yet generated if summary to update is defined
			txnQuery += 'AND Statement__c= :stmtId AND Bill_To_Member__c =:memId AND Date__c>=:fromDate AND Date__c<=:toDate';
			allTxns = Data.read(txnQuery, new Map<String, Object> {'stmtId' => null ,
																   'memId' => scope[0].id, 
																   'fromDate' => stmtSummaryTo.Date__c, 
																   'toDate' => stmtSummaryTo.To_Date__c, 
																   'recId' => Utility.searchRecordType('Deposit', 'TXN__c'),
																   'taxAndServChargeIds' => taxAndServChargeIds
																   });
		}

		if(allStatementSummaries!=null && latestSumm!=null){
			Map<Id, TXN__c> extraTxns = GenerateStatementBatch.getPreviousUnmapped(allStatementSummaries, new Set<Id> {scope[0].id}, taxAndServChargeIds, latestSumm.Date__c);
			
			if(extraTxns.values().size()>0){
				txnsWithCorrSummDate.put(latestSumm.Date__c, extraTxns.values());
				dateList.add(latestSumm.Date__c);
				stmtSummWithFromDate.put(latestSumm.Date__c, latestSumm.id);
			}
		}

		// loop over all txns of this member
		for(TXN__c txnObj : allTxns){
			for(Statements__c stmts :memStmtMap.values()){
				if(txnObj.Date__c>= stmts.Date__c && txnObj.Date__c<=stmts.To_Date__c){
					if(!txnsWithCorrSummDate.containsKey(stmts.Date__c)){
						txnsWithCorrSummDate.put(stmts.Date__c, new List<TXN__c>());
						dateList.add(stmts.Date__c);
						stmtSummWithFromDate.put(stmts.Date__c, stmts.id);
					}
					txnsWithCorrSummDate.get(stmts.Date__c).add(txnObj);
				}
			}
		}

		// collect all member statements with the stmt summ id and fill memStmtAndSummMap
		for(Statements__c stmtsMem  :(List<Statements__c>) Data.read('Select id, Statement_Balance__c, Statement__c, (Select id, Type__c, Date__c, RelatedTo_For_Adjustment__c, Amount__C, Statement__c, Tax__c, Total_Amount__c, Service_Charge__c from Statements__r) from Statements__c where RecordTypeId=:recId AND Statement__c in :stmtIds AND Member__c = :memId', new Map<String, Object> {'recId' => Utility.searchRecordType('Member Statement' , 'Statements__c'),
				'stmtIds' => memStmtMap.keySet(),
				'memId' => scope[0].id
			}))
		{
			memStmtAndSummMap.put(stmtsMem.Statement__c, stmtsMem);
			if(stmtsMem.Statements__r.size()>0){
				for(Statements__c stmtLine :stmtsMem.Statements__r){
					if(!memstmtIdAndStmtLines.containsKey(stmtLine.Statement__c)){
						memstmtIdAndStmtLines.put(stmtLine.Statement__c, new List<Statements__c>());
					}
					memstmtIdAndStmtLines.get(stmtLine.Statement__c).add(stmtLine);
				}
			}
		}

		// loop through all summaries needs to update in ASC order
		for(Date summFromDate :dateList){
			
			// Map of all related stmt summaried
			Map<Id, Id> RelatedToSumm = new Map<Id, Id>();
			Id stmtSummId = stmtSummWithFromDate.get(summFromDate);
			GenerateStatementBatch.statementStructure stmtStructure;
			if(stmtIdAndStructure.containsKey(stmtSummId)){
				stmtStructure = stmtIdAndStructure.get(stmtSummId);
			}
			if(stmtStructure==null){
				stmtStructure = new GenerateStatementBatch.statementStructure();
				stmtStructure.memStatement = searchMemberStatements(stmtSummWithFromDate.get(summFromDate), memStmtAndSummMap);
				if(stmtStructure.memStatement!=null){
					stmtListToUpdate.add(stmtStructure.memStatement);
				}
			} 
			if(stmtStructure.memStatement==null){
				Statements__c memStmt = new Statements__c(RecordTypeId=Utility.searchRecordType('Member Statement','Statements__c'), Statement__c=stmtSummWithFromDate.get(summFromDate));
				memStmt.Billing_Period__c = memStmtMap.get(stmtSummWithFromDate.get(summFromDate)).Billing_Period__c;
				memStmt.Member__c = scope[0].id;
	   			memStmt.Statement_Balance__c = 0;
	   			stmtStructure.memStatement = memStmt;
	   			stmtListToUpdate.add(stmtStructure.memStatement);
			}

			// updated map of relation will appear in RelatedToSumm		
			updateNextStatementMap(stmtSummWithFromDate.get(summFromDate), RelatedToSumm);

			// loop over all txns in the coming statement summary period
			for(TXN__c txnObj :txnsWithCorrSummDate.get(summFromDate))
			{
				GenerateStatementBatch.statementLinesTxnStruc statementLineObj;
				if(txnObj.Reservation__c!=null)
				{
					// search in eventsMap
					boolean found = false;
					if(stmtStructure.eventsMap.containsKey(txnObj.Reservation__c)){
						for(GenerateStatementBatch.statementLinesTxnStruc statementLineObjOne : stmtStructure.eventsMap.get(txnObj.Reservation__c)){
							if(statementLineObjOne.eventDate==txnObj.Date__c){
								statementLineObj = statementLineObjOne;
								statementLineObj.statementLine.Amount__c += txnObj.Amount__c;
								statementLineObj.statementLine.Total_Amount__c += txnObj.Amount__c;
								stmtStructure.memStatement.Statement_Balance__c += txnObj.Amount__c;
								statementLineObj.txnsList.add(txnObj);
								GenerateStatementBatch.updateTaxesSC(txnObj, statementLineObj, stmtStructure);
								found = true;
							}
						}
					}
					if(!found){
						Statements__c stmtLineObj = searchForEventStatementLine(stmtStructure.memStatement, memstmtIdAndStmtLines, txnObj);
						if(stmtLineObj!=null){
							statementLineObj = new GenerateStatementBatch.statementLinesTxnStruc(stmtLineObj);
							statementLineObj.eventDate = txnObj.Date__C;
							statementLineObj.statementLine.Amount__c += txnObj.Amount__c;
							statementLineObj.statementLine.Total_Amount__c += txnObj.Amount__c;
							statementLineObj.txnsList.add(txnObj);
							GenerateStatementBatch.updateTaxesSC(txnObj, statementLineObj, stmtStructure);
							stmtStructure.memStatement.Statement_Balance__c += txnObj.Amount__c;
						}
						else{
							statementLineObj = GenerateStatementBatch.createNewStatementLine(txnObj);
							statementLineObj.eventDate = txnObj.Date__C;
							stmtStructure.memStatement.Statement_Balance__c += statementLineObj.statementLine.Total_Amount__c;
						}
						stmtStructure.eventsMap.put(txnObj.Reservation__c, new List<GenerateStatementBatch.statementLinesTxnStruc> {statementLineObj});
						stmtListToUpdate.add(statementLineObj.statementLine);
					}
					statementLineObj.statementLine.Type__c = 'Event';
					statementLineObj.statementLine.Description__c = txnObj.Reservation__r.Name+' - '+String.valueOf(txnObj.Reservation__r.Event_Date__c).split(' ')[0];
				}
				else if(txnObj.Related_To__c==null){
					statementLineObj = GenerateStatementBatch.createNewStatementLine(txnObj);
					stmtStructure.memStatement.Statement_Balance__c += statementLineObj.statementLine.Total_Amount__c;
					stmtStructure.mainTxnIdAndStatementLine.put(txnObj.id, statementLineObj);
					stmtListToUpdate.add(statementLineObj.statementLine);
				}
				else if(txnObj.RecordType.Name=='Adjustment' || txnObj.RecordType.Name=='Refund'){
					Id parentId;
					String parentName;
					Boolean splits = false;
					if(txnObj.Related_To__r.Related_To__c!=null){
						parentId = txnObj.Related_To__r.Related_To__c;
						parentName = txnObj.Related_To__r.Related_To__r.Name;
						splits = true;
					}
					else{
						parentId = txnObj.Related_To__c;
						parentName = txnObj.Related_To__r.Name;
					}
					if(!stmtStructure.adjustmentTxnAndStatementLine.containsKey(parentId)){
						Statements__c stmtLineObj = searchForRefundOrAdjustmentStatementLine(stmtStructure.memStatement, memstmtIdAndStmtLines, parentName);
						if(stmtLineObj!=null){
							statementLineObj = new GenerateStatementBatch.statementLinesTxnStruc(stmtLineObj);
							statementLineObj.statementLine.Amount__c += txnObj.Amount__c;
							statementLineObj.statementLine.Total_Amount__c += txnObj.Amount__c;
							statementLineObj.txnsList.add(txnObj);
							stmtStructure.memStatement.Statement_Balance__c += txnObj.Amount__c;
						}
						else{
							statementLineObj = GenerateStatementBatch.createNewStatementLine(txnObj);
							stmtStructure.memStatement.Statement_Balance__c += statementLineObj.statementLine.Total_Amount__c;
						}
						stmtListToUpdate.add(statementLineObj.statementLine);
						stmtStructure.adjustmentTxnAndStatementLine.put(parentId, statementLineObj);
					}
					else{
						statementLineObj = stmtStructure.adjustmentTxnAndStatementLine.get(parentId);
						statementLineObj.statementLine.Amount__c += txnObj.Amount__c;
						statementLineObj.statementLine.Total_Amount__c += txnObj.Amount__c;
						statementLineObj.txnsList.add(txnObj);
						stmtStructure.memStatement.Statement_Balance__c += txnObj.Amount__c;
					}
					if(splits){
						statementLineObj.statementLine.Type__c = 'Charge Split Dated - '+String.valueOf(txnObj.Related_To__r.Related_To__r.Date__c).split(' ')[0]+' Adjustments';
					}
					statementLineObj.statementLine.RelatedTo_For_Adjustment__c = parentName;
				}
				else{
					/*
						for all child records splits
						check if the parent stmt line exist in stmtStrcut.mainTxnIdAndStatementLine then get it and include this child txn amount
						in it
					**/
					if(!stmtStructure.mainTxnIdAndStatementLine.containsKey(txnObj.Related_To__c)){
						statementLineObj = GenerateStatementBatch.createNewStatementLine(txnObj.Related_To__c, txnObj, new Map<Id, TXN__c>(txnsWithCorrSummDate.get(summFromDate)), stmtStructure);
						stmtStructure.memStatement.Statement_Balance__c += statementLineObj.statementLine.Total_Amount__c;
						stmtListToUpdate.add(statementLineObj.statementLine);
					}
					else {
						// parent record id is already present in stmtStrcut.mainTxnIdAndStatementLine
						statementLineObj = stmtStructure.mainTxnIdAndStatementLine.get(txnObj.Related_To__c);
						statementLineObj.statementLine.Amount__c += txnObj.Amount__c;
						statementLineObj.statementLine.Total_Amount__c += txnObj.Amount__c;
						stmtStructure.memStatement.Statement_Balance__c += txnObj.Amount__c;
						statementLineObj.txnsList.add(txnObj);
						GenerateStatementBatch.updateTaxesSC(txnObj, statementLineObj, stmtStructure);
					}
					statementLineObj.statementLine.Type__c = txnObj.Related_To__r.RecordType.Name+' Split Dated - '+String.valueOf(txnObj.Related_To__r.Date__c).split(' ')[0];
				}
			}
			stmtIdAndStructure.put(stmtSummWithFromDate.get(summFromDate), stmtStructure);
			if(RelatedToSumm.containsKey(stmtSummWithFromDate.get(summFromDate))){
				Updatestructures(stmtSummWithFromDate.get(summFromDate), RelatedToSumm, stmtIdAndStructure, scope[0].id, memStmtAndSummMap, memstmtIdAndStmtLines, stmtListToUpdate);
			}
		}

		if(stmtListToUpdate.size()>0){
			Data.upsurt(stmtListToUpdate,Statements__c.Id.getDescribe().getSObjectField(), new Set<String> {''});
		}

		stmtListToUpdate = new List<Statements__c>();

		for(GenerateStatementBatch.statementStructure stmtStructueObj : stmtIdAndStructure.values()){
   			if(stmtStructueObj.eventsMap.values().size()>0){
	   			for(List<GenerateStatementBatch.statementLinesTxnStruc> stmtList :stmtStructueObj.eventsMap.values())
	   			{
	   				for(GenerateStatementBatch.statementLinesTxnStruc stmtObj :stmtList){
	   					stmtObj.statementLine.Statement__c = stmtStructueObj.memStatement.id;
	   					stmtListToUpdate.add(stmtObj.statementLine);
		   				for(TXN__c txns :stmtObj.txnsList){
		   					txns.Statement__c = stmtObj.statementLine.id;
		   					txnsa.add(txns);
		   				}
	   				}
	   			}
   			}
   			if(stmtStructueObj.mainTxnIdAndStatementLine.values().size()>0){
				for(GenerateStatementBatch.statementLinesTxnStruc stmtList :stmtStructueObj.mainTxnIdAndStatementLine.values())
	   			{
	   				stmtList.statementLine.Statement__c = stmtStructueObj.memStatement.id;
	   				stmtListToUpdate.add(stmtList.statementLine);
		   			for(TXN__c txns :stmtList.txnsList){
		   				txns.Statement__c = stmtList.statementLine.id;
		   				txnsa.add(txns);
		   			}
	   			}
   			}
   			if(stmtStructueObj.adjustmentTxnAndStatementLine.values().size()>0){
				for(GenerateStatementBatch.statementLinesTxnStruc stmtList :stmtStructueObj.adjustmentTxnAndStatementLine.values())
	   			{
	   				stmtList.statementLine.Statement__c = stmtStructueObj.memStatement.id;
	   				stmtListToUpdate.add(stmtList.statementLine);
		   			for(TXN__c txns :stmtList.txnsList){
		   				txns.Statement__c = stmtList.statementLine.id;
		   				txnsa.add(txns);
		   			}
	   			}
   			}
   			if(stmtStructueObj.carryForwardStatementLine!=null){
   				stmtStructueObj.carryForwardStatementLine.Statement__c = stmtStructueObj.memStatement.id;
   				stmtListToUpdate.add(stmtStructueObj.carryForwardStatementLine);
   			}
		}
		Data.modify(txnsa);
		Data.modify(stmtListToUpdate);
	}
	
	public void finish(Database.BatchableContext BC) {

		AsyncApexJob a = (AsyncApexJob) Data.read('Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email, ExtendedStatus from AsyncApexJob where Id = :jobId', new Map<String, Object> {'jobId' => BC.getJobId()}).get(0); 
		if(a.TotalJobItems != 0 && a.NumberOfErrors>0 && a.ExtendedStatus!=null)
		{
			List<User> users = Data.read('select ProfileId, Email from User where Profile.Name = :profileName', new Map<String, Object>{'profileName' =>'System Administrator'});
			// Send an email to the Apex job's submitter notifying of job completion.                                          
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();         
			String[] toAddresses = new String[users.size()];
			for(Integer i=0; i<users.size();i++){
			 toAddresses[i] = users[i].Email;       
			}
			mail.setToAddresses(toAddresses);
			mail.setSubject('Update Statements Batch ' + a.Status);
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors 
					+' failures. \n'+a.ExtendedStatus); 
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}

	/**
	* @Description : a recursive method which will update nextStatementSummaryMap
	*/
	private void updateNextStatementMap(Id stmtId, Map<Id, Id> nextStatementSummaryMap)
	{
		for(Statements__c stmt :memStmtMap.values()){
			if(stmtId == stmt.Statement__c){
				nextStatementSummaryMap.put(stmtId, stmt.id);
				updateNextStatementMap(stmt.id, nextStatementSummaryMap);
			}
		}
	}

	/**
	* @Description : search in statement lines
	*/
	private Statements__c searchForEventStatementLine(Statements__c memStmt, Map<Id, List<Statements__c>> memstmtIdAndStmtLines, TXN__c txnObj){
		Statements__c stmtLine;
		if(memStmt.id!=null && memstmtIdAndStmtLines.containsKey(memStmt.id)){
			for(Statements__c stmt : memstmtIdAndStmtLines.get(memStmt.id)){
				if(stmt.Type__c=='Event' && txnObj.Date__c==stmt.Date__c){
					stmtLine = stmt;
					break;
				}
			}
		}
		return stmtLine;
	}

	/**
	* @Description : search for statement lines if already created for the adjustment
	*/
	private Statements__c searchForRefundOrAdjustmentStatementLine(Statements__c memStmt, Map<Id, List<Statements__c>> memstmtIdAndStmtLines, String parentName){
		Statements__c stmtLine;
		if(memStmt.id!=null && memstmtIdAndStmtLines.containsKey(memStmt.id)){
			for(Statements__c stmt : memstmtIdAndStmtLines.get(memStmt.id)){
				if(stmt.RelatedTo_For_Adjustment__c==parentName){
					stmtLine = stmt;
					break;
				}
			}
		}
		return stmtLine;
	}

	/**
	* @Description : search for member statements in structure or in member statements map
	*/
	private Statements__C searchMemberStatements(Id stmtSummId, Map<Id, Statements__c> mapOfMemStmt){
		Statements__c memStmt;
		if(mapOfMemStmt.containsKey(stmtSummId)){
			memStmt = mapOfMemStmt.get(stmtSummId);
		}
		return memStmt;
	}

	/**
	* @Description : search for carry forward statement line
	*/
	private Statements__c searchCarryForwardStmtLine(Id memberStatementId, Map<Id, List<Statements__c>> mapOfStatementLines)
	{
		Statements__c carryFStmt;
		if(mapOfStatementLines.containsKey(memberStatementId)){
			for(Statements__c stmt :mapOfStatementLines.get(memberStatementId)){
				if(stmt.Type__c=='Carry Forward'){
					carryFStmt = stmt;
				}
			}
		}
		System.debug('carryFStmt'+carryFStmt);
		return carryFStmt;
	}

	/**
	* @Description : updates all future statement summaries
	*/
	private void Updatestructures(Id stmtId, Map<Id, Id> relatedToMap, Map<Id, GenerateStatementBatch.statementStructure> structMap, Id memId, Map<Id, Statements__c> mapOfMemStmt, Map<Id, List<Statements__c>> mapOfstmtLines, List<Statements__c> stmtToUpdate){
		GenerateStatementBatch.statementStructure strucToUpdateFrom = structMap.get(stmtId); 
		GenerateStatementBatch.statementStructure structUpdateTo;
		Id stmtSummUpdateTo = relatedToMap.get(stmtId);
		if(structMap.containsKey(stmtSummUpdateTo)){
			structUpdateTo = structMap.get(stmtSummUpdateTo);
			if(structUpdateTo.carryForwardStatementLine==null){
				if(structUpdateTo.memStatement.id!=null){
					structUpdateTo.carryForwardStatementLine = searchCarryForwardStmtLine(structUpdateTo.memStatement.id, mapOfstmtLines);
					// if carryfoward stmt line doesn't exist i.e its new member
					if(structUpdateTo.carryForwardStatementLine==null){
						structUpdateTo.carryForwardStatementLine = createCarryForward(strucToUpdateFrom, memId, stmtSummUpdateTo);
						stmtToUpdate.add(structUpdateTo.carryForwardStatementLine);
					}
					else{
						structUpdateTo.memStatement.Statement_Balance__c -= structUpdateTo.carryForwardStatementLine.Amount__c;
						structUpdateTo.carryForwardStatementLine.Amount__c = strucToUpdateFrom.memStatement.Statement_Balance__c;
					}
				}
				else{
   					structUpdateTo.carryForwardStatementLine = createCarryForward(strucToUpdateFrom, memId, stmtSummUpdateTo);
   					stmtToUpdate.add(structUpdateTo.carryForwardStatementLine);
   				}
			}
			else{
				structUpdateTo.memStatement.Statement_Balance__c -= structUpdateTo.carryForwardStatementLine.Amount__c;
				structUpdateTo.carryForwardStatementLine.Amount__c = strucToUpdateFrom.memStatement.Statement_Balance__c;
			}
		}
		else{
			structUpdateTo = new GenerateStatementBatch.statementStructure();
			structUpdateTo.memStatement = searchMemberStatements(stmtSummUpdateTo, mapOfMemStmt);
			if(structUpdateTo.memStatement==null){
				Statements__c memStmt = new Statements__c(RecordTypeId=Utility.searchRecordType('Member Statement','Statements__c'), Statement__c=stmtSummUpdateTo);
				memStmt.Billing_Period__c = memStmtMap.get(stmtSummUpdateTo).Billing_Period__c;
				memStmt.Member__c = memId;
	   			memStmt.Statement_Balance__c = 0;
	   			structUpdateTo.memStatement = memStmt;
	   			structUpdateTo.carryForwardStatementLine = createCarryForward(strucToUpdateFrom, memId, stmtSummUpdateTo);
			}
			else{
				structUpdateTo.carryForwardStatementLine = searchCarryForwardStmtLine(structUpdateTo.memStatement.id, mapOfstmtLines);
				if(structUpdateTo.carryForwardStatementLine==null){
					structUpdateTo.carryForwardStatementLine = createCarryForward(strucToUpdateFrom, memId, stmtSummUpdateTo);
				}
				else{
					structUpdateTo.memStatement.Statement_Balance__c -= structUpdateTo.carryForwardStatementLine.Amount__c;
					structUpdateTo.carryForwardStatementLine.Amount__c = strucToUpdateFrom.memStatement.Statement_Balance__c;
				}
			}
			stmtToUpdate.add(structUpdateTo.memStatement);
			stmtToUpdate.add(structUpdateTo.carryForwardStatementLine);
			structMap.put(stmtSummUpdateTo, structUpdateTo);
		}

		structUpdateTo.carryForwardStatementLine.Total_Amount__c = structUpdateTo.carryForwardStatementLine.Amount__c;
		structUpdateTo.memStatement.Statement_Balance__c += structUpdateTo.carryForwardStatementLine.Total_Amount__c;
		if(relatedToMap.containsKey(stmtSummUpdateTo)){
			Updatestructures(stmtSummUpdateTo, relatedToMap, structMap, memId, mapOfMemStmt, mapOfstmtLines, stmtToUpdate);
		}
	}

	private Statements__c createCarryForward(GenerateStatementBatch.statementStructure strucToUpdateFrom, Id memId, Id stmtSummId){
		Statements__c carryFStmt = new Statements__c(RecordTypeId=Utility.searchRecordType('Statement Line','Statements__c'));
   		carryFStmt.Description__c = 'Carry Forward Balance';
   		carryFStmt.Date__c = memStmtMap.get(stmtSummId).Date__c;
   		carryFStmt.Amount__c = strucToUpdateFrom.memStatement.Statement_Balance__c;
   		carryFStmt.Type__c = 'Carry Forward';
   		carryFStmt.Bill_To_Member__c = memId;
   		carryFStmt.Customer__c = memId;
   		return carryFStmt;
	}
}