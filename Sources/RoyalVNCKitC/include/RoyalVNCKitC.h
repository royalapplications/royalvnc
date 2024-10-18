#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

// TODO: Cursor, Logger

#pragma mark - Enums

typedef enum : int {
    RVNC_CONNECTION_STATUS_DISCONNECTED = 0,
    RVNC_CONNECTION_STATUS_CONNECTING = 1,
    RVNC_CONNECTION_STATUS_CONNECTED = 2,
    RVNC_CONNECTION_STATUS_DISCONNECTING = 3
} RVNC_CONNECTION_STATUS;

typedef enum : uint32_t {
    RVNC_INPUTMODE_NONE = 0,
    RVNC_INPUTMODE_FORWARDKEYBOARDSHORTCUTSIFNOTINUSELOCALLY = 1,
    RVNC_INPUTMODE_FORWARDKEYBOARDSHORTCUTSEVENIFINUSELOCALLY = 2,
    RVNC_INPUTMODE_FORWARDALLKEYBOARDSHORTCUTSANDHOTKEYS = 3
} RVNC_INPUTMODE;

typedef enum : uint8_t {
    RVNC_COLORDEPTH_8BIT = 8, // 256 Colors
    RVNC_COLORDEPTH_16BIT = 16,
    RVNC_COLORDEPTH_24BIT = 24
} RVNC_COLORDEPTH;

typedef enum : int {
    RVNC_AUTHENTICATIONTYPE_VNC = 0,
    RVNC_AUTHENTICATIONTYPE_APPLEREMOTEDESKTOP = 1,
    RVNC_AUTHENTICATIONTYPE_ULTRAVNCMSLOGONII = 2
} RVNC_AUTHENTICATIONTYPE;


#pragma mark - Types

typedef void* rvnc_context_t;
typedef void* rvnc_authentication_request_t;
typedef void* rvnc_settings_t;
typedef void* rvnc_connection_state_t;
typedef void* rvnc_framebuffer_t;
typedef void* rvnc_connection_t;
typedef void* rvnc_connection_delegate_t;


#pragma mark - Authentication Type

extern bool rvnc_authentication_type_requires_username(RVNC_AUTHENTICATIONTYPE authenticationType);
extern bool rvnc_authentication_type_requires_password(RVNC_AUTHENTICATIONTYPE authenticationType);


#pragma mark - Authentication Request

extern RVNC_AUTHENTICATIONTYPE rvnc_authentication_request_authentication_type_get(rvnc_authentication_request_t _Nonnull authenticationRequest);

extern void rvnc_authentication_request_cancel(rvnc_authentication_request_t _Nonnull authenticationRequest);

extern void rvnc_authentication_request_complete_with_username_password(rvnc_authentication_request_t _Nonnull authenticationRequest,
                                                                        const char* _Nonnull username,
                                                                        const char* _Nonnull password);

extern void rvnc_authentication_request_complete_with_password(rvnc_authentication_request_t _Nonnull authenticationRequest,
                                                               const char* _Nonnull password);


#pragma mark - Settings

extern rvnc_settings_t _Nonnull rvnc_settings_create(bool isDebugLoggingEnabled,
                                                     const char* _Nonnull hostname,
                                                     uint16_t port,
                                                     bool isShared,
                                                     bool isScalingEnabled,
                                                     bool useDisplayLink,
                                                     RVNC_INPUTMODE inputMode,
                                                     bool isClipboardRedirectionEnabled,
                                                     RVNC_COLORDEPTH colorDepth);

extern void rvnc_settings_destroy(rvnc_settings_t _Nonnull settings);


#pragma mark - Connection State

extern void rvnc_connection_state_destroy(rvnc_connection_state_t _Nonnull connectionState);

extern RVNC_CONNECTION_STATUS rvnc_connection_state_status_get(rvnc_connection_state_t _Nonnull connectionState);
extern char* _Nullable rvnc_connection_state_error_description_get_copy(rvnc_connection_state_t _Nonnull connectionState);


#pragma mark - Framebuffer

extern uint16_t rvnc_framebuffer_size_width_get(rvnc_framebuffer_t _Nonnull framebuffer);
extern uint16_t rvnc_framebuffer_size_height_get(rvnc_framebuffer_t _Nonnull framebuffer);
extern void* _Nonnull rvnc_framebuffer_pixel_data_get(rvnc_framebuffer_t _Nonnull framebuffer);


#pragma mark - Connection Delegate

typedef void (*rvnc_connection_delegate_connection_state_did_change)(rvnc_connection_t _Nonnull /* connection */,
                                                                     const rvnc_context_t _Nullable /* context */,
                                                                     _Nonnull rvnc_connection_state_t /* connectionState */);

typedef void (*rvnc_connection_delegate_authenticate)(rvnc_connection_t _Nonnull /* connection */,
                                                      const rvnc_context_t _Nullable /* context */,
                                                      _Nonnull rvnc_authentication_request_t /* authenticationRequest */);

typedef void (*rvnc_connection_delegate_did_create_framebuffer)(rvnc_connection_t _Nonnull /* connection */,
                                                                const rvnc_context_t _Nullable /* context */,
                                                                _Nonnull rvnc_framebuffer_t /* framebuffer */);

typedef void (*rvnc_connection_delegate_did_resize_framebuffer)(rvnc_connection_t _Nonnull /* connection */,
                                                                const rvnc_context_t _Nullable /* context */,
                                                                _Nonnull rvnc_framebuffer_t /* framebuffer */);

typedef void (*rvnc_connection_delegate_framebuffer_did_update_region)(rvnc_connection_t _Nonnull /* connection */,
                                                                       const rvnc_context_t _Nullable /* context */,
                                                                       _Nonnull rvnc_framebuffer_t /* framebuffer */,
                                                                       uint16_t /* x */,
                                                                       uint16_t /* y */,
                                                                       uint16_t /* width */,
                                                                       uint16_t /* height */);

// TODO: Cursor type missing
typedef void (*rvnc_connection_delegate_did_update_cursor)(rvnc_connection_t _Nonnull /* connection */,
                                                           const rvnc_context_t _Nullable /* context */);

extern rvnc_connection_delegate_t _Nonnull rvnc_connection_delegate_create(rvnc_connection_delegate_connection_state_did_change _Nonnull connectionStateDidChange,
                                                                           rvnc_connection_delegate_authenticate _Nonnull authenticate,
                                                                           rvnc_connection_delegate_did_create_framebuffer _Nonnull didCreateFramebuffer,
                                                                           rvnc_connection_delegate_did_resize_framebuffer _Nonnull didResizeFramebuffer,
                                                                           rvnc_connection_delegate_framebuffer_did_update_region _Nonnull framebufferDidUpdateRegion,
                                                                           rvnc_connection_delegate_did_update_cursor _Nonnull didUpdateCursor);

extern void rvnc_connection_delegate_destroy(rvnc_connection_delegate_t _Nonnull connectionDelegate);


#pragma mark - Connection

extern rvnc_connection_t _Nonnull rvnc_connection_create(rvnc_settings_t _Nonnull settings, rvnc_context_t _Nullable context);
extern void rvnc_connection_destroy(rvnc_connection_t _Nonnull connection);

extern void rvnc_connection_connect(rvnc_connection_t _Nonnull connection);
extern void rvnc_connection_disconnect(rvnc_connection_t _Nonnull connection);

extern void rvnc_connection_update_color_depth(rvnc_connection_t _Nonnull connection, RVNC_COLORDEPTH colorDepth);
extern void rvnc_connection_delegate_set(rvnc_connection_t _Nonnull connection, rvnc_connection_delegate_t _Nullable connectionDelegate);

extern rvnc_context_t _Nullable rvnc_connection_context_get(rvnc_connection_t _Nonnull connection);
extern rvnc_connection_state_t _Nonnull rvnc_connection_state_get_copy(rvnc_connection_t _Nonnull connection);
extern rvnc_settings_t _Nonnull rvnc_connection_settings_get_copy(rvnc_connection_t _Nonnull connection);
extern rvnc_framebuffer_t _Nullable rvnc_connection_framebuffer_get(rvnc_connection_t _Nonnull connection);

extern void rvnc_connection_mouse_move(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_mouse_down(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_right_mouse_down(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_middle_mouse_down(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_mouse_up(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_mouse_wheel_up(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_mouse_wheel_down(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_mouse_wheel_left(rvnc_connection_t _Nonnull connection, double x, double y);
extern void rvnc_connection_mouse_wheel_right(rvnc_connection_t _Nonnull connection, double x, double y);

extern void rvnc_connection_key_down(rvnc_connection_t _Nonnull connection, uint32_t key);
extern void rvnc_connection_key_up(rvnc_connection_t _Nonnull connection, uint32_t key);
