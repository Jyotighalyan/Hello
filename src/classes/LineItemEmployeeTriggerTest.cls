@isTest
private class LineItemEmployeeTriggerTest {
    
    private static testmethod void testAllocatingGratuities()
    {
        Location__c loc = new Location__c();
        loc.Name = 'Test Location';
        insert loc;
        
        Event__c evt = TestHandler.getEvent();

        TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Cash';
        taxObj.Subtype__c = null;
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=false;
        insert taxObj;
        
        Charge_Item__c ci = new Charge_Item__c();
        ci.Name = 'Test Charge Item';
        ci.Type__c = 'Cash';
        ci.Price__c = 100;
        insert ci;
        
        Line_Item__c eci = new Line_Item__c();
        eci.Charge_Item__c = ci.id;
        eci.Qty__c = 1;
        eci.Reservation_line__c = evt.id;
        eci.Price__c = 100;
        insert eci;
        
        Line_Item_Employee__c split1 = new Line_Item_Employee__c();
        split1.Line_Item__c = eci.id;
        split1.Split_Amount__c = 50;
        insert split1;
        
        Line_Item_Employee__c split2 = new Line_Item_Employee__c();
        split2.Line_Item__c = eci.id;
        split2.Split_Amount__c = 50;
        insert split2;
        
        for(Line_Item_Employee__c lineItemEmployee:[Select id, Split_Amount__c from Line_Item_Employee__c])
        {
            system.assertequals(50,lineItemEmployee.Split_Amount__c);
        }
        
        split2.Split_Amount__c = 25;
        update split2;
    }
    
    private static testmethod void testOverAllocatingGratuities()
    {
        Location__c loc = new Location__c();
        loc.Name = 'Test Location';
        insert loc;
        
        Event__c evt = TestHandler.getEvent();

        TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Cash';
        taxObj.Subtype__c = null;
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=false;
        insert taxObj;
        
        Charge_Item__c ci = new Charge_Item__c();
        ci.Name = 'Test Charge Item';
        ci.Type__c = 'Cash';
        ci.Price__c = 100;
        insert ci;
        
        Line_Item__c eci = new Line_Item__c();
        eci.Charge_Item__c = ci.id;
        eci.Qty__c = 1;
        eci.Reservation_line__c = evt.id;
        eci.Price__c = 100;
        insert eci;
        
        List<Line_Item_Employee__c> splitsToInsert = new List<Line_Item_Employee__c>();
        Line_Item_Employee__c split1 = new Line_Item_Employee__c();
        split1.Line_Item__c = eci.id;
        split1.Split_Amount__c = 50;
        splitsToInsert.add(split1);
        
        Line_Item_Employee__c split2 = new Line_Item_Employee__c();
        split2.Line_Item__c = eci.id;
        split2.Split_Amount__c = 75;
        splitsToInsert.add(split2);
        
        try{  
            insert splitsToInsert;
        }
        catch(Exception e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Your split amounts are greater than your charge item total. Please update your split amount and click save.');
            System.assertEquals(expectedExceptionThrown, true);
        } 
        
    }
    
    @isTest static void TestEventUpdateOnInsert(){
        
        Id clubId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Home Club').getRecordTypeId();
        Id employeeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        
        User ftUser = UserTest.createForeTeesUser();
        
        System.runAs(ftUser){
            Account account = new Account(RecordTypeId = clubId, Name = 'Doe');
            insert account;
            Contact contact = new Contact(RecordTypeId = employeeId, Account = account, AccountId = account.Id, Customer_Id__c = '001',
                                          Membership_Type__c = 'Legacy', Relationship__c = 'Primary', Status__c = 'Active', 
                                          Substatus__c = 'Active', LastName = 'Doe');
            insert contact;
            Location__c location = new Location__c(Name = 'Patio');
            insert location;
            List<Event__c> events = new List<Event__c>();
            Event__c event1 = TestHandler.getEvent();
            event1.Name = 'Party';
            update event1; 
            
            Event__c event2= TestHandler.getEvent();
            event2.Name = 'Wedding';
            update event2;
            
            Event__c event3 = TestHandler.getEvent();
            event3.Name = 'Fundraiser';
            update event3;                       

            TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
            taxObj.Type__c='Bar';
            taxObj.Subtype__c = null;
            taxObj.Allow_in_POS__c=true;
            taxObj.Taxes_applicable_on_service_charge__c=false;
            taxObj.Service_Charge_applicable__c=false;
            insert taxObj;
            
            List<Charge_Item__c> chargeItems = new List<Charge_Item__c>();
            Charge_Item__c chargeItem1 = new Charge_Item__c(Name = 'Cocktail', Type__c = 'Bar', Price__c = 15.00);
            Charge_Item__c chargeItem2 = new Charge_Item__c(Name = 'Beer', Type__c = 'Bar', Price__c = 15.00);
            Charge_Item__c chargeItem3 = new Charge_Item__c(Name = 'Wine', Type__c = 'Bar', Price__c = 15.00);
            chargeItems.add(chargeItem1);
            chargeItems.add(chargeItem2);
            chargeItems.add(chargeItem3);
            insert chargeItems;
            List<Line_Item__c> lineItems = new List<Line_Item__c>();
            Line_Item__c lineItem1 = new Line_Item__c(Charge_Item__c = chargeItem1.Id, Qty__c = 50, Reservation_Line__c = event1.Id);
            Line_Item__c lineItem2 = new Line_Item__c(Charge_Item__c = chargeItem2.Id, Qty__c = 100, Reservation_Line__c = event2.Id);
            Line_Item__c lineItem3 = new Line_Item__c(Charge_Item__c = chargeItem3.Id, Qty__c = 75, Reservation_Line__c = event3.Id);
            lineItems.add(lineItem1);
            lineItems.add(lineItem2);
            lineItems.add(lineItem3);
            insert lineItems;
            
            Test.startTest();
            Set<Id> lineItemEmployeeIds = new Set<Id>();
            for(Integer i = 0; i < 3; i++){
                Line_Item_Employee__c lineItemEmployee = new Line_Item_Employee__c(Employee__c = contact.Id, Line_Item__c = lineItems.get(i).Id);
                lineItemEmployeeIds.add(lineItemEmployee.Id);
            }
            Test.stopTest();
            for(Line_Item_Employee__c newLineItemEmployee: [SELECT Id, Event__c FROM Line_Item_Employee__c WHERE Id IN :lineItemEmployeeIds]){
                if(events.iterator().hasNext()){
                    System.assertEquals(events.iterator().next().Id, newLineItemEmployee.Event__c); 
                }
            } 
        }    
    }
}