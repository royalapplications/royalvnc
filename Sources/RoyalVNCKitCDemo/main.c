#include <stdio.h>
#include <string.h>

#ifndef _WIN32
#include <unistd.h>
#else // _WIN32
// resolve:
// Sources\RoyalVNCKitCDemo\main.c:301:9: error: call to undeclared function 'usleep'; ISO C99 and later do not support implicit function declarations
// Sources\RoyalVNCKitCDemo\main.c:301:9: note: did you mean '_sleep'?
// note: convert from microseconds to milliseconds and call the builtin `_sleep` function
#define usleep(us) _sleep((us)/1000)
#endif // _WIN32

#include <RoyalVNCKitC.h>

#pragma mark - Context

typedef struct Context {
    rvnc_connection_t connection;
} Context;


#pragma mark - Helpers

char* readLine(void) {
    int maxLength = sizeof(char) * 4096;
    char* str = malloc(maxLength);
    
    if (fgets(str, maxLength, stdin)) {
        size_t len = strlen(str);
        
        if (len > 0 &&
            str[len - 1] == '\n') {
            str[--len] = '\0';
        }
    }
    
    return str;
}

char* readPassword(const char* prompt) {
#ifndef _WIN32
    char* password = getpass(prompt);
    
    if (!password) {
        return NULL;
    }
    
    size_t len = strlen(password);
    char* result = malloc(len + 1);
    
    if (!result) {
        return NULL;
    }
    
    strcpy(result, password);

    return result;
#else
    // TODO: Implement password input for Windows
    printf("%s", prompt);
    
    return readLine();
#endif
}

char* connectionStatusToString(RVNC_CONNECTION_STATUS connectionStatus) {
    switch (connectionStatus) {
        case RVNC_CONNECTION_STATUS_DISCONNECTED:
            return "Disconnected";
        case RVNC_CONNECTION_STATUS_CONNECTING:
            return "Connecting";
        case RVNC_CONNECTION_STATUS_CONNECTED:
            return "Connected";
        case RVNC_CONNECTION_STATUS_DISCONNECTING:
            return "Disconnecting";
    }
}

char* authenticationTypeToString(RVNC_AUTHENTICATIONTYPE authenticationType) {
    switch (authenticationType) {
        case RVNC_AUTHENTICATIONTYPE_VNC:
            return "VNC";
        case RVNC_AUTHENTICATIONTYPE_APPLEREMOTEDESKTOP:
            return "Apple Remote Desktop";
        case RVNC_AUTHENTICATIONTYPE_ULTRAVNCMSLOGONII:
            return "Ultra VNC MS Logon II";
    }
}

char* logLevelToString(RVNC_LOG_LEVEL logLevel) {
    switch (logLevel) {
        case RVNC_LOG_LEVEL_DEBUG:
            return "Debug";
        case RVNC_LOG_LEVEL_INFO:
            return "Info";
        case RVNC_LOG_LEVEL_WARNING:
            return "Warning";
        case RVNC_LOG_LEVEL_ERROR:
            return "Error";
    }
}


#pragma mark - Logger Delegate implementation

void loggerDelegate_log(rvnc_logger_t logger,
                        const rvnc_context_t context,
                        RVNC_LOG_LEVEL logLevel,
                        const char* message) {
    char* logLevelStr = logLevelToString(logLevel);
    
    printf("[%s] %s\n",
           logLevelStr,
           message);
}


#pragma mark - Connection Delegate implementation

void delegate_connectionStateDidChange(rvnc_connection_t connection,
                                       const rvnc_context_t context,
                                       rvnc_connection_state_t connectionState) {
    RVNC_CONNECTION_STATUS status = rvnc_connection_state_status_get(connectionState);
    const char* statusStr = connectionStatusToString(status);
    
    char* errorDescription = rvnc_connection_state_error_description_get_copy(connectionState);
    char* errorDescriptionForLog;
    
    if (errorDescription) {
        errorDescriptionForLog = errorDescription;
    } else {
        errorDescriptionForLog = "N/A";
    }
    
    bool shouldDisplayErrorToUser = rvnc_connection_state_error_should_display_to_user_get(connectionState);
    bool isAuthenticationError = rvnc_connection_state_error_is_authentication_error_get(connectionState);
    
    if (shouldDisplayErrorToUser) {
        printf("delegate_connectionStateDidChange - Status: %s; Error Description: %s; Is Authentication Error: %s\n",
               statusStr,
               errorDescriptionForLog,
               isAuthenticationError ? "Yes" : "No");
    } else {
        printf("delegate_connectionStateDidChange - Status: %s\n",
               statusStr);
    }
    
    if (errorDescription) {
        free(errorDescription);
    }
}

void delegate_authenticate(rvnc_connection_t connection,
                           const rvnc_context_t context,
                           rvnc_authentication_request_t authenticationRequest) {
    RVNC_AUTHENTICATIONTYPE authenticationType = rvnc_authentication_request_authentication_type_get(authenticationRequest);
    char* authenticationTypeStr = authenticationTypeToString(authenticationType);
    
    printf("delegate_authenticate - Authentication type: %s\n",
           authenticationTypeStr);
    
    bool requiresUsername = rvnc_authentication_type_requires_username(authenticationType);
    bool requiresPassword = rvnc_authentication_type_requires_password(authenticationType);
    
    if (requiresUsername) {
        printf("Enter username: ");
        char* username = readLine();
        char* password = readPassword("Enter password: ");

        if (username &&
            password) {
            rvnc_authentication_request_complete_with_username_password(authenticationRequest,
                                                                        username,
                                                                        password);
        } else {
            rvnc_authentication_request_cancel(authenticationRequest);
        }
        
        if (username) {
            free(username);
        }
        
        if (password) {
            free(password);
        }
    } else if (requiresPassword) {
        char* password = readPassword("Enter password: ");
        
        if (password) {
            rvnc_authentication_request_complete_with_password(authenticationRequest,
                                                               password);
            
            free(password);
        } else {
            rvnc_authentication_request_cancel(authenticationRequest);
        }
    } else { // Should never happen because authenticate is only called if a credential is actually required. So either requiresUsername or requiresPassword or both must be true.
        rvnc_authentication_request_cancel(authenticationRequest);
    }
}

void delegate_didCreateFramebuffer(rvnc_connection_t connection,
                                   const rvnc_context_t context,
                                   rvnc_framebuffer_t framebuffer) {
    printf("delegate_didCreateFramebuffer - Framebuffer Size: %ix%i; Pixel Data Size %lu; Pixel Data Pointer: %p\n",
           rvnc_framebuffer_size_width_get(framebuffer),
           rvnc_framebuffer_size_height_get(framebuffer),
           rvnc_framebuffer_pixel_data_size_get(framebuffer),
           rvnc_framebuffer_pixel_data_get(framebuffer));
}

void delegate_didResizeFramebuffer(rvnc_connection_t connection,
                                   const rvnc_context_t context,
                                   rvnc_framebuffer_t framebuffer) {
    printf("delegate_didResizeFramebuffer - Framebuffer Size: %ix%i; Pixel Data Size %lu; Pixel Data Pointer: %p\n",
           rvnc_framebuffer_size_width_get(framebuffer),
           rvnc_framebuffer_size_height_get(framebuffer),
           rvnc_framebuffer_pixel_data_size_get(framebuffer),
           rvnc_framebuffer_pixel_data_get(framebuffer));
}

void delegate_framebufferDidUpdateRegion(rvnc_connection_t connection,
                                         const rvnc_context_t context,
                                         rvnc_framebuffer_t framebuffer,
                                         uint16_t x,
                                         uint16_t y,
                                         uint16_t width,
                                         uint16_t height) {
    printf("delegate_framebufferDidUpdateRegion - x: %i; y: %i; width: %i; height: %i\n",
           x,
           y,
           width,
           height);
}

void delegate_didUpdateCursor(rvnc_connection_t connection,
                              const rvnc_context_t context,
                              rvnc_cursor_t cursor) {
    bool isEmpty = rvnc_cursor_is_empty_get(cursor);
    uint16_t width = rvnc_cursor_size_width_get(cursor);
    uint16_t height = rvnc_cursor_size_height_get(cursor);
    uint16_t hotspotX = rvnc_cursor_hotspot_x_get(cursor);
    uint16_t hotspotY = rvnc_cursor_hotspot_y_get(cursor);
    int64_t bitsPerComponent = rvnc_cursor_bits_per_component_get(cursor);
    int64_t bitsPerPixel = rvnc_cursor_bits_per_pixel_get(cursor);
    int64_t bytesPerPixel = rvnc_cursor_bytes_per_pixel_get(cursor);
    int64_t bytesPerRow = rvnc_cursor_bytes_per_row_get(cursor);
    void* pixelData = rvnc_cursor_pixel_data_get_copy(cursor);
    uint64_t pixelDataSize = rvnc_cursor_pixel_data_size_get(cursor);
    
    printf("delegate_didUpdateCursor - isEmpty: %s; width: %i; height: %i; hotspotX: %i; hotspotY: %i; bitsPerComponent: %li; bitsPerPixel: %li; bytesPerPixel: %li; bytesPerRow: %li; pixelData: %p; pixelDataSize: %lu\n",
           isEmpty ? "Yes" : "No",
           width,
           height,
           hotspotX,
           hotspotY,
           bitsPerComponent,
           bitsPerPixel,
           bytesPerPixel,
           bytesPerRow,
           pixelData,
           pixelDataSize);
    
    if (pixelData) {
        rvnc_cursor_pixel_data_destroy(pixelData);
    }
}


#pragma mark - Main

int main(int argc, char *argv[]) {
    // Get hostname either from args or stdin
    const char* hostname;
    
    if (argc >= 2) {
        hostname = argv[1];
    } else {
        printf("Enter hostname: ");
        
        hostname = readLine();
    }
    
    if (strlen(hostname) <= 0) {
        printf("No hostname given\n");
        
        exit(1);
    }
    
    // Declare settings
    const uint16_t port = 5900;
    const bool isShared = true;
    const bool isScalingEnabled = false;
    const bool useDisplayLink = false;
    const RVNC_INPUTMODE inputMode = RVNC_INPUTMODE_NONE;
    const bool isClipboardRedirectionEnabled = false;
    const RVNC_COLORDEPTH colorDepth = RVNC_COLORDEPTH_24BIT;
    const bool enableDebugLogging = true;
    
    // Create context
    Context* context = malloc(sizeof(Context));
    
    // Create logger
    rvnc_logger_t logger = rvnc_logger_create(loggerDelegate_log,
                                              context);
    
    // Create settings
    rvnc_settings_t settings = rvnc_settings_create(enableDebugLogging,
                                                    hostname,
                                                    port,
                                                    isShared,
                                                    isScalingEnabled,
                                                    useDisplayLink,
                                                    inputMode,
                                                    isClipboardRedirectionEnabled,
                                                    colorDepth);
    
    // Create connection
    rvnc_connection_t connection = rvnc_connection_create(settings,
                                                          logger,
                                                          context);
    
    // Create connection delegate
    rvnc_connection_delegate_t connectionDelegate = rvnc_connection_delegate_create(delegate_connectionStateDidChange,
                                                                                    delegate_authenticate,
                                                                                    delegate_didCreateFramebuffer,
                                                                                    delegate_didResizeFramebuffer,
                                                                                    delegate_framebufferDidUpdateRegion,
                                                                                    delegate_didUpdateCursor);
    
    // Set connection delegate in connection
    rvnc_connection_delegate_set(connection, connectionDelegate);
    
    // Connect
    rvnc_connection_connect(connection);
    
    // Run loop until connection is disconnected
    while (true) {
        rvnc_connection_state_t connectionState = rvnc_connection_state_get_copy(connection);
        RVNC_CONNECTION_STATUS connectionStatus = rvnc_connection_state_status_get(connectionState);
        
        rvnc_connection_state_destroy(connectionState);
        
        if (connectionStatus == RVNC_CONNECTION_STATUS_DISCONNECTED) {
            break;
        }
        
        usleep(0.5 * 1000000.0);
    }
    
    // Clean up
    rvnc_connection_destroy(connection);
    rvnc_connection_delegate_destroy(connectionDelegate);
    rvnc_settings_destroy(settings);
    rvnc_logger_destroy(logger);
    free(context);
    
    return EXIT_SUCCESS;
}
