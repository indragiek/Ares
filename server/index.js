var express = require('express');
var app = express();
var MongoClient = require('mongodb').MongoClient;
var assert = require('assert');

// ######## EXPRESS #########

app.set('port', (process.env.PORT || 5000));

app.get('/', function (req, res) {
    res.send('Hello World!');
});

app.listen(app.get('port'), function () {
    console.log('Example server started');
});

// ######## MONGODB #########

MongoClient.connect(process.env.MONGOLAB_URI, function(err, db) {
    assert.equal(null, err);
    console.log('Successfully connected to MongoDB');
    db.close();
});
