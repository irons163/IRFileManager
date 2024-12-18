//#import <Cocoa/Cocoa.h>
//#import <net/route.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>

@interface CustomRoute : NSObject {
    struct sockaddr_in     m_addrs[10];
    struct rt_msghdr2   m_rtm;
    int                 m_len;      /* length of the sockaddr array */
}

+ (NSMutableArray*) getRoutes;
+ (CustomRoute*) getRoute:(struct rt_msghdr2 *)rtm;

- (void) setAddr:(struct sockaddr*)sa index:(int)rtax_index;

- (NSString*) getDestination;
- (NSString*) getNetmask;
- (NSString*) getGateway;
- initWithRtm: (struct rt_msghdr2*) rtm;


@end