/**
* @Description : test class for BillingTableDomain 
* @group : Financial Management
*/
@isTest
private class MemberDuesDomainTest
{
    @isTest
    static void BillingTableDomainTest1()
    {
        Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
        Contact member = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
        List<Member_Dues__c> duesList = new List<Member_Dues__c>();
        List<Billing_Custom_Distribution__c> billList = new List<Billing_Custom_Distribution__c>();
        Member_Dues__c dueObj = TxnTestUtility.getDue('Testing Due', 'Monthly');

        // bulk test
        for(Integer i=0; i<199; i++)
        {
            Member_Dues__c dueObj1 = dueObj.clone(false,false);
            dueObj1.Name = dueObj1.Name+i;
            duesList.add(dueObj1);
        }
        insert duesList;
        update duesList;
        for(Member_Dues__c due :duesList)
        {
            Billing_Custom_Distribution__c billCus = new Billing_Custom_Distribution__c(Type__c='Dependent', Member_Dues__c=due.Id, January__c=100);
            Billing_Custom_Distribution__c billCus1 = new Billing_Custom_Distribution__c(Type__c='Primary', Member_Dues__c=due.Id);
            Billing_Custom_Distribution__c billCus2 = new Billing_Custom_Distribution__c(Type__c='Spouse/Partner', Member_Dues__c=due.Id);
            billList.add(billCus);
            billList.add(billCus1);
            billList.add(billCus2);
            due.Default_Billing_Frequency__c = 'Annual';
        }
        insert billList;

        // apply this due on member
        Test.startTest();
        update duesList;
        Billing_Custom_Distribution__c distr = [select January__c from Billing_Custom_Distribution__c where Member_Dues__c=:duesList.get(0).id AND Type__c='Dependent'];
        System.assertEquals(distr.January__c, 0);
        Test.stopTest();        
    }
}