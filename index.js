/**
 * Created by famer.me on 15-8-10.
 */

client =mqtt.connect({
  host: '127.0.0.1',
  port: 3000,
  path: '/mqtt'
});
client.on('connect', function() {
  client.subscribe('presence');
  return client.publish('presence', 'Hello mqtt');
});
client.on('message', function(topic, message) {
  console.log(message.toString());
  return client.end();
});

