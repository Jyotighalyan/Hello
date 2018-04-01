/*
*  Logic for txnUpdateContactBalanceTrigger that triggers automatic updates to Account_Balance__c field on Contacts
*  when TXN__c objects are created, updated, and deleted.
*
*
*/
public class TxnTriggerHandler {

    private static boolean run = true;
    public static Map<Map<String, Id>, Map<String, Id>> populateDebitCreditAccountOnRecord(List<TXN__c> triggerNew) {
        Map<ID, Schema.RecordTypeInfo> rt_Map = TXN__c.sObjectType.getDescribe().getRecordTypeInfosById();
        Map<Map<String, Id>, Map<String, Id>> financialAccountsMappedToRecordType = new Map<Map<String, Id>, Map<String, Id>>();
        List<TXN__c> updateRecords = new List<TXN__c>();
        Map<String, String> creditAccountMap = new Map<String, String>();
        Map<String, String> debitAccountMap = new Map<String, String>();
        Set<String> recordTypesMapped = new Set<String> {'Refund', 'Deposit', 'Payment', 'Charge'};
        for (TXN__c newTran : triggerNew) {

            if (rt_map.get(newTran.recordTypeID).getName().containsIgnoreCase('Refund')) {
                creditAccountMap.put('Refund', newTran.Payment_Type__c);
                debitAccountMap.put('Refund', 'Accounts Receivable');

            } else if (rt_map.get(newTran.recordTypeID).getName().containsIgnoreCase('Deposit')) {
                creditAccountMap.put('Deposit', 'Prepaid Deposits');
                debitAccountMap.put('Deposit', 'Bank Account');

            } else if (rt_map.get(newTran.recordTypeID).getName().containsIgnoreCase('Payment') && newTran.Status__c != 'Unpaid') {
                creditAccountMap.put('Payment', 'Accounts Receivable');
                debitAccountMap.put('Payment', newTran.Payment_Type__c);

            } else if (rt_map.get(newTran.recordTypeID).getName().containsIgnoreCase('Charge')) {
                creditAccountMap.put('Charge', 'Accounts Payable');
                debitAccountMap.put('Charge', 'Accounts Receivable');
            }
        }
        financialAccountsMappedToRecordType = Utility.getCreditAndDebitAccountsByRecordType(creditAccountMap, debitAccountMap);
        for(TXN__c txn: triggerNew){
            if (rt_map.get(txn.recordTypeID).getName().containsIgnoreCase('Adjustment')){
                List<Id> relatedTransId = new List<Id>();
        		Map<Id, TXN__c> transQueryMap = new Map<Id, TXN__c>();
        
		        for (TXN__c newTran : triggerNew) relatedTransId.add(newTran.Related_To__c);
        		transQueryMap = getparentData(relatedTransId);
                TXN__c tempTXN = transQueryMap.get(txn.Related_To__c);
                TXN__c updateRec=new TXN__c();
                updateRec.Debit_Financial_Account__c=tempTXN.Credit_Financial_Account__c;
                updateRec.Credit_Financial_Account__c=tempTXN.Debit_Financial_Account__c;
                updateRec.id=txn.id;
                updateRecords.add(updateRec);
            }else{
                for(Map<String, Id> creditAccMap: financialAccountsMappedToRecordType.keyset()){
                    for(Map<String, Id> debitAccMap: financialAccountsMappedToRecordType.values()){
                        if(recordTypesMapped.contains(rt_map.get(txn.recordTypeID).getName())){
                            if(txn.Status__c!='Unpaid' || !rt_map.get(txn.recordTypeID).getName().containsIgnoreCase('Payment')){
                                if((creditAccMap.get(rt_map.get(txn.recordTypeID).getName()) == null 
                                    || debitAccMap.get(rt_map.get(txn.recordTypeID).getName()) == null) 
                                   && (rt_map.get(txn.recordTypeID).getName() == 'Charge' 
                                       && debitAccMap.get(rt_map.get(txn.recordTypeID).getName()) == null)){
                                           txn.addError('Please make sure that financial account mapping is done for this transaction.', false);
                                       }else{// if(creditAccMap.get(rt_map.get(txn.recordTypeID).getName()) == debitAccMap.get(rt_map.get(txn.recordTypeID).getName())){
                                           
                                           TXN__c updateRecord = new TXN__c();
                                           updateRecord.id = txn.id;
                                           if(txn.Credit_Financial_Account__c==null){
                                               updateRecord.Credit_Financial_Account__c = creditAccMap.get(rt_map.get(txn.recordTypeID).getName());
                                           }
                                           if(txn.Debit_Financial_Account__c==null){
                                               updateRecord.Debit_Financial_Account__c = debitAccMap.get(rt_map.get(txn.recordTypeID).getName());
                                           }
                                           updateRecords.add(updateRecord);
                                       }
                            }
                        }              
                    }                
                }
            } 
        }
        
        data.modify(updateRecords);
        return financialAccountsMappedToRecordType;
    }
    public static Map<Id, TXN__c> getparentData(List<Id> relatedTransId){
        Map<Id, TXN__c> transQueryMap = new Map<Id, TXN__c>();
        for (TXN__c tranLoop :(List<TXN__c>) Data.Read('SELECT Id,Credit_Financial_Account__c,Debit_Financial_Account__c, Reservation__c, Reservation__r.Name, Line_Item__c FROM TXN__c WHERE ID IN :relatedTransId', new Map<String, Object>{'relatedTransId' => relatedTransId})) {
            transQueryMap.put(tranLoop.id, tranLoop);
        }
        return transQueryMap;
    }
    public static void TransactionCheckBeforeInsert(List<TXN__c> triggerNew){
        List<Id> relatedTransId = new List<Id>();
        Map<Id, TXN__c> transQueryMap = new Map<Id, TXN__c>();
        List<Id> refundIds = new List<Id>();
        List<TXN__c> charges = new List<TXN__c>();

        Map<ID, Schema.RecordTypeInfo> rt_Map = TXN__c.sObjectType.getDescribe().getRecordTypeInfosById();
        for (TXN__c newTran : triggerNew) relatedTransId.add(newTran.Related_To__c);
        for (TXN__c tranLoop : (List<TXN__c>) Data.Read('SELECT Id, Reservation__c, Reservation__r.Name, Line_Item__c FROM TXN__c WHERE ID IN :relatedTransId', new Map<String, Object> {'relatedTransId' => relatedTransId})) {
            transQueryMap.put(tranLoop.id, tranLoop);
        }
        for (TXN__c newTran : triggerNew) {
            if (rt_map.get(newTran.recordTypeID).getName().containsIgnoreCase('Adjustment')) {
                if (newTran.Related_To__c != null && newTran.Line_Item__c == null) {
                    TXN__c tempTXN = transQueryMap.get(newTran.Related_To__c);
                    if (tempTXN.Line_Item__c != null) {
                        newTran.addError('Please make your Adjustment from the Banquet in question. <a href="/' + tempTXN.Reservation__c + '">' + tempTXN.Reservation__r.Name + '</a>', false);
                    }
                }
            }
            if (rt_map.get(newTran.recordTypeID).getName().containsIgnoreCase('Charge')) {
                charges.add(newTran);
            }
        }


    }

    public static void TransactionCheckAfterInsert(List<TXN__c> triggerNew) {
        List<Id> relatedTransId = new List<Id>();
        Map<Id, TXN__c> transQueryMap = new Map<Id, TXN__c>();
        List<Id> refundIds = new List<Id>();


        Map<ID, Schema.RecordTypeInfo> rt_Map = TXN__c.sObjectType.getDescribe().getRecordTypeInfosById();


        for (TXN__c newTran : triggerNew) {
            if (rt_map.get(newTran.recordTypeID).getName().containsIgnoreCase('Refund')) {
                refundIds.add(newTran.Id);
                relatedTransId.add(newTran.Related_To__c);
            }
        }
        if (refundIds.size() > 0) {
            
            Map<Id, List<TXN__c>> testMap = new Map<Id, List<TXN__c>>();

            for (TXN__c tx : (List<TXN__c>)Data.read('SELECT Id, Related_To__c, Related_To__r.Amount__c, Amount__c '
                    + 'FROM TXN__c '
                    + 'WHERE Related_To__c IN :relatedTransId',
                    new Map<String, Object> {'relatedTransId' => relatedTransId})) {
                List<TXN__c> temp = testMap.get(tx.Related_To__c);
                if (temp == null) {
                    testMap.put(tx.Related_To__c, new List<TXN__c> {tx});
                } else {
                    temp.add(tx);
                }
            }
            for (Id relatedID : testMap.keySet()) {
                List<TXN__c> tempTXN = testMap.get(relatedID);
                Double parentAmount = tempTXN[0].Related_To__r.Amount__c;
                Double childAmounts = 0.00;
                for (TXN__c childTXN : tempTXN) {
                    childAmounts += childTXN.Amount__c;
                }
                system.debug(childAmounts);
                if (childAmounts > Math.abs(parentAmount)) {
                    for (TXN__c newTran : triggerNew) newTran.addError('You cannot refund more than the amount of the payment.', false);
                }
            }
        }
    }
    
    public static void TxnBalanceAmountRemainingBeforeInsert(List<TXN__c> triggerNew) {
        
        List<Id> billMemberIds = new List<Id>();
        List<Id> PaymentAndDepositesList = new List<Id>();
        String depositRecordTypeId = null;
        string paymentRecordTypeId = null;
        string creditRecordTypeId = null;
        string adjustmentRecTypeId = null;
        if (Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Deposit') != null) {
            depositRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Deposit').getRecordTypeId();
            PaymentAndDepositesList.add(depositRecordTypeId);
        }
        if (Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Payment') != null) {
            paymentRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
            PaymentAndDepositesList.add(paymentRecordTypeId);
        }
        if (Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Credit') != null) {
            creditRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Credit').getRecordTypeId();
            PaymentAndDepositesList.add(creditRecordTypeId);
        }
        if (Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Adjustment') != null) {
            adjustmentRecTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Adjustment').getRecordTypeId();
            PaymentAndDepositesList.add(adjustmentRecTypeId);
        }

        for (TXN__c txn : triggerNew) billMemberIds.add(txn.Bill_To_Member__c);
        
        List<TXN__c> txnsToSettleList = new List<TXN__c>();
        Map<id, TXN__c> txnsToSettleMap = new Map<Id, TXN__c>();
        List<TXN__c> historicalTxnList = new List<TXN__c>();
        List<TXN__c> historicalTxnChargesList = new List<TXN__c>();
        List<TXN__c> AllTXNsList = (List<TXN__c>)Data.read('SELECT Id, RecordTypeId, Amount__c, Related_To__c, Charge_Amount_Left__c,Amount_Remaining__c, Bill_To_Member__c, Date__c, GlobalType__c, Item_Code__c '
                                             + 'FROM TXN__c '
                                             + 'WHERE Settled__c = false AND '
                                             + 'Bill_To_Member__c IN :billMemberIds '
                                             //+ 'RecordTypeId IN :PaymentAndDepositesList '
                                             + 'ORDER BY Date__c ASC',
             new Map<String, Object> {
            'billMemberIds' => billMemberIds //,
            //'PaymentAndDepositesList' => PaymentAndDepositesList
        });
        Set<id> paymentAndDepositSet = new Set<Id>();
        paymentAndDepositSet.addall(PaymentAndDepositesList);

        for (TXN__c txn : AllTXNsList) {
            if (paymentAndDepositSet.contains(txn.RecordTypeId)) {
                historicalTxnList.add(txn);
            } else {
                historicalTxnChargesList.add(txn);
            }
        }

        for (TXN__c newTxn : triggerNew) {
            // set intial Amount_Remaining__c value on this TXN
            newTxn.Amount_Remaining__c = Math.abs(newTxn.Amount__c);
            if (newTxn.recordTypeId == depositRecordTypeId) {
                newTxn.Amount_Remaining__c = 0;
            }

            if (newTxn.recordTypeId != adjustmentRecTypeId && newTxn.recordTypeId != depositRecordTypeId && paymentRecordTypeId != newTxn.recordTypeId && creditRecordTypeId != newTxn.recordTypeId) {
                for (TXN__c relatedTxn : historicalTxnList) {
                    Boolean flag = isAmountOpposite(relatedTxn.Amount__c, newTxn.Amount__c);
                    // Check to make sure the amounts are opposite and our txns are related to the billed member
                    if (flag == true && newTxn.Bill_To_Member__c == relatedTxn.Bill_To_Member__c) {
                        // Iterate over old TXNs until the new TXN ever gets to zero Amount Remaining.
                        if (newTxn.Amount_Remaining__c > 0) {
                            // If new TXN has a greater Amount Remaining, reduce the value of Amount Remaining on the new TXN by the Amount Remaining on the old TXN. Set the Amount Remaining on the old TXN to zero
                            if (newTxn.Amount_Remaining__c > relatedTxn.Amount_Remaining__c) {
                                newTxn.Amount_Remaining__c -= relatedTxn.Amount_Remaining__c;
                                newTxn.Status__c = 'Partial';
                                relatedTxn.Amount_Remaining__c = 0;
                                txnsToSettleMap.put(relatedTxn.id, relatedTxn);
                                txnsToSettleList.add(relatedTxn);
                            }
                            // If new TXN has a smaller Amount Remaining, reduce the value of Amount Remaining on the *old* TXN by the Amount Remaining on the *new* TXN. Set the Amount Remaining on the *new* TXN to zero
                            if (newTxn.Amount_Remaining__c <= relatedTxn.Amount_Remaining__c) {
                                relatedTxn.Amount_Remaining__c -= newTxn.Amount_Remaining__c;
                                newTxn.Amount_Remaining__c = 0;
                                newTxn.Status__c = 'Fully Paid';
                                txnsToSettleMap.put(relatedTxn.id, relatedTxn);
                                txnsToSettleList.add(relatedTxn);
                            }
                        }
                    }
                }
            } else {

                //process adjustment on related charges only first
                if(newTxn.recordTypeId==adjustmentRecTypeId){
                    for(TXN__c relatedTxn : historicalTxnChargesList){
                        Boolean flag = isAmountOpposite(relatedTxn.Amount__c, newTxn.Amount__c);
                        if (flag == true && newTxn.Bill_To_Member__c == relatedTxn.Bill_To_Member__c) {
                            if (relatedTxn.Amount_Remaining__c > 0 && newTxn.Amount_Remaining__c > 0) {
                                if(newTxn.recordTypeId==adjustmentRecTypeId && (newTxn.Related_To__c==relatedTxn.id || newTxn.Related_To__c==relatedTxn.Related_To__c)){
                                // If new TXN has a greater Amount Remaining, reduce the value of Amount Remaining on the new TXN by the Amount Remaining on the old TXN. Set the Amount Remaining on the old TXN to zero
                                    if (newTxn.Amount_Remaining__c >= relatedTxn.Amount_Remaining__c) {
                                        newTxn.Amount_Remaining__c -= relatedTxn.Amount_Remaining__c;
                                        relatedTxn.Amount_Remaining__c = 0;
                                        relatedTxn.Charge_Amount_Left__c = 0;
                                        relatedTxn.Status__c = 'Fully Paid';
                                        txnsToSettleMap.put(relatedTxn.id, relatedTxn);
                                        txnsToSettleList.add(relatedTxn);
                                    }
                                    // If new TXN has a smaller Amount Remaining, reduce the value of Amount Remaining on the *old* TXN by the Amount Remaining on the *new* TXN. Set the Amount Remaining on the *new* TXN to zero
                                    if (newTxn.Amount_Remaining__c < relatedTxn.Amount_Remaining__c) {
                                        relatedTxn.Amount_Remaining__c -= newTxn.Amount_Remaining__c;
                                        if (relatedTxn.Charge_Amount_Left__c != null) {
                                            relatedTxn.Charge_Amount_Left__c -= newTxn.Amount_Remaining__c;
                                        }
                                        relatedTxn.Status__c = 'Partial';
                                        newTxn.Amount_Remaining__c = 0;
                                        txnsToSettleMap.put(relatedTxn.id, relatedTxn);
                                        txnsToSettleList.add(relatedTxn);
                                    }
                                }   
                            }
                        }
                    }
                }
                if(newTxn.recordTypeId!=adjustmentRecTypeId || newTxn.Amount_Remaining__c>0){
                    for (TXN__c relatedTxn : historicalTxnChargesList) {
                        Boolean flag = isAmountOpposite(relatedTxn.Amount__c, newTxn.Amount__c);
                        if (flag == true && newTxn.Bill_To_Member__c == relatedTxn.Bill_To_Member__c) {
                            if (relatedTxn.Amount_Remaining__c > 0 && newTxn.Amount_Remaining__c > 0) {
                                // If new TXN has a greater Amount Remaining, reduce the value of Amount Remaining on the new TXN by the Amount Remaining on the old TXN. Set the Amount Remaining on the old TXN to zero
                                if (newTxn.Amount_Remaining__c >= relatedTxn.Amount_Remaining__c) {
                                    newTxn.Amount_Remaining__c -= relatedTxn.Amount_Remaining__c;
                                    relatedTxn.Amount_Remaining__c = 0;
                                    relatedTxn.Charge_Amount_Left__c = 0;
                                    relatedTxn.Status__c = 'Fully Paid';
                                    txnsToSettleMap.put(relatedTxn.id, relatedTxn);
                                    txnsToSettleList.add(relatedTxn);
                                }
                                // If new TXN has a smaller Amount Remaining, reduce the value of Amount Remaining on the *old* TXN by the Amount Remaining on the *new* TXN. Set the Amount Remaining on the *new* TXN to zero
                                if (newTxn.Amount_Remaining__c < relatedTxn.Amount_Remaining__c) {
                                    relatedTxn.Amount_Remaining__c -= newTxn.Amount_Remaining__c;
                                    if (relatedTxn.Charge_Amount_Left__c != null) {
                                        relatedTxn.Charge_Amount_Left__c -= newTxn.Amount_Remaining__c;
                                    }
                                    relatedTxn.Status__c = 'Partial';
                                    newTxn.Amount_Remaining__c = 0;
                                    txnsToSettleMap.put(relatedTxn.id, relatedTxn);
                                    txnsToSettleList.add(relatedTxn);
                                }
                            }
                        }
                    }
                }
            }
        }
        //data.modify(txnsToSettleList);
        data.modify(txnsToSettleMap.values());
    }
    private static Boolean isAmountOpposite(Decimal amt1, Decimal amt2) {
        return (amt1 > 0 && amt2 < 0) || (amt1 < 0 && amt2 > 0);
    }


    public static void updateContactWithBalance(List<TXN__c> triggerNew, Map<Id, TXN__c> triggerOldMap) {
        List<Id> contactIdsList = new List<Id>();

        for (TXN__c thisUpdatedTransaction : triggerNew) {
            if (thisUpdatedTransaction.Bill_To_Member__c != null && triggerOldMap == null) {
                contactIdsList.add(thisUpdatedTransaction.Bill_To_Member__c);
            }
            if (triggerOldMap != null ) {
                if (thisUpdatedTransaction.Bill_To_Member__c != triggerOldMap.get(thisUpdatedTransaction.Id).Bill_To_Member__c) {
                    contactIdsList.add(triggerOldMap.get(thisUpdatedTransaction.Id).Bill_To_Member__c);
                    contactIdsList.add(thisUpdatedTransaction.Bill_To_Member__c);
                } else if (thisUpdatedTransaction.Amount_Remaining__c != triggerOldMap.get(thisUpdatedTransaction.Id).Amount_Remaining__c) {
                    contactIdsList.add(thisUpdatedTransaction.Bill_To_Member__c);
                }
            }
        }
        if (!contactIdsList.isEmpty()) {
            ContactRollupService.updateContactWithAccountBalance(contactIdsList);
        }
    }
    
    /**
     * TxnCreateTaxService Method to generate Tax and Service Charge TXNs automatically on the
     * Creation of a Charge TXN based on Type and Subtype mappings.
     * @param  chargeMap trigger.NewMap passed in
     */
    public static void TxnCreateTaxService(Map<Id, TXN__c> triggerNewMap) {
        Map<Map<String, Id>, Map<String, Id>> financialAccounts = populateDebitCreditAccountOnRecord(triggerNewMap.values());
        Id chargeRecordType = Utility.searchRecordType('Charge', 'TXN__c');
        Id adjustmentRecordType = Utility.searchRecordType('Adjustment', 'TXN__c');
        Id taxRecordType = Utility.searchRecordType('Taxes', 'TXN__c');
        Id serviceChargeRecordType = Utility.searchRecordType('Service Charges', 'TXN__c');
        Set<Id> recordTypesForTaxesAndServiceCharges = new Set<Id> {chargeRecordType, adjustmentRecordType};
            List<TXN__c> txnsToPopulateTaxesAndServiceCharges = new List<TXN__c>();
        List<TXN__c> taxAndServicesToInsert = new List<TXN__c>();
        List<Id> customerIds = new List<Id>();
        //Check TXNs in trigger context for record types that need taxes/service charges to save some time.
        for (TXN__c txn : triggerNewMap.values()) {
            if (recordTypesForTaxesAndServiceCharges.contains(txn.RecordTypeId) && txn.Is_Parent__c == true) {
                System.debug('// Found a matching TXN record type. Adding to List: ' + txnsToPopulateTaxesAndServiceCharges);
                txnsToPopulateTaxesAndServiceCharges.add(txn);
            }
        }
        System.debug('// Before calling lookupTaxesAndServices(). Passing: ' + txnsToPopulateTaxesAndServiceCharges);
        //Using list of relevent TXNs look up Taxes and Service Charges.
        Map<Id, List<Map<String, Decimal>>> taxAndServiceInfo = lookupTaxesAndServices(txnsToPopulateTaxesAndServiceCharges);
        System.debug('// Returned from lookupTaxesAndServices(). Returned: ' + taxAndServiceInfo);
        Set<String>taxAndServiceNames = new Set<String>();
        //Find the tax and service charge names that will be used for these TXNs
        for (TXN__c txn : txnsToPopulateTaxesAndServiceCharges) {
            System.debug('// Iterate through all txns. Current txn: ' + txn);
            System.debug('// taxAndServiceInfo for current TXN: ' + taxAndServiceInfo.get(txn.Id));
            if (taxAndServiceInfo.containsKey(txn.Id)) {
                System.debug('// taxAndServiceInfo keyset contained txn.Id');
                if (taxAndServiceInfo.get(txn.Id).size() > 0) {
                    System.debug('// taxAndServiceInfo size > 0. Size = ' + taxAndServiceInfo.get(txn.Id).size());
                    for (Integer i = 0; i < taxAndServiceInfo.get(txn.Id).size(); i++) {
                        System.debug('// Iterate through the list. Current Map: ' + taxAndServiceInfo.get(txn.Id).get(i));
                        if (taxAndServiceInfo.get(txn.Id).get(i) != null || taxAndServiceInfo.get(txn.Id).get(i).isEmpty()) {
                            System.debug('// List !NULL || empty.');
                            for (String name : taxAndServiceInfo.get(txn.Id).get(i).keyset()) {
                                System.debug('// Iterate through keyset. Current tax/service name: ' + name);
                                taxAndServiceNames.add(name);
                            }
                        }
                    }
                }
            }
        }
        System.debug('// Call Utility.getTaxAndFinancialAccountMappings passing: ' + taxAndServiceNames);
        //Get the financial account mappings for these taxes/service charges.
        Map<String, Tax_To_Account_Mapping__c> taxServiceChargeMapping = Utility.getTaxAndFinancialAccountMappings(taxAndServiceNames);
        System.debug('// Returned from Utility.getTaxAndFinancialAccountMappings: ' + taxServiceChargeMapping);
        Map<Id, Map<String, Decimal>> taxes = new Map<Id, Map<String, Decimal>>();
        Map<Id, Map<String, Decimal>> services = new Map<Id, Map<String, Decimal>>();
        Map<Id, Map<String, Decimal>> serviceTaxes = new Map<Id, Map<String, Decimal>>();
        //Iterate through relevant TXNs and separate taxes/service charges/taxes applied to service charges
        for (TXN__c txn : txnsToPopulateTaxesAndServiceCharges) {
            System.debug('// Iterate through txns that need tax/services. Current txn: ' + txn);
            if (taxAndServiceInfo.containsKey(txn.Id)) {
                System.debug('// taxAndServiceInfo keyset contains txn.Id');
                if (taxAndServiceInfo.get(txn.Id).size() > 0) {
                    System.debug('// List for current txn is > 0');
                    System.debug('// tax/service maps for current TXN: ' + taxAndServiceInfo.get(txn.Id).get(0));
                    if (taxAndServiceInfo.get(txn.Id).get(0).size() > 0 && !taxAndServiceInfo.get(txn.Id).get(0).values().isEmpty()) {
                        taxes.put(txn.Id, taxAndServiceInfo.get(txn.Id).get(0));
                        System.debug('// Put all tax mappings into tax map. Current taxes: ' + taxAndServiceInfo.get(txn.Id).get(0));

                    } else {
                        System.debug('//No taxes for this TXN.' + txn);
                    }

                    if (taxAndServiceInfo.get(txn.Id).size() > 1) {
                        System.debug('// List of maps for current txn > 1');
                        if (taxAndServiceInfo.get(txn.Id).get(1).size() > 0 && !taxAndServiceInfo.get(txn.Id).get(1).values().isEmpty()) {
                            services.put(txn.Id, taxAndServiceInfo.get(txn.Id).get(1));
                            System.debug('// Put all tax mappings into service map. Current services: ' + taxAndServiceInfo.get(txn.Id).get(1));
                        } else {
                            System.debug('//No Service Charges for this TXN.' + txn);
                        }


                        if (taxAndServiceInfo.get(txn.Id).size() > 2) {
                            System.debug('// List of maps for current txn > 2');
                            if (taxAndServiceInfo.get(txn.Id).get(2).size() > 0 && !taxAndServiceInfo.get(txn.Id).get(2).values().isEmpty()) {
                                serviceTaxes.put(txn.Id, taxAndServiceInfo.get(txn.Id).get(2));
                                System.debug('// Put all tax mappings into service-taxes map. Current tax-services: ' + taxAndServiceInfo.get(txn.Id).get(2));
                            }
                        } else {

                            System.debug('// No taxes applied on the service charge for this TXN.' + txn);

                        }
                    }
                } else {
                    System.debug('// No Taxes or Services for this TXN.');
                }

            } else {
                System.debug('// Could not find this TXN. ' + txn);
            }
        }

        List<TXN__c> childTxns = new List<TXN__c>();
        System.debug('// taxes: ' + taxes);
        //Populate Tax TXNs if there are any
        if (!taxes.values().isEmpty() && taxes.values() != null) {
            System.debug('// There are taxes to populate.');
            System.debug('// Calling populateChildTxns passing: ' + taxes + ' ' + txnsToPopulateTaxesAndServiceCharges + ' ' + taxServiceChargeMapping + ' ' + financialAccounts + ' ' + taxRecordType);
            List<TXN__c> taxList = populateChildTxns(taxes, txnsToPopulateTaxesAndServiceCharges, taxServiceChargeMapping, financialAccounts, taxRecordType);
            System.debug('// Returning from populateChildTxns: ' + taxList);
            childTxns.addAll(taxList);
            System.debug('// Child txns to insert: ' + childTxns);

        } else {
            System.debug('No tax txns to populate.');
        }
        System.debug('// services: ' + services);
        //Populate Service Charge TXNs if there are any
        if (!services.values().isEmpty() && services.values() != null) {
            System.debug('// Calling populateChildTxns passing: ' + services + ' ' + txnsToPopulateTaxesAndServiceCharges + ' ' + taxServiceChargeMapping + ' ' + financialAccounts + ' ' + serviceChargeRecordType);
            List<TXN__c> serviceList = populateChildTxns(services, txnsToPopulateTaxesAndServiceCharges, taxServiceChargeMapping, financialAccounts, serviceChargeRecordType);
            System.debug('// Returning from populateChildTxns: ' + serviceList);
            childTxns.addAll(serviceList);
            System.debug('// Child txns to insert: ' + childTxns);
        } else {
            System.debug('No service txns to populate.');
        }
        System.debug('// serviceTaxes: ' + serviceTaxes);
        //Populate Taxes applied to Service Charges if there are any.
        if (!serviceTaxes.values().isEmpty() && serviceTaxes.values() != null) {
            System.debug('// Calling populateChildTxns passing: ' + serviceTaxes + ' ' + txnsToPopulateTaxesAndServiceCharges + ' ' + taxServiceChargeMapping + ' ' + financialAccounts + ' ' + taxRecordType);
            List<TXN__c> serviceTaxList = populateChildTxns(serviceTaxes, txnsToPopulateTaxesAndServiceCharges, taxServiceChargeMapping, financialAccounts, taxRecordType);
            System.debug('// Returning from populateChildTxns: ' + serviceTaxList);
            childTxns.addAll(serviceTaxList);
            System.debug('// Child txns to insert: ' + childTxns);
        } else {
            System.debug('No service taxes to populate.');
        }
        //Insert child TXNs
        Data.create(childTxns);
    }
    /**
     * lookupTaxesAndServices Method to lookup the tax/service charges and compute their amounts for the given transactions
     * @param  txns Transactions in the current trigger context that need taxes/service charges looked up.
     * @return      return Mapping of TXN__c ID to a map of tax/service charge name and amounts.
     */
    public static Map<Id, List<Map<String, Decimal>>> lookupTaxesAndServices(List<TXN__c> txns) {
        Map<Id, List<String>> taxToTxnMap = new Map<Id, List<String>>();
        Map<Id, List<String>> serviceToTxnMap = new Map<Id, List<String>>();
        Map<Id, List<String>> serviceTaxToTxnMap = new Map<Id, List<String>>();
        Set<String> allTypes = new Set<String>();
        Set<String> allSubTypes = new Set<String>();
        //Collect all the types/subtypes for the given TXNs
        for (TXN__c txn : txns) {
            allTypes.add(txn.GlobalType__c);
            allSubTypes.add(txn.GlobalSubType__c);
        }
        System.debug('// Gathered all types/subtypes: ' + allTypes + ' ' + allSubTypes);
        //Query for all possible mappings matching those type/subtype combinations
        List<TxnChargeToTaxMapping__c> possibleMappings = Data.read('SELECT Id, Type__c, Subtype__c, Service_Charge_applicable__c,'
                + ' Service_Charge_Name__c, TaxId__c, Tax_Name_applicable_on_service_charge__c,'
                + ' Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c'
                + ' WHERE Type__c IN :allTypes AND Subtype__c IN :allSubTypes',
        new Map<String, Object> {
            'allTypes' => allTypes,
            'allSubTypes' => allSubTypes
        });
        System.debug('// Query for all possible tax/service mappings: ' + possibleMappings);
        System.debug('// Loop through each TXN and check mappings to get taxes and service charges.');
        //Iterate through all the TXNs and find the matching mappings
        for (TXN__c txn : txns) {
            System.debug('// Current TXN to find taxes/services for: ' + txn);
            //Iterate through all the possible mappings
            for (TxnChargeToTaxMapping__c mappingToCheck : possibleMappings) {
                System.debug('// Current mapping to check against type/subtype of TXN: ' + mappingToCheck.Type__c + '/' + mappingToCheck.SubType__c);
                System.debug('=taxToTxnMaptaxToTxnMap====>' + taxToTxnMap);
                System.debug('=txn.Id====>' + txn.Id);
                if (txn.GlobalType__c != null && mappingToCheck.Type__c != null) {
                    System.debug('// mapping Type and TXN type != null');

                    System.debug('//Cond. Elements: ' + txn.GlobalType__c + '/' + mappingToCheck.Type__c
                                 + ', ' + txn.GlobalSubType__c + '/' + mappingToCheck.Subtype__c);
                    //Check if the mapping matches the type/subtype of the TXN
                    if (mappingToCheck.Type__c.equals(txn.GlobalType__c)
                            && (((txn.GlobalSubType__c != null && mappingToCheck.Subtype__c != null) && mappingToCheck.Subtype__c.equals(txn.GlobalSubType__c)) || (txn.GlobalSubType__c == null && mappingToCheck.Subtype__c == null))) {
                        System.debug('// types == and subtypes either null or equal.');
                        //If we have already found a tax add the new one to the list of existing taxes mapped to the current TXN (unless the TXN is tax exempt)
                        if (taxToTxnMap.containsKey(txn.Id) && !txn.Tax_Exempt__c) {
                            System.debug('// taxToTXNMap contains TXN.Id: ' + taxToTxnMap.get(txn.Id));
                            List<String> taxes = taxToTxnMap.get(txn.Id);
                            System.debug('// mapping.TaxId__c ' + mappingToCheck.TaxId__c);
                            taxes.add(mappingToCheck.TaxId__c);
                            taxToTxnMap.put(txn.Id, taxes);
                            System.debug('// taxes: ' + taxes);

                        } else { //If not, start the list

                            taxToTxnMap.put(txn.Id, new List<String> {mappingToCheck.TaxId__c});
                            System.debug('// taxToTxnMap: ' + taxToTxnMap);

                        }
                        System.debug('// taxToTXNMap: ' + taxToTXNMap);
                        //Check if there is a Service Charge
                        if (mappingToCheck.Service_Charge_applicable__c == true) {
                            System.debug('// Service Charge Applicable.');
                            if (mappingToCheck.Service_Charge_Name__c != null) {

                                System.debug('// mapping.Service_Charge_Name__c ' + mappingToCheck.Service_Charge_Name__c);
                                //If we find a Service Charge we add it but once we find it we don't need to look again.
                                if (!serviceToTxnMap.containsKey(txn.Id) && !serviceToTxnMap.containsKey(txn.Id) != null) {
                                    serviceToTxnMap.put(txn.Id, new List<String> {mappingToCheck.Service_Charge_Name__c});
                                }


                            }
                            //Check if Taxes apply to the Service Charge
                            if (mappingToCheck.Taxes_applicable_on_service_charge__c == true && !txn.Tax_Exempt__c) {
                                System.debug('// Taxes applicable on Service Charges.');
                                if (taxToTxnMap.containsKey(txn.Id)) {

                                    List<String> taxes = taxToTxnMap.get(txn.Id);
                                    System.debug('// TXN ID: ' + txn.Id);
                                    System.debug('// taxToTxnMap: ' + taxToTxnMap);
                                    List<String> taxesNotAppliedToServices = new List<String>();
                                    //Loop through all the taxes mapped to the TXN
                                    for (String taxName : taxes) {

                                        System.debug('// Current taxName: ' + taxName);
                                        //Check for taxes applying to Service Charges and remove them from the tax map
                                        //and adding them to the serviceTaxMap
                                        if (mappingToCheck.Tax_Name_applicable_on_service_charge__c != null) {

                                            System.debug('// mapping Tax_Name_applicable_on_service_charge__c !NULL');

                                            if (taxName.equals(mappingToCheck.Tax_Name_applicable_on_service_charge__c)) {

                                                System.debug('// taxName == mapping Tax_Name_applicable_on_service_charge__c');
                                                //If we already found taxes applicable to service charges add them to the existing list
                                                if (serviceTaxToTxnMap.containsKey(txn.Id)) {

                                                    System.debug('// serviceTaxToTxnMap contains TXN.Id: ' + serviceTaxToTxnMap.get(txn.Id));
                                                    List<String> taxOnServiceCharges = serviceTaxToTxnMap.get(txn.Id);
                                                    System.debug('// mappingToCheck.Tax_Name_applicable_on_service_charge__c: ' + mappingToCheck.Tax_Name_applicable_on_service_charge__c);
                                                    taxOnServiceCharges.add(mappingToCheck.Tax_Name_applicable_on_service_charge__c);
                                                    serviceTaxToTxnMap.put(txn.Id, taxOnServiceCharges);
                                                    System.debug('// tax on service charges: ' + taxOnServiceCharges);

                                                } else { //If not, start a list and map it to the TXN

                                                    serviceTaxToTxnMap.put(txn.Id, new List<String> {mappingToCheck.Tax_Name_applicable_on_service_charge__c});
                                                    System.debug('// serviceTaxToTxnMap: ' + serviceTaxToTxnMap);
                                                }

                                            } else { //Any taxes not applied to Service charges are added to this list
                                                taxesNotAppliedToServices.add(taxName);
                                                System.debug('// Taxes not applied to services: ' + taxesNotAppliedToServices);
                                            }

                                        } else {
                                            //Need to handle null values for mapping.Tax_Name_applicable_on_service_charge__c here.
                                            taxesNotAppliedToServices.add(taxName);
                                            System.debug('// Taxes not applied to services: ' + taxesNotAppliedToServices);
                                        }
                                    }
                                    //After removing any taxes that are applied onto Service charges we replace the regular tax list with this updated one.
                                    taxToTxnMap.put(txn.Id, taxesNotAppliedToServices);
                                }
                            }
                        }
                    }
                }
            }
        }

        System.debug('// tax to txn map: ' + taxToTxnMap);
        System.debug('// service tax to txn map ' + serviceTaxToTxnMap);
        System.debug('// service to txn map ' + serviceToTxnMap);

        Map<Id, List<Map<String, Decimal>>> childTxnInfoMap = new Map<Id, List<Map<String, Decimal>>>();
        Map<Id, Decimal> serviceChargeAmountMap = new Map<Id, Decimal>();
        //Iterate through the TXNs a second time and build final map to be returned
        for (TXN__c txn : txns) {

            Map<String, Decimal> taxInfo = new Map<String, Decimal>();
            Map<String, Decimal> serviceInfo = new Map<String, Decimal>();
            Map<String, Decimal> serviceTaxInfo = new Map<String, Decimal>();

            System.debug('// current txn entering section looking up tax/service percent and generating $-amounts //');
            //Check if this TXN has taxes
            if (taxToTxnMap.containsKey(txn.Id)) {
                System.debug('// taxToTxnMap contains txn.Id');
                //Iterate through the taxes and collect the name and the amount of the tax.
                for (String tax : taxToTxnMap.get(txn.Id)) {
                    if (tax != null && !tax.equals('')) {

                        System.debug('// Iterate over taxes. Current tax: ' + tax);
                        Decimal amount = (txn.Amount__c * (Utility.getPercentageOfTax(tax) / 100)).setScale(2);
                        System.debug('// txn.Amount = ' + txn.Amount__c);
                        System.debug('// tax percentage = ' + Utility.getPercentageOfTax(tax) / 100);
                        taxInfo.put(Utility.getNameOfTax(tax), amount);
                        System.debug('// Tax Info mapped: ' + Utility.getNameOfTax(tax) + ' ' + amount);
                    }

                }
            } else {
                System.debug('++No tax found.' + txn);
            }
            //Check if this TXN has a Service Charge
            if (serviceToTxnMap.containsKey(txn.Id)) {
                System.debug('// serviceToTxnMap contains txn.Id');
                //Collect the name and amount for the Service Charge
                for (String service : serviceToTxnMap.get(txn.Id)) {
                    System.debug('// Iterate over Services. Current Service Charge: ' + service);
                    Decimal Amount = (txn.Amount__c * (Utility.getPercentageOfServiceCharge(service) / 100)).setScale(2);
                    System.debug('// txn.Amount = ' + txn.Amount__c);
                    System.debug('// Service percentage = ' + Utility.getPercentageOfServiceCharge(service) / 100);
                    if (serviceTaxToTxnMap.containsKey(txn.Id) && serviceTaxToTxnMap.get(txn.Id) != null) {
                        System.debug('// service has tax applied.');
                        serviceChargeAmountMap.put(txn.Id, amount);
                        System.debug('// amount saved for tax to be applied in the next section: ' + txn.Id + ' => ' + amount);
                    }
                    serviceInfo.put(Utility.getNameOfServiceCharge(service), amount);
                    System.debug('// Service Info mapped: ' + Utility.getNameOfServiceCharge(service) + ' ' + amount);
                }
                //Check if there are Taxes applied on the Service Charge
                if (serviceTaxToTxnMap.containsKey(txn.Id)) {
                    System.debug('// serviceTaxToTxnMap contains txn.Id');
                    //Iterate through the Taxes and get names and amounts
                    for (String tax : serviceTaxToTxnMap.get(txn.Id)) {
                        if (tax != null && !tax.equals('')) {
                            System.debug('// Iterate over tax on services. Current tax on service: ' + tax);
                            Decimal Amount = ((txn.Amount__c + serviceChargeAmountMap.get(txn.Id)) * (Utility.getPercentageOfTax(tax) / 100)).setScale(2);
                            System.debug('// txn.Amount = ' + txn.Amount__c);
                            System.debug('// Service charge amount = ' + serviceChargeAmountMap.get(txn.Id));
                            System.debug('// Tax on Service percentage = ' + Utility.getPercentageOfTax(tax) / 100);
                            serviceTaxInfo.put(Utility.getNameOfTax(tax), amount);
                            System.debug('// Service-Tax Info mapped: ' + Utility.getNameOfTax(tax) + ' ' + amount);
                        }
                    }
                } else {
                    System.debug('++No Service Tax found.' + txn);
                }

            } else {
                System.debug('++No Service Charge found.' + txn);
            }

            System.debug('// Tax info mapped: ' + taxInfo);
            System.debug('// Service info mapped: ' + serviceInfo);
            System.debug('// Service-Tax info mapped: ' + serviceTaxInfo);
            //Collect the data in the maps to be returned
            childTxnInfoMap.put(txn.Id, new List<Map<String, Decimal>> {taxInfo, serviceInfo, serviceTaxInfo});


        }

        return childTxnInfoMap;
    }
    /**
     * populateChildTxns    Method to create the individual child Tax/Service charge TXNs.
     * @param  taxOrServiceMap         Names and Amounts of the taxes/service charges.
     * @param  parentTxns              Parent TXNs in the current trigger context.
     * @param  taxServiceChargeMapping Financial Account mappings for taxes and services.
     * @param  financialAccounts       Financial Account mappings for TXN record types.
     * @param  recordTypeIdForChild    Record type of child TXN.
     * @return                         Child TXNs produced by this method.
     */
    public static List<TXN__c> populateChildTxns(Map<Id, Map<String, Decimal>> taxOrServiceMap, List<TXN__c> parentTxns,  Map<String, Tax_To_Account_Mapping__c> taxServiceChargeMapping, Map<Map<String, Id>, Map<String, Id>> financialAccounts, Id recordTypeIdForChild) {
        Id chargeRecordType = Utility.searchRecordType('Charge', 'TXN__c');
        Id adjustmentRecordType = Utility.searchRecordType('Adjustment', 'TXN__c');
        Id taxRecordType = Utility.searchRecordType('Taxes', 'TXN__c');
        Id serviceChargeRecordType = Utility.searchRecordType('Service Charges', 'TXN__c');
        Set<Id> parentIds = new Set<Id>();
        List<Id> customerIds = new List<Id>();
        List<TXN__c> childTxns = new List<TXN__c>();
        //Iterate through parent TXNs and collect IDs and customer IDs.
        for (TXN__c txn : parentTxns) {
            System.debug('// Iterate over parent txns to collect IDs and Customer IDs. Current txn: ' + txn + ' Id: ' + txn.Id + ' Customer: ' + txn.Customer__c);
            parentIds.add(txn.Id);
            customerIds.add(txn.Customer__c);
        }
        System.debug('// parentIDs: ' + parentIds);
        System.debug('// Calling billToMember passing: ' + customerIds);
        Map<Id, Id> billToMemberMap = Utility.getBillToMember(customerIds);
        System.debug('// Returned from billToMember: ' + billToMemberMap);
        //Query for relevent parent TXN data and iterate through each TXN.
        for (TXN__c parentTxn : (List<TXN__c>)Data.read('SELECT Id, RecordTypeId, Related_To__c, Amount__c,Line_Item__c, Employee__c, '
                + 'Customer__c, Date__c, Reservation__r.Name, Reservation__r.Event_Date__c '
                + 'FROM TXN__c WHERE Id IN :parentIds',
                new Map<String, Object> {'parentIds' => parentIds})) {
            System.debug('//Iterate through parent TXNs. Current TXN: ' + parentTxn);
            //Check if this TXN needs child TXNs
            if (taxOrServiceMap.containsKey(parentTxn.Id)) {
                //Iterate through the taxes/services that are associated with the parent TXN and populate the fields
                for (String taxOrServiceName : taxOrServiceMap.get(parentTxn.Id).keyset()) {
                    System.debug('// Iterate through each tax/service. Current tax/service name: ' + taxOrServiceName);
                    TXN__c newTxn = new TXN__c();
                    if (parentTxn.RecordTypeId == adjustmentRecordType) {
                        System.debug('// TXN recordtype == adjustment.');
                        newTxn.Related_To__c = parentTxn.Related_To__c;
                        newTxn.RecordTypeId = adjustmentRecordType;

                    } else if (parentTxn.RecordTypeId == chargeRecordType) {
                        System.debug('// TXN recordtype == charge.');
                        newTxn.Related_To__c = parentTxn.Id;
                        System.debug('// Set Related_To: ' + newTxn.Related_To__c);
                        newTxn.RecordTypeId = recordTypeIdForChild;
                        System.debug('// Set record type: ' + newTxn.RecordTypeId);
                    }
                    if (recordTypeIdForChild == taxRecordType) {
                        System.debug('// recordTypeIdForChild == tax');
                        newTxn.Tax_Name__c = taxOrServiceName;
                        System.debug('// Set Tax Name: ' + newTxn.Tax_Name__c);
                        newTxn.Credit_Financial_Account__c = taxServiceChargeMapping.get(newTxn.Tax_Name__c).Financial_Accounts__c;
                        System.debug('// Set Credit Fin. Acct. ' + newTxn.Credit_Financial_Account__c);
                        newTxn.Date__c = parentTxn.Date__c;
                    } else if (recordTypeIdForChild == serviceChargeRecordType) {
                        System.debug('// recordTypeIdForChild == service charge');
                        newTxn.Service_Charge_Name__c = taxOrServiceName;
                        System.debug('// Set Service Charge Name: ' + newTxn.Service_Charge_Name__c);
                        newTxn.Credit_Financial_Account__c = taxServiceChargeMapping.get(newTxn.Service_Charge_Name__c).Financial_Accounts__c;
                        System.debug('// Set Credit Fin. Acct. ' + newTxn.Credit_Financial_Account__c);
                        newTxn.Employee__c = parentTxn.Employee__c;
                        newTxn.Date__c = parentTxn.Date__c;
                    }

                    if (parentTxn.RecordTypeId == adjustmentRecordType) {
                        newTxn.Debit_Financial_Account__c = financialAccounts.values()[0].get('Adjustment');
                        System.debug('// Set Debit Fin. Acct. ' + newTxn.Debit_Financial_Account__c);
                    } else if (parentTxn.RecordTypeId == chargeRecordType) {
                        newTxn.Debit_Financial_Account__c = financialAccounts.values()[0].get('Charge');
                        System.debug('// Set Debit Fin. Acct. ' + newTxn.Debit_Financial_Account__c);
                    }

                    newTxn.Amount__c = taxOrServiceMap.get(parentTxn.Id).get(taxOrServiceName);
                    System.debug('// Set amount: ' + newTxn.Amount__c);
                    newTxn.Customer__c = parentTxn.Customer__c;
                    System.debug('// Set Customer: ' + newTxn.Customer__c);
                    newTxn.Bill_To_Member__c = billToMemberMap.get(parentTxn.Customer__c);
                    System.debug('// Set Bill To: ' + newTxn.Bill_To_Member__c);
                    if (parentTxn.Line_Item__c != null) {
                        System.debug('// Line Item !NULL ' + parentTxn.Line_Item__c);
                        newTxn.Line_Item__c = parentTxn.Line_Item__c;
                    }
                    newTxn.Reservation__c = parentTxn.Reservation__c;
                    if (newTxn.Reservation__c != null) {
                        System.debug('// Reservation !NULL ' + newTxn.Reservation__c);
                        if (parentTxn.RecordTypeId == adjustmentRecordType) {
                            System.debug('// TXN recordtype == adjustment.');
                            newTxn.Description__c = String.valueOf(parentTxn.Reservation__r.Name) + '-'
                                                    + String.valueOf(Date.valueOf(parentTxn.Reservation__r.Event_Date__c).format()) + '-'
                                                    + String.valueOf(Schema.getGlobalDescribe().get('TXN__c').getDescribe().getRecordTypeInfosByName().get('Adjustment').getName());
                        } else if (parentTxn.RecordTypeId == chargeRecordType) {
                            System.debug('// TXN recordtype != adjustment.');
                            System.debug('// Description elements ' + parentTxn.Reservation__r.Name + ' ' + Date.valueOf(parentTxn.Reservation__r.Event_Date__c).format() + ' ' + Schema.getGlobalDescribe().get('TXN__c').getDescribe().getRecordTypeInfosByName().get('Charge').getName());
                            newTxn.Description__c = String.valueOf(parentTxn.Reservation__r.Name) + '-'
                                                    + String.valueOf(Date.valueOf(parentTxn.Reservation__r.Event_Date__c).format()) + '-'
                                                    + String.valueOf(Schema.getGlobalDescribe().get('TXN__c').getDescribe().getRecordTypeInfosById().get(newTxn.RecordTypeId).getName());
                        }
                    }
                    System.debug('// TXN populated with data: ' + newTxn);
                    childTxns.add(newTxn);
                }
            }

        }
        System.debug('// TXNs to return: ' + childTxns);
        return childTxns;
    }


    public static void methodToSetBillToMember(List<TXN__c> triggerNew) {
        List<Id> contactIdsList = new List<Id>();
        Map<Id, Id> contactIdAndParentIdMap = new Map<Id, Id>();
        String adjustmentRecTypeId = null;
        List<Id> relatedToList = new List<Id>();
        Map<Id, TXN__c> relatedToIdRecord = new Map<Id, TXN__c>();
        if (Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Adjustment') != null) {
            adjustmentRecTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Adjustment').getRecordTypeId();
        }
        String refundRecTypeId = null;
        if (Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Refund') != null) {
            refundRecTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        }
        for (TXN__c newTran : triggerNew) {
            if (newTran.Bill_To_Member__c != null && adjustmentRecTypeId != newTran.recordTypeId && refundRecTypeId != newTran.recordTypeId ) {
                contactIdsList.add(newTran.Bill_To_Member__c);
            }
            if (newTran.Related_To__c != null && (adjustmentRecTypeId == newTran.recordTypeId || refundRecTypeId == newTran.recordTypeId)) {
                relatedToList.add(newTran.Related_To__c);

            }
        }
        if (!relatedToList.isEmpty()) {
            List<TXN__c> relatedTransList = [select id, Bill_To_Member__c from TXN__c where Id In: relatedToList ];
            for (TXN__c tran : relatedTransList) {
                if (tran.Bill_To_Member__c != null ) {
                    relatedToIdRecord.put(tran.Id, tran);
                }
            }
        }

        if (!contactIdsList.isEmpty()) {
            List<Contact> contactsList = (List<Contact>) Data.read('SELECT Id, Bill_To_Member__r.Id, Bill_To_Member__r.Bill_To_Member__r.Id, '
                                         + 'Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id, '
                                         + 'Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id, '
                                         + 'Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id '
                                         + 'FROM Contact WHERE Id IN :contactIdsList',
                                         new Map<String, Object> {'contactIdsList' => contactIdsList});

            for (Contact con : contactsList) {
                Id superParentId = con.Id;
                if (con.Bill_To_Member__r.Id != null) {
                    superParentId = con.Bill_To_Member__r.Id;
                }
                if (con.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParentId = con.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                if (con.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParentId = con.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                if (con.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParentId = con.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                if (con.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParentId = con.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                contactIdAndParentIdMap.put(con.Id, superParentId);
            }
        }
        for (TXN__c newTran : triggerNew) {
            if (contactIdAndParentIdMap.get(newTran.Bill_To_Member__c) != null && adjustmentRecTypeId != newTran.recordTypeId
                    && refundRecTypeId != newTran.recordTypeId) {

                newTran.Bill_To_Member__c = contactIdAndParentIdMap.get(newTran.Bill_To_Member__c);
            }
            if (newTran.Related_To__c != null && (adjustmentRecTypeId == newTran.recordTypeId
                                                  || refundRecTypeId == newTran.recordTypeId) && relatedToIdRecord.get(newTran.Related_To__c) != null) {

                newTran.Bill_To_Member__c = relatedToIdRecord.get(newTran.Related_To__c).Bill_To_Member__c;
            }
        }
    }
    
    /**
    *@description: this method is handling the event fields automation for the deposit.
    *@param List of TXN with record type deposit.
    **/
    public static void handleEventDeposit(List<TXN__c> records) {
        if (records.get(0).RecordTypeId == Utility.searchRecordType('Deposit', 'TXN__c')) {
            Event__c event = (Event__c)Data.read(
                'SELECT Id, Deposit_Amount_Received__c FROM Event__c' +
                ' WHERE Id = :eventId',
                new MAP<String, object> {
                    'eventId' => records.get(0).Reservation__c
                        }).get(0);
            
            Decimal depositedAmount = 0;
            List<TXN__c> eventDepositTransactions = (List<TXN__c>)Data.read('SELECT Id, Reservation__c, Date__c, Amount__c FROM TXN__c' +
                                                    ' WHERE Reservation__c =:eventId AND RecordTypeId =:RECORDTYPEID ORDER BY DateTime__c',
            new Map<String, Object> {
                'eventId' => records.get(0).Reservation__c,
                'RECORDTYPEID' => Utility.searchRecordType('Deposit', 'TXN__c')
            });

            event.Deposit_Received__c = false;
            event.Deposit_Received_Date__c = null;
            if (eventDepositTransactions.size() > 0) {
                event.Deposit_Received__c = true;
                event.Deposit_Received_Date__c = eventDepositTransactions.get(eventDepositTransactions.size() - 1).Date__c;
            }
            for (TXN__c depo : eventDepositTransactions) {
                depositedAmount = depositedAmount + (depo.Amount__c * -1);
            }
            
            event.Deposit_Amount_Received__c = depositedAmount;
            data.modify(event);
        }
        
    }
    /**
     * setGuestPassOnTXN Method for setting guest pass field on TXN if a guest is the Customer__c
     * @param  triggerNewRecords TXNs being inserted
     */
    public static void setGuestPassOnTXN(List<TXN__c> triggerNew) {
        Id guestRecordId = Utility.searchRecordType('Guest', 'Contact');
        List<Id> customerIds = new List<Id>();
        Map<Id, Id> guestPassMap = new Map<Id, Id>();

        //Get all the Customer__c Ids
        for (TXN__c record : triggerNew) {
            customerIds.add(record.Customer__c);
        }

        //Query for Guest Passes through relationship to Contact (Guest_Name__c)
        //NOTE: Guest_Passes1__r relates from Contact to Guest Pass through Guest_Name
        List<Contact> guests = Data.read('SELECT Id, LastName, '
                                         + '(SELECT Id, Guest_Name__r.LastName, Guest_Name__c FROM Guest_Passes1__r WHERE Active__c = true) '
                                         + 'FROM CONTACT '
                                         + 'WHERE Id IN :guestIds AND RecordTypeId = :guestRecordTypeId',
        new Map<String, Object> {
            'guestIds' => customerIds,
            'guestRecordTypeId' => guestRecordId
        }
                                        );
        //Map Customer__c to Guest_Pass__c
        for (Contact guest : guests) {
            for (Guest_Pass__c gPass : guest.Guest_Passes1__r) {
                guestPassMap.put(guest.Id, gPass.Id);
            }
        }
        
        System.debug('++GuestPassMap: ' + guestPassMap);


        List<TXN__c> recordsToUpdate = new List<TXN__c>();

        //Iterate through all the TXNs to be updated and set their guest pass if it is found in the map
        //for(TXN__c record: recordsToBeUpdated){
        for (TXN__c record : TriggerNew) {
            if (guestPassMap.containsKey(record.Customer__c)) {
                record.Guest_Pass__c = guestPassMap.get(record.Customer__c);
                recordsToUpdate.add(record);
            }
        }

    }
    /**
     *  getGuestPassIds from trigger context TXNs
     * @param  triggerRecords TXNs being inserted
     */
    public static void getGuestPassIdsFromTXNs(List<TXN__c> triggerRecords) {
        Set<Id> guestPassIds = new Set<Id>();

        for (TXN__c record : triggerRecords) {
            guestPassIds.add(record.Guest_Pass__c);
        }
        updateGuestPassTotals(guestPassIds);
    }

    /**
* updateGuestPassTotals Method for updating Total_Charges__c and Net_Total__c based upon TXNs
* @param  guestPassIds the guest Pass Ids
*/
    public static void updateGuestPassTotals(Set<Id> guestPassIds) {
        Double Total_Charges = 0.00;
        Double Net_Total = 0.00;

        List<Guest_Pass__c> guestPassesWithTXNs = (List<Guest_Pass__c>)Data.read('SELECT Id, Net_Total__c, Total_Charges__c, (SELECT Amount__c, RecordType.Name FROM Transactions__r) '
                + 'FROM Guest_Pass__c WHERE Id IN :guestPassIds',
        new Map<String, Object> {
            'guestPassIds' => guestPassIds
        }
                                                                                );

        for (Guest_Pass__c guestPass : guestPassesWithTXNs) {
            for (TXN__c guestPassTXN : guestPass.Transactions__r) {
                if (guestPassTXN.RecordType.Name == 'Charge') Total_Charges += guestPassTXN.Amount__c;
                Net_Total += guestPassTXN.Amount__c;
            }
            guestPass.Net_Total__c = Net_Total;
            guestPass.Total_Charges__c = Total_Charges;
        }
        Data.modify(guestPassesWithTXNs);
    }
    public static void rollupPaymentReceivedOnEvent(List<TXN__c> records, Map<Id, TXN__c> oldRecords, String triggerAction) {
        Set<Id> eventIds = new Set<Id>();
        for (TXN__c tran : records) {
            if (tran.Reservation__c != null) {
                if (tran.RecordTypeId == Utility.searchRecordType('Charge', 'TXN__c')
                        || tran.RecordTypeId == Utility.searchRecordType('Service Charges', 'TXN__c')
                        || tran.RecordTypeId == Utility.searchRecordType('Taxes', 'TXN__c')) {
                    eventIds.add(tran.Reservation__c);
                }
            }
        }
        
        if (eventIds.size() > 0) {
            Map<Id, Event__c> events = new Map<Id, Event__c>((List<Event__c>)Data.read(
                'SELECT Id, Payments_Received__c, Description__c FROM Event__c' +
                ' WHERE Id IN :eventIds',
                new MAP<String, object> {
                    'eventIds' => eventIds
                        }));
            
            if (events.size() > 0) {
                for (TXN__c tran : records) {
                    if (tran.Reservation__c != null) {
                        if (tran.RecordTypeId == Utility.searchRecordType('Charge', 'TXN__c')
                                || tran.RecordTypeId == Utility.searchRecordType('Service Charges', 'TXN__c')
                                || tran.RecordTypeId == Utility.searchRecordType('Taxes', 'TXN__c')) {
                            if (events.containsKey(tran.Reservation__c)) {
                                Event__c e = events.get(tran.Reservation__c);
                                if (e.Payments_Received__c == null) {
                                    e.Payments_Received__c = 0;
                                }

                                system.debug('Bhosad' + oldRecords + triggerAction);
                                if (triggerAction == 'update' && tran.Amount_Cleared__c != oldRecords.get(tran.id).Amount_Cleared__c) {
                                    e.Payments_Received__c = e.Payments_Received__c + (tran.Amount_Cleared__c - oldRecords.get(tran.id).Amount_Cleared__c);
                                    system.debug('Bhosad');
                                } else if (triggerAction == 'insert') {
                                    e.Payments_Received__c = e.Payments_Received__c + tran.Amount_Cleared__c;
                                }
                                events.put(tran.Reservation__c, e);
                            }
                        }
                    }
                }
            }
            Data.modify(events.values());
        }
    }

    public static void financialMonster(List<TXN__c> records) {
        Map<String, Financial_Journal_Line__c> fjlList = new Map<String, Financial_Journal_Line__c>();
        Set<Id> txnIds = new Set<Id>();
        Map<Id, Financial_Account__c> fAccountMap;

        Id fjeId;
        Financial_Journal_Entry__c fje;

        for (TXN__c tran : records) {
            if (tran.Related_To__c != null && tran.Credit_Financial_Account__c != null && tran.Debit_Financial_Account__c != null) {
                txnIds.add(tran.Related_To__c);
            }

            if (txnIds.size() > 0) {

                List<TXN__c> existingTransactionInSameMonster = (List<TXN__c>) Data.read('SELECT Id, Financial_Journal_Entry__c'
                        + ' FROM TXN__c WHERE Id IN :relatedTo LIMIT 1',
                New Map<String, Object> {
                    'relatedTo' => txnIds
                });

                if (existingTransactionInSameMonster.size() > 0) {
                    fjeId = existingTransactionInSameMonster.get(0).Financial_Journal_Entry__c;
                }

                List<Financial_Journal_Line__c> existingFinancialJournalLines = (List<Financial_Journal_Line__c>) Data.read('SELECT Id, Financial_Account__c, Amount__c, Debit__c, Credit__c'
                        + ' FROM Financial_Journal_Line__c WHERE Financial_Journal_Entry__c = :fjeId',
                New Map<String, Object> {
                    'fjeId' => fjeId
                });

                for (Financial_Journal_Line__c fjl : existingFinancialJournalLines) {
                    if (fjl.Credit__c != 0) {
                        fjl.Amount__c = Math.abs( fjl.Amount__c );
                    } else {
                        fjl.Amount__c = (Math.abs( fjl.Amount__c ) * -1);
                    }
                    fjlList.put(fjl.Financial_Account__c, fjl);
                }
            }
        }

        for (TXN__c tran : records) {
            if (tran.Credit_Financial_Account__c != null && tran.Debit_Financial_Account__c != null) {
                if (fjlList.containsKey(tran.Credit_Financial_Account__c)) {
                    Financial_Journal_Line__c fjl = fjlList.get(tran.Credit_Financial_Account__c);
                    fjl.Amount__c = fjl.Amount__c + tran.Amount__c;
                    fjlList.put(tran.Credit_Financial_Account__c, fjl);
                } else {
                    Financial_Journal_Line__c fjlCredit = new Financial_Journal_Line__c();
                    fjlCredit.Amount__c = tran.Amount__c;
                    fjlCredit.Transaction_Date__c = System.today();
                    fjlCredit.Posted__c = true;
                    fjlCredit.Description__c = 'fjl credit monster';
                    fjlCredit.Post_Date__c = System.today();
                    fjlCredit.Financial_Account__c = tran.Credit_Financial_Account__c;
                    fjlList.put(tran.Credit_Financial_Account__c, fjlCredit);
                }

                if (fjlList.containsKey(tran.Debit_Financial_Account__c)) {
                    Financial_Journal_Line__c fjl = fjlList.get(tran.Debit_Financial_Account__c);
                    fjl.Amount__c = fjl.Amount__c - tran.Amount__c;
                    fjlList.put(tran.Debit_Financial_Account__c, fjl);
                } else {
                    Financial_Journal_Line__c fjlDebit = new Financial_Journal_Line__c();
                    fjlDebit.Amount__c = tran.Amount__c * -1;
                    fjlDebit.Transaction_Date__c = System.today();
                    fjlDebit.Posted__c = true;
                    fjlDebit.Description__c = 'fjl debit monster';
                    fjlDebit.Post_Date__c = System.today();
                    fjlDebit.Financial_Account__c = tran.Debit_Financial_Account__c;
                    fjlList.put(tran.Debit_Financial_Account__c, fjlDebit);
                }
            }
        }

        if (fjlList.size() > 0) {
            fAccountMap = new Map<Id, Financial_Account__c>((List<Financial_Account__c>)Data.read('Select Id, Debit_Credit__c'
                    + ' FROM Financial_Account__c WHERE Id IN:fAccountIds',
            new Map<String, Object> {
                'fAccountIds' => fjlList.keySet()
            }));


            if (fjeId == null) {
                fje = new Financial_Journal_Entry__c();
                fje.Description__c = 'financial monster';
                fje.Entry_Date__c = System.today();
                Data.create(fje);
            }

            List<Financial_Journal_Line__c> linesToUpodate = new List<Financial_Journal_Line__c>();
            for (Financial_Journal_Line__c fjl : fjlList.values()) {
                if (fjl.Amount__c < 0) {
                    if (fAccountMap.get(fjl.Financial_Account__c).Debit_Credit__c == 'Debit') {
                        fjl.Amount__c = Math.abs(fjl.Amount__c);
                    }
                } else {
                    if (fAccountMap.get(fjl.Financial_Account__c).Debit_Credit__c == 'Debit') {
                        fjl.Amount__c = fjl.Amount__c * -1;
                    }
                }

                if (fjeId != null) {
                    fjl.Financial_Journal_Entry__c = fjeId;
                } else {
                    fjl.Financial_Journal_Entry__c = fje.Id;
                }

                linesToUpodate.add(fjl);
            }

            //Data.create(linesToUpodate);
            Data.upsurt(linesToUpodate, Financial_Journal_Line__c.Id.getDescribe().getSObjectField(), new Set<String>());
            for (TXN__c tran : records) {
                if (tran.Credit_Financial_Account__c != null && tran.Debit_Financial_Account__c != null) {
                    if (fjeId != null) {
                        tran.Financial_Journal_Entry__c = fjeId;
                    } else {
                        tran.Financial_Journal_Entry__c = fje.Id;
                    }

                    tran.Credit_Financial_Journal_Line__c = fjlList.get(tran.Credit_Financial_Account__c).Id;
                    tran.Financial_Journal_Line__c = fjlList.get(tran.Debit_Financial_Account__c).Id;
                }
            }
        }
    }
}