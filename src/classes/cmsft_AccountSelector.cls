/**
 * @Description :Class encapsulates query logic for Account
 * @Date : 6th June - 2017
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
 */
public class cmsft_AccountSelector extends fflib_SObjectSelector
{
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
				Account.Id,
				Account.X0_30__c,
				Account.X31_60__c,
				Account.X61_90__c,
				Account.X91__c,
				Account.Aging_Effective_Date__c,
				Account.Default_Account__c
			};
	}

	public Schema.SObjectType getSObjectType()
	{
		return Account.sObjectType;
	}
	
	/**
    * @Description select all Accounts with passed condition 
    * @return A query locator is returned, can run at calling place
    */
    public String getAllAccounts(String condition) {
        return (String)(newQueryFactory(true, true, true)
                                        .setCondition(condition)
                                        .toSOQL());
    }

    /**
    * @Description select all Accounts with passed condition 
    * @return A list is returned of the result
    */
    public List<Account> getAccountsWithPassedCondition(String condition) {
        return Database.query(newQueryFactory(true, true, true)
                                        .setCondition(condition)
                                        .toSOQL());
    }
}