# Pay Theory iOS SDK

[![CI Status](https://img.shields.io/travis/60404116/PayTheory.svg?style=flat)](https://travis-ci.org/60404116/PayTheory)
[![Version](https://img.shields.io/cocoapods/v/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)
[![License](https://img.shields.io/cocoapods/l/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)
[![Platform](https://img.shields.io/cocoapods/p/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)

## Requirements

Written in SwiftUI and requires iOS 14 for App Attestation

## Register your application

Before you can use Pay Theory iOS SDK you must register your app in Pay Theory's merchant portal

![App Registration](http://books-ui-assets.s3-website-us-east-1.amazonaws.com/android/ios-registration.png)

For each mobile app you want to register 
*   enter you applications bundle identifier
*   enter the associated Apple Team ID

## Installation

PayTheory is available through [CocoaPods](https://cocoapods.org). To install
the most recent stable build, simply add the following line to your Podfile:

```ruby
pod 'PayTheory', :git => 'https://github.com/pay-theory/pay-theory-ios', :branch => 'austin'
```

Check our page on [CocoaPods](https://cocoapods.org) for the most recent version and 
beta versions, to use a specific or beta version add it to the line like so:

```ruby
pod 'PayTheory', :git => 'https://github.com/pay-theory/pay-theory-ios', :branch => 'dev' 
```

At the top of the view import PayTheory

```swift
import PayTheory
```

## Usage

Initialize a PayTheory element for handling state. It accepts the following arguments.
*   **apiKey**: Your PayTheory merchant API Key
*   **tags**: optional custom tags you can include to track purchases
*   **environment**: tells the SDK if it should be working from a demo or production environment (**.DEMO** or **.PROD**). Defaults to **.DEMO**
*   **fee_mode**: optionally set the fee mode.  By default **.SURCHARGE** mode is used **.SERVICE_FEE** mode is available only when enabled by Pay Theory **.SURCHARGE** mode applies a fee of 2.9% + $0.30 to be deducted from original amount **.SERVICE FEE** mode calculates a fee based on predetermined parameters  and adds it to the original amount

```swift
let apiKey = 'your-api-key'
let tags: [String: Any] = ["YOUR_TAG_KEY": "YOUR_TAG_VALUE"]

let pt = PayTheory(apiKey: apiKey, tags: tags, environment: .DEMO, fee_mode: .SURCHARGE)
```

The content view in which the PayTheory object will be used needs to be wrapped with the PTForm component. You should pass the PayTheory object as an EnvironmentObject to the PTForm.

```swift
let apiKey = 'your-api-key'
let tags: [String: Any] = ["YOUR_TAG_KEY": "YOUR_TAG_VALUE"]

let pt = PayTheory(apiKey: apiKey, tags: tags, environment: .DEMO, fee_mode: .SURCHARGE)

PTForm{
    ContentView()
}.EnvironmentObject(pt)
```
### Credit Card Text Fields

These custom text fields are what will be used to collect the card information for the transaction.

There are three required text fields to capture the info needed to initialize a card transaction

*   Credit Card Number
*   Credit Card Expiration
*   Credit Card CVV

```swift
PTCardNumber()
PTExp()
PTCvv()
```

There are optional fields for capturing Billing Address and Name On Card

*   Credit Card Name
*   Credit Card Address Line One
*   Credit Card Address Line Two
*   Credit Card City
*   Credit Card State
*   Credit Card Zip

```swift
//Name on Card
PTCardName()

//Billing Address
PTCardLineOne()
PTCardLineTwo()
PTCardCity()
PTCardState()
PTCardZip()
```

### ACH Text Fields

These custom text fields are what will be used to collect the ACH information for the transaction.

All four text fields are required to capture the info needed to initialize an ACH transaction

*   ACH Account Number
*   ACH Account Type
*   ACH Account Name
*   ACH Routing Number

```swift
PTAchAccountName()
PTAchAccountType()
PTAchAccountNumber()
PTAchRoutingNumber()
```

### Pay Theory Button

This button component allows a transaction to be initialized. It will be disabled until it has the required data needed to initialize a transaction. It accepts a few arguments needed to initialize the payment.

*   **amount**: Payment amount that should be charged to the card in cents
*   **completion**: Function that will handle the result of the call returning a dictionary or **FailureResponse**

```swift
let amount = 1000

func completion(result: Result<[String: Any], FailureResponse>){
    switch result {
    case .success(let token):
            ...
        case .failure(let error):
            ...
        }
}

...
PTButton(amount: 5000, completion: completion)
```

### Capture or Cancel an Authorization

If the fee_mode is set to **.SERVICE_FEE** there is a confirmation step required. There are functions available to confirm or cancel the transaction after displaying the service fee to the user. The capture function accepts a completion handler for the response. To access these pull in the PayTheory object as an environment variable as shown below.

```swift
@EnvironmentObject var pt: PayTheory

func captureCompletion(result: Result<[String:Any], FailureResponse>){
    switch result {
    case .success(let completion):
        ...
    case .failure(let response):
        ...
    }
}


//To capture the transaction
    pt.capture(completion: captureCompletion)
    
//To cancel the transaction
    pt.cancel()

```

## Tokenization Response

When the necessary info is collected and the PTButton is clicked when fee_mode is set to **.SERVICE_FEE** the token details are returned as a dictionary with the following info:

*note that the service fee is included in amount*

```swift 
//Response for a card transaction
[
    "receipt_number": "pt-env-XXXXXX",
    "first_six": "XXXXXX", 
    "brand": "XXXXXXXXX", 
    "amount": 1000, 
    "convenience_fee": 195
]

//Response for an ACH transaction
[
    "receipt_number": "pt-env-XXXXXX",
    "last_four": "XXXX",
    "amount": 1000, 
    "convenience_fee": 195
]
```

## Completion Response

Once the PTButton is clicked and service_fee is set to **.SURCHARGE** or if the capture function is called after tokenization, a dictionary will be returned with the following info:

*note that the service fee is included in amount*

```swift 
//Response for a card transaction
[
   "receipt_number":"pt-env-XXXXXX",
    "last_four": "XXXX",
    "brand": "XXXXXXXXX",
    "created_at":"YYYY-MM-DDTHH:MM:SS.ssZ",
    "amount": 999,
    "service_fee": 195,
    "state":"SUCCEEDED",
    "tags": ["pay-theory-environment":"env","pt-number":"pt-env-XXXXXX", "YOUR_TAG_KEY": "YOUR_TAG_VALUE"]
]

//Response for an ACH transaction
[
   "receipt_number":"pt-env-XXXXXX",
    "last_four": "XXXX",
    "brand": "ACH",
    "created_at":"YYYY-MM-DDTHH:MM:SS.ssZ",
    "amount": 999,
    "service_fee": 195,
    "state":"SUCCEEDED",
    "tags": ["pay-theory-environment":"env","pt-number":"pt-env-XXXXXX", "YOUR_TAG_KEY": "YOUR_TAG_VALUE"]
]
```

## Failure Response

If a failure or decline occurs during the transaction, a FailureResponse object will be returned with the following info:

*note that the service fee is included in amount*

```swift 
class FailureResponse {
    var receipt_number: String
    var last_four: String
    var brand: String? //Will not include the brand if it is an ACH transaction
    var state = "FAILURE"
    var type: String
}
```

## Styling the text fields and button

To style the text fields and button you can simply treat them as any other standard SwiftUI text field to style.

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

PTCardName().textFieldStyle()
PTCardNumber().textFieldStyle()
PTExp().textFieldStyle()
PTCvv().textFieldStyle()
```

## Author

60404116, support@paytheory.com

## License

PayTheory is available under the MIT license. See the LICENSE file for more info.
