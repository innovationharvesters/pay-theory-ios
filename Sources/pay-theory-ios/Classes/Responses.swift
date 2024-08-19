//
//  Responses.swift
//  PayTheory
//
//  Created by Austin Zani on 8/5/24.
//

public enum SuccessfulResponse {
    case Cash(CashBarcode)
//    case Confirmation(Confirmation)
    case Failure(FailedTransaction)
    case Success(SuccessfulTransaction)
    case Tokenized(TokenizedPaymentMethod)
}

public class SuccessfulTransaction {
    public var transactionId: String
    public var lastFour: String
    public var brand: String
    public var createdAt: String
    public var amount: Double
    public var serviceFee: Double
    public var state: String
    public var metadata: [String: Any]
    public var payorId: String
    public var paymentMethodId: String

    init(response: [String: Any]) {
        self.transactionId = response["receipt_number"] as? String ?? ""
        self.lastFour = response["last_four"] as? String ?? ""
        self.brand = response["brand"] as? String ?? ""
        self.createdAt = response["created_at"] as? String ?? ""
        self.amount = response["amount"] as? Double ?? 0.0
        self.serviceFee = response["service_fee"] as? Double ?? 0.0
        self.state = response["state"] as? String ?? ""
        self.metadata = response["metadata"] as? [String: Any] ?? [:]
        self.payorId = response["payor_id"] as? String ?? ""
        self.paymentMethodId = response["payment_method_id"] as? String ?? ""
    }
}

public class TokenizedPaymentMethod {
    public var paymentMethodId: String
    public var payorId: String
    public var lastFour: String
    public var brand: String
    public var expiration: String
    public var paymentType: String
    public var metadata: [String: Any]

    init(response: [String: Any]) {
        self.paymentMethodId = response["payment_method_id"] as? String ?? ""
        self.payorId = response["payor_id"] as? String ?? ""
        self.lastFour = response["last_four"] as? String ?? ""
        self.brand = response["card_brand"] as? String ?? ""
        self.expiration = response["exp_date"] as? String ?? ""
        self.paymentType = response["payment_type"] as? String ?? ""
        self.metadata = response["metadata"] as? [String: Any] ?? [:]
    }
}

func extractFailureDetails(from response: [String: Any]) -> (errorCode: String, errorText: String) {
    // Navigate through the nested dictionary to extract the values
    if let body = response["body"] as? [String: Any],
       let status = body["status"] as? [String: Any],
       let reason = status["reason"] as? [String: Any] {
        
        let errorCode = reason["error_code"] as? String ?? ""
        let errorText = reason["error_text"] as? String ?? ""
        
        return (errorCode, errorText)
    }
    
    // Return nil if any of the keys are not found
    return ("", "")
}

public class FailedTransaction {
    public var transactionId: String
    public var lastFour: String
    public var brand: String
    public var state: String
    public var payorId: String
    public var failureCode: String
    public var failureText: String

    init(response: [String: Any]) {
        self.transactionId = response["receipt_number"] as? String ?? ""
        self.lastFour = response["last_four"] as? String ?? ""
        self.brand = response["brand"] as? String ?? ""
        self.state = response["state"] as? String ?? ""
        self.payorId = response["payor_id"] as? String ?? ""
        let failureDetails = extractFailureDetails(from: response)
        self.failureCode = failureDetails.errorCode
        self.failureText = failureDetails.errorText
    }
}

public class CashBarcode {
    public var barcodeUrl: String
    public var barcodeId: String
    public var mapUrl = "https://pay.vanilladirect.com/pages/locations"

    init(response: [String: Any]) {
        self.barcodeUrl = response["barcode_url"] as? String ?? ""
        self.barcodeId = response["barcode_id"] as? String ?? ""
    }
}

public enum PTErrorCode: String {
    case actionComplete
    case actionInProgress
    case attestationFailed
    case inProgress
    case invalidAPIKey
    case invalidParam
    case noFields
    case notReady
    case notValid
    case socketError
    case tokenFailed
}

public class PTError: Error, Equatable {
    public static func == (lhs: PTError, rhs: PTError) -> Bool {
        if lhs.code == rhs.code &&
            lhs.error == rhs.error {
            return true
        }
        return false
    }

    public var code: PTErrorCode
    public var error: String
    public init(code: PTErrorCode, error: String) {
        self.code = code
        self.error = error
    }
}
