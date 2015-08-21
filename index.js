/**
 * Created by famer.me on 15-8-10.
 */

var conn = mqtt.createConnection(
  1883,
  'localhost',
  function(err, client) {
    if (err) throw err;

    client.connect({
      protocolId: 'MQIsdp',
      protocolVersion: 3,
      clientId: 'example',
      keepalive: 30000
    });

    client.on('connack', function(packet) {
      if (packet.returnCode !== 0) {
        throw 'Connect error'
      }
      client.publish({
        topic: 'example',
        payload: new Buffer('example', 'utf8')
      });
    });
  });
