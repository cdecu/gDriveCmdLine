#!/usr/bin/env node

var google = require('googleapis');
var drive = google.drive('v3');


var SCOPES = ['https://www.googleapis.com/auth/drive.metadata.readonly'];

// Load client secrets from a local file.
// to get the public key openssl rsa -in test.txt -pubout
var key = require('./client_secret.json');

// Build the jwt
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
    // Make an authorized request to list Drive files.
    var req = drive.files.list({auth: jwtClient}, function (err, resp) {
        if (err) {
            console.log(err);
            return;
            }
        console.log(JSON.stringify(resp, null, '  '));
        });
});

