@isTest
public with sharing class TxnCreateChargeControllerTest
{
    public  Static String  AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public  Static String ContactMemberId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();

     @isTest
    static void createChargeTest()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);

        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');

        TxnChargeToTaxMapping__c taxObj = TxnTestUtility.getTaxMapping('Breakfast', 'Buffet');
        TxnTestUtility.mapFinancialAccountOnPassedTaxes(taxObj);
                
        Charge_Item__c ci = new Charge_Item__c();
        ci.Name = 'Test Charge Item';
        ci.Type__c = 'Breakfast';
        ci.SubType__c = 'Buffet';
        ci.Item_Code__c ='1234';
        ci.Description__c = 'Desc';
        ci.Price__c = 100;
        insert ci;

        TxnChargeToTaxMapping__c taxMapping = MappingAndTaxUtilityTest.createTaxMapping('Breakfast', 'Buffet'); // method inserts
        taxMapping.Service_Charge_Name__c = 'Banquet_Bar_Service_Charge__c';
        taxMapping.Service_Charge_applicable__c = true;
        TxnTestUtility.mapFinancialAccountOnPassedTaxes(taxMapping);
        update taxMapping;

        Financial_Account__c fa = TestHandler.getFinancialAccount1(); // method inserts

        Tax_To_Account_Mapping__c tam = new Tax_To_Account_Mapping__c();
        tam.Financial_Accounts__c = fa.Id;
        tam.Service_Charge__c = 'Banquet_Bar_Service_Charge__c';
        tam.Tax__c = 'Sales_Tax__c';
        tam.Service_Charge_Value__c = 'Value';
        tam.Tax_Value__c = 'Value';
        insert tam;

        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;

        txnCharge.selectedChargeItem = ci.Id;
        txnCharge.selectChargeItem();
        txnCharge.Charge_Amount = '50.0';
        txnCharge.nickName = 'save';
        txnCharge.save();

        Test.stopTest();
    }

    @isTest
    static void createChargeGuestTest()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);
        Contact dummyGuest = TxnTestUtility.createContact('Guest', 'Contact', 'Guest');
        dummyGuest.Sponsor_1_Name__c = dummyMember.Id;
        update dummyGuest;

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);

        System.currentPageReference().getParameters().put('ContactType', 'guest');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('memberId', dummyGuest.id);
        System.currentPageReference().getParameters().put('memberName', dummyGuest.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');

        TxnChargeToTaxMapping__c taxObj = TxnTestUtility.getTaxMapping('Breakfast', 'Buffet');
        
        Charge_Item__c ci = new Charge_Item__c();
        ci.Name = 'Test Charge Item';
        ci.Type__c = 'Breakfast';
        ci.SubType__c = 'Buffet';
        ci.Item_Code__c ='1234';
        ci.Description__c = 'Desc';
        ci.Price__c = 100;
        insert ci;

        TxnChargeToTaxMapping__c taxMapping = MappingAndTaxUtilityTest.createTaxMapping('Breakfast', 'Buffet'); // method inserts
        taxMapping.Service_Charge_Name__c = 'Banquet_Bar_Service_Charge__c';
        taxMapping.Service_Charge_applicable__c = true;
        update taxMapping;

        Financial_Account__c fa = TestHandler.getFinancialAccount1(); // method inserts

        Tax_To_Account_Mapping__c tam = new Tax_To_Account_Mapping__c();
        tam.Financial_Accounts__c = fa.Id;
        tam.Service_Charge__c = 'Banquet_Bar_Service_Charge__c';
        tam.Tax__c = 'Sales_Tax__c';
        tam.Service_Charge_Value__c = 'Value';
        tam.Tax_Value__c = 'Value';
        insert tam;

        String recTypeDefId = Utility.searchRecordType('Default', 'Default_Account__c');

        Default_Account__c tfm2 = new Default_Account__c();
        tfm2.Financial_Account__c = fa.Id;
        tfm2.Default_Type_Name__c = 'Account Receivable Default';
        tfm2.Financial_Account_Name_And_Number__c = 'Test 2';
        tfm2.RecordTypeId = recTypeDefId;
        insert tfm2;

        Payment_Gateway__c pg = new Payment_Gateway__c();
        pg.Default__c = true;
        pg.Production_URL__c = 'url';
        pg.Password_Encrypted__c = 'as';
        pg.Login_Encrypted__c = 'as';
        pg.Type__c = 'Dining';
        pg.Name = 'Authorize';
        insert pg;

        Payment_Method__c pm = new Payment_Method__c();
        pm.Payment_Type__c = 'Credit Card';
        pm.Customer__c = dummyGuest.Id;
        insert pm;

        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        txnCharge.selectedChargeItem = ci.Id;
        txnCharge.selectChargeItem();
        txnCharge.txn.Amount__c = 50.0;
        txnCharge.txn.Statement_Description__c = 'Testing charge Test';
        txnCharge.txn.Date__c = Date.today();
        txnCharge.nickName = 'save';
        txnCharge.paymentType = 'ACH';
        txnCharge.save();

        txnCharge.paymentType = 'Check';
        txnCharge.save();

        txnCharge.paymentType = 'Cash';
        txnCharge.save();

        txnCharge.paymentType = 'Credit Card';
        txnCharge.save();

        Test.stopTest();
    }

    @isTest
    static void existingChargeTest()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);
        
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;

        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = dummyMember.Id;
        charge.Bill_To_Member__c = dummyMember.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        TXN__c payment = new TXN__c();
        payment.RecordTypeId = Utility.searchRecordType('Payment', 'TXN__c');
        payment.Customer__c = dummyMember.Id;
        payment.Bill_To_Member__c = dummyMember.Id;
        payment.Status__c = 'Unpaid';
        payment.Posted__c = true;
        payment.Payment_Type__c='Cash';
        payment.Date__c = Date.today();
        payment.Statement_Description__c = 'statement description';
        payment.Amount__c = 0;
        payment.Amount_Remaining__c = 100;
        payment.Service_Charge__c = 0;
        payment.Tax__c = 0;
        payment.Charge_Amount_Left__c = 0;
        Data.create(payment);

        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('ChargeId', charge.Id);
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');
        TxnChargeToTaxMapping__c taxObj = TxnTestUtility.getTaxMapping('Breakfast', 'Buffet');
        TxnTestUtility.mapFinancialAccountOnPassedTaxes(taxObj);
        
        //TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        //taxObj.Type__c='Breakfast';
        //taxObj.Subtype__c = 'Buffet';
        //taxObj.Allow_in_POS__c=true;
        //taxObj.Taxes_applicable_on_service_charge__c=false;
        //taxObj.Service_Charge_applicable__c=false;
        //insert taxObj;

        //Taxes__c taxesCustomSettings = new Taxes__c();
        //taxesCustomSettings.Use_Tax__c = 1.00;
        //taxesCustomSettings.Sales_Tax__c = 1.00;
        //taxesCustomSettings.Transit_Improvement_Sales_Tax__c = 1.00;
        //taxesCustomSettings.Transit_Improvement_Use_Tax__c = 1.00;
        //insert taxesCustomSettings;

        Charge_Item__c ci = new Charge_Item__c();
        ci.Name = 'Test Charge Item';
        ci.Type__c = 'Breakfast';
        ci.SubType__c = 'Buffet';
        ci.Item_Code__c ='1234';
        ci.Description__c = 'Desc';
        ci.Price__c = 100;
        insert ci;

        //TxnChargeToTaxMapping__c taxMapping = MappingAndTaxUtilityTest.createTaxMapping('Breakfast', 'Buffet'); // method inserts
        //taxMapping.Service_Charge_Name__c = 'Service_Charge_Guest__c';
        //taxMapping.Service_Charge_applicable__c = true;
        //update taxMapping;

        fa = TestHandler.getFinancialAccount1(); // method inserts
        //Financial_Account__c fa = TestHandler.getFinancialAccount1(); // method inserts

        //Tax_To_Account_Mapping__c tam = new Tax_To_Account_Mapping__c();
        //tam.Financial_Accounts__c = fa.Id;
        //tam.Service_Charge__c = 'Service Charge Guest';
        //tam.Tax__c = 'Room Rental Occupancy Tax w/out Room';
        //tam.Service_Charge_Value__c = 'Value';
        //tam.Tax_Value__c = 'Value';
        //insert tam;

        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        txnCharge.selectedChargeItem = ci.Id;
        txnCharge.selectChargeItem();
        txnCharge.Charge_Amount = '50.0';
        txnCharge.nickName = 'save';
        txnCharge.save();

        Test.stopTest();
    }

    @isTest
    static void testAllPayments()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = dummyMember.Id;
        charge.Bill_To_Member__c = dummyMember.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('ChargeId', charge.Id);
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');

        //txn_payment_to_charge_mapping__c tpm = new txn_payment_to_charge_mapping__c();
        //tpm.amount_paid__c = 100;
        //tpm.Charge_Id__c = charge.Id;
        //tpm.Method__c = 'Payment';
        //tpm.Payment_Id__c = charge.Id;
        //insert tpm;

        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        txnCharge.insert_data_to_payment_to_charges_object(100, charge.Id, charge.Id);

        List<TxnCreateChargeController.tableRow> rows = txnCharge.allpayment;

        Test.stopTest();
    }

    @isTest
    static void testAllPaymentsCredit()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = dummyMember.Id;
        charge.Bill_To_Member__c = dummyMember.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('ChargeId', charge.Id);
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');

        Credit_Book__c cb = new Credit_Book__c();
        cb.Date__c = System.today();
        cb.Description__c = 'test';
       // cb.BalanceAmount__c = 100;
        cb.Credit_Amount__c = 1000;
        cb.Member_ID__c = dummyMember.id;
        insert cb;

        txn_payment_to_charge_mapping__c tpm = new txn_payment_to_charge_mapping__c();
        tpm.amount_paid__c = 100;
        tpm.Charge_Id__c = charge.Id;
        tpm.Method__c = 'Credit';
        tpm.Payment_Id__c = cb.Id;
        insert tpm;

        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        List<TxnCreateChargeController.tableRow> rows = txnCharge.allpayment;

        Test.stopTest();
    }

    @isTest
    static void testAllPaymentsOther()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = dummyMember.Id;
        charge.Bill_To_Member__c = dummyMember.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('ChargeId', charge.Id);
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');

        Credit_Book__c cb = new Credit_Book__c();
        cb.Date__c = System.today();
        cb.Description__c = 'test';
        //cb.BalanceAmount__c = 100;
        cb.Credit_Amount__c = 1000;
        cb.Member_ID__c = dummyMember.id;
        insert cb;

        txn_payment_to_charge_mapping__c tpm = new txn_payment_to_charge_mapping__c();
        tpm.amount_paid__c = 100;
        tpm.Charge_Id__c = charge.Id;
        tpm.Method__c = 'Other';
        tpm.Payment_Id__c = cb.Id;
        insert tpm;

        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        List<TxnCreateChargeController.tableRow> rows = txnCharge.allpayment;

        Test.stopTest();
    }

    @isTest
    static void testAllCharges()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = dummyMember.Id;
        charge.Bill_To_Member__c = dummyMember.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('ChargeId', charge.Id);
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');

        fa = TestHandler.getFinancialAccount(); // method inserts
        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        List<TxnCreateChargeController.atableRow> rows = txnCharge.allCharges;

        Test.stopTest();
    }

    @isTest
    static void testAllAdjustments()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnCreateCharge;
        Test.setCurrentPage(pageRef);
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = dummyMember.Id;
        charge.Bill_To_Member__c = dummyMember.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        TXN__c adjustment = new TXN__c();
        adjustment.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        adjustment.Customer__c = dummyMember.Id;
        adjustment.Bill_To_Member__c = dummyMember.Id;
        adjustment.Status__c = 'Unpaid';
        adjustment.Posted__c = true;
        adjustment.Amount__c = 10;
        adjustment.Service_Charge__c = 10;
        adjustment.Tax__c = 10;
        adjustment.Charge_Amount_Left__c = 12;
        Data.create(adjustment);

        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('ChargeId', charge.Id);
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');


        TxnCreateChargeController txnCharge = new TxnCreateChargeController();
        Test.startTest();

        List<TxnCreateChargeController.aTableAdjustment> rows = txnCharge.allAdjustments;

        Test.stopTest();
    }
}