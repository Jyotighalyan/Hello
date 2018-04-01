@isTest
public with sharing class TxnAdjustChargeControllerTest
{
	public  Static String  AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
  	public  Static String ContactMemberId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();


    @isTest
    static void testAllCharges()
    {
        Account dummyAccount = TxnTestUtility.createAccount(AccountMemberId);
        Contact dummyMember = TxnTestUtility.createMember(dummyAccount, 'Dependent',ContactMemberId);

        PageReference pageRef = Page.TxnAdjustCharge;
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
        charge.Quantity__c = 1;
        charge.Tax__c = 10;
        charge.Charge_Amount_Left__c = 120;
        Data.create(charge);
        
        TXN__c charge2 = new TXN__c();
        charge2.RecordTypeId = Utility.searchRecordType('Taxes', 'TXN__c');
        charge2.Customer__c = dummyMember.Id;
        charge2.Bill_To_Member__c = dummyMember.Id;
        charge2.Related_To__c = charge.id;
        charge2.Status__c = 'Unpaid';
        charge2.Posted__c = true;
        charge2.Amount__c = 100;
        charge2.Service_Charge__c = 10;
        charge2.Quantity__c = 1;
        charge2.Tax__c = 10;
        charge2.Charge_Amount_Left__c = 120;
        Data.create(charge2);
        
        TXN__c charge3 = new TXN__c();
        charge3.RecordTypeId = Utility.searchRecordType('Adjustment', 'TXN__c');
        charge3.Customer__c = dummyMember.Id;
        charge3.Bill_To_Member__c = dummyMember.Id;
        charge3.Related_To__c = charge.id;
        charge3.Status__c = 'Unpaid';
        charge3.Posted__c = true;
        charge3.Amount__c = -100;
        charge3.Service_Charge__c = 10;
        charge3.Quantity__c = 1;
        charge3.Tax__c = 10;
        charge3.Charge_Amount_Left__c = 120;
        Data.create(charge3);

        
        System.currentPageReference().getParameters().put('ContactType', 'member');
        System.currentPageReference().getParameters().put('from', 'MemberPage');
        System.currentPageReference().getParameters().put('ChargeId', charge.Id);
        System.currentPageReference().getParameters().put('memberId', dummyMember.id);
        System.currentPageReference().getParameters().put('memberName', dummyMember.name);
        System.currentPageReference().getParameters().put('node', '{"data":[{"TaxName":"Room Rental Occupancy Tax w/out Room","Amount":"4.97"}]}');

        fa = TestHandler.getFinancialAccount(); // method inserts
        TxnAdjustChargeController txnCharge = new TxnAdjustChargeController();
        
        Test.startTest();
        List<TxnAdjustChargeController.aTableAdjustment> adjustmentslist = txnCharge.allAdjustments;
        //txnCharge.selectedChargeItem = ci.Id;
        //txnCharge.selectChargeItem();
        txnCharge.Charge_Amount = '50.0';
        txnCharge.nickName = 'save';
        txnCharge.adj_Amount = '-6.00';
        txnCharge.txn.Quantity__c = 1;
        //txnCharge.othChargeRelatedTaxesWrapper = new List
        txnCharge.save();
        Test.stopTest();
    }
}