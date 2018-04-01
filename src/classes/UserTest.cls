/**
 * This test class should be used as a central place for creating all
 * personas user records, and assigning those user records to any
 * permission sets utilized by the application. jyoti test 121
 * <p>
 */
@isTest
public class UserTest {
    private static Integer userNumber = 0;
    
    @isTest
    public static User createStandardUser() {
        User u = createUserWithProfile([SELECT Id FROM Profile WHERE Name = 'Standard User'].Id);
        system.assertNotEquals(null, u);
        return u;
    }

    @isTest
     public static User createPlatformUser() {
        User u = createUserWithProfile([SELECT Id FROM Profile WHERE Name = 'Standard Platform User'].Id);
        system.assertNotEquals(null, u);
        return u;
    }

   
    public static User createForeTeesProfileUser(){
       User u = createUserWithProfile([SELECT Id FROM Profile WHERE Name = 'ForeTees User'].Id);
        system.assertNotEquals(null, u);
        return u; 
    }
    
    public static User createUserWithProfile(Id profileId) {
        Integer userNum = userNumber++;
        String email = 'unit.test.user+' + userNum + '@' + UserInfo.getOrganizationId() + '.test.com';
        User u = new User(
            FirstName           = 'Test',
            LastName            = 'User ',
            Email               = email,
            Username            = email,
            Alias               = ('tuser' + userNum).right(8),
            Phone               = '503-555-1212',
            ProfileId           = profileId,
            TimeZoneSidKey      = 'America/Los_Angeles',
            LocaleSidKey        = 'en_US',
            EmailEncodingKey    = 'ISO-8859-1',
            LanguageLocaleKey   = 'en_US'
        );
        if(Userinfo.isMultiCurrencyOrganization()) {
            ((SObject)u).put('CurrencyIsoCode','USD');
        }
        insert u;
        
        return u;
    }

    /**
     * Example showing how to create a user with a default assignment of some permission
     * sets.
     */
    @isTest
    public static User createUserWithPerms() {
        User u = createUser(new List<String>{'permission_set_name_1','permission_set_name_2'});
        system.assertNotEquals(null, u);
        return u;
    }

    private static User createUser(List<String> permissionSets) {
        User u = createStandardUser();

        // add user to perm sets
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [SELECT Id, Name
                                   FROM PermissionSet
                                  WHERE Name IN :permissionSets]) {
            psas.add(
                new PermissionSetAssignment(
                    AssigneeId              = u.Id,
                    PermissionSetId         = ps.Id
                )
            );
        }
        insert psas;

		return u;
	}

    //Method to set ForeTeesUser Profile or Standard User Profile based on boolean flag
    //when creating a user. Set flag to true for ForeTees User profile or false for Standard User profile.
     private static User createUser(List<String> permissionSets, Boolean ftProfile) {

        User u = createStandardUser();

        if(ftProfile){
            u = createForeTeesProfileUser();
        }

        // add user to perm sets
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [SELECT Id, Name
                                   FROM PermissionSet
                                  WHERE Name IN :permissionSets]) {
            psas.add(
                new PermissionSetAssignment(
                    AssigneeId              = u.Id,
                    PermissionSetId         = ps.Id
                )
            );
        }
        insert psas;

		return u;
	}
	
	public static User createForeTeesUser() {
		User u = createUser(new List<String>{'ForeTees_Admin','ForeTees_User'});
		System.assertNotEquals(null, u);
		return u;
	}
    //Method to create a ForeTees User passing a flag to set the profile to
    //ForeTeesUser profile if true.
    public static User createForeTeesUser(Boolean ftProfile) {
            User u = createUser(new List<String>{'ForeTees_Admin','ForeTees_User'}, ftProfile);
                    System.assertNotEquals(null, u);
                    return u;
	}
}