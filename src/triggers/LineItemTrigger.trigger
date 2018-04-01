/**
 * Trigger on changes to the Line_Item__c object.
 */
trigger LineItemTrigger on Line_Item__c (after insert, after update, after delete, before update, before delete, before insert) {
    if(Trigger.isBefore){
        
        if(Trigger.isUpdate){
            LineItemTriggerHandler.OnBeforeUpdate(trigger.new);
        }
        if(Trigger.isDelete){
            LineItemTriggerHandler.OnBeforeDelete(trigger.old);
        } 
        if(Trigger.isInsert){
            LineItemTriggerHandler.OnBeforeInsert(trigger.new);
        }               
    }

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            LineItemTriggerHandler.OnAfterInsert(trigger.newMap);
            LineItemTriggerHandler.postSetup(Trigger.new.get(0).Reservation_line__c);            
        }
        if(Trigger.isUpdate)
        {
            LineItemTriggerHandler.postSetup(Trigger.new.get(0).Reservation_line__c);
        }
        if(Trigger.isDelete)
        {
            LineItemTriggerHandler.postSetup(Trigger.old.get(0).Reservation_line__c);
        }        
    }
}