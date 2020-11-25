import XCTest
@testable import PayTheory
import Alamofire
import Mocker

class Tests: XCTestCase {
    
//    func testUserFetching() {
//        let configuration = URLSessionConfiguration.af.default
//        configuration.protocolClasses = [MockingURLProtocol.self]
//
//        let apiEndpoint = URL(string: "https://dev.tags.api.paytheorystudy.com/challenge")!
//        let expectedUser = Challenge()
//        let requestExpectation = expectation(description: "Request should finish")
//
//        let mockedData = try! JSONEncoder().encode(expectedUser)
//        Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData]).register()
//
//        getChallenge(apiKey: "Test") { (result) in
//            debugPrint("Test", result)
//            requestExpectation.fulfill()
//        }
//
//        wait(for: [requestExpectation], timeout: 10.0)
//    }
    func testBankAccountIsValid() {
        let bankAccount = BankAccount(identity: "test")
        XCTAssertFalse(bankAccount.isValid)
        XCTAssertTrue(bankAccount.validAccountType)
        
        bankAccount.account_type = "test"
        
        XCTAssertFalse(bankAccount.validAccountType)
        
        bankAccount.account_type = "SAVINGS"
        
        XCTAssertTrue(bankAccount.validAccountType)
        
        bankAccount.bank_code = "789456124"
        bankAccount.account_number = "11111111"
        bankAccount.name = "Test Name"
        
        XCTAssertTrue(bankAccount.isValid)
        
        
    }
    
    func testCodingBankAccount() {
        let bank = BankAccount(name: "Test", account_number: "11111111", account_type: "CHECKING", bank_code: "11111111")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(bank)
        let decodedBank = try? decoder.decode(BankAccount.self, from: data!)
        
        XCTAssertEqual(bank, decodedBank)
        
        let bank2 = BankAccount(name: "Test", account_number: "11111111", account_type: "CHECKING", bank_code: "11111111")
        bank2.country = "USA"
        
        let data2 = try? encoder.encode(bank2)
        let decodedBank2 = try? decoder.decode(BankAccount.self, from: data2!)
        
        XCTAssertEqual(bank2, decodedBank2)

        XCTAssertNotEqual(bank, bank2)
    }
    
    func testBankAccountValidAccountType() {
        let bankAccount = BankAccount(identity: "test")
        XCTAssertTrue(bankAccount.validAccountType)
        
        bankAccount.account_type = "test"
        
        XCTAssertFalse(bankAccount.validAccountType)
        
        bankAccount.account_type = "SAVINGS"
        
        XCTAssertTrue(bankAccount.validAccountType)
    }
    
    func testBankAccountValidBankCode() {
        let bankAccount = BankAccount(identity: "test")
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bank_code = "000"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bank_code = "789456124"
        
        XCTAssertTrue(bankAccount.validBankCode)
        
        bankAccount.bank_code = "789456124000"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bank_code = "F89456124"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bank_code = "7F9456124"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bank_code = "78F456124"
        
        XCTAssertFalse(bankAccount.validBankCode)
    }
    
    func testCodingPaymentCard() {
        let card = PaymentCard(number: "11111111", expiration_year: "2022", expiration_month: "12" , cvv: "240")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(card)
        let decodedCard = try? decoder.decode(PaymentCard.self, from: data!)
        
        XCTAssertEqual(card, decodedCard)
        
        let card2 = PaymentCard(number: "11111111", expiration_year: "2022", expiration_month: "12" , cvv: "test")
        
        let data2 = try? encoder.encode(card2)
        let decodedCard2 = try? decoder.decode(PaymentCard.self, from: data2!)
        
        XCTAssertEqual(card2, decodedCard2)

        XCTAssertNotEqual(card, card2)
    }
    
    func testCreditCardValidCardNumber() {
        let card = PaymentCard()
        
        XCTAssertFalse(card.validCardNumber)
        
        card.number = "0001"
        
        XCTAssertFalse(card.validCardNumber)
        
        card.number = "4242424242424242"
        
        XCTAssertTrue(card.validCardNumber)
        
        card.number = "4929449361763377"
        
        XCTAssertTrue(card.validCardNumber)
        
        card.number = "4242424242424242424242424242"
        
        XCTAssertFalse(card.validCardNumber)
        
        card.number = "1111111111111111"
        
        XCTAssertFalse(card.validCardNumber)
        
        card.number = "card-number-test"
        
        XCTAssertFalse(card.validCardNumber)
    }
    
    func testCreditCardIsValid() {
        let card = PaymentCard()
        XCTAssertFalse(card.isValid)
        
        card.number =  "424242424242424242424242424242"
        card.expiration_year = "2022"
        card.expiration_month = "12"
        card.security_code = "232"
        
        XCTAssertFalse(card.isValid)
        
        card.number = "4242424242424242"
        card.expiration_year = "2017"
        card.expiration_month = "12"
        card.security_code = "232"
        
        XCTAssertFalse(card.isValid)
        
        card.number = "4242424242424242"
        card.expiration_year = "2022"
        card.expiration_month = "12"
        card.security_code = "232"
        
        XCTAssertTrue(card.isValid)
        
    }
    
    func testCreditCardValidExpDate() {
        let card = PaymentCard()
        XCTAssertFalse(card.validExpirationDate)
        
        card.expiration_month = "13"
        card.expiration_year = "22"
        
        
        XCTAssertFalse(card.validExpirationDate)
       
        card.expiration_month = "13"
        card.expiration_year = "2022"
        
        XCTAssertFalse(card.validExpirationDate)

        card.expiration_month = "11"
        card.expiration_year = "2019"
        
        XCTAssertFalse(card.validExpirationDate)
        
        card.expiration_month = "NO"
        
        XCTAssertFalse(card.validExpirationDate)
        
        card.expiration_month = "11"
        card.expiration_year = "NOPE"
        
        XCTAssertFalse(card.validExpirationDate)

        card.expiration_month = "11"
        card.expiration_year = "2021"
        
        XCTAssertTrue(card.validExpirationDate)
    }
    
    func testCodingAddress() {
        let address = Address()
        address.city = "Test Town"
        address.country = "USA"
        address.region = "OH"
        address.line1 = "12 Test Street"
        address.line2 = "Apt 2"
        address.postal_code = "45212"
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(address)
        let decodedAddress = try? decoder.decode(Address.self, from: data!)
        
        XCTAssertEqual(address, decodedAddress)
        
        let address2 = Address()
        
        let data2 = try? encoder.encode(address2)
        let decodedAddress2 = try? decoder.decode(Address.self, from: data2!)
        
        XCTAssertEqual(address2, decodedAddress2)
        
        XCTAssertNotEqual(address2, decodedAddress)
    }
    
    func testCodingBuyer() {
        let address = Address()
        address.city = "Test Town"
        address.country = "USA"
        address.region = "OH"
        address.line1 = "12 Test Street"
        address.line2 = "Apt 2"
        address.postal_code = "45212"
        
        let buyer = Buyer()
        buyer.first_name = "Test"
        buyer.last_name = "Buyer"
        buyer.email = "test"
        buyer.phone = "5555555555"
        buyer.personal_address = address
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(buyer)
        let decodedBuyer = try? decoder.decode(Buyer.self, from: data!)
        
        XCTAssertEqual(buyer, decodedBuyer)
        
        let buyer2 = Buyer()
        
        let data2 = try? encoder.encode(buyer2)
        let decodedBuyer2 = try? decoder.decode(Buyer.self, from: data2!)
        
        XCTAssertEqual(buyer2, decodedBuyer2)
        
        XCTAssertNotEqual(buyer2, buyer)
    }
    
    func testCodingIdentityResponse() {
        let identity = IdentityResponse()
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(identity)
        let decodedIdentityResponse = try? decoder.decode(IdentityResponse.self, from: data!)
        
        XCTAssertEqual(identity, decodedIdentityResponse)
        
        let identity2 = IdentityResponse()
        identity2.id = "1"

        XCTAssertNotEqual(identity2, identity)
    }
    
    func testIdentityBodyInitializer() {
        let buyer = Buyer()
        buyer.first_name = "Test"
        
        let identity = IdentityBody(entity: buyer)
        
        
        XCTAssertEqual(identity.entity.first_name, "Test")
    }
    
    func testCodingAuthorization() {
        let auth = Authorization(merchant_identity: "Test", amount: "1000", source: "Test Source", idempotency_id: "test")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(auth)
        let decodedAuth = try? decoder.decode(Authorization.self, from: data!)
        
        XCTAssertEqual(auth, decodedAuth)
        
        let auth2 = Authorization(merchant_identity: "Test", amount: "1000", source: "Test Source", idempotency_id: "test")
        auth2.processor = "1"
        
        let data2 = try? encoder.encode(auth2)
        let decodedAuth2 = try? decoder.decode(Authorization.self, from: data2!)
        
        XCTAssertEqual(auth2, decodedAuth2)

        XCTAssertNotEqual(auth2, auth)
    }
    
    func testCodingCaptureAuth() {
        let auth = CaptureAuth(fee: 100, capture_amount: 10000)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(auth)
        let decodedAuth = try? decoder.decode(CaptureAuth.self, from: data!)
        
        XCTAssertEqual(auth, decodedAuth)
        
        let auth2 = CaptureAuth(fee: 10, capture_amount: 1000)

        XCTAssertNotEqual(auth2, auth)
    }
    
    func testCodingAuthorizationResponse() {
        let auth = AuthorizationResponse()
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(auth)
        let decodedAuth = try? decoder.decode(AuthorizationResponse.self, from: data!)
        
        XCTAssertEqual(auth, decodedAuth)
        
        let auth2 = AuthorizationResponse()
        auth2.id = "1"

        XCTAssertNotEqual(auth2, auth)
    }
    
    func testCompletionResponseInit() {
        let success = CompletionResponse(receipt_number: "1111", last_four: "1234", brand: "VISA", created_at: "Today", amount: 1234, convenience_fee: 12, state: "SUCCESS")
        let success2 = CompletionResponse(receipt_number: "1111", last_four: "1234", brand: "VISA", created_at: "Today", amount: 1234, convenience_fee: 12, state: "SUCCESS")
        
        XCTAssertEqual(success, success2)
        
        success2.last_four = "4321"
        
        XCTAssertNotEqual(success, success2)
    }
    
    func testTokenizationResponseInit() {
        let token = TokenizationResponse(receipt_number: "1111", first_six: "123456", brand: "VISA", amount: 123, convenience_fee: 12)
        let token2 = TokenizationResponse(receipt_number: "1111", first_six: "123456", brand: "VISA", amount: 123, convenience_fee: 12)
        
        XCTAssertEqual(token, token2)
        
        token2.brand = "4321"
        
        XCTAssertNotEqual(token, token2)
    }
    
    func testFailureResponseInit() {
        let fail = FailureResponse(type: "Failure", receipt_number: "12334", last_four: "1234", brand: "VISA")
        let fail2 = FailureResponse(type: "Failure", receipt_number: "12334", last_four: "1234", brand: "VISA")
        
        XCTAssertEqual(fail, fail2)
        
        let fail3 = FailureResponse(type: "Test")
        
        XCTAssertNotEqual(fail, fail3)
    }
    
    func testCodingAttestation() {
        let attest = Attestation(attestation: "qwerty", nonce: "test", key: "test", currency: "USD", amount: 1000)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(attest)
        let decodedAttest = try? decoder.decode(Attestation.self, from: data!)
        
        XCTAssertEqual(attest, decodedAttest)
        
        let attest2 = Attestation(attestation: "12345", nonce: "test", key: "Test", currency: "USD", amount: 1000)

        XCTAssertNotEqual(attest, attest2)
    }
    
    func testCodingChallenge() {
        let challenge = Challenge()
        challenge.challenge = "Test"
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(challenge)
        let decodedChallenge = try? decoder.decode(Challenge.self, from: data!)
        
        XCTAssertEqual(challenge, decodedChallenge)
        
        let challenge2 = Challenge()

        XCTAssertNotEqual(challenge, challenge2)
    }
    
    func testCodingIdempotency() {
        let payment = Payment(currency: "USD", amount: 1200, convenience_fee: 200, merchant: "Test")
        
        
        let idempotency = Idempotency(idempotency: "test", payment: payment, token: "Test")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try? encoder.encode(idempotency)
        let decodedIdempotency = try? decoder.decode(Idempotency.self, from: data!)
        
        XCTAssertEqual(idempotency, decodedIdempotency)
        
        idempotency.token = "Test2"

        XCTAssertNotEqual(idempotency, decodedIdempotency)
    }
    
    func testCodingPayment() {
        let payment = Payment(currency: "USD", amount: 1200, convenience_fee: 200, merchant: "Test")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try? encoder.encode(payment)
        let decodedPayment = try? decoder.decode(Payment.self, from: data!)
        
        XCTAssertEqual(payment, decodedPayment)
        
        payment.merchant = "Test2"

        XCTAssertNotEqual(payment, decodedPayment)
    }
    
    func testCodingAWSResponse() {
        let aws = AWSResponse(response: "Response", signature: "Test", credId: "Test2")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try? encoder.encode(aws)
        let decodedAWS = try? decoder.decode(AWSResponse.self, from: data!)
        
        XCTAssertEqual(aws, decodedAWS)
        
        aws.response = "Test"

        XCTAssertNotEqual(aws, decodedAWS)
    }
    
    
    
//    func testHandleResponse() {
//        let attestation =  Attestation(attestation: "Test", nonce: "Test", key: "Test", currency: "USD", amount: 1000)
//        let encoder = JSONEncoder()
//        let data = try? encoder.encode(attestation)
//        let response = AFDataResponse(request: nil, response: nil, data: data , metrics: nil, serializationDuration: 0, result: .success(data))
//        handleResponse(response: response) { response in
//            XCTAssertEqual(response.success, data)
//        }
//
//    }
    
    


    static var allTests = [
        ("Bank Account Has Required Fields", testBankAccountIsValid),
        ("Bank Account Valid Account Type", testBankAccountValidAccountType),
        ("Bank Account Valid Bank Code", testBankAccountValidBankCode),
        ("Credit Card Valid Card Number", testCreditCardValidCardNumber),
        ("Credit Card Has Required Fields", testCreditCardIsValid)
    ]
    
}
