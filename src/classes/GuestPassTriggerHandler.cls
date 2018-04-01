public class GuestPassTriggerHandler {
    
    public static Boolean isProcessed = false;
    /**
     * EventStatusValidation Verifies Status on the associated Event and determines whether changes may be made
     * to Event Charge Item records accordingly.
     * @param  records records Event Charge Items being modified.
     */
    public static void GuestPassValidation(List<Guest_Pass__c> records, List<Guest_Pass__c> oldTrigger) {
        Map<Id, String> guestPassErrors = new Map<Id, String>();
        List<Guest_Pass__c> GuestPassesToActivate = new List<Guest_Pass__c>();
        List<Guest_Pass__c> GuestPassesToExpire = new List<Guest_Pass__c>();
        Map<Id, Guest_Pass__c> guestIdsWithPass = new Map<Id, Guest_Pass__c>();
        Map<Id, Guest_Pass__c> oldTriggerGuestIdsWithPass = new Map<Id, Guest_Pass__c>();
        
        for (Guest_Pass__c guestPass : records) guestIdsWithPass.put(guestPass.Guest_Name__c, guestPass);
        
        if (oldTrigger != null) {
            for (Guest_Pass__c guestPass : oldTrigger) oldTriggerGuestIdsWithPass.put(guestPass.Guest_Name__c, guestPass);
        }
        system.debug(guestIdsWithPass);
        for (Contact con : (List<Contact>) Data.read('SELECT Id, Active_Guest_Pass__c, Account_Balance__c, (SELECT id, Active__c FROM Guest_Passes1__r) FROM Contact WHERE ID IN :guestIdsWithPasskeySet',
                                                        new Map<String, Object> {
                                                            'guestIdsWithPasskeySet' => guestIdsWithPass.keySet()
                                                        })) {
            Guest_Pass__c gp = guestIdsWithPass.get(con.id);
            boolean hasGuestPassActive = false;
            system.debug(con);
            for (Guest_Pass__c allGPs : con.Guest_Passes1__r) {
                system.debug(allGPs);
                if (allGPs.Active__c == true) hasGuestPassActive = true;
            }
            if ((oldTrigger == null || (oldTrigger != null && oldTriggerGuestIdsWithPass.get(con.id).Active__c != gp.Active__c)) && gp.Active__c == true && hasGuestPassActive == true) {

                guestPassErrors.put(gp.Id, 'Current_Guest_Pass');

            } else if (gp.Active__c == true && con.Account_Balance__c != 0 && con.Account_Balance__c != null) {

                guestPassErrors.put(gp.Id, 'Non_Zero_Balance');

            } 
        }

        for (Guest_Pass__c record : records) {
            if (guestPassErrors.containsKey(record.Id)) {
                if ('Current_Guest_Pass'.equals(guestPassErrors.get(record.Id))) {
                    record.AddError('Guest Pass not activated. Guests can only have one active guest pass at a time.');
                } else if ('Non_Zero_Balance'.equals(guestPassErrors.get(record.Id))) {
                    //record.AddError('Guest Pass not activated. Account balance must be $0 in order to activate a new guest pass.');
                }
            }
        }

    }
    
    public static void GuestPassProcessingOnUpdate(List<Guest_Pass__c> records, Map<Id, Guest_Pass__c> oldTriggerMap) {
        GuestPassSchedule gs = new GuestPassSchedule();
        List<Guest_Pass__c> GuestPassesToActivate = new List<Guest_Pass__c>();
        List<Guest_Pass__c> GuestPassesToExpire = new List<Guest_Pass__c>();
        List<Contact> onlyContactUpdates = new List<Contact>();
        Map<Id, Guest_Pass__c> oldTriggerGuestIdsWithPass = new Map<Id, Guest_Pass__c>();
        //for (Guest_Pass__c GP : records) {
        /*if (oldTriggerMap != null) {
            for (Guest_Pass__c guestPass : oldTrigger) oldTriggerGuestIdsWithPass.put(guestPass.Guest_Name__c, guestPass);
        }*/
        for (Guest_Pass__c GP : (List<Guest_Pass__c>) Data.read('SELECT Id, Active__c,Bill_Charges_to_Members_Account__c, Expiration__c, Start__c, Member_Sponsor__c,Guest_Name__c, Guest_Name__r.Name FROM Guest_Pass__c',
                                                            new Map<String, Object> {
                                                               
                                                            })) {
            //system.debug('oldTrigger : ' + oldTrigger + 'map: ' + oldTriggerGuestIdsWithPass);
            if (GP.Active__c == false && GP.Start__c <= (DateTime.now() + (0.5/24)) && GP.Expiration__c >= (DateTime.now() + (0.5/24))) {
                GuestPassesToActivate.add(GP);
            } else if (GP.Active__c == true && GP.Expiration__c <= (DateTime.now() + (0.5/24))) {
                GuestPassesToExpire.add(GP);
            } else if (oldTriggerMap.get(GP.Id) != null && oldTriggerMap.get(GP.Id).Bill_Charges_to_Members_Account__c != gp.Bill_Charges_to_Members_Account__c) {
                if (gp.Bill_Charges_to_Members_Account__c == true) GP.Guest_Name__r.Bill_To_Member__c = GP.Member_Sponsor__c;
                else GP.Guest_Name__r.Bill_To_Member__c = null;
                
        		onlyContactUpdates.add(GP.Guest_Name__r);
            }
        }
        if (onlyContactUpdates.size() > 0) Data.modify(onlyContactUpdates);
        if (GuestPassesToActivate.size() > 0 && !isProcessed) GuestPassActivation(GuestPassesToActivate);
        if (GuestPassesToExpire.size() > 0 && !isProcessed) GuestPassExpiration(GuestPassesToExpire);
    }
    
	 public static void GuestPassActivation(List<Guest_Pass__c> GuestPassesToActivate) {
        
        List<Guest_Pass__c> GuestPassesToUpdate = new List<Guest_Pass__c>();
        List<Contact> guestToUpdate = new List<Contact>();
       
        for (Guest_Pass__c GP : GuestPassesToActivate) {
            GP.Active__c = true;
            GP.Guest_Name__r.Active_Guest_Pass__c = true;
            if(GP.Bill_Charges_to_Members_Account__c == true) {
                GP.Guest_Name__r.Bill_To_Member__c = GP.Member_Sponsor__c;
            }
            system.debug(GP.Bill_Charges_to_Members_Account__c);
            guestToUpdate.add(GP.Guest_Name__r);
            GuestPassesToUpdate.add(GP);
        }
        isProcessed = true;
        Data.Modify(GuestPassesToUpdate);
        Data.Modify(guestToUpdate);
    }
    
    public static void GuestPassExpiration(List<Guest_Pass__c> GuestPassesToExpire) {
        
        List<Guest_Pass__c> GuestPassesToUpdate = new List<Guest_Pass__c>();
        List<Contact> guestToUpdate = new List<Contact>();
        
        for (Guest_Pass__c GP : GuestPassesToExpire) {
            GP.Active__c = false;
            GP.Guest_Name__r.Active_Guest_Pass__c = false;
            GP.Guest_Name__r.Bill_To_Member__c = null;
            GuestPassesToUpdate.add(GP);
            guestToUpdate.add(GP.Guest_Name__r);
        }
        isProcessed = true;
        Data.Modify(GuestPassesToUpdate);
        Data.Modify(guestToUpdate);
    }

}