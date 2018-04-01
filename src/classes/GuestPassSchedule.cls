global with sharing class  GuestPassSchedule implements Schedulable {
   global void execute(SchedulableContext SC) {
       List<Guest_Pass__c> GuestPassesToActivate = new List<Guest_Pass__c>();
       List<Guest_Pass__c> GuestPassesToExpire = new List<Guest_Pass__c>();
       
       for (Guest_Pass__c GP :(List<Guest_Pass__c>) Data.read('SELECT Id, Active__c,Bill_Charges_to_Members_Account__c, Expiration__c, Start__c, Member_Sponsor__c,Guest_Name__c, Guest_Name__r.Name FROM Guest_Pass__c',
                                                            new Map<String, Object> {
                                                               
                                                            })) {
           if (GP.Active__c == false && GP.Start__c <= (DateTime.now() + (0.5/24)) && GP.Expiration__c >= (DateTime.now() + (0.5/24))) {
               GuestPassesToActivate.add(GP);
           } else if (GP.Active__c == true && GP.Expiration__c <= (DateTime.now() + (0.5/24))) {
               GuestPassesToExpire.add(GP);
           }
       }
       
       if (GuestPassesToActivate.size() > 0) GuestPassActivation(GuestPassesToActivate);
       if (GuestPassesToExpire.size() > 0) GuestPassExpiration(GuestPassesToExpire);
       
   }
    
    public void GuestPassActivation(List<Guest_Pass__c> GuestPassesToActivate) {
        
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
        Data.Modify(GuestPassesToUpdate);
        Data.Modify(guestToUpdate);
    }
    
    public void GuestPassExpiration(List<Guest_Pass__c> GuestPassesToExpire) {
        
        List<Guest_Pass__c> GuestPassesToUpdate = new List<Guest_Pass__c>();
        List<Contact> guestToUpdate = new List<Contact>();
        
        for (Guest_Pass__c GP : GuestPassesToExpire) {
            GP.Active__c = false;
            GP.Guest_Name__r.Active_Guest_Pass__c = false;
            GP.Guest_Name__r.Bill_To_Member__c = null;
            GuestPassesToUpdate.add(GP);
            guestToUpdate.add(GP.Guest_Name__r);
        }
        Data.Modify(GuestPassesToUpdate);
        Data.Modify(guestToUpdate);
    }
}