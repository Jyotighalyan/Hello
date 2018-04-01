public with sharing class MassPaymentCaptureService {
	public MassPaymentCaptureService(){
        
    }
    public class paymentWrapper{
        public Integer index{get;set;}
        public string amount{get;set;}
        public TXN__c txnObj{get;set;}
        public paymentWrapper(Integer i, TXN__c data,string Amt){
            index = i;
            amount=Amt;
            txnObj=data;
        }
    }
    public Map<Integer,paymentWrapper> addMoreRows(integer LastIndex, Map<Integer,paymentWrapper> payList){
        lastIndex++;
        integer max=lastIndex + 5;
        for(Integer i=lastIndex;i<max;i++){
            TXN__c newObj=new TXN__c();
            payList.put(i,new paymentWrapper(i, newObj,''));
            lastIndex=i;
        }
        return payList;
    }
    
}