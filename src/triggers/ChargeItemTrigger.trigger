trigger ChargeItemTrigger on Charge_Item__c (before insert, before update) 
{
	if(Trigger.isInsert)
		ChargeItemTriggerHandler.handleBeforeInsert(Trigger.new);
	else if(Trigger.isUpdate)
		ChargeItemTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
}