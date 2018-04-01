/*
@Name           : VendorCheckRunControllerTest
@Author         : kiran@3embed.com
@Description    : Test methods for void check and check batch controller
*/
@isTest
public class voidCheckOrCheckBatchTest {
    public static String AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static String vendorAcc = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    static Integer jj=0;
    static testmethod void vendorCheckRunControllerTest1() {    
        
        Financial_Account__c fa1 = new Financial_Account__c(Active__c = true,Name='Test1',Account_Number__c='asd32sd1',Category__c='Liability');
        insert fa1;
        
        Financial_Account__c fa = new Financial_Account__c(Active__c = true,Name='Test',Account_Number__c='asd32sd',Category__c='Liability');
        insert fa;
        
        Vendor_Invoice_Check_Batch__c vicb = new Vendor_Invoice_Check_Batch__c();
        insert vicb;
        Check_Run__c cr = new Check_Run__c(Printed_Check_Digits__c = 8,Next_Check_Number__c='0');
        insert cr;
        
        
        Default_Account__c da =new Default_Account__c (Default_Type_Name__c ='Accounts Payable',Financial_Account__c = fa.Id);
        insert da;
        
        Account v= TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account'));
        Vendor_Invoice_Check__c vicc = new Vendor_Invoice_Check__c(Amount__c = 300,Vendor__c = v.id,Check_Number__c = '63251478',
                                                                   Vendor_Invoice_Check_Batch__c = vicb.Id,Memo__c = 'New Memo',Check_Date__c = Date.Today());
        insert vicc;
        
        Vendor_Invoice__c vi = new Vendor_Invoice__c(Vendor_Invoice_Check__c = vicc.Id,Invoice_Date__c= Date.today(),Due_Date__c = Date.today(),Hold_Status__c = false,Vendor__c=v.id,Invoice_Number__c='156985', Amount__c=500);
        insert vi;
        Financial_Account__c viacc=TxnTestUtility.createFinancialAccount('test1');
        Vendor_Invoice_Line__c vil = new Vendor_Invoice_Line__c(Payment_Type__c = 'Check',Financial_Account__c=viacc.id,Vendor_Invoice__c = vi.Id, Amount__c=500);
        insert vil;
        Vendor_Invoice_Payment__c vip = new Vendor_Invoice_Payment__c(Amount_Paid__c = 1,Vendor_Invoice__c = vi.Id, Vendor_Invoice_Line__c=vil.Id);
        insert vip;
        Vendor_Invoice__c vi1 = new Vendor_Invoice__c(Due_Date__c = Date.today(),Invoice_Date__c = Date.today(),Vendor__c=v.id,Invoice_Number__c=string.valueOf(jj++), Amount__c=500,  Hold_Status__c = true);
        insert vi1;
        Vendor_Invoice_Line__c vil1 = new Vendor_Invoice_Line__c(Vendor_Invoice__c = vi1.Id, Amount__c=500,Financial_Account__c=viacc.id);
        insert vil1;
        Vendor_Invoice_Payment__c vip1 = new Vendor_Invoice_Payment__c(Amount_Paid__c = 500, Vendor_Invoice_Check__c=vicc.id ,Vendor_Invoice__c = vi1.Id, Vendor_Invoice_Line__c=vil1.Id);
        insert vip1;
        
         Test.startTest();
        //save financial journal entry
        List<Default_Account__c> tradeAccount = (List<Default_Account__c>)Data.read(
            'select id, Financial_Account__c from Default_Account__c where Default_Type_Name__c =:Value ',
            new Map<String,Object> {
                'Value'=>'Accounts Payable'
                    }
        ); 
        Financial_Journal_Entry__c fjEntry = new Financial_Journal_Entry__c();
        fjEntry.Description__c = 'Invoice Check Batch '+vicb.id;
        fjEntry.Entry_Date__c = vicb.Batch_Date__c;
        fjEntry.Posted__c = true;
        fjEntry.Post_Date__c = vicb.Batch_Date__c;
        insert fjEntry;
        
        Financial_Journal_Line__c tradeJournal = new Financial_Journal_Line__c();
        tradeJournal.Amount__c = 500;
        tradeJournal.Description__c = 'Invoice Check Batch '+vicb.id;
        
        tradeJournal.Financial_Account__c=tradeAccount[0].Financial_Account__c;
        tradeJournal.Financial_Journal_Entry__c = fjEntry.Id;
        tradeJournal.Post_Date__c = vicb.Batch_Date__c;
        tradeJournal.Posted__c = true;
        tradeJournal.Transaction_Date__c = vicb.Batch_Date__c;
        Financial_Journal_Line__c cashJournal = new Financial_Journal_Line__c();
        
        cashJournal.Description__c = 'Invoice Check Batch '+vicb.id;
        //check account is for credit or debit
        List<Financial_Account__c> CheckCreditDebit = (List<Financial_Account__c>)Data.read(
            'select Debit_Credit__c  from Financial_Account__c  where id =: AccId ',
            new Map<String,Object> {
                'AccId'=>fa1.id
                    }
        ); 
        cashJournal.Amount__c = 500 ;
        if(CheckCreditDebit[0].Debit_Credit__c == 'Credit'){
            cashJournal.Amount__c = 500 * -1;
        }
        cashJournal.Financial_Account__c=fa1.id;
        cashJournal.Financial_Journal_Entry__c = fjEntry.Id;
        cashJournal.Post_Date__c = vicb.Batch_Date__c;
        cashJournal.Posted__c = true;
        cashJournal.Transaction_Date__c = vicb.Batch_Date__c;
        List<Financial_Journal_Line__c> fjsToInsert = new List<Financial_Journal_Line__c>();
        fjsToInsert.add(tradeJournal);
        fjsToInsert.add(cashJournal);
        Data.create(fjsToInsert);
        
        vicb.Financial_Journal_Entry__c=fjEntry.id;
        update vicb;
        PageReference myVfPage = Page.voidCheckorCheckBatch;
        Test.setCurrentPage(myVfPage);
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('batchId',vicb.Id);
        voidCheckorCheckBatch voidCB=new voidCheckorCheckBatch();
        voidCB.returnToCheckPage();
        voidCB.returnToBatchPage();
        system.assertEquals(voidCB.alreadyVoided, false);
        voidCB.VoidBatch();
        
        
        myVfPage = Page.voidCheckorCheckBatch;
        Test.setCurrentPage(myVfPage);
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('batchId',vicb.Id);
        voidCB=new voidCheckorCheckBatch();
        voidCB.returnToCheckPage();
        voidCB.returnToBatchPage();
        system.assertEquals(voidCB.alreadyVoided, true);
        //voidCB.VoidBatch();
        
        
        myVfPage = Page.voidCheckorCheckBatch;
        Test.setCurrentPage(myVfPage);
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('checkId',vicc.Id);
        
        voidCB=new voidCheckorCheckBatch();
        voidCB.returnToCheckPage();
        voidCB.returnToBatchPage();
        
        voidCB.VoidCheck();
        system.assertEquals(voidCB.alreadyVoided, true);
        Test.StopTest();
        
    }
}