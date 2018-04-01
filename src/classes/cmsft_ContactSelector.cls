/**
* https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
* @Date   March 1, 2016
* @Description Class encapsulates query logic for Contact
* @group Member Management
*/

public class cmsft_ContactSelector  extends fflib_SObjectSelector{

    /**
    * @Description method will set the default fields to be selected by the newQueryFactory()
    * @return list of fields that should be the default fields to be selected
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Contact.Id,
            Contact.Spouse__c,
            Contact.Name,
            Contact.Relationship__c,
            Contact.Email,
            Contact.Secondary_Email__c,
            Contact.Other_Email__c,
            Contact.AccountId
        };
    }

    /**
    * @Description configuring contact as sObjectType in fflib_SObjectSelector
    * @return current sobjectType
    */
    public Schema.SObjectType getSObjectType() {
        return Contact.sObjectType;
    }

    /**
    * @Description select Contact records having id in passed set of ids
    * @param idSet is the set of ids for which records are to be fetched
    * @return A list of all contacts records returned as a result
    */
    public List<Contact> selectById(Set<ID> idSet) {
        return (List<Contact>) selectSObjectsById(idSet);
    }

    /**
    * @description method to get all contacts with child addresses for the set of members id passed
    * @param idSet contains set of ids of which the contact records will be fetched
    * @return returns map of contactid and sobjectType-Contact
    */
    public Map<Id, sObject> getAllAddressesPerContact(Set<id> idSet) {
        assertIsAccessible();
        fflib_QueryFactory conAccQuery = newQueryFactory();
        fflib_QueryFactory PayMethodQuery = new cmsft_AddressSelector().addQueryFactorySubselect(conAccQuery);
        return new Map<Id, SObject>(Database.query(conAccQuery.setCondition('id in :idSet').toSOQL()));
    }
  
    /**
    * @description method to get contacts by passed dynamic query
    * @condition condition represents the dynamic where clause in the query 
    * @return returns list of contacts
    */
    public  List<Contact> getAllContactsWithTheDynamicCondition(String condition) {
        assertIsAccessible();

        List<String> str = new List<String> {
            getFieldListString(),
            getSObjectName(),
            condition
        };

        String query = String.format('select {0} ' + 'from {1} ' + '{2}', str);
        List<Contact> contactList = Data.read(query, new Map<String, Object>());

        return contactList;
    }
    
}