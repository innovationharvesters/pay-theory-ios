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
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        card.validCardNumber.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        card.$number.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class CardExp: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        card.validExpirationDate.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        card.$expirationDate.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class CardCvv: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        card.validSecurityCode.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        card.$securityCode.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class CardPostalCode: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()

    let card: Card
    
    init(card: Card) {
        self.card = card
        
        card.validPostalCode.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        card.address.$postalCode.sink { empty in
            let postal = empty ?? ""
            self.isEmpty = postal.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class ACHAccountName: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()

    let bank: ACH
    
    init(bank: ACH) {
        self.bank = bank
        
        bank.validAccountName.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)

        bank.$name.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class ACHAccountNumber: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()

    let bank: ACH
    
    init(bank: ACH) {
        self.bank = bank
        
        bank.validAccountNumber.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        bank.$accountNumber.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class ACHRoutingNumber: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()

    let bank: ACH
    
    init(bank: ACH) {
        self.bank = bank
        
        bank.validBankCode.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        bank.$bankCode.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class CashName: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()

    let cash: Cash
    
    init(cash: Cash) {
        self.cash = cash
        
        cash.validName.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        cash.$name.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class CashContact: ObservableObject {
    @Published public var isValid = false
    @Published public var isEmpty = false
    private var cancellables = Set<AnyCancellable>()

    let cash: Cash
    
    init(cash: Cash) {
        self.cash = cash
        
        cash.validContact.sink { valid in
            self.isValid = valid
        }
        .store(in: &cancellables)
        
        cash.$contact.sink { empty in
            self.isEmpty = empty.isEmpty
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

public class ValidFields: ObservableObject {
    @Published public var cash = false
    @Published public var card = false
    @Published public var ach = false
    private var cancellables = Set<AnyCancellable>()
    
    private let cashObject: Cash
    private let cardObject: Card
    private let achObject: ACH
    private let transaction: Transaction
    
    var validCashPublisher: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest(cashObject.$isValid, transaction.$hostToken)
            .map { valid, hostToken in
                if valid == false || hostToken == nil {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    var validCardPublisher: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest(cardObject.$isValid, transaction.$hostToken)
            .map { valid, hostToken in
                if valid == false || hostToken == nil {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    var validACHPublisher: AnyPublisher<Bool, Never> {
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
        
        validCashPublisher.sink { valid in
            self.cash = valid
        }
        .store(in: &cancellables)
        
        validCardPublisher.sink { valid in
            self.card = valid
        }
        .store(in: &cancellables)
        
        validACHPublisher.sink { valid in
            self.ach = valid
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
