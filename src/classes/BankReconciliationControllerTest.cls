/*
@Name            : BankReconciliationController
@Author          : joshi
@Date            : 07 26 2017
@Description     : Controller for Bank Rec Page
*/
@isTest
private class BankReconciliationControllerTest
{
	
    /*
    @Name : bankReconciliationControllerTest1
    @Description : Test method for C62BankReconciliationController
    */
    static testmethod void selectBankAccountAndBanktatement(){
      
        Financial_Account__c fa = TestHandler.getFinancialAccount();
        fa.A_P_Trade__c=false;
        fa.Bank_Account__c=true;
        update fa;

        Bank_Statement__c bstmnt = new Bank_Statement__c(Date__c = System.Today(),End_Balance__c = 50,Financial_Account__c = fa.Id,
        GL_Balance__c = 40,Statement_Balance__c = 60);
        insert bstmnt;

        Test.StartTest();
        //Financial account selection and bank statement selection.       
        ApexPages.StandardController sc = new ApexPages.StandardController(bstmnt);
        BankReconciliationController brc = new BankReconciliationController(sc);
        brc.getFASOs();
        brc.selectedFA = fa.Id;
        brc.getBSSOs();
        brc.selectedBST = bstmnt.Id;
        brc.searchStatement();
        brc.changeFAStat();
        system.assertEquals(1,brc.faMap.size());        
        brc.changeStatement(); 

        Test.stopTest();

    }

     static testmethod void searchTransactionsAndCheck(){
      
      	Date stDate=system.Today();
		Integer day=stDate.day();
		if(day<5)
		{
			stDate=stDate.addDays(5);
		}	
			
        Financial_Account__c fa = TestHandler.getFinancialAccount();
        fa.A_P_Trade__c=false;
        fa.Bank_Account__c=true;
        update fa;

        Bank_Statement__c bstmnt = new Bank_Statement__c(Date__c = System.Today().addMonths(-1),End_Balance__c = 50,Financial_Account__c = fa.Id,
        GL_Balance__c = 40,Statement_Balance__c = 60);
        insert bstmnt;

        //Create financial journal entries
        Financial_Journal_Line__c fjl = new Financial_Journal_Line__c();              
        fjl.Post_Date__c = System.Today();
        fjl.Transaction_Date__c = stDate.addDays(-1);
        fjl.Description__c = 'New Financial';
        fjl.Amount__c = 10.00;
        fjl.Transaction_Date__c = stDate.addDays(-1);
        fjl.Financial_Account__c = fa.Id;
        fjl.Income_Journal__c = true;
        fjl.Year_Closing__c = false;
        fjl.Posted__c =True;
        fjl.Manual_Journal__c =true;
        insert fjl;

        Financial_Journal_Line__c fjl1 = new Financial_Journal_Line__c();              
        fjl1.Post_Date__c = stDate.addDays(-2);
        fjl1.Transaction_Date__c = stDate.addDays(-2);
        fjl1.Description__c = 'New Financial';
        fjl1.Amount__c = 10.00;       
        fjl1.Financial_Account__c = fa.Id;
        fjl1.Income_Journal__c = true;
        fjl1.Year_Closing__c = false;
        fjl1.Posted__c =True;
        fjl1.Manual_Journal__c =true;
        insert fjl1;

        Financial_Journal_Line__c fjl2 = new Financial_Journal_Line__c();              
        fjl2.Post_Date__c = stDate.addDays(-3);
        fjl2.Transaction_Date__c = stDate.addDays(-3);
        fjl2.Description__c = 'New Financial';
        fjl2.Amount__c = 10.00;       
        fjl2.Financial_Account__c = fa.Id;
        fjl2.Income_Journal__c = true;
        fjl2.Year_Closing__c = false;
        fjl2.Posted__c =True;
        fjl2.Manual_Journal__c =true;
        insert fjl2;

	    Financial_Journal_Line__c fjl3 = new Financial_Journal_Line__c();              
        fjl3.Post_Date__c = stDate.addDays(-2);
        fjl3.Transaction_Date__c = stDate.addDays(-2);
        fjl3.Description__c = 'New Financial';
        fjl3.Amount__c = -10.00;       
        fjl3.Financial_Account__c = fa.Id;
        fjl3.Income_Journal__c = true;
        fjl3.Year_Closing__c = false;
        fjl3.Posted__c =True;
        fjl3.Manual_Journal__c =true;
        insert fjl3;       

        Financial_Journal_Line__c fjl4 = new Financial_Journal_Line__c();              
        fjl4.Post_Date__c = stDate.addDays(-3);
        fjl4.Transaction_Date__c = stDate.addDays(-3);
        fjl4.Description__c = 'New Financial';
        fjl4.Amount__c = -10.00;       
        fjl4.Financial_Account__c = fa.Id;
        fjl4.Income_Journal__c = true;
        fjl4.Year_Closing__c = false;
        fjl4.Posted__c =True;
        fjl4.Manual_Journal__c =true;
        insert fjl4;         

        //Create vendor invoice check batch.
        Vendor_Invoice_Check_Batch__c vcb =new Vendor_Invoice_Check_Batch__c();
        vcb.Cash_Financial_Journal_Line__c=fjl.Id;
        vcb.Batch_Date__c=System.Today();
        vcb.Description__c='Test bank Bank Reconciliation';
        insert vcb;

        Vendor_Invoice_Check__c vic=new Vendor_Invoice_Check__c();
        vic.Vendor__c=	TestHandler.getAccount('Vendor').id;
        vic.Amount__c=500;
        vic.Check_Number__c='0000999';
        vic.Check_Date__c=System.Today();
        vic.Vendor_Invoice_Check_Batch__c=vcb.id;
        insert vic;

        Test.StartTest();         
        ApexPages.StandardController sc = new ApexPages.StandardController(bstmnt);
        BankReconciliationController brc = new BankReconciliationController(sc);

        brc.getFASOs();
        brc.selectedFA = fa.Id;
        brc.getBSSOs();      
        brc.searchStatement();       

        brc.bankStat.Date__c = stDate.addDays(-4);
        brc.bankStat.End_Balance__c = 50;
        brc.bankStat.GL_Balance__c = 40;
        brc.bankStat.Statement_Balance__c = 60;       
        brc.saveStatement();          
        brc.searchTransactions();     
		System.assertEquals(2,[SELECT COUNT() FROM Bank_Statement__c]);  

		//Add and deduct cash manually
		brc.addManAddEntry();
		brc.addManDeductEntry();
		
		brc.addRemIndex=1;
		brc.deductRemIndex=1;	

		brc.remManAddEntry();
		brc.remManDeductEntry();

		BankReconciliationController.FinancialJournalWrapper addEntry=brc.manFJWMapAdd.get(0);
		addEntry.fj.Transaction_Date__c=stDate;	
		addEntry.fj.Description__c='Add Credit Cash';	
		addEntry.fj.Amount__c=10;	
		addEntry.fj.Financial_Account__c=fa.Id;	
		brc.manFJWMapAdd.put(0,addEntry);

		BankReconciliationController.FinancialJournalWrapper deductEntry=brc.manFJWMapDeduct.get(0);
		deductEntry.fj.Transaction_Date__c=stDate;	
		deductEntry.fj.Description__c='Deduct Credit Cash';	
		deductEntry.fj.Amount__c=10;	
		deductEntry.fj.Financial_Account__c=fa.Id;	
		brc.manFJWMapDeduct.put(0,deductEntry);

		brc.save();
		brc.postBRJL();	
        Test.StopTest();

    }    
}