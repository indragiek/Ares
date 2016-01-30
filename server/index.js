var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var MongoClient = require('mongodb').MongoClient;
var assert = require('assert');
var async = require('async');
var bcrypt = require('bcrypt');

// ######## EXPRESS #########

app.use(bodyParser.urlencoded({ extended: false }));
app.set('port', (process.env.PORT || 5000));

app.get('/', function (req, res) {
    res.send('Hello World!');
});

app.listen(app.get('port'), function () {
    console.log('Example server started');
});

app.post('/register', function(req, res, next) {
    async.waterfall([
        connectMongoDB,
        async.apply(createUser, req.body.username, req.body.password)
    ], function(err, result) {
        if (err) {
            res.status(400).json({ error: err.message });
        } else {
            res.json(result.ops[0]);
        }
    });
});

// ######## MONGODB #########

USERS_COLLECTION = "users";

var connectMongoDB = function(callback) {
    MongoClient.connect(process.env.MONGOLAB_URI, callback);
};

var getUserWithUsername = function(username, db, callback) {
    var users = db.collection(USERS_COLLECTION);
    users.findOne({ username: username }, callback);
};

var createUser = function(username, password, db, finalCallback) {
    async.waterfall([
        async.apply(getUserWithUsername, username, db),
        function(user, callback) {
            if (user) {
                callback(new Error('USER_EXISTS'));
            } else {
                callback(null, password);
            }
        },
        hashPassword,
        function(hash, callback) {
            db.collection(USERS_COLLECTION).insert({
                username: username,
                password_hash: hash
            }, callback);
        }
    ], finalCallback);
};

var hashPassword = function(password, callback) {
    bcrypt.genSalt(10, function(err, salt) {
        bcrypt.hash(password, salt, callback);
    });
};
