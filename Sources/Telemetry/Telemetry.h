/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

//! Project version number for Telemetry.
FOUNDATION_EXPORT double TelemetryVersionNumber;

//! Project version string for Telemetry.
FOUNDATION_EXPORT const unsigned char TelemetryVersionString[];

NS_INLINE NSException * _Nullable withObjCExceptionHandling(void(NS_NOESCAPE^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

