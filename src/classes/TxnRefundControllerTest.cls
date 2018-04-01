@isTest
public class TxnRefundControllerTest {
    public  Static String  AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public  Static String ContactMemberId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();

     
   	 //TxnTestUtitlity TTU=new TxnTestUtitlity();
    @isTest
    public static  void txnRef(){
         
     Account Acc=TxnTestUtility.createAccount(AccountMemberId);
	 Contact mem=TxnTestUtility.createMember(Acc,'Dependent',ContactMemberId);
      //create default account mapping for credit card payment
      Financial_Account__c fa = TxnTestUtility.createFinancialAccount('test');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultMapping('Accounts Payable',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;
     TXN__c payment=TxnTestUtility.txnCreatePay(mem);
     TXN__c charge=TxnTestUtility.createChargeOnMember(mem,200);
  	 TXN__c mapping=TxnTestUtility.txnMapPaymentToCharge(charge,payment,100);

    	PageReference pageRef = Page.TxnRefund;
    	Test.setCurrentPage(pageRef);
    	ApexPages.currentPage().getParameters().put('PaymentId', payment.Id);
        
        TxnRefundController refCont=new TxnRefundController();
        refCont.Cancel();
        refCont.save();
        
        refCont=new TxnRefundController();
        refCont.Cancel();
        refCont.othCharge.Refund_Reason__c='test refund';
        refCont.othCharge.Payment_Type__c='Cash';
        refCont.othCharge.Amount__c=150;
       // MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Default', 'Default Account Payable', '');
        //MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Default', 'Bank Account Default', '');
        refCont.save();
        
        /*TxnRefundController refCont1=new TxnRefundController();
        refCont1.Cancel();
        refCont1.othCharge.Refund_Reason__c='test refund';
        refCont1.othCharge.Payment_Type__c='Check';
        refCont1.othCharge.Amount__c=20;
        MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Default', 'Default Account Payable', '');
        MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Transactions', 'Check', '');
        refCont1.save();
        
        refCont1=new TxnRefundController();
        refCont1.Cancel();
        refCont1.othCharge.Refund_Reason__c='test refund';
        refCont1.othCharge.Payment_Type__c='Check';
        refCont1.othCharge.Amount__c=20;
        refCont1.save();
        
        refCont1=new TxnRefundController();
        refCont1.Cancel();
        refCont1.othCharge.Refund_Reason__c='test refund';
        refCont1.othCharge.Payment_Type__c='Credit Card';
        refCont1.othCharge.Amount__c=20;
        MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Default', 'Default Account Payable', '');
        MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Transactions', 'Credit Card', '');
        refCont1.save();*/
    }

    /*public static void txnRef1(){
        Account Acc=TxnTestUtility.createAccount(AccountMemberId);
        Contact mem=TxnTestUtility.createMember(Acc,'Primary',ContactMemberId);
        TXN__c payment=TxnTestUtility.txnCreatePay(mem);
        TXN__c charge=TxnTestUtility.createChargeOnMember(mem,200);
        TXN__c mapping=TxnTestUtility.txnMapPaymentToCharge(charge,payment,100);

        PageReference pageRef = Page.TxnRefund;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('PaymentId', payment.Id);

        TxnRefundController refCont1=new TxnRefundController();
        refCont1.Cancel();
        refCont1.othCharge.Refund_Reason__c='test refund';
        refCont1.othCharge.Payment_Type__c='Cash';
        refCont1.othCharge.Amount__c=50;
        refCont1.othCharge.Statement_Description__c = 'test';
        Date currentDate = system.today();
        refCont1.othCharge.Date__c=Date.newInstance(currentDate.year(),currentDate.month(),currentDate.day());
        refCont1.save();
        MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Default', 'Bank Account Default', '');
        refCont1.save();
        MappingAndTaxUtilityTest.mapFinancialAccountToCharge('Transactions', 'Cash', '');
        refCont1.save();
    } */
    
}