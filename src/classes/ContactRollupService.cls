public class ContactRollupService {
     /****
    Method is to update Account Balance in Contact Object.
    ****/
    public static void updateContactWithAccountBalance(List<Id> contactIds) {
        try {
            List<Contact> contactsListToUpdate = new List<Contact>();
            if(contactIds != null && !contactIds.isEmpty() ) {
                AggregateResult[] transactionBillToAmountResults = Data.read('SELECT Bill_To_Member__c, Sum(Amount_Remaining_formatted__c) remainingSum '
                                                                                + 'FROM TXN__c '
                                                                                + 'WHERE Bill_To_Member__c IN :contactIds Group by Bill_To_Member__c',
                                                                                new Map<String, Object>{'contactIds' => contactIds}
                                                                            );
                        
                for (AggregateResult billToIdAmountRemainingSum : transactionBillToAmountResults)  {
                    if(billToIdAmountRemainingSum.get('Bill_To_Member__c') != null) {
                        Contact contact_Ex = new Contact();
                        contact_Ex.Id = String.valueOf(billToIdAmountRemainingSum.get('Bill_To_Member__c'));
                        if(billToIdAmountRemainingSum.get('remainingSum') != null) {
                            contact_Ex.Account_Balance__c = decimal.valueOf(String.valueOf(billToIdAmountRemainingSum.get('remainingSum')));
                            contactsListToUpdate.add(contact_Ex);
                        }
                    }
                }
            }
            if(!contactsListToUpdate.isEmpty()) {
                data.modify(contactsListToUpdate);
            }
        }Catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}