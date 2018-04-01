/**
* @Author  kiran@3embed.com
* @Date   12th may, 2017
* @Description check vendor invoice is already uploaded or not in system with invoice number
*/

trigger vendorInvoiceTriggers on Vendor_Invoice__c (before insert, before update) {
    //call domain layer for this trigger
	fflib_SObjectDomain.triggerHandler(vendorInvoiceTrigger_domain.class);
}