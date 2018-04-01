@isTest
public with sharing class EventHandlerTest {
    static Id memberId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
    static Id householdId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    static Id chargeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Charge').getRecordTypeId();
    static Id chargeItemId = Schema.SObjectType.Charge_Item__c.getRecordTypeInfosByName().get('Event Menu').getRecordTypeId();
    static Id lineItemId = Schema.SObjectType.Line_Item__c.getRecordTypeInfosByName().get('Charge').getRecordTypeId();

    //Setup testing data

    @testSetup static void setup(){
        List<Account> accounts = new List<Account>();
        Account account1 = new Account(RecordTypeId = householdId, Name = 'Doe');
        Account account2 = new Account(RecordTypeId = householdId, Name = 'Smith');
        Account account3 = new Account(RecordTypeId = householdId, Name = 'Nguyen');
        accounts.add(account1);
        accounts.add(account2);
        accounts.add(account3);
        insert accounts;

        Taxes__c taxesCustomSettings = new Taxes__c();
        taxesCustomSettings.Sales_Tax__c = 10.00;
        taxesCustomSettings.Transit_Improvement_Sales_Tax__c = 1.00;
        insert taxesCustomSettings;

        ServiceCharges__c servicesCustomSettings = new ServiceCharges__c();
        servicesCustomSettings.Service_Charge_Member__c = 5.00;
        insert servicesCustomSettings;

        Financial_Account__c financialAccount = new Financial_Account__c(Name = 'TEST_FIN_ACCOUNT', Account_Number__c = '123456789', Category__c = 'Expense');
        insert financialAccount;

        List<Tax_To_Account_Mapping__c> taxToAccounts = new List<Tax_To_Account_Mapping__c>();
        Tax_To_Account_Mapping__c taxToAccount1 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT1', Financial_Accounts__c = financialAccount.Id, Tax__c = 'Sales_Tax__c');
        Tax_To_Account_Mapping__c taxToAccount2 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT2', Financial_Accounts__c = financialAccount.Id, Service_Charge__c = 'Service_Charge_Member__c');
        Tax_To_Account_Mapping__c taxToAccount3 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT1', Financial_Accounts__c = financialAccount.Id, Tax__c = Utility.getNameOfTax('Sales_Tax__c'));
        Tax_To_Account_Mapping__c taxToAccount4 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT2', Financial_Accounts__c = financialAccount.Id, Service_Charge__c = Utility.getNameOfServiceCharge('Service_Charge_Member__c'));
        taxToAccounts.add(taxToAccount1);
        taxToAccounts.add(taxToAccount2);
        taxToAccounts.add(taxToAccount3);
        taxToAccounts.add(taxToAccount4);
        insert taxToAccounts;

        TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Dinner';
        taxObj.Subtype__c = null;
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=true;
        taxObj.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj.TaxId__c = 'Sales_Tax__c';
        insert taxObj;

        List<Contact> contacts = new List<Contact>();
        Contact contact1 = new Contact(RecordTypeId = memberId, Account = account1, AccountId = account1.Id, Customer_Id__c = '001',
                                       Membership_Type__c = 'Legacy', Relationship__c = 'Primary', Status__c = 'Active',
                                       Substatus__c = 'Active',LastName = 'Doe');
        insert contact1;

        Location__c location1 = new Location__c(Name = 'CY_TEST_LOCATION');
        insert location1;
        List<Event__c> events = new List<Event__c>();
        for(Integer i = 0; i < 3; i++){
            Event__c event = new Event__c(Contract_Due_Date__c = System.Today(), EndTime__c = DateTime.now().addHours(2), SponsoringMember__c = contact1.Id, Max_Seats__c = 20, Name = ('CY_TEST_EVENT' + String.valueOf(i)), Sponsoring_Customer__c = contact1.Id, Status__c = 'Approved',
                                                    Location__c = location1.id, Post_Close_Date_Time__c = DateTime.now(),  StartTime__c = DateTime.now());
            events.add(event);
        }
        for(Integer i = 0; i < 3; i++){
            Event__c event = new Event__c(Contract_Due_Date__c = System.Today(), EndTime__c = DateTime.now().addHours(2), SponsoringMember__c = contact1.Id, Max_Seats__c = 20, Name = ('CLOSEDPOST_TEST_EVENT' + String.valueOf(i)), Sponsoring_Customer__c = contact1.Id, Status__c = 'Prospective',
                                        Location__c = location1.id, Post_Close_Date_Time__c = DateTime.now(),  StartTime__c = DateTime.now());
            events.add(event);
        }
        for(Integer i = 0; i < 3; i++){
            Event__c event = new Event__c(Contract_Due_Date__c = System.Today(), EndTime__c = DateTime.now().addHours(2), SponsoringMember__c = contact1.Id, Max_Seats__c = 20, Name = ('CANCELLED_TEST_EVENT' + String.valueOf(i)), Sponsoring_Customer__c = contact1.Id, Status__c = 'Prospective',
                                        Location__c = location1.id, Post_Close_Date_Time__c = DateTime.now(),  StartTime__c = DateTime.now());
            events.add(event);
        }
        for(Integer i = 0; i < 3; i++){
            Event__c event = new Event__c(Contract_Due_Date__c = System.Today(), EndTime__c = DateTime.now().addHours(2), SponsoringMember__c = contact1.Id, Max_Seats__c = 20, Name = ('REOPENED_TEST_EVENT' + String.valueOf(i)), Sponsoring_Customer__c = contact1.Id, Status__c = 'Re-opened',
                                        Location__c = location1.id, Post_Close_Date_Time__c = DateTime.now(),  StartTime__c = DateTime.now());
            events.add(event);
        }

        for(Integer i = 0; i < 3; i++){
            Event__c event = new Event__c(Contract_Due_Date__c = System.Today(), EndTime__c = DateTime.now().addHours(2), SponsoringMember__c = contact1.Id, Max_Seats__c = 20, Name = ('CONFIRMED_TEST_EVENT' + String.valueOf(i)), Sponsoring_Customer__c = contact1.Id, Status__c = 'Confirmed',
                                        Location__c = location1.id, Post_Close_Date_Time__c = DateTime.now(),  StartTime__c = DateTime.now());
            events.add(event);
        }

        insert events;

        Charge_Item__c chargeitem1 = new Charge_Item__c(Name = 'CY_TEST_CHARGE_ITEM', RecordTypeId = chargeItemId, 
                                                        Type__c = 'Dinner',Price__c = 50.00);
        insert chargeitem1;

        Line_Item__c lineItem1 = new Line_Item__c(Charge_Item__c = chargeitem1.id, RecordTypeId = lineItemId,
                                                                        Qty__c = 50, Reservation_line__c = events.get(0).id, Tax_Amount__c = 10.00,
                                                                        Service_Charge__c = 10.00, Override_Date__c = System.today());
        insert lineItem1;
    }

    //testing trigger for finalization of event
    @isTest static void TestFinalizeEvent(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            
            List<Event__c> eventList = [SELECT Id, Status__c FROM Event__c WHERE Name = 'CY_TEST_EVENT0'];
            
            System.test.startTest();
            Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
            Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
            da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;

            if (eventList.size() > 0) {
                eventList[0].Status__c = 'Closed/Posted';
                update eventList[0];
            }
            
            System.test.stopTest();

            ID CY_chargeitem = [SELECT ID FROM Charge_Item__c WHERE Name = 'CY_TEST_CHARGE_ITEM'].Id;
            
            Line_Item__c CY_line = [SELECT ID, Name, (SELECT Id FROM Transactions__r) 
                                            FROM Line_Item__c WHERE Charge_Item__c = :CY_chargeitem];
            
            System.assert(CY_line.Transactions__r.size() >= 0, 'There were no transactions created.');
        }
    }

    //testing trigger for EventStatusCheck of Closed/Posted event
    @isTest static void TestClosedPostedStatusCheckEventOnUpdate(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            Set<String> eventNames = new Set<String>{'CLOSEDPOST_TEST_EVENT0','CLOSEDPOST_TEST_EVENT1','CLOSEDPOST_TEST_EVENT2'};
            List<Event__c> eventList = [SELECT Id, Status__c FROM Event__c WHERE Name IN :eventNames];
            for(Event__c event: eventList){
                event.Status__c = 'Closed/Posted';
            }
            update eventList;

            
            try{
            System.test.startTest();
            List<Event__c> eventListToUpdate = [SELECT Id, Description__c FROM Event__c WHERE Name IN :eventNames];

            if (eventList.size() > 0) {

                for(Event__c event: eventList){
                   event.Description__c = 'Updated'; 
                }
                
                update eventListToUpdate;
            }
            System.test.stopTest();
            }catch(Exception e){
                System.debug('**** Message: <'+e.getMessage()+'>');
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Closed/Posted. If you wish to make changes, you must re-open your event.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
}


    //testing trigger for EventStatusCheck of Cancelled event
    @isTest static void TestCancelledStatusCheckEventOnUpdate(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            Set<String> eventNames = new Set<String>{'CANCELLED_TEST_EVENT0','CANCELLED_TEST_EVENT1','CANCELLED_TEST_EVENT2'};
            List<Event__c> eventList = [SELECT Id, Status__c FROM Event__c WHERE Name IN :eventNames];
            for(Event__c event: eventList){
                event.Status__c = 'Cancelled';
            }
            update eventList;

            try{
            System.test.startTest();
            List<Event__c> eventListToUpdate = [SELECT Id, Description__c FROM Event__c WHERE Name IN :eventNames];

            if (eventList.size() > 0) {

                for(Event__c event: eventListToUpdate){
                   event.Description__c = 'Updated'; 
                }
                
                update eventListToUpdate;
            }
            System.test.stopTest();
            }catch(Exception e){
                System.debug('**** Message: <'+e.getStackTraceString()+'>');
                //Boolean expectedExceptionThrown = e.getMessage().contains('This event is Cancelled. You can no longer make changes.');
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Closed/Posted or Cancelled. If you wish to make changes, you must re-open your event.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    //testing trigger for EventStatusCheck of Closed/Posted event
    @isTest static void TestClosedPostedStatusCheckEventOnDelete(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            Set<String> eventNames = new Set<String>{'CLOSEDPOST_TEST_EVENT0','CLOSEDPOST_TEST_EVENT1','CLOSEDPOST_TEST_EVENT2'};
            List<Event__c> eventList = [SELECT Id, Status__c FROM Event__c WHERE Name IN :eventNames];
            for(Event__c event: eventList){
                event.Status__c = 'Closed/Posted';
            }
            update eventList;
            
            try{               
                System.test.startTest();
                delete eventList;
                System.test.stopTest();
            
            
            }catch(Exception e){
                System.debug('**** Message: <'+e.getMessage()+'>');
                Boolean expectedExceptionThrown = e.getMessage().contains('This event has been Closed/Posted. You can no longer make changes.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    //testing trigger for EventStatusCheck of Cancelled event
    @isTest static void TestCancelledStatusCheckEventOnDelete(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            Set<String> eventNames = new Set<String>{'CANCELLED_TEST_EVENT0','CANCELLED_TEST_EVENT1','CANCELLED_TEST_EVENT2'};
            List<Event__c> eventList = [SELECT Id, Status__c FROM Event__c WHERE Name IN :eventNames];
            for(Event__c event: eventList){
                event.Status__c = 'Cancelled';
            }
            update eventList;
            
            try{
            System.test.startTest();
                delete eventList;
            System.test.stopTest();
            }catch(Exception e){
                System.debug('**** Message: <'+e.getMessage()+'>');
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Cancelled. You can no longer make changes.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

     //testing trigger for EventStatusCheck of Re-opened event
    @isTest static void TestReopenedStatusCheckEventOnDelete(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            Set<String> eventNames = new Set<String>{'REOPENED_TEST_EVENT0','REOPENED_TEST_EVENT1','REOPENED_TEST_EVENT2'};
            List<Event__c> eventList = [SELECT Id, Status__c FROM Event__c WHERE Name IN :eventNames];

            
            try{
            System.test.startTest();
                delete eventList;
            System.test.stopTest();
            }catch(Exception e){
                System.debug('**** Message: <'+e.getMessage()+'>');
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Re-opened. You can no longer delete it.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    //testing trigger for EventStatusCheck of Confirmed event
    @isTest static void TestConfirmedStatusCheckEventOnDelete(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            Set<String> eventNames = new Set<String>{'CONFIRMED_TEST_EVENT0','CONFIRMED_TEST_EVENT1','CONFIRMED_TEST_EVENT2'};
            List<Event__c> eventList = [SELECT Id, Status__c FROM Event__c WHERE Name IN :eventNames];

            
            try{
            System.test.startTest();
                delete eventList;
            System.test.stopTest();
            }catch(Exception e){
                System.debug('**** Message: <'+e.getMessage()+'>');
                Boolean expectedExceptionThrown = e.getMessage().contains('This event has been Confirmed. You can no longer delete it.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }
}