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
//        getChallenge(apiKey: "Test", endpoint: String) { (result) in
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
        
        bankAccount.accountType = 3
        
        XCTAssertFalse(bankAccount.validAccountType)
        
        bankAccount.accountType = 1
        
        XCTAssertTrue(bankAccount.validAccountType)
        
        bankAccount.bankCode = "789456124"
        bankAccount.accountNumber = "11111111"
        bankAccount.name = "Test Name"
        
        XCTAssertTrue(bankAccount.isValid)
        XCTAssertEqual(bankAccount.lastFour, "1111")
        
    }
    
    func testCodingBankAccount() {
        let bank = BankAccount(name: "Test", accountNumber: "11111111", accountType: 0, bankCode: "11111111")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(bank)
        let decodedBank = try? decoder.decode(BankAccount.self, from: data!)
        
        XCTAssertEqual(bank, decodedBank)
        
        let bank2 = BankAccount(name: "Test", accountNumber: "11111111", accountType: 1, bankCode: "11111111")
        bank2.country = "USA"
        
        let data2 = try? encoder.encode(bank2)
        let decodedBank2 = try? decoder.decode(BankAccount.self, from: data2!)
        
        XCTAssertEqual(bank2, decodedBank2)

        XCTAssertNotEqual(bank, bank2)
    }
    
    func testBankAccountToDictionary() {
        let name = "test"
        let accNumber = "111111111"
        let accountType = 0
        let bankCode = "789456124"
        let bank = BankAccount(name: name, accountNumber: accNumber, accountType: accountType, bankCode: bankCode)
        
        let result: [String: Any] = bankAccountToDictionary(account: bank)
        
        XCTAssertEqual(name, result["name"] as? String ?? "")
        XCTAssertEqual(accNumber, result["account_number"] as? String ?? "")
        XCTAssertEqual("CHECKING", result["account_type"] as? String ?? "")
        XCTAssertEqual(bankCode, result["bank_code"] as? String ?? "")
    }
    
    func testClearBankAccount() {
        let bank = BankAccount(name: "Test", accountNumber: "11111111", accountType: 0, bankCode: "11111111")
        let bank2 = BankAccount()
        
        XCTAssertNotEqual(bank, bank2)
        
        bank.clear()
        
        XCTAssertEqual(bank, bank2)
    }
    
    func testBankAccountValidAccountType() {
        let bankAccount = BankAccount(identity: "test")
        XCTAssertTrue(bankAccount.validAccountType)
        
        bankAccount.accountType = 3
        
        XCTAssertFalse(bankAccount.validAccountType)
        
        bankAccount.accountType = 1
        
        XCTAssertTrue(bankAccount.validAccountType)
    }
    
    func testBankAccountValidBankCode() {
        let bankAccount = BankAccount(identity: "test")
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bankCode = "000"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bankCode = "789456124"
        
        XCTAssertTrue(bankAccount.validBankCode)
        
        bankAccount.bankCode = "789456124000"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bankCode = "F89456124"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bankCode = "7F9456124"
        
        XCTAssertFalse(bankAccount.validBankCode)
        
        bankAccount.bankCode = "78F456124"
        
        XCTAssertFalse(bankAccount.validBankCode)
    }
    
    func testCodingPaymentCard() {
        let card = PaymentCard(number: "11111111", expirationDate: "12 / 22", cvv: "240")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        
        let data = try? encoder.encode(card)
        let decodedCard = try? decoder.decode(PaymentCard.self, from: data!)
        
        XCTAssertEqual(card, decodedCard)
        
        let card2 = PaymentCard(number: "11111111", expirationDate: "12 / 22", cvv: "test")
        
        let data2 = try? encoder.encode(card2)
        let decodedCard2 = try? decoder.decode(PaymentCard.self, from: data2!)
        
        XCTAssertEqual(card2, decodedCard2)

        XCTAssertNotEqual(card, card2)
    }
    
    func testClearPaymentCard() {
        let card = PaymentCard(number: "11111111", expirationDate: "12 / 22", cvv: "240")
        let card2 = PaymentCard()
        
        XCTAssertNotEqual(card, card2)
        
        card.clear()
        
        XCTAssertEqual(card, card2)
    }
    
    func testCardToDictionary() {
        let name = "test"
        let number = "4242424242424242"
        let exp = "12 / 22"
        let cvv = "222"
        let card = PaymentCard(number: number, expirationDate: exp, cvv: cvv)
        card.name = name
        
        let result: [String: Any] = paymentCardToDictionary(card: card)
        
        XCTAssertEqual(name, result["name"] as? String ?? "")
        XCTAssertEqual(number, result["number"] as? String ?? "")
        XCTAssertEqual("12", result["expiration_month"] as? String ?? "")
        XCTAssertEqual("2022", result["expiration_year"] as? String ?? "")
        XCTAssertEqual(cvv, result["security_code"] as? String ?? "")
    }
    
    func testCreditCardBrand() {
        let card = PaymentCard()
        
        XCTAssertEqual(card.brand, "")
        
        card.number = "4024007148719528"
        
        XCTAssertEqual(card.brand, "Visa")
        
        card.number = "6011876717071788"
        
        XCTAssertEqual(card.brand, "Discover")
        
        card.number = "5548281345836773"
        
        XCTAssertEqual(card.brand, "MasterCard")
        
        card.number = "3538346422215451"
        
        XCTAssertEqual(card.brand, "JCB")
        
        card.number = "376520957732459"
        
        XCTAssertEqual(card.brand, "American Express")
        
        card.number = "30238697651289"
        
        XCTAssertEqual(card.brand, "Diners Club")
    }
    
    func testCardLastFour() {
        let card = PaymentCard()
        
        XCTAssertEqual(card.lastFour, "")
        
        card.number = "4024007148719528"
        
        XCTAssertEqual(card.lastFour, "9528")
        
        card.number = "6011876717071788"
        
        XCTAssertEqual(card.lastFour, "1788")
    }
    
    func testCardFirstSix() {
        let card = PaymentCard()
        
        XCTAssertEqual(card.firstSix, "")
        
        card.number = "4024007148719528"
        
        XCTAssertEqual(card.firstSix, "402400")
        
        card.number = "6011876717071788"
        
        XCTAssertEqual(card.firstSix, "601187")
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
        
        card.number = "1111111111111111"
        
        XCTAssertFalse(card.validCardNumber)
        
        card.number = "card-number-test"
        
        XCTAssertFalse(card.validCardNumber)
    }
    
    
    func testCreditCardIsValid() {
        let card = PaymentCard()
        XCTAssertFalse(card.isValid)
        
        card.number =  "424242424242424242424242424242"
        card.expirationDate = "12 / 22"
        card.securityCode = "232"
        
        XCTAssertFalse(card.isValid)
        
        card.number = "4242424242424242"
        card.expirationDate = "12 / 17"
        card.securityCode = "232"
        
        XCTAssertFalse(card.isValid)
        
        card.number = "4242424242424242"
        card.expirationDate = "12 / 22"
        card.securityCode = "232"
        
        XCTAssertTrue(card.isValid)
        
    }
    
    func testCreditCardExpIsValid() {
        let card = PaymentCard()
        XCTAssertFalse(card.validExpirationDate)
        
        card.expirationDate = "12 / 22"
        
        XCTAssertTrue(card.validExpirationDate)
        
        card.expirationDate = "NO / 22"
        
        XCTAssertFalse(card.validExpirationDate)
        
        card.expirationDate = "12 / NO"
        
        XCTAssertFalse(card.validExpirationDate)
        
    }
    
    func testCreditCardValidExpDate() {
        let card = PaymentCard()
        XCTAssertFalse(card.validExpirationDate)
        
        card.expirationDate = "13 / 22"
        
        
        XCTAssertFalse(card.validExpirationDate)
       
        card.expirationDate = "13 / 22"
        
        XCTAssertFalse(card.validExpirationDate)

        card.expirationDate = "11 / 2019"
        
        XCTAssertFalse(card.validExpirationDate)
        
        card.expirationDate = "NO"
        
        XCTAssertFalse(card.validExpirationDate)
        
        card.expirationDate = "13 / NO"
        
        XCTAssertFalse(card.validExpirationDate)

        card.expirationDate = "11 / 22"
        
        XCTAssertTrue(card.validExpirationDate)
    }
    
    func testDidSetCardDate() {
        let card = PaymentCard()
        
        card.expirationDate = "1"
        
        XCTAssertEqual(card.expirationDate, "1")
        
        card.expirationDate = "2"
        
        XCTAssertEqual(card.expirationDate, "02 / ")
        
        card.expirationDate = "22"
        
        XCTAssertEqual(card.expirationDate, "02 / 2")
        
        card.expirationDate = "02 /"
        
        XCTAssertEqual(card.expirationDate, "0")
        
        card.expirationDate = "02 / 2022"
        
        XCTAssertEqual(card.expirationDate, "02 / 2022")
        
        card.expirationDate = "02 / 202222"
        
        XCTAssertEqual(card.expirationDate, "02 / 2022")
        
        card.expirationDate = "02"
        
        XCTAssertEqual(card.expirationDate, "02 / ")
        
    }
    
    func testDidSetCadNumber() {
        let card = PaymentCard()
        
        card.number = "1"
        
        XCTAssertEqual(card.number, "1")
        
        card.number = "3456"
        
        XCTAssertEqual(card.number, "3456 ")
        
        card.number = "3456 12345"
        
        XCTAssertEqual(card.number, "3456 12345")
        
        card.number = "3456 123456"
        
        XCTAssertEqual(card.number, "3456 123456 ")
        
        card.number = "3456 123456"
        
        XCTAssertEqual(card.number, "3456 12345")
        
        card.number = "4242"
        
        XCTAssertEqual(card.number, "4242 ")
        
        card.number = "4242 4"
        
        XCTAssertEqual(card.number, "4242 4")
        
        card.number = "4242 4242"
        
        XCTAssertEqual(card.number, "4242 4242 ")
        
        card.number = "4242 4242 424"
        
        XCTAssertEqual(card.number, "4242 4242 424")
        
        card.number = "4242 4242 4242"
        
        XCTAssertEqual(card.number, "4242 4242 4242 ")
        
        card.number = "4242 4242 4242"
        
        XCTAssertEqual(card.number, "4242 4242 424")
    }
    
    func testCodingAddress() {
        let address = Address()
        address.city = "Test Town"
        address.country = "USA"
        address.region = "OH"
        address.line1 = "12 Test Street"
        address.line2 = "Apt 2"
        address.postalCode = "45212"
        
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
    
    func testAddressToDictionary() {
        let city = "Test Town"
        let country = "USA"
        let region = "OH"
        let lineOne = "12 Test Street"
        let lineTwo = "Apt 2"
        let postalCode = "45212"
        let address = Address()
        address.city = city
        address.country = country
        address.region = region
        address.line1 = lineOne
        address.line2 = lineTwo
        address.postalCode = postalCode
        
        let result: [String: Any] = addressToDictionary(address: address)
        
        XCTAssertEqual(city, result["city"] as? String ?? "")
        XCTAssertEqual(country, result["country"] as? String ?? "")
        XCTAssertEqual(region, result["region"] as? String ?? "")
        XCTAssertEqual(lineOne, result["line1"] as? String ?? "")
        XCTAssertEqual(lineTwo, result["line2"] as? String ?? "")
        XCTAssertEqual(postalCode, result["postal_code"] as? String ?? "")
    }
    
    func testDidSetRegion() {
        let address = Address()
        address.region = "TEST"
        
        XCTAssertEqual(address.region, nil)
        
        address.region = "OH"
        
        XCTAssertEqual(address.region, "OH")
    }
    
    func testDidSetPostalCode() {
        let address = Address()
        address.postalCode = "TEST"
        
        XCTAssertEqual(address.region, nil)
        
        address.postalCode = "12345"
        
        XCTAssertEqual(address.postalCode, "12345")
    }
    
    func testCodingBuyer() {
        let address = Address()
        address.city = "Test Town"
        address.country = "USA"
        address.region = "OH"
        address.line1 = "12 Test Street"
        address.line2 = "Apt 2"
        address.postalCode = "45212"
        
        let buyer = Buyer()
        buyer.firstName = "Test"
        buyer.lastName = "Buyer"
        buyer.email = "test"
        buyer.phone = "5555555555"
        buyer.personalAddress = address
        
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
    
    func testClearBuyer() {
        let firstName = "Test"
        let lastName = "Person"
        let email = "test@test.com"
        let phone = "5555555555"
        let buyer = Buyer()
        buyer.firstName = firstName
        buyer.lastName = lastName
        buyer.email = email
        buyer.phone = phone
        
        let buyer2 = Buyer()
        
        XCTAssertNotEqual(buyer, buyer2)
        
        buyer.clear()
        
        XCTAssertEqual(buyer, buyer2)
        
    }
    
    func testBuyerToDictionary() {
        let firstName = "Test"
        let lastName = "Person"
        let email = "test@test.com"
        let phone = "5555555555"
        let buyer = Buyer()
        buyer.firstName = firstName
        buyer.lastName = lastName
        buyer.email = email
        buyer.phone = phone
        
        let result: [String: Any] = buyerToDictionary(buyer: buyer)
        
        XCTAssertEqual(firstName, result["first_name"] as? String ?? "")
        XCTAssertEqual(lastName, result["last_name"] as? String ?? "")
        XCTAssertEqual(email, result["email"] as? String ?? "")
        XCTAssertEqual(phone, result["phone"] as? String ?? "")
    }
    
    func testFailureResponseInit() {
        let fail = FailureResponse(type: "Failure", receiptNumber: "12334", lastFour: "1234", brand: "VISA")
        let fail2 = FailureResponse(type: "Failure", receiptNumber: "12334", lastFour: "1234", brand: "VISA")
        
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
    

    
    func testCodingPayment() {
        let payment = Payment(currency: "USD", amount: 1200, service_fee: 200, merchant: "Test", feeMode: "service_fee")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try? encoder.encode(payment)
        let decodedPayment = try? decoder.decode(Payment.self, from: data!)
        
        XCTAssertEqual(payment, decodedPayment)
        
        payment.merchant = "Test2"

        XCTAssertNotEqual(payment, decodedPayment)
    }
    
    func testCodingIdempotencyResponse() {
        let payment = Payment(currency: "USD", amount: 2000, service_fee: 120, merchant: "12345", feeMode: "SURCHARGE")
        let idempotency = IdempotencyResponse(response: "Test", signature: "test", credId: "1234", idempotency: "09876", payment: payment)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try? encoder.encode(idempotency)
        let decodedIdempotency = try? decoder.decode(IdempotencyResponse.self, from: data!)
        
        XCTAssertEqual(idempotency, decodedIdempotency)
        
        idempotency.response = "Test2"

        XCTAssertNotEqual(idempotency, decodedIdempotency)
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
