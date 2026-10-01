# MONEI Tap to Pay SDK for iOS

Accept contactless card payments with Tap to Pay on iPhone inside your own iOS app. MONEI processes the payments.

This repository contains the Swift package, the release binaries and an example app (`Example/`).

## Requirements

- iOS 18.5 or later.
- iPhone XS or newer. `TapToPay.isSupported` is `false` on other devices.
- The Tap to Pay on iPhone entitlement from Apple:
  1. Request the development entitlement from Apple for your team.
  2. Build and test your payment flow with it.
  3. Request the publishing entitlement. Apple asks for screenshots or a video of your payment flow.
- In your app target:
  - Add the entitlement key `com.apple.developer.proximity-reader.payment.acceptance` with the value `true` to the `.entitlements` file.
  - Add `NSLocationWhenInUseUsageDescription` to `Info.plist`. The SDK needs the location of the device to accept payments.
- A MONEI account and its API key. A test mode API key gives sandbox tokens.
- Read access to this repository and a GitHub token (see [Install](#install)).
- App Store privacy details. Declare these data types in App Store Connect, all for app functionality and not for tracking:
  - Coarse location, not linked to the user (this SDK).
  - Precise location, not linked to the user (the payment engine in this package).
  - Device ID, linked to the user (the payment engine in this package).

Use the name "Tap to Pay on iPhone" in your UI, as the Apple Human Interface Guidelines require.

## Install

The package is private. The binaries are private release assets. You need two things:

1. **Git read access** to `MONEI/monei-tap-to-pay-ios-spm`. Ask MONEI to give access to your GitHub account.
2. **A `~/.netrc` entry for `api.github.com`.** Swift Package Manager downloads the binaries from the GitHub API with this entry.

Create a GitHub personal access token (classic) with the `repo` scope. Fine-grained tokens do not work for outside collaborators on organization repositories. Then add this to `~/.netrc`:

```
machine api.github.com
  login <your-github-username>
  password <your-github-token>
```

Set the file permissions to `600`:

```sh
chmod 600 ~/.netrc
```

### Add the package

In Xcode, select **File > Add Package Dependencies** and enter:

```
https://github.com/MONEI/monei-tap-to-pay-ios-spm
```

Add the `MoneiTapToPay` product to your app target.

Not verified: MONEI has not tested this Xcode dialog with the private binaries yet. Verified: `xcodebuild -resolvePackageDependencies -packageAuthorizationProvider netrc` with the `~/.netrc` entry above.

In `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/MONEI/monei-tap-to-pay-ios-spm", exact: "0.1.0-beta.4")
],
targets: [
  .target(name: "YourApp", dependencies: [
    .product(name: "MoneiTapToPay", package: "monei-tap-to-pay-ios-spm")
  ])
]
```

Use `exact:` for 0.x versions. From 1.0.0, use `from:`.

### CI

CI needs the same two things. Keep the token in a secret. Never commit it.

Not verified: MONEI has not run the GitHub Actions and Xcode Cloud setups below yet. Tell MONEI if they do not work for you.

**GitHub Actions.** The default `GITHUB_TOKEN` cannot read this repository. Write a netrc file from a secret before the build:

```yaml
- name: Write netrc for MONEI Tap to Pay
  env:
    MONEI_TTP_TOKEN: ${{ secrets.MONEI_TTP_TOKEN }}
  run: |
    printf 'machine github.com\n  login x-access-token\n  password %s\nmachine api.github.com\n  login x-access-token\n  password %s\n' \
      "$MONEI_TTP_TOKEN" "$MONEI_TTP_TOKEN" > ~/.netrc
    chmod 600 ~/.netrc
```

The `github.com` entry gives git access. The `api.github.com` entry gives access to the binaries. Run `xcodebuild` with `-scmProvider system -packageAuthorizationProvider netrc`, so that it uses git and the netrc file.

**Xcode Cloud.**

1. In App Store Connect, give Xcode Cloud access to `MONEI/monei-tap-to-pay-ios-spm` as an additional repository.
2. Add a secret environment variable to the workflow, for example `MONEI_TTP_TOKEN`.
3. Add `ci_scripts/ci_post_clone.sh` to your repository. Make it executable. Xcode Cloud runs it before it resolves packages.

```sh
#!/bin/sh
set -e
printf 'machine api.github.com\n  login x-access-token\n  password %s\n' "$MONEI_TTP_TOKEN" > ~/.netrc
chmod 600 ~/.netrc
```

## Backend: get a token

The app needs a POS token for each payment session. Your server gets the token from the MONEI API. The API key stays on your server. Never put the API key in the app.

```sh
curl -X POST https://api.monei.com/v1/pos/auth-token \
  -H "Authorization: $MONEI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"storeId": "<MONEI store ID>"}'
```

Response:

```json
{ "token": "<jwt>" }
```

Send only the value of the `token` field to the app. Do not send the full JSON body. The SDK cannot use it.

Optional body fields:

| Field | Value |
|---|---|
| `storeId` | The MONEI store ID of the physical store of the device. MONEI records the payments under this store. The store must belong to the account of the API key. If not, payments fail with "Store not found". |
| `pointOfSaleId` | The ID of a Point of Sale that you created in MONEI. Never use a device identifier here. If you send it, the store comes from the Point of Sale. |

Rules:

- **One token for each device.** Cache the token for each device.
- **Renew before expiry.** A token is valid for 24 hours. Get a new token before it expires. Then call `prepare` again with the new token.
- **Several MONEI accounts.** If you have more than one MONEI account (for example, separate legal entities), each device uses the API key of the account that its store belongs to. Use one account on each device. MONEI has not tested a switch to another account on one device yet.
- **Test and live.** A test mode API key gives a sandbox token. A live API key gives a live token. Do not mix test and live tokens on one device.

API reference: https://docs.monei.com/apis/rest/pos-auth-token-create/

## App: accept a payment

The API is `@MainActor`. Call it from the main actor, for example from a SwiftUI view.

```swift
import MoneiTapToPay

// On launch, and again after each token renewal.
func startTapToPay() async {
  guard TapToPay.isSupported else { return } // Hide Tap to Pay on iPhone in your UI.
  do {
    let token = try await myServer.fetchPosToken() // The "token" field only.
    try await TapToPay.prepare(token: token)
  } catch {
    // See "Errors".
  }
}

// When the customer pays.
func pay(amountInCents: Int, orderId: String) async {
  do {
    let result = try await TapToPay.acceptPayment(
      amount: amountInCents,
      orderId: orderId,
      callbackUrl: URL(string: "https://example.com/monei/webhook"))
    switch result.status {
    case .approved: showApproved(result)
    case .declined: showDeclined(result)
    @unknown default: showPending(orderId)
    }
  } catch TapToPayError.outcomeUnknown(let orderId) {
    // Do not retry. Check this orderId in MONEI (see "Errors").
    showPending(orderId)
  } catch {
    // See "Errors".
  }
}
```

### Public API

| Symbol | Description |
|---|---|
| `TapToPay.isSupported: Bool` | `true` when the device supports Tap to Pay on iPhone. |
| `TapToPay.prepare(token: String) async throws` | Stores the token and prepares the reader in the background. It does not show Apple's terms. It asks for location permission if the user did not answer yet. Call it on launch and after each token renewal. |
| `TapToPay.acceptPayment(amount: Int, orderId: String, callbackUrl: URL?) async throws -> PaymentResult` | Takes one card payment. `amount` is in euro cents and must be more than 0. `orderId` is your own reference and must not be empty. |
| `TapToPay.presentEducation(from: UIViewController) async throws` | Shows Apple's screens that teach how to tap a card. |
| `PaymentResult` | `paymentId` (MONEI payment ID), `status` (`.approved` or `.declined`), `cardBrand` (the card network name in lowercase, for example `visa` or `amex`; `unknown` for a network the SDK does not know; or `nil`), `last4` (or `nil`), `orderId`. |

### Payment flow

1. Call `prepare` on launch. The token stays in memory only, so call `prepare` again after each launch.
2. Call `acceptPayment` with your own `orderId`. Use a new, non-empty `orderId` for each order. MONEI stores it with the payment, and you use it to reconcile.
3. The SDK needs a location fix to prepare the reader. The first `prepare` or `acceptPayment` after launch waits up to 15 seconds for it.
4. The first `acceptPayment` on a device shows Apple's Tap to Pay on iPhone terms if the account is not linked yet.
5. Apple shows the tap screen. The customer taps the card.
6. `acceptPayment` returns a `PaymentResult` or throws a `TapToPayError`.

The SDK prepares the reader again when the app comes back to the foreground. You do not need to do this.

The SDK never retries a payment.

### Trusted result: the webhook

Always pass `callbackUrl`. MONEI sends a signed webhook to this URL with the payment result. The signed webhook is the only trusted payment result. Verify its signature on your server. Use the app result for the UI only.

### Education

Call `presentEducation(from:)` to show Apple's education screens, for example on first use and from your help menu.

### Switch statements

The SDK uses library evolution. Its public enums are not frozen. A `switch` over `PaymentResult.Status`, `TapToPayError` or `TapToPayErrorCode` needs an `@unknown default` case. Without it, your app does not compile.

## Errors

All calls throw `TapToPayError`.

| Error | Thrown by | Meaning | What to do |
|---|---|---|---|
| `notSupported` | all calls | The device or iOS version does not support Tap to Pay on iPhone. | Hide Tap to Pay on iPhone. |
| `locationDenied` | `prepare`, `acceptPayment` | The user did not allow location access, or `Info.plist` has no `NSLocationWhenInUseUsageDescription`. | Tell the user to allow location access in Settings. Then try again. |
| `termsDeclined` | `acceptPayment` | The user did not accept Apple's terms, or linking failed. | Tell the user that the terms are necessary. The next `acceptPayment` shows the terms again. |
| `invalidArgument` | `acceptPayment` | `amount` is 0 or less, or `orderId` is empty. | Correct the value. |
| `tokenExpired` | `prepare`, `acceptPayment` | The token expired. | Get a new token from your server. Call `prepare`. Then try again. |
| `invalidToken` | `prepare` | The SDK cannot read the token. | Send only the `token` field. Get a new token and call `prepare`. Until then, `acceptPayment` throws `notPrepared`. |
| `notPrepared` | `acceptPayment` | No valid token is stored. | Call `prepare` first. |
| `busy` | `acceptPayment` | A payment is in progress. | Wait until it ends. Disable your pay button during a payment. |
| `cancelled` | `acceptPayment` | The user cancelled on Apple's screen. No payment occurred. | Start a new payment when the customer is ready. |
| `sdkUpgradeRequired` | `prepare`, `acceptPayment` | MONEI blocked this SDK version. All calls fail with this error. | Update to a newer SDK version and release your app. |
| `outcomeUnknown(orderId:)` | `acceptPayment` | The SDK cannot tell if the payment reached MONEI. The card can be charged. Causes: a connection or server error at any step of the payment, most iOS reader errors (also a card read or PIN error), or a cancelled task. Some of these occur before the card is charged, but the SDK cannot tell which. | **Do not retry, and do not charge again with a new `orderId`.** Show a pending state. Wait for the signed webhook for this `orderId`, or find the `orderId` in the MONEI Dashboard ([Payments](https://docs.monei.com/manage-account/transaction-history/), filter by order ID) or with the GraphQL API [`charges`](https://docs.monei.com/apis/graphql/operations/queries/charges/) query (`filter.orderId`). If no payment shows, this does not prove that the card was not charged. Contact MONEI support with the `orderId` before you charge the customer again. |
| `paymentFailed(code:)` | all calls | The payment or setup failed. See the codes below. | See the codes below. |

`TapToPayErrorCode` values:

| Code | Meaning | What to do |
|---|---|---|
| `cardDeclined` | The card was declined during the read. No payment occurred. | Ask for a different card. |
| `readerNotReady` | The reader session was not ready or expired. | Try again. The SDK prepares the reader again on the next call. |
| `locationTimeout` | The device did not get a location in 15 seconds. | Make sure that Location Services are on. Then try again. |
| `unknown` | The payment did not start. No payment occurred. | Try again. If the error continues, contact MONEI. |

A `PaymentResult` with status `.declined` is not an error. The card was read and the issuer declined the payment. The payment is in MONEI with its `paymentId`.

## Versioning

The SDK uses semantic versioning (`MAJOR.MINOR.PATCH`).

- **Patch:** bug fixes. No change to the public API or to error semantics.
- **Minor:** the same public API with a new version of the internal payment engine, or new API that does not break your code.
- **Major:** a change in error semantics, or a change that breaks your code.
- **0.x prereleases** are for internal testing only. Do not ship them to production.

Releases from `0.1.0-beta.4` have a signed `MoneiTapToPay` binary (team `72J3PXJJ4K`). `0.1.0-beta.3` is not signed.

| SDK version | iOS minimum | Built with | Notes |
|---|---|---|---|
| `0.1.0-beta.4` | 18.5 | Xcode 26.6 (Swift 6.3.3) | Prerelease for internal testing. Signed. |
| `0.1.0-beta.3` | 18.5 | Xcode 27.0 (Swift 6.4) | Prerelease for internal testing. Not signed. |

Use the same Xcode version as "Built with", or a newer one.

## Example app

`Example/TapToPayExample.xcodeproj` is a SwiftUI app that uses this package. It has a token field, an amount, an order ID, a pay button, education and a result view. Set your team and bundle ID, then run it on a supported iPhone.
