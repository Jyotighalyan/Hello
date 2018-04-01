public class ApproveRejectStatements implements Database.Batchable<sObject> {
	
	@TestVisible
	private List<Statements__c> stmtSumm;

	@TestVisible
	private List<Id> stmtSummIds;

	@TestVisible
	private String approveOrReject;

	public ApproveRejectStatements(List<Statements__c> stmtSumm, String approveOrReject) {
		this.stmtSumm = stmtSumm;
		stmtSummIds = new List<Id>();
		for(Statements__c stmt : this.stmtSumm){
			stmtSummIds.add(stmt.id);
		}
		this.approveOrReject = approveOrReject;
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		if(approveOrReject=='Approve'){
			for(Statements__c stmt :stmtSumm){
				stmt.Approved__c = true;
			}
			Data.modify(stmtSumm);
		}
		return Data.locator('Select id from Statements__c where RecordTypeId=:recId AND Statement__c in :stmtId order by Member__r.Name ASC', new Map<String, Object> {
			'recId' => Utility.searchRecordType('Member Statement','Statements__c'),
			'stmtId' => stmtSummIds
			});
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Statements__c> stmtsToBeUpdated = new List<Statements__c> ();
		Set<Id> memStatIds = new Set<Id>();
		for(Statements__c stmt :(List<Statements__c>)scope)
		{
			if(approveOrReject=='Approve'){
				stmt.Approved__c = true;
			}
			stmtsToBeUpdated.add(stmt);
			memStatIds.add(stmt.id);
		}
		if(approveOrReject=='Reject'){
			List<Statements__c> stmtLines = Data.read('Select Id from Statements__c Where RecordTypeId=:recId AND Statement__c in :stmtIds', new Map<String, Object> {
				'recId' => Utility.searchRecordType('Statement Line','Statements__c'),
				'stmtIds' => memStatIds
				});
			stmtsToBeUpdated.addAll(stmtLines);
			Data.remove(stmtsToBeUpdated);
		}
		if(approveOrReject=='Approve'){
			Data.modify(stmtsToBeUpdated);
		}
	}
	
	public void finish(Database.BatchableContext BC) {
		if(approveOrReject=='Reject'){
			Data.remove(stmtSumm);
		}
		else{
			AsyncApexJob a = (AsyncApexJob) Data.read('Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email, ExtendedStatus from AsyncApexJob where Id = :jobId', new Map<String, Object> {'jobId' => BC.getJobId()}).get(0); 

			if(a.TotalJobItems != 0)
			{
				// Send an email to the Apex job's submitter notifying of job completion.                                          
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();         
				String[] toAddresses = new String[] {a.CreatedBy.Email};         
				mail.setToAddresses(toAddresses);
				mail.setSubject('Approve Statements Batch ' + a.Status);
				mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors 
						+' failures. \n'+a.ExtendedStatus); 
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}
		}
	}
}