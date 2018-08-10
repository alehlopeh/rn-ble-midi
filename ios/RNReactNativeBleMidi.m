
#import "RNReactNativeBleMidi.h"
#import <UIKit/UIKit.h>
#import <CoreAudioKit/CoreAudioKit.h>
#import <CoreMIDI/CoreMIDI.h>
#import <MIKMIDI/MIKMIDI.h>
#import <React/RCTConvert.h>



@interface RNReactNativeBleMidi ()

@property (nonatomic, strong) MIKMIDIDeviceManager *deviceManager;
@property (nonatomic, strong) MIKMIDIDevice    *device;
@property (nonatomic, strong) MIKMIDIDestinationEndpoint *destination;
@property (nonatomic, strong) id connectionToken;

@end

@implementation RNReactNativeBleMidi

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(hideView) {
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)disconnectFromDevice:(MIKMIDIDevice *)device
{
    NSLog(@"disconnectFromDevice");

    if (!device) return;
    [self.deviceManager disconnectConnectionForToken:self.connectionToken];
}

- (void)connectToDevice:(MIKMIDIDevice *)device
{
    NSLog(@"connectToDevice");

    if (!device) return;
    NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
    if (![sources count]) return;
    MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
    NSError *error = nil;

    id connectionToken = [self.deviceManager connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {

        for (MIKMIDIChannelVoiceCommand *command in commands) {
            if ((command.commandType | 0x0F) == MIKMIDICommandTypeSystemMessage) continue;

            [[UIApplication sharedApplication] handleMIDICommand:command];

            NSLog(@"Received: %@", command);
        }
    }];
    if (!connectionToken) NSLog(@"Unable to connect to input: %@", error);
    self.connectionToken = connectionToken;
}

RCT_REMAP_METHOD(send, val:(int)val control:(int)control sendWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    MIKMIDIControlChangeCommand *tweak = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:(control) value:val ];
    NSError *error = nil;
    MIKMIDIDeviceManager *dm = [MIKMIDIDeviceManager sharedDeviceManager];
    [dm sendCommands:@[tweak] toEndpoint:self.destination error:&error];
//    resolve(0);
     if (error) {
         reject(@"failed_send", @"Could not send", error);
     } else {
         resolve(0);
     }
}

RCT_REMAP_METHOD(list, listWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSArray *availableMIDIDevices = [[MIKMIDIDeviceManager sharedDeviceManager] availableDevices];
    NSArray *virtualDestinations = [[MIKMIDIDeviceManager sharedDeviceManager] virtualDestinations];
    NSLog(@"The content of virtualDestinations is%@", virtualDestinations);
    NSLog(@"The content of availableMIDIDevices is%@", availableMIDIDevices);
    self.destination = virtualDestinations.lastObject;
    NSLog(@"%@",self.destination.displayName);
    NSLog(@"%i",self.destination.uniqueID);
    NSLog(@"%i",self.destination.objectRef);
    NSMutableArray *v = [[NSMutableArray alloc] init];
    int i = 0;
    for ( MIKMIDIDestinationEndpoint *d in virtualDestinations )
    {
        NSString *uid = [NSString stringWithFormat:@"%i",d.uniqueID];
        NSString *oid = [NSString stringWithFormat:@"%i",d.objectRef];

        NSDictionary *deviceInfo = @{
                                     @"name": d.displayName,
                                     @"uniqueID": uid,
                                     @"objectRef": oid
                                };
        NSLog(@"%@",deviceInfo);
        NSLog(@"%i",i);
        v[i] = deviceInfo;
        i++;
    }

    resolve(v);
}

RCT_REMAP_METHOD(connect, connectWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    CABTMIDILocalPeripheralViewController *viewController = [[CABTMIDILocalPeripheralViewController alloc] init];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

    [rootViewController presentViewController:viewController animated:YES completion:^{
        NSLog(@"ok");

        resolve(0);

    }];
}


#pragma mark - Properties

@synthesize deviceManager = _deviceManager;

- (void)setDeviceManager:(MIKMIDIDeviceManager *)deviceManager
{
    if (deviceManager != _deviceManager) {
        [_deviceManager removeObserver:self forKeyPath:@"availableDevices"];
        _deviceManager = deviceManager;
        [_deviceManager addObserver:self forKeyPath:@"availableDevices" options:NSKeyValueObservingOptionInitial context:NULL];
    }
}

- (MIKMIDIDeviceManager *)deviceManager
{
    if (!_deviceManager) {
        self.deviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
    }
    return _deviceManager;
}

- (void)setDevice:(MIKMIDIDevice *)device
{
    if (device != _device) {
        [self disconnectFromDevice:_device];
        _device = device;
        [self connectToDevice:_device];
    }
}


@end
