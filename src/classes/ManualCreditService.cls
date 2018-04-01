public with sharing class ManualCreditService {
	public ManualCreditService(){
        
    }
    public class CreditSplitWrapper{
        public Integer index{get;set;}
        public string DebitAmt{get;set;}
        public TXN__c manCredit{get;set;}
        public CreditSplitWrapper(Integer i, TXN__c data,string dAmt){
            index = i;
            DebitAmt=dAmt;
            manCredit=data;
        }
    }
    public Map<Integer,CreditSplitWrapper> addMoreRows(integer LastIndex, Map<Integer,CreditSplitWrapper> payList){
        lastIndex++;
        integer max=lastIndex + 5;
        for(Integer i=lastIndex;i<max;i++){
            TXN__c newObj=new TXN__c();
            payList.put(i,new CreditSplitWrapper(i, newObj,''));
            lastIndex=i;
        }
        return payList;
    }
    
}