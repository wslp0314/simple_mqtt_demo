//
//  ViewController.m
//  LPMQTTDemo
//
//  Created by 刘璞 on 2021/3/26.
//
#import "ViewController.h"
#import "MQTTClient.h"

@interface ViewController ()<MQTTSessionManagerDelegate,MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSessionManager *manager;
@property (nonatomic, strong) MQTTSession *session;
@property (strong, nonatomic) NSTimer *time;
@end

@implementation ViewController


/**           注册(地址,端口号,clientId,username,password)
                连接成功mqtt服务器之后,然后在订阅主题
 ____________              成功订阅之后在进行固定主题发送消息             ____________
 |                      | ----------------------------------------------------------------------->|                      |
 |        app        |                  server成功之后进行发送消息,app接收          |      server      |
 |___________| <-----------------------------------------------------------------------|___________|
                                                    
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    
    MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
    transport.host = @"121.41.17.229";
    transport.port = 31183;
    self.session = [[MQTTSession alloc] init];
    self.session.transport = transport;
    self.session.delegate =self;
    self.session.userName = @"admin";
    self.session.password = @"public";
    self.session.clientId = @"LSEC-2090aa77f71e59c2fc5510672911871113466635384";
    [self.session connectAndWaitTimeout:30];//设定超时时长，如果超时则认为是连接失败，如果设为0则是一直连接。
    [self.session addObserver:self
                     forKeyPath:@"status"
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                        context:nil];
    //注册
    [self.session connectWithConnectHandler:^(NSError *error) {
        //订阅频道
        [self subscribeTopic:self.session ToTopic:@"ivicar_iov/pong/LSEC-2090aa77f71e59c2fc55106729118711/#"];
    }];
    
}


#pragma mark - 发布消息
- (void) subscribeTopic:(MQTTSession *)session ToTopic: (NSString *)topicUrl {
    [session subscribeToTopic:topicUrl atLevel:MQTTQosLevelAtMostOnce subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss) {
        if (error) {
            NSLog(@"连接失败");
        } else {
            NSLog(@"连接成功: %@",gQoss);
            self.time = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendMessage) userInfo:nil repeats:YES];
        }
    }];
}

#pragma mark - 接收Mqtt数据
- (void) newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    //这个是代理回调方法，接收到的数据可以在这里进行处理。
    NSString *str =[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"刘璞: %@",str);
    if ([str isEqualToString:@"pong"]) {
        [self.time invalidate];
        self.time = nil;
    }
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    switch (self.session.status) {
        case MQTTSessionStatusClosed: //连接已经关闭
            NSLog(@"刘璞: 连接已经关闭");
        break;
        case MQTTSessionStatusDisconnecting://将要断开连接
            NSLog(@"刘璞: 将要断开连接");
        break;
        case MQTTSessionStatusConnected: //已经连接
            NSLog(@"刘璞: 已经连接");
            [self sendMessage];
        break;
        case MQTTSessionStatusConnecting: //正在连接中
            NSLog(@"刘璞: 正在连接中");
        break;
        case MQTTSessionStatusError: //异常
            NSLog(@"刘璞: 异常");
        break;
        case MQTTSessionStatusCreated:
            NSLog(@"刘璞: 创建完成");
        default:
        break;
    }
}

- (void) sendMessage {
    [self.session publishData:[@"ping" dataUsingEncoding:NSUTF8StringEncoding] onTopic:@"ivicar_iov/ping/LSEC-2090aa77f71e59c2fc55106729118711" retain:YES qos:MQTTQosLevelExactlyOnce publishHandler:^(NSError *error) {
    }];
}






@end
