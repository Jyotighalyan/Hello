var git = require('git-rev-sync')
var fs = require('fs');
var path = require('path');
var tools = require('cs-jsforce-metadata-tools');
var ciconfig = require('./ci.config.js');
var authtools = require('./authTools.js');

//   Options:
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
// testLevel = NoTestRun
// testLevel = RunSpecifiedTests
// testLevel = RunLocalTests
// testLevel = RunAllTestsInOrg
var options = {
    loginUrl: "https://login.salesforce.com",
    checkOnly: ciconfig.checkOnly,
    testLevel: "NoTestRun",
    ignoreWarnings: ciconfig.ignoreWarnings,
    pollTimeout: 1200000,
    pollInterval: 15000,
    rollbackOnError : true,
    verbose : true,
    purgeOnDelete : true
};
var branch = git.branch();

var logger = (function (fs) {
    var buffer = '';
    return {
        log: log,
        flush: flush
    };
    function log(val) {
        buffer += (val + '\n');
    }
    function flush() {
        var logFile = path.resolve((process.env.CIRCLE_ARTIFACTS || '.') + '/DeployStatistics.log');
        fs.appendFileSync(logFile, buffer, 'utf8');
        buffer = '';
    }
} (fs));

// Deploy the Code from a directory
var deployDestructiveChanges = function(){
    if(fs.existsSync('./build/destroy/destructiveChanges.xml')){
        console.log('Found /build/destroy/destructiveChanges.xml');
        var origin = path.resolve('./build/destroy/destructiveChanges.xml');
        var artifacts =  path.resolve((process.env.CIRCLE_ARTIFACTS || '.') + '/destructiveChanges.xml');
        if (fs.statSync(origin).isFile()){
            fs.writeFileSync(artifacts, fs.readFileSync(origin, 'utf8'));
        }
        tools.deployFromDirectory('./build/destroy', options).then(function (res) {
            tools.reportDeployResult(res, logger, options.verbose);
            logger.flush();
            if (!res.success || res.numberTestErrors > 0 || res.numberComponentErrors > 0) {
                console.error('Destructive changes were NOT Successful');
                process.exit(1);
            } else {
                console.error('Destructive changes were Successful');
                fs.writeFileSync('.validationId', res.id);
                process.exit(0);
            }
        }).catch(function (err) {
            console.error(err.message);
            process.exit(1);
        });
    }
};

authtools.updateAuthOptions(ciconfig, options);
deployDestructiveChanges();
