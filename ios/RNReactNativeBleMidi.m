
#import "RNReactNativeBleMidi.h"

@implementation RNReactNativeBleMidi

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(connect,
                 connectWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  CABTMIDILocalPeripheralViewController *viewController = [[CABTMIDILocalPeripheralViewController alloc] init];
  [self.navigationController pushViewController: viewController animated:YES];


  resolve(true);
  // if (events) {
  //   resolve(events);
  // } else {
  //   NSError *error = ...
  //   reject(@"no_events", @"There were no events", error);
  // }
}



@end
