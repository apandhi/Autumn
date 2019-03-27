//
//  USB.m
//  Autumn
//

#import "USB.h"
#import <IOKit/ps/IOPSKeys.h>

#include <IOKit/usb/IOUSBLib.h>

static JSValue* module;
static IONotificationPortRef notifyPort;
static io_iterator_t portIterator;

@interface UsbDeviceInfoContainer: NSObject
@property io_object_t notification;
@property NSDictionary* info;
@end
@implementation UsbDeviceInfoContainer
@end

static NSMapTable<NSNumber*, UsbDeviceInfoContainer*>* infos;


/**
 * module USB
 *
 * Handle USB connect/disconnect events.
 */
@implementation USB

/**
 * static onConnected: (info: {
 *   name:string,
 *   vendor:string,
 *   serial:string,
 *   uid?:number
 * }) => void;
 *
 * Set a function that will be called when a USB device is connected.
 *
 * The 'uid' info field is unique and persistent even across reboots.
 */

/**
 * static onDisconnected: (info: {
 *   name:string,
 *   vendor:string,
 *   serial:string,
 *   uid?:number
 * }) => void;
 *
 * Set a function that will be called when a USB device is disconnected.
 *
 * The 'uid' info field is unique and persistent even across reboots.
 */

+ (void)startModule:(JSValue *)ctor {
    module = ctor;
    module[@"onConnected"] = [JSValue valueWithUndefinedInContext: module.context];
    module[@"onDisconnected"] = [JSValue valueWithUndefinedInContext: module.context];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        infos = [NSMapTable strongToStrongObjectsMapTable];
        notifyPort = IONotificationPortCreate(kIOMasterPortDefault);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPort), kCFRunLoopDefaultMode);
        if (!IOServiceAddMatchingNotification(notifyPort, kIOMatchedNotification, IOServiceMatching(kIOUSBDeviceClassName), DeviceAdded, NULL, &portIterator)) {
            DeviceAdded(nil, portIterator);
        }
    });
}

+ (void)stopModule {
    module = nil;
    
//    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPort), kCFRunLoopDefaultMode);
//    IONotificationPortDestroy(notifyPort);
//    IOObjectRelease(portIterator);
}

static void DeviceAdded(void *refCon, io_iterator_t iterator) {
    kern_return_t returnCode = KERN_FAILURE;
    io_object_t usbDevice;
    while ((usbDevice = IOIteratorNext(iterator))) {
        NSMutableDictionary* info = [NSMutableDictionary dictionary];
        
        io_name_t name;
        if (IORegistryEntryGetName(usbDevice, name) != KERN_SUCCESS) {
            name[0] = '\0';
        }
        info[@"name"] = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        
        NSString* vendor = (__bridge_transfer NSString*)IORegistryEntrySearchCFProperty(usbDevice, kIOServicePlane, CFSTR(kUSBVendorString), kCFAllocatorDefault, kIORegistryIterateRecursively);
        info[@"vendor"] = vendor ?: @"";
        
        NSString* serialNumber = (__bridge_transfer NSString*)IORegistryEntrySearchCFProperty(usbDevice, kIOServicePlane, CFSTR(kUSBSerialNumberString), kCFAllocatorDefault, kIORegistryIterateRecursively);
        info[@"serial"] = serialNumber ?: @"";
        
        IOCFPlugInInterface **theInterface;
        SInt32 theScore;
        kern_return_t ret = IOCreatePlugInInterfaceForService(usbDevice,
                                                              kIOUSBDeviceUserClientTypeID,
                                                              kIOCFPlugInInterfaceID,
                                                              &theInterface,
                                                              &theScore);
        
        if (ret == kIOReturnSuccess) {
            IOUSBDeviceInterface** deviceInterface;
            HRESULT hres = (*theInterface)->QueryInterface(theInterface,
                                                           CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                           (LPVOID*)&deviceInterface);
            
            if (SUCCEEDED(hres)) {
                UInt32 uid;
                (*deviceInterface)->GetLocationID(deviceInterface, &uid);
                NSNumber* infosKey = @(uid);
                info[@"uid"] = infosKey;
                
                (*deviceInterface)->Release(deviceInterface);
                (*theInterface)->Release(theInterface);
                
                JSValue* callback = module[@"onConnected"];
                if ([callback isInstanceOf: module.context[@"Function"]]) {
                    [callback callWithArguments: @[info]];
                }
                
                UsbDeviceInfoContainer* usbDeviceInfoContainer = [[UsbDeviceInfoContainer alloc] init];
                usbDeviceInfoContainer.info = info;
                [infos setObject: usbDeviceInfoContainer
                          forKey: infosKey];
                
                io_object_t notification;
                returnCode = IOServiceAddInterestNotification(notifyPort,
                                                              usbDevice,
                                                              kIOGeneralInterest,
                                                              DeviceRemoved,
                                                              (__bridge void*)infosKey,
                                                              &notification);
                usbDeviceInfoContainer.notification = notification;
            }
        }
        else {
            NSLog(@"USB added event returned = %x", ret);
        }
        
        IOObjectRelease(usbDevice);
    }
}

static void DeviceRemoved(void *refCon, io_service_t service, natural_t messageType, void *messageArgument) {
    if (messageType == kIOMessageServiceIsTerminated) {
        NSNumber* infosKey = (__bridge NSNumber*)refCon;
        UsbDeviceInfoContainer* usbDeviceInfoContainer = [infos objectForKey: infosKey];
        
        JSValue* callback = module[@"onDisconnected"];
        if ([callback isInstanceOf: module.context[@"Function"]]) {
            [callback callWithArguments: @[usbDeviceInfoContainer.info]];
        }
        
        IOObjectRelease(usbDeviceInfoContainer.notification);
        
        [infos removeObjectForKey: infosKey];
    }
}

@end
