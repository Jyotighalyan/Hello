var git = require('git-rev-sync')
var fs = require('fs-extra')
var path = require('path')
var tools = require('cs-jsforce-metadata-tools')
var ZIP = require('zip');
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
    packageName: ciconfig.packageName,
    checkOnly: ciconfig.checkOnly,
    testLevel: ciconfig.testLevel,
    ignoreWarnings: ciconfig.ignoreWarnings,
    pollTimeout: 600000,
    pollInterval: 15000,
    packageXmlPath: path.resolve('./src/package.xml'),
    retrievePath: path.resolve('./src')
}
var branch = git.branch();

var retrievePackageByName = function(){
    tools.retrieveByPackageNames([options.packageName], options).then(function (res) {
        tools.reportRetrieveResult(res, console, options.verbose)
        if (!res.success) {
            process.exit(1)
        } else {
            // Here is where we unzip the data...
            var data = Buffer.from(res.zipFile, 'base64');
            var reader = ZIP.Reader(data);
            reader.forEach(function (entry) {
                if (entry.isFile()) {
                    var name = entry.getName().replace(new RegExp('^' + options.packageName + '/'),'');
                    var data = entry.getData();
                    fs.outputFileSync(path.resolve('./src/' + name), data);
                }
            });
            console.log('Retrieved metadata files are saved under the directory: ');
            process.exitCode = 0
        }
    }).catch(function (err) {
        console.error(err.message)
        process.exitCode = 0
    });
}

authtools.updateAuthOptions(ciconfig, options);
retrievePackageByName();
