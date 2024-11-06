#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

// NOTE: Memory management roughly follows Apple's CoreFoundation Ownership Policy: https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFMemoryMgmt/Concepts/Ownership.html#//apple_ref/doc/uid/20001148-CJBEJBHH
// If you create an object (by calling a method suffixed with either `_create` or `_copy`), you own it and must relinquish ownership when you have finished using it (by calling a matching method suffixed with `_destroy` or `free` in case of C strings).
// If you get an object from somewhere else, you do not own it. You must not store a reference to such objects since they might be destroyed right after the function call that they're passed into finishes.


#pragma mark - Enums

typedef enum {
    RVNC_LOG_LEVEL_DEBUG = 0,
    RVNC_LOG_LEVEL_INFO = 1,
    RVNC_LOG_LEVEL_WARNING = 2,
    RVNC_LOG_LEVEL_ERROR = 3
} RVNC_LOG_LEVEL;

typedef enum {
    RVNC_CONNECTION_STATUS_DISCONNECTED = 0,
    RVNC_CONNECTION_STATUS_CONNECTING = 1,
    RVNC_CONNECTION_STATUS_CONNECTED = 2,
    RVNC_CONNECTION_STATUS_DISCONNECTING = 3
} RVNC_CONNECTION_STATUS;

typedef enum {
    RVNC_INPUTMODE_NONE = 0,
    RVNC_INPUTMODE_FORWARDKEYBOARDSHORTCUTSIFNOTINUSELOCALLY = 1,
    RVNC_INPUTMODE_FORWARDKEYBOARDSHORTCUTSEVENIFINUSELOCALLY = 2,
    RVNC_INPUTMODE_FORWARDALLKEYBOARDSHORTCUTSANDHOTKEYS = 3
} RVNC_INPUTMODE;

typedef enum {
    RVNC_COLORDEPTH_8BIT = 8, // 256 Colors
    RVNC_COLORDEPTH_16BIT = 16,
    RVNC_COLORDEPTH_24BIT = 24
} RVNC_COLORDEPTH;

typedef enum {
    RVNC_AUTHENTICATIONTYPE_VNC = 0,
    RVNC_AUTHENTICATIONTYPE_APPLEREMOTEDESKTOP = 1,
    RVNC_AUTHENTICATIONTYPE_ULTRAVNCMSLOGONII = 2
} RVNC_AUTHENTICATIONTYPE;

typedef enum {
    RVNC_MOUSEBUTTON_LEFT = 0,
    RVNC_MOUSEBUTTON_MIDDLE = 1,
    RVNC_MOUSEBUTTON_RIGHT = 2
} RVNC_MOUSEBUTTON;

typedef enum {
    RVNC_MOUSEWHEEL_LEFT = 0,
    RVNC_MOUSEWHEEL_RIGHT = 1,
    RVNC_MOUSEWHEEL_UP = 2,
    RVNC_MOUSEWHEEL_DOWN = 3
} RVNC_MOUSEWHEEL;


#pragma mark - Types

typedef void* rvnc_context_t;
typedef void* rvnc_logger_t;
typedef void* rvnc_logger_delegate_t;
typedef void* rvnc_authentication_request_t;
typedef void* rvnc_settings_t;
typedef void* rvnc_connection_state_t;
typedef void* rvnc_framebuffer_t;
typedef void* rvnc_connection_t;
typedef void* rvnc_connection_delegate_t;
typedef void* rvnc_cursor_t;


#pragma mark - Logger

typedef void (*rvnc_logger_delegate_log)(rvnc_logger_t _Nonnull /* logger */,
                                         const rvnc_context_t _Nullable /* context */,
                                         RVNC_LOG_LEVEL /* logLevel */,
                                         const char* _Nonnull /* message */);

extern rvnc_logger_t _Nonnull rvnc_logger_create(rvnc_logger_delegate_log _Nonnull log,
                                                 rvnc_context_t _Nullable context);
extern void rvnc_logger_destroy(rvnc_logger_t _Nonnull logger);


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
extern bool rvnc_connection_state_error_should_display_to_user_get(rvnc_connection_state_t _Nonnull connectionState);
extern bool rvnc_connection_state_error_is_authentication_error_get(rvnc_connection_state_t _Nonnull connectionState);


#pragma mark - Framebuffer

extern uint16_t rvnc_framebuffer_size_width_get(rvnc_framebuffer_t _Nonnull framebuffer);
extern uint16_t rvnc_framebuffer_size_height_get(rvnc_framebuffer_t _Nonnull framebuffer);

// NOTE: This always returns 32-bit BGRA data.
extern void* _Nonnull rvnc_framebuffer_pixel_data_get(rvnc_framebuffer_t _Nonnull framebuffer);
extern uint64_t rvnc_framebuffer_pixel_data_size_get(rvnc_framebuffer_t _Nonnull framebuffer);


#pragma mark - Cursor

extern bool rvnc_cursor_is_empty_get(rvnc_cursor_t _Nonnull cursor);
extern uint16_t rvnc_cursor_size_width_get(rvnc_cursor_t _Nonnull cursor);
extern uint16_t rvnc_cursor_size_height_get(rvnc_cursor_t _Nonnull cursor);
extern uint16_t rvnc_cursor_hotspot_x_get(rvnc_cursor_t _Nonnull cursor);
extern uint16_t rvnc_cursor_hotspot_y_get(rvnc_cursor_t _Nonnull cursor);
extern int64_t rvnc_cursor_bits_per_component_get(rvnc_cursor_t _Nonnull cursor);
extern int64_t rvnc_cursor_bits_per_pixel_get(rvnc_cursor_t _Nonnull cursor);
extern int64_t rvnc_cursor_bytes_per_pixel_get(rvnc_cursor_t _Nonnull cursor);
extern int64_t rvnc_cursor_bytes_per_row_get(rvnc_cursor_t _Nonnull cursor);
extern void* _Nullable rvnc_cursor_pixel_data_get_copy(rvnc_cursor_t _Nonnull cursor);
extern void rvnc_cursor_pixel_data_destroy(void* _Nonnull pixelData);
extern uint64_t rvnc_cursor_pixel_data_size_get(rvnc_cursor_t _Nonnull cursor);


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

typedef void (*rvnc_connection_delegate_did_update_framebuffer)(rvnc_connection_t _Nonnull /* connection */,
                                                                const rvnc_context_t _Nullable /* context */,
                                                                _Nonnull rvnc_framebuffer_t /* framebuffer */,
                                                                uint16_t /* x */,
                                                                uint16_t /* y */,
                                                                uint16_t /* width */,
                                                                uint16_t /* height */);

typedef void (*rvnc_connection_delegate_did_update_cursor)(rvnc_connection_t _Nonnull /* connection */,
                                                           const rvnc_context_t _Nullable /* context */,
                                                           rvnc_cursor_t _Nonnull /* cursor */);

extern rvnc_connection_delegate_t _Nonnull rvnc_connection_delegate_create(rvnc_connection_delegate_connection_state_did_change _Nonnull connectionStateDidChange,
                                                                           rvnc_connection_delegate_authenticate _Nonnull authenticate,
                                                                           rvnc_connection_delegate_did_create_framebuffer _Nonnull didCreateFramebuffer,
                                                                           rvnc_connection_delegate_did_resize_framebuffer _Nonnull didResizeFramebuffer,
                                                                           rvnc_connection_delegate_did_update_framebuffer _Nonnull didUpdateFramebuffer,
                                                                           rvnc_connection_delegate_did_update_cursor _Nonnull didUpdateCursor);

extern void rvnc_connection_delegate_destroy(rvnc_connection_delegate_t _Nonnull connectionDelegate);


#pragma mark - Connection

extern rvnc_connection_t _Nonnull rvnc_connection_create(rvnc_settings_t _Nonnull settings,
                                                         rvnc_logger_t _Nullable logger,
                                                         rvnc_context_t _Nullable context);

extern void rvnc_connection_destroy(rvnc_connection_t _Nonnull connection);

extern void rvnc_connection_connect(rvnc_connection_t _Nonnull connection);
extern void rvnc_connection_disconnect(rvnc_connection_t _Nonnull connection);

extern void rvnc_connection_update_color_depth(rvnc_connection_t _Nonnull connection, RVNC_COLORDEPTH colorDepth);
extern void rvnc_connection_delegate_set(rvnc_connection_t _Nonnull connection, rvnc_connection_delegate_t _Nullable connectionDelegate);

extern rvnc_context_t _Nullable rvnc_connection_context_get(rvnc_connection_t _Nonnull connection);
extern rvnc_connection_state_t _Nonnull rvnc_connection_state_get_copy(rvnc_connection_t _Nonnull connection);
extern rvnc_settings_t _Nonnull rvnc_connection_settings_get_copy(rvnc_connection_t _Nonnull connection);

extern void rvnc_connection_mouse_move(rvnc_connection_t _Nonnull connection, uint16_t x, uint16_t y);
extern void rvnc_connection_mouse_down(rvnc_connection_t _Nonnull connection, RVNC_MOUSEBUTTON button, uint16_t x, uint16_t y);
extern void rvnc_connection_mouse_up(rvnc_connection_t _Nonnull connection, RVNC_MOUSEBUTTON button, uint16_t x, uint16_t y);
extern void rvnc_connection_mouse_wheel(rvnc_connection_t _Nonnull connection, RVNC_MOUSEWHEEL wheel, uint16_t x, uint16_t y, uint32_t steps);

// NOTE: key is an X11 keysym (eg. `XK_A` for the latin capital letter "A"). See the `X11KeySymbols` struct.
extern void rvnc_connection_key_down(rvnc_connection_t _Nonnull connection, uint32_t key);
extern void rvnc_connection_key_up(rvnc_connection_t _Nonnull connection, uint32_t key);
