var git = require('git-rev-sync');

// CONFIG OPTIONS:
//     username [username]          Salesforce username
//     password [password]          Salesforce password (and security token, if available)
//     loginUrl [loginUrl]          Salesforce login url
//     checkOnly                    Whether Apex classes and triggers are saved to the organization as part of the deployment
//     dry-run                      Dry run. Same as --checkOnly
//     testLevel [testLevel]        Specifies which tests are run as part of a deployment (NoTestRun/RunSpecifiedTests/RunLocalTests/RunAllTestsInOrg)
//     runTests [runTests]          A list of Apex tests to run during deployment (commma separated)
//     ignoreWarnings               Indicates whether a warning should allow a deployment to complete successfully (true) or not (false).
//     rollbackOnError              Indicates whether any failure causes a complete rollback (true) or not (false)
//     pollTimeout [pollTimeout]    Polling timeout in millisec (default is 60000ms)
//     pollInterval [pollInterval]  Polling interval in millisec (default is 5000ms)
//     verbose                      Output execution detail log

var config = {
    url: 'https://login.salesforce.com',
    packageName: 'ForeTeesCMS',
    testLevel: 'RunLocalTests', // NoTestRun
    runDeleteScript: true,
    checkOnly: false,
    ignoreWarnings: true,
};
var gitBranch = git.branch();
var authConfig;
if(process.env['CI']){
    authConfig = {
        username: process.env[gitBranch.toUpperCase().replace('.','_') + '_USERNAME'],
        password: process.env[gitBranch.toUpperCase().replace('.','_') + '_PASSWD'],
        refreshToken: process.env[gitBranch.toUpperCase().replace('.','_') + '_TOKEN'],
        clientId: process.env['CLIENTID'],
        clientSecret: process.env['CLIENTSECRET']
    }
}
else {
    authConfig = require('./build.properties.'+gitBranch);
}
module.exports = Object.assign(config, authConfig);
