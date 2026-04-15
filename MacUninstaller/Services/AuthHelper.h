#ifndef AuthHelper_h
#define AuthHelper_h

#include <Security/Security.h>

/// Wrapper for AuthorizationExecuteWithPrivileges since it's unavailable in Swift
OSStatus AuthHelperExecute(AuthorizationRef auth, const char *tool, const char **args);

#endif
