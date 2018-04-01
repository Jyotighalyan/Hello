/*
@Name           : VendorCheckRunControllerTest
@Author         : customersuccess@cloud62.com
@Description    : Test methods for VendorCheckRunController
*/
@isTest
private class VendorCheckRunControllerTest {
    public static String AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static String vendorAcc = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    public static String VendorRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    static Integer jj=0;
    static testmethod void vendorCheckRunControllerTest1() {      
        Vendor_Invoice_Check_Batch__c vicb = new Vendor_Invoice_Check_Batch__c();
        insert vicb;
        Check_Run__c cr = new Check_Run__c(Printed_Check_Digits__c = 8,Next_Check_Number__c='0');
        insert cr;
        
        Financial_Account__c fa = new Financial_Account__c(Name='Test',Account_Number__c='asd32sd',Category__c='Liability', Bank_Account__c = true, Active__c=true);
        insert fa;
        Default_Account__c da =new Default_Account__c (Default_Type_Name__c ='Accounts Payable',Financial_Account__c = fa.Id);
        insert da;
        
        check_PDF_Spacing__c cp=new check_PDF_Spacing__c();
        cp.amount_in_words_top__c=0;
        cp.Name='section1';
        insert cp;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(vicb);
        VendorCheckRunController apc = new VendorCheckRunController(sc);
        //Contact v = new Contact(Name = 'Test name');
        //insert v;
    
        Account v= TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account'));
        Vendor_Invoice_Check__c vicc = new Vendor_Invoice_Check__c(Amount__c = 300,Vendor__c = v.id,Check_Number__c = '63251478',
                Vendor_Invoice_Check_Batch__c = vicb.Id,Memo__c = 'New Memo',Check_Date__c = Date.Today());
        insert vicc;
        
        Vendor_Invoice__c vi = new Vendor_Invoice__c(Vendor_Invoice_Check__c = vicc.Id,Invoice_Date__c= Date.today(),Due_Date__c = Date.today(),Hold_Status__c = false,Vendor__c=v.id,Invoice_Number__c='156985', Amount__c=500);
        insert vi;
        Financial_Account__c viacc=TxnTestUtility.createFinancialAccount('test1');
        Vendor_Invoice_Line__c vil = new Vendor_Invoice_Line__c(Payment_Type__c = 'Check',Financial_Account__c=viacc.id,Vendor_Invoice__c = vi.Id, Amount__c=500);
        insert vil;
        Vendor_Invoice_Payment__c vip = new Vendor_Invoice_Payment__c(Amount_Paid__c = 1,Vendor_Invoice__c = vi.Id, Vendor_Invoice_Line__c=vil.Id);
        insert vip;
        Vendor_Invoice__c vi1 = new Vendor_Invoice__c(Due_Date__c = Date.today(),Invoice_Date__c = Date.today(),Vendor__c=v.id,Invoice_Number__c=string.valueOf(jj++), Amount__c=500,  Hold_Status__c = true);
        insert vi1;
        Vendor_Invoice_Line__c vil1 = new Vendor_Invoice_Line__c(Vendor_Invoice__c = vi1.Id, Amount__c=500,Financial_Account__c=viacc.id);
        insert vil1;
        Vendor_Invoice_Payment__c vip1 = new Vendor_Invoice_Payment__c(Amount_Paid__c = 1,Vendor_Invoice__c = vi1.Id, Vendor_Invoice_Line__c=vil1.Id);
        insert vip1;
       // Financial_Closing__c fc = new Financial_Closing__c(Year__c=Date.today
         //                                                 ().year()+'-'+Date.today().addYears(1).year(), Month__c=Date.today().Month()+'');
        Test.StartTest();
        apc.loadPostedInvoices();
        apc.loadNotPostedInvoices();
        apc.selectedVendor = v.id;
        apc.selectAllVendor();
        apc.selectAll = true;
        apc.selectAll();
        apc.checkClosedMonth(Date.today());
        apc.locationSelection = vil;
        apc.checkBatchDate();
        apc.getOperatingChecksFA();
        apc.loadPostedInvoices();
        
        for(VendorCheckRunService.VendorInvoiceWrapper viw : apc.viwMap.values()){
            viw.selected = true;
            viw.vi = vi1;
            viw.vipList = new List<Vendor_Invoice_Payment__c>();
            for(Vendor_Invoice_Payment__c vipay : viw.vipList){
                vipay = vip;
            }
        }
        //apc.generateChecks();
        for(VendorCheckRunService.VendorInvoiceWrapper viw1 : apc.viwHoldMap.values()){
            viw1.selected = true;
            viw1.vi = vi1;
            viw1.vipList = new List<Vendor_Invoice_Payment__c>();
            viw1.vipList.add(vip);
        }
        //apc.generateChecks();
        apc.filterInvoices();
        //apc.setOperatingChecksForLocation();
        List<VendorCheckRunService.VendorInvoiceWrapper> nonPostedInv = apc.getNotPostedInvoices();
        List<VendorCheckRunService.VendorInvoiceWrapper> postedInv = apc.getPostedInvoices();
        //apc.checkAmountToWords(50);
        NumberToWordConversion nwcObj = new NumberToWordConversion();
        nwcObj.getNumberToWordConversion(50);
        VendorCheckRunService.remotingSaveRequest rsr = new VendorCheckRunService.remotingSaveRequest();
        rsr.selected = true;
        rsr.vid = v.id;
        rsr.invId = vi.Id;
        rsr.amtToPay = 600;
        List<VendorCheckRunService.remotingSaveRequest> checkList = new List<VendorCheckRunService.remotingSaveRequest>();
        checkList.add(rsr);
        VendorCheckRunController.testPreviewCheckRA(checkList,true,fa.Id,System.today(),'New Description',1,true);
        apc.errorLevel = '';
        apc.messageName = 'List<remotingReturnResponse> rRRLst = new List<remotingReturnResponse>();';
        apc.messageName += 'remotingReturnResponse rrr = new remotingReturnResponse;rrr.severityCode=\'Warning\';rRRLst.add(rrr);';
        json.serialize(apc.messageName);
        apc.cancelBatch();
        //apc.getPrintCheckListPreview();
        try{
        apc.showMessage();
        }catch(exception e){}
        Test.StopTest();
    }
    /*
    @Name : vendorCheckRunControllerTest2
    @Description : Test method for VendorCheckRunController
   
    static testmethod void vendorCheckRunControllerTest2() {
        Financial_Account__c fa = new Financial_Account__c(A_P_Trade__c=true,Name='Test',Account_Number__c='asd32sd',Balance_Sheet_Type__c='Current Assets',
                Balance_Sheet_Sub_Type__c='Accounts Receivables',Category__c='Assets',Type__c='Food',
                Statement_of_Activities_Type__c='Operating Expenses',Operating_Checks__c = true,Statement_of_Activities_Sub_Type__c='Food');
        insert fa;
        Vendor_Invoice_Check_Batch__c vicb = new Vendor_Invoice_Check_Batch__c();
        insert vicb;
        Check_Run__c cr = new Check_Run__c(Printed_Check_Digits__c = 8,Next_Check_Number__c=0);
        insert cr;
        ApexPages.StandardController sc = new ApexPages.StandardController(vicb);
        VendorCheckRunController apc = new VendorCheckRunController(sc);
        
        Account account=TxnTestUtility.createAccount(AccountMemberId);
        Contact v=TxnTestUtility.createMember(account,'Primary',VendorRecordType);
        Vendor_Invoice_Check__c vicc = new Vendor_Invoice_Check__c(Amount__c = 300,Vendor__c = account.id,Check_Number__c = '63251478',
                Vendor_Invoice_Check_Batch__c = vicb.Id,Memo__c = 'New Memo',Total_Amount__c = '500',Check_Date__c = Date.Today());
        insert vicc;
        
        Vendor_Invoice__c vi = new Vendor_Invoice__c(Payment_Financial_Account__c = fa.Id,Vendor_Invoice_Check__c = vicc.Id,Due_Date__c = Date.today(),Invoice_Date__c= Date.today(),Hold_Status__c = false,Vendor__c=account.id,Invoice_Number__c=string.valueOf(jj++), Amount__c=500);
        insert vi;
        
        Financial_Account__c viacc=TxnTestUtility.createFinancialAccount('test1');
        Vendor_Invoice_Line__c vil = new Vendor_Invoice_Line__c(Payment_Type__c = 'Check',Financial_Account__c=viacc.id,Vendor_Invoice__c = vi.Id, Amount__c=500);
        insert vil;
        Vendor_Invoice_Payment__c vip = new Vendor_Invoice_Payment__c(Amount_Paid__c = 1,Vendor_Invoice__c = vi.Id, Vendor_Invoice_Line__c=vil.Id);
        insert vip;
        Vendor_Invoice__c vi1 = new Vendor_Invoice__c(Due_Date__c = Date.today(),Invoice_Date__c= Date.today(),Vendor__c=account.id,Invoice_Number__c=string.valueOf(jj++), Amount__c=500, Hold_Status__c = true);
        insert vi1;
        Vendor_Invoice_Line__c vil1 = new Vendor_Invoice_Line__c(Vendor_Invoice__c = vi1.Id,Financial_Account__c=viacc.id, Amount__c=500);
        insert vil1;
        Vendor_Invoice_Payment__c vip1 = new Vendor_Invoice_Payment__c(Amount_Paid__c = 1,Vendor_Invoice__c = vi1.Id, Vendor_Invoice_Line__c=vil1.Id);
        insert vip1;
       // Financial_Closing__c fc = new Financial_Closing__c(Year__c=Date.today
         //                                                  ().year()+'-'+Date.today().addYears(1).year(), Month__c=Date.today().Month()+'');
        Test.StartTest();
        apc.loadPostedInvoices();
        apc.loadNotPostedInvoices();
        apc.selectedVendor = account.id;
        apc.selectAllVendor();
        apc.selectAll = true;
        apc.selectAll();
        apc.checkClosedMonth(Date.today());
        apc.locationSelection = vi;
        apc.checkBatchDate();
        apc.getOperatingChecksFA();
        apc.loadPostedInvoices();
        //apc.generateChecks();
        apc.filterInvoices();
        List<VendorCheckRunService.VendorInvoiceWrapper> nonPostedInv = apc.getNotPostedInvoices();
        List<VendorCheckRunService.VendorInvoiceWrapper> postedInv = apc.getPostedInvoices();
        //apc.getprintCheckList();
        apc.vicPreviewMap.put(account.id,vicc);
        List<Vendor_Invoice_Payment__c> viplst = new List<Vendor_Invoice_Payment__c>();
        viplst.add(vip);
        apc.vipPreviewMap.put(account.id,viplst);
        apc.getprintCheckList();
        apc.selectInvoice();
        for(VendorCheckRunService.VendorInvoiceWrapper viw1 : apc.viwHoldMap.values()){
            viw1.selected = true;
            viw1.vi = vi1;
        }
        for(VendorCheckRunService.VendorInvoiceWrapper viw : apc.viwMap.values()){
            viw.vendor = account.id;    
        }
        try{
        //apc.generateChecks();
        }catch(exception e){}
        fa.Operating_Checks__c =true;
        //update fa;
        try{
        delete fa;
        }catch(exception e){}
        Test.StopTest();
    }
    /*
    @Name : vendorCheckRunControllerTest3
    @Description : Test method
    */
    static testmethod void vendorCheckRunControllerTest3() {
        Financial_Account__c fa = new Financial_Account__c(Name='Test',Account_Number__c='asd32sd',Category__c='Liability');
        insert fa;
        Default_Account__c da =new Default_Account__c (Default_Type_Name__c ='Accounts Payable',Financial_Account__c = fa.Id);
        insert da;
        Vendor_Invoice_Check_Batch__c vicb = new Vendor_Invoice_Check_Batch__c();
        insert vicb;
        Check_Run__c cr = new Check_Run__c(Printed_Check_Digits__c = 8,Next_Check_Number__c='0');
        insert cr;
        
         check_PDF_Spacing__c cp=new check_PDF_Spacing__c();
        cp.amount_in_words_top__c=0;
        cp.Name='section2';
        insert cp;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(vicb);
        VendorCheckRunController apc = new VendorCheckRunController(sc);
        //Location__c l = new Location__c();
        //insert l;

        Account account=TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account'));
        //Contact v=TxnTestUtility.createMember(account,'Primary',VendorRecordType);
        Vendor_Invoice_Check__c vicc = new Vendor_Invoice_Check__c(Amount__c = 300,Vendor__c = account.id,Check_Number__c = '63251478',
                Vendor_Invoice_Check_Batch__c = vicb.Id,Memo__c = 'New Memo',Check_Date__c = Date.Today());
        insert vicc;
        
        Vendor_Invoice__c vi = new Vendor_Invoice__c(Invoice_Date__c= Date.today(),Vendor_Invoice_Check__c = vicc.Id,Due_Date__c = Date.today(),Hold_Status__c = false,Vendor__c=account.id,Invoice_Number__c=string.valueOf(jj++), Amount__c=500);
        insert vi;
         Financial_Account__c viacc=TxnTestUtility.createFinancialAccount('test1');
        Vendor_Invoice_Line__c vil = new Vendor_Invoice_Line__c(Payment_Type__c = 'Check',Financial_Account__c=viacc.id,Vendor_Invoice__c = vi.Id, Amount__c=500);
        insert vil;
        Vendor_Invoice_Payment__c vip = new Vendor_Invoice_Payment__c(Amount_Paid__c = 5,Vendor_Invoice__c = vi.Id, Vendor_Invoice_Line__c=vil.Id);
        insert vip;
        
        Vendor_Invoice__c vi1 = new Vendor_Invoice__c(Due_Date__c = Date.today(),Invoice_Date__c= Date.today(),Vendor__c=account.id,Invoice_Number__c=string.valueOf(jj++), Amount__c=500,  Hold_Status__c = true);
        Vendor_Invoice__c vi2 = new Vendor_Invoice__c(Due_Date__c = System.Today(),Invoice_Date__c= Date.today(),Vendor__c=account.id,Invoice_Number__c=string.valueOf(jj++), Amount__c=500,  Hold_Status__c = false);
        insert new List<Vendor_Invoice__c>{vi1,vi2};
        Vendor_Invoice_Line__c vil1 = new Vendor_Invoice_Line__c(Vendor_Invoice__c = vi1.Id,Financial_Account__c=viacc.id, Amount__c=500);
        insert vil1;
        Vendor_Invoice_Payment__c vip1 = new Vendor_Invoice_Payment__c(Vendor_Invoice__c = vi1.Id,Amount_Paid__c = 5,Vendor_Invoice_Line__c=vil1.Id);
        Vendor_Invoice_Payment__c vip2 = new Vendor_Invoice_Payment__c(Vendor_Invoice__c = vi2.Id,Amount_Paid__c = 5,
                                    Vendor_Invoice_Line__c=vil1.Id);
        insert new List<Vendor_Invoice_Payment__c>{vip1,vip2};
        
       // Financial_Closing__c fc = new Financial_Closing__c(Year__c=Date.today
         //                                                  ().year()+'-'+Date.today().addYears(1).year(), Month__c=Date.today().Month()+'');
        Test.StartTest();
        apc.loadPostedInvoices();
        apc.loadNotPostedInvoices();
        apc.selectedVendor = account.Id;
        apc.selectAllVendor();
        apc.selectAll = true;
        apc.selectAll();
        apc.checkClosedMonth(Date.today());
        apc.locationSelection = vil;
        apc.checkBatchDate();
        apc.getOperatingChecksFA();
        apc.cPurchaseCategory.Purchase_Category__c = 'Food';
        apc.loadPostedInvoices();
        for(VendorCheckRunService.VendorInvoiceWrapper viw : apc.viwHoldMap.values()){
            viw.selected = true;
            viw.vi = vi1;
            viw.vipList = new List<Vendor_Invoice_Payment__c>();
            viw.vipList.add(vip);
        }
        for(VendorCheckRunService.VendorInvoiceWrapper viw1 : apc.viwMap.values()){
            viw1.selected = true;
            viw1.vi = vi1;
            viw1.vipList = new List<Vendor_Invoice_Payment__c>();
            viw1.vipList.add(vip);
        }
        apc.reCalcTotal();
        try{
        //apc.generateChecks();
        }catch(exception e){}
        apc.filterInvoices();
        List<VendorCheckRunService.VendorInvoiceWrapper> nonPostedInv = apc.getNotPostedInvoices();
        List<VendorCheckRunService.VendorInvoiceWrapper> postedInv = apc.getPostedInvoices();
        ApexPages.currentPage().getparameters().put('bid',vicb.Id);
        apc.getprintCheckList();
        apc.selectInvoice();
        apc.selectAllOnHold = 'true';
        apc.selectAll();
        apc.selectAllOnHold = 'false';
        apc.selectAll();
        apc.selectAllVendor();
        //apc.previewChecks();
        new VendorCheckRunService.FinancialJournalLineWrapper('test','6325466655');
        VendorCheckRunController.loadPostedInvoicesRA(System.today(),'Miscellaneous');
        //getPrintCheckListPreview();
        Test.StopTest();

    }
}