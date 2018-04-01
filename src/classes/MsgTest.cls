@isTest
public class MsgTest {
	private static Boolean isNotSetup = true; // Used to determine if the setup method has been called by other setups

	@TestSetup
	public static void setup() {
		if (isNotSetup) {

			List<Account> acctsToSetup = new List<Account>();
			for (Integer i=0; i<200; i++) {
				acctsToSetup.add(
					new Account(
						Name = 'Test Customer Account: ' + i,
						Website = 'https://test.sample.com/' + i
					)
				);
			}
			insert acctsToSetup;

			List<Contact> ctctsToSetup = new List<Contact>();
			for (Account a : acctsToSetup) {
				for (Integer i=0; i<2; i++) {
					ctctsToSetup.add(
						new Contact(
							AccountId = a.Id,
							FirstName = 'Contact ' + i,
							LastName  = a.Name,
							RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Guest').getRecordTypeId()
						)
					);
				}
			}
			insert ctctsToSetup;

			isNotSetup = false;
            system.assertEquals(200, acctsToSetup.size());
		}
        system.assertEquals(false, isNotSetup);
    }

	@isTest
	public static void fromAndToRecords() {
		List<Account> acctRecs = [SELECT Id, Name, Website, CreatedDate, 
										 (SELECT Id, Name, FirstName, LastName
										 	FROM Contacts)
									FROM Account
								   WHERE Id IN (SELECT AccountId
								   				  FROM Contact)];

		List<Msg> acctMsgs = (List<Msg>)Msg.fromRecords(AccountMsgTest.class, acctRecs);

		System.assertEquals(200, acctRecs.size());
		System.assertEquals(200, acctMsgs.size());
		for (Msg m : acctMsgs) {
			AccountMsgTest amt = (AccountMsgTest)m;
			System.assertNotEquals(null, amt.childContacts);
			System.assertEquals(2, amt.childContacts.size());
			System.assert(amt.childContacts[0].firstName.contains('Contact '));
			System.assert(amt.childContacts[1].firstName.contains('Contact '));
			System.assert(amt.childContacts[1].LastName.contains(amt.Name));

			Account a = (Account)amt.toRecord();
			System.assertEquals(amt.recordId, a.Id);
			System.assertEquals(amt.name, a.Name);
			System.assertEquals(amt.websiteAddress, a.Website);
		}
	}
	

	/**
	 * A concrete instance of a Msg that uses a standard object
	 * so that we can have out-of-the box testing
	 */
	public with sharing class AccountMsgTest extends Msg {
		public String websiteAddress;
		public DateTime dateCreated;
		public List<ContactMsgTest> childContacts;

		public override SObjectType getType() {
			return Schema.Account.SObjectType;
		}

		public override List<Msg.FieldMapping> getFieldMappings() {
			return new List<Msg.FieldMapping>{
				new Msg.FieldMapping('website', 'websiteAddress'),
				new Msg.FieldMapping('createdDate', 'dateCreated', true),
				new Msg.FieldMapping('Contacts', 'childContacts', true, ContactMsgTest.class)
			};
		}
	}

	public with sharing class ContactMsgTest extends Msg {
		public String firstName;
		public String lastName;
		public String fullName;

		public override SObjectType getType() {
			return Schema.Contact.SObjectType;
		}

		public override List<Msg.FieldMapping> getFieldMappings() {
			return new List<Msg.FieldMapping>{
				new Msg.FieldMapping('FirstName', 'firstName'),
				new Msg.FieldMapping('LastName', 'lastName'),
				new Msg.FieldMapping('Name', 'fullName', true)
			};
		}
	}
}