import MoneiTapToPay
import SwiftUI

struct ContentView: View {
  @State private var token = ""
  @State private var amount = "100"
  @State private var orderId = Self.newOrderId()
  @State private var isPaying = false
  @State private var outcome: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("POS token") {
          TextField("Token from POST /v1/pos/auth-token", text: $token, axis: .vertical)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        Section("Payment") {
          TextField("Amount in cents", text: $amount)
            .keyboardType(.numberPad)
          TextField("Order ID", text: $orderId)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        Section {
          Button("Tap to Pay on iPhone") { Task { await pay() } }
            .disabled(isPaying)
          Button("How to use Tap to Pay on iPhone") { Task { await showEducation() } }
        } footer: {
          if !TapToPay.isSupported {
            Text("This device does not support Tap to Pay on iPhone.")
          }
        }
        if let outcome {
          Section("Result") {
            Text(outcome).textSelection(.enabled)
          }
        }
      }
      .navigationTitle("MONEI Example")
    }
  }

  private func pay() async {
    isPaying = true
    defer { isPaying = false }
    do {
      // A real app calls prepare on launch and again with each refreshed token.
      try await TapToPay.prepare(token: token)
      // This example has no server for the webhook. A real app always passes its webhook URL.
      let result = try await TapToPay.acceptPayment(
        amount: Int(amount) ?? 0, orderId: orderId, callbackUrl: nil)
      let status =
        switch result.status {
        case .approved: "Approved"
        case .declined: "Declined"
        @unknown default: "Unknown status"
        }
      outcome = """
        \(status)
        Payment ID: \(result.paymentId)
        Card: \(result.cardBrand ?? "-") \(result.last4 ?? "")
        Order ID: \(result.orderId)
        """
      orderId = Self.newOrderId()
    } catch TapToPayError.outcomeUnknown(let orderId) {
      outcome = "Outcome unknown for order \(orderId). Do not retry; check the payment in MONEI."
    } catch {
      outcome = "Error: \(error)"
    }
  }

  private func showEducation() async {
    let root = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
      .first
    guard let root else { return }
    do {
      try await TapToPay.presentEducation(from: root)
    } catch {
      outcome = "Error: \(error)"
    }
  }

  private static func newOrderId() -> String {
    "order-\(Int(Date().timeIntervalSince1970))"
  }
}
