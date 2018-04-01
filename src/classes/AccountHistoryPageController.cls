public with sharing class AccountHistoryPageController {
    public String startDateStr { get; set; }
    public Date startDate { get; set; }
    public Date endDate { get; set; }
    public List<TXN__c> txnList { get; set; }
    private final Contact contact;

    public AccountHistoryPageController(ApexPages.StandardController stdController) {

        if (!Test.isRunningTest()) stdController.addFields(new List<String> {'Bill_To_Member__c', 'Account_Balance__c'});
        this.contact = (Contact)stdController.getRecord();
        String billToMember = contact.Id;
        if (contact.Bill_To_Member__c != null) {

            billToMember = contact.Bill_To_Member__c;
        }

        txnlist = (List<TXN__c>)Data.read('SELECT Date__c, Customer__r.Name, Bill_To_Member__c, Recordtype.Name, Name,'
                                          + ' Description__c, GlobalType__c, GlobalSubType__c, Total_Amount__c, Bill_to_Member__r.Name'
                                          + ' FROM TXN__c WHERE Bill_To_Member__c = :billToMember AND RecordType.Name != :taxes AND RecordType.Name != :serviceCharge AND RecordType.Name != :deposit',
        new map<String, Object> {
            'billToMember' => billToMember,
            'taxes' => 'Taxes',
            'serviceCharge' => 'Service Charges',
            'deposit' => 'Deposit'
        });

        system.debug(txnlist.size());
        startDate = System.Date.today().toStartOfMonth();
        endDate = System.Date.today().addMonths(1).toStartofMonth().addDays(-1);

    }
    public String getAccountBalanceByDate() {
        String accountTotal;
        system.debug('startdate: ' + startDate + 'txnlist: ' + txnlist);
        if (startDate != null) {
            for (TXN__c txn : txnList) {
                if (txn.Date__c <= startDate) accountTotal += txn.Total_Amount__c;
            }
        }
        return accountTotal;
    }
    @RemoteAction
    public static String AccountBalanceByDate(Date startDate, String txnListstr) {
        Decimal accountTotal = 0.00;
        system.debug('startdate: ' + startDate + 'txnlist: ' + txnliststr);
        txnListstr = txnListstr.replace('[', '');
        txnListstr = txnListstr.replace(']', '');
        List<String> txnListsplit = txnliststr.split(',');       
        List<TXN__c> txnlist = (List<TXN__c>)Data.read('SELECT Date__c, Customer__r.Name,'
                               + ' Bill_To_Member__c, Recordtype.Name, Name, Description__c, GlobalType__c,'
                               + ' GlobalSubType__c, Total_Amount__c, Bill_to_Member__r.Name'
                               + ' FROM TXN__c WHERE Id IN :txnids',

        new Map<String, Object> {
            'txnids' => txnListsplit
        });

        if (startDate != null) {
            for (TXN__c txn : txnList) {
                if (txn.Date__c <= startDate) accountTotal += txn.Total_Amount__c;
            }
        }
        accountTotal.setScale(2);
        return string.valueOf(accountTotal);
    }
    public String getCurrentAccountBalanceFormat() {
        Decimal conTotal = 0.00;
        if (contact.Account_Balance__c != null) conTotal = contact.Account_Balance__c.setScale(2);
        return string.valueOf(conTotal);
    }
}