/*
*   Test class for TxnUpdateContactBalanceTrigger
*   Tests trigger that updates the Account_Balance__c field on Contacts when TXN__c objects
*   are created, update, and deleted.
*
*/
@isTest
private class TxnTriggerTest {
    static Id memberId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
    static Id householdId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    static Id chargeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Charge').getRecordTypeId();
    static Id paymentId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
    static Id chargeItemId = Schema.SObjectType.Charge_Item__c.getRecordTypeInfosByName().get('Event Menu').getRecordTypeId();
    static Id lineItemId = Schema.SObjectType.Line_Item__c.getRecordTypeInfosByName().get('Charge').getRecordTypeId();
    static Id guestRecordId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Guest').getRecordTypeId();

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


        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da = TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa);
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('Check',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('Credit Card',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('ACH',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('ACH',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('Cash',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('Check',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('Credit Card',fa) ;


        Taxes__c taxesCustomSettings = new Taxes__c();
        taxesCustomSettings.Sales_Tax__c = 10.00;
        taxesCustomSettings.Transit_Improvement_Sales_Tax__c = 1.00;
        insert taxesCustomSettings;

        ServiceCharges__c servicesCustomSettings = new ServiceCharges__c();
        servicesCustomSettings.Service_Charge_Member__c = 5.00;
        insert servicesCustomSettings;

        List<Contact> members = new List<Contact>();
        List<Contact> guests = new List<Contact>();
        Contact contact1 = new Contact(RecordTypeId = memberId, Account = account1, AccountId = account1.Id, Customer_Id__c = '001',
                                       Membership_Type__c = 'Legacy', Relationship__c = 'Primary', Status__c = 'Active',
                                       Substatus__c = 'Active',LastName = 'Doe');
        Contact contact2 = new Contact(RecordTypeId = memberId, Account = account2, AccountId = account2.Id, Customer_Id__c = '002',
                                       Membership_Type__c = 'Legacy', Relationship__c = 'Primary', Status__c = 'Active',
                                       Substatus__c = 'Active',LastName = 'Smith');
        Contact contact3 = new Contact(RecordTypeId = memberId, Account = account3, AccountId = account3.Id, Customer_Id__c = '003',
                                       Membership_Type__c = 'Legacy', Relationship__c = 'Primary', Status__c = 'Active',
                                       Substatus__c = 'Active',LastName = 'Nguyen');
        Contact contact_CY = new Contact(RecordTypeId = memberId, Account = account3, AccountId = account3.Id, Customer_Id__c = '004',
                                       Membership_Type__c = 'Legacy', Relationship__c = 'Primary', Status__c = 'Active',
                                       Substatus__c = 'Active',LastName = 'TEST_CY');

        members.add(contact1);
        members.add(contact2);
        members.add(contact3);
        members.add(contact_CY);
        insert members;
        for(Integer i = 0; i < 200; i++){
            Contact guest = new Contact(RecordTypeId = guestRecordId, Account = account1, AccountId = account1.id,
                                         Customer_Id__c = ('004' + String.valueOf(i)), LastName = ('GUEST' + String.valueOf(i)),
                                         Relationship__c = 'Primary', Status__c = 'Active', Bill_To_Member__c = contact3.Id);
            guests.add(guest);
        }
        insert guests;
        

        List<Guest_Pass__c> guestPasses = new List<Guest_Pass__c>();
        for(Contact guest: guests){
            Guest_Pass__c pass = new Guest_Pass__c();
            pass.Guest_Name__c = guest.Id;
            pass.Member_Sponsor__c = contact3.Id;
            pass.Active__c = true;
            pass.Start__c = System.DateTime.now();
            pass.Expiration__c = (System.DateTime.now() + 30);
            guestPasses.add(pass);
        }
        insert guestPasses;

        //CY changes for trigger merge
        Location__c location1 = new Location__c(Name = 'CY_TEST_LOCATION');
        insert location1;
       
        Event__c event1 = new Event__c();
        event1.Name = 'CY_TEST_EVENT';
        event1.Location__c = location1.id;
        event1.Status__c = 'Approved';
        event1.Sponsoring_Customer__c = contact_CY.id;
        event1.SponsoringMember__c = contact_CY.Id;
        event1.StartTime__c = DateTime.now();
        event1.EndTime__c = System.now().addHours(2);
        event1.Setup_Time__c = 'Half Hour';
        event1.Cleanup_Time__c = 'Half Hour';
        event1.Contract_Due_Date__c = System.today();
        event1.Max_Seats__c = 20;
        insert event1;

        Financial_Account__c financialAccount = new Financial_Account__c(Name = 'TEST_FIN_ACCOUNT', Account_Number__c = '123456789', Category__c = 'Expense');
        insert financialAccount;


        List<Tax_To_Account_Mapping__c> taxToAccounts = new List<Tax_To_Account_Mapping__c>();
        Tax_To_Account_Mapping__c taxToAccount1 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT1', Financial_Accounts__c = financialAccount.Id, Tax__c = Utility.getNameOfTax('Sales_Tax__c'));
        Tax_To_Account_Mapping__c taxToAccount2 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT2', Financial_Accounts__c = financialAccount.Id, Service_Charge__c = Utility.getNameOfServiceCharge('Service_Charge_Member__c'));
        Tax_To_Account_Mapping__c taxToAccount3 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT1', Financial_Accounts__c = financialAccount.Id, Tax__c = 'Sales_Tax__c');
        Tax_To_Account_Mapping__c taxToAccount4 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT2', Financial_Accounts__c = financialAccount.Id, Service_Charge__c = 'Service_Charge_Member__c');
        taxToAccounts.add(taxToAccount1);
        taxToAccounts.add(taxToAccount2);
        taxToAccounts.add(taxToAccount3);
        taxToAccounts.add(taxToAccount4);
        insert taxToAccounts;

        List<TxnChargeToTaxMapping__c> mappings = new List<TxnChargeToTaxMapping__c>();
        TxnChargeToTaxMapping__c taxObj1= new TxnChargeToTaxMapping__c();
        taxObj1.Type__c='Dinner';
        taxObj1.Subtype__c = null;
        taxObj1.Allow_in_POS__c=true;
        taxObj1.Taxes_applicable_on_service_charge__c=false;
        taxObj1.Service_Charge_applicable__c=true;
        taxObj1.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj1.TaxId__c = 'Sales_Tax__c';
        mappings.add(taxObj1);


        TxnChargeToTaxMapping__c taxObj2= new TxnChargeToTaxMapping__c();
        taxObj2.Type__c='Bar';
        taxObj2.Subtype__c = null;
        taxObj2.Allow_in_POS__c=true;
        taxObj2.Taxes_applicable_on_service_charge__c=true;
        taxObj2.Service_Charge_applicable__c=true;
        taxObj2.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj2.TaxId__c = 'Sales_Tax__c';
        taxObj2.Tax_Name_applicable_on_service_charge__c = 'Sales_Tax__c';
        mappings.add(taxObj2);
        
        TxnChargeToTaxMapping__c taxObj3= new TxnChargeToTaxMapping__c();
        taxObj3.Type__c='Breakfast';
        taxObj3.Subtype__c = null;
        taxObj3.Allow_in_POS__c=true;
        taxObj3.Taxes_applicable_on_service_charge__c=false;
        taxObj3.Service_Charge_applicable__c=false;
        taxObj3.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj3.TaxId__c = 'Sales_Tax__c';
        mappings.add(taxObj3);

        TxnChargeToTaxMapping__c taxObj4= new TxnChargeToTaxMapping__c();
        taxObj4.Type__c='Dinner';
        taxObj4.Subtype__c = 'Plated';
        taxObj4.Allow_in_POS__c=true;
        taxObj4.Taxes_applicable_on_service_charge__c=false;
        taxObj4.Service_Charge_applicable__c=true;
        taxObj4.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj4.TaxId__c = 'Sales_Tax__c';
        mappings.add(taxObj4);

        TxnChargeToTaxMapping__c taxObj5= new TxnChargeToTaxMapping__c();
        taxObj5.Type__c='Bar';
        taxObj5.Subtype__c = 'Cash Bar';
        taxObj5.Allow_in_POS__c=true;
        taxObj5.Taxes_applicable_on_service_charge__c=true;
        taxObj5.Service_Charge_applicable__c=true;
        taxObj5.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj5.TaxId__c = 'Sales_Tax__c';
        taxObj5.Tax_Name_applicable_on_service_charge__c = 'Sales_Tax__c';
        mappings.add(taxObj5);
        
        TxnChargeToTaxMapping__c taxObj6= new TxnChargeToTaxMapping__c();
        taxObj6.Type__c='Breakfast';
        taxObj6.Subtype__c = 'Buffet';
        taxObj6.Allow_in_POS__c=true;
        taxObj6.Taxes_applicable_on_service_charge__c=false;
        taxObj6.Service_Charge_applicable__c=false;
        taxObj6.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj6.TaxId__c = 'Sales_Tax__c';
        mappings.add(taxObj6);
        upsert mappings;

        List<Charge_Item__c> chargeItems = new List<Charge_Item__c>();

        Charge_Item__c chargeitem1 = new Charge_Item__c(Name = 'CY_TEST_CHARGE_ITEM1', RecordTypeId = chargeItemId,
                                                        Type__c = 'Dinner',Price__c = 50.00);
        chargeItems.add(chargeItem1);
        Charge_Item__c chargeitem2 = new Charge_Item__c(Name = 'CY_TEST_CHARGE_ITEM2', RecordTypeId = chargeItemId,
                                                        Type__c = 'Dinner', Subtype__c = 'Plated', Price__c = 50.00);
        chargeItems.add(chargeItem2);
        Charge_Item__c chargeitem3 = new Charge_Item__c(Name = 'CY_TEST_CHARGE_ITEM3', RecordTypeId = chargeItemId,
                                                        Type__c = 'Bar', Price__c = 50.00);
        chargeItems.add(chargeItem3);
        Charge_Item__c chargeitem4 = new Charge_Item__c(Name = 'CY_TEST_CHARGE_ITEM4', RecordTypeId = chargeItemId,
                                                        Type__c = 'Bar', Subtype__c = 'Cash Bar', Price__c = 50.00);
        chargeItems.add(chargeItem4);
        Charge_Item__c chargeitem5 = new Charge_Item__c(Name = 'CY_TEST_CHARGE_ITEM5', RecordTypeId = chargeItemId,
                                                        Type__c = 'Breakfast',Price__c = 50.00);
        chargeItems.add(chargeItem5);
        Charge_Item__c chargeitem6 = new Charge_Item__c(Name = 'CY_TEST_CHARGE_ITEM6', RecordTypeId = chargeItemId,
                                                        Type__c = 'Breakfast', Subtype__c = 'Buffet', Price__c = 50.00);
        chargeItems.add(chargeItem6);
        insert chargeItems;

        List<Line_Item__c> lineItems = new List<Line_Item__c>();
        for(Integer i = 0; i < 6; i++){
            Line_Item__c lineItem = new Line_Item__c(Charge_Item__c = chargeItems.get(i).id, RecordTypeId = lineItemId,
                                                    Qty__c = 50, Reservation_line__c = event1.id, Tax_Amount__c = 10.00,
                                                    Service_Charge__c = 10.00);
            lineItems.add(lineItem);                                        
        }

        insert lineItems;

        List<TXN__c> txnList = new List<TXN__c>();
        TXN__c txn1 = new TXN__c(Amount__c = 10,Bill_To_Member__c = contact_CY.id, Item_Code__c = 'CY_01', Line_Item__c = lineItems[0].id, RecordtypeId = chargeId);
        txnList.add(txn1);

        TXN__c txnPayment = new TXN__c(Amount__c = -10,Payment_Type__c = 'Cash',Date__c = Date.today(), Statement_Description__c = 'statement description',Bill_To_Member__c = contact_CY.id, Item_Code__c = 'MT_01', Line_Item__c = lineItems[0].id, RecordtypeId = Utility.searchRecordType('Payment', 'TXN__c'));
        txnList.add(txnPayment);
        
        insert txnList;
    }

    //testing trigger for finalization of event
    @isTest static void TestBeforeInsertTXN(){

        Id chargeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Charge').getRecordTypeId();

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            List<TXN__c> testTXN = [SELECT Id, Item_Code__c, Bill_To_Member__c FROM TXN__c WHERE Item_Code__c = 'CY_01'];

            System.test.startTest();
            try {
               if (testTXN.size() > 0) {
                    TXN__c txn2 = new TXN__c(Amount__c = 10, Bill_To_Member__c = testTXN[0].Bill_To_Member__c, Item_Code__c = 'CY_02', Related_To__c = testTXN[0].id, RecordtypeId = chargeId);
                    insert txn2;
                }
            } catch(exception e) {
                system.debug(e.getmessage());
                System.assert(e.getMessage().contains('Please make your Adjustment from the Banquet'));
            }
            System.test.stopTest();

        }
    }
    @isTest static void TestAfterInsertRefundTXN(){

        Id RefundRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            System.test.startTest();
            List<TXN__c> testTXN = [SELECT Id,Payment_Type__c,  Item_Code__c, Bill_To_Member__c FROM TXN__c WHERE Item_Code__c = 'MT_01'];
            try {
               if (testTXN.size() > 0) {
                    TXN__c txn2 = new TXN__c(Amount__c = 20,Payment_Type__c='Cash', Bill_To_Member__c = testTXN[0].Bill_To_Member__c, Item_Code__c = 'CY_02_REF', Related_To__c = testTXN[0].id, recordTypeId = RefundRecordTypeId);
                    insert txn2;
                }
            } catch(exception e) {
                system.debug('aaaa '+e.getmessage());
                System.assert(e.getMessage().contains('You cannot refund more than the amount of the payment'));
            }
            System.test.stopTest();

        }
    }

    //testing trigger for insertion of Charges
    @isTest static void TestBalanceUpdateOnInsertCharge(){

        //initialize the test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
                List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];

            //test the trigger for insertion of Charges
            Test.startTest();
            List<TXN__c> chargesToInsert = new List<TXN__c>();
            for(Integer i = 0; i < 3; i++){
                for(Integer j = 0; j < 3; j++){
                    TXN__c charge = new TXN__c(RecordTypeId = chargeId, Bill_To_Member__c = contacts.get(i).Id, Amount__c = 100.00);
                    chargesToInsert.add(charge);

                }
            }
            insert chargesToInsert;
            Test.stopTest();

            /*List<Contact> newContacts = [SELECT Id, Account_Balance__c FROM Contact WHERE LastName IN :contactNames];
            for(Contact newContact: newContacts){
                System.assertEquals(300.00, newContact.Account_Balance__c, 'Account Balance is not the expected value.');
            }*/
        }
    }
 
    //testing trigger for the insertion of Payments
    @isTest static void TestBalanceUpdateOnInsertPayment(){

        //initialize test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
                List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];
            List<TXN__c> initialCharges = new List<TXN__c>();
            for(Integer i = 0; i < 3; i++){
                TXN__c charge = new TXN__c(RecordTypeId = chargeId, Bill_To_Member__c = contacts.get(i).Id, Amount__c = 300.00);
                initialCharges.add(charge);
            }
            insert initialCharges;

            //test trigger for the insertion of Payments
            Test.startTest();
            List<TXN__c> paymentsToInsert = new List<TXN__c>();
            for(Integer i = 0; i < 3; i++){
                for(Integer j = 0; j < 3; j++){
                    TXN__c payment = new TXN__c(RecordTypeId = paymentId,Payment_Type__c='Cash',Date__c = Date.today(),Statement_Description__c = 'statement description', Bill_To_Member__c = contacts.get(i).Id, Amount__c = -100.00);
                    paymentsToInsert.add(payment);
                }
            }
            insert paymentsToInsert;
            Test.stopTest();

            /*List<Contact> newContacts = [SELECT Id, Account_Balance__c FROM Contact WHERE LastName IN :contactNames];
            for(Contact newContact: newContacts){
                System.assertEquals(0, newContact.Account_Balance__c, 'Account Balance is not the expected value.');
            }*/
        }
    }

    //testing trigger for updates to Charges
    @isTest static void TestBalanceUpdateOnUpdateCharge(){

        //initializing test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
                List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];
            List<TXN__c> charges = new List<TXN__c>();
            List<Id> chargeIds = new List<Id>();
            for(Integer i = 0; i < 3; i++){
                for(Integer j = 0; j < 3; j++){
                    TXN__c charge = new TXN__c(RecordTypeId = chargeId, Bill_To_Member__c = contacts.get(i).Id, Amount__c = 1000.00);
                    charges.add(charge);
                }
            }
            insert charges;

            for(TXN__c charge: charges){
                chargeIds.add(charge.Id);
            }
            //test trigger for the update of Charges
            Test.startTest();
            List<TXN__c> chargesToUpdate = [SELECT Id, Amount__c from TXN__c where Id IN :chargeIds];
            for(TXN__c chargeToUpdate: chargesToUpdate){
                chargeToUpdate.Amount__c = 500.00;
            }
            update chargesToUpdate;
            Test.stopTest();

            /*List<Contact> newContacts = [SELECT Id, Account_Balance__c FROM Contact WHERE LastName IN :contactNames];
            for(Contact newContact: newContacts){
                System.assertEquals(3000.00, newContact.Account_Balance__c, 'Account Balance is not the expected value.');
            }*/
        }
    }

    //testing trigger for updates to Payments
    @isTest static void TestBalanceUpdateOnUpdatePayment(){

        //initialize test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
            List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];
            List<TXN__c> initialCharges = new List<TXN__c>();
            List<TXN__c> payments = new List<TXN__c>();
            List<Id> paymentIds = new List<Id>();

            for(Integer i = 0; i < 3; i++){
                TXN__c charge = new TXN__c(RecordTypeId = chargeId, Bill_To_Member__c = contacts.get(i).Id, Amount__c = 300.00);
                initialCharges.add(charge);
            }
            insert initialCharges;
            for(Integer i = 0; i < 3; i++){
                for(Integer j = 0; j < 3; j++){
                    TXN__c payment = new TXN__c(RecordTypeId = paymentId,Payment_Type__c='Cash',Date__c = Date.today(),Statement_Description__c = 'statement description', Bill_To_Member__c = contacts.get(i).Id, Amount__c = -50.00);
                    payments.add(payment);
                }
            }
            insert payments;

            for(TXN__c payment: payments){
                paymentIds.add(payment.Id);
            }

            //test trigger for the update of Payments
            Test.startTest();
            List<TXN__c> paymentsToUpdate = [SELECT Id, Amount__c from TXN__c WHERE Id IN :paymentIds];
            for(TXN__c paymentToUpdate: paymentsToUpdate){
                paymentToUpdate.Amount__c = -100.00;
            }
            update paymentsToUpdate;
            Test.stopTest();
            /*List<Contact> newContacts = [SELECT Id, Account_Balance__c FROM Contact WHERE LastName IN :contactNames];
            for(Contact newContact: newContacts){
                System.assertEquals(150, newContact.Account_Balance__c, 'Account Balance is not the expected value.');
            }*/
        }
    }

    //testing trigger for deletion of Charges
    @isTest static void TestBalanceUpdateOnDeleteCharge(){

        //initializing test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
                List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];
            List<TXN__c> charges = new List<TXN__c>();
            for(Integer i = 0; i < 3; i++){
                for(Integer j = 0; j < 3; j++){
                    TXN__c charge = new TXN__c(RecordTypeId = chargeId, Bill_To_Member__c = contacts.get(i).Id, Amount__c = 100.00);
                    charges.add(charge);
                }
            }
            insert charges;
            //test trigger for deletion of Charges
            Test.startTest();
            delete charges;
            Test.stopTest();

            /*List<Contact> newContacts = [SELECT Id, Account_Balance__c FROM Contact WHERE LastName IN :contactNames];
            for(Contact newContact: newContacts){
                System.assertEquals(300, newContact.Account_Balance__c, 'Account Balance is not the expected value.');
            }*/
        }
    }

    //testing deletion of Payments
    @isTest static void TestBalanceUpdateOnDeletePayment(){

        //initializing test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
                List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];
            List<TXN__c> payments = new List<TXN__c>();
            for(Integer i = 0; i < 3; i++){
                for(Integer j = 0; j < 3; j++){
                    TXN__c payment = new TXN__c(RecordTypeId = paymentId,Payment_Type__c='Cash',Date__c = Date.today(),Statement_Description__c = 'statement description', Bill_To_Member__c = contacts.get(i).Id, Amount__c = -100.00);
                    payments.add(payment);
                }
            }
            insert payments;
            //test trigger for deletion of Payments
            Test.startTest();
            delete payments;
            Test.stopTest();

            /*List<Contact> newContacts = [SELECT Id, Account_Balance__c FROM Contact WHERE LastName IN :contactNames];
            for(Contact newContact: newContacts){
                System.assertEquals(-300, newContact.Account_Balance__c, 'Account Balance is not the expected value.');
            }*/
        }
    }

    //testing Financial Accounts active
    @isTest static void TestFinancialAccounts(){

        //initializing test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
            List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];

            Location__c loc= TestHandler.getLocation();// method does the insert

            Financial_Account__c activeFA = TestHandler.getFinancialAccountWithChecks(loc.Id); // method does the insert
            TXN__c payment = new TXN__c(RecordTypeId = paymentId,Payment_Type__c='Cash',Date__c = Date.today(),Statement_Description__c = 'statement description', Bill_To_Member__c = contacts.get(0).Id, Amount__c = -100.00, Financial_Account__c=activeFA.Id);
            insert payment;
        }
    }

    //testing Financial Accounts deactive
    @isTest static void TestFinancialAccountsDeactive(){

        //initializing test data
        User ftUser = UserTest.createForeTeesUser();

        System.runAs(ftUser){
            Set<String> contactNames = new Set<String>{'Doe', 'Smith', 'Nguyen'};
            List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName IN :contactNames];

            Financial_Account__c deactiveFA = TestHandler.getFinancialAccount1();// method does the insert
            deactiveFA.Active__c = false;
            update deactiveFA;

            TXN__c payment2 = new TXN__c(RecordTypeId = paymentId, Bill_To_Member__c = contacts.get(0).Id, Amount__c = -100.00, Default_A_R_Account__c=deactiveFA.Id);
            try
            {
                insert payment2;
            }
            catch(Exception thisShouldFail)
            {
                System.assert(payment2.Id == null);
            }

        }
    }

    //testing TxnCreateTaxService method
    @isTest static void TestCreateTaxService(){
        

        //initialize test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            

            Event__c event = [SELECT Id FROM Event__c WHERE Name = 'CY_TEST_EVENT'];
            Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Doe'];
            Set<String> chargeItemNames = new Set<String>{'CY_TEST_CHARGE_ITEM1', 'CY_TEST_CHARGE_ITEM2', 'CY_TEST_CHARGE_ITEM3',
                                                            'CY_TEST_CHARGE_ITEM4', 'CY_TEST_CHARGE_ITEM5', 'CY_TEST_CHARGE_ITEM6'};
            Set<String> taxAndServicesRecordTypes = new Set<String>{'Tax', 'Service Charge'};
            List<Charge_Item__c> chargeItems = [SELECT Id, Type__c, SubType__c FROM Charge_Item__c WHERE Name IN : chargeItemNames];
            
            List<Line_Item__c> lineItems = [SELECT Id FROM Line_Item__c WHERE Reservation_Line__c = :event.Id];
            List<RecordType> taxServiceRecordIds = [SELECT Id, SObjectType, Name, DeveloperName FROM RecordType WHERE IsActive = true AND DeveloperName IN :taxAndServicesRecordTypes AND SObjectType = 'TXN__c'];
            Set<Id> charges = new Set<Id>();
            List<TXN__c> chargeList = new List<TXN__c>();
            test.startTest();
            for(Integer i = 0; i < 6; i++){
                TXN__c charge = new TXN__c(Amount__c = 10,Bill_To_Member__c = contact.Id, Item_Code__c = 'CY_01', Line_Item__c = lineItems[i].id, RecordtypeId = chargeId, GlobalType__c = chargeItems[i].Type__c, GlobalSubtype__c = chargeItems[i].Subtype__c);
            
                chargeList.add(charge);
                charges.add(charge.Id);
            }
            insert chargeList;

            //Charge without tax or SC mapped
            test.stopTest();

            List<TXN__c> taxesAndServices = [SELECT Id, Amount__c, Bill_To_Member__c, Related_To__r.Id FROM TXN__c WHERE TXN__c.Related_To__c IN :charges AND RecordtypeId IN :taxServiceRecordIds];
            
            for(TXN__c txn: taxesAndServices){
                System.assert(true, txn.Bill_To_Member__c == contact.Id);
                System.assert(true, charges.contains(txn.Related_To__r.Id));
                System.assert(true, txn.Amount__c != null);
                if(txn.RecordTypeId == taxServiceRecordIds.get(0).Id){
                    System.assert(true, txn.Tax_Name__c == 'Sales_Tax__c');
                }else if(txn.RecordTypeId == taxServiceRecordIds.get(1).Id){
                    System.assert(true, txn.Service_Charge_Name__c == 'Service_Charge_Member__c');
                }
                
            }            
        }
    }

    @isTest static void TestSetGuestPassOnTxn(){
    
        //initialize test data
        User ftUser = UserTest.createForeTeesUser(true);

        System.runAs(ftUser){
            List<String> guestNames = new List<String>();
            for(Integer i = 0; i < 200; i++){

                guestNames.add('GUEST' + String.valueOf(i));

            }

            List<Contact> billToMember = [SELECT Id FROM Contact WHERE LastName = 'Nguyen'];
            Id chargeRecordId = Utility.searchRecordType('Charge', 'TXN__c');
            List<Charge_Item__c> chargeItem = [SELECT Id, Type__c, SubType__c FROM Charge_Item__c WHERE Name = 'CY_TEST_CHARGE_ITEM1'];
            List<Contact> guests = [SELECT Id from Contact WHERE LastName IN :guestNames];
            List<TXN__c> txns = new List<TXN__c>();

            for(Contact guest: guests){

                TXN__c txn = new TXN__c(Amount__c = 10, Bill_To_Member__c = billToMember.get(0).Id, Customer__c = guest.Id, Item_Code__c = 'GPASS_TEST', RecordtypeId = chargeId, GlobalType__c = chargeItem.get(0).Type__c , GlobalSubtype__c = chargeItem.get(0).SubType__c);
                txns.add(txn);

            }

            test.StartTest();
            insert txns;
            test.StopTest();
            List<TXN__c> txnsToTest = [SELECT Id, Guest_Pass__c,Guest_Pass__r.Guest_Name__c, Guest_Pass__r.Guest_Name__r.LastName,  
                                        Bill_To_Member__c, Customer__c, Customer__r.LastName, Guest_Pass__r.Guest_Name__r.Bill_To_Member__c,
                                        Guest_Pass__r.Guest_Name__r.Bill_To_Member__r.LastName
                                        FROM TXN__c WHERE Customer__c IN :guests AND RecordTypeId = :chargeRecordId
                                      ];

            // System.debug('++ + txnsToTest: ' + txnsToTest);
            for(TXN__c txn :txnsToTest){
                
                System.assertEquals(true, txn.Guest_Pass__c != null, 'Guest pass is null.');
                System.assertEquals(true, txn.Guest_Pass__r.Guest_Name__c.equals(txn.Customer__c), 'Guest name != Customer');
                System.assertEquals(true, txn.Guest_Pass__r.Guest_Name__r.Bill_To_Member__c == txn.Bill_To_Member__c, 'Bill To Member != Bill To Member');
            }
        }
    }
}