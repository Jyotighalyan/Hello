/**
 * @Description: selector class for Vendor Invoice object - includes query logic for vendor invoice
 * @Date: 16th May - 2017
 * @group : Financial Management
 */
public class cmsft_vendorInvoiceTriggerSelector extends fflib_SObjectSelector {
 public List<Schema.SObjectField> getSObjectFieldList() {
  return new List<Schema.SObjectField> {
       Vendor_Invoice__c.Id,
                Vendor_Invoice__c.Posted__c,
                Vendor_Invoice__c.Post_Status__c,
                Vendor_Invoice__c.Hold_Status__c,
                Vendor_Invoice__c.Vendor__c,
                Vendor_Invoice__c.Invoice_Date__c,
                Vendor_Invoice__c.Post_Date__c,
                Vendor_Invoice__c.Invoice_Number__c,
                Vendor_Invoice__c.Amount__c,
                Vendor_Invoice__c.Due_Date__c,
                Vendor_Invoice__c.Name,
                Vendor_Invoice__c.Amount_Distributed__c,
                Vendor_Invoice__c.Journal_Entry__c,
                Vendor_Invoice__c.Posted_Date__c,
                Vendor_Invoice__c.Name
    };
 }

    /**
    * @Description : used to return current object
    * @return Vendor Invoice obj as SObjectType
    */
 public Schema.SObjectType getSObjectType() {
  return Vendor_Invoice__c.sObjectType;
 }

    /**
    * @Description : get all records having id in passed id set
    * @return list of query result vendor invoice records
    */
 public List<Vendor_Invoice__c> selectById(Set<ID> idSet) {
  fflib_QueryFactory contQuey = newQueryFactory(true, true, true);
        return new List<SObject> (Database.query(contQuey.setCondition('id in :idSet').toSOQL()));
 }
    

    public List<Vendor_Invoice__c> checkExistingRecord(string invoiceNumber, string vendorId) {
        assertIsAccessible();
        //query with the invoice number in database and return the result
        string query_condition = 'Invoice_Number__c =\'' + invoiceNumber + '\'';
        query_condition += ' and Vendor__c =\'' + vendorId + '\'';
        return (List<Vendor_Invoice__c>) Database.query(
                   'select id from Vendor_Invoice__c ' +
                   'where ' + query_condition  );

    }

    /**
    * @Description : get all records with passed condition
    * @return list of query result vendor invoice records
    */
 public List<Vendor_Invoice__c> selectVendorInvoicesWithPassedCondition(String queryCondition)
    {
        assertIsAccessible();
        fflib_QueryFactory contQuey = newQueryFactory(true, true, true);
        return new List<SObject> (Database.query(contQuey.setCondition(queryCondition).toSOQL()));
    }

    /**
    * @Description : get all records having id in passed venInvId list with its child vendor invoice line records
    * @return list of query result vendor invoice records with child records
    */
    public List<Vendor_Invoice__c> getVendorInvoiceWithLines(List<Id> venInvIds){
        assertIsAccessible();
        fflib_QueryFactory query = newQueryFactory(true, true, true).selectFields(new Set<String> {'Vendor__r.Name'});
        query.setCondition('Id IN :venInvIds');
        query.subselectQuery('Vendor_Invoice_Lines__r', true).selectFields(new cmsft_vendorInvoiceLineTriggerSelector().getSObjectFieldList());
        return (List<SObject>) Database.query( query.toSOQL() );
    }

    /**
    * @Description : get all vendor invoices whose amount is equal to the sum of all vendor invoice line amount
    * @return list of vendor invoices having total amount = sum of vendor invoice line
    */
    public List<Vendor_Invoice__c> getVendorInvoicesWithLinesAmountEqual(List<Id> vendInvIds, String condition)
    {
        List<Vendor_Invoice__c> vendInvList = getVendorInvoiceWithLines(vendInvIds);

        //list to be returned and filled based on the passed condition
        List<Vendor_Invoice__c> vendInvoicesList = new List<Vendor_Invoice__c>();
        
            for(Vendor_Invoice__c vendInvObj :vendInvList)
            {
                Decimal vendInvAmount = vendInvObj.Amount__c;
                Decimal vendInvLineAmount = 0;
                for(Vendor_Invoice_Line__c vendInvLineObj : vendInvObj.Vendor_Invoice_Lines__r )
                {
                    vendInvLineAmount += vendInvLineObj.Amount__c;
                }
                if(condition=='Amount Equal')
                    if(vendInvAmount==vendInvLineAmount)
                    vendInvoicesList.add(vendInvObj);
                if(condition=='Amount Not Equal')
                    if(vendInvAmount!=vendInvLineAmount)
                    vendInvoicesList.add(vendInvObj);
            }
        return vendInvoicesList;
    }
}