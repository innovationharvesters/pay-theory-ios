//
//  Valid.swift
//  PayTheory
//
//  Created by Austin Zani on 7/23/21.
//

import SwiftUI
import Combine

public class CardNumber: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        validCancellable = card.validCardNumber.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = card.$number.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class CardExp: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        validCancellable = card.validExpirationDate.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = card.$expirationDate.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class CardCvv: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        validCancellable = card.validSecurityCode.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = card.$securityCode.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class CardPostalCode: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        validCancellable = card.validPostalCode.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = card.address.$postalCode.sink { empty in
            let postal = empty ?? ""
            self.isEmpty = postal.isEmpty
        }
    }
}

public class ACHAccountName: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let bank: ACH
    
    init(bank: ACH) {
        self.bank = bank
        
        validCancellable = bank.validAccountName.sink { valid in
            
            self.isValid = valid
        }
        
        emptyCancellable = bank.$name.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class ACHAccountNumber: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let bank: ACH
    
    init(bank: ACH) {
        self.bank = bank
        
        validCancellable = bank.validAccountNumber.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = bank.$accountNumber.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class ACHRoutingNumber: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let bank: ACH
    
    init(bank: ACH) {
        self.bank = bank
        
        validCancellable = bank.validBankCode.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = bank.$bankCode.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class CashName: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let cash: Cash
    
    init(cash: Cash) {
        self.cash = cash
        
        validCancellable = cash.validName.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = cash.$name.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class CashContact: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let cash: Cash
    
    init(cash: Cash) {
        self.cash = cash
        
        validCancellable = cash.validContact.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = cash.$contact.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class ValidFields: ObservableObject {
    @Published public var cash = false
    private var cashCancellable: AnyCancellable!
    @Published public var card = false
    private var cardCancellable: AnyCancellable!
    @Published public var ach = false
    private var achCancellable: AnyCancellable!
    
    private let cashObject: Cash
    private let cardObject: Card
    private let achObject: ACH
    private let transaction: Transaction
    
    var validCashPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(cashObject.$isValid, transaction.$hostToken)
            .map { valid, hostToken in
                if valid == false || hostToken == nil {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    var validCardPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(cardObject.$isValid, transaction.$hostToken)
            .map { valid, hostToken in
                if valid == false || hostToken == nil {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    var validACHPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(achObject.$isValid, transaction.$hostToken)
            .map { valid, hostToken in
                if valid == false || hostToken == nil {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    init(cash: Cash, card: Card, ach: ACH, transaction: Transaction) {
        self.cashObject = cash
        self.cardObject = card
        self.achObject = ach
        self.transaction = transaction
        
        cashCancellable = validCashPublisher.sink { valid in
            self.cash = valid
        }
        
        cardCancellable = validCardPublisher.sink { valid in
            self.card = valid
        }
        
        achCancellable = validACHPublisher.sink { valid in
            self.ach = valid
        }
    }
}
