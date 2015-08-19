/**
 * Created by famer.me on 15-8-10.
 */
var client = new Paho.MQTT.Client('q.m2m.io', 4483, '/mqtt', 'bIspFUx5gvCeu7XUBgsxP');

client.connect({
  userName: 'cbefb25b-0c8c-4e70-a21d-9c381bc7e4bb',
  password: 'a185b3de0fa03c1818ba0ac21bf173dd',//'3cbc487e-e2d0-4770-aa77-d3dac235b0e0' md5 'a185b3de0fa03c1818ba0ac21bf173dd'
  useSSL: true,
  keepAliveInterval: 30,
  mqttVersion: 3.1,
  onSuccess: function (info) {
    console.log(info);
    client.subscribe('wavocnvukgsu72j/#', {qos: 0});
    client.onMessageArrived = function (msg) {
      console.log(msg.payloadString);
    };
  },
  onFailure: function (info) {
    console.log(info);
  }
});



