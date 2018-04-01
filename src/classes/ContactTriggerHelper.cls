/*************************
@Name:ContactTrigger
@Author:Venkat Neteesh
@description:class is to maintain one primary contact for single account
*************************/
public class ContactTriggerHelper {

    public static void checkPrimaryContactExists( List<Contact> contacts_newList,List<Contact> contacts_oldList,Map<Id,Contact> contactsOldMap) {
        Map<Id,List<Contact>> existingPrimaryContactsMap = new Map<Id,List<Contact>>();
        Set<Id> accountIdsSet = new Set<Id>();
        Set<Id> contactIdsSet = new Set<Id>();
        Id memberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        for(Contact con : contacts_newList) {
            if( con.accountId != null && con.recordTypeId == memberRecordTypeId && (Trigger.isInsert && con.Relationship__c == 'Primary') || (Trigger.isUpdate && con.Relationship__c == 'Primary' && contactsOldMap.get(con.Id).Relationship__c != con.Relationship__c) ) {
                accountIdsSet.add(con.AccountId);
                contactIdsSet.add(con.Id);
            }
        }
        if(!accountIdsSet.isEmpty()) {
            List<Contact> existing_primaryContactsList = Data.read('select id,name,accountId from contact where accountid in : accountIdsSet and Relationship__c = \'Primary\' And recordTypeId =: memberRecordTypeId AND ID NOT IN : contactIdsSet', new Map<String,Object> {'accountIdsSet'=>accountIdsSet,'memberRecordTypeId'=>memberRecordTypeId,'contactIdsSet'=>contactIdsSet});
            for(Contact contact_exist : existing_primaryContactsList ){
                //System.debug('contact_exist.Id===>'+contact_exist.Id);
                if(!existingPrimaryContactsMap.containsKey(contact_exist.AccountId)) {
                    List<Contact> conExList = new List<Contact>();
                    conExList.add(contact_exist);
                    existingPrimaryContactsMap.put(contact_exist.AccountId,conExList);
                }
            }
        }
        
        for(Contact con : contacts_newList) {
            if(con.Relationship__c == 'Primary' && existingPrimaryContactsMap.get(con.accountId) != null && !existingPrimaryContactsMap.get(con.accountId).isEmpty()) {
                con.addError('You cannot have multiple primary contacts for one account');
            }
            if(con.recordTypeId == memberRecordTypeId && con.Hold_Dues__c && con.Hold_Dues_Reason__c==null)
            {
                con.Hold_Dues_Reason__c.addError('Hold Dues Reason is required.');
            }
        }
    }
}
