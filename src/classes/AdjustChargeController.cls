public class AdjustChargeController {

    public String eventId{set;get;}
    public String transactionId {get; set;}
    
    public AdjustChargeController(ApexPages.StandardController controller) {
        transactionId = ApexPages.currentPage().getParameters().get('Id');
        //System.debug('transactionId=====>'+transactionId);
        List<TXN__c> txnTransactionList = Data.read('Select id, Reservation__c from TXN__c where id =: transactionId', new Map<String,Object> {'transactionId' =>transactionId});
        eventId = txnTransactionList[0].Reservation__c;
        //System.debug('eventId=====>'+eventId);
    }
}