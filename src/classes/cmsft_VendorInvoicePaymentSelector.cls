/**
 * @Description : Class encapsulates query logic for Vendor_Invoice_Payment__c
 * @Date : 6th June - 2017
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
 */

public class cmsft_VendorInvoicePaymentSelector extends fflib_SObjectSelector
{
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
				Vendor_Invoice_Payment__c.Id,
				Vendor_Invoice_Payment__c.Amount_Paid__c,
				Vendor_Invoice_Payment__c.Payment_Type__c,
				Vendor_Invoice_Payment__c.Vendor_Invoice__c
	    };
	}

	public Schema.SObjectType getSObjectType()
	{
		return Vendor_Invoice_Payment__c.sObjectType;
	}
}