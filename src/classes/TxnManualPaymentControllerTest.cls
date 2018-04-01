@isTest
private class TxnManualPaymentControllerTest {

    public Static String AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public Static String ContactMemberId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();

    public static Account account = TxnTestUtility.createAccount(AccountMemberId);
    public static Contact contact = TxnTestUtility.createMember(account, 'Primary', ContactMemberId);

    @isTest static void testGetSanitizedParam1() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String referrer = ApexPages.currentPage().getParameters().put('from', '\'badParam\'');

        Test.startTest();
            // get parameter
            String param = TxnManualPaymentController.getSanitizedParam('from');
        Test.stopTest();

        System.assertEquals(param, '\\\'badParam\\\'');
    }

    @isTest static void testGetSanitizedParam2() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String referrer = ApexPages.currentPage().getParameters().put('from', 'goodParam');

        Test.startTest();
            // get parameter
            String param = TxnManualPaymentController.getSanitizedParam('from');
        Test.stopTest();

        System.assertEquals(param, 'goodParam');
    }

    @isTest static void testGetCurrentPageLabel1() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String referrer = ApexPages.currentPage().getParameters().put('from', 'MemberPage');

        Test.startTest();
            // get label
            String ret = TxnManualPaymentController.getCurrentPageLabel();
        Test.stopTest();

        System.assertEquals(ret, 'New Payment');
    }

    // @isTest static void testGetCurrentPageLabel2() {
    //     Test.setCurrentPageReference(Page.TxnManualPayment);

    //     // set page params
    //     String referrer = ApexPages.currentPage().getParameters().put('from', 'Banquet');
    //     String reservationId = Apexpages.currentPage().getParameters().put('reservationId', 'abcd');

    //     Test.startTest();
    //         // get label
    //         String ret = TxnManualPaymentController.getCurrentPageLabel();
    //     Test.stopTest();

    //     System.assertEquals(ret, 'Deposit Page');
    // }

    @isTest static void testGetCurrentPageLabel3() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        // set page params
        String referrer = ApexPages.currentPage().getParameters().put('from', 'MemberPayment');

        Test.startTest();
            // get label
            String ret = TxnManualPaymentController.getCurrentPageLabel();
        Test.stopTest();

        System.assertEquals(ret, 'Payment Detail');
    }

    @isTest static void testGetCurrentPageLabel4() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String referrer = ApexPages.currentPage().getParameters().put('from', 'Charges');

        Test.startTest();
            // get label
            String ret = TxnManualPaymentController.getCurrentPageLabel();
        Test.stopTest();

        System.assertEquals(ret, 'Payment Detail');
    }

    // Default case
    @isTest static void testGetCurrentPageLabel5() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        Test.startTest();
            // get label
            String ret = TxnManualPaymentController.getCurrentPageLabel();
        Test.stopTest();

        System.assertEquals(ret, 'Payment Detail');
    }

    @isTest static void testGetPaymentId() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String param = ApexPages.currentPage().getParameters().put('paymentId', 'abcd');

        Test.startTest();
            // get id
            String ret = TxnManualPaymentController.getPaymentId();
        Test.stopTest();

        System.assertEquals(ret, 'abcd');
    }

    @isTest static void testGetRecordTypeOptions() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        Test.startTest();
            List<SelectOption> options = paymentController.getRecordTypeOptions();
        Test.stopTest();

        System.assertNotEquals(options, null);
    }

    @isTest static void testIsPaymentTypeValidTrue() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentTypeValid('Visa');
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testIsPaymentTypeValidFalse() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentTypeValid('');
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testUpdateChargeNameCredit() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Credit', 'TXN__c');

        Test.startTest();
            List<SelectOption> options = paymentController.getRecordTypeOptions();
        Test.stopTest();

        System.assertEquals(paymentController.updateChargeName, 'Check to manually apply Credit:');
        System.assertEquals(paymentController.renderupdateChargeName, true);
    }

    @isTest static void testUpdateChargeNamePayment() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');

        Test.startTest();
            List<SelectOption> options = paymentController.getRecordTypeOptions();
        Test.stopTest();

        System.assertEquals(paymentController.updateChargeName, 'Check to manually apply Payment:');
        System.assertEquals(paymentController.renderupdateChargeName, true);
    }

    @isTest static void testIsAmountValidEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isAmountValid('');
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsAmountValidNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isAmountValid(null);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsAmountValidNegative() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isAmountValid('-100');
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsAmountValidGood() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isAmountValid('100');
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testIsPaymentDateValidNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.othCharge.Date__c = null;

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentDateValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsPaymentDateValidDateFilled() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.othCharge.Date__c = Date.today();

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentDateValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testIsTypeValidEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isTypeValid('');
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsTypeValidNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isTypeValid(null);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsTypeValidNone() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isTypeValid('--None--');
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsTypeValidSelected() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isTypeValid('Payment');
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testSetPageErrorMessage() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            String ret = TxnManualPaymentController.setPageErrorMessage('Hello');
        Test.stopTest();

        System.assertEquals(ret, 'Hello');
    }

    @isTest static void testIsCheckValidCheckNumberIsDuplicate() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        //create default mapping
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        paymentController.init();

        // create a charge
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);
   
        // create a check payment
        TXN__c txn = new TXN__c();
        txn.Customer__c = paramMemberId;
        txn.Bill_To_Member__c = contact.Id;
        txn.RecordTypeId = Utility.searchRecordType('Payment', 'TXN__c');
        txn.Statement_Description__c = 'hi';
        txn.Amount__c = -1;
        txn.Date__c = Date.today();
        txn.Payment_Type__c = 'Check';
        txn.Status__c = 'Paid';
        txn.Check_Number__c = '123';
        txn.Check_Date__c = Date.today();
        txn.Name_on_Check__c = 'Holly Hunter';
        Data.create(txn);

        paymentController.othCharge.Customer__c = paramMemberId;
        paymentController.othCharge.Bill_To_Member__c = contact.Id;
        paymentController.othCharge.RecordTypeId = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.othCharge.Statement_Description__c = 'hi';
        paymentController.othCharge.Amount__c = 1;
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Payment_Type__c = 'Check';
        paymentController.othCharge.Status__c = 'Paid';
        paymentController.othCharge.Check_Number__c = '123';
        paymentController.othCharge.Check_Date__c = Date.today();
        paymentController.othCharge.Name_on_Check__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCheckValid(paramMemberId, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCheckValidCheckNumberGood() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
                //create default mapping
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        paymentController.init();

        // create a charge
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        
        // create a check payment
        TXN__c txn = new TXN__c();
        txn.Customer__c = paramMemberId;
        txn.Bill_To_Member__c = contact.Id;
        txn.RecordTypeId = Utility.searchRecordType('Payment', 'TXN__c');
        txn.Statement_Description__c = 'hi';
        txn.Amount__c = -1;
        txn.Date__c = Date.today();
        txn.Payment_Type__c = 'Check';
        txn.Status__c = 'Paid';
        txn.Check_Number__c = '321'; // different check number than charge above
        txn.Check_Date__c = Date.today();
        txn.Name_on_Check__c = 'Holly Hunter';
        Data.create(txn);

        paymentController.othCharge.Customer__c = paramMemberId;
        paymentController.othCharge.Bill_To_Member__c = contact.Id;
        paymentController.othCharge.RecordTypeId = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.othCharge.Statement_Description__c = 'hi';
        paymentController.othCharge.Amount__c = 1;
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Payment_Type__c = 'Check';
        paymentController.othCharge.Status__c = 'Paid';
        paymentController.othCharge.Check_Number__c = '123';
        paymentController.othCharge.Check_Date__c = Date.today();
        paymentController.othCharge.Name_on_Check__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCheckValid(paramMemberId, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, true);
        System.assertEquals(paymentController.othCharge.Check_Number__c != null, true);
        System.assertEquals(paymentController.othCharge.Check_Number__c != '', true);
        System.assertEquals(paymentController.othCharge.Name_on_Check__c != null, true);
        System.assertEquals(paymentController.othCharge.Name_on_Check__c != '', true);
        System.assertEquals(paymentController.othCharge.Check_Date__c != null, true);
    }

    @isTest static void testIsCheckValidNumberNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        paymentController.othCharge.Check_Date__c = Date.today();
        paymentController.othCharge.Check_Number__c = null;
        paymentController.othCharge.Name_on_Check__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCheckValid(paramMemberId, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCheckValidNameNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        paymentController.othCharge.Check_Date__c = Date.today();
        paymentController.othCharge.Check_Number__c = '123';
        paymentController.othCharge.Name_on_Check__c = null;

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCheckValid(paramMemberId, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCheckValidDateNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        paymentController.othCharge.Check_Date__c = null;
        paymentController.othCharge.Check_Number__c = '123';
        paymentController.othCharge.Name_on_Check__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCheckValid(paramMemberId, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCreditCardValidCardholderNameEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        paymentController.othCharge.Cardholder_Name__c = '';
        paymentController.othCharge.Card_Type__c = 'Visa';
        paymentController.othCharge.Card_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCreditCardValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCreditCardValidCardholderNameNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Cardholder_Name__c = null;
        paymentController.othCharge.Card_Type__c = 'Visa';
        paymentController.othCharge.Card_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCreditCardValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCreditCardValidCardTypeEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Card_Type__c = '';
        paymentController.othCharge.Cardholder_Name__c = 'Holly Hunter';
        paymentController.othCharge.Card_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCreditCardValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCreditCardValidCardTypeNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Card_Type__c = null;
        paymentController.othCharge.Cardholder_Name__c = 'Holly Hunter';
        paymentController.othCharge.Card_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCreditCardValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCreditCardValidCardTypeGood() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Cardholder_Name__c = 'Holly Hunter';
        paymentController.othCharge.Card_Type__c = 'Visa';
        paymentController.othCharge.Card_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCreditCardValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testIsCreditCardValidLastFourNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Card_Last_4_Digits__c = null;

        paymentController.othCharge.Cardholder_Name__c = 'Holly Hunter';
        paymentController.othCharge.Card_Type__c = 'Visa';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCreditCardValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsCreditCardValidLastFourGood() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Cardholder_Name__c = 'Holly Hunter';
        paymentController.othCharge.Card_Type__c = 'Visa';
        paymentController.othCharge.Card_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isCreditCardValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testIsACHValidBankNameEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Bank_Name__c = '';

        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidBankNameNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Bank_Name__c = null;

        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidRoutingNumberEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Routing_Number__c = '';

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidRoutingNumberNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Routing_Number__c = null;

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidAccountTypeEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Account_Type__c = '';

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidAccountTypeNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Account_Type__c = null;

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidAccountLastFourNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Account_Number_Last_4_Digits__c = null;

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidNameOnAccountEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Name_on_Account__c = '';

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidNameOnAccountNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Name_on_Account__c = null;

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsACHValidNameOnAccountGood() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Routing_Number__c = '123456';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Holly Hunter';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isACHValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testIsStatementDescriptionValidNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Statement_Description__c = null;
        paymentController.txn = new TXN__c();

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isStatementDescriptionValid(paymentController.txn, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsStatementDescriptionValidEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Statement_Description__c = '';
        paymentController.txn = new TXN__c();

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isStatementDescriptionValid(paymentController.txn, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsStatementDescriptionValidTrue() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.othCharge.Statement_Description__c = 'hello';
        paymentController.txn = new TXN__c();

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isStatementDescriptionValid(paymentController.txn, paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testIsPaymentMethodValidEmpty() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentMethodValid('');
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsPaymentMethodValidNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentMethodValid(null);
        Test.stopTest();

        System.assertEquals(ret, false);
    }

    @isTest static void testIsPaymentMethodValidTrue() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentMethodValid('abc123');
        Test.stopTest();

        System.assertEquals(ret, true);
    }

    @isTest static void testInsertDataToPaymentToChargesObjectPayment() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.insertDataToPaymentToChargesObject(Double.valueOf('1.00'), 'abcd', '1234');

        Test.startTest();
            Txn_Payment_To_Charge_Mapping__c ptc = paymentController.Payment_to_charge;
        Test.stopTest();

        System.assertEquals(ptc.amount_paid__c, 1.00);
        System.assertEquals(ptc.Charge_Id__c, 'abcd');
        System.assertEquals(ptc.Payment_Id__c, '1234');
        System.assertEquals(ptc.Method__c, 'Payment');
    }

    @isTest static void testInsertDataToPaymentToChargesObjectDeposit() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Deposit', 'TXN__c');
        paymentController.insertDataToPaymentToChargesObject(Double.valueOf('1.00'), 'abcd', '1234');

        Test.startTest();
            Txn_Payment_To_Charge_Mapping__c ptc = paymentController.Payment_to_charge;
        Test.stopTest();

        System.assertEquals(ptc.amount_paid__c, 1.00);
        System.assertEquals(ptc.Charge_Id__c, 'abcd');
        System.assertEquals(ptc.Payment_Id__c, '1234');
        System.assertEquals(ptc.Method__c, 'Deposit');
    }

    @isTest static void testInsertDataToPaymentToChargesObjectManualCredit() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = Utility.searchRecordType('Credit', 'TXN__c');
        paymentController.insertDataToPaymentToChargesObject(Double.valueOf('1.00'), 'abcd', '1234');

        Test.startTest();
            Txn_Payment_To_Charge_Mapping__c ptc = paymentController.Payment_to_charge;
        Test.stopTest();

        System.assertEquals(ptc.amount_paid__c, 1.00);
        System.assertEquals(ptc.Charge_Id__c, 'abcd');
        System.assertEquals(ptc.Payment_Id__c, '1234');
        System.assertEquals(ptc.Method__c, 'Manual Credit');
    }

    @isTest static void testInsertDataToPaymentToChargesObjectCredit() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.selectedValue = 'kittens';
        paymentController.insertDataToPaymentToChargesObject(Double.valueOf('1.00'), 'abcd', '1234');

        Test.startTest();
            Txn_Payment_To_Charge_Mapping__c ptc = paymentController.Payment_to_charge;
        Test.stopTest();

        System.assertEquals(ptc.amount_paid__c, 1.00);
        System.assertEquals(ptc.Charge_Id__c, 'abcd');
        System.assertEquals(ptc.Payment_Id__c, '1234');
        System.assertEquals(ptc.Method__c, 'Credit');
    }

    @isTest static void testPageParameters() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        String paramMemberName = ApexPages.currentPage().getParameters().put('memberName', 'Groucho Marx');
        String paramReservationId = ApexPages.currentPage().getParameters().put('reservationId', '333666999');

        Test.startTest();
            paymentController.init();
        Test.stopTest();

        System.assertEquals(ApexPages.currentPage().getParameters().get('memberId'), contact.Id);
        System.assertEquals(ApexPages.currentPage().getParameters().get('memberName'), 'Groucho Marx');
        System.assertEquals(ApexPages.currentPage().getParameters().get('reservationId'), '333666999');
        System.assertEquals(paymentController.referrerURL, '/' + contact.Id);
    }

    @isTest static void testAllCharges() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        Test.startTest();
            List<TXN__c> charges = paymentController.allCharges;
        Test.stopTest();

        System.assertEquals(charges.size() > 0, true);
    }

    @isTest static void testSaveBadDate() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.othCharge.Date__c = null;
        paymentController.othCharge.Amount__c = 100;
        paymentController.othCharge.Statement_Description__c = 'hi';

        Test.startTest();
            Boolean ret = TxnManualPaymentController.isPaymentDateValid(paymentController.othCharge);
        Test.stopTest();

        System.assertEquals(paymentController.save(), null);
    }

    @isTest static void testSaveBadType() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        paymentController.selectedValue = null;
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Amount__c = 100;
        paymentController.othCharge.Statement_Description__c = 'hi';

        Test.startTest();
            System.assertEquals(paymentController.save(), null);
        Test.stopTest();
    }

    @isTest static void testSaveBadAmount() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Amount__c = null;
        paymentController.othCharge.Statement_Description__c = 'hi';

        Test.startTest();
            System.assertEquals(paymentController.save(), null);
        Test.stopTest();
    }

    @isTest static void testSaveBadStatementDescription() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Amount__c = 100;
        paymentController.othCharge.Statement_Description__c = null;

        Test.startTest();
            System.assertEquals(paymentController.save(), null);
        Test.stopTest();
    }

    @isTest static void testSaveCash() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.othCharge.Payment_Type__c = 'Cash';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        Test.startTest();
            paymentController.save();
        Test.stopTest();

        System.assertEquals(paymentController.txn.Customer__c, paymentController.paramMemberId);
        System.assertEquals(paymentController.txn.RecordTypeId, paymentController.selectedValue);
        System.assertEquals(paymentController.txn.Description__c, paymentController.othCharge.Description__c);
        System.assertEquals(paymentController.txn.Statement_Description__c, paymentController.othCharge.Statement_Description__c);
        System.assertEquals(paymentController.txn.Date__c, paymentController.othCharge.Date__c);
        System.assertEquals(paymentController.txn.Payment_Type__c, 'Cash');
        System.assertEquals(paymentController.txn.Status__c, 'Paid');
    }

    @isTest static void testSaveCheck() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
             //create default mapping
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);
   
        
        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.paymentType = 'Check';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        paymentController.othCharge.Check_Number__c = '123';
        paymentController.othCharge.Check_Date__c = Date.today();
        paymentController.othCharge.Name_on_Check__c = 'Robert Plant';

        Test.startTest();
            paymentController.save();
        Test.stopTest();       
    }

    @isTest static void testSaveCheckNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.paymentType = 'Check';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        paymentController.othCharge.Check_Number__c = '';
        paymentController.othCharge.Check_Date__c = Date.today();
        paymentController.othCharge.Name_on_Check__c = 'Robert Plant';

        Test.startTest();
            System.assertEquals(paymentController.save(), null);
        Test.stopTest();
    }

    @isTest static void testSaveCreditCard() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        TxnTestUtility.requiredDefaultAccounts();

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        
        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.paymentType = 'CreditCard';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        paymentController.othCharge.Cardholder_Name__c = 'Robert Plant';
        paymentController.othCharge.Card_Type__c = 'Visa';
        paymentController.othCharge.Card_Last_4_Digits__c = '1234';
        paymentController.othCharge.External_Payment_Transaction_Code__c = '123';
        paymentController.othCharge.External_Payment_Authorization_Code__c = '123';

        Test.startTest();
            paymentController.save();
        Test.stopTest();       
    }

    @isTest static void testSaveCreditCardNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.paymentType = 'CreditCard';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        paymentController.othCharge.Cardholder_Name__c = 'Robert Plant';
        paymentController.othCharge.Card_Type__c = 'Visa';
        paymentController.othCharge.Card_Last_4_Digits__c = null;
        paymentController.othCharge.External_Payment_Transaction_Code__c = '123';
        paymentController.othCharge.External_Payment_Authorization_Code__c = '123';

        Test.startTest();
            System.assertEquals(paymentController.save(), null);
        Test.stopTest();
    }

    @isTest static void testSaveACH() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        TxnTestUtility.requiredDefaultAccounts();

        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);
        
        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.paymentType = 'ACH';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Account_Type__c = 'Checking';
        paymentController.othCharge.Routing_Number__c = '111222';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = '1234';
        paymentController.othCharge.Name_on_Account__c = 'Robert Plant';

        Test.startTest();
            paymentController.save();
        Test.stopTest();

    }

    @isTest static void testSaveACHNull() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.paymentType = 'ACH';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        paymentController.othCharge.Bank_Name__c = 'Simple';
        paymentController.othCharge.Account_Type__c = '';
        paymentController.othCharge.Routing_Number__c = '';
        paymentController.othCharge.Account_Number_Last_4_Digits__c = null;
        paymentController.othCharge.Name_on_Account__c = 'Robert Plant';

        Test.startTest();
            System.assertEquals(paymentController.save(), null);
        Test.stopTest();
    }

    @isTest static void testGetPaymentToChargePayment() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.othCharge.Payment_Type__c = 'Cash';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        List<Txn_Payment_To_Charge_Mapping__c> paymentToChargeList = new List<Txn_Payment_To_Charge_Mapping__c>();
        List<TXN__c> txnRecords = (List<TXN__c>)Data.read(
            'SELECT Id, Status__c, Charge_Amount_Left__c, Total_Amount__c, DateTime__c, Reservation__c FROM TXN__c WHERE RecordTypeId = :chargeId AND Customer__c = :memId AND Status__c != \'Fully Paid\' ORDER BY DateTime__c',
            new Map<String,Object> {
                'chargeId' => Utility.searchRecordType('Charge', 'TXN__c'),
                'memId' => contact.Id
            }
        );

        Test.startTest();
            paymentController.save();
            for (TXN__c GetRecord:txnRecords) {
                if (GetRecord.Charge_Amount_Left__c > 0) {
                    paymentToChargeList.add(
                        paymentController.getPaymentToCharge(Double.valueOf(GetRecord.Charge_Amount_Left__c), GetRecord.Id, charge.Id)
                    );
                }
            }
            Txn_Payment_To_Charge_Mapping__c pmtToCharge = paymentController.getPaymentToCharge(Double.valueOf(charge.Amount__c), charge.Id, paymentController.txn.Id);
        Test.stopTest();

        System.assertEquals(paymentToChargeList.size() > 0, true);
        System.assertEquals(pmtToCharge.amount_paid__c, Double.valueOf(charge.Amount__c));
        System.assertEquals(pmtToCharge.Method__c, 'Payment');
    }

    @isTest static void testGetPaymentToChargeDeposit() {
        Test.setCurrentPageReference(Page.TxnManualPayment);

        TxnTestUtility.requiredDefaultAccounts();

        Event__c event = TestHandler.getEvent();
        event.Sponsoring_Customer__c = contact.Id;
        event.SponsoringMember__c =contact.Id;
        update event;

        // set page params
        String fromPage = ApexPages.currentPage().getParameters().put('from','Banquet');
        String paramMemberId = ApexPages.currentPage().getParameters().put('reservationId', event.id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);
         //create default account mapping for credit card payment
         Financial_Account__c fa = TxnTestUtility.createFinancialAccount('test');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Prepaid Deposits',fa);
        da = TxnTestUtility.getDefaultMapping('Bank Account',fa) ;
        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Deposit', 'TXN__c');
        paymentController.eventDeposit.Deposit_Amount__c = 20;
        paymentController.othCharge.Payment_Type__c = 'Cash';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        List<Txn_Payment_To_Charge_Mapping__c> paymentToChargeList = new List<Txn_Payment_To_Charge_Mapping__c>();
        List<TXN__c> txnRecords = (List<TXN__c>)Data.read(
            'SELECT Id, Status__c, Charge_Amount_Left__c, Total_Amount__c, DateTime__c, Reservation__c FROM TXN__c WHERE RecordTypeId = :chargeId AND Customer__c = :memId AND Status__c != \'Fully Paid\' ORDER BY DateTime__c',
            new Map<String,Object> {
                'chargeId' => Utility.searchRecordType('Charge', 'TXN__c'),
                'memId' => contact.Id
            }
        );

        Test.startTest();
            paymentController.save();
            for (TXN__c GetRecord:txnRecords) {
                if (GetRecord.Charge_Amount_Left__c > 0) {
                    paymentToChargeList.add(
                        paymentController.getPaymentToCharge(Double.valueOf(GetRecord.Charge_Amount_Left__c), GetRecord.Id, charge.Id)
                    );
                }
            }
            Txn_Payment_To_Charge_Mapping__c pmtToCharge = paymentController.getPaymentToCharge(Double.valueOf(charge.Amount__c), charge.Id, paymentController.txn.Id);
        Test.stopTest();

        System.assertEquals(paymentToChargeList.size() > 0, true);
        System.assertEquals(pmtToCharge.amount_paid__c, Double.valueOf(charge.Amount__c));
        System.assertEquals(pmtToCharge.Method__c, 'Deposit');
    }

    @isTest static void testGetPaymentToChargeManualCredit() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Credit', 'TXN__c');
        paymentController.paymentAmount = '-20';
        paymentController.othCharge.Payment_Type__c = 'Cash';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        List<Txn_Payment_To_Charge_Mapping__c> paymentToChargeList = new List<Txn_Payment_To_Charge_Mapping__c>();
        List<TXN__c> txnRecords = (List<TXN__c>)Data.read(
            'SELECT Id, Status__c, Charge_Amount_Left__c, Total_Amount__c, DateTime__c, Reservation__c FROM TXN__c WHERE RecordTypeId = :chargeId AND Customer__c = :memId AND Status__c != \'Fully Paid\' ORDER BY DateTime__c',
            new Map<String,Object> {
                'chargeId' => Utility.searchRecordType('Charge', 'TXN__c'),
                'memId' => contact.Id
            }
        );

        Test.startTest();
            paymentController.save();
            for (TXN__c GetRecord:txnRecords) {
                if (GetRecord.Charge_Amount_Left__c > 0) {
                    paymentToChargeList.add(
                        paymentController.getPaymentToCharge(Double.valueOf(GetRecord.Charge_Amount_Left__c), GetRecord.Id, charge.Id)
                    );
                }
            }
            Txn_Payment_To_Charge_Mapping__c pmtToCharge = paymentController.getPaymentToCharge(Double.valueOf(charge.Amount__c), charge.Id, paymentController.txn.Id);
        Test.stopTest();

        System.assertEquals(paymentToChargeList.size() > 0, true);
        System.assertEquals(pmtToCharge.amount_paid__c, Double.valueOf(charge.Amount__c));
        System.assertEquals(pmtToCharge.Method__c, 'Manual Credit');
    }

    @isTest static void testAutoPartial() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '20';
        paymentController.othCharge.Payment_Type__c = 'Cash';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        Test.startTest();
            paymentController.save();
            paymentController.AutoPay(paymentController.paymentAmount, charge.Id, contact.Id);
        Test.stopTest();
    }

    @isTest static void testAutoPayFullyPay() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        TxnTestUtility.requiredDefaultAccounts();
        // set page params
        String paramMemberId = ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        // create a charge record
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Charge', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Unpaid';
        charge.Posted__c = true;
        charge.Amount__c = 100;
        charge.Service_Charge__c = 10;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);

        // create a payment
        paymentController.selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        paymentController.paymentAmount = '100';
        paymentController.othCharge.Payment_Type__c = 'Cash';
        paymentController.othCharge.Date__c = Date.today();
        paymentController.othCharge.Description__c = 'description';
        paymentController.othCharge.Statement_Description__c = 'statement description';

        Test.startTest();
            paymentController.save();
            paymentController.AutoPay(paymentController.paymentAmount, charge.Id, contact.Id);
        Test.stopTest();
    }

    @isTest static void testPaymentId() {
        Test.setCurrentPageReference(Page.TxnManualPayment);
        //create default mapping
        TxnTestUtility.requiredDefaultAccounts();
        // create a payment
        TXN__c charge = new TXN__c();
        charge.RecordTypeId = Utility.searchRecordType('Payment', 'TXN__c');
        charge.Customer__c = contact.Id;
        charge.Bill_To_Member__c = contact.Id;
        charge.Status__c = 'Paid';
        charge.Amount__c = -100;
        charge.Payment_Type__c = 'Cash';
        charge.Date__c = Date.today();
        charge.Description__c = 'description';
        charge.Statement_Description__c = 'statement description';
        Data.create(charge);

        // set page params
        ApexPages.currentPage().getParameters().put('memberId', contact.Id);
        ApexPages.currentPage().getParameters().put('PaymentId', charge.Id);
        TxnManualPaymentController paymentController = new TxnManualPaymentController();
        paymentController.init();

        List<TXN__c> txnCharges = (List<TXN__c>)Data.read(
            'SELECT ID, Name, Customer__c, RECORDTYPEID, Check_Date__c, Check_Number__c, Payment_Type__c, External_Payment_Authorization_Code__c, External_Payment_Transaction_Code__c, External_Payment_Method_Last_4_Digits__c, External_Payment_Method__c, Description__c, Date__c, Total_Amount__c, Status__c, Amount__c FROM TXN__c WHERE Id = :paymentId',
            new Map<String,Object> {
                'paymentId' => charge.Id
            }
        );

        Test.startTest();
            // System.assertEquals(paymentController.isDetailPage, true);

            if (txnCharges.size() > 0) {
                List<Contact> contactList = (List<Contact>)Data.read(
                    'SELECT ID, Name FROM Contact WHERE Id = :txnMember',
                    new Map<String,Object> {
                        'txnMember' => String.valueOf(txnCharges.get(0).Customer__c)
                    }
                );

                if (contactList.size() > 0) {
                    System.assertEquals(paymentController.paramMemberId, String.valueOf(contactList.get(0).ID));
                    System.assertEquals(paymentController.guestID, String.valueOf(contactList.get(0).ID));
                    // System.assertEquals(paymentController.paramMemberName, String.valueOf(contactList.get(0).Name));
                }
            }
        Test.stopTest();

        // System.assertEquals(paymentController.editPg, false);
        // System.assertEquals(paymentController.editPg1, true);
        // System.assertEquals(paymentController.selectedValue, String.valueOf(txnCharges.get(0).RECORDTYPEID));
        // System.assertEquals(paymentController.paymentAmount, String.valueOf(Double.valueOf(txnCharges.get(0).Total_Amount__c) * -1));
        // System.assertEquals(paymentController.paymentType, String.valueOf(txnCharges.get(0).Payment_Type__c));
        // System.assertEquals(paymentController.othCharge.Date__c, Date.valueOf(txnCharges.get(0).Date__c));
        // System.assertEquals(paymentController.othCharge.Description__c, String.valueOf(txnCharges.get(0).Description__c));
    }

}