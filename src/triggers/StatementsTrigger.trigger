trigger StatementsTrigger on Statements__c (before insert, before update) {

	fflib_SObjectDomain.triggerHandler(StatementsDomain.Class);
	
}