
#import "RNReactNativeBleMidi.h"
#import <UIKit/UIKit.h>
#import <CoreAudioKit/CoreAudioKit.h>

#include <CoreFoundation/CoreFoundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import <MIKMIDI/MIKMIDI.h>




@implementation RNReactNativeBleMidi

@property (nonatomic, strong) MIKMIDIDeviceManager *deviceManager;
@property (nonatomic, strong) MIKMIDIDevice    *device;
@property (nonatomic, strong) id connectionToken;

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
    if (!device) return;
    [self.deviceManager disconnectConnectionForToken:self.connectionToken];

    self.textView.text = @"";
}

- (void)connectToDevice:(MIKMIDIDevice *)device
{
    if (!device) return;
    NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
    if (![sources count]) return;
    MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
    NSError *error = nil;

    id connectionToken = [self.deviceManager connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {

        NSMutableString *textViewString = [self.textView.text mutableCopy];
        for (MIKMIDIChannelVoiceCommand *command in commands) {
            if ((command.commandType | 0x0F) == MIKMIDICommandTypeSystemMessage) continue;

            [[UIApplication sharedApplication] handleMIDICommand:command];

            [textViewString appendFormat:@"Received: %@\n", command];
            NSLog(@"Received: %@", command);
        }
        self.textView.text = textViewString;
    }];
    if (!connectionToken) NSLog(@"Unable to connect to input: %@", error);
    self.connectionToken = connectionToken;
}



RCT_REMAP_METHOD(send,
                 connectWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject
                 )
{
    NSDate *date = [NSDate date];
    MIKMIDINoteOnCommand *noteOn = [MIKMIDINoteOnCommand noteOnCommandWithNote:60 velocity:127 channel:0 timestamp:date];
    MIKMIDINoteOffCommand *noteOff = [MIKMIDINoteOffCommand noteOffCommandWithNote:60 velocity:0 channel:0 timestamp:[date dateByAddingTimeInterval:0.5]];

    MIKMIDIDeviceManager *dm = [MIKMIDIDeviceManager sharedDeviceManager];
    [dm sendCommands:@[noteOn, noteOff] toEndpoint:destinationEndpoint error:&error];
}


RCT_REMAP_METHOD(connect,
                 connectWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject
                 )
{
    CABTMIDILocalPeripheralViewController *viewController = [[CABTMIDILocalPeripheralViewController alloc] init];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;


    viewController.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(hideView:)];

    rootViewController.modalPresentationStyle = UIModalPresentationPopover;

    [rootViewController presentViewController:viewController animated:YES completion:^{
        NSLog(@"ok");
        [self.deviceManager connectDevice];

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
