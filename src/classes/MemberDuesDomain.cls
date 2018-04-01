/**
 * @Description : Encapsulates all behaviour logic relating to the Billing_Table__c object
 * For more guidelines and details see 
 *   https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Domain_Layer
 * @group : Financial Management
 * @Date : 2017
 **/
public class MemberDuesDomain extends fflib_SObjectDomain 
{
    public MemberDuesDomain(List<Member_Dues__c> records) 
    {
        super(records); 
    }

    public override void onBeforeUpdate(Map<Id,SObject> existingRecords)
    {
        Set<Id> dueIdSet = new Set<Id>();
        for(Member_Dues__c record : (List<Member_Dues__c>) Records)
        {
            dueIdSet.add(record.id);
        }
        Map<Id, List<Billing_Custom_Distribution__c>> mapOfDistributions = getMapOfDueIdAndMembers(dueIdSet);
        Map<Id, Member_Dues__c> billTableRecs = new Map<Id, Member_Dues__c>((List<Member_Dues__c>)Data.read('select Default_Billing_Frequency__c from Member_Dues__c where id in :dueId', new Map<String, Object> {'dueId' => dueIdSet}));
        List<Billing_Custom_Distribution__c> distributionsRecsToBeUpdated = new List<Billing_Custom_Distribution__c>();

        for(Member_Dues__c record : (List<Member_Dues__c>) Records)
        {
            // condition to check if defaut billing freq is changing from Monthly or installment to any other freq, from quaterly to semi anuual or annual, from semi-annual to annual then clear out distribution
            if(billTableRecs.get(record.id).Default_Billing_Frequency__c!=record.Default_Billing_Frequency__c){
                 if(((billTableRecs.get(record.id).Default_Billing_Frequency__c=='Monthly' || billTableRecs.get(record.id).Default_Billing_Frequency__c=='Installment') && (record.Default_Billing_Frequency__c=='Quaterly' || record.Default_Billing_Frequency__c=='Annual' || record.Default_Billing_Frequency__c=='Semi-Annual')) 
                    || (billTableRecs.get(record.id).Default_Billing_Frequency__c=='Quaterly' && (record.Default_Billing_Frequency__c=='Annual' || record.Default_Billing_Frequency__c=='Semi-Annual')) 
                    || (billTableRecs.get(record.id).Default_Billing_Frequency__c=='Semi-Annual' && record.Default_Billing_Frequency__c=='Annual')
                  )
                 {
                    for(Billing_Custom_Distribution__c billCusDistr :mapOfDistributions.get(record.id)){
                        distributionsRecsToBeUpdated.add(BillingTableSetupDetailController.removeDistrAmounts(billCusDistr));
                    }
                 }
            }
        }

        if(distributionsRecsToBeUpdated.size()>0){
            Data.modify(distributionsRecsToBeUpdated);
        }
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable2
    {
        public fflib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new MemberDuesDomain (sObjectList);
        }

        public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType)
        {
            return new MemberDuesDomain (sObjectList);
        }           
    }

    public Map<Id, List<Billing_Custom_Distribution__c>> getMapOfDueIdAndMembers(Set<Id> dueIds)
    {
        Map<Id, List<Billing_Custom_Distribution__c>> mapOfDistributions = new Map<Id, List<Billing_Custom_Distribution__c>>();
        String query = 'Select '+Utility.getFields('Billing_Custom_Distribution__c')+' from Billing_Custom_Distribution__c';
        for(Billing_Custom_Distribution__c appDueOnMem :(List<Billing_Custom_Distribution__c>)Data.read(query+' where Member_Dues__c in :dueId', new Map<String, Object> {'dueId' => dueIds}))
        {
            if(!mapOfDistributions.containsKey(appDueOnMem.Member_Dues__c)){
                mapOfDistributions.put(appDueOnMem.Member_Dues__c, new List<Billing_Custom_Distribution__c>());
            }
            mapOfDistributions.get(appDueOnMem.Member_Dues__c).add(appDueOnMem);
        }
        return mapOfDistributions;
    }

}