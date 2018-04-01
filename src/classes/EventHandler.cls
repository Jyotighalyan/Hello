public with sharing class EventHandler {

    public static void finalizeEvent (List<Id> eventIds) {
        List<Event__c> eventList = new List<Event__c>();
        List<TXN__c> txnList = new List<TXN__C>();
        Map<Id, Line_Item__c> lineItemMap = new Map<Id, Line_Item__c>();
        Map<Id, TXN__c> lineItemIdTransaction = new Map<Id, TXN__c>();


        String ChargeRecTypeId = Utility.searchRecordType('Charge', 'TXN__c');

        List<Event__c> allEvents = (List<Event__c>)Data.read(
                                       'SELECT Id, Status__c, Total_Service_Charges__c, Total_Taxes__c, Name, Post_Close_Date_Time__c, Adjustments__c, Additions__c, (SELECT Name, Amount__c, Override_Date__c, Tax_Amount__c, Service_Charge__c, Original_Line_Item__c,' +
                                       'Create_charge_if_event_is_cancelled__c, Reservation_line__r.Post_Close_Date_Time__c, Reservation_line__r.StartTime__c, Reservation_line__r.Name,' +
                                       'Reservation_line__r.Sponsoring_Customer__c, Reservation_line__r.SponsoringMember__c, Reservation_line__r.Id, Charge_Item__r.Type__c, Charge_Item__r.SubType__c,' +
                                       'Charge_Item__r.Name, Charge_Item__r.Id,Charge_Item__r.Financial_Account__c, qty__c, recordType.Name, Service_Charge_Name__c, Tax_Name__c, Tax_Exempt__c, Reservation_line__r.Status__c, Employee__c FROM Events__r)' +
                                       ' FROM Event__c' +
                                       ' WHERE Id IN :eventIds',
        new Map<String, Object> {
            'eventIds' => eventIds
        }
                                   );

        for (Event__c event : allEvents) {
            for (Line_Item__c lineItem : event.Events__r) {
                // System.debug('-- Line Item: ' + lineItem);
                lineItemMap.put(String.escapeSingleQuotes(lineItem.Id), lineItem);
            }
            If (event.Post_Close_Date_Time__c == null && event.Status__c != 'Cancelled') {
                event.Post_Close_Date_Time__c = DateTime.now();
                eventList.add(event);
            }
        }

        List<TXN__c> transList = (List<TXN__c>)Data.read('SELECT Id, Name, Amount__c, Charge_Amount_Left__c,'
                                 + ' Date__c, Service_Charge__c, Line_Item__c, Tax_Exempt__c, Related_To__c'
                                 + ' FROM TXN__c WHERE Line_Item__c IN :lineItems',
        new Map<String, Object> {
            'lineItems' => lineItemMap.keySet()
        });
                
        for (TXN__c tran : transList) {
            if(!lineItemIdTransaction.containsKey(tran.Line_Item__c)){
                lineItemIdTransaction.put(tran.Line_Item__c, tran);
            }            
            if (lineItemMap.containsKey(tran.Line_Item__c)) {
                lineItemMap.remove(tran.Line_Item__c);
            }
        }
        txnList = upsertTransactions(lineItemMap.values(), ChargeRecTypeId, lineItemIdTransaction);
        txnList = createSplitChargeAmountTxnRecords(txnList);
        

        Data.create(txnList);
        Data.modify(eventList);
        rollupEventFields(allEvents);
    }
    /**
     * upsertTransactions Method to upsert TXNs when finalizing an Event.
     * @param  ChargeItemList          ChargeItemList List of Line Items
     * @param  recId                   recId Record Type Id of the TXNs
     * @param  chargeItemIdTransaction chargeItemIdTransaction Map of the Line_Item Id to its corresponding TXN.
     * @return                         return TXNs to create.
     */
    public static List<TXN__c> upsertTransactions(List<Line_Item__c> ChargeItemList, String recId, Map<Id, TXN__c> chargeItemIdTransaction) {
        List<TXN__c> txnList = new List<TXN__c>();
        String adjustmentRecTypeId = null;

        if (Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Adjustment') != null) {
            adjustmentRecTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Adjustment').getRecordTypeId();
        }
        String ChargeRecTypeId = Schema.SObjectType.Line_Item__c.getRecordTypeInfosByName().get('Charge').getRecordTypeId();
        Map<Id, RecordType> txnRecordTypeMap = new Map<Id, RecordType>([select Id, Name from RecordType where sObjectType = 'TXN__c']);
        List<Id> contactIdsList = new List<Id>();
        for (Line_Item__c ChargeItem : ChargeItemList) {
            
            if (ChargeItem.Reservation_line__r.Sponsoring_Customer__c != null) {
                contactIdsList.add(ChargeItem.Reservation_line__r.Sponsoring_Customer__c);
            }
        }
        Map<Id, Id> contactIdAndParentIdMap = Utility.getBillToMember(contactIdsList);

        for (Line_Item__c ChargeItem : ChargeItemList) {
            if (ChargeItem.Reservation_line__r.Status__c == 'Cancelled' && ChargeItem.Create_charge_if_event_is_cancelled__c != true) {
                continue;
            }
            try {
                TXN__c newTransaction = new TXN__c();
                newTransaction.Amount__c = ChargeItem.Amount__c;
                newTransaction.Tax_Exempt__c = ChargeItem.Tax_Exempt__c;
                newTransaction.Is_Parent__c = true;

                if (ChargeItem.Tax_Amount__c == null && ChargeItem.Service_Charge__c == null) {
                    newTransaction.Charge_Amount_Left__c = ChargeItem.Amount__c;
                } else if (ChargeItem.Tax_Amount__c == null) {
                    newTransaction.Charge_Amount_Left__c = ChargeItem.Amount__c + ChargeItem.Service_Charge__c;
                } else if (ChargeItem.Service_Charge__c == null) {
                    newTransaction.Charge_Amount_Left__c = ChargeItem.Amount__c + ChargeItem.Tax_Amount__c;
                }

                if (ChargeItem.Override_Date__c != null) {
                    newTransaction.Date__c = ChargeItem.Override_Date__c;

                } else if (ChargeItem.Reservation_line__r.StartTime__c != null) {
                    DateTime DT = ChargeItem.Reservation_line__r.StartTime__c;
                    newTransaction.Date__c = Date.newInstance(DT.year(), DT.month(), DT.day());
                }
                if (ChargeItem.Service_Charge__c != null) {
                    newTransaction.Service_Charge__c = ChargeItem.Service_Charge__c;
                } else {
                    newTransaction.Service_Charge__c = 0;
                }
                if (ChargeItem.Tax_Amount__c != null) {
                    newTransaction.Tax__c = ChargeItem.Tax_Amount__c;
                } else {
                    newTransaction.Tax__c = 0;
                }
                if (ChargeItem.recordType.Name == 'Adjustment') {
                    
                    newTransaction.RecordTypeId = adjustmentRecTypeId;
                    if (ChargeItem.Original_Line_Item__c != null && chargeItemIdTransaction.get(ChargeItem.Original_Line_Item__c) != null) {
                        newTransaction.Related_To__c = chargeItemIdTransaction.get(ChargeItem.Original_Line_Item__c).Id;
                    }
                    newTransaction.Quantity__c = ChargeItem.Qty__c;
                    newTransaction.Tax_Name__c = ChargeItem.Tax_Name__c;
                    newTransaction.Service_Charge_Name__c = ChargeItem.Service_Charge_Name__c;
                } else {

                    // System.debug('-- recId = ' + recId);
                    newTransaction.Employee__c = ChargeItem.Employee__c;
                    newTransaction.RecordTypeId = recId;
                }
                if (ChargeItem.recordTypeId == ChargeRecTypeId) {
                    newTransaction.Quantity__c = ChargeItem.Qty__c;
                }
                newTransaction.Line_Item__c = ChargeItem.Id;
                if (ChargeItem.Reservation_line__r.Sponsoring_Customer__c != null && contactIdAndParentIdMap.get(ChargeItem.Reservation_line__r.Sponsoring_Customer__c) != null) {
                    newTransaction.Bill_To_Member__c = contactIdAndParentIdMap.get(ChargeItem.Reservation_line__r.Sponsoring_Customer__c);
                }

                DateTime DT = ChargeItem.Reservation_line__r.StartTime__c;

                newTransaction.Description__c = ChargeItem.Reservation_line__r.Name + '-' + DT.month() + '/' + DT.day() + '/' + DT.year() + '-' + txnRecordTypeMap.get(newTransaction.RecordTypeId).name;
                newTransaction.GlobalType__c = ChargeItem.Charge_Item__r.Type__c;
                newTransaction.Credit_Financial_Account__c = ChargeItem.Charge_Item__r.Financial_Account__c;
                newTransaction.GlobalSubType__c = ChargeItem.Charge_Item__r.SubType__c;
                newTransaction.Reservation__c = ChargeItem.Reservation_line__r.Id;
                newTransaction.Charge_Item__c = ChargeItem.Charge_Item__r.Id;
                newTransaction.Customer__c = ChargeItem.Reservation_line__r.Sponsoring_Customer__c;
                txnList.add(newTransaction);
            } catch (Exception e) {
                system.debug(e.getStackTraceString());
            }
        }
        return txnList;
    }
    public static List<TXN__c> createSplitChargeAmountTxnRecords(List<TXN__c> TxnRecords) {
        List<Revenue_Split__c> SplitRecords = (List<Revenue_Split__c>)Data.read('SELECT Id,Charge_Item__c,Financial_Account__c,Split_Amount__c from Revenue_Split__c');
        List<TXN__c> deleteList = new List<TXN__c>();
        List<TXN__c> passBackTXNs = new List<TXN__c>();
        Map<Id, TXN__c> deleteMap = new Map<Id, TXN__c>();
        set<Id> deleteTaxesTXN = new set<Id>();
        Map<String, List<TXN__c>> allTxnMap = new Map<String, List<TXN__c>>();
        integer val = 0;
        List<Line_Item__c> lineitemRec = (List<Line_Item__c>)Data.read('SELECT Qty__c,Id from Line_Item__c');
        //passBackTXNs.addAll(TxnRecords); 

        //loop all the new charges created with charge items
        for(Integer i = 0; i < TxnRecords.size(); i++){
            TXN__c Txn = TxnRecords.get(i);
        //for (TXN__C Txn : TxnRecords) {
            integer flag = 0;
            val++;
            List<TXN__c> createList = new List<TXN__c>();
            if (Txn.Charge_Item__c != null) {
                for (Revenue_Split__c SplitRec : SplitRecords) {
                    //if any charge item available then check if revenue has split.
                    if (SplitRec.Charge_Item__c == Txn.Charge_Item__c) {
                        //if revenue has split for any charge item then create tnx records for that split
                        TXN__c splitCharge = new TXN__c();
                        //get qty for lineitem
                        double lineItemQty = 0;
                        for (Line_Item__c lineitems : lineitemRec) {
                            if (lineitems.id == Txn.Line_Item__c) {
                                lineItemQty = lineitems.Qty__c;
                            }
                        }


                        splitCharge.Amount__c = SplitRec.Split_Amount__c * lineItemQty;
                        splitCharge.Related_To__c = Txn.id;
                        splitCharge.RecordTypeId = Txn.RecordTypeId;
                        splitCharge.GlobalType__c = Txn.GlobalType__c;
                        splitCharge.GlobalSubType__c = Txn.GlobalSubType__c;
                        splitCharge.Customer__c = Txn.Customer__c;
                        splitCharge.Bill_To_Member__c = Txn.Bill_To_Member__c;
                        splitCharge.Amount_Remaining__c = Txn.Amount_Remaining__c;
                        splitCharge.Line_Item__c = Txn.Line_Item__c;
                        splitCharge.Transaction_Split__c = true;
                        splitCharge.Charge_Item__c = Txn.Charge_Item__c;
                        splitCharge.Reservation__c = Txn.Reservation__c;
                        splitCharge.Description__c = Txn.Description__c;
                        splitCharge.Credit_Financial_Account__c = SplitRec.Financial_Account__c;
                        splitCharge.Is_Parent__c = true;
                        createList.add(splitCharge);
                        flag = 1;
                    }
                }
            }
            //if amount has split for the charge item then add master record in delete List.
            if (flag == 1) {
                deleteList.add(Txn);
                TxnRecords.remove(i);
                deleteMap.put(Txn.id, txn);
                deleteTaxesTXN.add(Txn.Id);
                allTxnMap.put(string.valueOf(Txn.Line_Item__c + '' + Txn.Charge_Item__c), createList);
            }
        }
        List<TXN__c> MasterRecord = new List<TXN__c>();
        for (String key : allTxnMap.keySet()) {
            List<TXN__c> Listtt = allTxnMap.get(key);
            MasterRecord.add(Listtt[0]);
            Listtt.remove(0);
            allTxnMap.put(key, Listtt);
        }

        //Data.Create(MasterRecord);
        TxnRecords.addAll(MasterRecord);
        List<TXN__c> ChildRecordList = new List<TXN__c>();
        for (TXN__c masterRec : MasterRecord) {
            for (String key : allTxnMap.keySet()) {
                if (masterRec.Line_Item__c + '' + masterRec.Charge_Item__c == key) {
                    List<TXN__c> getChildList = allTxnMap.get(key);
                    for (TXN__c CR : getChildList) {
                        CR.Related_To__c = masterRec.id;
                        ChildRecordList.add(CR);
                    }
                }
            }
        }
        //Data.create(ChildRecordList);
        TxnRecords.addAll(ChildRecordList);
        //delete master record and its tax and service charge txn records for charge item as we already created records with its split amount
        if (deleteMap.size() > 0) {
            List<TXN__c> acMapp = (List<TXN__c>)Data.read('Select Id From TXN__c Where Related_To__c in :TXNIDs and RecordTypeId!=:RT',
            new Map<String, Object> {
                'TXNIDs' => deleteTaxesTXN,
                'RT' => Utility.searchRecordType('Charge', 'TXN__c')
            });
            data.remove(acMapp);
            //Data.remove(deleteList);
        }
        return TxnRecords;
    }
    public static void rollupEventFields(List<Event__c> events) {
        if (events.size() > 0) {
            Event__c event = events.get(0);
            //Get all the record type from the Txn so we can reduce no of SOQL
            Map<String, Id> recordTypeIdName = new Map<String, Id>();
            for (RecordType rt : (List<RecordType>) Data.read('SELECT Id, Name FROM RecordType WHERE sObjectType = \'TXN__c\'')) {
                recordTypeIdName.put(rt.Name, rt.Id);

            }
            //Fetch all the transaction related to this event. and convert deposit to payment.
            List<TXN__c> transactions = (List<TXN__c>)Data.read(
                                            'SELECT Id, Amount__c, Amount_Remaining__c, Customer__c, Bill_To_Member__c, Reservation__c, Related_To__c, Line_Item__r.CreatedDate, RecordTypeId,' +
                                            ' Payment_Type__c, Date__c, Description__c, Statement_Description__c,' +
                                            ' Check_Number__c, Check_Date__c, Name_on_Check__c,' +
                                            ' Cardholder_Name__c, Card_Type__c, Card_Last_4_Digits__c, External_Payment_Transaction_Code__c, External_Payment_Authorization_Code__c,' +
                                            ' Bank_Name__c, Routing_Number__c, Account_Type__c, Account_Number_Last_4_Digits__c, Name_on_Account__c' +
                                            ' FROM TXN__c WHERE Reservation__c =:eventId AND (RecordTypeId =:chargeRecord OR RecordTypeId =:adjustmentRecord OR RecordTypeId =:depositRecord)',
            new MAP<String, object> {
                'eventId' => event.Id,
                'chargeRecord' => recordTypeIdName.get('Charge'),
                'adjustmentRecord' => recordTypeIdName.get('Adjustment'),
                'depositRecord' => recordTypeIdName.get('Deposit')
            });

            List<TXN__c> paymentTransaction = new List<TXN__c>();
            Set<Id> childTransactionIds = new Set<Id>();

            //Setup the financial account for the payment generated from deposit.
            List<Default_Account__c> defaultAccountList = (List<Default_Account__c>)Data.read('select id, Financial_Account__c from Default_Account__c'
                +' Where Default_Type_Name__c= :defaultAccountType',
                new Map<String,Object>{
                    'defaultAccountType' => 'Prepaid Deposits'
            });

            for (TXN__c eventTransaction : transactions) {

                if (eventTransaction.RecordTypeId == recordTypeIdName.get('Deposit') && eventTransaction.Related_To__c == null) {
                    TXN__c payment = eventTransaction.clone(false, true);
                    payment.RecordTypeId = recordTypeIdName.get('Payment');
                    
                    if(defaultAccountList.size()>0)
                    {
                        payment.Debit_Financial_Account__c = defaultAccountList.get(0).Financial_Account__c;
                    }
                    
                    paymentTransaction.add(payment);
                } else {
                    childTransactionIds.add(eventTransaction.Id);
                }
            }

            Data.create(paymentTransaction);

            if (paymentTransaction.size() > 0) {
                Integer i = 0;
                List<TXN__c> depositRec = new List<TXN__c>();
                for (TXN__c eventTransaction : transactions) {

                    if (eventTransaction.RecordTypeId == recordTypeIdName.get('Deposit') && eventTransaction.Related_To__c == null) {
                        eventTransaction.Related_To__c = paymentTransaction.get(i).Id;
                        eventTransaction.Amount_Remaining__c = 0;
                        depositRec.add(eventTransaction);
                        i++;
                    }
                }
                Data.modify(depositRec);
            }

            List<TXN__c> childTransactionsList = (List<TXN__c>)Data.read(
                    'SELECT Id, Amount__c, RecordTypeId, Related_To__c, CreatedDate FROM TXN__c' +
                    ' WHERE (Related_To__c IN :childIds AND (RecordTypeId =:taxes OR RecordTypeId =:serviceCharges)) OR (RecordTypeId =:paymentRecord AND Reservation__c =:eventId)',
            new MAP<String, object> {
                'childIds' => childTransactionIds,
                'taxes' => recordTypeIdName.get('Taxes'),
                'serviceCharges' => recordTypeIdName.get('Service Charges'),
                'paymentRecord' => recordTypeIdName.get('Payment'),
                'eventId' => event.Id
            });

            Map<Id, Decimal> taxScSumMap = new Map<Id, Decimal>();

            Decimal TotalTax = 0;
            Decimal TotalSc = 0;
            for (TXN__c childTransaction : childTransactionsList) {
                if (taxScSumMap.containsKey(childTransaction.Related_To__c)) {
                    Decimal amount = taxScSumMap.get(childTransaction.Related_To__c);
                    amount = amount + childTransaction.Amount__c;
                    taxScSumMap.put(childTransaction.Related_To__c, amount);
                } else {
                    taxScSumMap.put(childTransaction.Related_To__c, childTransaction.Amount__c);
                }

                if (childTransaction.RecordTypeId == recordTypeIdName.get('Taxes')) {
                    TotalTax = TotalTax + childTransaction.Amount__c;
                } else if(childTransaction.RecordTypeId == recordTypeIdName.get('Service Charges')){
                    TotalSc = TotalSc + childTransaction.Amount__c;
                }
            }

            Decimal adjustment = 0;
            Decimal additions = 0;

            for (TXN__c txn : transactions) {

                if (txn.RecordTypeId != recordTypeIdName.get('Deposit')) {
                    Decimal taxScAmount = 0;
                    if (taxScSumMap.containsKey(txn.Id)) {
                        taxScAmount = taxScSumMap.get(txn.Id);
                    }

                    if (txn.RecordTypeId == recordTypeIdName.get('Adjustment')) {
                        adjustment = adjustment + taxScAmount + txn.Amount__c;
                    }

                    if (txn.RecordTypeId == recordTypeIdName.get('Charge') && txn.Line_Item__r.CreatedDate > event.Post_Close_Date_Time__c) {
                        additions = additions + taxScAmount + txn.Amount__c;
                    }
                }
            }

            event.Adjustments__c = adjustment;
            event.Additions__c = additions;
            event.Total_Taxes__c = TotalTax;
            event.Total_Service_Charges__c = TotalSc;
            Data.modify(event);
        }
    }
}