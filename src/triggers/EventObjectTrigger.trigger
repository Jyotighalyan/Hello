trigger EventObjectTrigger on Event__c (after insert, after update, before delete) {
    if (checkRecursive.runOnce()) {
    //triggered after an Event update
        if (trigger.isUpdate) {
            EventObjectTriggerHandler.EventStatusCheckOnUpdate(trigger.NewMap, trigger.OldMap);
        }
    }
    if (trigger.isDelete) {
        EventObjectTriggerHandler.EventStatusCheckBeforeDelete(trigger.old);
    }
    
    //after events
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        String eventAction = 'Insert';
        if(Trigger.isUpdate)
        {
            if (checkRecursive.runAfterUpdateOnce()) {
                eventAction = 'Update';
                if(Trigger.new.get(0).Location__c!=Trigger.old.get(0).Location__c)
                EventObjectTriggerHandler.createUnavailableReservation(new List<Event__c> {Trigger.new.get(0)}, trigger.OldMap, eventAction); 
                EventObjectTriggerHandler.TaxExemptTrueForLineItemsWhileMakingEventTotalTransTrue(trigger.New, trigger.OldMap); 
            }
        }
        else
        {
            EventObjectTriggerHandler.createUnavailableReservation(new List<Event__c> {Trigger.new.get(0)}, trigger.OldMap, eventAction);
        }  
    }   
}