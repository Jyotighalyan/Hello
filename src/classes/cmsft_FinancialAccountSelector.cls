/**
* @author Salesforce.com Foundation
* @date 2014
*
* @group Financial Management
*
* @description financial account trigger selectore to get the data from database.
*/

/**
 * Class encapsulates query logic for Financial_Account__c
 *
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
 **/
public class cmsft_FinancialAccountSelector extends fflib_SObjectSelector
{
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
			Financial_Account__c.Id,
			Financial_Account__c.Debit_Credit__c
		};
	}
	public Schema.SObjectType getSObjectType()
	{
		return Financial_Account__c.sObjectType;
	}
	public List<Financial_Account__c> selectById(Set<ID> idSet)
	{
		return (List<Financial_Account__c>) selectSObjectsById(idSet);
	}
	public Map<Id, SObject> selectAllFinancialAccount(){
		assertIsAccessible();
		fflib_QueryFactory conAccQuery = newQueryFactory();
		return new Map<Id, SObject>(Database.query(conAccQuery.toSOQL()));
	}

		/**
	* @description Returns id,Location__c as pet the condition
	*/
	public List<Financial_Account__c> get_finAccountValues(string where_fieldName) {
		assertIsAccessible();
		string query_condition = where_fieldName + '= true';
		return (List<Financial_Account__c>) Database.query(
		           'select id,Location__c from Financial_Account__c ' +

		           'where ' + query_condition  );

	}

}