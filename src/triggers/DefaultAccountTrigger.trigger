/**
* @Description : trigger for Default_Account__c not to allow duplicate default type name
*/
trigger DefaultAccountTrigger on Default_Account__c (before insert, before update) {
	
	fflib_SObjectDomain.triggerHandler(DefaultAccountDomain.Class);
}