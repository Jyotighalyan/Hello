trigger GuestPassTrigger on Guest_Pass__c (before insert, after insert, before update, after update) {

    if(Trigger.isInsert) {
        if (Trigger.isBefore) GuestPassTriggerHandler.GuestPassValidation(Trigger.new, null);
        else if (Trigger.isAfter) {
            GuestPassSchedule gs = new GuestPassSchedule();
            gs.execute(null);
        }
    } else if(Trigger.isUpdate) {
        if (Trigger.isBefore) GuestPassTriggerHandler.GuestPassValidation(Trigger.new, Trigger.old);
		//GuestPassSchedule gs = new GuestPassSchedule();
		//gs.execute(null);
        else if (!GuestPassTriggerHandler.isProcessed && Trigger.isAfter) GuestPassTriggerHandler.GuestPassProcessingOnUpdate(Trigger.new, Trigger.oldMap); 
    }

}