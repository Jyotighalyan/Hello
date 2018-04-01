public with sharing class ChargeItemTriggerHandler 
{
	public static void handleBeforeInsert(List<Charge_Item__c> newCharges)
	{
		ChargeItemTriggerHandler.checkTypeAndSubType(newCharges, 'creating');
	}

	public static void handleBeforeUpdate(List<Charge_Item__c> newCharges, Map<Id, Charge_Item__c> oldMap)
	{
		ChargeItemTriggerHandler.checkTypeAndSubType(newCharges, 'updating');
	}

	private static void checkTypeAndSubType(List<Charge_Item__c> newCharges, String callType)
	{
		List<TxnChargeToTaxMapping__c> mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
            'SELECT Id, Name, Type__c, SubType__c FROM TxnChargeToTaxMapping__c ',
            new Map<String, Object> {}
        );

        for(Charge_Item__c charge : newCharges)
        {
        	if(!ChargeItemTriggerHandler.areTypeAndSubValid(charge, mappings))
        		charge.addError('Type and Subtype are not mapped. Please map the combination before '+callType+' the record');
        }
	}

	private static Boolean areTypeAndSubValid(Charge_Item__c charge, List<TxnChargeToTaxMapping__c> mappings)
	{
		for(TxnChargeToTaxMapping__c tcm : mappings)
		{
			if(tcm.Type__c == charge.Type__c)
			{
				if(charge.SubType__c == null && tcm.Subtype__c == null)
					return true; // Type matched, no Sub, so we're good
				else if(charge.SubType__c!=null && tcm.SubType__c == charge.SubType__c)
					return true; // Type matched, Subs matched, so we're good
			}
		}

		return false;
	}
}