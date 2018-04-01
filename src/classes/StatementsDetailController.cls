public with sharing class StatementsDetailController {

	public Boolean isStmtSummRelated {get; set;}
	public Boolean isMemStmt {get; set;}
	public Boolean isEdit {get; set;}
	public Boolean isNew {get; set;}
	public String returnPage {get; set;}
	public Id batchId {get; set;}
	private Statements__c stmt;

	public StatementsDetailController(ApexPages.StandardController std) {
		isStmtSummRelated = false;
		isEdit = false;
		isNew = false;
		isMemStmt = false;
		stmt = (Statements__c)std.getRecord();
	}

	public void initializeActivity(){
		if(ApexPages.currentPage().getParameters().get('delId')!=null){
			stmt = (Statements__c) Data.read('Select RecordType.Name from Statements__c where Id=:summId', new Map<String, Object> {'summId' => stmt.id})[0];
			if(stmt.RecordType.Name == 'Statement Summary'){
				List<Statements__c> stmtListRelated = GenerateStatementController.getRelatedToStmt(stmt.id);
				if(stmtListRelated.size()>0){
					isStmtSummRelated = true;
				}
				else{
					batchId = GenerateDuesController.getStatusOfBatch('ApproveRejectStatements');
					if(batchId==null){
						ApproveRejectStatements apprvReject = new ApproveRejectStatements(new List<Statements__c> {stmt}, 'Reject');
						batchId = Database.executeBatch(apprvReject, 9000);
					}
				}
				returnPage = Statements__c.SObjectType.getDescribe().getKeyPrefix()+'/o';
			}
			else if(stmt.RecordType.Name == 'Member Statement'){
				isMemStmt = true;
				returnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL')).getURL();
			}
		}
		else if(ApexPages.currentPage().getParameters().get('Id')!=null){
			isEdit = true;
			returnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL')).getURL();
		}
		else{
			isNew = true;
			returnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL')).getURL();
		}
	}
}