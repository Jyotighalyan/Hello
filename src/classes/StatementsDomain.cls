/**
 * See https://github.com/financialforcedev/fflib-apex-common for more info
 *
 * Install library via 
 *   https://githubsfdeploy.herokuapp.com/app/githubdeploy/financialforcedev/fflib-apex-common
 */

/**
 * Encapsulates all behaviour logic relating to the Statements__c object
 * 
 * For more guidelines and details see 
 *   https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Domain_Layer
 *
 **/
public class StatementsDomain extends fflib_SObjectDomain 
{
	public StatementsDomain(List<Statements__c> records) 
	{
		super(records);	
	}

	public override void onBeforeInsert()
	{
		List<Statements__c> memberStmtList = new List<Statements__c>();
		Id recTypeId = Utility.searchRecordType('Member Statement', 'Statements__c');
		for(Statements__c record : (List<Statements__c>) Records)
		{
			if(record.recordTypeId==recTypeId){
				memberStmtList.add(record);
			}
		}
		updateAddressOnMemberStatements(memberStmtList);
	}

	public override void onBeforeUpdate(map<id, SObject> existing)
	{
		List<Statements__c> memberStmtList = new List<Statements__c>();
		Id recTypeId = Utility.searchRecordType('Member Statement', 'Statements__c');
		for(Statements__c record : (List<Statements__c>) Records)
		{
			if(record.recordTypeId==recTypeId){
				memberStmtList.add(record);
			}
		}
		updateAddressOnMemberStatements(memberStmtList);
	}

	public void updateAddressOnMemberStatements(List<Statements__c> memberStatements){
		Set<Id> memberIds = new Set<Id>();
		Map<Id, List<Address__c>> mapOfMemIdAndAddresses = new Map<Id, List<Address__c>>();
		Map<Id, List<Statements__c>> mapOfMemIdAndstmt = new Map<Id, List<Statements__c>>();

		for(Statements__c memStmtObj : memberStatements){
			memberIds.add(memStmtObj.Member__c);
			if(!mapOfMemIdAndstmt.containsKey(memStmtObj.Member__c)){
				mapOfMemIdAndstmt.put(memStmtObj.Member__c, new List<Statements__c>());
			}
			mapOfMemIdAndstmt.get(memStmtObj.Member__c).add(memStmtObj);
		}

		for(Address__c addressOne :(List<Address__c>) Data.read('Select Customer__c, Type__c, Addressee__c, Street_1__c, Street_2__c, Street_3__c, To_Date__c, From_Date__c, Billing__c, Primary__c, City__c, Country__c, State_Province__c, Zip_Postal_Code__c from Address__c where Customer__c in : memberIds',
			new Map<String, object> {'memberIds' => memberIds }
			)){
			if(!mapOfMemIdAndAddresses.containsKey(addressOne.Customer__c)){
				mapOfMemIdAndAddresses.put(addressOne.Customer__c, new List<Address__c>());
			}
			mapOfMemIdAndAddresses.get(addressOne.Customer__c).add(addressOne);
		}

		for(Id memIdOne : mapOfMemIdAndAddresses.keySet()){
			List<Address__c> billingAddress = new List<Address__c>();
			List<Address__c> primaryAdresses = new List<Address__c>();
			List<Address__c> homeAddresses = new List<Address__c>();

			Address__c adressToBeAdded;

			for(Address__c addressOne : mapOfMemIdAndAddresses.get(memIdOne)){
				if(addressOne.Billing__c){
					billingAddress.add(addressOne);
				}
				if(addressOne.Primary__c){
					primaryAdresses.add(addressOne);
				}
				if(addressOne.Type__c=='Home'){
					homeAddresses.add(addressOne);
				}
			}
			if(billingAddress.size()>1){
				for(Address__c addressOne : billingAddress){
					if(addressOne.From_Date__c.month()<=Date.today().month() && addressOne.To_Date__c.month()>=Date.today().month()){
						adressToBeAdded = addressOne;
					}
					if(adressToBeAdded==null){
						continue;
					}
					else{
						break;
					}
				}
			}
			else if(billingAddress.size()==1){
				adressToBeAdded = billingAddress[0];
			}

			// if billing address can not be filled then get primary or home address
			if(adressToBeAdded==null){
				if(primaryAdresses.size()>0){
					adressToBeAdded = primaryAdresses[0];
				}
				else if(homeAddresses.size()>0){
					adressToBeAdded = homeAddresses[0];
				}
			}

			if(adressToBeAdded!=null){
				for(Statements__c stmt : mapOfMemIdAndstmt.get(memIdOne)){
					stmt.AddressId__c = adressToBeAdded.id;
				}
			}
		}
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable2
	{
		public fflib_SObjectDomain construct(List<SObject> sObjectList)
		{
			return new StatementsDomain(sObjectList);
		}

		public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType)
		{
			return new StatementsDomain(sObjectList);
		}			
	}	
}