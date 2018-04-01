@isTest
public class LineItemTriggerTest {
    @testSetup static void setup() {

        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da =TxnTestUtility.getDefaultMapping('Accounts Payable',fa);
        
        Location__c location = new Location__c(Name = 'Lounge');
        insert location;

        TxnChargeToTaxMapping__c taxObj = new TxnChargeToTaxMapping__c();
        taxObj.Type__c = 'Bar';
        taxObj.Subtype__c = null;
        taxObj.Allow_in_POS__c = true;
        taxObj.Taxes_applicable_on_service_charge__c = false;
        taxObj.Service_Charge_applicable__c = false;
        
        insert taxObj;

        List<Charge_Item__c> chargeItems = new List<Charge_Item__c>();
        Charge_Item__c chargeItem1 = new Charge_Item__c(Name = 'Cocktail', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem2 = new Charge_Item__c(Name = 'Scotch', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem3 = new Charge_Item__c(Name = 'Wine', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem4 = new Charge_Item__c(Name = 'Cigar', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem5 = new Charge_Item__c(Name = 'Bourbon', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem6 = new Charge_Item__c(Name = 'Champagne', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem7 = new Charge_Item__c(Name = 'Cigarette', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem8 = new Charge_Item__c(Name = 'Vodka', Type__c = 'Bar', Price__c = 15.00);
        Charge_Item__c chargeItem9 = new Charge_Item__c(Name = 'Steak', Type__c = 'Bar', Price__c = 15.00);
        chargeItems.add(chargeItem1);
        chargeItems.add(chargeItem2);
        chargeItems.add(chargeItem3);
        chargeItems.add(chargeItem4);
        chargeItems.add(chargeItem5);
        chargeItems.add(chargeItem6);
        chargeItems.add(chargeItem7);
        chargeItems.add(chargeItem8);
        chargeItems.add(chargeItem9);
        insert chargeItems;

        List<Event__c> events = new List<Event__c>();
        Event__c event1 = TestHandler.getEvent();
        event1.Name = 'Party';
        event1.Location__c = location.Id;
        event1.Status__c = 'Approved';

        Event__c event2 = TestHandler.getEvent();
        event2.Name = 'Whiskey Tasting';
        event2.Location__c = location.Id;
        event2.Status__c = 'Approved';

        Event__c event3 = TestHandler.getEvent();
        event3.Name = 'Fundraiser';
        event3.Location__c = location.Id;
        event3.Status__c = 'Approved';

        Event__c event4 = TestHandler.getEvent();
        event4.Name = 'New Year Celebration';
        event4.Location__c = location.Id;
        event4.Status__c = 'Approved';

        Event__c event5 = TestHandler.getEvent();
        event5.Name = 'Wine Tasting';
        event5.Location__c = location.Id;
        event5.Status__c = 'Approved';

        Event__c event6 = TestHandler.getEvent();
        event6.Name = 'Smoker';
        event6.Location__c = location.Id;
        event6.Status__c = 'Approved';

        events.add(event1);
        events.add(event2);
        events.add(event3);
        events.add(event4);
        events.add(event5);
        events.add(event6);
        update events;

        Set<String> eventNames = new Set<String> {'Party', 'Whiskey Tasting', 'Fundraiser', 'New Year Celebration', 'Wine Tasting', 'Smoker'};
        List<Event__c> eventsToUpdate = [SELECT Id, Status__c FROM Event__c WHERE Name IN :eventNames];
        List<Line_Item__c> lineItems = new List<Line_Item__c>();
        Set<String> chargeItemNames = new Set<String> {'Cigarette', 'Vodka', 'Steak'};
        List<Charge_Item__c> newChargeItems = [SELECT Id, Name FROM Charge_Item__c WHERE Name IN :chargeItemNames];

        for (Event__c event : eventsToUpdate) {
            Line_Item__c lineItem1 = new Line_Item__c(Charge_Item__c = newChargeItems[0].Id, Qty__c = 10, Reservation_Line__c = event.Id, Override_Date__c = date.parse('7/17/2017'));
            Line_Item__c lineItem2 = new Line_Item__c(Charge_Item__c = newChargeItems[1].Id, Qty__c = 10, Reservation_Line__c = event.Id, Override_Date__c = date.parse('7/17/2017'));
            Line_Item__c lineItem3 = new Line_Item__c(Charge_Item__c = newChargeItems[2].Id, Qty__c = 10, Reservation_Line__c = event.Id, Override_Date__c = date.parse('7/17/2017'));
            lineItems.add(lineItem1);
            lineItems.add(lineItem2);
            lineItems.add(lineItem3);
        }

        insert lineItems;
        for (Integer i = 0; i < 3; i++) {
            eventsToUpdate[i].Status__c = 'Closed/Posted';
        }
        for (Integer i = 3; i < 6; i++) {
            eventsToUpdate[i].Status__c = 'Cancelled';
        }
        for (Integer i = 0; i < 6; i++) {
            eventsToUpdate[i].Post_Close_Date_Time__c = date.parse('6/17/2017');
        }

        update eventsToUpdate;
    }

    @isTest static void TestEventStatusClosedPostOnInsert() {
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser) {
            Set<String> chargeItemNames = new Set<String> {'Cocktail', 'Scotch', 'Wine', 'Cigar', 'Bourbon', 'Champagne'};
            List<Charge_Item__c> chargeItems = [SELECT Id FROM Charge_Item__c WHERE Name IN :chargeItemNames];
            Set<String> eventNames = new Set<String> {'Party', 'Whiskey Tasting', 'Fundraiser', 'New Year Celebration', 'Wine Tasting', 'Smoker'};
            List<Event__c> events = [SELECT Id FROM Event__c WHERE Name IN :eventNames];
            List<Line_Item__c> lineItems = new List<Line_Item__c>();
            try {
                Test.startTest();
                for (Integer i = 0; i < 3; i++) {
                    Line_Item__c lineItem = new Line_Item__c(Charge_Item__c = chargeItems.get(i).Id, Qty__c = 10, Reservation_Line__c = events.get(i).Id, Override_Date__c = System.today());
                    lineItems.add(lineItem);
                }
                insert lineItems;
                Test.stopTest();
            } catch (Exception e) {
                System.debug('**** Message: <' + e.getMessage() + '>');
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Closed/Posted or Cancelled. If you wish to make changes, you must re-open your event');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    @isTest static void TestEventStatusCancelledOnInsert() {
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser) {
            Set<String> chargeItemNames = new Set<String> {'Cocktail', 'Scotch', 'Wine', 'Cigar', 'Bourbon', 'Champagne'};
            List<Charge_Item__c> chargeItems = [SELECT Id FROM Charge_Item__c WHERE Name IN :chargeItemNames];
            Set<String> eventNames = new Set<String> {'Party', 'Whiskey Tasting', 'Fundraiser', 'New Year Celebration', 'Wine Tasting', 'Smoker'};
            List<Event__c> events = [SELECT Id FROM Event__c WHERE Name IN :eventNames];
            List<Line_Item__c> lineItems = new List<Line_Item__c>();
            try {
                Test.startTest();
                for (Integer i = 3; i < 6; i++) {
                    Line_Item__c lineItem = new Line_Item__c(Charge_Item__c = chargeItems.get(i).Id, Qty__c = 10, Reservation_Line__c = events.get(i).Id, Override_Date__c = System.today());
                    lineItems.add(lineItem);
                }
                insert lineItems;
                Test.stopTest();
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Closed/Posted or Cancelled. If you wish to make changes, you must re-open your event.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    @isTest static void TestEventStatusClosedPostOnUpdate() {
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser) {
            Set<String> eventNames = new Set<String> {'Party', 'Whiskey Tasting', 'Fundraiser'};
            List<Event__c> events = [SELECT Id FROM Event__c WHERE Name IN :eventNames];
            List<Line_Item__c> lineItems = [SELECT Id FROM Line_Item__c WHERE Reservation_Line__c IN :events];
            try {
                List<Line_Item__c> lineItemsToUpdate = new List<Line_Item__c>();
                Test.startTest();
                for (Line_Item__c lineItem : lineItemsToUpdate) {
                    lineItem.Qty__c = 20;
                    lineItemsToUpdate.add(lineItem);
                }
                update lineItemsToUpdate;
                Test.stopTest();
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Closed/Posted. If you wish to make changes, you must re-open your event.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    @isTest static void TestEventStatusCancelledOnUpdate() {
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser) {
            Set<String> eventNames = new Set<String> {'New Year Celebration', 'Wine Tasting', 'Smoker'};
            List<Event__c> events = [SELECT Id FROM Event__c WHERE Name IN :eventNames];
            List<Line_Item__c> lineItems = [SELECT Id FROM Line_Item__c WHERE Reservation_Line__c IN :events];
            try {
                List<Line_Item__c> lineItemsToUpdate = new List<Line_Item__c>();
                Test.startTest();
                for (Line_Item__c lineItem : lineItemsToUpdate) {
                    lineItem.Qty__c = 20;
                    lineItemsToUpdate.add(lineItem);
                }
                update lineItemsToUpdate;
                Test.stopTest();
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Cancelled. You can no longer make changes.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }


    @isTest static void TestEventStatusClosedPostOnDelete() {
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser) {
            Set<String> eventNames = new Set<String> {'Party', 'Whiskey Tasting', 'Fundraiser'};
            List<Event__c> events = [SELECT Id FROM Event__c WHERE Status__c = 'Closed/Posted' and Name IN :eventNames];
            List<Line_Item__c> lineItemsToDelete = [SELECT Id FROM Line_Item__c WHERE Reservation_Line__c IN :events];
            try {
                Test.startTest();
                delete lineItemsToDelete;
                Test.stopTest();
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Closed/Posted. If you wish to make changes, you must re-open your event.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    @isTest static void TestEventStatusCancelledOnDelete() {
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser) {
            Set<String> eventNames = new Set<String> {'New Year Celebration', 'Wine Tasting', 'Smoker'};
            List<Event__c> events = [SELECT Id FROM Event__c WHERE Status__c = 'Cancelled' and Name IN :eventNames];
            List<Line_Item__c> lineItemsToDelete = [SELECT Id FROM Line_Item__c WHERE Reservation_Line__c IN :events];
            try {
                Test.startTest();
                delete lineItemsToDelete;
                Test.stopTest();
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('This event is Cancelled. You can no longer make changes.');
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
    }

    /**
    *@description: Following method contains the testCode for adding a line item to the event including the taz
    *and service charge auto calculation
    **/
    @isTest static void TestAddLineItem() {


        Location__c location = new Location__c(Name = 'Garden');
        insert location;

        TxnChargeToTaxMapping__c taxObj = TxnTestUtility.getTaxMapping('Bar','Other');
        Charge_Item__c chargeItem1 = new Charge_Item__c(Name = 'Cocktail', Type__c = 'Bar', SubType__c='Other', Price__c = 15.00);
        insert chargeItem1;

        Account act = TestHandler.getAccount('Household');    
        Contact contact = new Contact(RecordTypeId=Utility.searchRecordType('Member', 'Contact'), FirstName='Test',Suffix__c = 'TestContact',LastName='TestContact',Relationship__c ='Dependent',AccountId=act.Id,Title__c = 'TestContact',Email='test@test.com');
        insert contact;

        Event__c event = new Event__c();
        event.Name = 'Test Event';
        event.Location__c = location.id;
        event.Status__c = 'Tentative';
        event.Sponsoring_Customer__c = contact.id;
        event.SponsoringMember__c = contact.Id;
        event.StartTime__c = System.now();
        event.EndTime__c = System.now().addHours(2);
        event.Setup_Time__c = 'Half Hour';
        event.Cleanup_Time__c = 'Half Hour';
        event.Contract_Due_Date__c = System.today();
        event.Max_Seats__c = 20;
        insert event;

        Test.startTest();
        Line_Item__c lineItem1 = new Line_Item__c();
        lineItem1.Charge_Item__c = chargeItem1.Id; 
        lineItem1.Qty__c = 10;
        lineItem1.Reservation_Line__c = event.Id;
        insert lineItem1;
        update lineItem1;
        
        Test.stopTest();        
    }
}