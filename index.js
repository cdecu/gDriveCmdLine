

var fs = require('fs');
var readline = require('readline');
var google = require('googleapis');
var googleAuth = require('google-auth-library');
var drive = google.drive('v3');


// If modifying these scopes, delete your previously saved credentials
// at ~/.credentials/drive-nodejs-quickstart.json
var SCOPES = ['https://www.googleapis.com/auth/drive.metadata.readonly'];
var TOKEN_DIR = (process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE) + '/.credentials/';
var TOKEN_PATH = TOKEN_DIR + 'drive-nodejs-quickstart.json';

// Load client secrets from a local file.
var key = require('./client_secret.json');
var jwtClient = new google.auth.JWT(
    key.client_email,
    null,
    key.private_key,
    SCOPES,
    "cdecu@rmxgcp.com"
);

jwtClient.authorize(function (err, tokens) {
    if (err) {
        console.log(err);
        return;
        }
    // console.log(JSON.stringify(jwtClient, null, '  '));
    // Make an authorized request to list Drive files.
    var req = drive.files.list({auth: jwtClient}, function (err, resp) {
        if (err) {
            console.log(err);
            return;
            }
        console.log(JSON.stringify(resp, null, '  '));
        });
    // console.log(req);
});

