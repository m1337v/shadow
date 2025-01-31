#import "hooks.h"
#include <dlfcn.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

// Function pointers for original syscalls
static int (*orig_access)(const char *, int);
static int (*orig_stat)(const char *, struct stat *);
static int (*orig_lstat)(const char *, struct stat *);
static int (*orig_open)(const char *, int, mode_t);

// List of paths to hide
static const char *jailbreak_paths[] = {
    "/var/jb",
    "/bin/bash",
    "/Library/MobileSubstrate",
    "/usr/sbin/sshd",
    "/etc/apt",
    "/var/lib/cydia",
    "/var/mobile/Library/Preferences/com.saurik.Cydia.plist",
    NULL // End marker
};

// Hooked access() function
int hooked_access(const char *path, int mode) {
    for (int i = 0; jailbreak_paths[i] != NULL; i++) {
        if (strstr(path, jailbreak_paths[i])) {
            errno = ENOENT;
            return -1;
        }
    }
    return orig_access(path, mode);
}

// Hooked stat() function
int hooked_stat(const char *path, struct stat *buf) {
    for (int i = 0; jailbreak_paths[i] != NULL; i++) {
        if (strstr(path, jailbreak_paths[i])) {
            errno = ENOENT;
            return -1;
        }
    }
    return orig_stat(path, buf);
}

// Hooked lstat() function
int hooked_lstat(const char *path, struct stat *buf) {
    for (int i = 0; jailbreak_paths[i] != NULL; i++) {
        errno = ENOENT;
        return -1;
    }
    return orig_lstat(path, buf);
}

// Hooked open() function
int hooked_open(const char *path, int flags, mode_t mode) {
    for (int i = 0; jailbreak_paths[i] != NULL; i++) {
        if (strstr(path, jailbreak_paths[i])) {
            errno = ENOENT;
            return -1;
        }
    }
    return orig_open(path, flags, mode);
}

// Apply fishhook symbol rebindings
void shadowhook_FileSystem(HKSubstitutor* hooks) {
    struct rebinding rebindings[] = {
        {"access", hooked_access, (void **)&orig_access},
        {"stat", hooked_stat, (void **)&orig_stat},
        {"lstat", hooked_lstat, (void **)&orig_lstat},
        {"open", hooked_open, (void **)&orig_open},
    };
    rebind_symbols(rebindings, 4);
}
