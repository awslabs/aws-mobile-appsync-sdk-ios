//
// Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import <Foundation/Foundation.h>

#import <AWSCore/AWSCore.h>

typedef NS_ENUM(NSInteger, MQTTStatus) {
    MQTTStatusUnknown,
    MQTTStatusConnecting,
    MQTTStatusConnected,
    MQTTStatusDisconnected,
    MQTTStatusConnectionRefused,
    MQTTStatusConnectionError,
    MQTTStatusProtocolError
};

typedef NS_ENUM(NSInteger, MQTTQoS) {
    MQTTQoSMessageDeliveryAttemptedAtMostOnce = 0,
    MQTTQoSMessageDeliveryAttemptedAtLeastOnce = 1
};

typedef void(^MQTTNewMessageBlock)(NSData *data);
typedef void(^MQTTExtendedNewMessageBlock)(NSObject *mqttClient, NSString *topic, NSData *data);

@interface MQTTTopicModel : NSObject
@property (nonatomic, strong) NSString *topic;
@property (nonatomic) UInt8 qos;
@property (nonatomic, strong) MQTTNewMessageBlock callback;
@property (nonatomic, strong) MQTTExtendedNewMessageBlock extendedCallback;
@end

@interface MQTTQueueMessage : NSObject
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSData *message;
@property (atomic, assign) UInt8 qos;
@end

@class MQTTClient;

@protocol MQTTClientDelegate

-(void)receivedMessageData:(NSData *)data
                   onTopic:(NSString *)topic;

-(void)connectionStatusChanged:(MQTTStatus)status
                        client:(MQTTClient *)client;
@end

@interface MQTTClient <AWSSRWebSocketDelegate, NSStreamDelegate>: NSObject

@property(nonatomic, strong) id<MQTTClientDelegate> clientDelegate;
/**
 Boolean flag to indicate whether auto-resubscribe feature is enabled. This flag may
 be set through MQTTConfiguration in AWSIoTDataManager
 */
@property(nonatomic, assign) BOOL autoResubscribe;

/**
 The current MQTT connection status to AWS IoT
 */
@property(atomic, assign, readonly) MQTTStatus mqttStatus;
/**
 These properties control the reconnect behavior of the MQTT Client.  If the MQTT
 client becomes disconnected, it will attempt to reconnect after a quiet period;
 this quiet period doubles with each reconnection attempt, e.g. 1 seconds, 2
 seconds, 2, 8, 16, 32, etc... up until a maximum reconnection time is reached.
 If a connection is active for the minimum connection time, the quiet period
 is reset to the initial value.
 
 baseReconnectTime: the time in seconds to wait before the first reconnect attempt
 minimumConnectionTime: the time in seconds that a connection must be active before
     resetting the current reconnection time to the base reconnection time
 maximumReconnectTime: the maximum time in seconds to wait between reconnect
     attempts
 
 The defaults for these values are:
 
 baseReconnectTime: 1 seconds
 minimumConnectionTime: 20 seconds
 maximumReconnectTime: 128 seconds
 */
@property(atomic, assign) NSTimeInterval baseReconnectTime;
@property(atomic, assign) NSTimeInterval minimumConnectionTime;
@property(atomic, assign) NSTimeInterval maximumReconnectTime;

/**
 The client ID for the current connection; can be nil if not connected.
 */
@property(nonatomic, strong) NSString *clientId;

/**
 An optional associated object (nil by default).
 */
@property(nonatomic, strong) NSObject *associatedObject;

- (instancetype)initWithDelegate:(id<MQTTClientDelegate>)delegate;

/**
 Returns a default singleton object. You should use this singleton method instead of creating an instance of the mqtt client.
 @return The default mqtt client. This is a singleton object.
 */
//+ (instancetype)sharedInstance;

- (BOOL)connectWithClientId:(NSString *)clientId
                     toHost:(NSString *)host
             statusCallback:(void (^)(MQTTStatus status))callback;

- (BOOL)connectWithClientId:(NSString *)clientId
                     toHost:(NSString *)host
               cleanSession:(BOOL)cleanSession
             statusCallback:(void (^)(MQTTStatus status))callback;

- (void)disconnect;

- (void)reconnectToSession;

/**
 Subscribes to a topic at a specific QoS level

 @param topic The Topic to subscribe to.

 @param qos Specifies the QoS Level of the subscription. Can be 0, 1, or 2.

 @param callback Delegate Reference to MQTTNewMessageBlock. When new message is received the callback will be invoked.
 */
- (void)subscribeToTopic:(NSString *)topic qos:(UInt8)qos
         messageCallback:(MQTTNewMessageBlock)callback;

/**
 Subscribes to a topic at a specific QoS level
 
 @param topic The Topic to subscribe to.
 
 @param qos Specifies the QoS Level of the subscription. Can be 0, 1, or 2.
 
 @param callback Delegate Reference to MQTTExtendedNewMessageBlock. When new message is received the block will be invoked.
 */
- (void)subscribeToTopic:(NSString *)topic qos:(UInt8)qos
        extendedCallback:(MQTTExtendedNewMessageBlock)callback;

/**
 Unsubscribes from a topic

 @param topic The Topic to unsubscribe from.

 */
- (void)unsubscribeTopic:(NSString *)topic;

@end
