public with sharing class TxnRefundController {
  public string PaymentId {get; set;}
  public string GuestId {get; set;}
  public string memberId {get; set;}
  public string memName {get; set;}
  public string paymentAmount {get; set;}
  public string paymentMethod {get; set;}
  public string paymentType {get; set;}
  public string FromPage {get; set;}
  public string FromLink {get; set;}
  public string currentPage {get; set;}
  public string breadCrump {get; set;}
  public TXN__c othCharge {get; set;}
  public TXN__c txnRecord {get; set;}
  public Account venDor {get; set;}
  public String allPaymentPage {get; set;}
  public String memId {get; set;}
  public String membName {get; set;}
  public Boolean closeVendorPopup {get; set;}
  public Boolean isGuestPaying {get; set;}
  public Boolean isMemberPaying {get; set;}
  public TXN__c UpdatePaymentRow {get; set;}
  public List<SelectOption> RefundType {get; set;}
  public string PaymentName {get; set;}
  public decimal amount_left_to_refund {get; set;}
  public double amount_left_to_clear {get; set;}
  public string PaymentTransactionId {get; set;}
  public List<Financial_Journal_Line__c> finLinesListPay;



  public TxnRefundController() {
    venDor = new Account();
    closeVendorPopup = false;

    othCharge = new  TXN__c();
    RefundType = new  List<SelectOption>();
    //get payment if
    PaymentId = Apexpages.currentPage().getParameters().get('PaymentId');
    PaymentId = String.escapeSingleQuotes(PaymentId);
    if (PaymentId != '' && PaymentId != null) {
      //get payment details
      //List<TXN__c> txnCharges=[SELECT ID,Name,Bill_To_Member__c,RECORDTYPEID,Check_Date__c,Check_Number__c,Payment_Type__c,External_Payment_Authorization_Code__c,External_Payment_Transaction_Code__c,External_Payment_Method_Last_4_Digits__c,External_Payment_Method__c,Description__c,Date__c,Total_Amount__c,Status__c,Amount__c FROM TXN__c WHERE Id=:String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('PaymentId'))];
      List<TXN__c> txnCharges = (List<TXN__c>)Data.read('SELECT ID, Name, Bill_To_Member__c,'
                                + ' RECORDTYPEID, Check_Date__c, Check_Number__c, Payment_Type__c, External_Payment_Authorization_Code__c,'
                                + ' External_Payment_Transaction_Code__c, External_Payment_Method_Last_4_Digits__c,'
                                + ' External_Payment_Method__c, Description__c, Date__c, Total_Amount__c, Status__c, Amount__c'
                                + ' FROM TXN__c WHERE Id= :paymentId',
      new Map<String, Object> {
        'paymentId' => Apexpages.currentPage().getParameters().get('PaymentId')
      });

      //TXN__c txnRecord = [SELECT ID, Name, Bill_To_Member__c, RECORDTYPEID, Check_Date__c, Check_Number__c, Payment_Type__c, External_Payment_Authorization_Code__c, External_Payment_Transaction_Code__c, External_Payment_Method_Last_4_Digits__c, External_Payment_Method__c, Description__c, Date__c, Total_Amount__c, Status__c, Amount__c, Customer__c FROM TXN__c WHERE Id = :String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('PaymentId'))];
      TXN__c txnRecord = (TXN__c)Data.read('SELECT ID, Name, Bill_To_Member__c,'
                                           + ' RECORDTYPEID, Check_Date__c, Check_Number__c, Payment_Type__c, External_Payment_Authorization_Code__c,'
                                           + ' External_Payment_Transaction_Code__c, External_Payment_Method_Last_4_Digits__c,'
                                           + ' External_Payment_Method__c, Description__c, Date__c, Total_Amount__c, Status__c, Amount__c, Customer__c'
                                           + ' FROM TXN__c WHERE Id= :paymentId',
      new Map<String, Object> {
        'paymentId' => Apexpages.currentPage().getParameters().get('PaymentId')
      }).get(0);

      othCharge.Bill_To_Member__c = txnRecord.Bill_To_Member__c;
      othCharge.Customer__c = txnRecord.Customer__c;
      memId = txnRecord.Bill_To_Member__c;
      if (txnCharges.size() > 0) {
        // List<Contact> ContDetail = [SELECT ID, Name FROM Contact WHERE Id = :string.valueOf(txnCharges.get(0).Bill_To_Member__c)];
        List<Contact> ContDetail = (List<Contact>)Data.read('SELECT ID, Name FROM Contact WHERE Id = :billToMember',
        new Map<String, Object> {
          'billToMember' => string.valueOf(txnCharges.get(0).Bill_To_Member__c)
        });

        if (ContDetail.size() > 0) {
          memberId = string.valueOf(ContDetail.get(0).ID);
          memName = string.valueOf(ContDetail.get(0).Name);
        }
      }
      amount_left_to_refund = Math.abs(txnRecord.Amount__c);
      Map<Id, List<TXN__c>> testMap = new Map<Id, List<TXN__c>>();
      //for (TXN__c tx : [SELECT Id, Related_To__c, Related_To__r.Amount__c, Amount__c
      //                  FROM TXN__c
      //                  WHERE Related_To__c = :txnRecord.id])
      for (TXN__c tx : (List<TXN__c>)Data.read('SELECT Id, Related_To__c, Related_To__r.Amount__c, Amount__c'
           + ' FROM TXN__c WHERE Related_To__c = :relatedTo',
      new Map<String, Object> {
      'relatedTo' => txnRecord.id
    })) {
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
        amount_left_to_refund = Math.abs(parentAmount) - childAmounts;
        amount_left_to_refund = amount_left_to_refund.setScale(2);
        if (childAmounts > Math.abs(parentAmount)) {

          //for (TXN__c newTran : triggerNew) newTran.addError('You cannot refund more than the amount of the payment.', false);
        }
      }


      //get required paramters
      PaymentName = string.valueOf(txnCharges.get(0).Name);
      PaymentTransactionId = string.valueOf(txnCharges.get(0).Id);
      GuestId = txnCharges.get(0).Bill_To_Member__c;

      Schema.DescribeFieldResult fieldResult = TXN__c.Payment_Type__c.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

      for ( Schema.PicklistEntry f : ple) {
        RefundType.add(new SelectOption(f.getLabel(), f.getValue()));
      }
      paymentAmount = string.valueOf(double.valueOf(txnCharges.get(0).Total_Amount__c) * -1);
      paymentType = string.valueOf(txnCharges.get(0).Payment_Type__c);


    }
    FromPage = Apexpages.currentPage().getParameters().get('from');
    if (FromPage == 'MemberPayement' || FromPage == null) {
      FromLink = '/' + PaymentId;
      allPaymentPage = '/apex/allPayments?memberId=' + memId;
      currentPage = 'Refund';
      breadCrump = 'Payment Page';
      membName = 'All-Payments';
    }
  }
  public PageReference Cancel() {
    system.debug('cancel');
    PageReference reRend = new PageReference('/' + memId);
    reRend.setRedirect(true);
    return reRend;
  }
  public PageReference Save() {
    system.debug('in SAVE');
    //check refund reason is entered by user
    finLinesListPay = new List<Financial_Journal_Line__c>();

    if (othCharge.Refund_Reason__c == '' || othCharge.Refund_Reason__c == null) {

      ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Enter refund reason.'));
      return null;

    }
    if (othCharge.Amount__c > amount_left_to_refund) {
      ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Refund Amount larger than the amount left to refund'));
      return null;
    }

    if (othCharge.Amount__c < 0) {
      ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Refund Amount must be positive'));
      return null;
    }

    if (othCharge.Payment_Type__c == null) {
      ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Refund Method: You must enter a value.'));
      return null;
    }


    if (othCharge.Payment_Type__c != 'Credit Card') {
      if (othCharge.Amount__c == null || othCharge.Amount__c == 0) {

        ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Refund amount should be greater then 0.'));
        return null;
      }
    }


    UpdatePaymentRow = new  TXN__c();



    SavePoint sp = Database.setSavepoint();
    double amount_remaining = othCharge.Amount__c;
    double left_amt = Utility.Round2(double.valueOf(othCharge.Amount__c));
    if (left_amt < 0)left_amt = 0;
    double left_amt_refund = Utility.Round2(double.valueOf(othCharge.Amount__c));
    //UpdatePaymentRow.amount_left_to_clear__c=left_amt;
    //UpdatePaymentRow.amount_left_to_refund__c=left_amt_refund;
    UpdatePaymentRow.Id = PaymentId;
    Data.modify(UpdatePaymentRow);
    othCharge.RecordTypeId = Utility.searchRecordType('Refund', 'TXN__c');
    othCharge.Related_To__c = PaymentId;
    othCharge.Charge_Amount_Left__c = othCharge.Amount__c;
    System.debug(LoggingLevel.Info, 'Your info' + othCharge.Payment_Type__c);
    //othCharge.Description__c = 'Refund for the payment - ' + [select Name from TXN__c where id = :String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('PaymentId'))].Name;
    TXN__c t = (TXN__c)Data.read('select Name from TXN__c where id = :paymentId',new Map<String,Object>{'paymentId'=>Apexpages.currentPage().getParameters().get('PaymentId')}).get(0);
    othCharge.Description__c = 'Refund for the payment - '+t.Name;    
    othCharge.Status__c = 'Unpaid';
    othCharge.service_charge__c = 0.00;
    othCharge.Tax__c = 0.00;
    othCharge.Related_To__c = PaymentId;

    Data.create(othCharge);
    PageReference reRend = new PageReference('/' + memId);
    reRend.setRedirect(true);
    return reRend;
  }

  public PageReference closeWindow() {
    closeVendorPopup = false;
    return null;
  }
  public PageReference openWindow() {
    closeVendorPopup = true;
    return null;
  }

}