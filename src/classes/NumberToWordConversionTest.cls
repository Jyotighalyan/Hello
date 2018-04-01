@isTest
public class NumberToWordConversionTest {
    private testMethod static void runAll() {
        NumberToWordConversion TAM = new NumberToWordConversion();
        string result='';
        result=TAM.getNumberTOWordConversion(1);
        System.AssertEquals(result, ' One Dollar And 00 Cents Only');
        result=TAM.getNumberTOWordConversion(10);
        system.debug(result);
        System.AssertEquals(result, ' Ten Dollar And 00 Cents Only');
        result=TAM.getNumberTOWordConversion(100);
        System.AssertEquals(result, ' One Hundred Dollar And 00 Cents Only');
        result=TAM.getNumberTOWordConversion(1000);
        System.AssertEquals(result, ' One Thousand Dollar And 00 Cents Only');
        result=TAM.getNumberTOWordConversion(10000); 
        System.AssertEquals(result, ' Ten Thousand Dollar And 00 Cents Only');
        result=TAM.getNumberTOWordConversion(100000);
        System.AssertEquals(result, ' One Hundred Thousand Dollar And 00 Cents Only');
        result=TAM.getNumberTOWordConversion(1000000);
        System.AssertEquals(result, ' One Million Dollar And 00 Cents Only');
        result=TAM.getNumberTOWordConversion(10000000);
        System.AssertEquals(result, ' Ten Million Dollar And 00 Cents Only');
        //result=TAM.getNumberTOWordConversion(100000000);
        //system.debug(result);
        //System.AssertEquals(result, ' Ten Crore Dollar Only');
        
        result=TAM.getNumberTOWordConversion(10.10);
        System.AssertEquals(result, ' Ten Dollar And  Ten Cents Only');
    }
}