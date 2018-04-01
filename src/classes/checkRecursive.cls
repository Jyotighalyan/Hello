public Class checkRecursive{
    private static boolean run = true;
    private static boolean runBeforeInsert = true;
    private static boolean runAfterInsert = true;
    private static boolean runBeforeUpdate = true;
    private static boolean runAfterUpdate = true;
    private static boolean runBeforeDelete = true;
    private static boolean runAfterDelete = true;
    
    public static boolean runOnce(){
        if(run){
            run=false;
            return true;
        }else{
            return run;
        }
    }
    
    public static boolean runBeforeInsertOnce(){
        if(runBeforeInsert){
            runBeforeInsert=false;
            return true;
        }else{
            return runBeforeInsert;
        }
    }
    
    public static boolean runAfterInsertOnce(){
        if(runAfterInsert){
            runAfterInsert=false;
            return true;
        }else{
            return runAfterInsert;
        }
    }
    
    public static boolean runBeforeUpdateOnce(){
        if(runBeforeUpdate){
            runBeforeUpdate=false;
            return true;
        }else{
            return runBeforeUpdate;
        }
    }
    public static boolean runAfterUpdateOnce(){
        if(runAfterUpdate){
            runAfterUpdate=false;
            return true;
        }else{
            return runAfterUpdate;
        }
    }
    public static boolean runAfterDeleteOnce(){
        if(runAfterDelete){
            runAfterDelete=false;
            return true;
        }else{
            return runAfterDelete;
        }
    }
    public static boolean runBeforeDeleteOnce(){
        if(runBeforeDelete){
            runBeforeDelete=false;
            return true;
        }else{
            return runBeforeDelete;
        }
    }
    
}