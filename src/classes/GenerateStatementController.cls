/**
* @Description : controller class for generating statements
*/
public with sharing class GenerateStatementController {

	public Statements__c statementSummaryRec {get; set;}
	public String monthYear {get; set;}
	public Id batchId {get; set;}
	public Boolean confirmOnDup {get; set;}
	public Boolean callRegenerate {get; set;}
	public Boolean noTxnsFound {get; set;}
	public String status {get; set;}
	public Boolean afterStmtError {get; set;}
	private Set<Id> membersForGenerating;
	private Statements__c stmtSummIdToDeleteOrRegen;


	public GenerateStatementController() {
		afterStmtError = false;
		batchId = GenerateDuesController.getStatusOfBatch('GenerateStatementBatch');
		if(batchId==null){
			batchId = GenerateDuesController.getStatusOfBatch('UpdateStatementBatch');
		}
		noTxnsFound = false;
		confirmOnDup = false;
		callRegenerate = false;
		statementSummaryRec = new Statements__c(RecordtypeId=Utility.searchRecordType('Statement Summary','Statements__c'));		
	}

	public void generate()
	{
		confirmOnDup = false;
		callRegenerate = false;
		noTxnsFound = false;
		afterStmtError = false;

		if(monthYear==null || monthYear=='' || statementSummaryRec.Statement_Summary_Name__c==null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please fill in the mandatory fields.'));
			return;
		}
		if(status=='Confirm'){
			statementSummaryRec.Date__c = Date.newInstance(Integer.valueOf(monthYear.split(' ')[0]), Integer.valueOf(monthYear.split(' ')[1])+1, 1);
			List<Statements__c> stmtList = getStatement(statementSummaryRec.Date__c);
			if(stmtList.size()>0)
			{	
				List<Statements__c> stmtListRelated = getRelatedToStmt(stmtList[0].id);
				if(stmtListRelated.size()>0){
					callRegenerate = true;
				}
				else{
					confirmOnDup = true;
				}
				stmtSummIdToDeleteOrRegen = stmtList[0];
				return;
			}
		}
		if(!confirmOnDup && !callRegenerate){
			statementSummaryRec.Billing_Period__c = String.valueOf(DateTime.newInstance(statementSummaryRec.Date__c.Year(), statementSummaryRec.Date__c.Month(), statementSummaryRec.Date__c.Day()).format('MMMM'))+' '+statementSummaryRec.Date__c.Year();
			if(getpreviousStatementSumm(statementSummaryRec.Date__c)!=null){
				statementSummaryRec.Statement__c = getpreviousStatementSumm(statementSummaryRec.Date__c).id;
			}
			if(status=='Generate'){
				ApproveRejectStatements ap = new ApproveRejectStatements(new List<Statements__c> {stmtSummIdToDeleteOrRegen}, 'Reject');
				Database.executeBatch(ap);
			}
			if(status=='Generate' || status=='Confirm'){
				Integer numberOfDays = Date.daysInMonth(statementSummaryRec.Date__c.Year(), statementSummaryRec.Date__c.Month());
				Date lastDayOfMonth = Date.newInstance(statementSummaryRec.Date__c.Year(), statementSummaryRec.Date__c.Month(), numberOfDays);
				statementSummaryRec.To_Date__c = lastDayOfMonth;
				List<Statements__c> afterStmt = getAfterStatement(statementSummaryRec.To_Date__c);
				if(afterStmt.size()>0){
					afterStmtError = true;
					return;
				}
				GenerateStatementBatch genStatBatch = new GenerateStatementBatch(statementSummaryRec.Date__c, lastDayOfMonth, statementSummaryRec, getAllStatementSummarioes());
				batchId = Database.executeBatch(genStatBatch, 2);
			}
			if(status=='Update'){
				stmtSummIdToDeleteOrRegen.Statement_Summary_Name__c = statementSummaryRec.Statement_Summary_Name__c;
				updateStatements(stmtSummIdToDeleteOrRegen);
			}
		}
	}

	/**
	* @Description : get statement summary with the passed in date
	*/
	public List<Statements__c> getStatement(Date billingDate){
		return Data.read('Select Id, To_Date__c, Date__c from Statements__c where RecordtypeId=:recId AND Date__c=:billingDate',
											new Map<String, Object> {'recId' => Utility.searchRecordType('Statement Summary','Statements__c'),
																	 'billingDate' => billingDate	
											});
	}

	/**
	* @Description : get statement summary with the passed in date
	*/
	public List<Statements__c> getAfterStatement(Date billingDate){
		return Data.read('Select Id, To_Date__c, Date__c from Statements__c where RecordtypeId=:recId AND Date__c>=:billingDate',
											new Map<String, Object> {'recId' => Utility.searchRecordType('Statement Summary','Statements__c'),
																	 'billingDate' => billingDate	
											});
	}

	/**
	* @Description : get relatedStatements
	*/
	public static List<Statements__c> getRelatedToStmt(Id stmtSummId){
		return Data.read('Select id from Statements__c where RecordtypeId=:recId AND Statement__c=:stmtId', 
					new Map<String, Object> {'recId' => Utility.searchRecordType('Statement Summary','Statements__c'),
											 'stmtId' => stmtSummId	
					});
	}

	public void cancel()
	{
		confirmOnDup = false;
		callRegenerate = false;
		noTxnsFound = false;
		stmtSummIdToDeleteOrRegen = null;
		status = '';
	}

	/**
	* @Description : get previous summary record
	*/
	public Statements__c getpreviousStatementSumm(Date billingDate)
	{
		List<Statements__c> statementsList;
		if(stmtSummIdToDeleteOrRegen==null){
			statementsList = Data.read('Select Id from Statements__c where RecordtypeId=:recId AND Date__c<:billingDate order by Date__c DESC',
												new Map<String, Object> {'recId' => Utility.searchRecordType('Statement Summary','Statements__c'),
																		 'billingDate' => billingDate	
												});
		}
		else{
			statementsList = Data.read('Select Id from Statements__c where RecordtypeId=:recId AND Date__c<:billingDate AND Id!=: summToDelId order by Date__c DESC',
												new Map<String, Object> {'recId' => Utility.searchRecordType('Statement Summary','Statements__c'),
																		 'billingDate' => billingDate,
																		 'summToDelId' => stmtSummIdToDeleteOrRegen.id	
												});
		}
		if(statementsList.size()>0){
			return statementsList[0];
		}
		return null;
	}

	/**
	* @Description : get all the statement summaries
	*/
	public List<Statements__c> getAllStatementSummarioes(){
		return Data.read('Select Id, Date__c, To_Date__c from Statements__c where RecordTypeId=:recId', 
			new Map<String, Object>{'recId' => Utility.searchRecordType('Statement Summary','Statements__c')});
	}

	public void updateStatements(Statements__c stmtIdToRegen){
		Set<Id> membersIds = new Set<Id>();
		Map<Id, Statements__c> mapOfStmtSumm = new Map<Id, Statements__c> ((List<Statements__c>) Data.read('Select id, Statement__c, Billing_Period__c, Date__c, To_Date__c from Statements__c where RecordtypeId=:recId AND Date__C>=:fromDate',
									new Map<String, Object> {'recId' => Utility.searchRecordType('Statement Summary','Statements__c'),
															 'fromDate' => stmtIdToRegen.Date__c 
								}
			));

		for(AggregateResult ar : (List<AggregateResult>) Data.read('Select count(Id) c, Bill_To_Member__c  from TXN__C where Date__c>=:fromDate AND Date__c<=:toDate AND Statement__c=:stmtId AND RecordTypeId not in:recId group by Bill_To_Member__c',
			new Map<String, Object> {'fromDate' => stmtIdToRegen.Date__c,
									 'toDate' => stmtIdToRegen.To_Date__c,
									 'stmtId' => null,
									 'recId' => new List<String> {Utility.searchRecordType('Deposit', 'TXN__C'), Utility.searchRecordType('Taxes', 'TXN__C'), Utility.searchRecordType('Service Charges', 'TXN__C')}
			}))
		{
			if(Integer.valueOf(ar.get('c'))>0){
				if(ar.get('Bill_To_Member__c')!=null && String.valueOf(ar.get('Bill_To_Member__c'))!=''){
					membersIds.add(String.valueOf(ar.get('Bill_To_Member__c')));
				}
			}
		}
		if(membersIds.size()>0){
			UpdateStatementsBatch ups = new UpdateStatementsBatch(stmtIdToRegen, membersIds, mapOfStmtSumm, null, null);
			batchId = Database.executeBatch(ups, 1);
		}
		else{
			noTxnsFound = true;
			Data.modify(stmtIdToRegen);
		}
	}
}