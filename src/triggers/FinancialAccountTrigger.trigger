trigger FinancialAccountTrigger on Financial_Account__c (before insert,before update,before delete) 
{
     fflib_SObjectDomain.triggerHandler(cmsft_FinancialAccountDomain.class);
}