/**
 * See https://github.com/financialforcedev/fflib-apex-common for more info
 *
 * Install library via
 *   https://githubsfdeploy.herokuapp.com/app/githubdeploy/financialforcedev/fflib-apex-common
 */

/**
 * Class encapsulates query logic for Address
 *
 *  https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
 *  @author Nagendra kumar 
 *  @Date March 01, 2017
 *	@Description Encapsulates all SOQL logic relating to the Address object
 *  @group Member Management
 */
public class cmsft_AddressSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Address__c.Id,
            Address__c.Customer__c,
            Address__c.Name,
            Address__c.Primary__c,
            Address__c.Active__c,
            Address__c.MonthDayActive__c,
            Address__c.City__c,
            Address__c.Customer__c,
            Address__c.State_Province__c,
            Address__c.Addressee__c,
            Address__c.Street_1__c,
            Address__c.Street_2__c,
            Address__c.Street_3__c,
            Address__c.Type__c,
            Address__c.Zip_Postal_Code__c,
            Address__c.Country__c,
            Address__c.From_Date__c,
            Address__c.To_Date__c,
            Address__c.Billing__c,
            Address__c.Newsletter__c,
            Address__c.Primary__c,
            Address__c.Roster__c,
            Address__c.Description__c,
            Address__c.Copied_From_Dependent__c
        };
    }

    /**
    * @description	abstract method in fflib_SObjectSelector
    * @return returns the list of fields api name
    */
    public Schema.SObjectType getSObjectType() {
        return Address__c.sObjectType;
    }

    /**
    * @description method to fetch all Adress records with passed idSet
    * @param idSet contains set of ids of which the Adress records will be fetched
    * @return returns Address as SObjectType
    */
    public List<Address__c> selectById(Set<ID> idSet) {
        return (List<Address__c>) selectSObjectsById(idSet);
    }
    
    /**
    * @description method to get contacts by passed dynamic query
    * @condition condition represents the dynamic where clause in the query 
    * @return returns list of contacts
    */
    public List<Address__c> getAllAddressesWithTheDynamicCondition(String condition) {
        assertIsAccessible();

        List<String> str = new List<String> {
            getFieldListString(),
            getSObjectName(),
            condition
        };

        String query = String.format('select {0} ' + 'from {1} ' + '{2}', str);
        List<Address__c> adrList = Data.read(query, new Map<String, Object>());

        return adrList;
    }

}