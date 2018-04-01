/**
* @Description : trigger for Billing_Table__c object
* @group : Financial Management
*/
trigger MemberDuesTrigger on Member_Dues__c (before update) {

    fflib_SObjectDomain.triggerHandler(MemberDuesDomain.class);
}