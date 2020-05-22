#import "LandmarkRecognitionPlugin.h"
#if __has_include(<landmark_recognition/landmark_recognition-Swift.h>)
#import <landmark_recognition/landmark_recognition-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "landmark_recognition-Swift.h"
#endif

@implementation LandmarkRecognitionPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLandmarkRecognitionPlugin registerWithRegistrar:registrar];
}
@end
