#import "FlCamera.h"
#import "FBLPromise.h"

#if __has_include(<fl_camera/fl_camera-Swift.h>)
#import <fl_camera/fl_camera-Swift.h>
#else
//#import "fl_camera-Swift.h"
#endif
@implementation FlCamera

+ (void)registerWithRegistrar {
  [SwiftFlCameraPlugin registerWithRegistrar:registrar];
}
@end
