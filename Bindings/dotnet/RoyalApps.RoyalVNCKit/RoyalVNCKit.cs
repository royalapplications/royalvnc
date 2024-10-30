using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace RoyalApps.RoyalVNCKit;

// NOTE: Manually "imported" from Sources/RoyalVNCKitC/include/RoyalVNCKitC.h
static unsafe partial class RoyalVNCKit
{
    // ReSharper disable once InconsistentNaming
    const string libRoyalVNCKit = nameof(RoyalVNCKit);
    const StringMarshalling Utf8Marshalling = StringMarshalling.Utf8;
    
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    internal delegate void LogDelegate(
        void* logger,
        void* context,
        LogLevel logLevel,
        string message
    );
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_logger_create(
        LogDelegate log,
        void* context
    );

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_logger_destroy(void* logger);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial byte rvnc_authentication_type_requires_username(AuthenticationType authenticationType);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial byte rvnc_authentication_type_requires_password(AuthenticationType authenticationType);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial AuthenticationType rvnc_authentication_request_authentication_type_get(void* authenticationRequest);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_authentication_request_cancel(void* authenticationRequest);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_authentication_request_complete_with_username_password(
        void* authenticationRequest,
        string username,
        string password
    );

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_authentication_request_complete_with_password(
        void* authenticationRequest,
        string password
    );

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_settings_create(
        byte isDebugLoggingEnabled,
        string hostname,
        ushort port,
        byte isShared,
        byte isScalingEnabled,
        byte useDisplayLink,
        InputMode inputMode,
        byte isClipboardRedirectionEnabled,
        ColorDepth colorDepth
    );

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_settings_destroy(void* settings);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_state_destroy(void* connectionState);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ConnectionStatus rvnc_connection_state_status_get(void* connectionState);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial string? rvnc_connection_state_error_description_get_copy(void* connectionState);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial byte rvnc_connection_state_error_should_display_to_user_get(void* connectionState);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial byte rvnc_connection_state_error_is_authentication_error_get(void* connectionState);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ushort rvnc_framebuffer_size_width_get(void* framebuffer);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ushort rvnc_framebuffer_size_height_get(void* framebuffer);

    // NOTE: This always returns 32-bit BGRA data.
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_framebuffer_pixel_data_get(void* framebuffer);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ulong rvnc_framebuffer_pixel_data_size_get(void* framebuffer);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial byte rvnc_cursor_is_empty_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ushort rvnc_cursor_size_width_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ushort rvnc_cursor_size_height_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ushort rvnc_cursor_hotspot_x_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ushort rvnc_cursor_hotspot_y_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial long rvnc_cursor_bits_per_component_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial long rvnc_cursor_bits_per_pixel_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial long rvnc_cursor_bytes_per_pixel_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial long rvnc_cursor_bytes_per_row_get(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_cursor_pixel_data_get_copy(void* cursor);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_cursor_pixel_data_destroy(void* pixelData);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial ulong rvnc_cursor_pixel_data_size_get(void* cursor);
    
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    internal delegate void ConnectionStateDidChangeDelegate(
        void* connection,
        void* context,
        void* connectionState
    );

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    internal delegate void AuthenticateDelegate(
        void* connection,
        void* context,
        void* authenticationRequest
    );

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    internal delegate void DidCreateFramebufferDelegate(
        void* connection,
        void* context,
        void* framebuffer
    );
    
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    internal delegate void DidResizeFramebufferDelegate(
        void* connection,
        void* context,
        void* framebuffer
    );

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    internal delegate void DidUpdateFramebufferDelegate(
        void* connection,
        void* context,
        void* framebuffer,
        ushort x,
        ushort y,
        ushort width,
        ushort height
    );

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    internal delegate void DidUpdateCursorDelegate(
        void* connection,
        void* context,
        void* cursor
    );

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_connection_delegate_create(
        ConnectionStateDidChangeDelegate connectionStateDidChange,
        AuthenticateDelegate authenticate,
        DidCreateFramebufferDelegate didCreateFramebuffer,
        DidResizeFramebufferDelegate didResizeFramebuffer,
        DidUpdateFramebufferDelegate didUpdateFramebuffer,
        DidUpdateCursorDelegate didUpdateCursor
    );

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_delegate_destroy(void* connectionDelegate);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_connection_create(
        void* settings,
        void* logger,
        void* context
    );

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_destroy(void* connection);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_connect(void* connection);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_disconnect(void* connection);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_update_color_depth(void* connection, ColorDepth colorDepth);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_delegate_set(void* connection, void* connectionDelegate);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_connection_context_get(void* connection);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_connection_state_get_copy(void* connection);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void* rvnc_connection_settings_get_copy(void* connection);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_mouse_move(void* connection, ushort x, ushort y);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_mouse_down(void* connection, MouseButton button, ushort x, ushort y);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_mouse_up(void* connection, MouseButton button, ushort x, ushort y);

    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_mouse_wheel(void* connection, MouseWheel wheel, ushort x, ushort y, uint steps);
    
    // NOTE: key is an X11 keysym (eg. `XK_A` for the latin capital letter "A"). See the `KeySymbol` enum.
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_key_down(void* connection, KeySymbol key);
    
    [LibraryImport(libRoyalVNCKit, StringMarshalling = Utf8Marshalling)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    internal static partial void rvnc_connection_key_up(void* connection, KeySymbol key);    
}