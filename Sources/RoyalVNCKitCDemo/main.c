#include <stdio.h>
#include <unistd.h>

#include <RoyalVNCKitC.h>

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
    
    rvnc_connection_t connection = rvnc_connection_create(settings);
    
    rvnc_connection_state_t initialConnectionState = rvnc_connection_state_get_copy(connection);
    RVNC_CONNECTION_STATUS initialConnectionStatus = rvnc_connection_state_status_get(initialConnectionState);
    
    if (initialConnectionStatus != RVNC_CONNECTION_STATUS_DISCONNECTED) {
        printf("Error: Connection status should be disconnected\n");
        exit(1);
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
}
