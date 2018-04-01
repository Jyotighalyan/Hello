public with sharing class GenerateDuesController {

  public List<selectOption> unSelectedDues{get;set;}
  public List<SelectOption> dueList{get;set;}
  public Dues_Summary__c txnObjRec {get; set;}
  public string selectedBillingPeriod{get;set;}
  public List<SelectOption> billingPeriod{get;set;}
  public Id batchId {get; set;}
  public Date lastRun {get; set;}
  public String status {get; set;}
  public String confirmDues {get; set;}
  public Set<Id> dueIdsToGenerate {get; set;}
  public Set<Id> dueIdsToReject {get; set;}

  public GenerateDuesController() 
  {
    dueIdsToGenerate = new Set<Id>();
    dueIdsToReject = new Set<Id>();
    txnObjRec = new Dues_Summary__c(Post_Date__c=Date.today());
    billingPeriod = getBillingPeriod_For_Current_FiscalYear();
    selectedBillingPeriod = billingPeriod[0].getValue();
    getAvailableDues_With_Mapping();
    AP_Aging__c ap = getLastGenerateDueBatchDate();
    batchId = getStatusOfBatch('GenerateDuesBatch');
    if(batchId==null && ap!=null && ap.Last_Generate_Due_Batch_Run_Date__c!=null && ap.Last_Generate_Due_Billing_Period__c!=null)
    {
      lastRun = ap.Last_Generate_Due_Batch_Run_Date__c;  
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'GenerateDuesBatch with Post Date of '+String.valueOf(lastRun).split(' ')[0]+' and Billing Period of '+ap.Last_Generate_Due_Billing_Period__c+' was successful.'));
    }
  }

  public void getAvailableDues_With_Mapping()
   {
        dueList=new List<SelectOption>();
        unSelectedDues = new List<SelectOption>();  
        boolean active = true;     
        List<Member_Dues__c> allDueList = Data.read('select id,Name, Type__c, Subtype__c, Tax_exempt__c from Member_Dues__c where Inactive_Flag__c!=:status AND Default_Billing_Frequency__c!=:oneTime', new Map<String, object> {'status' => active, 'oneTime' => 'One Time'});   
        Map<Id, Member_Dues__c> dueIdsMap = new Map<Id, Member_Dues__c>();
        Set<String> types = new set<String>();
        Set<String> subtypes = new set<String>();

        Map<String, Tax_To_Account_Mapping__c> allFinancialMapping = Utility.getTaxAndFinancialAccountMappings();
        for(Member_Dues__c due:allDueList)
        {                 
            types.add(due.Type__c);
            subtypes.add(due.Subtype__c);
        }
        List<TxnChargeToTaxMapping__c> taxes = Data.read('Select Id, Type__c, Subtype__c from TxnChargeToTaxMapping__c where Type__c in :types AND Subtype__c in :sub',
          new Map<String, Object> {'types' => types, 'sub' => subtypes}
          );

        for(Member_Dues__c due:allDueList)
        {                 
            if((due.Tax_exempt__c && taxesExemptRec(taxes, due.Type__c, due.Subtype__c)) || Utility.isTaxAndFinancialAccountMapped(due.Type__c, due.Subtype__c, allFinancialMapping)) 
            {
                dueIdsMap.put(due.id, due);
            }
        }

        List<Dues_Summary__c> dueSumm = getDueSumWithPassedPostDate(selectedBillingPeriod, txnObjRec.Post_Date__c, dueIdsMap.keySet());
        for(Dues_Summary__c dueSummObj :dueSumm)
        {
          dueIdsMap.remove(dueSummObj.Member_Dues__c);
          dueList.add(new SelectOption(dueSummObj.Member_Dues__c, dueSummObj.Member_Dues__r.Name));
        }

        for(Member_Dues__c dueObj:dueIdsMap.values())
        {
          unSelectedDues.add(new SelectOption(dueObj.id, dueObj.Name));
        }       
    }

    public void generateDues()
    {
      if(status=='confirm'){
        confirmDues = '';       
        Set<Id> unSelecDueIds = new Set<Id>();
        for(SelectOption dueObj :dueList)
        {
          dueIdsToGenerate.add(dueObj.getValue());
          unSelecDueIds.add(dueObj.getValue());
        }
          //for(SelectOption dueObj :unSelectedDues)
          //{
          //  unSelecDueIds.add(dueObj.getValue());
          //}

          List<String> namesOfDuesToSkip = new List<String>();
          Map<Id, Dues_Summary__c> dueSummRecs = new Map<Id, Dues_Summary__c> (getDueSumWithPassedPostDate(selectedBillingPeriod, txnObjRec.Post_Date__c, unSelecDueIds));
          for(Dues_Summary__c dueSummObj :dueSummRecs.values())
          {
            if(dueSummObj.Posted__c){
              dueIdsToGenerate.remove(dueSummObj.Member_Dues__c);
              namesOfDuesToSkip.add(dueSummObj.Member_Dues__r.Name);
            }
            else
            {
              dueIdsToReject.add(dueSummObj.id);
            }
          }

          if(namesOfDuesToSkip.size()>0){
            confirmDues = string.join(namesOfDuesToSkip,',');
          }
        }
        if(status=='generate'){
          Map<String, String> fieldNamesCorrToMonth = new Map<String, String>
          {
           'January' => 'January__c',
           'February' => 'February__c',
           'March' => 'March__c',
           'April' => 'April__c',
           'May' => 'May__c',
           'June'=> 'June__c',
           'July' => 'July__c',
           'August' => 'August__c',
           'September' => 'September__c',
           'October' => 'October__c',
           'November' => 'November__c',
           'December' => 'December__c'
         };

         if(txnObjRec.Post_Date__c==null)
         {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Post date is mandatory.'));
          return;
        }
        if(dueIdsToGenerate==null || dueIdsToGenerate.size()<1)
        {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select valid Due to be processed.'));
          return;
        }

        if(dueIdsToReject.size()>0)
        {
          List<Dues_Summary__c> dueSumms = getDueSummHavingNoChild(dueIdsToReject);
          if(dueSumms.size()>0){
            Data.remove(dueSumms);
          }
          PostDuesBatch postDues = new PostDuesBatch(null, null, dueIdsToReject, 'Reject');
          batchId = Database.executeBatch(postDues, 200);
        }
        GenerateDuesBatch generateDues = new GenerateDuesBatch(dueIdsToGenerate, txnObjRec.Post_Date__c, fieldNamesCorrToMonth.get(selectedBillingPeriod));
        batchId = Database.executeBatch(generateDues, 200);
      }
    }

    public List<SelectOption> getBillingPeriod_For_Current_FiscalYear()
    {
      List<SelectOption> billingPeriod = new List<SelectOption>();
      Integer fiscalMonth=[SELECT FiscalYearStartMonth FROM Organization limit 1].FiscalYearStartMonth;
      List<String> listOfMonths = new List<String> {'January','February','March','April','May','June','July','August','September','October','November','December'};
      Integer tempMonth = fiscalMonth - 1;
      for(Integer i=0; i<12; i++)
      {
          if(tempMonth==12) 
          {
            tempMonth = 0;
          }
          billingPeriod.add(new selectOption(listOfMonths.get(tempMonth), listOfMonths.get(tempMonth)));
          tempMonth++; 
      }
       return billingPeriod;
    }

    public AP_Aging__c getLastGenerateDueBatchDate()
    {
      String effecDateRec = 'Effective Date Record';
      List<AP_Aging__c> ApAging = [select Effective_Date__c, Last_Generate_Due_Batch_Run_Date__c, Last_Generate_Due_Billing_Period__c from AP_Aging__c where name =:effecDateRec];
      if(ApAging.size()>0)
      {
        return ApAging[0];
      } 
      return null; 
    }

    /**
    * @Description : method implementation of getting status of the passed batch
    * @return : returns true of the passed batch name is active
    */
    public static Id getStatusOfBatch(String batchName)
    {
      List<SObject> asyncJ = Data.read('select Id, TotalJobItems, Status, NumberOfErrors From AsyncApexJob where JobType = \'BatchApex\' and ApexClass.Name = :batchName and Status in :listOfExpStatus', new Map<String, Object> {'batchName' => batchName, 'listOfExpStatus' => new List<String> {'Queued','Pending','Active','Preparing','Processing'}});
      if(asyncJ.size()>0)
      {
        return asyncJ[0].id;
      }
      return null;
    }

    /**
    * @Description : get due summary records with passed billing month name and post date
    */
    public List<Dues_Summary__c> getDueSumWithPassedPostDate(String billingPeriod, Date postDate, Set<Id> dueIds)
    {
        return Data.read('select Id, Member_Dues__c, Member_Dues__r.Name, Posted__c from Dues_Summary__c where RecordTypeId=:recTypeId AND Billing_Period__c=:billMnth AND Post_Date__c=:pstDate AND Member_Dues__c=: dueIdsList',
          new Map<String, object> {'recTypeId' => Utility.searchRecordType('Due Summary', 'Dues_Summary__c'),
                                   'billMnth' => billingPeriod,
                                   'pstDate' => postDate,
                                   'dueIdsList' => dueIds
          }
          );
    }

    /**
    * @Description : due-summary records having no child records and removing them duesToBeRejected
    */
    public List<Dues_Summary__c> getDueSummHavingNoChild(Set<Id> dueSummIds)
    {
      List<Dues_Summary__c> dueSummList = new List<Dues_Summary__c>();
      for(Dues_Summary__c dueSummObj :(List<Dues_Summary__c>)Data.read('SELECT Id, Name, (SELECT Id FROM Dues_Summary1__r) FROM Dues_Summary__c Where Id in :dueSummIds', new Map<String, Object> {'dueSummIds' => dueSummIds})){
        if(dueSummObj.Dues_Summary1__r.size()<1){
          dueSummList.add(dueSummObj);
          dueIdsToReject.remove(dueSummObj.id);
        }
      }
      return dueSummList;
    }

    public void renderDues()
    {
      getAvailableDues_With_Mapping();
    }

    public boolean taxesExemptRec(List<TxnChargeToTaxMapping__c> taxesList, String type, String subtype){
      boolean taxMap = false;  
      for(TxnChargeToTaxMapping__c taxes : taxesList){
        if(taxes.Type__c==type && taxes.Subtype__c==subtype){
          taxMap = true;
        }
      }
      if(!taxMap){
        for(TxnChargeToTaxMapping__c taxes : taxesList){
        if(taxes.Type__c==type && taxes.Subtype__c==null){
          taxMap = true;
        }
      }
    }
    return taxMap;
  }
}