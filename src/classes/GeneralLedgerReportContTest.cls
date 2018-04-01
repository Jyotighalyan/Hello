@isTest
public class GeneralLedgerReportContTest {
    public GeneralLedgerReportContTest(){
        
    }
    private testMethod static void runAll() {
        GeneralLedgerReportCont GLRc=new GeneralLedgerReportCont();
        GLRc.fAcc.Category__c='Income';
        GLRc.fAcc.Department2__c='Department 1';
        GLRc.txnRec.Check_Date__c= date.today();
        GLRc.txnRec.Date__c=date.today();
        GLRc.sortAccounts();
        GLRc.getfullAccList();
        GLRc.LoadEntries();
        
    }
}