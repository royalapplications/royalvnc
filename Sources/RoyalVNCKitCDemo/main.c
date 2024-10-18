#include <stdio.h>
#include <unistd.h>

#include <RoyalVNCKitC.h>

#pragma mark - Context

typedef struct Context {
    rvnc_connection_t connection;
//    rvnc_connection_delegate_t connectionDelegate;
} Context;


#pragma mark - Helpers
char* getLine(void) {
    char* str = malloc(sizeof(char) * 1024);
    scanf(" %[^\n]s", str);
    
    return str;
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


#pragma mark - Connection Delegate Implementation
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
        printf("Username: ");
        char* username = getLine();
        
        printf("Password: ");
        char* password = getLine();
        
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
        printf("Password: ");
        char* password = getLine();
        
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
    printf("delegate_didCreateFramebuffer - Framebuffer Size: %ix%i; Pixel Data Size %llu; Pixel Data Pointer: %p\n",
           rvnc_framebuffer_size_width_get(framebuffer),
           rvnc_framebuffer_size_height_get(framebuffer),
           rvnc_framebuffer_pixel_data_size_get(framebuffer),
           rvnc_framebuffer_pixel_data_get(framebuffer));
}

void delegate_didResizeFramebuffer(rvnc_connection_t connection,
                                   const rvnc_context_t context,
                                   rvnc_framebuffer_t framebuffer) {
    printf("delegate_didResizeFramebuffer - Framebuffer Size: %ix%i\n",
           rvnc_framebuffer_size_width_get(framebuffer),
           rvnc_framebuffer_size_height_get(framebuffer));
}

void delegate_framebufferDidUpdateRegion(rvnc_connection_t connection,
                                         const rvnc_context_t context,
                                         rvnc_framebuffer_t framebuffer,
                                         uint16_t x,
                                         uint16_t y,
                                         uint16_t width,
                                         uint16_t height) {
    printf("delegate_framebufferDidUpdateRegion - x: %i; y: %i; width: %i; height: %i\n",
           x, y, width, height);
}

// TODO: Missing cursor type
void delegate_didUpdateCursor(rvnc_connection_t connection,
                              const rvnc_context_t context) {
    printf("delegate_didUpdateCursor\n");
}


#pragma mark - Main

int main(int argc, char *argv[]) {
    const char* hostname = "localhost";
    const uint16_t port = 5900;
    
    const bool enableDebugLogging = true;
    
    // Create settings
    rvnc_settings_t settings = rvnc_settings_create(enableDebugLogging,
                                                    hostname,
                                                    port,
                                                    true,
                                                    false,
                                                    false,
                                                    RVNC_INPUTMODE_NONE,
                                                    false,
                                                    RVNC_COLORDEPTH_24BIT);
    
    // Create context
    Context* context = malloc(sizeof(Context));
    
    if (!context) {
        printf("Error: Failed to create context\n");
        
        rvnc_settings_destroy(settings);
        
        return EXIT_FAILURE;
    }
    
    // Create connection
    rvnc_connection_t connection = rvnc_connection_create(settings, context);
    
    // Verify context is properly set in connection
    Context* connectionContext = rvnc_connection_context_get(connection);
    
    if (connectionContext != context) {
        printf("Error: Connection context should be equal to the context we just created\n");
        
        rvnc_connection_destroy(connection);
        free(context);
        rvnc_settings_destroy(settings);
        
        return EXIT_FAILURE;
    }
    
    // Verify initial connection status is disconnected
    rvnc_connection_state_t initialConnectionState = rvnc_connection_state_get_copy(connection);
    RVNC_CONNECTION_STATUS initialConnectionStatus = rvnc_connection_state_status_get(initialConnectionState);
    
    if (initialConnectionStatus != RVNC_CONNECTION_STATUS_DISCONNECTED) {
        printf("Error: Connection status should be disconnected\n");
        
        rvnc_connection_state_destroy(initialConnectionState);
        rvnc_connection_destroy(connection);
        rvnc_settings_destroy(settings);
        
        return EXIT_FAILURE;
    }
    
    rvnc_connection_state_destroy(initialConnectionState);
    
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
    free(context);
    
    return EXIT_SUCCESS;
}
