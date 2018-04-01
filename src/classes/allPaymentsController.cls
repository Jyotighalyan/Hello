public with sharing class allPaymentsController {
    public List<TXN__c> txnList {get; set;}
    public List<paymentWrapper> wrapperList {get; set;}
    public String memberId {get; set;}
    public String memberName {get; set;}
    public String PaymentId {get; set;}
    public String linkToRefund {get; set;}
    public String FromLink {get; set;}
    public String currentPage {get; set;}
    Public  allPaymentsController() {

        //String recType = [SELECT ID FROM RecordType WHERE SobjectType =:'TXN__c' AND DeveloperName =:'Payment'].id;
        String recType = Utility.searchRecordType('Payment', 'TXN__c');
        memberId = Apexpages.currentPage().getParameters().get('memberId');
        memberName = Apexpages.currentPage().getParameters().get('memberName');
        PaymentId = Apexpages.currentPage().getParameters().get('PaymentId');
        linkToRefund = '/apex/allPayments?memberId=' + memberId;
        FromLink = '/' + memberId;
        currentPage = 'All-Payments';

        //Map<Id, TXN__c> temptxnList = new Map<Id, TXN__c>([Select Id, RecordType.Name, Name, Amount__c, Payment_Type__c, Date__c, Description__c, Bill_To_Member__c, Customer__c, Bill_To_member__r.Name, Customer__r.Name
        //           From TXN__c
        //           Where Bill_To_Member__c = :string.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('memberId')) AND RecordType.Name = 'Payment']);

        Map<Id, TXN__c> temptxnList = new Map<Id, TXN__c>((List<TXN__c>)Data.read('Select Id, RecordType.Name, Name, Amount__c,'
                + ' Payment_Type__c, Date__c, Description__c, Bill_To_Member__c, Customer__c, Bill_To_member__r.Name,'
                + ' Customer__r.Name From TXN__c Where Bill_To_Member__c = :billToMember AND RecordType.Name = :rtypeName',
        new Map<String, Object> {
            'billToMember' => Apexpages.currentPage().getParameters().get('memberId'),
            'rtypeName' => 'Payment'
        }));

        txnList = new List<TXN__c>();
        wrapperList = new List<paymentWrapper>();
        Map<Id, List<TXN__c>> testMap = new Map<Id, List<TXN__c>>();

        //for (TXN__c tx : [SELECT Id, Related_To__c, Related_To__r.Amount__c, Amount__c
        //                  FROM TXN__c
        //                  WHERE Related_To__c IN :temptxnlist.keySet() AND RecordType.Name = 'Refund']) 
        for (TXN__c tx : (List<TXN__c>)Data.read('SELECT Id, Related_To__c, Related_To__r.Amount__c, Amount__c'
                        +' FROM TXN__c'
                        +' WHERE Related_To__c IN :relatedToList AND RecordType.Name =:recTypeName',
                        new Map<String,Object>{
                            'relatedToList'=>temptxnlist.keySet(),
                            'recTypeName' =>  'Refund'
                            })) 
        {
            List<TXN__c> temp = testMap.get(tx.Related_To__c);
            if (temp == null) {
                testMap.put(tx.Related_To__c, new List<TXN__c> {tx});
            } else {
                temp.add(tx);
            }
        }

        if (testMap.size() > 0) {
            for (Id relatedID : testMap.keySet()) {
                List<TXN__c> tempTXN = testMap.get(relatedID);
                Double parentAmount = tempTXN[0].Related_To__r.Amount__c;
                Double childAmounts = 0.00;
                for (TXN__c childTXN : tempTXN) {
                    childAmounts += childTXN.Amount__c;
                }

                if (childAmounts < Math.abs(parentAmount)) {
                    paymentWrapper tempWrapper = new paymentWrapper();
                    tempWrapper.txn = temptxnList.get(relatedID);
                    tempWrapper.refunded = childAmounts;
                    tempWrapper.amount_left = Math.abs(parentAmount) - childAmounts;

                    wrapperList.add(tempWrapper);

                    temptxnList.remove(relatedId);
                } else {
                    temptxnList.remove(relatedId);
                }
            }
        }
        system.debug(temptxnList);
        for (TXN__c txn : temptxnList.values()) {
            paymentWrapper tempWrapper = new paymentWrapper();
            tempWrapper.txn = txn;
            tempWrapper.refunded = 0.00;
            tempWrapper.amount_left = Math.abs(txn.Amount__c);
            wrapperList.add(tempWrapper);
        }
    }
    public class paymentWrapper {
        public TXN__c txn {get; set;}
        public double refunded {get; set;}
        public double amount_left {get; set;}
    }
}