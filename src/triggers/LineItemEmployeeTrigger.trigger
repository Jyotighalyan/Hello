/**
* Trigger on changes to the Line_Item_Employee__c object.
*/
trigger LineItemEmployeeTrigger on Line_Item_Employee__c (before insert, before update, after insert) {
    
    
    if(Trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            LineItemEmployeeTriggerHandler.OnBeforeInsert(trigger.new);
            
        }
        if(trigger.isUpdate)
        {
            LineItemEmployeeTriggerHandler.OnBeforeUpdate(trigger.new, trigger.oldmap);
        }
    }
}