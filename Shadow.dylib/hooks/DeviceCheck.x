
#import "hooks.h"

%group shadowhook_DeviceCheck
// %hook DCDevice
// - (BOOL)isSupported {
//     // maybe returning unsupported can skip some app attest token generations
// 	return NO;
// }
// %end

%hook UIDevice
+ (BOOL)isJailbroken {
    return NO;
}

- (BOOL)isJailBreak {
    return NO;
}

- (BOOL)isJailBroken {
    return NO;
}

- (BOOL)getPerk{
    return NO;
}
%end

// %hook SFAntiPiracy
// + (int)isJailbroken {
// 	// Probably should not hook with a hard coded value.
// 	// This value may be changed by developers using this library.
// 	// Best to defeat the checks rather than skip them.
// 	return 4783242;
// }
// %end

%hook JailbreakDetectionVC
- (BOOL)isJailbroken {
    return NO;
}
%end

%hook DTTJailbreakDetection
+ (BOOL)isJailbroken {
    // NSLog(@"[+] DTTJailbreak");
    return NO;
}
%end

%hook FlurryUtil
- (BOOL)deviceIsjailbroken { return NO; }
%end

%hook STKDevice
- (BOOL)containsJailbrokenFiles { return NO; }
- (BOOL)containsJailbrokenPermissions { return NO; }
- (BOOL)isJailbroken { return NO; }
%end

%hook CPrBaseController
- (BOOL)jAilBrokenSimulator{
    NSLog(@"[+] CPrBase");
    return NO;
}
%end 

%hook IOSSecuritySuite
+ (BOOL)amIJailbroken { return NO; }
+ (BOOL)isDebugged { return NO; }
+ (BOOL)amIDebugged { return NO; }
+ (BOOL)amIRunInEmulator { return NO; }
%end

%hook ANSMetadata
- (BOOL)computeIsJailbroken {
    return NO;
}

- (BOOL)isJailbroken {
    return NO;
}
%end

%hook AppsFlyerUtils
+ (BOOL)isJailBroken{
    return NO;
}

+ (BOOL)isJailbrokenWithSkipAdvancedJailbreakValidation:(BOOL)a { 
    return NO; 
}
%end

%hook AppsflyerLib
- (BOOL)skipAdvancedJailbreakValidation {
    return YES;
}

- (void)setSkipAdvancedJailbreakValidation:(BOOL)a { 
    %orig(YES);
}

- (BOOL)isEmulator { return NO; }
- (BOOL)isRunningOnVirtualMachine { return NO; }
%end

%hook AppsFlyerAttribution
+ (BOOL)isJailBroken { return NO; }
+ (BOOL)deviceIsCompromised { return NO; }
+ (BOOL)isDeviceRooted { return NO; }
%end

%hook AFSDKChecksum
- (id)calculateV2valueWithTimestamp:(id)timestamp 
                                uid:(id)uid 
                      systemVersion:(id)systemVersion 
                    firstLaunchDate:(id)firstLaunchDate 
                      AFSDKVersion:(id)AFSDKVersion 
                        isSimulator:(BOOL)isSimulator 
                        isDevBuild:(BOOL)isDevBuild 
                       isJailbroken:(BOOL)isJailbroken 
                    isCounterValid:(BOOL)isCounterValid 
               isDebuggerAttached:(BOOL)isDebuggerAttached {
    return %orig(timestamp, uid, systemVersion, firstLaunchDate, AFSDKVersion, NO, NO, NO, YES, NO);
}

- (id)calculateV2SanityFlagsWithIsSimulator:(BOOL)isSimulator 
                                isDevBuild:(BOOL)isDevBuild 
                               isJailbroken:(BOOL)isJailbroken 
                            isCounterValid:(BOOL)isCounterValid 
                       isDebuggerAttached:(BOOL)isDebuggerAttached {
    return %orig(NO, NO, NO, YES, NO);
}
%end


%hook jailBreak
+ (bool)isJailBreak {
    return false;
}
%end

%hook BugsnagDevice
- (BOOL)jailbroken { return NO; }
%end

%hook BugsnagSessionTracker
- (BOOL)isJailbroken { return NO; }
- (BOOL)hasModifiedSystemFiles { return NO; }
- (BOOL)isDeviceTampered { return NO; }
%end


%hook METATerminationReporterTerminationReport
- (BOOL)isJailbroken { return NO; }
%end

%hook GBDeviceInfo
- (BOOL)isJailbroken {
    return NO;
}
%end

%hook CMARAppRestrictionsDelegate
- (bool)isDeviceNonCompliant {
    return false;
}
%end

%hook ADYSecurityChecks
+ (bool)isDeviceJailbroken {
    return false;
}
%end

%hook UBReportMetadataDevice
- (void *)is_rooted {
    return NULL;
}
%end

%hook UtilitySystem
+ (bool)isJailbreak {
    return false;
}
%end

%hook GemaltoConfiguration
+ (bool)isJailbreak {
    return false;
}
%end

%hook PAGDeviceHelper
- (bool)bu_isJailBroken { return false; }
- (BOOL)isDeviceCompromised { return NO; }
%end

%hook CPWRDeviceInfo
- (bool)isJailbroken {
    return false;
}
%end

%hook CPWRSessionInfo
- (bool)isJailbroken {
    return false;
}
%end

%hook KSSystemInfo
+ (bool)isJailbroken {
    return false;
}
%end

%hook EMDSKPPConfiguration
- (bool)jailBroken {
    return false;
}
%end

%hook EnrollParameters
- (void *)jailbroken {
    return NULL;
}
%end

%hook EMDskppConfigurationBuilder
- (bool)jailbreakStatus {
    return false;
}
%end

%hook FCRSystemMetadata
- (bool)isJailbroken {
    return false;
}
%end

%hook CLSAnalyticsMetadataController
+ (BOOL)hostJailbroken { return NO; }
%end

%hook Utility
- (BOOL)isJailBreak { return NO; }
%end

%hook DeviceInfoManager
- (BOOL)isJailBreak { return NO; }
%end

%hook STLivenessDetector
- (BOOL)isJailbroken { return NO; }
%end

%hook BLYDevice
+ (BOOL)isJailBreak { return NO; }
- (BOOL)isJailbroken { return NO; }
// - (unsigned long)jailbrokenStatus { return 0; }
- (BOOL)isRooted { return NO; }
- (BOOL)isTampered { return NO; }
- (BOOL)isDebugged { return NO; }
%end

%hook MobClick
+ (BOOL)isJailbroken { return NO; }
%end

%hook UMUtils
+ (BOOL)isDeviceJailBreak { return NO; }
%end

%hook IFlySystemInfo
+ (BOOL)isJailbroken { return NO; }
%end

// %hook NSDictionary
// - (id)objectForKey:(id)aKey {
//     if ([aKey isKindOfClass:NSString.class] && [@"DISABLE_JAILBREAK_DETECTION" isEqualToString:aKey]) {
//         return @(YES);
//     }
//     return %orig;
// }
// %end

%hook KeyOSPlayerInternal
- (BOOL)isJailbroken { return NO; }
%end

%hook AIMetaDataCollector
+ (id)getDeviceJailbrokenState {
    return [NSNumber numberWithBool:NO];
}
%end

%hook PiracyProtection
+ (BOOL)isJailbroken { return NO; }
%end

%hook FMFeatureUtils
- (BOOL)isFastMetricsEnabled { return YES; }
%end


%hook v_VDMap
- (bool)isJailbrokenDetected {
    return false;
}

- (bool)isJailBrokenDetectedByVOS {
    return false;
}

- (bool)isDFPHookedDetecedByVOS {
    return false;
}

- (bool)isCodeInjectionDetectedByVOS {
    return false;
}

- (bool)isDebuggerCheckDetectedByVOS {
    return false;
}

- (bool)isAppSignerCheckDetectedByVOS {
    return false;
}

- (bool)v_checkAModified {
    return false;
}

- (bool)isRuntimeTamperingDetected {
    return false;
}
%end

%hook SDMUtils
- (BOOL)isJailBroken {
    return NO;
}
%end

%hook OneSignalJailbreakDetection
+ (BOOL)isJailbroken {
    return NO;
}
%end

%hook DigiPassHandler
- (BOOL)rootedDeviceTestResult {
    return NO;
}
%end

%hook AWMyDeviceGeneralInfo
- (bool)isCompliant {
    return true;
}
%end

%hook MCPDemoAppDelegate
- (bool)isJailbroken { return false; }
%end

%hook AAAPBootStartPoint
+ (void)load { }
%end

%hook GULSwizzler
+ (void)swizzleClass:(Class)aClass
            selector:(SEL)selector
     isClassSelector:(BOOL)isClassSelector
           withBlock:(id)block {}
%end

%hook _TtC5Chase11AuthManager
- (bool)isJMC { return false; }
%end


%hook DTXSessionInfo
- (bool)isJailbroken {
    return false;
}
%end

%hook DTXDeviceInfo
- (bool)isJailbroken {
    return false;
}
%end

%hook JailbreakDetection
- (bool)jailbroken {
    return false;
}
- (BOOL)jailbroken { return NO; }
%end

%hook jailBrokenJudge
- (bool)isJailBreak {
    return false;
}

- (bool)isCydiaJailBreak {
    return false;
}

- (bool)isApplicationsJailBreak {
    return false;
}

- (bool)ischeckCydiaJailBreak {
    return false;
}

- (bool)isPathJailBreak {
    return false;
}

- (bool)boolIsjailbreak {
    return false;
}
%end

%hook FBAdBotDetector
- (bool)isJailBrokenDevice {
    return false;
}
%end

%hook TNGDeviceTool
+ (bool)isJailBreak {
    return false;
}

+ (bool)isJailBreak_file {
    return false;
}

+ (bool)isJailBreak_cydia {
    return false;
}

+ (bool)isJailBreak_appList {
    return false;
}

+ (bool)isJailBreak_env {
    return false;
}
%end

%hook DTDeviceInfo
+ (bool)isJailbreak {
    return false;
}
%end

%hook SecVIDeviceUtil
+ (bool)isJailbreak {
    return false;
}   
%end

%hook RVPBridgeExtension4Jailbroken
- (bool)isJailbroken {
    return false;
}
%end

%hook ISDeviceInfoService
- (bool)isJailbroken { return false; }
%end

%hook ZDetection
+ (bool)isZDetectionAvailable {
    return false;
}

+ (bool)isDebugged {
    return false;
}

+ (bool)isRootedOrJailbroken {
    return false;
}
%end

%hook ThreatChecks
+ (void)checkJailbreak { }
+ (bool)checkIfHooked:(id)arg2 method_name:(id)arg3 { return false; }
+ (void)doThreatChecks { }
+ (void)doInitChecks { }
+ (void)doPortCheck:(id)arg2 { }
%end

%hook JailbreakDetector
+ (bool)isJailbrokenWithReasons:(id)arg2 { return false; }
+ (void)check_system_tampering { }
+ (void)check_system_tampering_inner { }
+ (void)check_app_tampering { }
+ (void)reportSystemTamperingReason:(id)arg2 { }
+ (void)reportAppTamperingReason:(id)arg2 { }
+ (void)reportFileSystemModificationReason:(id)arg2 { }
+ (void)reportElevationOfPrivilegesReason:(id)arg2 { }
+ (void)reportJailbreakReason:(id)arg2 { }
%end

// %hook NSUserDefaults
// - (BOOL)boolForKey:(NSString *)aKey {
//     if ([aKey isKindOfClass:[NSString class]] && [@"ZimperiumShouldDoThreatChecks" isEqualToString:aKey]) {
//         return NO;
//     }
//     return %orig;
// }
// %end

%hook SecurityCheckHandler
- (BOOL)isTampered { return NO; }
- (BOOL)isSignatureValid { return YES; }
- (BOOL)isDeviceTrusted { return YES; }
%end


%hook ZDetection
+ (BOOL)isRootedOrJailbroken { return NO; }
+ (BOOL)isDebugged { return NO; }
+ (BOOL)isCodeInjected { return NO; }
+ (BOOL)isMalwareDetected { return NO; }
%end


%hook TZSKPaymentParamsTool
+ (BOOL)detectCurrentDeviceIsJailbroken {
    return NO;
}
%end

%hook FFMClassOneFive
- (NSMutableDictionary *)cofiSymbolOneNine {
    return [@{@(0): @(7), @(1577865600): @(44)} mutableCopy];
}
%end

%hook JailMonkey
+ (BOOL)isJailBroken { return NO; }
+ (BOOL)isDebugged { return NO; }
+ (BOOL)hasCydia { return NO; }
+ (BOOL)canViolateSandbox { return NO; }
%end

%hook AMA_JailbreakCheck
- (int)jailbroken {
    return 0;
}
%end

%hook YMM_YX_SSJailbreakCheck
+ (BOOL)isProcessInfoAvailable { return NO; }
+ (int)filesExistCheck { return 0; }
+ (int)cydiaCheck { return 0; }
+ (int)isJailbroken { return 0; }
+ (int)plistCheck { return 0; }
+ (int)symbolicLinksCheck { return 0; }
+ (int)processesCheck { return 0; }
+ (int)systemCheck { return 0; }
+ (id)runningProcesses { return nil; }
%end

%hook AppdomeSecurity
+ (BOOL)isDeviceCompromised { return NO; }
+ (BOOL)isRunningOnEmulator { return NO; }
+ (BOOL)isTampered { return NO; }
+ (BOOL)isCodeInjected { return NO; }
%end


%end

%group shadowhook_VPNCheck

%hook ISDeviceInfoService
+ (BOOL)isVPNEnabled { return NO; }
%end


%hook JailMonkey
- (BOOL)canMockLocation { return NO; }
- (bool)canMockLocation { return false; }
%end

%hook iOSSecuritySuite
- (BOOL)isProxyEnabled { return NO; }
%end


%hook VGRTCPeerConnectionFactoryOptions
- (BOOL)ignoreVPNNetworkAdapter { return YES; }
- (void)setIgnoreVPNNetworkAdapter:(BOOL)a { 
    %orig(YES);
}
%end

%hook AppsFlyerUtils
+ (BOOL)isVPNConnected { return NO; }
- (BOOL)VPNCollectionEnabled { return NO; }
- (void)setVPNCollectionEnabled:(BOOL)a { 
    %orig(NO);
}
%end

%hook AppsFlyerLib
+ (BOOL)isProxyEnabled { return NO; }
%end


%hook METANetworkReachabilityMonitor
- (BOOL)usingVPN { return NO; }
%end

%hook FBSCNReachabilityMonitor
- (BOOL)connectedToVPN { return NO; }
%end

%hook FBReachabilityAnnouncer
- (BOOL)connectedToVPN { return NO; }
%end

%hook FBNWPathMonitor
- (BOOL)connectedToVPN { return NO; }
%end
%end

%group shadowhook_LocationCheck

%hook BMGeoLocation
- (BOOL)hasIsMocked { return NO; }
- (BOOL)isMocked { return NO; }
- (void)setIsMocked:(BOOL)a { 
    %orig(NO);
}
%end

%hook BMGeoLocation_Builder
- (id)setIsMocked:(bool)a { 
    return %orig(false); 
}
%end

%hook USRVInitializeStateCreate
- (void)setIsMocked:(BOOL)a { 
    %orig(NO);
}
%end

%hook CheckVPNViewController
- (void)dealWithVPN:(bool)a loading:(id)b { 
    %orig(false,b);
}
%end
%end

void shadowhook_DeviceCheck(HKSubstitutor* hooks) {
    %init(shadowhook_DeviceCheck);
    %init(shadowhook_VPNCheck);
    %init(shadowhook_LocationCheck);
}
