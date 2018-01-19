var firebase = require('firebase-admin');
var request = require('request');

var API_KEY = "AAAASa4Q9hg:APA91bEOJpaYe1diD7BjsNPzmN-JtlOklO5qN0-QqqnrRQf3--xhpNLLYfd8gncIIGS46jVtQZb_Jl8zR7uyO3y6afPGcKYxRXwVd10wM4sfPKVIk1tz5VyqEq6fBXbc3DcuXxzcKtO5";

var serviceAccount = require("./meta.json");

firebase.initializeApp({
	credential: firebase.credential.cert(serviceAccount),
	databaseURL: "https://instakilo-ccbfc.firebaseio.com/"
});
ref = firebase.database().ref();

function listenForNotificationRequests() {
  var requests = ref.child('notificationRequests');
  requests.on('child_added', function(requestSnapshot) {
    var request = requestSnapshot.val();
      sendNotificationToUser(
      request.receiverId, 
      request.message,
      request.senderId,
      function() {
        requestSnapshot.ref.remove();
      }
    );
  }, function(error) {
    console.error(error);
  });
};

function sendNotificationToUser(receiverId, message, senderId, onSuccess) {
  request({
    url: 'https://fcm.googleapis.com/fcm/send',
    method: 'POST',
    headers: {
      'Content-Type' :' application/json',
      'Authorization': 'key='+API_KEY
    },
    body: JSON.stringify({
      notification: {
        title: "New Message",
		text: message,
		sender: senderId
      },
      to : "/topics/"+receiverId
      //data: {rideInfo: rideinfo}
    })
  }, function(error, response, body) {
    if (error) { console.error(error); }
    else if (response.statusCode >= 400) { 
      console.error('HTTP Error: '+response.statusCode+' - '+response.statusMessage); 
    }
    else {
      onSuccess();
    }
  });
}

// start listening
listenForNotificationRequests();
