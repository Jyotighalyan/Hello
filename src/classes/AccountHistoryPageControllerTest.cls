@isTest
public with sharing class AccountHistoryPageControllerTest
{

    @isTest
    static void testAccountHistoryPage()
    {
        PageReference pageRef = Page.AccountHistory;
        Test.setCurrentPage(pageRef);
        Account acc = new Account(Name='testacc');
		Contact con = new Contact(LastName='test',AccountId=acc.id,Account_Balance__c=1.00);
        TXN__c txn = new TXN__c(Bill_To_member__c = con.id, Amount__c = 5.00, Date__c = Date.today());
        //System.currentPageReference().getParameters().put('Id', 'member');
		ApexPages.StandardController sc = new ApexPages.StandardController(con);
        AccountHistoryPageController accountHistory = new AccountHistoryPageController(sc);
        accountHistory.startDate = Date.today();

        Test.startTest();
        String accountBalance = accountHistory.getCurrentAccountBalanceFormat();
		String accountBalanceByDate = accountHistory.getAccountBalanceByDate();
        String passedTXNList = '[' + txn.id + ']';
        String remoteBalance = AccountHistoryPageController.AccountBalanceByDate(Date.today(), passedTXNList);
        Test.stopTest();
    }
}