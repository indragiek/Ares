var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var MongoClient = require('mongodb').MongoClient;
var assert = require('assert');
var async = require('async');
var bcrypt = require('bcrypt');
var jwt = require('jsonwebtoken');
var apn = require('apn');
var path = require('path');

// ######## CONSTANTS #########

USERS_COLLECTION = 'users';
DEVICES_COLLECTION = 'devices';
TOKEN_EXPIRY_SECONDS = 86400; // 24 hours
ERROR_USER_EXISTS = new Error('USER_EXISTS');
ERROR_USER_DOES_NOT_EXIST = new Error('USER_DOES_NOT_EXIST');
ERROR_DEVICE_DOES_NOT_EXIST = new Error('DEVICE_DOES_NOT_EXIST');
ERROR_PASSWORD_INCORRECT = new Error('PASSWORD_INCORRECT');
ERROR_INVALID_TOKEN = new Error('INVALID_TOKEN');

// ######## EXPRESS #########

app.set('port', (process.env.PORT || 5000));
app.set('mongo_uri', process.env.MONGOLAB_URI);
app.set('secret', process.env.APP_SECRET);

app.use(bodyParser.urlencoded({ extended: false }));

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
            return next(err);
        } else {
            res.json({ 
                success: true, 
                result: { username: result.ops[0].username }
            });
        }
    });
});

app.post('/authenticate', function(req, res, next) {
    var username = req.body.username;

    async.waterfall([
        connectMongoDB,
        async.apply(getUser, username),
        function(user, callback) {
            if (user) {
                callback(null, user);
            } else {
                callback(ERROR_USER_DOES_NOT_EXIST);
            }
        },
        function(user, callback) {
            verifyPassword(user.password_hash, req.body.password, function(err, res) {
                if (err) {
                    callback(err);
                } else {
                    callback(null, res, user);
                }
            });
        },
        function(verified, user, callback) {
            if (verified) {
                callback(null, user);
            } else {
                callback(ERROR_PASSWORD_INCORRECT);
            }
        },
    ], function(err, user) {
        if (err) {
            return next(err);
        } else {
            var token = jwt.sign(user, app.get('secret'), {
                expiresIn: TOKEN_EXPIRY_SECONDS
            });
            res.json({
                success: true,
                result: { 
                    username: username,
                    token: token 
                }
            });
        }
    });
});

app.use(function(req, res, next) {
    var token = req.body.token || req.query.token || req.headers['x-access-token'];
    if (token) {
        jwt.verify(token, app.get('secret'), function(err, user) {
            if (err) {
                next(ERROR_INVALID_TOKEN);
            } else {
                req.user = user;
                next();
            }
        });
    } else {
        res.status(403).json({
            success: false,
            error: 'No authentication token provided'
        });
    }
});

app.post('/register_device', function(req, res, next) {
    var userID = req.user._id;
    var uuid = req.body.uuid;
    var deviceName = req.body.device_name;
    var pushToken = req.body.push_token;
    async.waterfall([
        connectMongoDB,
        async.apply(registerDevice, userID, uuid, deviceName, pushToken)
    ], function(err, result) {
        if (err) {
            return next(err);
        } else {
            res.json({
                success: true,
                result: {
                    uuid: uuid,
                    device_name: deviceName
                }
            });
        }
    });
});

app.get('/devices', function(req, res, next) {
    async.waterfall([
        connectMongoDB,
        async.apply(getDevices, req.user._id)
    ], function(err, result) {
        if (err) {
            return next(err);
        } else {
            res.json({
                success: true,
                result: result
            });
        }
    });
});


var apnConnection = new apn.Connection({ production: false });

app.post('/send', function(req, res, next) {
    async.waterfall([
        connectMongoDB,
        async.apply(getDevice, req.user._id, req.body.to_id),
        function(device, callback) {
            if (device) {
                var apnsDevice = new apn.Device(device.push_token);
                var notification = new apn.Notification();
                var filePath = req.body.file_path;
                notification.alert = path.basename(filePath);
                notification.payload = { 'device_id': req.body.from_id, 'path': filePath };
                apnConnection.pushNotification(notification, apnsDevice);
                callback(null, {});
            } else {
                callback(ERROR_DEVICE_DOES_NOT_EXIST);
            }
        }
    ], function(err, result) {
        if (err) {
            return next(err);
        } else {
            res.json({
                success: true,
                result: result
            });
        }
    });
});

app.use(function(err, req, res, next) {
    res.status(400).json({ 
        success: false,
        error: err.message 
    });
});

// ######## MONGODB #########

var connectMongoDB = function(callback) {
    MongoClient.connect(app.get('mongo_uri'), callback);
};

var getUser = function(username, db, callback) {
    var users = db.collection(USERS_COLLECTION);
    users.findOne({ username: username }, callback);
};

var createUser = function(username, password, db, finalCallback) {
    async.waterfall([
        async.apply(getUser, username, db),
        function(user, callback) {
            if (user) {
                callback(ERROR_USER_EXISTS);
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

var registerDevice = function(userID, uuid, deviceName, pushToken, db, callback) {
    db.collection(DEVICES_COLLECTION).insert({
        user_id: userID,
        _id: uuid,
        device_name: deviceName,
        push_token: pushToken
    }, callback);
};

var getDevices = function(userID, db, callback) {
    var devices = db.collection(DEVICES_COLLECTION);
    devices.find({ user_id: userID }).map(function(device) {
        return {
            uuid: device._id,
            device_name: device.device_name
        };
    }).toArray(callback);
};

var getDevice = function(userID, deviceID, db, callback) {
    db.collection(DEVICES_COLLECTION).findOne({
        user_id: userID,
        _id: deviceID
    }, callback);
};

// ######## HASHING #########

var hashPassword = function(password, callback) {
    bcrypt.genSalt(10, function(err, salt) {
        bcrypt.hash(password, salt, callback);
    });
};

var verifyPassword = function(hash, password, callback) {
    bcrypt.compare(password, hash, callback);
};
