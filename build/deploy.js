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
var options = {
    loginUrl: "https://login.salesforce.com",
    checkOnly: ciconfig.checkOnly,
    testLevel: ciconfig.testLevel,
    ignoreWarnings: ciconfig.ignoreWarnings,
    pollTimeout: 600000,
    pollInterval: 15000,
    rollbackOnError : true,
    verbose : true
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

//copy the package-xml to artifacts
var createPackageXML = function(){
    console.log('Copying Package XML to Artifacts');
    fs.stat('./src/package.xml', function(err, stat) {
        if(err === null) {
            console.log('Found /src/package.xml');
            var origin = path.resolve('./src/package.xml');
            var artifacts =  path.resolve((process.env.CIRCLE_ARTIFACTS || '.') + '/package.xml');
            if (fs.statSync(origin).isFile()){
                fs.writeFileSync(artifacts, fs.readFileSync(origin, 'utf8'));
            }
        } else if(err.code == 'ENOENT') {
            console.log('No package.xml found');
        } else {
            console.log('Some other error: ', err.code);
        }
    });
};


// Deploy the Code from a directory
var deployCode = function(){
    console.log('Deploying the code from to Salesforce');
    console.info('branch', branch.toUpperCase().replace('.','_'));
    tools.deployFromDirectory('./src', options).then(function (res) {
        tools.reportDeployResult(res, logger, options.verbose);
        logger.flush();
        if (!res.success || res.numberTestErrors > 0 || res.numberComponentErrors > 0) {
            console.error('Deploy was NOT Successful');
            process.exit(1);
        } else {
            console.error('Deploy was Successful');
            process.exit(0);
        }
    }).catch(function (err) {
        console.error(err.message);
        process.exit(1);
    });
};

authtools.updateAuthOptions(ciconfig, options);
createPackageXML();
deployCode();