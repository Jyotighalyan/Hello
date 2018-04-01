@isTest
public with sharing class GuestPassScheduleTest
{

    @isTest
    static void testGuestPass()
    {
        Account acc = new Account(Name='testacc',RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId());
        insert acc;
        
		Contact con = new Contact(LastName='testGuest1',AccountId=acc.id,Account_Balance__c=1.00, RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Guest').getRecordTypeId());
        insert con;
        Contact con2 = new Contact(LastName='testMember1',AccountId=acc.id,Account_Balance__c=1.00);
        insert con2;
        
        Contact con3 = new Contact(LastName='testGuest2',AccountId=acc.id,Account_Balance__c=1.00, RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Guest').getRecordTypeId());
        insert con3;
        Contact con4 = new Contact(LastName='testMember2',AccountId=acc.id,Account_Balance__c=1.00);
        insert con4;

        Guest_Pass__c guestPassActivate= new Guest_Pass__c(Guest_Name__c=con.id,
                                                            Member_Sponsor__c=con2.id,
                                                            Start__c = Date.today() - 1,
                                                            Expiration__c = Date.today() + 1);
        insert guestPassActivate;

        Guest_Pass__c guestPassExpire= new Guest_Pass__c(Guest_Name__c=con3.id,
                                                            Member_Sponsor__c=con4.id,
                                                            Start__c = Date.today() - 2,
                                                            Expiration__c = Date.today() - 1,
                                                        	Active__c = true);
        insert guestPassExpire;

        Test.startTest();
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
			GuestPassSchedule scheduledJob = new GuestPassSchedule();
            scheduledJob.execute(null);
		}
        Test.stopTest();
    }
}