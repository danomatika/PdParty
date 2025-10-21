/*
 Copyright (c) 2012-2019, Pierre-Olivier Latour
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "GCDWebServerDataResponse.h"
#import "GCDWebServerHTTPStatusCodes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The ReadiumGCDWebServerDataResponse subclass of ReadiumGCDWebServerDataResponse generates
 *  an HTML body from an HTTP status code and an error message.
 */
@interface ReadiumGCDWebServerErrorResponse : ReadiumGCDWebServerDataResponse

/**
 *  Creates a client error response with the corresponding HTTP status code.
 */
+ (instancetype)responseWithClientError:(ReadiumGCDWebServerClientErrorHTTPStatusCode)errorCode message:(NSString*)format, ... NS_FORMAT_FUNCTION(2, 3);

/**
 *  Creates a server error response with the corresponding HTTP status code.
 */
+ (instancetype)responseWithServerError:(ReadiumGCDWebServerServerErrorHTTPStatusCode)errorCode message:(NSString*)format, ... NS_FORMAT_FUNCTION(2, 3);

/**
 *  Creates a client error response with the corresponding HTTP status code
 *  and an underlying NSError.
 */
+ (instancetype)responseWithClientError:(ReadiumGCDWebServerClientErrorHTTPStatusCode)errorCode underlyingError:(nullable NSError*)underlyingError message:(NSString*)format, ... NS_FORMAT_FUNCTION(3, 4);

/**
 *  Creates a server error response with the corresponding HTTP status code
 *  and an underlying NSError.
 */
+ (instancetype)responseWithServerError:(ReadiumGCDWebServerServerErrorHTTPStatusCode)errorCode underlyingError:(nullable NSError*)underlyingError message:(NSString*)format, ... NS_FORMAT_FUNCTION(3, 4);

/**
 *  Initializes an empty response with a specific HTTP status code and error.
 */
- (instancetype)initWithStatusCode:(NSInteger)statusCode error:(NSError*)error;

/**
 *  Initializes a client error response with the corresponding HTTP status code.
 */
- (instancetype)initWithClientError:(ReadiumGCDWebServerClientErrorHTTPStatusCode)errorCode message:(NSString*)format, ... NS_FORMAT_FUNCTION(2, 3);

/**
 *  Initializes a server error response with the corresponding HTTP status code.
 */
- (instancetype)initWithServerError:(ReadiumGCDWebServerServerErrorHTTPStatusCode)errorCode message:(NSString*)format, ... NS_FORMAT_FUNCTION(2, 3);

/**
 *  Initializes a client error response with the corresponding HTTP status code
 *  and an underlying NSError.
 */
- (instancetype)initWithClientError:(ReadiumGCDWebServerClientErrorHTTPStatusCode)errorCode underlyingError:(nullable NSError*)underlyingError message:(NSString*)format, ... NS_FORMAT_FUNCTION(3, 4);

/**
 *  Initializes a server error response with the corresponding HTTP status code
 *  and an underlying NSError.
 */
- (instancetype)initWithServerError:(ReadiumGCDWebServerServerErrorHTTPStatusCode)errorCode underlyingError:(nullable NSError*)underlyingError message:(NSString*)format, ... NS_FORMAT_FUNCTION(3, 4);

@end

NS_ASSUME_NONNULL_END
