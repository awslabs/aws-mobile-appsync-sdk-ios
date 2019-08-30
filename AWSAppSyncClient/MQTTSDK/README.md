# MQTT client flows

## Init flow

This is originated from AWSAppSyncClient, which creates a subscription watcher and an `AppSyncMQTTClient`. This flow focuses only on the AWSIoTMQTTClient related modules.

```
+-------------------+                       +-------------------+ +-----------------+ +-----------------+ +-----------------+
| AWSIoTMQTTClient  |                       | AWSIoTMQTTSession | | AWSSRWebSocket  | | AWSMQTTEncoder  | | AWSMQTTDecoder  |
+-------------------+                       +-------------------+ +-----------------+ +-----------------+ +-----------------+
          |                                           |                    |                   |                   |
          | initWithClientId:                         |                    |                   |                   |
          |------------------------------------------>|                    |                   |                   |
          |                                           |                    |                   |                   |
          | initWithURLRequest:                       |                    |                   |                   |
          |--------------------------------------------------------------->|                   |                   |
          |                                           |                    |                   |                   |
          | delegate = self                           |                    |                   |                   |
          |--------------------------------------------------------------->|                   |                   |
          |                                           |                    |                   |                   |
          | open:                                     |                    |                   |                   |
          |--------------------------------------------------------------->|                   |                   |
          |                                           |                    |                   |                   |
          |                                           |  webSocketDidOpen: |                   |                   |
          |<---------------------------------------------------------------|                   |                   |
          |                                           |                    |                   |                   |
          | decoderStream,                            |                    |                   |                   |
          | toDecoderStream=                          |                    |                   |                   |
          |   bound pair                              |                    |                   |                   |
          |-----------------                          |                    |                   |                   |
          |                |                          |                    |                   |                   |
          |<----------------                          |                    |                   |                   |
          |                                           |                    |                   |                   |
          | toWebSocketStream=                        |                    |                   |                   |
          |   create...WithWebSocket:                 |                    |                   |                   |
          |------------------------                   |                    |                   |                   |
          |                       |                   |                    |                   |                   |
          |<-----------------------                   |                    |                   |                   |
          |                                           |                    |                   |                   |
          | start thread,                             |                    |                   |                   |
          | openStreams                               |                    |                   |                   |
          |--------------                             |                    |                   |                   |
          |             |                             |                    |                   |                   |
          |<-------------                             |                    |                   |                   |
          |                                           |                    |                   |                   |
          | -[connectToInputStream:decoderStream      |                    |                   |                   |
          |           outputStream:toWebSocketStream] |                    |                   |                   |
          |------------------------------------------>|                    |                   |                   |
          |                                           |                    |                   |                   |
          |                                           | -[initWithStream:  |                   |                   |
          |                                           |   toWebSocketStream]                   |                   |
          |                                           |--------------------------------------->|                   |
          |                                           |                    |                   |                   |
          |                                           | -[initWithStream:  |                   |                   |
          |                                           |   decoderStream]   |                   |                   |
          |                                           |----------------------------------------------------------->|
          |                                           |                    |                   |                   |
```

### Sequence diagram source

http://weidagang.github.io/text-diagram/

```
AWSIoTMQTTClient->AWSIoTMQTTSession: initWithClientId:
AWSIoTMQTTClient->AWSSRWebSocket: initWithURLRequest:
AWSIoTMQTTClient->AWSSRWebSocket: delegate = self
AWSIoTMQTTClient->AWSSRWebSocket: open:
AWSSRWebSocket->AWSIoTMQTTClient: webSocketDidOpen:
AWSIoTMQTTClient->AWSIoTMQTTClient: decoderStream,\ntoDecoderStream=\n  bound pair
AWSIoTMQTTClient->AWSIoTMQTTClient: toWebSocketStream=\n  create...WithWebSocket:
AWSIoTMQTTClient->AWSIoTMQTTClient: start thread,\nopenStreams
AWSIoTMQTTClient->AWSIoTMQTTSession: -[connectToInputStream:decoderStream\n          outputStream:toWebSocketStream]
AWSIoTMQTTSession->AWSMQTTEncoder: -[initWithStream:\n  toWebSocketStream]
AWSIoTMQTTSession->AWSMQTTDecoder: -[initWithStream:\n  decoderStream]
```

## Send Data Flow

"Send" operations for AppSync are for new subscriptions, connections and disconnections. AppSync clients do not publish data through an MQTT connection, but rather through 
a GraphQL Mutation via normal HTTPS connection.

```
+-------------------+        +-----------------+  +-------------------+ +-----------------+
| AWSIoTMQTTSession |        | AWSMQTTEncoder  |  | toWebSocketStream | | AWSSRWebSocket  |
+-------------------+        +-----------------+  +-------------------+ +-----------------+
          |                           |                     |                    |
          | encodeMessage:            |                     |                    |
          |-------------------------->|                     |                    |
          |                           |                     |                    |
          |                           | Do encode           |                    |
          |                           |----------           |                    |
          |                           |         |           |                    |
          |                           |<---------           |                    |
          |                           |                     |                    |
          |                           | write:              |                    |
          |                           |-------------------->|                    |
          |                           |                     |                    |
          |                           |                     | send:              |
          |                           |                     |------------------->|
          |                           |                     |                    |
          |          (status delegate |                     |                    |
          |                  methods) |                     |                    |
          |<--------------------------|                     |                    |
          |                           |                     |                    |
```

### Sequence diagram source

http://weidagang.github.io/text-diagram/

```
AWSIoTMQTTSession->AWSMQTTEncoder: encodeMessage:
AWSMQTTEncoder->AWSMQTTEncoder: Do encode
AWSMQTTEncoder->toWebSocketStream: write:
toWebSocketStream->AWSSRWebSocket: send:
AWSMQTTEncoder->AWSIoTMQTTSession: (status delegate\nmethods)
```

## Receive Data Flow

```
+-----------------+            +-------------------+ +---------------------+             +-----------------+               +-------------------+                
| AWSSRWebSocket  |            | AWSIoTMQTTClient  | | toDecoderStreamPair |             | AWSMQTTDecoder  |               | AWSIoTMQTTSession |                
+-----------------+            +-------------------+ +---------------------+             +-----------------+               +-------------------+                
         |                               |                      |                                 |                                  |                          
         | -[webSocket:                  |                      |                                 |                                  |                          
         |   didReceiveMessage:]         |                      |                                 |                                  |                          
         |------------------------------>|                      |                                 |                                  |                          
         |                               |                      |                                 |                                  |                          
         |                               | -[write:]            |                                 |                                  |                          
         |                               |--------------------->|                                 |                                  |                          
         |                               |                      |                                 |                                  |                          
         |                               |                      | -[stream:handleEvent:]          |                                  |                          
         |                               |                      |-------------------------------->|                                  |                          
         |                               |                      |                                 |                                  |                          
         |                               |                      |                                 | Do decode                        |                          
         |                               |                      |                                 |----------                        |                          
         |                               |                      |                                 |         |                        |                          
         |                               |                      |                                 |<---------                        |                          
         |                               |                      |                                 |                                  |                          
         |                               |                      |                                 | -[decoder:newMessage:]           |                          
         |                               |                      |                                 |--------------------------------->|                          
         |                               |                      |                                 |                                  |                          
         |                               |                      |                                 |                                  | -[AWSMQTTSessionDelegate 
         |                               |                      |                                 |                                  |   session:               
         |                               |                      |                                 |                                  |   newMessage:            
         |                               |                      |                                 |                                  |   onTopic:]              
         |                               |                      |                                 |                                  |------------------------- 
         |                               |                      |                                 |                                  |                        | 
         |                               |                      |                                 |                                  |<------------------------ 
         |                               |                      |                                 |                                  |                          
         |                               |                      |                                 |                                  | send flow:               
         |                               |                      |                                 |                                  | puback                   
         |                               |                      |                                 |                                  |-----------               
         |                               |                      |                                 |                                  |          |               
         |                               |                      |                                 |                                  |<----------               
         |                               |                      |                                 |                                  |                          
```

### Sequence diagram source

http://weidagang.github.io/text-diagram/

```
AWSSRWebSocket->AWSIoTMQTTClient: -[webSocket:\n  didReceiveMessage:]
AWSIoTMQTTClient->toDecoderStreamPair: -[write:]
toDecoderStreamPair->AWSMQTTDecoder: -[stream:handleEvent:]
AWSMQTTDecoder->AWSMQTTDecoder: Do decode
AWSMQTTDecoder->AWSIoTMQTTSession: -[decoder:newMessage:]
AWSIoTMQTTSession->AWSIoTMQTTSession: -[AWSMQTTSessionDelegate\n  session:\n  newMessage:\n  onTopic:]
AWSIoTMQTTSession->AWSIoTMQTTSession: send flow:\npuback
```