public class ScheduleUpdateStatementBatch implements Schedulable
{
    public void execute(SchedulableContext sc)
    {
    	Set<Id> membersIds = new Set<Id>();
        for(AggregateResult ar : (List<AggregateResult>) Data.read('Select count(Id) c, Bill_To_Member__c  from TXN__C where Bill_To_Member__c !=:membersId AND Statement__c=:stmtId AND RecordTypeId not in:recId AND Date__C!=:dte group by Bill_To_Member__c',
			new Map<String, Object> {'membersId' => null,
									 'stmtId' => null,
									 'dte' => null,
									 'recId' => new List<String> {Utility.searchRecordType('Deposit', 'TXN__C'), Utility.searchRecordType('Taxes', 'TXN__C'), Utility.searchRecordType('Service Charges', 'TXN__C')}
			}))
		{
			if(Integer.valueOf(ar.get('c'))>0){
				membersIds.add(String.valueOf(ar.get('Bill_To_Member__c')));
			}
		}

		if(membersIds.size()>0){
			List<AggregateResult> arL = (List<AggregateResult>) Data.read('Select MIN(Date__C) d from TXN__C where Bill_To_Member__c in :membersId AND Statement__c=:stmtId AND RecordTypeId not in:recId AND Date__C!=:dte',
			new Map<String, Object> {'membersId' => membersIds,
									 'stmtId' => null,
									 'dte' => null,
									 'recId' => new List<String> {Utility.searchRecordType('Deposit', 'TXN__C'), Utility.searchRecordType('Taxes', 'TXN__C'), Utility.searchRecordType('Service Charges', 'TXN__C')}
									});
			Date minimumDate = Date.valueOf(arL[0].get('d'));

			Map<Id, Statements__c> mapOfStmtSumm = new Map<Id, Statements__c> ();

			List<Statements__c> allStatementSummary = ((List<Statements__c>) Data.read('Select id, Statement__c, Billing_Period__c, Date__c, To_Date__c from Statements__c where RecordtypeId=:recId',
									new Map<String, Object> {'recId' => Utility.searchRecordType('Statement Summary','Statements__c')
								}
			));

			Statements__c latestSumm;
			for(Statements__c stmts : allStatementSummary){
				Boolean isGetRelatedTo = false;
				if(stmts.To_Date__c>=minimumDate){
					mapOfStmtSumm.put(stmts.id, stmts);
				}
				for(Statements__c stmts1 : allStatementSummary){
					if(stmts1.Statement__c==stmts.id){
						isGetRelatedTo = true;
					}
				}
				if(!isGetRelatedTo){
					latestSumm = stmts;
				}
			}
			UpdateStatementsBatch ups = new UpdateStatementsBatch(null, membersIds, mapOfStmtSumm, allStatementSummary, latestSumm);
			Database.executeBatch(ups, 1);
		}
    }
}