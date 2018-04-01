@isTest
public class ManualCreditControllerTest {
    @isTest
    static void ManualCreditTest1()
    {
        Test.setCurrentPage(Page.ManualCredit);
        ApexPages.currentPage().getParameters().put('message','success');
        // create a member with the selected membership type
        Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
        Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
        Financial_Account__c creditFC = TxnTestUtility.createFinancialAccount('CreditFC');
        Financial_Account__c debit1 = TxnTestUtility.createFinancialAccount('debit1');
        Financial_Account__c debit2 = TxnTestUtility.createFinancialAccount('debit2');
        Test.startTest();
        ManualCreditController creditSetup = new ManualCreditController();
        creditSetup.txnObj.Customer__c =con.id;
        creditSetup.txnObj.Bill_To_Member__c =con.id;
        creditSetup.txnObj.Date__c =date.today();
        creditSetup.txnObj.Credit_Financial_Account__c =creditFC.id;
        creditSetup.TotalAmount =10;
        
        creditSetup.cObjIndex = 0;
        creditSetup.delMember();
        creditSetup.addMoreRows();
        creditSetup.getCreditListV();
        
        TXN__c txnRec=new TXN__c();
        txnRec.Financial_Account__c=debit1.id;
        creditSetup.CreditList.put(0,new ManualCreditService.CreditSplitWrapper(0,txnRec,'10'));
        creditSetup.save();
        Test.stopTest();
    }
    @isTest
    static void ManualCreditTest2()
    {
        // create a member with the selected membership type
        Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
        Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
        Financial_Account__c creditFC = TxnTestUtility.createFinancialAccount('CreditFC');
        Financial_Account__c debit1 = TxnTestUtility.createFinancialAccount('debit1');
        Financial_Account__c debit2 = TxnTestUtility.createFinancialAccount('debit2');
        Test.startTest();
        ManualCreditController creditSetup = new ManualCreditController();
        creditSetup.txnObj.Customer__c =con.id;
        creditSetup.txnObj.Bill_To_Member__c =con.id;
        creditSetup.txnObj.Date__c =date.today();
        creditSetup.txnObj.Credit_Financial_Account__c =creditFC.id;
        creditSetup.TotalAmount =20;
        
        creditSetup.cObjIndex = 0;
        
        TXN__c txnRec=new TXN__c();
        txnRec.Financial_Account__c=debit1.id;
        creditSetup.CreditList.put(0,new ManualCreditService.CreditSplitWrapper(0,txnRec,'10'));
        creditSetup.CreditList.put(1,new ManualCreditService.CreditSplitWrapper(1,txnRec,'10'));
        creditSetup.save();
        
        Test.stopTest();
    }
    @isTest
    static void ManualCreditTest3()
    {
        // create a member with the selected membership type
        Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
        Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
        Financial_Account__c creditFC = TxnTestUtility.createFinancialAccount('CreditFC');
        Financial_Account__c debit1 = TxnTestUtility.createFinancialAccount('debit1');
        Financial_Account__c debit2 = TxnTestUtility.createFinancialAccount('debit2');
           Test.startTest();
        try{
            ManualCreditController creditSetup = new ManualCreditController();
            creditSetup.save();
        }catch(Exception e){
                        
            System.assertEquals('Please enter amount.',e.getMessage() );
        }
        try{
            ManualCreditController creditSetup = new ManualCreditController();
            creditSetup.TotalAmount =20;
            creditSetup.save();
            
        }catch(Exception e){
            System.assertEquals('Please select date.',e.getMessage() );
        }
        try{
            ManualCreditController creditSetup = new ManualCreditController();
            creditSetup.TotalAmount =20;
            creditSetup.txnObj.Date__c =date.today();
            creditSetup.save();
            
        }catch(Exception e){
            System.assertEquals('Please select customer.',e.getMessage() );
        }
        try{
            ManualCreditController creditSetup = new ManualCreditController();
            creditSetup.TotalAmount =20;
            creditSetup.txnObj.Date__c =date.today();
            creditSetup.txnObj.Customer__c =con.id;
            creditSetup.txnObj.Bill_To_Member__c =con.id;
            creditSetup.save();
            
        }catch(Exception e){
            System.assertEquals('Enter credit financial account',e.getMessage() );
        }
        try{
            ManualCreditController creditSetup = new ManualCreditController();
            creditSetup.TotalAmount =20;
            creditSetup.txnObj.Date__c =date.today();
            creditSetup.txnObj.Customer__c =con.id;
            creditSetup.txnObj.Bill_To_Member__c =con.id;
            creditSetup.txnObj.Credit_Financial_Account__c =creditFC.id;
            creditSetup.save();
            
        }catch(Exception e){
            System.assertEquals('Enter at least one debit account.',e.getMessage() );
        }
        try{
            ManualCreditController creditSetup = new ManualCreditController();
            creditSetup.TotalAmount =20;
            creditSetup.txnObj.Date__c =date.today();
            creditSetup.txnObj.Customer__c =con.id;
            creditSetup.txnObj.Bill_To_Member__c =con.id;
            creditSetup.txnObj.Credit_Financial_Account__c =creditFC.id;
            TXN__c txnRec=new TXN__c();
            txnRec.Financial_Account__c=debit1.id;
            creditSetup.CreditList.put(0,new ManualCreditService.CreditSplitWrapper(0,txnRec,'5'));
            creditSetup.save();
            
        }catch(Exception e){
            System.assertEquals('Total of Debit amount should be same as total amount.',e.getMessage() );
        }
        Test.stopTest();
        
        
        
        
      
        
    }
}