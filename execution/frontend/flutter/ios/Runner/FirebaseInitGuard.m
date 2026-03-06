// FirebaseInitGuard.m
// Prevents EXC_CRASH (SIGABRT) at FIRApp.m:307 caused by duplicate Firebase
// initialization. Patches +[FIRApp configureWithName:options:] at runtime to
// be idempotent: if the named app already exists the call is a no-op.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

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
        typedef id (*AppNamedIMP)(Class, SEL, id);
        SEL appNamedSel = NSSelectorFromString(@"appNamed:");
        id existing = ((AppNamedIMP)objc_msgSend)(NSClassFromString(@"FIRApp"), appNamedSel, name);
        if (existing != nil) {
            NSLog(@"[BingeQuest] Firebase app '%@' already configured — duplicate init prevented.", name);
            return;
        }
        ((void (*)(id, SEL, id, id))origIMP)(self, configureSel, name, opts);
    });

    method_setImplementation(configureMethod, safeIMP);
}

@end
