/**
* @author joshi Prakash
* @date 07-07-2017
* @group Financial Management
* @description Update the credit and debit total on financial account whenever the financial journal line is updated deleted or inserted.
 **/
trigger FinancialJournalLine on Financial_Journal_Line__c (after delete, after insert, after update) {
	
	if (Trigger.isInsert) {
		FinancialJournalLineTriggerHandler.AfterInsertUpdateDelete(Trigger.new);			
	}

	if (Trigger.isUpdate || Trigger.isDelete) {
		FinancialJournalLineTriggerHandler.AfterInsertUpdateDelete(Trigger.old);		
	}
}
