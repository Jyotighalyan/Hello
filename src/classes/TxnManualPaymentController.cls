public with sharing class TxnManualPaymentController {

    public String paramMemberId {get; set;}
    public String paramMemberName {get; set;}
    public String paramFrom {get; set;}
    public String paramReservationId {get; set;}
    public String referrerURL {get; set;}
    public String paramPaymentId {get; set;}
    public String currentPageLabel {get; set;}
    public List<SelectOption> statusOptions {get; set;}
    public List<SelectOption> sos {get; set;}
    public Boolean isDetailPage {get; set;}
    public String paymentAmount {get; set;}
    public String paymentType {get; set;}
    public Event__c eventDeposit {get; set;}
    public Event__c eventStatus {get; set;}
    public List<Event__c> eventDepositList {get; set;}
    public String selectedValue {get; set;}
    public TXN__c othCharge {get; set;}
    public String achType {get; set;}
    public String guestID {get; set;}
    public Boolean isPostedAndClosed {get; set;}
    public Boolean editPg {get; set;}
    public Boolean editPg1 {get; set;}
    public Payment_Method__c paymentMethod {get; set;}
    public String updateChargeName {get; set;}
    public Boolean renderupdateChargeName {get; set;}
    public Txn_Payment_To_Charge_Mapping__c Payment_to_charge {get; set;}
    public String billToMember {get; set;}
    public String dynamicContent {get;set;}
    
    public TXN__c txn {
        get {
            if (txn == null) {
                txn = new TXN__c();
            }
            return txn;
        }
        set;
    }

    public TxnManualPaymentController() {
        renderupdateChargeName = false;
        isDetailPage = false;
        othCharge = new TXN__c();
        paramPaymentId = getSanitizedParam('PaymentId');
        // transactionId = 'none';
        editPg = true;
        editPg1 = false;

        String message = '' + ApexPages.currentPage().getParameters().get('message');
        if (message != '' && message != 'null') {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
        }

        // sumOfcharges = new Map<String,String>(); TODO: Implement with Folio

        // set selected default
        try {
            selectedValue = Utility.searchRecordType('Payment', 'TXN__c');
        } catch (Exception e) {
            selectedValue = '';
        }

        if (getSanitizedParam('memberId') != '' && getSanitizedParam('memberId') != null) {
            String conId = getSanitizedParam('memberId');
            List<Contact> currentContact = (List<Contact>)Data.read(
                                               'SELECT ID,Name,Bill_To_Member__c FROM Contact WHERE Id = :conId',
            new Map<String, Object> {
                'conId' => conId
            }
                                           );
            if (currentContact.size() > 0) billToMember = currentContact[0].Bill_To_Member__c;
        }

        if (paramPaymentId != '' && paramPaymentId != null) {
            isDetailPage = true;
            editPg = false;
            editPg1 = true;

            List<TXN__c> txnCharges = (List<TXN__c>)Data.read(
                                          'SELECT ID, Name, Customer__c, RECORDTYPEID, Check_Date__c, Check_Number__c, Payment_Type__c, External_Payment_Authorization_Code__c, External_Payment_Transaction_Code__c, External_Payment_Method_Last_4_Digits__c, External_Payment_Method__c, Description__c, Date__c, Total_Amount__c, Status__c, Amount__c FROM TXN__c WHERE Id = :paramPaymentId',
            new Map<String, Object> {
                'paramPaymentId' => paramPaymentId
            }
                                      );

            if (txnCharges.size() > 0) {
                List<Contact> contactList = (List<Contact>)Data.read(
                                                'SELECT ID,Name FROM Contact WHERE Id = :txnMember',
                new Map<String, Object> {
                    'txnMember' => String.valueOf(txnCharges.get(0).Customer__c)
                }
                                            );

                if (contactList.size() > 0) {
                    paramMemberId = String.valueOf(contactList.get(0).ID);
                    guestID = String.valueOf(contactList.get(0).ID);
                    paramMemberName = String.valueOf(contactList.get(0).Name);
                }
            }

            selectedValue = String.valueOf(txnCharges.get(0).RECORDTYPEID);
            paymentAmount = String.valueOf(Double.valueOf(txnCharges.get(0).Total_Amount__c)); //  * -1
            paymentType = String.valueOf(txnCharges.get(0).Payment_Type__c);
            othCharge.Date__c = date.valueOf(txnCharges.get(0).Date__c);
            othCharge.Description__c = String.valueOf(txnCharges.get(0).Description__c);

            if (paymentType == 'CreditCard' || paymentType == 'ACH') {
                othCharge.External_Payment_Transaction_Code__c = String.valueOf(txnCharges.get(0).External_Payment_Transaction_Code__c);
                othCharge.External_Payment_Authorization_Code__c = String.valueOf(txnCharges.get(0).External_Payment_Authorization_Code__c);
            }

            if (paymentType == 'Check') {
                othCharge.Check_Number__c = String.valueOf(txnCharges.get(0).Check_Number__c);
                othCharge.Check_Date__c = Date.valueOf(txnCharges.get(0).Check_Date__c);
            }
        } else {
            paramMemberId = getSanitizedParam('memberId');
            paramMemberName = getSanitizedParam('memberName');
            paramReservationId = getSanitizedParam('reservationId');
            guestID = paramMemberId;

            if (paramReservationId != null && paramReservationId != '') {
                List<Event__c> eventStatusList = (List<Event__c>)Data.read(
                                                     'Select Id, Status__c, Sponsoring_Customer__c From Event__c Where Id = :paramReservationId',
                new Map<String, Object> {
                    'paramReservationId' => paramReservationId
                }
                                                 );
                eventStatus = eventStatusList[0];

                if (eventStatus.Sponsoring_Customer__c != null) {
                    paramMemberId = eventStatus.Sponsoring_Customer__c;
                    guestID = paramMemberId;
                }

                if (eventStatus.Status__c == 'Closed/Posted') {
                    isPostedAndClosed = true;
                }
            }
            othCharge.Customer__c = String.valueOf(paramMemberId);
        }
    }

    public void init() {
        setPageAttributes();
        Schema.DescribeFieldResult statusFieldDescription = TXN__c.GlobalType__c.getDescribe();
        statusOptions = new List<SelectOption>();

        for (Schema.Picklistentry picklistEntry : statusFieldDescription.getPicklistValues()) {
            statusOptions.add(new SelectOption(pickListEntry.getValue(), pickListEntry.getLabel()));
        }

        Schema.DescribeFieldResult statusFieldDescription1 = TXN__c.GlobalSubType__c.getDescribe();
        sos = new List<SelectOption>();

        for (Schema.Picklistentry picklistEntry1 : statusFieldDescription1.getPicklistValues()) {
            sos.add(new SelectOption(picklistEntry1.getValue(), picklistEntry1.getLabel()));
        }
    }

    /**
     * Sets dynamic page attributes and state based on URL parameters
     */
    private void setPageAttributes() {
        paramFrom = getSanitizedParam('from');
        paramMemberId = getSanitizedParam('memberId');
        paramMemberName = getSanitizedParam('memberName');
        paramReservationId = getSanitizedParam('reservationId');
        referrerURL = '/' + paramMemberId;
        currentPageLabel = getCurrentPageLabel();

        if (paramFrom == 'payment') {
            String paymentId = getPaymentId();
        }
        
        if(paramFrom == 'MemberPage') {
            dynamicContent = 'Payment';
        }else {
            dynamicContent = 'Deposit';
        }
        // not implementing banquet yet
        if (paramFrom == 'Banquet' && paramReservationId != '') {
            eventDepositList = (List<Event__c>)Data.read(
                                   'Select Id, Deposit_Amount__c, Deposit_Remaining__c, Deposit_Amount_Received__c, Sponsoring_Customer__c From Event__c Where Id = :paramReservationId',
            new Map<String, Object> {
                'paramReservationId' => paramReservationId
            }
                               );
            eventDeposit = eventDepositList[0];
            paramMemberId = eventDeposit.Sponsoring_Customer__c;
            referrerURL = '/' + paramReservationId;
            selectedValue = Utility.searchRecordType('Deposit', 'TXN__c');
        }
        // not implementing banquet yet
    }

    public List<TXN__c> allCharges {
        get {
            List<TXN__c> txn = (List<TXN__c>)Data.read(
                'SELECT AMOUNT__c, Id, Name, Description__c, Date__c, Tax__c, service_charge__c, Total_Amount__c, Status__c, Charge_Amount_Left__c, Reservation__r.Id, Reservation__r.Name FROM TXN__c WHERE (Customer__c = :paramMemberId) AND RECORDTYPEID = :chargeId AND (Status__c = \'Unpaid\' OR Status__c = \'Partial\') AND Reservation__r.Id IN (Null, \'\')',
            new Map<String, Object> {
                'paramMemberId' => paramMemberId,
                'chargeId' => Utility.searchRecordType('Charge', 'TXN__c')
            }
            );

            return txn;
        }
        private set;
    }

    /**
     * Build options for Payment Type select
     * @return list of select options
     */
    public List<SelectOption> getRecordTypeOptions() {
        Map<String, Schema.RecordTypeInfo> transactionRecordTypeInfo = TXN__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        List<SelectOption> recordTypesOptions = new List<SelectOption>();

        recordTypesOptions.add(new SelectOption('', '--None--'));

        if (paramFrom == 'Banquet') {
            // not implementing banquet yet
            for (String s : transactionRecordTypeInfo.keySet()) {
                if (s == 'Deposit') {
                    recordTypesOptions.add(new SelectOption(transactionRecordTypeInfo.get(s).getRecordTypeId(), s));
                }
            }
            //not implementing banquet yet*/
        } else {
            for (String s : transactionRecordTypeInfo.keySet()) {
                if (s == 'Payment') {
                    recordTypesOptions.add(new SelectOption(transactionRecordTypeInfo.get(s).getRecordTypeId(), s));
                }
            }
        }

        if (selectedValue == Utility.searchRecordType('Credit', 'TXN__c')) {
            updateChargeName = 'Check to manually apply Credit:';
            renderupdateChargeName = true;
        }

        if (selectedValue == Utility.searchRecordType('Payment', 'TXN__c')) {
            updateChargeName = 'Check to manually apply Payment:';
            renderupdateChargeName = true;
        }

        return recordTypesOptions;
    }

    /**
     * Sanitize query parameter
     * @return {String} sanitized query parameter
     */
    public static String getSanitizedParam(String str) {
        String param = Apexpages.currentPage().getParameters().get(str);
        return param != null ? String.escapeSingleQuotes(param).trim() : '';
    }

    /**
     * Get current page name from query parameter
     * @return {String} name of page
     */
    public static String getCurrentPageLabel() {
        String paramFrom = getSanitizedParam('from');
        String paramReservationId = getSanitizedParam('reservationId');

        if (paramFrom == 'MemberPage') {
            return 'New Payment';
        }

        //not implementing banquet yet
        if (paramFrom == 'Banquet' && paramReservationId != '') {
            return 'Deposit Page';
        }
        //not implementing banquet yet*/

        return 'Payment Detail';
    }

    /**
     * Get payment Id from query parameter
     * @return {String} paymentId
     */
    public static String getPaymentId() {
        return String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('paymentId')).trim();
    }

    /**
     * Validate payment date
     * @param {TXN__c} othCharge othCharge TXN__c record
     * @return {Boolean}
     */
    public static Boolean isPaymentDateValid(TXN__c othCharge) {
        if (othCharge.Date__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00000, Payment Date is missing');
            return false;
        }

        return true;
    }

    /**
     * Ensure user has made a type selection
     * @param selectedVal is the value of the Type select dropdown
     * @return {Boolean}
     */
    public static Boolean isTypeValid(String selectedVal) {
        if (selectedVal == null || selectedVal == '' || selectedVal == '--None--') {
            setPageErrorMessage('Error No: TxnPaymentError00003, Message: Type is Not Selected');
            return false;
        }

        return true;
    }

    /**
     * Ensure pAmount exists and is not negative
     * @param pAmount value of the amount field
     * @return {Boolean}
     */
    public static Boolean isAmountValid(String pAmount) {
        if (pAmount == '' || pAmount == null) {
            setPageErrorMessage('Error No: TxnPaymentError00003, Message: Amount cannot be empty.');
            return false;
        }

        if ((Decimal.valueOf(pAmount.trim())) <= 0) {
            setPageErrorMessage('Error No: TxnPaymentError00004, Message: Amount cannot be Zero Or Negative.');
            return false;
        }

        return true;
    }

    /**
     * Set apex page error message
     * @param msg Message string to set
     * @return {String}
     */
    public static String setPageErrorMessage(String msg) {
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, msg));
        return msg;
    }

    /**
     * Ensure the check fields are valid
     * @param memberId customer ID
     * @param othCharge TXN__c
     * @return {Boolean}
     */
    public static Boolean isCheckValid(String memberId, TXN__c othCharge) {
        List<TXN__c> customerTransactions = (List<TXN__c>)Data.read(
                                                'SELECT Check_Number__c, Customer__c FROM TXN__c WHERE Customer__c = :memberId AND (Check_Number__c != null OR Check_Number__c != \'\')',
        new Map<String, Object> {
            'memberId' => memberId
        }
                                            );

        for (TXN__c customerTxn : customerTransactions) {
            if (customerTxn.Check_Number__c == othCharge.Check_Number__c) {
                setPageErrorMessage('Error No: TxnPaymentError00002, Duplicate Check Number.');
                return false;
            }
        }

        if (othCharge.Check_Number__c == '' || othCharge.Check_Number__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00003, Check number is missing.');
            return false;
        }

        if (othCharge.Name_on_Check__c == '' || othCharge.Name_on_Check__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00004, Name on Check is missing.');
            return false;
        }

        if (othCharge.Check_Date__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00005, Check date is missing.');
            return false;
        }

        return true;
    }

    /**
     * Validate Credit Card
     * @param {TXN__c} othCharge is a TXN__c record
     * @return {Boolean}
     */
    public static Boolean isCreditCardValid(TXN__c othCharge) {
        if (othCharge.Cardholder_Name__c == '' || othCharge.Cardholder_Name__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00006, Cardholder name is missing.');
            return false;
        }

        if (othCharge.Card_Type__c == '' || othCharge.Card_Type__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00007, Card type is missing.');
            return false;
        }

        if (othCharge.Card_Last_4_Digits__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00008, Last 4 Digits of Card is missing.');
            return false;
        }

        return true;
    }

    /**
     * Validate ACH
     * @param {TXN__c} othCharge is a TXN__c record
     * @return {Boolean}
     */
    public static Boolean isACHValid(TXN__c othCharge) {
        if (othCharge.Bank_Name__c == '' || othCharge.Bank_Name__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00009, Bank Name is Missing');
            return false;
        }

        if (othCharge.Routing_Number__c == '' || othCharge.Routing_Number__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00010, Routing Number is Missing');
            return false;
        }

        if (othCharge.Account_Type__c == '' || othCharge.Account_Type__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00011, Account Type is Missing');
            return false;
        }

        if (othCharge.Account_Number_Last_4_Digits__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00012, Account Number is Missing');
            return false;
        }

        if (othCharge.Name_on_Account__c == '' || othCharge.Name_on_Account__c == null) {
            setPageErrorMessage('Error No: TxnPaymentError00013, Name on Account is missing.');
            return false;
        }

        return true;
    }

    /**
     * Ensure the Statement Description is not empty or null
     * @param txn TXN__c
     * @param othCharge TXN__c
     * @return {Boolean}
     */
    public static Boolean isStatementDescriptionValid(TXN__c txn, TXN__c othCharge) {
        if (( txn.Statement_Description__c == '' || txn.Statement_Description__c == null) && (othCharge.Statement_Description__c == '' || othCharge.Statement_Description__c == null)) {
            setPageErrorMessage('Error No : TxnPaymentError00001, Statement Description is missing.');
            return false;
        }

        return true;
    }

    /**
     * Ensure paymentType is not empty or null
     * @param pType references the value of the Payment Type select dropdown
     * @return {Boolean}
     */
    public static Boolean isPaymentTypeValid(String pType) {
        if (pType == '' || pType == null) {
            setPageErrorMessage('Error No: TxnPaymentError000012, Select Payment Method');
            return false;
        }

        return true;
    }

    /**
     * Ensure payment method value is not empty or null
     * @param id {String}
     * @return {Boolean}
     */
    public static Boolean isPaymentMethodValid(String id) {
        if (id == '' || id == null) {
            setPageErrorMessage('Error No: TxnPaymentError000011, Problem with payment');
            return false;
        }

        return true;
    }

    public PageReference save() {
        Boolean success = false;

        txn = new TXN__c();

        if (selectedValue != Utility.searchRecordType('Deposit', 'TXN__c')) {
            if (!isPaymentDateValid(othCharge)) {
                return null;
            }

            if (!isTypeValid(selectedValue)) {
                return null;
            }

            if (!isAmountValid(paymentAmount)) {
                return null;
            }

            if (!isStatementDescriptionValid(txn, othCharge)) {
                return null;
            }
        } else {
            txn.Reservation__c = paramReservationId;
        }

        txn.Customer__c = paramMemberId;
        txn.RecordTypeId = selectedValue;
        txn.Description__c = othCharge.Description__c;
        txn.Statement_Description__c = othCharge.Statement_Description__c;
        txn.Date__c = othCharge.Date__c;
        txn.Payment_Type__c = 'Cash';
        txn.Status__c = 'Paid';

        success = true;

        /* TODO: This block needs to be reworked. Payment Method and transactionId not working.
            if (paymentType == 'CreditCard') {
                // TODO: handle error - 'none' is not an appropriate type for transactionId
                // TODO: work out payment method
                String strQuery= 'SELECT Customer__r.FirstName, Customer__r.LastName,' + Utility.getFields('Payment_Method__c') + ' FROM Payment_Method__c WHERE Id = \'' + String.escapeSingleQuotes(transactionId) + '\' LIMIT 1';
                paymentMethod = Database.query(strQuery);
                String firstName = paymentMethod.Customer__r.FirstName;
                String lastName = paymentMethod.Customer__r.LastName;
                if (selectedValue == Utility.searchRecordType('Deposit', 'TXN__c')) {
                    paymentAmount = String.valueOf(Double.valueOf(eventDeposit.Deposit_Amount__c));
                }
            }
            if (!success) {
                return null;
            }
        */

        SavePoint sp = Database.setSavepoint();      
            if (!isPaymentTypeValid(paymentType)) {
                return null;
            }

            if (paymentType == 'Check') {
                if (!isCheckValid(paramMemberId, othCharge)) {
                    return null;
                }

                txn.Payment_Type__c = 'Check';
                txn.Check_Number__c = othCharge.Check_Number__c;
                txn.Check_Date__c = othCharge.Check_Date__c;
                txn.Name_on_Check__c = othCharge.Name_on_Check__c;
                txn.Status__c = 'Paid';
            }

            if (paymentType == 'CreditCard') {
                if (!isCreditCardValid(othCharge)) {
                    return null;
                }

                txn.Payment_Type__c = 'Credit Card';
                txn.Cardholder_Name__c = othCharge.Cardholder_Name__c;
                txn.Card_Type__c = othCharge.Card_Type__c;
                txn.Card_Last_4_Digits__c = othCharge.Card_Last_4_Digits__c;
                txn.External_Payment_Transaction_Code__c = othCharge.External_Payment_Transaction_Code__c;
                txn.External_Payment_Authorization_Code__c = othCharge.External_Payment_Authorization_Code__c;
            }

            if (paymentType == 'ACH') {
                if (!isACHValid(othCharge)) {
                    return null;
                }

                txn.Payment_Type__c = 'ACH';
                txn.Bank_Name__c = othCharge.Bank_Name__c;
                txn.Account_Type__c = othCharge.Account_Type__c;
                txn.Routing_Number__c = othCharge.Routing_Number__c;
                txn.Account_Number_Last_4_Digits__c = othCharge.Account_Number_Last_4_Digits__c;
                txn.Name_on_Account__c = othCharge.Name_on_Account__c;
                txn.Status__c = 'Paid';
            }

        Double amt = 0.00;
        SavePoint sp1 = Database.setSavepoint();

        if (selectedValue != Utility.searchRecordType('Deposit', 'TXN__c')) {
            amt = double.valueOf(paymentAmount) * -1;
        } else {
            amt = double.valueOf(eventDeposit.Deposit_Amount__c) * -1;
        }


        txn.Amount__c = Utility.Round2(amt); // TODO: revisit * -1. Currently, payments must be negative.
        success = true;
        String latest_payment_id = null;

        if (selectedValue == Utility.searchRecordType('Credit', 'TXN__c')) {
            txn.Status__c = 'Approved';
            txn.Payment_Type__c = 'Manual Credit';
        }

        if (billToMember != null && billToMember != '') {
            txn.Bill_To_Member__c = billToMember;
        } else {
            txn.Bill_To_Member__c = paramMemberId;
        }

        Data.create(txn);
        latest_payment_id = txn.id;

        if (!success) {
            return null;
        }

        try {

            // If no charges are checked in the all charges table, apply payment to the oldest charge
            if (selectedValue != Utility.searchRecordType('Deposit', 'TXN__c')) {
                String sanitizedPaymentAmount = String.escapeSingleQuotes(paymentAmount);
                AutoPay(sanitizedPaymentAmount, latest_payment_id, paramMemberId);
            } 
        } catch (Exception e) {
            return null;
        }

        PageReference pg = new PageReference('/apex/TxnManualPayment?from=MemberPage&memberId= ' + paramMemberId + '&memberName= ' + paramMemberName);

        if (paramFrom == 'Banquet') {
            pg = new PageReference('/apex/TxnManualPayment?from=Banquet&ReservationId=' + paramReservationId);
            pg.getParameters().put('message', 'Deposit Successful');
            pg.setRedirect(true);
            return pg;
        }
        pg.getParameters().put('message', 'Payment Successful');
        pg.setRedirect(true);
        return pg;
    }

    public Txn_Payment_To_Charge_Mapping__c getPaymentToCharge(Double amt, String chargeid, String paymentid) {
        Txn_Payment_To_Charge_Mapping__c paymentToCharge = new Txn_Payment_To_Charge_Mapping__c();

        paymentToCharge.amount_paid__c = amt;
        paymentToCharge.Charge_Id__c = chargeid;
        paymentToCharge.Payment_Id__c = paymentid;
        String paymentMethod = '';

        if (selectedValue == Utility.searchRecordType('Payment', 'TXN__c')) {
            paymentMethod = 'Payment';
        } else if (selectedValue == Utility.searchRecordType('Deposit', 'TXN__c')) {
            paymentMethod = 'Deposit';
        } else if (selectedValue == Utility.searchRecordType('Credit', 'TXN__c')) {
            paymentMethod = 'Manual Credit';
        } else {
            paymentMethod = 'Credit';
        }

        paymentToCharge.Method__c = paymentMethod;
        return paymentToCharge;
    }

    public void insertDataToPaymentToChargesObject(Double amt, String chargeid, String paymentid) { //, String folioId
        Payment_to_charge = new Txn_Payment_To_Charge_Mapping__c();
        Payment_to_charge.amount_paid__c = amt;
        Payment_to_charge.Charge_Id__c = chargeid;
        Payment_to_charge.Payment_Id__c = paymentid;
        String paymentMethod = '';

        if (selectedValue == Utility.searchRecordType('Payment', 'TXN__c')) {
            paymentMethod = 'Payment';
        } else if (selectedValue == Utility.searchRecordType('Deposit', 'TXN__c')) {
            paymentMethod = 'Deposit';
        } else if (selectedValue == Utility.searchRecordType('Credit', 'TXN__c')) {
            paymentMethod = 'Manual Credit';
        } else {
            paymentMethod = 'Credit';
        }

        Payment_to_charge.Method__c = paymentMethod;
        Data.create(Payment_to_charge);
    }

    // pay automatically
    public void AutoPay(String paymentAmount, String latest_payment_id, String memId) {
        // String folioID = '';
        Double remainingAmt = Double.valueOf(String.escapeSingleQuotes(paymentAmount));
        Double paidAmount = 0.00;
        Double TotalAmount = 0.00;

        if (remainingAmt > 0) {
            List<TXN__c> GetRecordList = new List<TXN__c>();
            List<Txn_Payment_To_Charge_Mapping__c> paymentToChargeList = new List<Txn_Payment_To_Charge_Mapping__c>();
            List<TXN__c> txnRecords = (List<TXN__c>)Data.read(
                                          'SELECT Id, Status__c, Charge_Amount_Left__c, Total_Amount__c, DateTime__c, Reservation__c FROM TXN__c WHERE RecordTypeId = :chargeId AND Customer__c = :memId AND Status__c != \'Fully Paid\' ORDER BY DateTime__c',
            new Map<String, Object> {
                'chargeId' => Utility.searchRecordType('Charge', 'TXN__c'),
                'memId' => String.escapeSingleQuotes(memId)
            }
                                      );

            List<String> txnIdList = new List<String>();

            for (TXN__c GetRecord : txnRecords) {
                if (GetRecord.Charge_Amount_Left__c > 0) {
                    if (remainingAmt >= Double.valueOf(GetRecord.Charge_Amount_Left__c) ) {

                        remainingAmt = remainingAmt - Double.valueOf(GetRecord.Charge_Amount_Left__c);

                        paymentToChargeList.add(
                            getPaymentToCharge(Double.valueOf(GetRecord.Charge_Amount_Left__c), GetRecord.Id, latest_payment_id)
                        );

                        GetRecord.Charge_Amount_Left__c = 0;
                        GetRecord.Status__c = 'Fully Paid';

                        GetRecordList.add(GetRecord);

                    } else {
                        GetRecord.Charge_Amount_Left__c = GetRecord.Charge_Amount_Left__c - Double.valueOf(remainingAmt);

                        paymentToChargeList.add(
                            getPaymentToCharge(Double.valueOf(remainingAmt), GetRecord.Id, latest_payment_id)
                        );

                        GetRecord.Status__c = 'Partial';

                        // add to list to loop through later
                        txnIdList.add(String.valueOf(GetRecord.Id));
                        remainingAmt = 0.00;
                        GetRecordList.add(GetRecord);
                        break;
                    }
                }
            } // end for txnRecords loop

            Data.modify(GetRecordList);
            Data.create(paymentToChargeList);
        }


        if (remainingAmt >= 0) {
            txn = new TXN__c();
            txn.id = latest_payment_id;
            Update txn;
        }
    }

    public pageReference cancelAction() {
        PageReference pg = new PageReference('/' + paramMemberId);
        if (paramFrom == 'Banquet') {
            pg = new PageReference('/' + paramReservationId);
        }
        pg.setRedirect(true);
        return pg;
    }

}