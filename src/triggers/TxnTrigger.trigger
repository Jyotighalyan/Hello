/*
 *  Method for triggering automatic updates to Account_Balance__c field on Contacts
 *  when TXN__c objects are created, updated, and deleted.
 *
 */

trigger TxnTrigger on TXN__c (before insert, after insert, after update,before update, after delete) {
Map<ID, TXN__c> nonTaxOrServiceChargeTXNs = new Map<Id,TXN__c>();
    //triggered after insertion of a new TXN
    if (trigger.isInsert) {
        for (TXN__c txn : Trigger.new) {
                if (txn.recordtype.Name != 'Taxes' && txn.recordtype.Name != 'Service Charges') nonTaxOrServiceChargeTXNs.put(txn.id, txn);
            }

        if (trigger.isBefore) {
            
            TxnTriggerHandler.TransactionCheckAfterInsert(Trigger.new);
            TxnTriggerHandler.setGuestPassOnTXN(trigger.New);
            TxnTriggerHandler.TransactionCheckBeforeInsert(Trigger.new);
            TxnTriggerHandler.methodToSetBillToMember(Trigger.new);
            TxnTriggerHandler.TxnBalanceAmountRemainingBeforeInsert(Trigger.new);
            TxnTriggerHandler.financialMonster(trigger.new); 

        } else if (trigger.isAfter) {              
            TxnTriggerHandler.updateContactWithBalance(trigger.new, null); //Added for ME-561
            TxnTriggerHandler.handleEventDeposit(trigger.new); //Added for ME-561
            TxnTriggerHandler.getGuestPassIdsFromTXNs(trigger.new); //ME-606
           // Map<Map<String, Id>, Map<String, Id>> financialAccounts = TxnTriggerHandler.populateDebitCreditAccountOnRecord(trigger.new); 
            TxnTriggerHandler.TxnCreateTaxService(nonTaxOrServiceChargeTXNs);            
        }
    }
    //triggered after a TXN update
    if (trigger.isUpdate) {    
        if (Trigger.isBefore) {                       
            TxnTriggerHandler.methodToSetBillToMember(Trigger.new);
            List<TXN__c> remainingTransactions = new List<TXN__c>();
            
            for(TXN__c remaining:Trigger.new)
            {                                   
                if(remaining.Credit_Financial_Account__c!=null && remaining.Debit_Financial_Account__c!=null && remaining.Financial_Journal_Entry__c==null)
                {                
                    remainingTransactions.add(remaining);
                }
            }

            if(remainingTransactions.size()>0)
            {                
                TxnTriggerHandler.financialMonster(remainingTransactions); 
            }
        }
        //Added for ME-561 - Start
        if (Trigger.isAfter) {         
            TxnTriggerHandler.updateContactWithBalance(trigger.new, trigger.OldMap);
            TxnTriggerHandler.handleEventDeposit(trigger.new); 

            TxnTriggerHandler.getGuestPassIdsFromTXNs(trigger.new); //ME-606
            TxnTriggerHandler.rollupPaymentReceivedOnEvent(trigger.new,trigger.OldMap,'update'); //ME-606              
        }
        //End
    }
    //triggered before a TXN deletion
    if (trigger.isDelete) {
        TxnTriggerHandler.updateContactWithBalance(trigger.old, null);
    }
}