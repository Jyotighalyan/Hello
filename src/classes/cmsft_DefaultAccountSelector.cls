/**
 * @Description : Class encapsulates query logic for Default_Account__c
 * @Date : 27th May - 2017
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
 **/
public class cmsft_DefaultAccountSelector extends fflib_SObjectSelector
{
	/**
	* @Description : get the list of fields to include in select query
	*/
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
				Default_Account__c.Id,
				Default_Account__c.Default_Type_Name__c,
				Default_Account__c.Financial_Account__c
			};
	}

	/**
	* @Description : get the type of sObject
	*/
	public Schema.SObjectType getSObjectType()
	{
		return Default_Account__c.sObjectType;
	}

	/**
	* @Description : method used to query Default_Account__c and return list of records with passed ids set
	*/
	public List<Default_Account__c> selectById(Set<ID> idSet)
	{
		fflib_QueryFactory contQuey = newQueryFactory(true, true, true);
		return new List<SObject> (Database.query(contQuey.setCondition('id in :idSet').toSOQL()));
	}	

	/**
	 * @Description : returns list of records matching the passed condition
	 */
	public List<Default_Account__c> selectByPassedCondition(String condition)
	{
		assertIsAccessible();
		return (List<Default_Account__c>) Database.query(
        /**
         * Query factory has been pre-initialised by calling
         * getSObjectFieldList(), getOrderBy() for you.
        */
        newQueryFactory(true, true, true).
        /**
         * Now focus on building the remainder of the
         * query needed for this method.
        */
        setCondition(condition).
        // Finally build the query to execute
        toSOQL());
	}

	/**
	 * @Description : returns list of records having default type name in passed list
	 */
	public List<Default_Account__c> selectByPassedCondition(List<String> defaultTypeName)
	{
		assertIsAccessible();
		return (List<Default_Account__c>) Database.query(
        /**
         * Query factory has been pre-initialised by calling
         * getSObjectFieldList(), getOrderBy() for you.
        */
        newQueryFactory(true, true, true).
        /**
         * Now focus on building the remainder of the
         * query needed for this method.
        */
        setCondition('Default_Type_Name__c in: defaultTypeName').
        // Finally build the query to execute
        toSOQL());
	}
}