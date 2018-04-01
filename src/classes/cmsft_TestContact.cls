/**
 * See https://github.com/financialforcedev/fflib-apex-common for more info
 *
 * Install library via
 *   https://githubsfdeploy.herokuapp.com/app/githubdeploy/financialforcedev/fflib-apex-common
 */

/**
 * For more guidelines and details see
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Domain_Layer
 * @Author Nagendra kumar
 * @Date March 6, 2017
 * @Description Trigger to populate the household on member based on the household rules.
                      Terminate Member Subscription and Recurring Payments
                      Pass members to duplicate check
                      Create community User for Contact
 * @group Test Code Coverage
 */

@isTest
private class cmsft_TestContact {
    /**
    * @description this method covered test code for C62Contact Trigger
    */
    static testmethod void C62Contact() {
        Test.startTest();

        Id guestContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Guest').getRecordTypeId();

        Contact thisContact =  new Contact(FirstName = 'TestMember23', Suffix__c = 'SmithSecond3', LastName = 'Smith3',
                                           Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith3@test.com', Relationship__c = 'Dependent', Status__c = 'Active', RecordTypeId = guestContactRT);
        Contact thisContactSpouse =  new Contact(FirstName = 'TestSpouse230', Suffix__c = '', LastName = 'Smith31',
                Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith3@test.com', Relationship__c = 'Spouse/Partner', Status__c = 'Active', Spouse__c = thisContact.id,  RecordTypeId = guestContactRT);
        Contact thisContact2 =  new Contact(FirstName = 'TestMember1', Suffix__c = 'Smith', LastName = 'Smith',
                                            Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith@test.com',  RecordTypeId = guestContactRT);
        Contact thisContact3 =  new Contact(FirstName = 'TestMember2', Suffix__c = 'SmithSecond', LastName = 'Smith2',
                                            Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith2@test.com',  RecordTypeId = guestContactRT);
        Account thisAccount = new Account(Name = thisContact.LastName, Household_Name__c = 'Test');
        thisContact3.AccountId = thisAccount.id;
        thisContact2.AccountId = thisAccount.id;
        thisContact.AccountId = thisAccount.id;

        insert thisAccount;
        insert thisContact;
        insert thisContact2;
        insert thisContact3;
        insert thisContactSpouse;

        thisContact.Status__c = 'Resigned';
        update thisContact;
        thisContact.Status__c = 'Cancelled';
        update thisContact;
        thisContact.Status__c = 'Reinstated';
        update thisContact;
        thisContact.Status__c = 'Suspended';
        update thisContact;
        thisContact.Status__c = 'Expelled';
        update thisContact;
        thisContact.Spouse__c = thisContactSpouse.id;
        update thisContact;
        thisContact.Spouse__c = thisContact3.id;
        update thisContact;
        Address__c thisAddress = new Address__c(Name = 'Test Address1', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact.Id,
                                                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                                                Street_2__c = 'Apt B', Street_3__c = 'Street 1', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress2 = new Address__c(Name = 'Test Address2', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact2.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 2', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress3 = new Address__c(Name = 'Test Address3', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact3.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 3', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress4 = new Address__c(Name = 'Test Address2', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact2.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 2', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress5 = new Address__c(Name = 'Test Address2', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact3.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 2', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);

        System.assertEquals(thisAddress.Name, 'Test Address1');

        List<Address__c> theseAddress = new List<Address__c>();

        theseAddress.add(thisAddress);
        theseAddress.add(thisAddress2);
        theseAddress.add(thisAddress3);
        theseAddress.add(thisAddress4);
        theseAddress.add(thisAddress5);
        insert theseAddress;
        Test.stopTest();

    }
    static testmethod void C62Contact2() {

        Test.startTest();

        Id guestContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Guest').getRecordTypeId();
        
        Contact thisContact =  new Contact(FirstName = 'TestMember23', Suffix__c = 'SmithSecond3', LastName = 'Smith3',
                                           Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith3@test.com', Relationship__c = 'Dependent', Status__c = 'Active',  RecordTypeId = guestContactRT);

        Contact thisContactSpouse =  new Contact(FirstName = 'TestSpouse231', Suffix__c = '', LastName = 'Smith9',
                Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith10@test.com', Relationship__c = 'Spouse/Partner', Status__c = 'Active', Spouse__c = thisContact.id,  RecordTypeId = guestContactRT);

        Contact thisContact2 =  new Contact(FirstName = 'TestMember1456', Suffix__c = 'Smith', LastName = 'Smith',
                                            Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith@test.com', Relationship__c = 'Dependent',  RecordTypeId = guestContactRT);

        Contact thisContact3 =  new Contact(FirstName = 'TestMember2', Suffix__c = 'SmithSecond', LastName = 'Smith10',
                                            Birthdate = date.newInstance(1999, 03, 05), Title__c = 'Test new', Email = 'smith2@test.com', Relationship__c = 'Dependent',  RecordTypeId = guestContactRT);

        Account thisAccount = new Account(Name = thisContact3.LastName, Household_Name__c = 'TestC62Contact2');

        thisContact3.AccountId = thisAccount.id;
        thisContact2.AccountId = thisAccount.id;
        thisContact.AccountId = thisAccount.id;

        insert thisAccount;
        insert thisContact;
        insert thisContact2;
        insert thisContact3;
        insert thisContactSpouse;

        thisContact.Status__c = 'Resigned';
        update thisContact;
        thisContact.Status__c = 'Cancelled';
        update thisContact;
        thisContact.Status__c = 'Reinstated';
        update thisContact;
        thisContact.Status__c = 'Suspended';
        update thisContact;
        thisContact.Status__c = 'Expelled';
        update thisContact;
        thisContact.Spouse__c = thisContactSpouse.id;
        update thisContact;
        thisContact.Spouse__c = thisContact3.id;
        update thisContact;
        Address__c thisAddress = new Address__c(Name = 'Test Address1', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact.Id,
                                                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                                                Street_2__c = 'Apt B', Street_3__c = 'Street 1', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress2 = new Address__c(Name = 'Test Address2', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact2.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 2', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress3 = new Address__c(Name = 'Test Address3', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact3.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 3', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress4 = new Address__c(Name = 'Test Address2', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact2.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 2', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        Address__c thisAddress5 = new Address__c(Name = 'Test Address2', From_Date__c = date.newInstance(1999, 03, 05), Customer__c = thisContact3.Id,
                Country__c = 'United States', State_Province__c = 'NY', City__c = 'Lewiston', Street_1__c = '102 River Road',
                Street_2__c = 'Apt B', Street_3__c = 'Street 2', Zip_Postal_Code__c = '14095', Type__c = 'Home', Active__c = true);
        System.assertEquals(thisAddress.Name, 'Test Address1');

        List<Address__c> theseAddress = new List<Address__c>();
        theseAddress.add(thisAddress);
        theseAddress.add(thisAddress2);
        theseAddress.add(thisAddress3);
        theseAddress.add(thisAddress4);
        theseAddress.add(thisAddress5);
        insert theseAddress;
        Test.stopTest();

    }

}