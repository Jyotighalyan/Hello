public with sharing class voidCheckorCheckBatchService {
    public voidCheckorCheckBatchService() {

    }
    public Vendor_Invoice_Check__c getCheckDetail(string checkId) {
        Vendor_Invoice_Check__c VIC = (Vendor_Invoice_Check__c) Data.read('select id, Void__c, Amount__c, Check_Number__c, Vendor_Invoice_Check_Batch__r.Financial_Journal_Entry__c from ' +
                                      ' Vendor_Invoice_Check__c where id =:checkId',
        new Map<String, Object> {
            'checkId' => checkId
        }).get(0);
        return VIC;
    }
    public List<Vendor_Invoice_Check__c> getAllChecks(string batchId) {
        List<Vendor_Invoice_Check__c> VIC = (List<Vendor_Invoice_Check__c>) Data.read('select id, Void__c, Amount__c, Check_Number__c, Vendor_Invoice_Check_Batch__r.Financial_Journal_Entry__c from ' +
                                            ' Vendor_Invoice_Check__c where Vendor_Invoice_Check_Batch__c =:batchId',
        new Map<String, Object> {
            'batchId' => batchId
        });
        return VIC;
    }
    public Vendor_Invoice_Check_Batch__c getBatchDetail(string batchId) {
        Vendor_Invoice_Check_Batch__c VICB = (Vendor_Invoice_Check_Batch__c) Data.read('select id,Void__c, Batch_Date__c  from ' +
                                             ' Vendor_Invoice_Check_Batch__c where id =:batchId',
        new Map<String, Object> {
            'batchId' => batchId
        }).get(0);
        return VICB;
    }
    public void VoidCheck(List<Vendor_Invoice_Check__c> CheckDetails, date postedDate) {
        if (CheckDetails.size() > 0) {
            Vendor_Invoice_Check__c CheckDetail = CheckDetails.get(0);
            system.debug('check this entry  :' + CheckDetail.Vendor_Invoice_Check_Batch__r.Financial_Journal_Entry__c);
            List<Financial_Journal_Line__c> journalLines = (List<Financial_Journal_Line__c>)Data.read(
                        'select Financial_Account__c,Credit__c,Debit__c from Financial_Journal_Line__c where Financial_Journal_Entry__c =:entryId ',
            new Map<String, Object> {
                'entryId' => CheckDetail.Vendor_Invoice_Check_Batch__r.Financial_Journal_Entry__c
            }
                    );
            double Amount = math.abs(double.valueOf(CheckDetail.Amount__c));
            Financial_Journal_Entry__c fjEntry = new Financial_Journal_Entry__c();
            fjEntry.Description__c = 'voided Check #' + CheckDetail.Check_Number__c;
            fjEntry.Entry_Date__c = postedDate;
            fjEntry.Posted__c = true;
            fjEntry.Post_Date__c = postedDate;
            data.create(fjEntry);

            string CreditAccount = '';
            string DebitAccount = '';
            for (Financial_Journal_Line__c lines : journalLines) {
                if (lines.Credit__c != 0) {
                    DebitAccount = lines.Financial_Account__c;
                } else {
                    CreditAccount = lines.Financial_Account__c;
                }
            }
            Financial_Journal_Line__c CreditLine = new Financial_Journal_Line__c();
            Financial_Journal_Line__c DebitLine = new Financial_Journal_Line__c();

            string debitcredit = Utility.getCredDebitStatus(CreditAccount);
            CreditLine.Amount__c = Amount * -1;
            if (debitcredit == 'Credit') {
                CreditLine.Amount__c = Amount;
            }
            CreditLine.Financial_Account__c = CreditAccount;
            CreditLine.Financial_Journal_Entry__c = fjEntry.Id;
            CreditLine.Transaction_Date__c = date.today();
            data.create(CreditLine);

            debitcredit = Utility.getCredDebitStatus(DebitAccount);
            DebitLine.Amount__c = Amount;
            if (debitcredit == 'Credit') {
                DebitLine.Amount__c = Amount * -1;
            }
            DebitLine.Financial_Account__c = DebitAccount;
            DebitLine.Financial_Journal_Entry__c = fjEntry.Id;
            DebitLine.Transaction_Date__c = date.today();
            data.create(DebitLine);

            CheckDetail.Void__c = true;
            CheckDetail.Voided_Financial_Journal_Entry__c = fjEntry.id;
            data.modify(CheckDetail);

            List<Vendor_Invoice_Payment__c> PaymentDetail = (List<Vendor_Invoice_Payment__c>)Data.read(
                        'select Payment_Type__c,Amount_Paid__c,Amount__c ,Vendor_Invoice__c ,Vendor_Invoice_Line__c  from Vendor_Invoice_Payment__c where Vendor_Invoice_Check__c =:checkId ',
            new Map<String, Object> {
                'checkId' => CheckDetail.Id
            }
                    );
            for (Vendor_Invoice_Payment__c Oldpayment : PaymentDetail) {

                Vendor_Invoice_Payment__c payment = new Vendor_Invoice_Payment__c();
                payment.Amount_Paid__c = 0;
                payment.Vendor_Invoice__c = Oldpayment.Vendor_Invoice__c;
                payment.Vendor_Invoice_Line__c = Oldpayment.Vendor_Invoice_Line__c;
                Data.create(payment);
                Oldpayment.Amount_Paid__c = 0;
                data.modify(Oldpayment);
            }
        }
    }
}