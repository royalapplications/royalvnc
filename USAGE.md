# Usage

## Building a headless client
- Create an instance of `VNCConnection.Settings` by providing the configuration parameters for your target host. This is an immutable type, so all properties must be set in the initializer and cannot be changed later.
    - If you don't want to customize the order and enabled state of `frameEncodings`, use `[VNCFrameEncodingType].default`.
    - For debugging purposes you may set `isDebugLoggingEnabled` to `true`. Note that this will impact performance noticeably and should only be enabled for debugging purposes.
```swift
let settings = VNCConnection.Settings(isDebugLoggingEnabled: true,
                                      hostname: "targethost",
                                      port: 5900,
                                      isShared: true,
                                      isScalingEnabled: true,
                                      useDisplayLink: true,
                                      inputMode: .forwardKeyboardShortcutsEvenIfInUseLocally,
                                      isClipboardRedirectionEnabled: true,
                                      colorDepth: .depth24Bit,
                                      frameEncodings: .default)
```
- Create an instance of `VNCConnection` by providing the settings you created in the previous step in the initializer. Make sure to keep a strong reference to the connection!
```swift
let connection = VNCConnection(settings: settings)
self.connection = connection // Keep a strong reference
```
- Assign an implementation of `VNCConnectionDelegate` to `VNCConnection.delegate` to receive notifications for connection state changes, framebuffer updates and other updates.
    - Note that a connection is very likely to fail if you forget to provide a delegate implementation because authentication is also handled via `VNCConnectionDelegate`. So a connection without a delegate will only succeed if the remote host requires no authentication.
    - For a headless client, you should at least implement `connection(_:stateDidChange:)`, `connection(_:credentialFor:completion:)` of the connection delegate.
```swift
connection.delegate = self

extension MyConnectionController: VNCConnectionDelegate {
    func connection(_ connection: VNCConnection,
                    stateDidChange connectionState: VNCConnection.ConnectionState) {
        // TODO: Update/show/hide progress indicator depending on connectionState.status
        // TODO: Destroy framebuffer view and disconnect delegate if the connection was closed
    }

    func connection(_ connection: VNCConnection,
                    credentialFor authenticationType: VNCAuthenticationType,
                    completion: @escaping (VNCCredential?) -> Void) {
        // TODO: Provide credential for authenticationType
        completion(nil)
    }

    func connection(_ connection: VNCConnection,
                    didCreateFramebuffer framebuffer: VNCFramebuffer) {
        // TODO: Create a framebuffer view and add it to the view hierarchy
    }

    func connection(_ connection: VNCConnection,
                    didResizeFramebuffer framebuffer: VNCFramebuffer) {
        // TODO: Resize your previously created framebuffer view
    }

    func connection(_ connection: VNCConnection,
                    didUpdateFramebuffer framebuffer: VNCFramebuffer,
                    x: UInt16, y: UInt16,
                    width: UInt16, height: UInt16) {
        // TODO: Update the image in your framebuffer view
    }

    func connection(_ connection: VNCConnection,
                    didUpdateCursor cursor: VNCCursor) {
        // TODO: Update the local cursor shown in the framebuffer view
    }
}
```
- Call `VNCConnection.connect()` to initiate the connection asynchronously.
- Updates to the connection's state will be delivered to `connection(_:stateDidChange:)` of the connection's delegate. The current status (Connecting, Connected, Disconnecting, Disconnected) of the connection is accessible via the `VNCConnection.ConnectionState`'s `status` property while the optional `error` property allows you to evaluate why a connection failed.
- If `connection(_:credentialFor:completion:)` is called, you're supposed to provide the user's credential for the authentication type specified in the `authenticationType` parameter by calling the completion handler.
    - Because `credential` is an optional parameter, you can pass `nil`, which indicates that the authentication process should be cancelled.
    - Because authentication types can have different input parameters, you will have to check which `VNCAuthenticationType` you should provide credentials for.
    - `VNCAuthenticationType` has convenience extensions (`requiresUsername`, `requiresPassword`) which help determine exactly which data has to be provided.
    - Once you have the user's credential data, either create an instance of `VNCPasswordCredential` or `VNCUsernamePasswordCredential` depending on the requirements of the authentication type and pass it to the completion handler.
```swift
func connection(_ connection: VNCConnection,
                credentialFor authenticationType: VNCAuthenticationType,
                completion: @escaping (VNCCredential?) -> Void) {
    let credential: VNCCredential?

    if authenticationType.requiresUsername {
        // TODO: Ask user to provide credential data
        credential = VNCUsernamePasswordCredential(username: "MyUser",
                                                   password: "MyPass")
    } else if authenticationType.requiresPassword {
        // TODO: Ask user to provide credential data
        credential = VNCPasswordCredential(password: "MyPass")
    } else {
        credential = nil
    }

    completion(credential)
}
```
- For a headless client, this is all that's needed to establish the connection and get notified about updates to it.
- To send input to the remote host, use one of the `VNCConnection`'s input APIs like `keyDown(_:)`, `keyUp(_:)`, `mouseButtonDown(_:x:y:)`, `mouseButtonUp(_:x:y:)`, etc.
```swift
// Convert the string "abc" into VNCKeyCode's
let keyCodes = VNCKeyCode.keyCodesFrom(characters: "abc")

// Press keys required for printing "abc"
for keyCode in keyCodes {
    connection.keyDown(keyCode)
    connection.keyUp(keyCode)
}

// Press return/enter key
connection.keyDown(.return)
connection.keyUp(.return)

// Press Left Mouse Button at x: 10, y: 15
connection.mouseButtonDown(.left, x: 10, y: 15)
connection.mouseButtonUp(.left, x: 10, y: 15)
```
- If you want to close the connection, call `VNCConnection.disconnect()`. Note that this is a non-blocking/asynchronous method and likely will only complete some time after you call it. Don't assume the connection has been fully teared down immediately after the call to `disconnect()`. Instead, wait for `connection(_:stateDidChange:)` to be called with a status of `VNCConnection.Status.disconnected`. Once that has happened, you're not(!) supposed to (re-)use the connection anymore and discard your strong reference to it.
```swift
// Begin disconnection, wait for response in connection(_:stateDidChange:)
self.connection.disconnect()

func connection(_ connection: VNCConnection,
                stateDidChange connectionState: VNCConnection.ConnectionState) {
    if connectionState.status == .disconnected {
        self.connection.delegate = nil

        // TODO: Destroy framebuffer view

        if let error = connectionState.error as? VNCError,
           error.shouldDisplayToUser {
            // TODO: Present error to the user
        }
    }
}
```

## Handling framebuffer updates
- Now that you have a functioning headless VNC connection you will likely also want to allow the user to see and interact with the remote desktop.
- To do so, you will have to implement additional `VNCConnectionDelegate` methods, namely `connection(_:didCreateFramebuffer:)`, `connection(_:didResizeFramebuffer:)`, `connection(_:didUpdateFramebuffer:x:y:width:height:)` and `connection(_:didUpdateCursor:)`.
- `connection(_:didCreateFramebuffer:)` and `connection(_:didResizeFramebuffer:)` are called when a framebuffer has been created or resized respectively. In both cases, you will need to (re-)create a view for the framebuffer and present it.
- `connection(_:didUpdateFramebuffer:x:y:width:height:)` is called whenever a specific region of the framebuffer has been updated. This allows you to optimize updates to your framebuffer view so that you can only render a subset of the full framebuffer's bounds.
- Last but not least, `connection(_:didUpdateCursor:)` is called whenever the remote desktop requests that you show a local mouse cursor. Note that not all VNC servers support local cursors so in some cases this delegate method may never get called.
- To retrieve an image of the remote desktop's framebuffer, you use `VNCFramebuffer.ciImage` or `VNCFramebuffer.cgImage`, depending on the context you'll render the image in.
- Then it's up to you to display that image to the user. You can, for instance directly assign the `CGImage` to the `contents` property of an `CALayer` or use Metal to render the `CIImage`.
```swift
func connection(_ connection: VNCConnection,
                didUpdateFramebuffer framebuffer: VNCFramebuffer,
                x: UInt16, y: UInt16,
                width: UInt16, height: UInt16) {
    // TODO: Only invalidate the part of the image that was updated, indicated by the x, y, width and height parameters
    self.view.layer?.contents = framebuffer.cgImage
}
```
- RoyalVNCKit also provides some ready-to-use views that handle this for you (and more, including input handling). For instance, `VNCCAFramebufferView` is an `NSView` subclass for macOS.
    - Just initialize the view with a frame, framebuffer and connection, add it to your view hierarchy and then forward some of the connection's delegate methods to it, namely `connection(_:didUpdateFramebuffer:x:y:width:height:)` and `connection(_:didUpdateCursor:)`.
