/**
* @Author  kiran@3embed.com
* @Date   12th may, 2017
* @Description check vendor invoice lines total amount should be equal to or less then the total invoice amount.
*/

trigger vendorInvoiceLineTrigger on Vendor_Invoice_Line__c (before insert,before update) {
	fflib_SObjectDomain.triggerHandler(vendorInvoiceLineTrigger_domain.class);
}