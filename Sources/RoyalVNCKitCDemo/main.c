#include <stdio.h>
#include <unistd.h>

#include <RoyalVNCKitC.h>

typedef struct Context {
    rvnc_connection_t connection;
//    rvnc_connection_delegate_t connectionDelegate;
} Context;

int main(int argc, char *argv[]) {
    const char* hostname = "localhost";
    
    rvnc_settings_t settings = rvnc_settings_create(true,
                                                    hostname,
                                                    5900,
                                                    true,
                                                    false,
                                                    false,
                                                    RVNC_INPUTMODE_NONE,
                                                    false,
                                                    RVNC_COLORDEPTH_24BIT);
    
    Context* context = malloc(sizeof(Context));
    
    if (!context) {
        printf("Error: Failed to create context\n");
        
        rvnc_settings_destroy(settings);
        
        return EXIT_FAILURE;
    }
    
    rvnc_connection_t connection = rvnc_connection_create(settings, context);
    
    Context* connectionContext = rvnc_connection_context_get(connection);
    
    if (connectionContext != context) {
        printf("Error: Connection context should be equal to the context we just created\n");
        
        rvnc_connection_destroy(connection);
        free(context);
        rvnc_settings_destroy(settings);
        
        return EXIT_FAILURE;
    }
    
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
    
    rvnc_connection_connect(connection);
    
    // Start endless loop
    while (true) {
        rvnc_connection_state_t connectionState = rvnc_connection_state_get_copy(connection);
        RVNC_CONNECTION_STATUS connectionStatus = rvnc_connection_state_status_get(connectionState);
        
        switch (connectionStatus) {
            case RVNC_CONNECTION_STATUS_DISCONNECTED:
                printf("Status: Disconnected\n");
                break;
            case RVNC_CONNECTION_STATUS_CONNECTING:
                printf("Status: Connecting\n");
                break;
            case RVNC_CONNECTION_STATUS_CONNECTED:
                printf("Status: Connected\n");
                break;
            case RVNC_CONNECTION_STATUS_DISCONNECTING:
                printf("Status: Disconnecting\n");
                break;
        }
        
        rvnc_connection_state_destroy(connectionState);
        
        usleep(1 * 1000000.0);
    }
    
    rvnc_connection_destroy(connection);
    rvnc_settings_destroy(settings);
    
    return EXIT_SUCCESS;
}
