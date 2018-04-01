/**
* @author joshi Prakash
* @date 06-20-2017
* @group Financial Management
* @description Controller class to create update and delete financial manual journal entry
 **/
@isTest
private class ManualFinancialJournalControllerTest {
    @isTest
    static void ManualFinancialJournalCRUDTest() {

        /*Create new finacial journal entry block*/
        PageReference pageRef = Page.ManualFinancialJournal;
        Test.setCurrentPage(pageRef);

        Financial_Account__c fa = TestHandler.getFinancialAccount1();
        Financial_Journal_Line__c fjl = new Financial_Journal_Line__c(Financial_Account__c = fa.id, Transaction_Date__c = Date.today(), Posted__c = true, Amount__c = 10);
        ApexPages.StandardController sc = new ApexPages.StandardController(fjl);
        ManualFinancialJournalController apc = new ManualFinancialJournalController(sc);

        Test.startTest();

        List<ManualFinancialJournalController.ManualJournalLine> initialGrids = apc.manEntry.getJournalList();
        system.assertEquals(initialGrids.size(), 10);

        apc.numberLinesToAdd = 10;
        apc.addNewEntryLines();
        initialGrids = apc.manEntry.getJournalList();
        system.assertEquals(initialGrids.size(), 20);

        apc.manEntry.mjlList.get(0).linecrd = '10';
        apc.manEntry.mjlList.get(0).fjl.Financial_Account__c = fa.id;
        apc.manEntry.mjlList.get(0).fjl.Description__c = 'Test finacial journal line';

        apc.manEntry.mjlList.get(1).debit = '10';
        apc.manEntry.mjlList.get(1).fjl.Financial_Account__c = fa.id;
        apc.manEntry.mjlList.get(1).fjl.Description__c = 'Test finacial journal line';
        apc.calDebCredTotal();

        apc.addNewEntry();

        List<Financial_Journal_Entry__c> fjeLst = (List<Financial_Journal_Entry__c>)Data.read(
                    'select Id, Name, Entry_Date__c, Description__c, Notes__c, Posted__c, Post_Date__c, (select id, Name, Credit__c, Debit__c,Financial_Account__c, Description__c, Amount__c from Financial_Journals__r) from Financial_Journal_Entry__c where Manual_Entry__c = :isManual',
        new Map<String, Object> {
            'isManual' => true
        }
                );

        System.assertEquals(fjeLst.get(0).Financial_Journals__r.size(), 2);
        /**Insert new new entries ends**/

        /**Update existing entries start**/
        apc.cSelId = apc.getmanualEntries().get(0).fje.id;
        apc.setSelFJE();
        apc.numberLinesToAdd = 10;
        apc.addNewExistingLines();

        apc.selectedMe.mjlList.get(2).linecrd = '10';
        apc.selectedMe.mjlList.get(2).fjl.Financial_Account__c = fa.id;
        apc.selectedMe.mjlList.get(2).fjl.Description__c = 'Test finacial journal line';

        apc.selectedMe.mjlList.get(3).debit = '10';
        apc.selectedMe.mjlList.get(3).fjl.Financial_Account__c = fa.id;
        apc.selectedMe.mjlList.get(3).fjl.Description__c = 'Test finacial journal line';

        //Delete one manual journal line at the time of editing the grid
        apc.fjeId = apc.getmanualEntries().get(0).fje.id;
        apc.fjlId = apc.selectedMe.mjlList.get(1).fjl.id;
        apc.delFJL();

        apc.updateEntry();
        apc.closeSelectedME();

        fjeLst = (List<Financial_Journal_Entry__c>)Data.read(
                     'select Id, Name, Entry_Date__c, Description__c, Notes__c, Posted__c, Post_Date__c, (select id, Name, Credit__c, Debit__c,Financial_Account__c, Description__c, Amount__c from Financial_Journals__r) from Financial_Journal_Entry__c where Manual_Entry__c = :isManual',
        new Map<String, Object> {
            'isManual' => true
        }
                 );

        System.assertEquals(fjeLst.get(0).Financial_Journals__r.size(), 3);
        /**Update existing entries end**/

        /**Delete manual journal entry start**/
        apc.cSelDelId = apc.getmanualEntries().get(0).fje.id;
        apc.delSelFJE();
        System.assertEquals(apc.getmanualEntries().size(), 0);       
        /**Delete manual journal entry end**/

        /**Post journal entry section start**/
        //Create financial journal entry again to post it previously created entry is deleted.
        ManualFinancialJournalController postapc = new ManualFinancialJournalController(sc);    
        postapc.manEntry.mjlList.get(0).linecrd = '10';
        postapc.manEntry.mjlList.get(0).fjl.Financial_Account__c = fa.id;
        postapc.manEntry.mjlList.get(0).fjl.Description__c = 'Test finacial journal line';

        postapc.manEntry.mjlList.get(1).debit = '10';
        postapc.manEntry.mjlList.get(1).fjl.Financial_Account__c = fa.id;
        postapc.manEntry.mjlList.get(1).fjl.Description__c = 'Test finacial journal line';
    
        postapc.addNewEntry();
        postapc.getmanualEntries().get(0).post=true;
        postapc.postFJE();
        /**Post journal entry ends section**/

        /**Load and set recurring template**/
        Financial_Journal_Entry__c recurringEntry=new Financial_Journal_Entry__c();
        recurringEntry.Manual_Entry__c=false;
        recurringEntry.Recurring_Entry__c=true;
        recurringEntry.Recurring_Journal_Frequency__c='Monthly';
        recurringEntry.Recurring_Entry_Name__c='TestEntry';
        Data.Create(recurringEntry);

        Financial_Journal_Line__c recurringLine=new Financial_Journal_Line__c();
        recurringLine.Amount__c = 10;
        recurringLine.Financial_Account__c = fa.id;
        recurringLine.Description__c = 'Test finacial journal line';
        recurringLine.Recurring_Journal_Line__c = true;
        recurringLine.Financial_Journal_Entry__c=recurringEntry.id;
        Data.Create(recurringLine);

        postapc.recurringEntry.Recurring_Journal_Frequency__c='Monthly';
        postapc.loadTemplates();
        postapc.selectedTemplate=recurringEntry.id;
        postapc.setRecurringEntry();
        /**Load and set recurring template End**/
        Test.stopTest();
    }
}