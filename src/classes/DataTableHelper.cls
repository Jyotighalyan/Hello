public with sharing class DataTableHelper{
 
    Public Integer noOfRecords{get; set;}
    Public Integer size{get;set;}
    Public Integer start{get;set;}
    string queryString;
    public ApexPages.StandardSetController setCon {get;set;}
 
    public DataTableHelper(){
       
    }
 
 
    public string dataTableJson {get;set;}
     
    public void processData(){
        DataTableWrapper datawrap;
        List<sobject> contactList = new List<sobject>();
        if(ApexPages.currentPage().getParameters().get('FromPage')=='\'Dues\''){
    	String dueId = ApexPages.currentPage().getParameters().get('dueId');
    	String billMonth = ApexPages.currentPage().getParameters().get('billingMonth');
    	String postDate = ApexPages.currentPage().getParameters().get('dueDate');
    	List<Dues_Summary__c> dueSumm = Data.read('Select Id from Dues_Summary__c where Member_Dues__c=:dueId AND Billing_Period__c=:monthName AND Post_Date__c=:postDate AND Posted__c=:postStatus AND RecordTypeId=:recId',
        	new Map<String, Object> {'dueId' => dueId,
        							 'monthName' => billMonth,
        							 'postDate' => 	Date.valueOf(postDate),
        							 'postStatus' => false,
        							 'recId' => Utility.searchRecordType('Due Summary','Dues_Summary__c')
        							 });

        queryString = 'select Contact__r.Name, Contact__r.Customer_Id__c, Contact__r.Relationship__c, Contact__r.Membership_Type__c , Amount__c, Tax_Amount__c, Total_Amount__c from Dues_Summary__c where Due_Summary__c=\''+dueSumm[0].id+'\'';
        string searchKey = ApexPages.currentPage().getParameters().get('search[value]');
        if(searchKey != null && searchKey != '' && searchKey.trim().length() > 0){
            queryString += ' AND Contact__r.Name like \'%'+String.escapeSingleQuotes(searchKey)+'%\''; 
        } 
        integer i = 0;
        String str = 'order[0][column]';
        //set order by clause , this code is assume that the sorting is on only one field but this can modified accordingly
        //also set direction from order[0][dir] parameter. note: we are taking 0th element as we have assume only one sorting
        if(ApexPages.currentPage().getParameters().get('columns['+ApexPages.currentPage().getParameters().get(str) + '][data]')!='null')
        queryString += ' order by ' + String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('columns['+ApexPages.currentPage().getParameters().get(str) + '][data]')) + ' ' + 
                                String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('order[0][dir]'));
       
        //get starting record number for current view, this parametter will be send by datatable js
        start= Integer.valueOf(ApexPages.currentPage().getParameters().get('start'));
        //current number of records per page, it is also in avilable in get request
        size = Integer.valueOf(ApexPages.currentPage().getParameters().get('length'));
        queryString += ' limit '+size+' OFFSET '+start;
        noOfRecords= [select Count() from Dues_Summary__c where Due_Summary__c=:String.escapeSingleQuotes(dueSumm[0].id) limit 50000];
        //set pagenumber
        contactList = Database.query(queryString);
        }
        else if(ApexPages.currentPage().getParameters().get('FromPage')=='\'Statements\''){
            String stmtId = ApexPages.currentPage().getParameters().get('stmtId');
            String countQuery = 'Select count(Id) c from Statements__c where RecordTypeId=:recId And Statement__c=:stmtId';
            String membershipTypes = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('memTypes'));
            String fromMemId = ApexPages.currentPage().getParameters().get('fromMemId');
            String toMemId = ApexPages.currentPage().getParameters().get('toMemId');
            string searchKey = ApexPages.currentPage().getParameters().get('search[value]');
            queryString = 'Select Name, Billing_Period__c, Member__r.Name, Member__r.Relationship__c, Member__r.Customer_Id__c, Member__r.Membership_Type__c, Statement_Balance__c from Statements__c where RecordTypeId=:recId And Statement__c=:stmtId';
            
            Map<String, Object> queryMap = new Map<String, Object> {'recId' => Utility.searchRecordType('Member Statement','Statements__c'), 'stmtId' => stmtId};

            List<String> membershipTypesList = new List<String>();
            if(membershipTypes!='' && membershipTypes!='null'){
                for(String types : membershipTypes.split(',')){
                    membershipTypesList.add(types);
                }
                queryString += ' AND Member__r.Membership_Type__c in :memberTypes';
                countQuery+= ' AND Member__r.Membership_Type__c in :memberTypes';
                queryMap.put('memberTypes',membershipTypesList);
            }
            if(searchKey != null && searchKey != '' && searchKey.trim().length() > 0){
                queryString += ' AND Member__r.Name like \'%'+String.escapeSingleQuotes(searchKey)+'%\''; 
            }
            String str = 'order[0][column]'; 
            if(ApexPages.currentPage().getParameters().get('columns['+ApexPages.currentPage().getParameters().get(str) + '][data]')!='null')
            queryString += ' order by ' + String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('columns['+ApexPages.currentPage().getParameters().get(str) + '][data]')) + ' ' + 
                                String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('order[0][dir]'));

           

            Integer memIdFrom;
            Integer memIdTo;
            if(ApexPages.currentPage().getParameters().get('fromMemId')!=''){
                memIdFrom = Integer.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('fromMemId')));
            }
            if(ApexPages.currentPage().getParameters().get('toMemId')!=''){
                memIdTo = Integer.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('toMemId')));
            }
            start= Integer.valueOf(ApexPages.currentPage().getParameters().get('start'));
            //current number of records per page, it is also in avilable in get request
            size = Integer.valueOf(ApexPages.currentPage().getParameters().get('length'));
            if(memIdFrom>0 || memIdTo>0){
                List<Statements__c> stmntsInMembersIdRange = new List<Statements__c>(); 
                for(Statements__c memberOne :(List<Statements__c>)Data.read(queryString, queryMap))
                {
                    String memId = '';
                    for(Integer i=0; i<memberOne.Member__r.Customer_Id__c.length(); i++)
                    {
                        Integer charAsciiCode = memberOne.Member__r.Customer_Id__c.charAt(i);
                        if((charAsciiCode>=48 && charAsciiCode<=57) || charAsciiCode==32){
                            memId += String.fromCharArray( new List<integer> { charAsciiCode } );
                        }
                        else{
                            break;
                        }
                    }
                    try{
                        Integer memIdInt = Integer.valueOf(memId);
                        if(memIdFrom<memIdTo){
                            if(memIdInt>=memIdFrom && memIdInt<=memIdTo){
                                stmntsInMembersIdRange.add(memberOne);
                            }
                        }
                        else{
                            if(memIdInt<=memIdFrom && memIdInt>=memIdTo){
                                stmntsInMembersIdRange.add(memberOne);
                            }
                        }
                    }
                    catch(Exception ex)
                    {
                        continue;
                    }
                }
                noOfRecords = stmntsInMembersIdRange.size();
                for(Integer i=start; i<start+size; i++){
                    if(i<noOfRecords){
                        contactList.add(stmntsInMembersIdRange[i]);
                    }
                }
            }
            else{
                queryString += ' limit '+size+' OFFSET '+start;
                noOfRecords= Integer.valueOf(Data.read(countQuery, queryMap)[0].get('c'));
                contactList = Data.read(queryString, queryMap);
            }
        }        
         //create wrapper
        datawrap = new DataTableWrapper(0,noOfRecords,noOfRecords,contactList );
        dataTableJson = JSON.serialize(datawrap);         
    }
    public class DataTableWrapper{
        public Integer draw;
        public Integer recordsTotal;
        public Integer recordsFiltered;
        public List<sobject> data;
        public DataTableWrapper(Integer draw,Integer recordsTotal,Integer recordsFiltered,list<SObject> data){
            this.draw = draw;
            this.recordsTotal = recordsTotal;
            this.recordsFiltered = recordsFiltered ;
            this.data = data;
        }
    }
}