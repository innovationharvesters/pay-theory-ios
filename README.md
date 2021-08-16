# Pay Theory iOS SDK

[![CI Status](https://img.shields.io/travis/60404116/PayTheory.svg?style=flat)](https://travis-ci.org/60404116/PayTheory)
[![Version](https://img.shields.io/cocoapods/v/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)
[![License](https://img.shields.io/cocoapods/l/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)
[![Platform](https://img.shields.io/cocoapods/p/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)

## Requirements

Written in SwiftUI and requires iOS 14 for App Attestation

## Register your application

Before you can use Pay Theory iOS SDK you must register your app in Pay Theory's merchant portal

![App Registration](https://assets.paytheory.com/android/ios-registration.png)

For each mobile app you want to register 
*   enter you applications bundle identifier
*   enter the associated Apple Team ID

## Installation

PayTheory is available through [CocoaPods](https://cocoapods.org). To install
the most recent stable build, simply add the following line to your Podfile:

```ruby
pod 'PayTheory'
```

Check our page on [CocoaPods](https://cocoapods.org) for the most recent version and 
development versions, to use a specific or development version add it to the line like so:

```ruby
pod 'PayTheory', '~> RELEASE'
```

_replace RELEASE with the number below_

[![Version](https://img.shields.io/cocoapods/v/PayTheory.svg?style=flat)](https://cocoapods.org/pods/PayTheory)

At the top of the view import PayTheory

```swift
import PayTheory
```

### Troubleshooting

If you encounter missing libraries, ensure that Xcode and CocoaPods are both up to date

## Usage

### Initialization

Initialize a PayTheory element for handling state. It accepts the following arguments.
*   **apiKey**: Your PayTheory merchant API Key
*   **tags**: optional custom tags you can include to track purchases
*   **fee_mode**: optionally set the fee mode.  By default **.SURCHARGE** mode is used **.SERVICE_FEE** mode is available only when enabled by Pay Theory **.SURCHARGE** mode applies a fee of 2.9% + $0.30 to be deducted from original amount **.SERVICE FEE** mode calculates a fee based on predetermined parameters  and adds it to the original amount

```swift
let apiKey = 'your-api-key'
let TAGS: [String: String] = [
        "pay-theory-account-code": "code-123456789",
        "pay-theory-reference": "field-trip"
      ];

let pt = PayTheory(apiKey: apiKey, tags: tags, fee_mode: .SURCHARGE)
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

There is also a combined text field available if you wanted all three required fields in one text field

```swift
PTCombinedCard()
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

All four fields are required to capture the info needed to initialize an ACH transaction

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

### Cash Text Fields

These custom text fields are what will be used to collect the Cash information for generating a cash barcode.

Both text fields are required to capture the info needed to generate a Cash barcode

*   ACH Account Number
*   ACH Account Type

```swift
PTCashContact()
PTCashName()
```

### Pay Theory Button

This button component allows a transaction to be initialized. It will be disabled until it has the required data needed to initialize a transaction. It accepts a few arguments needed to initialize the payment.

**Required**
*   **amount**: Payment amount that should be charged to the card in cents
*   **completion**: Function that will handle the result of the call returning a dictionary or **FailureResponse**

**Optional**
*   **text**: Text that shows in the button
    *   *default*:  Confirm
*   **buyerOptions**: *Buyer* object that will pass details about buyer into the payment that will be tied to the payment



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
PTButton(amount: amount, completion: completion)
```

### Wrapping your PayTheory Fields and Button

The PayTheory Fields and Button you will be using need to be wrapped with the PTForm component. You should pass the PayTheory object as an `environmentObject` to the PTForm.

```swift
PTForm{
    PTCardNumber()
    PTExp()
    PTCvv()
    PTButton(amount: amount, completion: completion)
}.environmentObject(pt)
```

## Custom Tags

To track payments with custom tags simply add the following when initializing the SDK:

-   **pay-theory-account-code**: Code that will be used to track the payment and can be filtered by.
-   **pay-theory-reference**: Custom description assigned to a payment that can later be filtered by.


```swift
let TAGS: [String: String] = [
        "pay-theory-account-code": "code-123456789",
        "pay-theory-reference": "field-trip"
      ];
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
    var receipt_number: String?
    var last_four: String?
    var brand: String? 
    //Will not include the brand if it is an ACH or Cash transaction
    var state = "FAILURE"
    var type: String
    //Type will be the specific details of the failure
}
```

## Cash Response

Once the PTButton is clicked and a cash barcode is generated, a dictionary will be returned with the following info:

```swift 
[
    "BarcodeUid":"XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX@partner",
    "Merchant":"XXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX",
    "barcode":"12345678901234567890",
    "barcodeFee":"2.0",
    "barcodeUrl":"https://partner.env.ptbar.codes/XXXXXX",
    "mapUrl":"https://pay.vanilladirect.com/pages/locations",
]
```

It is reccomended to provide both the Barcode URL and Map URL as links that open in their default browser to the payee.

## Buyer Class

The buyer class can be used to pass buyer options into the PTButton to assosciate buyer details with a payment

```swift 
class Buyer {
    var phone: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var personalAddress: Address
}


class Address {
    var city: String?
    var country: String?
    //Region would be the state and should be the 2 character abbreviation
    var region: String?
    var line1: String?
    var line2: String?
    //Postal code will only accept a 5 character zip
    var postalCode: String?
}
```
## Valid State

There are eight fields that require validation. 

-   Card
    -   cardNumber
    -   cvv
    -   exp
-   ACH
    -   achAccountNumber
    -   achAccountName
    -   achRoutingNumber
-   Cash
    -   cashName
    -   cashContact

For each of these fields we have access to two pieces of state

-   **isEmpty**: *Bool*: has there been anything input into the text field
-   **isValid**: *Bool*: does the text entered pass validation

These can be accessed from the PayTheory object like so

```swift
let pt = PayTheory(apiKey: apiKey, tags: tags, fee_mode: .SURCHARGE)

//Card details
pt.cardNumber.isValid
pt.cardNumber.isEmpty
pt.cvv.isValid
pt.cvv.isEmpty
pt.exp.isValid
pt.exp.isEmpty

//ACH details
pt.achAccountNumber.isValid
pt.achAccountNumber.isEmpty
pt.achAccountName.isValid
pt.achAccountName.isEmpty
pt.achRoutingNumber.isValid
pt.achRoutingNumber.isEmpty

//Cash Details
pt.cashName.isValid
pt.cashName.isEmpty
pt.cashContact.isValid
pt.cashContact.isEmpty
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
