#include "AuthHelper.h"
#include <Security/Security.h>
#include <sys/wait.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

OSStatus AuthHelperExecute(AuthorizationRef auth, const char *tool, const char **args) {
    OSStatus status = AuthorizationExecuteWithPrivileges(
        auth,
        tool,
        kAuthorizationFlagDefaults,
        (char *const *)args,
        NULL
    );

    if (status == errAuthorizationSuccess) {
        int childStatus;
        wait(&childStatus);
    }

    return status;
}

#pragma clang diagnostic pop
