// FirebaseInitGuard.m
// Prevents EXC_CRASH (SIGABRT) at FIRApp.m:307 from duplicate Firebase init.
//
// Root cause: the first configure stores the app under "__FIRAPP_DEFAULT" but
// FLTFirebaseCorePlugin requests it as "[DEFAULT]", so an appNamed: existence
// check returns nil even when Firebase is already configured. Instead we wrap
// the original IMP in @try/@catch — ObjC can catch NSException, Dart cannot.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface BQFirebaseInitGuard : NSObject
@end

@implementation BQFirebaseInitGuard

+ (void)load {
    Class FIRApp = NSClassFromString(@"FIRApp");
    if (!FIRApp) return;

    SEL configureSel = NSSelectorFromString(@"configureWithName:options:");
    Method configureMethod = class_getClassMethod(FIRApp, configureSel);
    if (!configureMethod) return;

    IMP origIMP = method_getImplementation(configureMethod);

    IMP safeIMP = imp_implementationWithBlock(^(__unsafe_unretained id self, NSString *name, id opts) {
        @try {
            ((void (*)(id, SEL, id, id))origIMP)(self, configureSel, name, opts);
        } @catch (NSException *exception) {
            // Firebase throws NSInternalInconsistencyException when configureWithName:options:
            // is called a second time for the same app name. Suppress it so the app launches.
            NSLog(@"[BingeQuest] Firebase duplicate init suppressed for app '%@': %@",
                  name, exception.reason);
        }
    });

    method_setImplementation(configureMethod, safeIMP);
}

@end
