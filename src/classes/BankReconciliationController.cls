/*
@Name            : BankReconciliationController
@Author          : joshi
@Date            : 07 18 2017
@Description     : Controller for Bank Rec Page
*/
public with sharing class BankReconciliationController {

	//Financial account map containing all the bank account filled in loadFinancialAccounts method
	public Map<Id, Financial_Account__c> faMap {get; set;}

	//map to store fetched financial account after sorting based on the finacial account number.
	public Map<String, SelectOption> faSOMap {get; set;}

	//Map to hold retived bank-statement for selected financial account as a select option with index.
	public Map<String, SelectOption> bsSOMap {get; set;}

	//Select financial account for bank reconcilation statement.
	public String selectedFA {get; set;}

	//Store selected bank statement name for edit and creating new bank statement.
	public String selectedBST {get; set;}

	//Boolean flag variable in order to manage enable and disable component in bank statement section.
	public Boolean workingBankRec {get; set;}

	//Boolean flag variable in order to manage enable and disable component in create and update bank statement section.
	public Boolean workingBankStat {get; set;}

	//List of financial wrapper to fetch all the financial journal lines for selected bank account and display on the vf as page-bloack table.
	public List<FinancialJournalWrapper> fjwList {get; set;}

	//List of financial wrapper to fetch all the vendor check for selected bank account and display on the vf as page-bloack table.
	public List<FinancialJournalWrapper> vicList {get; set;}

	//Map to hold all the reconcilation journal line for adding amount manually to bank account.
	public Map<Integer, FinancialJournalWrapper> manFJWMapDeduct {get; set;}

	//Map to hold all the reconcilation journal line for deducting amount manually to bank account.
	public Map<Integer, FinancialJournalWrapper> manFJWMapAdd {get; set;}

	//Map to store associate existing bank account id with genereted index for select option.
	public Map<String, Id> bsSOIndexToId {get; set;}

	//Map to show financial journal entries per bank for deduction
	public List<FinancialJournalWrapper> fjwListBSDeduct {get; set;}

	//Map to show financial journal entries per bank for aadition
	public List<FinancialJournalWrapper> fjwListBSAdd {get; set;}

	//List holding all the journals to delete when the save bbutton is clicked in bank per /GL section.
	public List<Financial_Journal_Line__c> journalsToDelete {get; set;}

	//Global counter for add amount manually to the bank financial account.
	public Integer addIndex {get; set;}

	//Global counter for deduct amount manually to the bank financial account.
	public Integer deductIndex {get; set;}

	//Assign the Id for deleing the row from add cash entry section.
	public Integer addRemIndex {get; set;}

	//Assign the Id for deleing the row from deduct entry section.
	public Integer deductRemIndex {get; set;}

	//Bank statement object to store the statement details for creating new statement or updating the existing statement.
	public Bank_Statement__c bankStat {get; set;}

	//Total dabit amnount for financial journal line to display total for dabit down to the debit column in page-block table.
	public Decimal FJDebitTotal {get; set;}

	//Total credit amnount for financial journal line to display total for credit down to the credit column in page-block table.
	public Decimal FJCreditTotal {get; set;}

	//Total amount of generated check for vendors in selected bank account.
	public Decimal FJCreditCheckTotal {get; set;}

	//Store outstanding check balance and for unselected checks.
	public Decimal checkedOffChecksBal {get; set;}

	//Total addition amount in check or other table which is not selected
	public Decimal bsAddTotal {get; set;}

	//Total deduction amount  in check or other table which is not selected
	public Decimal bsDeductTotal {get; set;}

	//Total cash added to this bank account manually
	public Decimal addTotal {get; set;}

	//Total cash deducted from selected bank account manually
	public Decimal deductTotal {get; set;}

	//Calculate the bank variance and store the values to show on the VF
	public Decimal cBankRecVariance {get; set;}

	//Flag to manage rendering while working in add and deduct amount section.
	public Boolean workingAddDeduct {get; set;}

	/**
	*@description: Standard controller initialization of reources with default values.
	**/

	public BankReconciliationController(ApexPages.StandardController stdController) {
		fjwList = new List<FinancialJournalWrapper>();
		vicList = new List<FinancialJournalWrapper>();
		fjwListBSAdd = new List<FinancialJournalWrapper>();
		fjwListBSDeduct = new List<FinancialJournalWrapper>();
		manFJWMapDeduct = new Map<Integer, FinancialJournalWrapper>();
		manFJWMapAdd = new Map<Integer, FinancialJournalWrapper>();

		faSOMap = new Map<String, SelectOption>();
		bsSOMap = new Map<String, SelectOption>();
		bsSOIndexToId = new Map<String, Id>();
		journalsToDelete = new List<Financial_Journal_Line__c>();

		loadFinancialAccounts();
		generateFASO();
		workingBankRec = false;
		workingBankStat = false;
		workingAddDeduct = false;

	}

	/**
	*@description: Retrieve all "Bank" Financial Accounts and all generated bank-statement for this account.
	**/
	public void loadFinancialAccounts() {
		faMap = new Map<Id, Financial_Account__c>((List<Financial_Account__c>)Data.read(
		            'Select id, Name, Account_Number__c, Debit_Credit__c, (Select Id, Name, Date__c, End_Balance__c, Financial_Account__c, GL_Balance__c, Statement_Balance__c from Bank_Statements__r ORDER BY Date__c DESC) from Financial_Account__c Where Bank_Account__c =: isBankAccount',
		new Map<String, Object> {
			'isBankAccount' => true
		}));
	}

	/**
	*@description: Create select option for financial account and sort the finacial account in ascending order.
	**/
	public void generateFASO() {
		faSOMap.clear();
		bsSOMap.clear();
		faSOMap.put('', new SelectOption('', '--None--'));
		bsSOMap.put('', new SelectOption('', '--Create New Statement--'));

		Map<String, Id> faSortMap = new Map<String, Id>();
		for (Financial_Account__c fa : faMap.values()) {
			faSortMap.put(fa.Account_Number__c + ' - ' + fa.Name, fa.Id);
		}

		List<String> faSortKeys = new List<String>(faSortMap.keySet());
		faSortKeys.sort();
		for (String fa : faSortKeys) {
			faSOMap.put(faSortMap.get(fa), new SelectOption(faSortMap.get(fa) + '', fa));
		}
		selectedFA = '';
		selectedBST = '';
	}

	//Return fetched financial account as select option which has marked as bank account.
	public List<SelectOption> getFASOs() {
		return faSOMap.values();
	}

	//Retuen all the existing bank statement for selected financial account.
	public List<SelectOption> getBSSOs() {
		selectedBST = '';
		bsSOIndexToId.clear();
		if (selectedFA != '') {
			bsSOMap.clear();
			bsSOMap.put('', new SelectOption('', '--Create New Statement--'));
			Integer i = 0;
			for (Bank_Statement__c bst : faMap.get(selectedFA).Bank_Statements__r) {
				//Change Date to Month/Year
				DateTime dt = Datetime.newInstance(bst.Date__c, Time.newInstance(0, 0, 0, 0));
				//Format Approprietly
				String dtFormat = dt.format('yyyy/MM');
				bsSOMap.put(i + '', new SelectOption(i + '', dtFormat));
				bsSOIndexToId.put(i + '', bst.id);
				i--;
			}
			return bsSOMap.values();
		} else {
			return new List<SelectOption>();
		}
	}

	//Recalculate the total debit and credit for reconcialiation journal line added manually.
	public void regenerateManualTotals() {
		addTotal = 0.00;
		deductTotal = 0.00;

		for (FinancialJournalWrapper fjw : manFJWMapAdd.values()) {
			if (fjw.fj.Amount__c != null)
				addTotal += fjw.fj.Amount__c;
		}
		for (FinancialJournalWrapper fjw : manFJWMapDeduct.values()) {
			if (fjw.fj.Amount__c != null)
				deductTotal += fjw.fj.Amount__c;
		}
	}

	/**
	*@description: Assign selected bank statement to update from the bank statement map. or create a new bank statement object.
	**/
	public void searchStatement() {
		workingBankRec = true;
		bankStat = null;

		if (selectedBST != null && selectedBST != '' && selectedFA != '') {
			Id selectedBSTId = bsSOIndexToId.get(selectedBST);
			for (Bank_Statement__c bankS : faMap.get(selectedFA).Bank_Statements__r) {
				if (selectedBSTId == bankS.id) {
					bankStat = bankS;
					break;
				}
			}
		} else if (selectedFA != '') {
			bankStat = new Bank_Statement__c();
			bankStat.Financial_Account__c = selectedFA;

		}
	}

	/**
	*@description : calculate the current-Gl balance. (Total debit-Total credit) for selected financial account.
	*@param : financial account id for calculating the balance.
	**/
	public Decimal calcDebCred(String faId) {

		List<AggregateResult> agresult = (List<AggregateResult>)Data.read(
		                                     'Select Sum(Debit__c), sum(Credit__c) from Financial_Journal_Line__c where Posted__c =: isPosted ' +
		                                     'and Financial_Summary__c =: financialSummary and Transaction_Date__c<=:statementDate and Financial_Account__c =:financialAccount and (not (Bank_Reconciliation_Journal__c=: isBankReconciliation and Bank_Statement__c=:bankStatement)) group by Financial_Account__c',
		new Map<String, Object> {
			'isPosted' => true,
			'financialSummary' => null,
			'statementDate' => bankStat.Date__c,
			'financialAccount' => faId,
			'isBankReconciliation' => true,
			'bankStatement' => bankStat.Id
		});

		Decimal deb = 0;
		Decimal cred = 0;
		Decimal totDeb = 0;
		Decimal totCred = 0;
		for (AggregateResult ar : agresult) {
			deb = (Decimal)ar.get('expr0');
			cred = (Decimal)ar.get('expr1');
		}

		if (deb != null) {
			totDeb = deb;
		}
		if (cred != null) {
			totCred = cred;
		}

		agresult = (List<AggregateResult>)Data.read(
		               'Select Sum(Debit__c), sum(Credit__c) from Financial_Summary__c where Yearly_Summary__c =: yearlySummary and Date__c<=:statementDate and Financial_Account__c =:financialAccount group by Financial_Account__c',
		new Map<String, Object> {
			'yearlySummary' => false,
			'statementDate' => bankStat.Date__c,
			'financialAccount' => faId
		});

		deb = 0;
		cred = 0;
		for (AggregateResult ar : agresult) {
			deb = (Decimal)ar.get('expr0');
			cred = (Decimal)ar.get('expr1');
		}

		if (deb != null) {
			totDeb += deb;
		}
		if (cred != null) {
			totCred += cred;
		}

		return totDeb - totCred;
	}

	/**
	*@description : Search all financial journal lines and vendor invoice check attached to this bank account.
	**/
	public void searchTransactions() {
		if (selectedFA != '' && bankStat.Date__c != null && bankStat.Statement_Balance__c != null) {
			Decimal currentGLBalance = calcDebCred(selectedFA);

			Date sDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1);
			Date eDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1).addMonths(1).addDays(-1);

			Decimal oldGLAmount = bankStat.GL_Balance__c;
			if (oldGLAmount == null) {
				oldGLAmount = 0;
			}

			bankStat.GL_Balance__c = currentGLBalance;
			if (bankStat.id != null && oldGLAmount != bankStat.GL_Balance__c) {
				Data.modify(bankStat);
			}

			if (checkStatementExists() == false) {
				FJDebitTotal = 0.00;
				FJCreditTotal = 0.00;
				FJCreditCheckTotal = 0.00;

				manFJWMapAdd.clear();
				manFJWMapDeduct.clear();

				addIndex = 0;
				deductIndex = 0;
				workingBankStat = true;
				fjwList = new List<FinancialJournalWrapper>();
				Set<String> fjlSet = new Set<String>();
				//Fetch all the financial journal line for selected bank account upto selected statement date.
				List<Financial_Journal_Line__c> fjList = (List<Financial_Journal_Line__c>)Data.read('Select id, Name, Financial_Account__r.Debit_Credit__c, Financial_Account__r.Account_Number__c, Financial_Account__r.Name, Financial_Account__c, ' +
				        'Bank_Statement__c, Amount__c, Description__c, ' +
				        'Post_Date__c, Posted__c, Transaction_Date__c, Bank_Statement__r.Date__c ' +
				        'from Financial_Journal_Line__c ' +
				        'where Financial_Account__c = :financialAccount' +
				        ' and (Bank_Statement__c =:bankStatement1 or Bank_Statement__c = :bankStatementId or Bank_Statement__r.Date__c >= :statementDate) ' +
				        ' and Posted__c = :isPosted' +
				        ' and Check_Run__c = :isCheckRun' +
				        ' and Transaction_Date__c <= :endDate' +
				        ' and Bank_Reconciliation_Journal__c =:isReconciliation and (not (Description__c like :lineDescription or Financial_Journal_Entry__r.Description__c like :entryDescription))',

				new Map<string, Object> {
					'financialAccount' => selectedFA,
					'bankStatement1' => null,
					'bankStatementId' => bankStat.Id,
					'statementDate' => bankStat.Date__c,
					'isPosted' => true,
					'isCheckRun' => false,
					'endDate' => eDate,
					'isReconciliation' => false,
					'lineDescription' => 'Invoice Check Batch VICB-%',
					'entryDescription' => '%Check Void'
				});

				for (Financial_Journal_Line__c fj : fjList) {
					fjlSet.add(fj.Id);
				}

				//Fetch all the generated vendor check for selected financial account.
				List<Vendor_Invoice_Check__c> vicLst = (List<Vendor_Invoice_Check__c>)Data.read('Select Id, Name, Void__c, Bank_Statement__r.Date__c, Amount__c,' +
				                                       ' Check_Date__c, Check_Number__c, Vendor__c, Vendor__r.Name,' +
				                                       ' Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c,' +
				                                       ' Bank_Statement__c' +
				                                       ' From Vendor_Invoice_Check__c' +
				                                       ' Where Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__r.Financial_Account__c = :financialAccount' +
				                                       ' and Check_Date__c <= :endDate and (Void__c =:isVoidedT or' +
				                                       ' (Void__c =:isVoided and Voided_Financial_Journal_Entry__r.Entry_Date__c > :statementDate1))' +
				                                       ' and (Bank_Statement__c =:bankStatement1 or Bank_Statement__c = :bankStatementId or Bank_Statement__r.Date__c >= :statementDate)',
				new Map<string, Object> {
					'financialAccount' => selectedFA,
					'endDate' => eDate,
					'isVoidedT' => false,
					'isVoided' => true,
					'statementDate1' => bankStat.Date__c,
					'bankStatement1' => null,
					'bankStatementId' => bankStat.Id,
					'statementDate' => bankStat.Date__c
				});
				vicList.clear();

				Set<Id> fjlTiedToCheck = new Set<Id>();
				//Fetch all the vendor check having cash account matching to the finacial jounal line fetched from above.
				List<Vendor_Invoice_Check__c> vicLstFJLCompare = (List<Vendor_Invoice_Check__c>)Data.read('Select id, Void__c, Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c' +
				        ' from Vendor_Invoice_Check__c where Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c in :fjlSet' +
				        ' and (Void__c =:isVoidedT or (Void__c = :isVoided and Voided_Financial_Journal_Entry__r.Entry_Date__c > :statementDate))',
				new Map<string, Object> {
					'fjlSet' => fjlSet,
					'isVoidedT' => false,
					'isVoided' => true,
					'statementDate' => bankStat.Date__c
				});

				for (Vendor_Invoice_Check__c vicCompare : vicLstFJLCompare) {
					if (vicCompare.Vendor_Invoice_Check_Batch__r != null && vicCompare.Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c != null) {
						fjlTiedToCheck.add(vicCompare.Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c);
					}
				}

				Map<String, Integer> vicMap = new Map<String, Integer>();
				for (Vendor_Invoice_Check__c vic : vicLst) {
					if (vic.Bank_Statement__c == null || vic.Bank_Statement__c == bankStat.Id || vic.Bank_Statement__r.Date__c >= bankStat.Date__c) {
						FinancialJournalWrapper fjwTemp = new FinancialJournalWrapper(vic, false);
						if ((vic.Bank_Statement__r.Date__c >= bankStat.Date__c && vic.Bank_Statement__c != null && vic.Bank_Statement__c != bankStat.Id) || vic.Void__c == true) {
							fjwTemp.disabled = true;
							fjwTemp.selected = false;
						}

						vicList.add(fjwTemp);
						FJCreditCheckTotal += Math.abs(vic.Amount__c);
					}

					if (vic.Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c != null) {
						if (!vicMap.containsKey(vic.Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c)) {
							vicMap.put(vic.Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c, 0);
						}
						vicMap.put(vic.Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c, vicMap.get(vic.Vendor_Invoice_Check_Batch__r.Cash_Financial_Journal_Line__c) + 1);
					}
				}

				/*Iterate through all the financial journal lines for selected bank account and discard all the
				  journal line which is tied to vendor check.
				*/
				for (Financial_Journal_Line__c fj : fjList) {
					if (!vicMap.containsKey(fj.id) && !fjlTiedToCheck.contains(fj.Id)) {
						FinancialJournalWrapper fjwTemp = new FinancialJournalWrapper(fj);
						if (fj.Bank_Statement__r.Date__c >= bankStat.Date__c && fj.Bank_Statement__c != null && fj.Bank_Statement__c != bankStat.Id) {
							fjwTemp.disabled = true;
							fjwTemp.selected = false;
						}

						fjwList.add(fjwTemp);
						if ((fj.Amount__c > 0 && fj.Financial_Account__r.Debit_Credit__c == 'Debit') || fj.Amount__c < 0 && fj.Financial_Account__r.Debit_Credit__c == 'Credit') {
							FJDebitTotal += Math.abs(fj.Amount__c);
						} else {
							FJCreditTotal += Math.abs(fj.Amount__c);
						}
					}
				}

				//Sort financial journal wrapper based onn the transaction date to show it in asc order.
				for (Integer k = 0; k < fjwList.size() - 1; k++) {
					for (Integer j = k + 1; j < fjwList.size(); j++) {
						if (fjwList.get(j).fj.Transaction_Date__c < fjwList.get(k).fj.Transaction_Date__c) {
							FinancialJournalWrapper rp = fjwList.get(k);
							fjwList.set(k, fjwList.get(j));
							fjwList.set(j, rp);
						}
					}
				}

				//Load the manual entries made for this
				if (bankStat.id != null) {
					//Fetch all the reconcilation financial journal lines.
					List<Financial_Journal_Line__c> fjlReconciliationJournal = (List<Financial_Journal_Line__c>)Data.read('Select id, Name, Financial_Account__r.Account_Number__c,' +
					        ' Financial_Account__r.Name, Financial_Account__r.Debit_Credit__c, Financial_Account__c,' +
					        ' Bank_Statement__c, Credit__c, Amount__c, Description__c, Post_Date__c, Posted__c, Transaction_Date__c' +
					        ' from Financial_Journal_Line__c where Bank_Statement__c = :bankStatementId and' +
					        ' Check_Run__c = :isCheckRun and Bank_Reconciliation_Journal__c = :isReconciliation and' +
					        ' Manual_Journal__c =:isManual ORDER BY Transaction_Date__c',
					new Map<string, Object> {
						'bankStatementId' => BankStat.id,
						'isCheckRun' => false,
						'isReconciliation' => true,
						'isManual' => false
					});

					for (Financial_Journal_Line__c fj : fjlReconciliationJournal) {
						if(fj.Amount__c <0){
								fj.Amount__c = fj.Amount__c *-1;
							}
							
						if (fj.Credit__c!=null && fj.Credit__c!=0) {
							FinancialJournalWrapper fjw = new FinancialJournalWrapper(addIndex, fj);						
							manFJWMapAdd.put(addIndex, fjw);							
							addIndex++;
						} else {
							manFJWMapDeduct.put(deductIndex, new FinancialJournalWrapper(deductIndex, fj));
							deductIndex++;
						}
					}
				}

				addManAddEntry();
				addManDeductEntry();
				regenerateManualTotals();
			} else {
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'A Bank Statement for this time period already exists'));
			}
		}
		addDeduct();
	}

	/**
	*@description : Filter all the unselected financil journal lines to for debit and credit.
	*and sort it based on the transaction date to show it in related add or deduct section.
	**/
	public void addDeduct() {
		workingAddDeduct = true;
		fjwListBSAdd.clear();
		fjwListBSDeduct.clear();
		bsAddTotal = 0.00;
		bsDeductTotal = 0.00;
		checkedOffChecksBal = 0.00;

		//Fiiter deduct and add entry from the other table
		for (FinancialJournalWrapper fjw : fjwList) {
			if (fjw.selected != true) {
				if (fjw.fj.Amount__c > 0) {
					fjwListBSAdd.add(fjw);
					bsAddTotal += fjw.fj.Amount__c;
				} else {
					fjwListBSDeduct.add(fjw);
					bsDeductTotal += (fjw.fj.Amount__c * -1);
				}
			}
		}

		//Sort add map in asc order based on the transacction date
		for (Integer k = 0; k < fjwListBSAdd.size() - 1; k++) {
			for (Integer j = k + 1; j < fjwListBSAdd.size(); j++) {
				if (fjwListBSAdd.get(j).fj.Transaction_Date__c < fjwListBSAdd.get(k).fj.Transaction_Date__c) {
					FinancialJournalWrapper rp = fjwListBSAdd.get(k);
					fjwListBSAdd.set(k, fjwList.get(j));
					fjwListBSAdd.set(j, rp);
				}
			}
		}

		//Sort deduct map in asc order based on the transacction date
		for (Integer k = 0; k < fjwListBSDeduct.size() - 1; k++) {
			for (Integer j = k + 1; j < fjwListBSDeduct.size(); j++) {
				if (fjwListBSDeduct.get(j).fj.Transaction_Date__c < fjwListBSDeduct.get(k).fj.Transaction_Date__c) {
					FinancialJournalWrapper rp = fjwListBSDeduct.get(k);
					fjwListBSDeduct.set(k, fjwList.get(j));
					fjwListBSDeduct.set(j, rp);
				}
			}
		}

		for (FinancialJournalWrapper fjw : vicList) {
			if (fjw.selected != true) {
				//bsDeductTotal-=fjw.vic.Amount__c;
				checkedOffChecksBal += fjw.vic.Amount__c;
			}
		}
	}

	/**
	*@description: Post Bank Rec Journal Lines created in the add cash and deduct cash section.
	*/
	public void postBRJL() {
		save();

		List<Financial_Journal_Line__c> fjUpdate = new List<Financial_Journal_Line__c>();
		List<Financial_Journal_Line__c> fjInsert = new List<Financial_Journal_Line__c>();		
		Integer insertI = 0;		

		Set<Id> financialAccountIds = new Set<Id>();
		for (FinancialJournalWrapper fj : manFJWMapAdd.values()) {
			financialAccountIds.add(fj.fj.Financial_Account__c);
		}

		for (FinancialJournalWrapper fj : manFJWMapDeduct.values()) {
			financialAccountIds.add(fj.fj.Financial_Account__c);
		}

		Map<Id, Financial_Account__c> financialMap = new Map<Id, Financial_Account__c>((List<Financial_Account__c>)Data.read(
		            'Select id, Debit_Credit__c from Financial_Account__c Where Id in :fids',
		new Map<String, Object> {
			'fids' => financialAccountIds
		}));

		for (FinancialJournalWrapper fj : manFJWMapAdd.values()) {
			if (fj.fj.Financial_Account__c != null && fj.fj.Amount__c != null && fj.fj.Transaction_Date__c != null && fj.fj.Posted__c != true) {				
				//Create financial journal entry.
				Financial_Journal_Entry__c fje = new Financial_Journal_Entry__c();
				fje.Entry_Date__c = bankStat.Date__c;
				fje.Posted__c = true;
			    fje.Post_Date__c = fj.fj.Transaction_Date__c;
				fje.Description__c = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy') + ' Bank Rec';
				
				Data.Create(fje);
				Decimal entryAmount = Math.abs(fj.fj.Amount__c);				
				fj.fj.Posted__c = true;
				fj.fj.Post_Date__c = fj.fj.Transaction_Date__c;
				fj.fj.Amount__c = entryAmount;
				
				if(financialMap.get(fj.fj.Financial_Account__c).Debit_Credit__c=='Debit')
				{
					fj.fj.Amount__c = entryAmount*-1;
				}

				fj.fj.Financial_Journal_Entry__c = fje.Id;
				fjUpdate.add(fj.fj);				
				Financial_Journal_Line__c fjo = new Financial_Journal_Line__c();
				fjo.Amount__c = entryAmount;
				
				if(faMap.get(selectedFA).Debit_Credit__c=='Credit')
				{
					fjo.Amount__c = entryAmount * -1;
				}				

				fjo.Description__c = fj.fj.Description__c;
				fjo.Financial_Account__c = faMap.get(selectedFA).id;
				fjo.Insert_Index__c = insertI + '';
				fjo.Post_Date__c = fj.fj.Transaction_Date__c;
				fjo.Posted__c = true;
				fjo.Transaction_Date__c = fj.fj.Transaction_Date__c;
				fjo.Bank_Statement__c = fj.fj.Bank_Statement__c;
				fjo.Manual_Journal__c = true;
				fjo.Bank_Reconciliation_Journal__c = true;				
				fjo.Financial_Journal_Entry__c = fje.id;
				fjInsert.add(fjo);
			}
		}

		for (FinancialJournalWrapper fj : manFJWMapDeduct.values()) {
			if (fj.fj.Financial_Account__c != null && fj.fj.Amount__c != null && fj.fj.Transaction_Date__c != null && fj.fj.Posted__c != true) {
				
				//Create financial journal entry.
				Financial_Journal_Entry__c fje = new Financial_Journal_Entry__c();
				fje.Entry_Date__c = bankStat.Date__c;
				fje.Posted__c = true;
			    fje.Post_Date__c = fj.fj.Transaction_Date__c;
				fje.Description__c = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy') + ' Bank Rec';				
				Data.create(fje);

				Decimal entryAmount=Math.abs(fj.fj.Amount__c);			
				fj.fj.Posted__c = true;
				fj.fj.Post_Date__c = fj.fj.Transaction_Date__c;
				fj.fj.Amount__c = entryAmount;

				if(financialMap.get(fj.fj.Financial_Account__c).Debit_Credit__c=='Credit')
				{
					fj.fj.Amount__c = entryAmount*-1;
				}

				fj.fj.Financial_Journal_Entry__c = fje.Id;
				fjUpdate.add(fj.fj);
				//Post Other side of transaction
				Financial_Journal_Line__c fjo = new Financial_Journal_Line__c();
				fjo.Amount__c = entryAmount;
				if(faMap.get(selectedFA).Debit_Credit__c=='Debit')
				{			
					fjo.Amount__c = entryAmount * -1;	
				}				
								
				fjo.Description__c = fj.fj.Description__c;
				fjo.Financial_Account__c = faMap.get(selectedFA).id;
				fjo.Insert_Index__c = insertI + '';
				fjo.Post_Date__c = fj.fj.Transaction_Date__c;
				fjo.Posted__c = true;
				fjo.Transaction_Date__c = fj.fj.Transaction_Date__c;
				fjo.Bank_Statement__c = fj.fj.Bank_Statement__c;
				fjo.Manual_Journal__c = true;
				fjo.Bank_Reconciliation_Journal__c = true;
				fjo.Financial_Journal_Entry__c = fje.Id;
				fjInsert.add(fjo);
			}
		}
		
		Data.upsurt(fjUpdate, Financial_Journal_Line__c.Id.getDescribe().getSObjectField(), new Set<String>());
		Data.create(fjInsert);

		for (FinancialJournalWrapper fjw : manFJWMapAdd.values()) {
			if (fjw.fj.Amount__c != null) {
				fjw.fj.Amount__c = Math.abs(fjw.fj.Amount__c);
			}
		}

		for (FinancialJournalWrapper fjw : manFJWMapDeduct.values()) {
			if (fjw.fj.Amount__c != null) {
				fjw.fj.Amount__c = Math.abs(fjw.fj.Amount__c);
			}
		}		
		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Bank Rec Posted Successfully!'));

	}

	//Return all the reconciliation financial journal line added for adding amount manually to selected bank account.
	public List<FinancialJournalWrapper> getAddManList() {
		return manFJWMapAdd.values();
	}

	//Return all the reconciliation financial journal line  added for deducting amount manually to selected bank account.
	public List<FinancialJournalWrapper> getDeductManList() {
		return manFJWMapDeduct.values();
	}

	/**
	*@description: Add more empty row for adding manual journal line in deduct cash section.
	**/
	public void addManAddEntry() {
		manFJWMapAdd.put(addIndex, new FinancialJournalWrapper(addIndex, faMap.get(selectedFA).id));
		addIndex++;
	}

	/**
	*@description: Remove manual entry added manually in add cash section.
	**/
	public void remManAddEntry() {
		if (addRemIndex != null) {
			if (manFJWMapAdd.get(addRemIndex).fj.id != null) {
				journalsToDelete.add(manFJWMapAdd.get(addRemIndex).fj);
			}
			manFJWMapAdd.remove(addRemIndex);
		}
	}

	/**
	*@description: Add more empty row for adding manual journal line in deduct cash section.
	**/
	public void addManDeductEntry() {
		manFJWMapDeduct.put(deductIndex, new FinancialJournalWrapper(deductIndex, faMap.get(selectedFA).id));
		deductIndex++;
	}

	/**
	*@description: Remove manual entry added manually in deduct cash section.
	**/
	public void remManDeductEntry() {
		if (deductRemIndex != null) {
			if (manFJWMapDeduct != null && manFJWMapDeduct.containsKey(deductRemIndex) && manFJWMapDeduct.get(deductRemIndex).fj != null && manFJWMapDeduct.get(deductRemIndex).fj.id != null) {
				journalsToDelete.add(manFJWMapDeduct.get(deductRemIndex).fj);
			}

			if (manFJWMapDeduct.containsKey(deductRemIndex)) {
				manFJWMapDeduct.remove(deductRemIndex);
			}
		}
	}

	/**
	*@description: 	Save transactions/Bank statement/Journal Lines.
	**/
	public void save() {

		Data.upsurt(new List<Bank_Statement__c> {bankStat}, Bank_Statement__c.Id.getDescribe().getSObjectField(), new Set<String>());
		List<Financial_Journal_Line__c> fjupdatelist = new List<Financial_Journal_Line__c>();
		List<Vendor_Invoice_Check__c> vicupdatelist = new List<Vendor_Invoice_Check__c>();

		//Fetch all the selected entry to save from other table
		for (FinancialJournalWrapper fjw : fjwList) {
			if (fjw.selected == true) {
				fjw.fj.Bank_Statement__c = bankStat.id;
				fjupdatelist.add(fjw.fj);
			} else if (fjw.disabled != true) {
				fjw.fj.Bank_Statement__c = null;
				fjupdatelist.add(fjw.fj);
			}
		}

		//Fetch all the selected check to save from check table
		if (vicList != null) {
			for (FinancialJournalWrapper fjw : vicList) {
				if (fjw.selected == true) {
					fjw.vic.Bank_Statement__c = bankStat.id;
					vicupdatelist.add(fjw.vic);
				} else if (fjw.disabled != true) {
					fjw.vic.Bank_Statement__c = null;
					vicupdatelist.add(fjw.vic);
				}
			}
		}

		Data.remove(journalsToDelete);
		journalsToDelete.clear();

		for (FinancialJournalWrapper fjw : manFJWMapAdd.values()) {
			if (fjw.fj.Financial_Account__c != null && fjw.fj.Amount__c != null && fjw.fj.Transaction_Date__c != null && fjw.fj.Posted__c!=true) {
				Date sDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1);
				Date eDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1).addMonths(1).addDays(-1);

				if (!(sDate <= fjw.fj.Transaction_Date__c && fjw.fj.Transaction_Date__c <= eDate)) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'Book Date must be within the Statement Period'));
					return;
				}

				fjw.fj.Insert_Index__c = 'Add' + fjw.index;
				fjw.fj.Bank_Statement__c = BankStat.id;
				fjw.fj.Amount__c = Math.abs(fjw.fj.Amount__c) * -1;
				fjupdatelist.add(fjw.fj);

			} else if (fjw.fj.Financial_Account__c != null && fjw.fj.Amount__c != null && fjw.fj.Transaction_Date__c == null) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'Book Date is Required for Journal Lines'));
				return;
			}

		}

		for (FinancialJournalWrapper fjw : manFJWMapDeduct.values()) {
			if (fjw.fj.Financial_Account__c != null && fjw.fj.Amount__c != null && fjw.fj.Transaction_Date__c != null && fjw.fj.Posted__c!=true) {
				Date sDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1);
				Date eDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1).addMonths(1).addDays(-1);

				if (!(sDate <= fjw.fj.Transaction_Date__c && fjw.fj.Transaction_Date__c <= eDate)) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'Book Date must be within the Statement Period'));
					return;
				}

				fjw.fj.Insert_Index__c = 'Deduct' + fjw.index;
				fjw.fj.Bank_Statement__c = BankStat.id;
				fjupdatelist.add(fjw.fj);

			} else if (fjw.fj.Financial_Account__c != null && fjw.fj.Amount__c != null && fjw.fj.Transaction_Date__c == null) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'Book Date is Required for Journal Lines'));
				return;
			}
		}

		Data.upsurt(vicupdatelist, Vendor_Invoice_Check__c.Id.getDescribe().getSObjectField(), new Set<String>());
		Data.upsurt(fjupdatelist, Financial_Journal_Line__c.Id.getDescribe().getSObjectField(), new Set<String>());

		for (FinancialJournalWrapper fjw : manFJWMapAdd.values()) {
			if (fjw.fj.Amount__c != null) {
				fjw.fj.Amount__c = Math.abs(fjw.fj.Amount__c);
			}
		}

		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Bank Statement and Transactions and Journal Lines Saved Successfully.'));
	}

	/**
	*@description: Check if the bank statement is already created for selected month and user is
	*			   trying to create the new statement for same month.
	**/
	public Boolean checkStatementExists() {
		Boolean exists = false;
		Date sDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1);
		Date eDate = Date.newInstance(bankStat.Date__c.Year(), bankStat.Date__c.Month(), 1).addMonths(1).addDays(-1);

		for (Bank_Statement__c bankS : faMap.get(selectedFA).Bank_Statements__r) {
			if (sDate <= bankS.date__c && bankS.date__c <= eDate && bankS.id != bankStat.id) {
				exists = true;
				break;
			}
		}
		return exists;
	}

	/**
	*@description: Save or update bank statement
	**/

	public void saveStatement() {
		if (bankStat != null) {
			if (checkStatementExists() == false) {
				Data.upsurt(new List<Bank_Statement__c> {bankStat}, Bank_Statement__c.Id.getDescribe().getSObjectField(), new Set<String>());
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Bank Statement Saved Successfully'));
			} else {
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'A Bank Statement for this time period already exists'));
			}
		}
	}

	/**
	* @description Reset page and select a new Financial account anny time while working with bank statement.
	**/
	public void changeFAStat() {
		workingBankStat = false;
		workingBankRec = false;
		workingAddDeduct = false;
		bankStat = null;

		fjwList = new List<FinancialJournalWrapper>();
		vicList = new List<FinancialJournalWrapper>();
		fjwListBSAdd = new List<FinancialJournalWrapper>();
		fjwListBSDeduct = new List<FinancialJournalWrapper>();
		manFJWMapDeduct = new Map<Integer, FinancialJournalWrapper>();
		manFJWMapAdd = new Map<Integer, FinancialJournalWrapper>();
		faSOMap = new Map<String, SelectOption>();
		bsSOMap = new Map<String, SelectOption>();
		bsSOIndexToId = new Map<String, Id>();
		journalsToDelete = new List<Financial_Journal_Line__c>();

		loadFinancialAccounts();
		generateFASO();
	}

	/**
	*@description: Change Bank Statment
	**/
	public void changeStatement() {
		workingBankStat = false;
		workingAddDeduct = false;
		fjwList = new List<FinancialJournalWrapper>();
	}

	/**
	*@description: financial journal wrapper to display and collect the data from vendor check and financial journal line object
	**/
	public class FinancialJournalWrapper {
		public Financial_Journal_Line__c fj {get; set;}
		public Vendor_Invoice_Check__c vic {get; set;}
		public Boolean selected {get; set;}
		public Integer index {get; set;}
		public String FAAccount {get; set;}
		public Decimal debit {get; set;}
		public Decimal crdAmount {get; set;}
		public Boolean disabled {get; set;}

		//Initialize the vendor object as enable or disable to show in page block table on VF.
		public FinancialJournalWrapper(Vendor_Invoice_Check__c c, Boolean s) {
			this.vic = c;
			this.selected = s;
			if (vic.Bank_Statement__c != null) {
				selected = true;
			}
		}

		public FinancialJournalWrapper(Financial_Journal_Line__c f) {
			fj = f;
			FAAccount = f.Financial_Account__r + ' - ' + f.Financial_Account__r.Name;
			if (fj.Bank_Statement__c != null) {
				selected = true;
			}

			debit = 0.00;
			crdAmount = 0.00;

			if ((fj.Amount__c > 0 && fj.Financial_Account__r.Debit_Credit__c == 'Debit') || fj.Amount__c < 0 && fj.Financial_Account__r.Debit_Credit__c == 'Credit') {
				debit += Math.abs(fj.Amount__c);
			} else {
				crdAmount += Math.abs(fj.Amount__c);
			}
		}

		public FinancialJournalWrapper(Integer i, Financial_Journal_Line__c f) {
			this(f);
			index = i;
		}

		public FinancialJournalWrapper(Integer i, String faId) {
			debit = 0.00;
			crdAmount = 0.00;
			fj = new Financial_Journal_Line__c();
			index = i;
			fj.Bank_Reconciliation_Journal__c = true;
			fj.Amount__c = 0.00;
		}
	}
}