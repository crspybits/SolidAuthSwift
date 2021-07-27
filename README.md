# SolidAuthSwift

Implements the flow as in https://solid.github.io/authentication-panel/solid-oidc-primer.

Some discussion on the [Solid Project forum](https://forum.solidproject.org/t/both-client-and-server-accessing-a-pod/4511/6).

See also https://datatracker.ietf.org/doc/html/draft-ietf-oauth-dpop-03

Based off https://github.com/wrmack/Get-tokens

## SolidAuthSwiftUI

This is intended to be used on iOS. It provides the initial sign in via web browser user interface, allowing the user to enter their credentials. The output is a `code` value (see `AuthorizationResponse`), which can then be used to generate access and refresh tokens.

### Issues or questions
#### Sometimes when you tap on the initial sign in screen prompt, you don't get any secondary prompt.
i.e., you don't get any prompt beyond [this initial one](./Docs/README/InitialPrompt.png).
I thought originally this was to do with the requested response type, but it seems independent of that.
Note that I *am* successfully getting a `AuthorizationResponse` in this case despite the lack of a seond prompt.

#### Not getting app name showing up on sign in screen.
Despite having added "client_name" to the registration request, I'm still seeing [this](./Docs/README/AuthorizeNull.png).

### To be implemented
#### Not all codable classes are implemented or implemented in full. Mostly seems to be a style thing at this point.

## SolidAuthSwiftTools

This is intended to be used from either iOS or Linux. It is separated out from the `SolidAuthSwiftUI` library because `SolidAuthSwiftUI` contains UIKit code, and will *not* work on Linux.

The specific use case I'm designing for is for the key pair (needed to generate DPoP tokens) to be stored on a custom server only. The key pair will *not* be present on the iOS client app.

 The server I'm considering is running on Linux. Note that this is not a Solid Pod,. It's a custom server that will be making requests of a Solid Pod.
