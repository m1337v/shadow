#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wframe-address"

#import "hooks.h"
#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <fishhook/fishhook.h>
#include <dlfcn.h>
#include <mach/mach.h>

// Global collections
static NSMutableArray<NSDictionary *>* _shdw_dyld_collection = nil;
static NSMutableArray<NSValue *>* _shdw_dyld_add_image = nil;
static NSMutableArray<NSValue *>* _shdw_dyld_remove_image = nil;
static BOOL _shdw_dyld_error = NO;

//------------------------------------------------------------------------------
#pragma mark - Original Function Pointers

static uint32_t (*original_dyld_image_count)(void);
static const char* (*original_dyld_get_image_name)(uint32_t image_index);
static const struct mach_header* (*original_dyld_get_image_header)(uint32_t image_index);
static intptr_t (*original_dyld_get_image_vmaddr_slide)(uint32_t image_index);
static void (*original_dyld_register_func_for_add_image)(void (*func)(const struct mach_header*, intptr_t));
static void (*original_dyld_register_func_for_remove_image)(void (*func)(const struct mach_header*, intptr_t));
static kern_return_t (*original_task_info)(task_name_t target_task, task_flavor_t flavor,
                                           task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt);
static void* (*original_dlopen)(const char* path, int mode);
static void* (*original_dlopen_internal)(const char* path, int mode, void* caller);
static bool (*original_dlopen_preflight)(const char* path);
static char* (*original_dlerror)(void);
static void* (*original_dlsym)(void* handle, const char* symbol);

// For the fishhook-based dladdr hook:
static int (*orig_dladdr)(const void* addr, Dl_info* info);

  
//------------------------------------------------------------------------------
#pragma mark - Utility: isCallerTweak

#undef isCallerTweak
bool isCallerTweak() {
    @synchronized(_shdw_dyld_collection) {
        NSArray* dyld_collection = [_shdw_dyld_collection copy];
        void *retaddrs[] = {
            __builtin_return_address(0),
            __builtin_return_address(1),
            __builtin_return_address(2),
            __builtin_return_address(3),
            __builtin_return_address(4),
            __builtin_return_address(5),
            __builtin_return_address(6),
            __builtin_return_address(7),
        };
        for (int i = 0; i < 8; i++) {
            void *addr = __builtin_extract_return_addr(retaddrs[i]);
            if (!addr) continue;
            if (![_shadow isAddrExternal:addr]) {
                return false;
            }
            const char* image_path = dyld_image_path_containing_address(addr);
            if (!image_path) continue;
            for (NSString *imgPath in dyld_collection) {
                if (!strcmp([imgPath UTF8String], image_path)) {
                    return false;
                }
            }
            const char* blacklist[] = {
                "systemhook.dylib",
                "libstdc++.6.dylib",
                "libsubstrate.dylib",
                "libhooker.dylib",
                "frida-agent.dylib",
                "libellekit.dylib",
                "Choicy.dylib",
                "libroot.dylib",
                "Crane.dylib",
                "libsandy.dylib",
                "Shadow.dylib",
                "libinjector.dylib",
                "HookKit.framework",
                "RootBridge.framework",
                "Modulous.framework",
                "Shadow.framework",
                NULL
            };
            for (int j = 0; blacklist[j] != NULL; j++) {
                if (strstr(image_path, blacklist[j])) {
                    return true;
                }
            }
        }
    }
    return false;
}


//------------------------------------------------------------------------------
#pragma mark - dyld Hook Functions

static uint32_t replaced_dyld_image_count(void) {
    uint32_t count = original_dyld_image_count();
    NSMutableSet *blacklistSet = [NSMutableSet setWithObjects:
        @"systemhook.dylib", @"libstdc++.6.dylib", @"libsubstrate.dylib",
        @"libhooker.dylib", @"frida-agent.dylib", @"libellekit.dylib",
        @"Choicy.dylib", @"libroot.dylib", @"Crane.dylib", @"libsandy.dylib",
        @"Shadow.dylib", @"libinjector.dylib", @"HookKit.framework",
        @"RootBridge.framework", @"Modulous.framework", @"Shadow.framework", nil];
    int hidden_dylibs = 0;
    for (uint32_t i = 0; i < count; i++) {
        const char* image_name = original_dyld_get_image_name(i);
        if (image_name) {
            NSString *imageNameStr = [NSString stringWithUTF8String:image_name];
            if ([blacklistSet containsObject:imageNameStr]) {
                hidden_dylibs++;
            }
        }
    }
    return count - hidden_dylibs;
}

static const struct mach_header* replaced_dyld_get_image_header(uint32_t image_index) {
    if (isCallerTweak()) {
        return original_dyld_get_image_header(image_index);
    }
    NSArray* dyld_collection = [_shdw_dyld_collection copy];
    if (image_index < [dyld_collection count]) {
        return (struct mach_header *)[dyld_collection[image_index][@"mach_header"] pointerValue];
    }
    return NULL;
}

static intptr_t replaced_dyld_get_image_vmaddr_slide(uint32_t image_index) {
    if (isCallerTweak()) {
        return original_dyld_get_image_vmaddr_slide(image_index);
    }
    NSArray* dyld_collection = [_shdw_dyld_collection copy];
    if (image_index < [dyld_collection count]) {
        return (intptr_t)[dyld_collection[image_index][@"slide"] pointerValue];
    }
    return 0;
}

static const char* replaced_dyld_get_image_name(uint32_t image_index) {
    if (!original_dyld_get_image_name) {
        return NULL;
    }
    const char* original_name = original_dyld_get_image_name(image_index);
    if (isCallerTweak()) {
        return original_name;
    }
    if (!original_name) return NULL;
    const char* blacklist[] = {
        "systemhook.dylib", "libstdc++.6.dylib", "libsubstrate.dylib",
        "libhooker.dylib", "frida-agent.dylib", "libellekit.dylib",
        "Choicy.dylib", "libroot.dylib", "Crane.dylib", "libsandy.dylib",
        "Shadow.dylib", "libinjector.dylib", "HookKit.framework",
        "RootBridge.framework", "Modulous.framework", "Shadow.framework", NULL
    };
    for (int i = 0; blacklist[i] != NULL; i++) {
        if (strstr(original_name, blacklist[i])) {
            return "/usr/lib/libSystem.B.dylib";
        }
    }
    return original_name;
}

void hook_dyld_image_name() {
    struct rebinding rebindings[] = {
        {"_dyld_get_image_name", (void*)replaced_dyld_get_image_name, (void**)&original_dyld_get_image_name},
    };
    rebind_symbols(rebindings, 1);
}

void hook_dyld_image_count() {
    struct rebinding rebindings[] = {
        {"_dyld_image_count", (void*)replaced_dyld_image_count, (void**)&original_dyld_image_count},
    };
    rebind_symbols(rebindings, 1);
}


//------------------------------------------------------------------------------
#pragma mark - dyld Register Functions

static void replaced_dyld_register_func_for_add_image(void (*func)(const struct mach_header*, intptr_t)) {
    if (isCallerTweak() || !func) {
        return original_dyld_register_func_for_add_image(func);
    }
    [_shdw_dyld_add_image addObject:[NSValue valueWithPointer:func]];
    NSArray* dyld_collection = [_shdw_dyld_collection copy];
    if(dyld_collection) {
        for(NSDictionary* dylib in dyld_collection) {
            func((struct mach_header *)[dylib[@"mach_header"] pointerValue],
                 (intptr_t)[dylib[@"slide"] pointerValue]);
        }
    }
}

static void replaced_dyld_register_func_for_remove_image(void (*func)(const struct mach_header*, intptr_t)) {
    if (isCallerTweak() || !func) {
        return original_dyld_register_func_for_remove_image(func);
    }
    [_shdw_dyld_remove_image addObject:[NSValue valueWithPointer:func]];
}


//------------------------------------------------------------------------------
#pragma mark - dlopen / dlsym / dlerror Hooks

static void* replaced_dlopen(const char* path, int mode) {
    if (isCallerTweak() || !path) {
        return original_dlopen(path, mode);
    }
    if (path[0] != '/') {
        if (![_shadow isPathRestricted:@(path) options:@{
            kShadowRestrictionWorkingDir : @"/usr/lib",
            kShadowRestrictionFileExtension : @"dylib"
        }]) {
            return original_dlopen(path, mode);
        }
    } else {
        if (![_shadow isCPathRestricted:path]) {
            return original_dlopen(path, mode);
        }
    }
    _shdw_dyld_error = YES;
    return NULL;
}

static void* replaced_dlopen_internal(const char* path, int mode, void* caller) {
    if (isCallerTweak() || !path) {
        return original_dlopen_internal(path, mode, caller);
    }
    if (path[0] != '/') {
        if (![_shadow isPathRestricted:@(path) options:@{
            kShadowRestrictionWorkingDir : @"/usr/lib",
            kShadowRestrictionFileExtension : @"dylib"
        }]) {
            return original_dlopen_internal(path, mode, caller);
        }
    } else {
        if (![_shadow isCPathRestricted:path]) {
            return original_dlopen_internal(path, mode, caller);
        }
    }
    _shdw_dyld_error = YES;
    return NULL;
}

static bool replaced_dlopen_preflight(const char* path) {
    if (isCallerTweak() || !path) {
        return original_dlopen_preflight(path);
    }
    if (path[0] != '/') {
        if (![_shadow isPathRestricted:@(path) options:@{
            kShadowRestrictionWorkingDir : @"/usr/lib",
            kShadowRestrictionFileExtension : @"dylib"
        }]) {
            return original_dlopen_preflight(path);
        }
    } else {
        if (![_shadow isCPathRestricted:path]) {
            return original_dlopen_preflight(path);
        }
    }
    return false;
}

static char* replaced_dlerror(void) {
    if (isCallerTweak() || !_shdw_dyld_error) {
        return original_dlerror();
    }
    _shdw_dyld_error = NO;
    return "library not found";
}

static void* replaced_dlsym(void* handle, const char* symbol) {
    if (isCallerTweak()) {
        return original_dlsym(handle, symbol);
    }
    void* addr = original_dlsym(handle, symbol);
    if (![_shadow isAddrRestricted:addr]) {
        return addr;
    }
    if (symbol) {
        NSLog(@"dlsym: restricted symbol lookup: %s", symbol);
    }
    _shdw_dyld_error = YES;
    return NULL;
}


//------------------------------------------------------------------------------
#pragma mark - dladdr Hook (using fishhook)

int hooked_dladdr(const void* addr, Dl_info* info) {
    int result = orig_dladdr(addr, info);
    if (result && info && info->dli_fname) {
        const char* blacklist[] = {
            "systemhook.dylib", "libstdc++.6.dylib", "libsubstrate.dylib",
            "libhooker.dylib", "frida-agent.dylib", "libellekit.dylib",
            "Choicy.dylib", "libroot.dylib", "Crane.dylib", "libsandy.dylib",
            "Shadow.dylib", "libinjector.dylib", "HookKit.framework",
            "RootBridge.framework", "Modulous.framework", "Shadow.framework", NULL
        };
        for (int i = 0; blacklist[i] != NULL; i++) {
            if (strstr(info->dli_fname, blacklist[i])) {
                info->dli_fname = "/usr/lib/libSystem.B.dylib";
                break;
            }
        }
    }
    return result;
}

void hook_dladdr() {
    struct rebinding rebindings[] = {
        {"dladdr", (void*)hooked_dladdr, (void**)&orig_dladdr},
    };
    rebind_symbols(rebindings, 1);
}


//------------------------------------------------------------------------------
#pragma mark - task_info Hook

static kern_return_t replaced_task_info(task_name_t target_task, task_flavor_t flavor,
                                         task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt) {
    if (isCallerTweak()) {
        return original_task_info(target_task, flavor, task_info_out, task_info_outCnt);
    }
    kern_return_t result = original_task_info(target_task, flavor, task_info_out, task_info_outCnt);
    if (flavor == TASK_DYLD_INFO && result == KERN_SUCCESS) {
        struct task_dyld_info *task_info = (struct task_dyld_info *) task_info_out;
        struct dyld_all_image_infos *dyld_info = (struct dyld_all_image_infos *) task_info->all_image_info_addr;
        dyld_info->infoArrayCount = 5;
        dyld_info->uuidArrayCount = 5;
        return KERN_SUCCESS;
    }
    return result;
}

void hook_task_info() {
    struct rebinding rebindings[] = {
        {"task_info", (void*)replaced_task_info, (void**)&original_task_info},
    };
    rebind_symbols(rebindings, 1);
}


//------------------------------------------------------------------------------
#pragma mark - dyld Event Handlers

void shadowhook_dyld_updatelibs(const struct mach_header* mh, intptr_t vmaddr_slide) {
    if (!mh) {
        return;
    }
    
    const char* image_path = dyld_image_path_containing_address(mh);
    if (image_path) {
        NSString* path = [NSString stringWithUTF8String:image_path];
        NSLog(@"dyld: checking lib: %@", path);
        if ([path hasPrefix:@"/System"] ||
            ![_shadow isPathRestricted:path options:@{ kShadowRestrictionEnableResolve : @(NO) }]) {
            NSLog(@"dyld: adding lib: %@", path);
            [_shdw_dyld_collection addObject:@{
                @"name" : path,
                @"mach_header" : [NSValue valueWithPointer:mh],
                @"slide" : [NSValue valueWithPointer:(void *)vmaddr_slide]
            }];
            NSArray* addHandlers = [_shdw_dyld_add_image copy];
            if ([addHandlers count]) {
                NSLog(@"dyld: add_image calling handlers");
                for (NSValue* func_ptr in addHandlers) {
                    void (*func)(const struct mach_header*, intptr_t) = [func_ptr pointerValue];
                    func(mh, vmaddr_slide);
                }
            }
        }
    }
}

void shadowhook_dyld_updatelibs_r(const struct mach_header* mh, intptr_t vmaddr_slide) {
    if (!mh) {
        return;
    }
    
    NSArray* dyld_collection = [_shdw_dyld_collection copy];
    NSDictionary* dylibToRemove = nil;
    for (NSDictionary* dylib in dyld_collection) {
        if ((struct mach_header *)[dylib[@"mach_header"] pointerValue] == mh) {
            dylibToRemove = dylib;
            break;
        }
    }
    if (dylibToRemove) {
        NSLog(@"dyld: removing lib: %@", dylibToRemove[@"name"]);
        [_shdw_dyld_collection removeObject:dylibToRemove];
        NSArray* removeHandlers = [_shdw_dyld_remove_image copy];
        if ([removeHandlers count]) {
            NSLog(@"dyld: remove_image calling handlers");
            for (NSValue* func_ptr in removeHandlers) {
                void (*func)(const struct mach_header*, intptr_t) = [func_ptr pointerValue];
                func(mh, vmaddr_slide);
            }
        }
    }
}


//------------------------------------------------------------------------------
#pragma mark - Main Hook Setup Functions

void shadowhook_dyld(HKSubstitutor* hooks) {
    _shdw_dyld_collection = [NSMutableArray new];
    _shdw_dyld_add_image = [NSMutableArray new];
    _shdw_dyld_remove_image = [NSMutableArray new];
    
    _dyld_register_func_for_add_image(shadowhook_dyld_updatelibs);
    _dyld_register_func_for_remove_image(shadowhook_dyld_updatelibs_r);
    
    hook_dladdr();
    hook_dyld_image_name();
    hook_dyld_image_count();
    hook_task_info();
    
    MSHookFunction((void *)_dyld_get_image_name, (void *)replaced_dyld_get_image_name, (void **)&original_dyld_get_image_name);
    MSHookFunction(_dyld_image_count, replaced_dyld_image_count, (void **)&original_dyld_image_count);
    MSHookFunction(_dyld_get_image_header, replaced_dyld_get_image_header, (void **)&original_dyld_get_image_header);
    MSHookFunction(_dyld_get_image_vmaddr_slide, replaced_dyld_get_image_vmaddr_slide, (void **)&original_dyld_get_image_vmaddr_slide);
    MSHookFunction(_dyld_register_func_for_add_image, replaced_dyld_register_func_for_add_image, (void **)&original_dyld_register_func_for_add_image);
    MSHookFunction(_dyld_register_func_for_remove_image, replaced_dyld_register_func_for_remove_image, (void **)&original_dyld_register_func_for_remove_image);
    MSHookFunction(task_info, replaced_task_info, (void **)&original_task_info);
    
    void *p_dlopen_preflight = MSFindSymbol(MSGetImageByName("/usr/lib/system/libdyld.dylib"), "_dlopen_preflight");
    if (p_dlopen_preflight) {
        MSHookFunction(p_dlopen_preflight, replaced_dlopen_preflight, (void **)&original_dlopen_preflight);
    }
    MSHookFunction(dlerror, replaced_dlerror, (void **)&original_dlerror);
}

void shadowhook_dyld_extra(HKSubstitutor* hooks) {
    MSImageRef libdyldImage = MSGetImageByName("/usr/lib/system/libdyld.dylib");
    void* libdyldHandle = dlopen("/usr/lib/system/libdyld.dylib", RTLD_NOW);
    
    MSHookFunction(dlopen, replaced_dlopen, (void **)&original_dlopen);
    
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_1) {
        void* dlopen_internal_ptr = MSFindSymbol(libdyldImage, "__ZL15dlopen_internalPKciPv");
        if (dlopen_internal_ptr) {
            MSHookFunction(dlopen_internal_ptr, replaced_dlopen_internal, (void **)&original_dlopen_internal);
        }
    } else {
        void* dlopen_from_ptr = dlsym(libdyldHandle, "dlopen_from");
        if (dlopen_from_ptr) {
            MSHookFunction(dlopen_from_ptr, replaced_dlopen_internal, (void **)&original_dlopen_internal);
        }
    }
}

void shadowhook_dyld_symlookup(HKSubstitutor* hooks) {
    MSHookFunction(dlsym, replaced_dlsym, (void **)&original_dlsym);
}

void shadowhook_dyld_symaddrlookup(HKSubstitutor* hooks) {
    // Empty stub.
    // If you wanted to hook dladdr using MobileSubstrate instead of Fishhook,
    // you could implement that here. For now, do nothing.
}

/*
// Alternatively, if you prefer a MobileSubstrate hook for dladdr:
void shadowhook_dyld_symaddrlookup(HKSubstitutor* hooks) {
    MSHookFunction(dladdr, replaced_dladdr, (void **)&orig_dladdr);
}
*/
