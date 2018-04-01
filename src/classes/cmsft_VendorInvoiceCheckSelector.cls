/**
 * @Description :Class encapsulates query logic for Vendor_Invoice_Check__c
 *
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
 */

public class cmsft_VendorInvoiceCheckSelector extends fflib_SObjectSelector
{
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
				Vendor_Invoice_Check__c.Id,
				Vendor_Invoice_Check__c.Vendor__c,
				Vendor_Invoice_Check__c.Check_Date__c
			};
	}

	public Schema.SObjectType getSObjectType()
	{
		return Vendor_Invoice_Check__c.sObjectType;
	}

	/**
    * @Description : get all vendor invoice check records with the child vendor invoice payment records
    * @return list of query result vendor invoice check records with child records
    */
    public List<Vendor_Invoice_Check__c> getVendorInvoiceCheckWithPayments(String condition){
        assertIsAccessible();
        fflib_QueryFactory query = newQueryFactory(true, true, true);
        query.setCondition(condition);
        query.subselectQuery('Vendor_Invoice_Payments__r', true).selectFields(new cmsft_VendorInvoicePaymentSelector().getSObjectFieldList()).selectField('Vendor_Invoice__r.Invoice_Date__c');
        return (List<SObject>) Database.query( query.toSOQL() );
    }

}