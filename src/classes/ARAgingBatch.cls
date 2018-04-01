global class ARAgingBatch implements Database.Batchable<sObject> {
	
	@TestVisible
	private Date effectiveDate;
	
	global ARAgingBatch(Date effectiveDate) {
		this.effectiveDate = effectiveDate;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Data.Locator('Select Id from Contact', 
			new Map<String, Object>());
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		Set<Id> memberIds = new Set<Id>();
   		List<Contact> conListToBeUpdated = new List<Contact>();

   		for(sObject memObj : scope){
   			memberIds.add(memObj.id);
   		}
		Map<Id, Contact> consMap = new Map<Id, Contact>((List<Contact>)Data.read('Select Id, Last_Aging_Effective_Date_Dev__c, X0_30_Days__c, X120_days__c, X31_60_Days__c, X61_90_Days__c, X91_120_Days__c from Contact where id in :memId',
			new Map<String, Object> {'memId' => memberIds}));

		//prepare the dates
		Date days30 = effectiveDate.addDays(-30);
		Date days31 = effectiveDate.addDays(-31);
		Date days60 = effectiveDate.addDays(-60);
		Date days61 = effectiveDate.addDays(-61);
		Date days90 = effectiveDate.addDays(-90);
		Date days91 = effectiveDate.addDays(-91);
		Date days120 = effectiveDate.addDays(-120);

		Set<Id> recIds = new Set<Id> {Utility.searchRecordType('Taxes', 'TXN__c'), Utility.searchRecordType('Service Charges', 'TXN__c')};
		Map<Id, Map<String, Decimal>> contactAndAgingMap = new Map<Id, Map<String, Decimal>>();

		/**
		* @Description : sum of txns in 1st month
		*/
		for(AggregateResult month1Ag : (List<AggregateResult>) Data.read('Select SUM(Amount__c) amount, Bill_To_Member__c from TXN__c where RecordTypeId !=:depRecId AND (Date__c<=:effectiveDate OR (RecordTypeId in :recIds AND Related_To__r.Date__c<=:effectiveDate)) AND (Date__c>=:days30 OR (RecordTypeId in :recIds AND Related_To__r.Date__c>=:days30)) AND Bill_To_Member__c in :memId group by Bill_To_Member__c',
			new Map<String, Object> {'memId' => memberIds,
									 'effectiveDate' => effectiveDate,
									 'recIds' => recIds,
									 'depRecId' => Utility.searchRecordType('Deposit', 'TXN__c'),
									 'days30' => days30
			})){
			contactAndAgingMap.put((Id)month1Ag.get('Bill_To_Member__c'), new Map<String, Decimal> {'month1'=> (Decimal)month1Ag.get('amount')});
		}

		/**
		* @Description : sum of txns in 2nd month
		*/
		for(AggregateResult month2Ag : (List<AggregateResult>) Data.read('Select SUM(Amount__c) amount, Bill_To_Member__c from TXN__c where RecordTypeId !=:depRecId AND (Date__c<=:days31 OR (RecordTypeId in :recIds AND Related_To__r.Date__c<=:days31)) AND (Date__c>=:days60 OR (RecordTypeId in :recIds AND Related_To__r.Date__c>=:days60)) AND Bill_To_Member__c in :memId group by Bill_To_Member__c',
			new Map<String, Object> {'memId' => memberIds,
									 'days31' => days31,
									 'recIds' => recIds,
									 'depRecId' => Utility.searchRecordType('Deposit', 'TXN__c'),
									 'days60' => days60
			})){
			if(contactAndAgingMap.containsKey((Id)month2Ag.get('Bill_To_Member__c'))){
				contactAndAgingMap.get((Id)month2Ag.get('Bill_To_Member__c')).put('month2', (Decimal)month2Ag.get('amount'));
			}
			else{
				contactAndAgingMap.put((Id)month2Ag.get('Bill_To_Member__c'), new Map<String, Decimal> {'month2'=> (Decimal)month2Ag.get('amount')});
			}
		}

		/**
		* @Description : sum of txns in 3rd month
		*/
		for(AggregateResult month2Ag : (List<AggregateResult>) Data.read('Select SUM(Amount__c) amount, Bill_To_Member__c from TXN__c where RecordTypeId !=:depRecId AND (Date__c<=:days61 OR (RecordTypeId in :recIds AND Related_To__r.Date__c<=:days61)) AND (Date__c>=:days90 OR (RecordTypeId in :recIds AND Related_To__r.Date__c>=:days90)) AND  Bill_To_Member__c in :memId group by Bill_To_Member__c',
			new Map<String, Object> {'memId' => memberIds,
									 'days61' => days61,
									 'recIds' => recIds,
									 'depRecId' => Utility.searchRecordType('Deposit', 'TXN__c'),
									 'days90' => days90
			})){
			if(contactAndAgingMap.containsKey((Id)month2Ag.get('Bill_To_Member__c'))){
				contactAndAgingMap.get((Id)month2Ag.get('Bill_To_Member__c')).put('month3', (Decimal)month2Ag.get('amount'));
			}
			else{
				contactAndAgingMap.put((Id)month2Ag.get('Bill_To_Member__c'), new Map<String, Decimal> {'month3'=> (Decimal)month2Ag.get('amount')});
			}
		}

		/**
		* @Description : sum of txns in 4th month
		*/
		for(AggregateResult month2Ag : (List<AggregateResult>) Data.read('Select SUM(Amount__c) amount, Bill_To_Member__c from TXN__c where RecordTypeId !=:depRecId AND (Date__c<=:days91 OR (RecordTypeId in :recIds AND Related_To__r.Date__c<=:days91)) AND (Date__c>=:days120 OR (RecordTypeId in :recIds AND Related_To__r.Date__c>=:days120)) AND Bill_To_Member__c in :memId group by Bill_To_Member__c',
			new Map<String, Object> {'memId' => memberIds,
									 'days91' => days91,
									 'recIds' => recIds,
									 'depRecId' => Utility.searchRecordType('Deposit', 'TXN__c'),
									 'days120' => days120
			})){
			if(contactAndAgingMap.containsKey((Id)month2Ag.get('Bill_To_Member__c'))){
				contactAndAgingMap.get((Id)month2Ag.get('Bill_To_Member__c')).put('month4', (Decimal)month2Ag.get('amount'));
			}
			else{
				contactAndAgingMap.put((Id)month2Ag.get('Bill_To_Member__c'), new Map<String, Decimal> {'month4'=> (Decimal)month2Ag.get('amount')});
			}
		}

		/**
		* @Description : sum of txns in 5th month
		*/
		for(AggregateResult month2Ag : (List<AggregateResult>) Data.read('Select SUM(Amount__c) amount, Bill_To_Member__c from TXN__c where RecordTypeId !=:depRecId AND (Date__c<:days120 OR (RecordTypeId in :recIds AND Related_To__r.Date__c<:days120)) AND Bill_To_Member__c in :memId group by Bill_To_Member__c',
			new Map<String, Object> {'memId' => memberIds,
									 'recIds' => recIds,
									 'depRecId' => Utility.searchRecordType('Deposit', 'TXN__c'),
									 'days120' => days120
			})){
			if(contactAndAgingMap.containsKey((Id)month2Ag.get('Bill_To_Member__c'))){
				contactAndAgingMap.get((Id)month2Ag.get('Bill_To_Member__c')).put('month5', (Decimal)month2Ag.get('amount'));
			}
			else{
				contactAndAgingMap.put((Id)month2Ag.get('Bill_To_Member__c'), new Map<String, Decimal> {'month5'=> (Decimal)month2Ag.get('amount')});
			}
		}

		for(Id memberIdOne : consMap.keySet()){
			Contact member = consMap.get(memberIdOne);
			member.Last_Aging_Effective_Date_Dev__c = effectiveDate;
			member.X0_30_Days__c = 0;
			member.X31_60_Days__c = 0;
			member.X61_90_Days__c = 0;
			member.X91_120_Days__c = 0;
			member.X120_days__c = 0;
			if(contactAndAgingMap.containsKey(memberIdOne)){
				if(contactAndAgingMap.get(memberIdOne).containsKey('month1')){
					member.X0_30_Days__c = contactAndAgingMap.get(memberIdOne).get('month1');
				}
				if(contactAndAgingMap.get(memberIdOne).containsKey('month2')){
					member.X31_60_Days__c = contactAndAgingMap.get(memberIdOne).get('month2');
				}
				if(contactAndAgingMap.get(memberIdOne).containsKey('month3')){
					member.X61_90_Days__c = contactAndAgingMap.get(memberIdOne).get('month3');
				}
				if(contactAndAgingMap.get(memberIdOne).containsKey('month4')){
					member.X91_120_Days__c = contactAndAgingMap.get(memberIdOne).get('month4');
				}
				if(contactAndAgingMap.get(memberIdOne).containsKey('month5')){
					member.X120_days__c = contactAndAgingMap.get(memberIdOne).get('month5');
				}
			}
			// add to updating list
			conListToBeUpdated.add(member);
		}
		Data.modify(conListToBeUpdated);
	}
	
	global void finish(Database.BatchableContext BC) {
		AsyncApexJob a = (AsyncApexJob) Data.read('Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email, ExtendedStatus from AsyncApexJob where Id = :jobId', new Map<String, Object> {'jobId' => BC.getJobId()}).get(0); 
		if(a.TotalJobItems != 0)
		{
			// Send an email to the Apex job's submitter notifying of job completion.                                          
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();         
			String[] toAddresses = new String[] {a.CreatedBy.Email};			
			mail.setToAddresses(toAddresses);
			mail.setSubject('Member Aging Batch ' + a.Status);
			if(a.NumberOfErrors>0){
				mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors 
					+' failures. \n'+a.ExtendedStatus); 
			}
			else{
				mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches (' + ' items) with '+ a.NumberOfErrors 
					+' failures.');
				List<AP_Aging__c> apCust = Data.read('Select Last_Run_Of_Member_Aging__c from AP_Aging__c where Name=:recName', new Map<String, Object> {'recName' => 'Effective Date Record'});
				AP_Aging__c custToUpdate;
				if(apCust.size()>0){
					custToUpdate = apCust[0];
					custToUpdate.Last_Run_Of_Member_Aging__c = effectiveDate;
				}
				else{
					custToUpdate = new AP_Aging__c(Name='Effective Date Record', Last_Run_Of_Member_Aging__c=effectiveDate);
				}
				Data.upsurt(new List<AP_Aging__c> {custToUpdate}, Schema.AP_Aging__c.Id, new Set<String>());
			}
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}
}