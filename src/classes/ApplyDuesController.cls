public with sharing class ApplyDuesController {

    public List<SelectOption> allCategories{get;set;}
    public List<SelectOption> selectedCategories{get;set;}
    public Member_Dues__c currentBillingObj {get; set;}

    //variables for confirmation on removal of categories
    public List<SelectOption> removedCategories;
    public String removedCatString {get; set;}
    public String actionToPerform {get; set;}
    public List<String> delList;

    // property true if due id is invalid
    public boolean isDueIdErr {get; set;}
    public List<Billing_Custom_Distribution__c> existingInstallment{get;set;}

    // variable to show on page - the distribution table
    public Map<String, distributionStructure> distrubtionMap {get; set;}
    public List<String> sortedListOfKeys {get; set;}

    // Fiscal Month variable
    public Integer fiscalMonth;
    public boolean isUpdate{get;set;}

    // currency symbol
    public string currencySymbol {get; set;} 

    // boolean to show error if problem in distribution
    public boolean isDistributionFailed {get; set;}

    //variable stores month names and crossponding field name
    Map<String, String> fieldNamesCorrToMonth;

    //variable to store success when distrubutions are saved
    public boolean distributionSuccess {get; set;}

    public boolean isOneTime {get; set;}

    /**
    * Variables related to dues from member
    */

    public Contact memberRec {get; set;}
    public List<SelectOption>allAvailableActiveDues{get;set;}
    public List<SelectOption>duesListOnThisMember{get;set;}
    public string memberId{get;set;}

    // variable to store selected due name for detail
    public string SelectedDuesForDetails{get;set;} 

    // list variable whose values will display in a dropdown list
    public List<SelectOption> duesListOnThisMemberForDetail{get;set;}

    public ApplyDuesController(ApexPages.StandardController std) {

        // check if the passed due id is correct or not
        Boolean checkDueId = false;
        isDueIdErr = false;
        if(ApexPages.currentPage().getParameters().get('dueId')!=null && ApexPages.currentPage().getParameters().get('dueId')!=''){
            List<Member_Dues__c> billObj = (List<Member_Dues__c>) Data.read('Select Id, Auto_Apply_On_Membership_Types__c, Primary_Annual_Amount__c, Spouse_Partner_Annual_Amount__c, Dependent_Annual_Amount__c, Default_Billing_Frequency__c, Start_Date__c  from Member_Dues__c where id=:dueId', new Map<String, object> {'dueId' => ApexPages.currentPage().getParameters().get('dueId')});
            if(billObj!=null && billObj.size()>0){
                currentBillingObj = billObj[0];
                if(currentBillingObj.Default_Billing_Frequency__c=='One Time'){
                    isOneTime = true;
                }
            }
            else
            checkDueId = true;
        }
        else
        checkDueId = true; 
        if(checkDueId)
        {
            isDueIdErr = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'Invalid Due Id. Can not proceed further.'));
            return;
        }
        InitialSetup(currentBillingObj.id);
    }

    public ApplyDuesController()
    {
        isDueIdErr = false;
        if(ApexPages.currentPage().getParameters().get('memId')!=null && ApexPages.currentPage().getParameters().get('memId')!='')
        {
            SelectedDuesForDetails = 'none';
            memberId = ApexPages.currentPage().getParameters().get('memId');
            try{
                memberRec = (Contact) Data.read('Select Name from Contact where id=:memberId And RecordTypeId=:recId', new Map<String, Object> {'memberId'=>memberId, 'recId' => Utility.searchRecordType('Member','Contact')})[0];
            }
            catch(Exception ex)
            {
                isDueIdErr = true;
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'Invalid Member Id. Can not proceed further.'));
                return;
            }
            allAvailableActiveDues=new List<SelectOption>();
            Set<string> ExistingDueList = new Set<string>();
            duesListOnThisMember=new List<SelectOption>();
            duesListOnThisMemberForDetail=new List<SelectOption>();

            List<Apply_due_on_members__c> duesOnThisMember = Data.read('select id,Member_Dues__r.Name,Member_Dues__r.id from Apply_due_on_members__c where Contact__c=:memId', new Map<String, Object> {'memId' => memberId});        
            for(Apply_due_on_members__c due:duesOnThisMember)
            {      
                duesListOnThisMember.add(new SelectOption(due.Member_Dues__r.id,due.Member_Dues__r.Name));   
                ExistingDueList.add(due.Member_Dues__r.Name);           
            }

            duesListOnThisMemberForDetail = getSelectDueList(duesListOnThisMember);
            boolean status = true;  
            List<Member_Dues__c> allDueList = Data.read('select id,Name,Start_Date__c from Member_Dues__c where Inactive_Flag__c!=:status', new Map<String, Object> {'status' => status});
            for(Member_Dues__c due:allDueList)
            {      
                if(ExistingDueList!=null && (!ExistingDueList.contains(due.Name)))
                {
                    allAvailableActiveDues.add(new SelectOption(due.id,due.Name)); 
                }               
            } 
        }
    }

    public PageReference saveSetup()
    {
        isDistributionFailed = false;
        // to take confirmation from user on deletion of membership types
        if(actionToPerform=='confirm')
        { 
            delList = new List<String>();
            removedCatString = '';

            // removedCategories contains all the selected categories in right hand side initially - fill delList with the options unselected
            for(SelectOption rmCatObj :removedCategories)
            {
                boolean tempBool = false;
                for(SelectOption seleCat :selectedCategories)
                {
                    if(rmCatObj.getValue() == seleCat.getValue())
                    tempBool = true;
                }
                if(!tempBool)
                {  
                    delList.add(rmCatObj.getLabel());
                }   
            }

            // get all the apply members list for delList
            Map<String, List<Apply_due_on_members__c>> MembersWithDelOption = getApplyDueOnMembers(delList);

            // if members related to the delList exists then fill the list
            List<String> namesToBeShown = new List<String>();
            if(delList.size()>0){
                for(String strObj : delList) {if(MembersWithDelOption.get(strObj)!=null) namesToBeShown.add(strObj);}
                
                for(Integer i=0; i<namesToBeShown.size(); i++) 
                {
                    if(i==namesToBeShown.size()-1)
                    removedCatString = removedCatString + namesToBeShown[i];
                    else
                    removedCatString = removedCatString + namesToBeShown[i]+', ';  
                }
            }
            return null;
        }

        if(actionToPerform=='save')
        {
            List<String> selectedCat = new List<String>();
            for(SelectOption strObj :selectedCategories)
            {
                selectedCat.add(strObj.getLabel()); 
            }

            Map<String, List<Contact>> listOfContactsWithMembershipType= getAllContactsWithPassedMemType(selectedCat);
            List<Apply_due_on_members__c> AlladdedMembers= Data.read('select id,Contact__c, Member_Dues__c, Membership_Type__c from Apply_due_on_members__c where Member_Dues__c=:currentBillingObjId', new Map<String, Object> {'currentBillingObjId'=> currentBillingObj.id});    
            List<Apply_due_on_members__c> memberToInset=new List<Apply_due_on_members__c>();
            List<Apply_due_on_members__c> membersToDelete = new List<Apply_due_on_members__c>();

        // to add the members with the membership type in selected category list
        for(String temp:selectedCat)
        {           
            Set<Id> MemberIdNDueId = new Set<Id>();
            
            for(Apply_due_on_members__c autApply:AlladdedMembers)
            {
                MemberIdNDueId.add(autApply.Contact__c);
            }
            
            List<Contact> members = listOfContactsWithMembershipType.get(temp); 
            if(members!=null && members.size()>0)    
            for(Contact c:members)
            {                
                if(!MemberIdNDueId.contains(c.id))
                {                                         
                    Apply_due_on_members__c tempData=new Apply_due_on_members__c();
                    tempData.Member_Dues__c=currentBillingObj.id;
                    tempData.Contact__c=c.id; 
                    memberToInset.add(tempData);
                }              
            }
        }

        // delete the members with the membership type in delete list
        if(delList!=null && delList.size()>0){
            for(String del :delList)
            {
                for(Apply_due_on_members__c conObj :AlladdedMembers)
                {
                    if(conObj.Membership_Type__c==del)
                    membersToDelete.add(conObj);
                }
            }
        }

        if(memberToInset.size()>0)
        Data.create(memberToInset);

        if(membersToDelete.size()>0)
        Data.remove(membersToDelete);

        currentBillingObj.Auto_Apply_On_Membership_Types__c= String.join(selectedCat, ';');
        Data.upsurt(new List<SObject> {currentBillingObj}, Member_Dues__c.id.getDescribe().getSObjectField(), new Set<String>());
        return new PageReference('/'+currentBillingObj.id);
        }
        if(actionToPerform=='')
        {

            List<SelectOption> newAllCat = allCategories.clone();
            List<SelectOption> newSeleCat = selectedCategories.clone();

            for(String strObj :removedCatString.split(','))
            {
                for(Integer i=0; i<allCategories.size(); i++)
                {
                    if(allCategories[i].getLabel()==strObj){
                        newSeleCat.add(allCategories[i]);
                        newAllCat.remove(i);
                    }
                }
                
            }
            allCategories = newAllCat;
            selectedCategories = newSeleCat;
            return null;
        } 
        return null;
    }

    /**
    * @Description : save complete page
    */
    public void SaveFull()
    {
        distributionSuccess = false;
        isDistributionFailed = false;
        actionToPerform = 'confirm';
        saveSetup();
        Decimal annualPrimaryAmount = currentBillingObj.Primary_Annual_Amount__c;
        Decimal annualSpouseAmount = currentBillingObj.Spouse_Partner_Annual_Amount__c;
        Decimal annualDependentAmount = currentBillingObj.Dependent_Annual_Amount__c;
        Decimal distributedPrimaryAmount =0.00;
        Decimal distributedSpouseAmount = 0.00;
        Decimal distributedDependentAmount = 0.00;
        for(distributionStructure disStructObj :distrubtionMap.values())
        {
            if(disStructObj.primaryAmount.January__c!=null) distributedPrimaryAmount += disStructObj.primaryAmount.January__c;
            if(disStructObj.spouseAmount.January__c!=null) distributedSpouseAmount += disStructObj.spouseAmount.January__c;
            if(disStructObj.dependentAmount.January__c!=null) distributedDependentAmount += disStructObj.dependentAmount.January__c;
        }

        if(annualPrimaryAmount!=distributedPrimaryAmount || annualSpouseAmount!=distributedSpouseAmount || annualDependentAmount!=distributedDependentAmount){
            isDistributionFailed = true;
            return;
        }
        else
        {  
            for(Billing_Custom_Distribution__c billCustDist :existingInstallment)
            {
                for(distributionStructure disStructObj :distrubtionMap.values())
                {
                    if(billCustDist.Type__c=='Primary')
                    billCustDist.put(fieldNamesCorrToMonth.get(disStructObj.monthName), disStructObj.primaryAmount.January__c);
                    if(billCustDist.Type__c=='Spouse/Partner')    
                    billCustDist.put(fieldNamesCorrToMonth.get(disStructObj.monthName), disStructObj.spouseAmount.January__c);
                    if(billCustDist.Type__c=='Dependent')
                    billCustDist.put(fieldNamesCorrToMonth.get(disStructObj.monthName), disStructObj.dependentAmount.January__c);    
                }
            }

            Data.upsurt(existingInstallment, Billing_Custom_Distribution__c.Id.getDescribe().getSObjectField(),new Set<String>());
            distributionSuccess = true;
        }
    }

    /**
    * @Description : get all apply dues on member records with passed membership types
    */
    public Map<String, List<Apply_due_on_members__c>> getApplyDueOnMembers(List<String> membershipType)
    {
        List<Apply_due_on_members__c> addedMembersWithPassedType = Data.read('select id,Contact__c, Member_Dues__c, Membership_Type__c from Apply_due_on_members__c where Member_Dues__c=:currentBillingObjId And Membership_Type__c in :membershipType', new Map<String, Object> {'currentBillingObjId'=> currentBillingObj.id, 'membershipType' => membershipType});
        Map<String, List<Apply_due_on_members__c>> mapOfAppMem = new Map<String, List<Apply_due_on_members__c>>();
        for(Apply_due_on_members__c appDueOnMem :addedMembersWithPassedType)
        {
            if(!mapOfAppMem.containsKey(appDueOnMem.Membership_Type__c))
            mapOfAppMem.put(appDueOnMem.Membership_Type__c, new List<Apply_due_on_members__c>());
            mapOfAppMem.get(appDueOnMem.Membership_Type__c).add(appDueOnMem);    
        }
        return mapOfAppMem;
    }

    /**
    * @Description : get all Contact with membership type in passed list 
    */
    public Map<String, List<Contact>> getAllContactsWithPassedMemType(List<String> memTypeList)
    {
        Map<String, List<Contact>> listOfContactsWithMembershipType = new Map<String, List<Contact>>();
        for(Contact conObj :(List<Contact>) Data.read('select id, Membership_Type__c from Contact where Membership_Type__c in:memTypeList AND RecordTypeId=:recTypeId', new Map<String, Object> {'memTypeList'=>memTypeList, 'recTypeId'=>Utility.searchRecordType('Member', 'Contact')}))
        {
            if(listOfContactsWithMembershipType.get(conObj.Membership_Type__c)==null)
            listOfContactsWithMembershipType.put(conObj.Membership_Type__c, new List<Contact>());
            listOfContactsWithMembershipType.get(conObj.Membership_Type__c).add(conObj);
        }
        return listOfContactsWithMembershipType;
    }

    /**
    * @Description : structure to be shown on the front page
    */
    public class distributionStructure
    {
        public String className {get; set;}
        public String monthName {get; set;}
        public Billing_Custom_Distribution__c dependentAmount {get; set;}
        public Billing_Custom_Distribution__c primaryAmount {get; set;}
        public Billing_Custom_Distribution__c spouseAmount {get; set;}

        public distributionStructure(String monthName, String className)
        {
            this.monthName = monthName;
            this.className = className;
            dependentAmount = new Billing_Custom_Distribution__c();
            primaryAmount = new Billing_Custom_Distribution__c();
            spouseAmount = new Billing_Custom_Distribution__c();
        }

        public void setDependentAmount(Decimal amount)
        {
            dependentAmount.January__c = amount;
            System.debug(dependentAmount.January__c);
        }

        public void setPrimaryAmount(Decimal amount)
        {
            primaryAmount.January__c = amount;
        }

        public void setSpouseAmount(Decimal amount)
        {
            spouseAmount.January__c = amount;
        }
    }

    public void selectedDueDetails(){
        if(SelectedDuesForDetails!='none' && SelectedDuesForDetails!=null)
        InitialSetup(SelectedDuesForDetails);
    }

    public void InitialSetup(String dueId)
    {
        distributionSuccess = false;
        isDistributionFailed = false;
        sortedListOfKeys = new List<String>();
        isUpdate = false;
        distrubtionMap = new Map<String, distributionStructure>();
        removedCatString = '';
        allCategories=new List<SelectOption>();
        selectedCategories=new List<SelectOption>();
        currencySymbol = Utility.getcurrencySymbol();

        fiscalMonth=[SELECT FiscalYearStartMonth FROM Organization limit 1].FiscalYearStartMonth;
        
        List<Member_Dues__c> billObj = (List<Member_Dues__c>) Data.read('Select Id, Name, Auto_Apply_On_Membership_Types__c, Primary_Annual_Amount__c, Spouse_Partner_Annual_Amount__c, Dependent_Annual_Amount__c, Default_Billing_Frequency__c, Start_Date__c  from Member_Dues__c where id=:dueId', new Map<String, object> {'dueId' => dueId});
        currentBillingObj = billObj[0];

        Set<string> ExistingCatList = new Set<string>();
        if(currentBillingObj.Auto_Apply_On_Membership_Types__c!=null)
        {
            String[] existingCat=(currentBillingObj.Auto_Apply_On_Membership_Types__c).split(';');
            for(integer i=0;i<existingCat.size();i++)
            {                       
                selectedCategories.add(new SelectOption(existingCat[i],existingCat[i]));
                ExistingCatList.add(existingCat[i]);
            }
        }

        // transfer all selected categories
        removedCategories = selectedCategories.clone();

       // Fetch all the categories from category object to show in left-side of picklist        
       Schema.DescribeFieldResult fieldResult = Contact.Membership_Type__c.getDescribe();  
       List<Schema.PicklistEntry> categoryList = fieldResult.getPicklistValues();
       for(Schema.PicklistEntry category:categoryList)
       {
        if(ExistingCatList!=null && (!ExistingCatList.contains(category.getLabel())))
        {
            allCategories.add(new SelectOption(category.getLabel(),category.getLabel()));
        }
    }

    existingInstallment= Data.read('select id,Total_distributed_amount__c,Member_Dues__c,January__c,February__c,March__c,April__c,May__c,June__c,July__c,August__c,September__c,October__c,November__c,December__c,Type__c from Billing_Custom_Distribution__c where Member_Dues__c=:currentBillingObjId order by Type__c ASC', new Map<String, Object> {'currentBillingObjId' => currentBillingObj.id});       
    if(existingInstallment.size()<1)
    {      
        existingInstallment.add(new Billing_Custom_Distribution__c(Type__c='Dependent', Member_Dues__c=currentBillingObj.id));
        existingInstallment.add(new Billing_Custom_Distribution__c(Type__c='Primary', Member_Dues__c=currentBillingObj.id));
        existingInstallment.add(new Billing_Custom_Distribution__c(Type__c='Spouse/Partner', Member_Dues__c=currentBillingObj.id));                 
    } 
    else if(existingInstallment.size()>0)
    {                       
        isUpdate=true;
    }

            // setup a distribution table to be shown on the page
            List<String> listOfMonths = new List<String> {'January','February','March','April','May','June','July','August','September','October','November','December'};
            fieldNamesCorrToMonth = new Map<String, String>
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

           Integer tempMonth = fiscalMonth - 1;
           Integer currentMonth = Date.today().Month();

           for(Integer i=0; i<12; i++)
           {
            if(tempMonth==12)
            tempMonth = 0;

            sortedListOfKeys.add(listOfMonths.get(tempMonth));    
            if(tempMonth==currentMonth-1)
            distrubtionMap.put(listOfMonths.get(tempMonth), new distributionStructure(listOfMonths.get(tempMonth), ' (CURRENT MONTH)'));  
            else if(tempMonth==fiscalMonth-1)
            distrubtionMap.put(listOfMonths.get(tempMonth), new distributionStructure(listOfMonths.get(tempMonth), ' (FISCAL YEAR START)'));
            else
            distrubtionMap.put(listOfMonths.get(tempMonth), new distributionStructure(listOfMonths.get(tempMonth), ''));
            tempMonth++; 
        }
        for(distributionStructure disStrucObj :distrubtionMap.values())
        {
            disStrucObj.setDependentAmount((Decimal)existingInstallment[0].get(fieldNamesCorrToMonth.get(disStrucObj.monthName)));
            disStrucObj.setPrimaryAmount((Decimal)existingInstallment[1].get(fieldNamesCorrToMonth.get(disStrucObj.monthName)));
            disStrucObj.setSpouseAmount((Decimal)existingInstallment[2].get(fieldNamesCorrToMonth.get(disStrucObj.monthName)));
        }
    }

    public void ApplyDueOnMember()
    {
        List<Apply_due_on_members__c> addSelectedDues=new List<Apply_due_on_members__c>();
        List<Apply_due_on_members__c> todeleteList = Data.read('select id from Apply_due_on_members__c where Contact__c=:memId', new Map<String, object> {'memId' => memberId});
        Data.remove(todeleteList);
        for(SelectOption due:duesListOnThisMember)
        {
        Apply_due_on_members__c member=new Apply_due_on_members__c();
        member.Member_Dues__c=due.getValue();
        member.Contact__c=memberId;           
        addSelectedDues.add(member);
        }
        if(addSelectedDues!=null)
        {
            Data.create(addSelectedDues);
        }

        duesListOnThisMemberForDetail = getSelectDueList(duesListOnThisMember);

        // check if some due is removed from selected dues then hide the distribution table if that due was selected to display
        for(SelectOption availavleDuesObj :allAvailableActiveDues)
        {
            if(availavleDuesObj.getValue()==SelectedDuesForDetails)
                SelectedDuesForDetails = 'none';
        }
    }

    public List<SelectOption> getSelectDueList(List<SelectOption> selectedDues)
    {
        List<SelectOption> dueListToReturn = new List<SelectOption>();
        if(duesListOnThisMember.size()>0)
        {
           dueListToReturn.addAll(duesListOnThisMember);
           dueListToReturn.add(0,new SelectOption('none','-None-'));
        } 
        else
        {     
           dueListToReturn.add(new SelectOption('none','-None-'));       
        }
        return dueListToReturn;
    }
}