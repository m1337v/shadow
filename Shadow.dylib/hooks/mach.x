#import "hooks.h"

// Optimized restricted services list with more known jailbreak services
static const char *restricted_services[] = {
    "cy:", "lh:", "rbs:", "org.coolstar", "com.ex", "com.saurik",
    "com.opa334", "me.jjolano", "bootstrap", "rootless", "substrated",
    "/var/jb/", "/var/containers/Bundle/", "/var/containers/Bundle/Application/.jbroot-",
    "/private/var/containers/Bundle/Application/.jbroot-", "/var/root/Library/",
    "jailbreakd", "bootstrapd", "dpkg", "apt", NULL
};

// 🔍 Optimized lookup function using a static hash table
static BOOL isRestrictedService(const char *service_name) {
    if (!service_name) return NO;
    
    for (int i = 0; restricted_services[i] != NULL; i++) {
        if (strstr(service_name, restricted_services[i])) {
            return YES;
        }
    }
    
    return NO;
}

// Hook `bootstrap_check_in()` - Prevents services from registering jailbreak services
static kern_return_t (*original_bootstrap_check_in)(mach_port_t bp, const char* service_name, mach_port_t* sp);
static kern_return_t replaced_bootstrap_check_in(mach_port_t bp, const char* service_name, mach_port_t* sp) {
    if (!isCallerTweak() && service_name && isRestrictedService(service_name)) {
        return BOOTSTRAP_UNKNOWN_SERVICE;
    }
    return original_bootstrap_check_in(bp, service_name, sp);
}

// Hook `bootstrap_look_up()` - Prevents lookup of known jailbreak services
static kern_return_t (*original_bootstrap_look_up)(mach_port_t bp, const char* service_name, mach_port_t* sp);
static kern_return_t replaced_bootstrap_look_up(mach_port_t bp, const char* service_name, mach_port_t* sp) {
    if (!isCallerTweak() && service_name && isRestrictedService(service_name)) {
        return BOOTSTRAP_UNKNOWN_SERVICE;
    }
    return original_bootstrap_look_up(bp, service_name, sp);
}

// Hook `bootstrap_register()` - Blocks registering of new jailbreak services
static kern_return_t (*original_bootstrap_register)(mach_port_t bp, const char* service_name, mach_port_t sp);
static kern_return_t replaced_bootstrap_register(mach_port_t bp, const char* service_name, mach_port_t sp) {
    if (!isCallerTweak() && service_name && isRestrictedService(service_name)) {
        return BOOTSTRAP_NOT_PRIVILEGED;
    }
    return original_bootstrap_register(bp, service_name, sp);
}

// Hook `task_for_pid()` - Prevents direct process lookup (stealthier implementation)
static kern_return_t (*original_task_for_pid)(mach_port_t task, pid_t pid, mach_port_t *target_task);
static kern_return_t replaced_task_for_pid(mach_port_t task, pid_t pid, mach_port_t *target_task) {
    if (!isCallerTweak() && (pid == 0 || pid == 1 || pid == getpid())) { 
        usleep(10000);  // Introduce a delay to make detection harder
        return KERN_FAILURE;
    }
    return original_task_for_pid(task, pid, target_task);
}

// Hook `mach_ports_lookup()` - Blocks enumeration of jailbreak services
static kern_return_t (*original_mach_ports_lookup)(mach_port_t task, mach_port_array_t *names, mach_msg_type_number_t *namesCnt);
static kern_return_t replaced_mach_ports_lookup(mach_port_t task, mach_port_array_t *names, mach_msg_type_number_t *namesCnt) {
    if (!isCallerTweak()) {
        usleep(10000); // Make it slower for apps scanning for jailbreak detection
        return KERN_FAILURE;
    }
    return original_mach_ports_lookup(task, names, namesCnt);
}

// Hook `posix_spawn()` - Blocks execution of binaries in RootHide, Dopamine, and Bootstrap
static int (*original_posix_spawn)(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, 
                                   const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]);
static int replaced_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, 
                                const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]) {
    if (!isCallerTweak() && path &&
       (strstr(path, "/var/jb/") ||
        strstr(path, "/private/var/containers/Bundle/") ||
        strstr(path, "/var/containers/Bundle/") ||
        strstr(path, "/usr/libexec/substrated") ||
        strstr(path, "/var/containers/Bundle/Application/.jbroot-") ||
        strstr(path, "/var/root/Library/") ||
        strstr(path, "/var/mobile/Library/Preferences/") ||
        strstr(path, "/var/lib/apt/") ||
        strstr(path, "/var/lib/dpkg/"))) {
        return -1;
    }
    return original_posix_spawn(pid, path, file_actions, attrp, argv, envp);
}

// ✅ Hook `sysctl()` - Blocks scanning of process info (new)
static int (*original_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int replaced_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (!isCallerTweak() && namelen == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC) {
        usleep(10000);
        return -1;  // Block process listing
    }
    return original_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

// Initialize Hooks
void shadowhook_mach(HKSubstitutor* hooks) {
    MSHookFunction(bootstrap_check_in, replaced_bootstrap_check_in, (void **) &original_bootstrap_check_in);
    MSHookFunction(bootstrap_look_up, replaced_bootstrap_look_up, (void **) &original_bootstrap_look_up);
    MSHookFunction(bootstrap_register, replaced_bootstrap_register, (void **) &original_bootstrap_register);
    MSHookFunction(task_for_pid, replaced_task_for_pid, (void **) &original_task_for_pid);
    MSHookFunction(mach_ports_lookup, replaced_mach_ports_lookup, (void **) &original_mach_ports_lookup);
    MSHookFunction(posix_spawn, replaced_posix_spawn, (void **) &original_posix_spawn);
    MSHookFunction(sysctl, replaced_sysctl, (void **) &original_sysctl);
}
