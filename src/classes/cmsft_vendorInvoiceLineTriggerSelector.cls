/**
 * @Description: selector class for Vendor Invoice Line object - includes query logic for vendor invoice Line
 * @Date: 16th May - 2017
 * @group : Financial Management
 */
public class cmsft_vendorInvoiceLineTriggerSelector extends fflib_SObjectSelector {

/**
* @Description : fields list can be included in query
*/	
public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField> {
			Vendor_Invoice_Line__c.Id,
			Vendor_Invoice_Line__c.Name,
			Vendor_Invoice_Line__c.Amount__c,
			Vendor_Invoice_Line__c.Financial_Account__c,
			Vendor_Invoice_Line__c.Amount_Remaining_To_Pay__c,
			Vendor_Invoice_Line__c.Description__c,
			Vendor_Invoice_Line__c.Financial_Journal_Line__c,
			Vendor_Invoice_Line__c.Payment_Type__c,
			Vendor_Invoice_Line__c.Posted__c,
			Vendor_Invoice_Line__c.Vendor_Invoice__c,
			Vendor_Invoice_Line__c.Vendor_Invoice__r.Payment_Type__c,
			Vendor_Invoice_Line__c.Vendor_Invoice__r.Vendor__r.id,
			Vendor_Invoice_Line__c.Payment_Financial_Account__c,
            Vendor_Invoice_Line__c.Use_Tax__c 
		};
	}

	/**
    * @Description : used to return current object
    * @return Vendor Invoice line obj as SObjectType
    */
	public Schema.SObjectType getSObjectType() {
		return Vendor_Invoice_Line__c.sObjectType;
	}

	/**
    * @Description : get all records having id in passed id set
    * @return list of query result vendor invoice line records
    */
	public List<Vendor_Invoice_Line__c> selectById(Set<ID> idSet) {
		fflib_QueryFactory contQuey = newQueryFactory(true, true, true);
		return new List<SObject> (Database.query(contQuey.setCondition('id in :idSet').toSOQL()));
	}
    
    public double getInvoiceLineAmountTotal(string invoiceId) {
		assertIsAccessible();
        //AggregateResult[] TotalAmountQryResult = [select sum(Amount__c)total from Vendor_Invoice_Line__c where Vendor_Invoice__c =:invoiceId ];
        AggregateResult[] TotalAmountQryResult = (AggregateResult[])Data.read(
                'select sum(Amount__c)total from Vendor_Invoice_Line__c where Vendor_Invoice__c =:invoiceId',
                new Map<String,Object> {
                    'invoiceId'=>invoiceId
                }
            );
		return double.valueOf(TotalAmountQryResult[0].get('total')); 
	}
    
    public double getTotalInvoiceAmount(string invoiceId) {
		assertIsAccessible();
        //List<Vendor_Invoice__c> TotalAmountQryResult = [select Amount__c from Vendor_Invoice__c where id =:invoiceId ];
		 List<Vendor_Invoice__c> TotalAmountQryResult = (List<Vendor_Invoice__c>)Data.read(
                'select Amount__c from Vendor_Invoice__c where id =:invoiceId',
                new Map<String,Object> {
                    'invoiceId'=>invoiceId
                }
            );
        return double.valueOf(TotalAmountQryResult[0].get('Amount__c'));
	}
}