@isTest
public class SelectorTest {
	private static Boolean isNotSetup = true; // Used to determine if the setup method has been called by other setups

	@TestSetup
	public static void setup() {
		if (isNotSetup) {

			List<Account> acctsToSetup = new List<Account>();
			for (Integer i=0; i<200; i++) {
				acctsToSetup.add(new Account(Name = 'Test Customer Account: ' + i));
			}
			insert acctsToSetup;

			isNotSetup = false;
        	system.assertEquals(200, acctsToSetup.size());
        }
        system.assertEquals(false, isNotSetup);
	}
	
	@isTest
	public static void constructors() {
		new AccountSelectorTest(true, true, true);
        Selector s = new AccountSelectorTest();
        System.assertEquals(3, s.getDefaultFields().size());
	}
	
	@isTest
	public static void getSObjectType() {
		Selector s = new AccountSelectorTest();
		System.assertEquals(Schema.Account.SObjectType, s.getSObjectType());
	}
	
	@isTest
	public static void getSObjectName() {
		Selector s = new AccountSelectorTest();
		System.assertEquals('Account', s.getSObjectName());
	}
	
	@isTest
	public static void isEnforcing() {
		Selector s = new AccountSelectorTest(false, false, false);
		System.assertEquals(false, s.isEnforcingCRUD());
		System.assertEquals(false, s.isEnforcingFLS());
		System.assertEquals(false, s.isEnforcingShr());
		
		s = new AccountSelectorTest(true, true, true);
		System.assertEquals(true, s.isEnforcingCRUD());
		System.assertEquals(true, s.isEnforcingFLS());
		System.assertEquals(true, s.isEnforcingShr());
	}
	
	@isTest
	public static void getDefaultQuery() {
		Selector s = new AccountSelectorTest(true, true, true);
		System.assert(s.getDefaultQuery().startsWith('SELECT '));
		System.assert(s.getDefaultQuery().endsWith(' FROM Account '));
	}
	
	@isTest
	public static void getAllRecords() {
		Selector s = new AccountSelectorTest(true, true, true);
		
		List<SObject> recs = s.getAllRecords();
		
		System.assertEquals(200, recs.size());
	}
	
	@isTest
	public static void getRecordById() {
		Selector s = new AccountSelectorTest(true, true, true);
		
		Account a = [SELECT Id FROM Account LIMIT 1];
		
		SObject rec = s.getRecordById(a.Id);
		
		System.assertNotEquals(null, rec);
		System.assertEquals(a.Id, rec.Id);
	}
	
	@isTest
	public static void getRecordsByIds() {
		Selector s = new AccountSelectorTest(true, true, true);
		
		Set<Id> acctIds = new Map<Id,Account>([SELECT Id FROM Account]).keySet();
		
		List<SObject> recs = s.getRecordsByIds(acctIds);
		
		System.assertEquals(200, recs.size());
	}
	
	/**
	 * A concrete instance of a selector that uses a standard object
	 * so that we can have out-of-the
	 */
	public class AccountSelectorTest extends Selector {
		public AccountSelectorTest() {
			super(Schema.Account.SObjectType);
		}
		
		public AccountSelectorTest(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
			super(Schema.Account.SObjectType, enforceCRUD, enforceFLS, enforceShr);
		}
		
		public override Set<String> getDefaultFields() {
			return new Set<String>{
				'Id',
				'Name',
				'AccountNumber'
			};
		}
	}
}