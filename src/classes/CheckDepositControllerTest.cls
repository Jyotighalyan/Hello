@isTest
public class CheckDepositControllerTest {
    private testMethod static void runAll() {
        Vendor_Invoice_Check_Batch__c vicb = new Vendor_Invoice_Check_Batch__c();
        insert vicb;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(vicb);
        CheckDepositController CDC = new CheckDepositController(sc);
        CDC.addMoreRows();
        integer amount=10;
        Financial_Account__c fa = new Financial_Account__c(Name='Test',Account_Number__c='asd32sd',Category__c='Liability' ,Bank_Account__c = true, Active__c=true);
        insert fa;
        CDC.bd.Financial_Account__c=fa.id;
        CDC.bd.Deposit_Slip_Number__c='1233';
        CDC.bd.Deposit_Date__c=date.today();
        CDC.bd.Total__c=100;
        Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
        Contact member = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
        for(Integer i=1;i<=10;i++){
            Deposit_Batch_Check_Payment__c newObj=new Deposit_Batch_Check_Payment__c();
            newObj.Amount__c=amount;
            newObj.Check_Date__c=date.today();
            newObj.Check_Number__c='123'+amount;
            newObj.Customer__c=member.id;
            CDC.payList.put(i,new CheckDepositeService.PaymentWrapper(i, newObj));
            CDC.lastIndex=i;
           
        }
        CDC.getPayListV();
        CDC.getpayListToMergeV();
        CDC.cObjIndex=1;
        CDC.makeAmountFieldBlank();
        CDC.saveCheckDepositPayments();
        //update 
        CDC.selectedPastBD=CDC.bd.id;
        CDC.loadCheckDepositPayments();
        CDC.saveCheckDepositPayments();
        
        //CDC.bdForMerge=CDC.bd;
        //CDC.selectedPastBDForMerge=CDC.bd.id;
        //CDC.setPastBankDepsoit();
       // CDC.getDetailOfBatchToMerge();
        CDC.PostBatch();
        CDC.loadCheckDepositPaymentsForMerge();
        
        //mearge batch
        //CDC = new CheckDepositController(sc);
        CDC.bd.Financial_Account__c=fa.id;
        CDC.bd.Deposit_Slip_Number__c='1244';
        CDC.bd.Deposit_Date__c=date.today();
        CDC.bd.Total__c=100;
        for(Integer i=1;i<=10;i++){
            Deposit_Batch_Check_Payment__c newObj=new Deposit_Batch_Check_Payment__c();
            newObj.Amount__c=amount;
            newObj.Check_Date__c=date.today();
            newObj.Check_Number__c='123'+amount;
            newObj.Customer__c=member.id;
            CDC.payList.put(i,new CheckDepositeService.PaymentWrapper(i, newObj));
            CDC.lastIndex=i;
           
        }
        CDC.selectedPastBDForMerge=CDC.bd.id;
        CDC.saveCheckDepositPayments();
        CDC.MergeBoth();
    }
}