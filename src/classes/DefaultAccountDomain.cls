/**
 * For more guidelines and details see 
 *   https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Domain_Layer
 *
 * @Description : Encapsulates all behaviour logic relating to the Default_Account__c object
 * @Author : jyotig@mobifyi.com
 * @group : Financial Management
 **/
public class DefaultAccountDomain extends fflib_SObjectDomain 
{
	public DefaultAccountDomain(List<Default_Account__c> records) 
	{
		super(records);	
	}

	public override void onBeforeInsert()
	{
		validateTypeName(Records);
	}

	public override void onBeforeUpdate(Map<Id,SObject> existingRecords)
	{
		validateTypeName(Records);
	}

	/**
	* @Description : check for records having duplicate default type name
	*/
	public void validateTypeName(List<SObject> Records)
	{
		List<String> defaultTypeNames = new List<String>();

		for(Default_Account__c record : (List<Default_Account__c>) Records)
		{
			if(record.Default_Type_Name__c!=null && record.Default_Type_Name__c!='')
				defaultTypeNames.add(record.Default_Type_Name__c);
		}
		Map<Id, Default_Account__c> defAccountHaving = new Map<Id, Default_Account__c>(new cmsft_DefaultAccountSelector().selectByPassedCondition(defaultTypeNames));
		for(Integer i=0; i< Records.size(); i++)
		{
			Default_Account__c defRecord = (Default_Account__c)Records[i];

			// for loop to cover all saved records
			for(Default_Account__c defAccObj :defAccountHaving.values())
			{
				if(defRecord.id!=null && defRecord.id!=defAccObj.id) {
					if(defRecord.Default_Type_Name__c == defAccObj.Default_Type_Name__c)
					defRecord.Default_Type_Name__c.addError('Account mapping with this default type name already exist.');
					break;
				}
				else if(defRecord.id==null) {
					if(defRecord.Default_Type_Name__c == defAccObj.Default_Type_Name__c)
					defRecord.Default_Type_Name__c.addError('Account mapping with this default type name already exist.');
					break;
				}
			}

			// for loop to check in the coming list
			for(Integer j=i+1; j<Records.size(); j++)
			{
				Default_Account__c record1 = (Default_Account__c) Records[i];
				if(defRecord.Default_Type_Name__c == record1.Default_Type_Name__c){
					defRecord.Default_Type_Name__c.addError('Account mapping with this default type name already exist.');
					break;
				}
			}
		}
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable2
	{
		public fflib_SObjectDomain construct(List<SObject> sObjectList)
		{
			return new DefaultAccountDomain(sObjectList);
		}

		public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType)
		{
			return new DefaultAccountDomain(sObjectList);
		}			
	}	
}