/**
* @author joshi Prakash
* @date 06-14-2017
* @group Financial Management
* @description Controller class to create update and delete financial manual journal entry
 **/

public with sharing class ManualFinancialJournalController {

	//Variables used while creating new journal entries
	public ManualEntry manEntry {get; set;}
	public Decimal mjeDebitTotal {get; set;}
	public Decimal mjeCreditTotal {get; set;}
	public Decimal mjeTotalAmount {get; set;}
	public Integer numberLinesToAdd {get; set;}

	//Variables used in existing journal entries section.
	public Map<Id, ManualEntry> manEntryMap {get; set;}
	public Decimal TBCredit {get; set;}
	public Decimal TBDebit {get; set;}
	public Decimal TBTotal {get; set;}

	//Delete financial journal entry variables
	public List<Financial_Journal_Line__c> fjlDeleteList {get; set;}
	public List<Financial_Journal_Entry__c> fjeDeleteList {get; set;}
	public String cSelDelId {get; set;}

	//Update existing manual journal entries.
	public Manualentry selectedME {get; set;}
	public String cSelId {get; set;}
	public Decimal mjelDebitTotal {get; set;}
	public Decimal mjelCreditTotal {get; set;}
	public Decimal mjelTotalAmount {get; set;}
	public String fjeId {get; set;}
	public String fjlId {get; set;}

	//Filter and post variables
	public Financial_Journal_Line__c searchDateOS {get; set;}
	public Financial_Journal_Line__c searchDateOE {get; set;}
	public Date searchDateS {get; set;}
	public Date searchDateE {get; set;}
	public Boolean searchPosted {get; set;}
	public Boolean searchUnPosted {get; set;}

	//Recurring journal entry variables
	public Financial_Journal_Entry__c recurringEntry{get;set;}	
	public String selectedTemplate{get;set;}
	public List<SelectOption> availableTemplates{get;set;}
	public Map<Id,ManualEntry> recurringEntryMap{get;set;}	
	/**
	* @description counstructor allocate resources.
	 **/
	public ManualFinancialJournalController(ApexPages.StandardController stdController) {
		mjeDebitTotal = 0;
		mjeCreditTotal = 0;
		mjeTotalAmount = 0;
		numberLinesToAdd = 1;
		manEntry = new ManualEntry();

		//Tie SearchDate to a Date field to allow us to use calendar render
		searchDateOS = new Financial_Journal_Line__c(Post_Date__c = Date.today());
		searchDateOE = new Financial_Journal_Line__c(Post_Date__c = Date.today());
		searchPosted = false;
		searchUnPosted = false;

		loadEntries();
		fjeDeleteList = new List<Financial_Journal_Entry__c>();
		fjlDeleteList = new List<Financial_Journal_Line__c>();

		recurringEntry=new Financial_Journal_Entry__c();		
	}

	/**
	* @description innner class for creating manual journal entries and handling a grid on VF
	**/
	public class ManualEntry implements Comparable {
		public Financial_Journal_Entry__c fje {get; set;}
		public Integer index {get; set;}

		//Map to hold financial journal lines for the financial journal entry
		public Map<Integer, ManualJournalLine> mjlList {get; set;}
		public Integer lineIndex {get; set;}
		public Integer numberLinesToAdd {get; set;}
		public Decimal TotalAmount {get; set;}
		public Decimal DebitTotal {get; set;}
		public Decimal crdtotal {get; set;}
		public Boolean post {get; set;}

		/**
		* @description counstructor to show the number of grid based on the existing entry
		* @param Financial journal object to be edit
		* @param Integer index to next allocation number to grid while adding more lines to grid
		**/
		public ManualEntry(Financial_Journal_Entry__c fje, Integer i) {
			this.fje = fje;
			index = i;
			lineIndex = 0;
			numberLinesToAdd = 10;
			TotalAmount = 0.00;
			DebitTotal = 0.00;
			crdtotal = 0.00;
			mjlList = new Map<Integer, ManualJournalLine>();
			for (Financial_Journal_Line__c fj : fje.Financial_Journals__r) {
				mjlList.put(lineIndex, new ManualJournalLine(fj, lineIndex));
				lineIndex++;
				debittotal += fj.debit__c;
				crdtotal += fj.credit__c;
			}
			TotalAmount = debittotal - crdtotal;
		}

		/**
		* @description Default counstructor to create the reference of financial journal entry for getting journal date notes and description.
		**/
		public ManualEntry() {
			fje = new Financial_Journal_Entry__c();
			fje.Entry_Date__c = Date.Today();
			mjlList = new Map<Integer, ManualJournalLine>();
			lineIndex = 0;
			numberLinesToAdd = 10;
			fje.manual_entry__c = true;
			addJournalLine();
		}

		/**
		* @description Method to add 10 more lines in a grid.
		**/
		public void addJournalLine() {
			for (Integer i = 0; i < numberLinesToAdd; i++) {
				mjlList.put(lineIndex, new ManualJournalLine(lineIndex));
				lineIndex++;
			}
		}

		/**
		* @description Method to add no of lines in a grid.
		* @param Integer containing the number of grid to be added
		**/
		public void addJournalLine(Integer i) {
			numberLinesToAdd = i;
			addJournalLine();
		}

		/**
		* @description Convert map to the list and sort and return.
		**/
		public List<ManualJournalLine> getJournalList() {
			List<ManualJournalLine> templist = mjlList.values();
			templist.sort();
			return templist;
		}

		/**
		* @description CompareTo method to sort an object
		**/
		public Integer compareTo(Object compareTo) {
			ManualEntry jl = (ManualEntry)compareTo;
			if (fje.Id == jl.fje.Id)
				return 0;
			if (fje.Id > jl.fje.Id)
				return 1;
			return -1;
		}
	}

	/**
	* @description innner class for creating manual journal lines and attach to the entry.
	**/
	public class ManualJournalLine implements Comparable {
		public Financial_Journal_Line__c fjl {get; set;}
		public Integer index {get; set;}
		public String debit {get; set;}
		public String linecrd {get; set;}
		public boolean isError {get; set;}

		/**
		* @description counstructor to create empty reference of financial manual journal with assigning index.
		* @param Integer index to grid grid row.
		**/
		public ManualJournalLine(Integer i) {
			fjl = new Financial_Journal_Line__c();
			fjl.Manual_Journal__c = true;
			index = i;
			isError = false;
		}

		/**
		* @description counstructor to convert debit and linecrd in string while updationg the line.
		* @param Financial journal line object to get linecrd and debit.
		* @param Integer index to next allocation number to grid while adding more lines to grid while update.
		**/
		public ManualJournalLine(Financial_Journal_Line__c fjl, Integer i) {
			this.fjl = fjl;
			index = i;
			debit = String.valueof(Math.abs(fjl.debit__c));
			linecrd = String.valueof(Math.abs(fjl.credit__c));
			isError = false;
			if (debit == null) {
				debit = '0';
			}
			if (linecrd == null) {
				linecrd = '0';
			}
		}

		/**
		* @description CompareTo method to sort an object
		**/
		public Integer compareTo(Object compareTo) {
			ManualJournalLine jl = (ManualJournalLine)compareTo;
			if (index == jl.index) {
				return 0;
			} else if (index > jl.index) {
				return 1;
			} else {
				return -1;
			}
		}
	}

	/**
	* @description Method to add more rows in grid when button is clicked on VF
	**/
	public void addNewEntryLines() {
		manEntry.addJournalLine(numberLinesToAdd);
	}

	/**
	* @description Calculate total debit total linecrd and Total amount each time
	*			   when the user add or update the value in grid for linecrd or debit column.
	**/

	public void calDebCredTotal() {
		mjeDebitTotal = 0;
		mjeCreditTotal = 0;
		for (ManualJournalLine mjl : manEntry.mjlList.values()) {
			if (mjl.debit != null && mjl.debit != '') {
				String temp = mjl.debit.replaceAll(',', '').replaceAll('$', '').trim();
				try {
					mjeDebitTotal += Decimal.valueOf(temp);
				} catch (Exception e) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Fatal, 'There is journal line that have incoreect debit amount'));
				}
			}

			if (mjl.linecrd != null && mjl.linecrd != '') {
				String temp = mjl.linecrd.replaceAll(',', '').replaceAll('$', '').trim();
				try {
					mjeCreditTotal += Decimal.valueOf(temp);
				} catch (Exception e) {
					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Fatal, 'There is journal line that have incoreect linecrd amount'));
				}
			}
		}
		mjeTotalAmount = mjeDebitTotal - mjeCreditTotal ;
	}

	/**
	* @description Validate and save financial journal entry by concidering only
	*			   filled rows in grid by the user.
	**/
	public void addNewEntry() {
		SavePoint sp = Database.setSavePoint();

		try {
			if (manEntry.fje.Entry_Date__c == null) {
				throw new Utility.CustomException('Entry date is mandatory.');
			}

			List<Financial_Journal_Line__c> fjInsertList = new List<Financial_Journal_Line__c>();
			Integer index = 0;
			Set<Id> faSet = new Set<Id>();
			Map<Id, Financial_Account__c> faMap;

			for (ManualJournalLine mjl : manEntry.mjlList.values()) {
				if (!((String.valueOf(mjl.fjl.Financial_Account__c) == '' || mjl.fjl.Financial_Account__c == null) && (mjl.fjl.Description__c == '' || mjl.fjl.Description__c == null)  && ((mjl.linecrd == null || mjl.linecrd == '0' || mjl.linecrd == '') && (mjl.debit == '0' || mjl.debit == null || mjl.debit == '')))) {
					if (String.valueOf(mjl.fjl.Financial_Account__c) != '' || mjl.fjl.Financial_Account__c != null) {
						faSet.add(mjl.fjl.Financial_Account__c);
					}
				}
			}

			faMap = new Map<Id, Financial_Account__c>((List<Financial_Account__c>)Data.read(
			            'select id, Debit_Credit__c from Financial_Account__c where id in :faSet',
			new Map<String, Object> {
				'faSet' => faSet
			}));

			Boolean throwError = false;
			for (ManualJournalLine mjl : manEntry.mjlList.values()) {
				mjl.isError = false;
				if (!((String.valueOf(mjl.fjl.Financial_Account__c) == '' || mjl.fjl.Financial_Account__c == null) && (mjl.fjl.Description__c == '' || mjl.fjl.Description__c == null)  && ((mjl.linecrd == null || mjl.linecrd == '0' || mjl.linecrd == '') && (mjl.debit == '0' || mjl.debit == null || mjl.debit == '')))) {
					if (String.valueOf(mjl.fjl.Financial_Account__c) == null) {
						mjl.isError = true;		
						throw new Utility.CustomException('There is a journal line that does not have a financial account');
																
					}

					if ((mjl.debit == null && mjl.linecrd == null) || (mjl.debit == '' && mjl.linecrd == '')) {
						mjl.isError = true;						
						throw new Utility.CustomException('There is a journal line that does not have a debit or a Credit');												
					}

					if (mjl.debit == null || mjl.debit == '') {
						mjl.debit = '0';
					}

					if (mjl.linecrd == null || mjl.linecrd == '') {
						mjl.linecrd = '0';
					}

					Decimal mjldebit = 0;
					try {
						mjldebit = Decimal.valueOf(mjl.debit.replaceAll(',', '').replaceAll('$', ''));
					} catch (Exception e) {
						mjldebit = 0;
					}

					Decimal mjlcredit = 0;
					try {
						mjlcredit = Decimal.valueOf(mjl.linecrd.replaceAll(',', '').replaceAll('$', ''));
					} catch (Exception e) {
						mjlcredit = 0;
					}

					mjl.fjl.Amount__c = mjldebit - mjlcredit;
					if (faMap.get(mjl.fjl.Financial_Account__c).Debit_Credit__c == 'Credit') {
						mjl.fjl.Amount__c = -mjl.fjl.Amount__c;
					}

					mjl.fjl.Transaction_Date__c = manEntry.fje.Entry_Date__c;
					mjl.fjl.Insert_Index__c = index + '';
					fjInsertList.add(mjl.fjl);
					index++;
				}
			}

			if(fjInsertList.size()<=0)
			{
				throw new Utility.CustomException('There are no Financial Journal Lines to Save.');
			}

			Data.create(manEntry.fje);
			for (Financial_Journal_Line__c fjl : fjInsertList) {
				fjl.Financial_Journal_Entry__c = manEntry.fje.id;
			}

			Data.create(fjInsertList);

			manEntry = new ManualEntry();
			loadEntries();
			calDebCredTotal();

		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Fatal, e.getMessage()));
			Database.rollback(sp);
		}
	}

	/**
	* @description Validate and update financial journal lines for selected journal entry by concidering only
	*			   filled rows in grid by the user.
	**/
	public void updateEntry() {
		SavePoint sp = Database.setSavePoint();

		try {
			if (manEntry.fje.Entry_Date__c == null) {
				throw new Utility.CustomException('Entry date is mandatory.');
			}

			Financial_Journal_Entry__c fjeExist = (Financial_Journal_Entry__c)Data.read(
			        'select id, Posted__c from Financial_Journal_Entry__c where id = :journalId',
			new Map<String, Object> {
				'journalId' => selectedME.fje.id
			}
			                                      ).get(0);

			if (fjeExist.Posted__c == true) {
				throw new Utility.CustomException('This Journal has already been posted and cannot be updated');
			}

			List<Financial_Journal_Line__c> fjInsertList = new List<Financial_Journal_Line__c>();
			Integer index = 0;
			Set<Id> faSet = new Set<Id>();
			Map<Id, Financial_Account__c> faMap;

			for (ManualJournalLine mjl : selectedME.mjlList.values()) {
				if (!((String.valueOf(mjl.fjl.Financial_Account__c) == '' || mjl.fjl.Financial_Account__c == null) && (mjl.fjl.Description__c == '' || mjl.fjl.Description__c == null)  && ((mjl.linecrd == null || mjl.linecrd == '0' || mjl.linecrd == '') && (mjl.debit == '0' || mjl.debit == null || mjl.debit == '')))) {
					if (String.valueOf(mjl.fjl.Financial_Account__c) != '' || mjl.fjl.Financial_Account__c != null) {
						faSet.add(mjl.fjl.Financial_Account__c);
					}
				}
			}


			faMap = new Map<Id, Financial_Account__c>((List<Financial_Account__c>)Data.read(
			            'select id, Debit_Credit__c from Financial_Account__c where id in :faSet',
			new Map<String, Object> {
				'faSet' => faSet
			}));

			for (ManualJournalLine mjl : selectedME.mjlList.values()) {
				mjl.isError = false;
				if (!((String.valueOf(mjl.fjl.Financial_Account__c) == '' || mjl.fjl.Financial_Account__c == null) && (mjl.fjl.Description__c == '' || mjl.fjl.Description__c == null)  && ((mjl.linecrd == null || mjl.linecrd == '0' || mjl.linecrd == '') && (mjl.debit == '0' || mjl.debit == null || mjl.debit == '')))) {
					if (String.valueOf(mjl.fjl.Financial_Account__c) == null) {
						mjl.isError = true;
						throw new Utility.CustomException('There is a journal line that does not have a financial account');															
					}

					if ((mjl.debit == null && mjl.linecrd == null) || (mjl.debit == '' && mjl.linecrd == '')) {
						mjl.isError = true;
						throw new Utility.CustomException('There is a journal line that does not have a debit or a Credit');						
					}

					if (mjl.debit == null || mjl.debit == '') {
						mjl.debit = '0';
					}

					if (mjl.linecrd == null || mjl.linecrd == '') {
						mjl.linecrd = '0';
					}

					Decimal mjldebit = 0;
					try {
						mjldebit = Decimal.valueOf(mjl.debit.replaceAll(',', '').replaceAll('$', ''));
					} catch (Exception e) {
						mjldebit = 0;
					}

					Decimal mjlcredit = 0;
					try {
						mjlcredit = Decimal.valueOf(mjl.linecrd.replaceAll(',', '').replaceAll('$', ''));
					} catch (Exception e) {
						mjlcredit = 0;
					}

					mjl.fjl.Amount__c = mjldebit - mjlcredit;
					if (faMap.get(mjl.fjl.Financial_Account__c).Debit_Credit__c == 'Credit') {
						mjl.fjl.Amount__c = -mjl.fjl.Amount__c;
					}

					mjl.fjl.Transaction_Date__c = selectedME.fje.Entry_Date__c;
					mjl.fjl.Insert_Index__c = index + '';
					fjInsertList.add(mjl.fjl);
					index++;
				}
			}

			if(fjInsertList.size()<=0)
			{
				throw new Utility.CustomException('There are no Financial Journal Lines to Save.');
			}
			
			Data.modify(selectedME.fje);
			for (Financial_Journal_Line__c fjl : fjInsertList) {
				fjl.Financial_Journal_Entry__c = selectedME.fje.id;
			}

			Data.upsurt(fjInsertList, Financial_Journal_Line__c.Id.getDescribe().getSObjectField(), new Set<String>());
			selectedME = null;
			loadEntries();

		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Fatal, e.getMessage()));
			Database.rollback(sp);
		}
	}

	/**
	* @description Close the update section on VF
	**/
	public void closeSelectedME() {
		selectedME = null;
		cSelId = null;
	}

	/**
	* @description Select journal entry to update
	**/
	public void setSelFJE() {
		selectedME = null;
		if (cSelId != null) {
			selectedME = manEntryMap.get(cSelId);
			calDebCredTotalMEJL();
		}
	}

	/**
	* @description Delete financial journal (row in grid) while updating the entry.
	**/
	public void delFJL() {
		try {
			if (fjlDeleteList != null) {
				fjlDeleteList.clear();
			} else {
				fjlDeleteList = new List<Financial_Journal_Line__c>();
			}

			if (fjeId != null && fjlId != null) {
				if (manEntryMap != null && manENtryMap.containsKey(fjeId) && manENtryMap.get(fjeId).mjlList != null) {
					for (Integer i : manEntryMap.get(fjeId).mjlList.keyset()) {
						ManualJournalLine mjl = manEntryMap.get(fjeId).mjlList.get(i);
						if (mjl != null && mjl.fjl != null && mjl.fjl.Id != null && mjl.fjl.Id == fjlId) {
							fjlDeleteList.add(mjl.fjl);
							manEntryMap.get(fjeId).mjlList.remove(i);
						}
					}
					saveDeleteEntry();
				} else {
					ApexPages.addMessage(new APexPages.message(ApexPages.Severity.ERROR, 'Unable to delete this journal line.'));
				}
			}
		} catch (Exception e) {
			fjeId = null;
			fjlId = null;
			ApexPages.addMessages(e);
		}

		fjeId = null;
		fjlId = null;
		calDebCredTotalMEJL();
	}

	/**
	* @description Update the total linecrd debit and total balance in update section.
	**/
	public void calDebCredTotalMEJL() {
		mjelDebitTotal = 0;
		mjelCreditTotal = 0;

		for (ManualJournalLine mjl : selectedMe.mjlList.values()) {
			if (mjl.debit != null && mjl.debit != '') {
				String temp = mjl.debit.replaceAll(',', '').replaceAll('$', '').trim();
				try {
					mjelDebitTotal += Decimal.valueOf(temp);
				} catch (Exception e) {
					mjelDebitTotal += 0;
				}
			}

			if (mjl.linecrd != null && mjl.linecrd != '') {
				String temp = mjl.linecrd.replaceAll(',', '').replaceAll('$', '').trim();
				try {
					mjelCreditTotal += Decimal.valueOf(temp);
				} catch (Exception e) {
					mjelCreditTotal += 0;
				}
			}
		}

		mjelTotalAmount = mjelDebitTotal - mjelCreditTotal ;
	}

	/**
	* @description Add more rows to the grid while updating journal entry.
	**/
	public void addNewExistingLines() {
		try {
			selectedME.addJournalLine(numberLinesToAdd);
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Fatal, e.getMessage() + ' - ' + e.getLineNumber()));
		}
	}

	/**
	* @description Convert map to the list and return a list and update total linecrd debit.
	**/
	public List<ManualEntry> getmanualEntries() {
		List<ManualEntry> tempList = manEntryMap.values();
		TBCredit = 0;
		TBDebit = 0;
		TBTotal = 0;
		for (ManualEntry me : tempList) {
			TBCredit += me.crdtotal;
			TBDebit += me.debitTotal;
			TBTotal += me.totalAmount;
		}
		tempList.sort();
		return tempList;
	}

	/**
	* @description Query existing manual journal entry from the object and show as table in VF.
	**/
	public void loadEntries() {

		searchDateS = searchDateOS.Post_Date__c;
		searchDateE = searchDateOE.Post_Date__c;

		Map<String, Object> filterParams=new Map<String, Object>();
		filterParams.put('isManual',true);
		filterParams.put('startDate',searchDateS);
		filterParams.put('endDate',searchDateE);

		String postFilter='';		
		if(searchPosted && searchUnPosted)
		{
			postFilter='';
		}
		else if(searchPosted)
		{
			postFilter=' and Posted__c=:posted ';
			filterParams.put('posted',true);			
		}
		else if(searchUnPosted)
		{
			postFilter=' and Posted__c=:posted ';
			filterParams.put('posted',false);			
		}

		String Query='select Id, Name, Entry_Date__c, Reference__c, Description__c, Notes__c, Posted__c, Post_Date__c, (select id, Name, Credit__c, Debit__c,Financial_Account__c, Description__c, Amount__c from Financial_Journals__r order by Insert_Index_Num__c) from Financial_Journal_Entry__c where Manual_Entry__c = :isManual'+postFilter+' and (Entry_Date__c >=: startDate and Entry_Date__c <= :endDate)';
		manEntryMap = new Map<Id, ManualEntry>();
		List<Financial_Journal_Entry__c> fjeLst = (List<Financial_Journal_Entry__c>)Data.read(
		            Query,filterParams);

		selectedME = null;
		Integer i = 0;

		for (Financial_Journal_Entry__c fje : fjeLst) {
			manEntryMap.put(fje.id, new ManualEntry(fje, i));
			i++;
		}
	}

	/* Delete manual financial journal methods */
	/**
	* @description Delete manual journal entry when the del link is clicked from the PageBloackTable.
	**/
	public void delSelFJE() {
		if (cSelDelId != null) {
			fjeDeleteList.clear();
			fjeDeleteList.add(manEntryMap.get(cSelDelId).fje);
			for (ManualJournalLine mjl : manEntryMap.get(cSelDelId).mjlList.values()) {
				fjlDeleteList.add(mjl.fjl);
			}
			manEntryMap.remove(cSelDelId);
			saveDeleteEntry();
		}
		loadEntries();
	}

	/**
	* @description Permanantly delete the journal line and entry from the object.
	**/
	public void saveDeleteEntry() {
		Data.remove(fjeDeleteList);
		Data.remove(fjlDeleteList);
		fjeDeleteList.clear();
		fjlDeleteList.clear();
	}

	/**
	* @description Post selected manual journal entries filling the post date abd Posted checkbox.
	**/
	public void postFJE() {
		SavePoint sp = Database.setSavePoint();
		try {
			List<Financial_Journal_Entry__c> fjeList = new List<Financial_Journal_Entry__c>();
			List<Financial_Journal_Line__c> fjlList = new List<Financial_Journal_Line__c>();
			for (ManualEntry me : manEntryMap.values()) {
				if (me.post == true) {
					me.fje.Posted__c = true;
					me.fje.Post_Date__c = me.fje.Entry_Date__c;
					fjeList.add(me.fje);
					for (ManualJournalLine fjl : me.mjlList.values()) {
						fjl.fjl.Posted__c = true;
						fjl.fjl.Post_Date__c = me.fje.Entry_Date__c;
						fjlList.add(fjl.fjl);
					}
				}
			}

			Data.modify(fjeList);
			Data.modify(fjlList);
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Journals Sucessfully Posted.'));

		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Fatal, e.getMessage()));
			Database.rollback(sp);
			loadEntries();
		}
	}

	/**
	*@description: Load recurring journal templates based on the selected frequency.
	**/
	public void loadTemplates()
	{		
		List<Financial_Journal_Entry__c> fjeLst = (List<Financial_Journal_Entry__c>)Data.read(
			        'Select Recurring_Entry_Name__c, Notes__c, (Select Credit__c, Debit__c, Financial_Account__c, Description__c from Financial_Journals__r Order By Insert_Index_Num__c ASC) from Financial_Journal_Entry__c where Recurring_Entry__c =: isRecurring and Recurring_Journal_Frequency__c =: frequency',
			new Map<String, Object> {
				'isRecurring' => true,
				'frequency' => recurringEntry.Recurring_Journal_Frequency__c
		});
        
        Integer i =0;        
        recurringEntryMap = new Map<Id,ManualEntry>();

        for(Financial_Journal_Entry__c fje : fjeLst){
            recurringEntryMap.put(fje.id,new ManualEntry(fje,i));
            i++;
        }

        availableTemplates=new List<SelectOption>();
        availableTemplates.add(new SelectOption('','--None--'));
        for(ManualEntry me: recurringEntryMap.values()){
            availableTemplates.add(new SelectOption(me.fje.id,me.fje.Recurring_Entry_Name__c));
        }      
	}

	/**
	*@description: Set selected journal template for edit and save.
	**/	
	
    public void setRecurringEntry(){

        if(selectedTemplate!=null && selectedTemplate!=''){
            manEntry = recurringEntryMap.get(selectedTemplate);            
            manEntry.fje = manEntry.fje.clone(false,false,false,false);
            manEntry.fje.Recurring_Entry__c = false;
            manEntry.fje.Manual_Entry__c = true;
            if(manEntry.fje.Recurring_Entry_Name__c!=null)
            {
            	manEntry.fje.Reference__c = manEntry.fje.Recurring_Entry_Name__c;
            	manEntry.fje.Recurring_Entry_Name__c = null;     
			} 

            manEntry.fje.Entry_Date__c=Date.Today();                                    
            for(ManualJournalLine mjl : manEntry.mjlList.values()){
                mjl.fjl = mjl.fjl.clone(false,false,false,false);
                mjl.fjl.Recurring_Journal_Line__c = false;
                mjl.fjl.Manual_Journal__c = true;
            }
        }
        calDebCredTotal();
    }

    public void clearEntry()
    {
    	manEntry=new ManualEntry();
    }
}