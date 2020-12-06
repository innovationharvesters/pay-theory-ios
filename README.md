# PayTheory

[![CI Status](https://img.shields.io/travis/60404116/PayTheory.svg?style=flat)](https://travis-ci.org/60404116/PayTheory)
[![Version](https://img.shields.io/cocoapods/v/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)
[![License](https://img.shields.io/cocoapods/l/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)
[![Platform](https://img.shields.io/cocoapods/p/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)

## Requirements

Written in SwiftUI and requires iOS 14 for App Attestation

## Installation

PayTheory is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PayTheory'
```

At the top of the view import PayTheory

```swift
import PayTheory
```

## Usage

Initalize a PayTheory element passing it an API Key and optionally an environment (.DEV or .PROD) which defaults to .DEV if not included.

```swift
let apiKey = 'your-api-key'

let pt = PayTheory(apiKey: apiKey, environment: .DEV)
```

An ancestor view to the views in which the PayTheory object will be used needs to be wrapped with the PTForm component. You should then pass it the PayTheory object as an EnvironmentObject. This makes sure the Envoronment Objects required by the Pay Theory Text Fields are available.

```swift
PTForm{
    AncestorView()
}.EnvironmentObject(pt)
```
### Credit Card Text Fields

These custom text fields are what will be used to collect the card information for the transaction.

There are four required text fields to capture the info needed to initiaize a transaction

- Credit Card Number
- Credit Card Expiration Month
- Credit Card Expiration Year
- Credit Card CVV

```swift
PTCardNumber()
PTExpYear()
PTExpMonth()
PTCvv()
```

There are optional fields for capturing Billing Address and Name On Card

- Credit Card Name
- Credit Card Address Line One
- Credit Card Address Line Two
- Credit Card City
- Credit Card State
- Credit Card Zip
- Credit Card Country

```swift
PTCardName()
PTCardLineOne()
PTCardLineTwo()
PTCardCity()
PTCardState()
PTCardZip()
PTCardCountry()
```

### Buyer Options

You can optionally pass buyer information that will be tied to a transaction. All pieces of data are optional in the buyer object. 

One way to capture buyer options are to use text fields the same as you would for card details

- Buyer First Name
- Buyer Last Name
- Buyer Phone
- Buyer Email
- Buyer Address Line One
- Buyer Address Line Two
- Buyer City
- Buyer State
- Buyer Zip
- Buyer Country


```swift
PTBuyerFirstName()
PTBuyerLastName()
PTBuyerPhone()
PTBuyerEmail()
PTBuyerLineOne()
PTBuyerLineTwo()
PTBuyerCity()
PTBuyerState()
PTBuyerZip()
PTBuyerCountry()
```

Another option is to pass the info in as a Buyer object when initializing the payment.

```swift
let address = Address(line1: "123 Street St", line2: "Apt 12", city: "Somewhere", country: "USA", state: "OH", zip: "12345")
let buyer = Buyer(first_name: "Some", last_name: "Body", email: "somebody@gmail.com", phone: "555-555-5555", address: address)
```

### Pay Theory Card Button

This button component allows a transaction to be initialized. It will be disabled until it has the required data needed to initialize a transaction. It accepts a few arguments needed to initialize the payment.

 - amount: Payment amount that should be charged to the card in cents.
 - PT: PayTheory object that was initiated in the project with the API Key.
 - buyer: Buyer that allows name, email, phone number, and address of the buyer to be associated with the payment. If Buyer Info is passed as an argument it will ignore the ones captured by the custom text fields
 - fee_mode: Defaults to .SURCHARGE if you don't declare it. Can also pass .SERVICE_FEE as alternate option if account is set up for Service Fees.
 - tags: 
 - completion: Function that will handle the result of the call returning a Tokenization Response or Failure Response


```swift
let tags: [String: Any] = ["YOUR_TAG_KEY": "YOUR_TAG_VALUE"]
let amount = 1000
let buyer = Buyer(first_name: "Some", last_name: "Body", email: "somebody@gmail.com")

func completion(result: Result<TokenizationResponse, FailureResponse>){
    switch result {
    case .success(let token):
            ...
        case .failure(let error):
            ...
        }
}

...
PTCardButton(amount: amount, buyer: buyer, PT: pt, fee_mode: .SURCHARGE, tags: tags, completion: completion)
```

### Caputre or Cancel an Authorization

Once the PTCardButton has been pressed and a TokenizationRespomse has been recieved you have two options. You can either cancel or confirm. Those are handled by two functions in the PayTheory object that accept a completion handler as an argument.

```swift
func captureCompletion(result: Result<CompletionResponse, FailureResponse>){
    switch result {
    case .success(let completion):
        ...
    case .failure(let response):
        ...
    }
}

func cancelCompletion(result: Result<Bool, FailureResponse>){
    switch result {
    case .success(_):
        ...
    case .failure(let response):
        ...
    }
}


//To capture the transaction
    pt.capture(completion: captureCompletion)
    
//To cancel the transaction
    pt.cancel(completion: cancelCompletion)

```

## Tokenization Response

When the necessary card info is collected and the PTCardButton is clicked the card token details are returned as a TokenizationResponse with the following info:

*note that the service fee is included in amount*

```swift 
class TokenizationResponse {
    var first_six: String
    var brand: String
    var receipt_number: String
    var amount: Int
    var convenience_fee: Int
}
```

## Completion Response

Upon completion of tokenization and capture, a CompletionResponse object will be returned:

*note that the service fee is included in amount*

```swift 
class CompletionResponse {
    var receipt_number: String
    var last_four: String
    var brand: String
    var created_at: String
    var amount: Int
    var convenience_fee: Int
    var state: String
}
```

## Failure Response

If a failure or decline occurs during the transaction, a FailureResponse object will be returned:

*note that the service fee is included in amount*

```swift 
class FailureResponse {
    var receipt_number: String
    var last_four: String
    var brand: String
    var state = "FAILURE"
    var type: String
}
```

## Styling the text fields and button

To style the text fields and button you can simply treat the as any other standard SwiftUI text field to style.

```swift
struct TextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(15)
            .font(Font.system(size: 15, weight: .medium, design: .serif))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
    }
}

extension View {
    func textFieldStyle() -> some View {
        self.modifier(TextField())
    }
}


PTCardNumber().textFieldStyle()
PTExpYear().textFieldStyle()
PTExpMonth().textFieldStyle()
PTCvv().textFieldStyle()
```


## Author

60404116, support@paytheory.com

## License

PayTheory is available under the MIT license. See the LICENSE file for more info.
