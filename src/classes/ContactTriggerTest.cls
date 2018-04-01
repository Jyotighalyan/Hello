/*************************
@Name:ContactTriggerTest
@Author:Venkat Neteesh
@description:Class is to make code coverage for the ContactTrigger
*************************/

@isTest
public class ContactTriggerTest {
      
    /************************
     @Description: Setup required data for the test cases to execute
    *************************/
    @testSetup static void setup() {
        Id householdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        Account acc = new Account();
        acc.recordTypeId = householdRecordTypeId;
        acc.name = 'TestAccount';
        Test.startTest();
        insert acc;
        
      
        
    }
    
    Public Static List<Contact> createNewContact(Integer size, Account accc) {
        List<Contact> conList = new List<Contact>();
        for(Integer i=1 ;i<size;i++) {
            Contact con = new Contact();
            con.Relationship__c ='spouse/partner';
            con.LastName = 'TestLastName'+i;
            con.accountId = accc.Id;
            con.Membership_Type__c = 'Legacy';
            con.Status__c = 'Active';
            con.Substatus__c = 'Active';
            Id memberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
            con.recordTypeId = memberRecordTypeId;
            conList.add(con);
        }
        return conList;
    }
    
    /************************
     @Description: Method is to cover positive scenario if the user creating contact with 'Primary' relationship
    *************************/
    public static testmethod void positiveTestScenarios() {
        Account accc = [select id, name from Account where name ='TestAccount' Limit 1];        
        Contact con = new Contact();
        con.Relationship__c ='Primary';
        con.LastName = 'TestLastName';
        con.accountId = accc.Id;
        con.Membership_Type__c = 'Legacy';
        con.Status__c = 'Active';
        con.Substatus__c = 'Active';
        Id memberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        con.recordTypeId = memberRecordTypeId;
        Test.startTest();
        insert con;
        Test.stopTest();
    }
    
    /************************
     @Description: Method is to cover the exception case where the user is trying to 
     create a duplicate contact for the same account with relationship 'Primary'
    *************************/
    public static testmethod void negativeTestScenarios() {
        Account accc = [select id, name from Account where name ='TestAccount' Limit 1];         
        Contact con = new Contact();
        con.Relationship__c ='Primary';
        con.LastName = 'TestLastName';
        con.accountId = accc.Id;
        con.Membership_Type__c = 'Legacy';
        con.Status__c = 'Active';
        con.Substatus__c = 'Active';
        Test.startTest();
        insert con;
        Id memberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        Contact conDuplicate = new Contact();
        conDuplicate.Relationship__c ='Primary';
        conDuplicate.LastName = 'TestLastName2';
        conDuplicate.accountId = accc.Id;
        conDuplicate.Membership_Type__c = 'Legacy';
        conDuplicate.Status__c = 'Active';
        conDuplicate.Substatus__c = 'Active';
        conDuplicate.recordTypeId = memberRecordTypeId;
        try {
        insert conDuplicate;
        }catch(Exception e) {        
        }
        Test.stopTest();
    }
    
    /************************
     @Description: Test method for bulk insertion and updation
    *************************/
    public static testmethod void bulkInsertUpdateTestScenarios() {
    Account accc = [select id, name from Account where name ='TestAccount' Limit 1];
        Test.startTest();
        List<Contact> conListt = createNewContact(200, accc);
        //Inserting Data
        insert conListt;
        for(Contact connn :conListt) {
            Integer i = 0;
            connn.lastName = 'Test'+i;
            if(i == 200) {
                connn.Relationship__c ='Primary';
                i = 0;
            }
        }
        try {
            Database.update(conListt);
        }catch(Exception e) {           
        }
        Test.stopTest();
    }
}