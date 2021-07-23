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
    
    let card: PaymentCard
    
    init(card: PaymentCard) {
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
    
    let card: PaymentCard
    
    init(card: PaymentCard) {
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
    
    let card: PaymentCard
    
    init(card: PaymentCard) {
        self.card = card
        
        validCancellable = card.validSecurityCode.sink { valid in
            self.isValid = valid
        }
        
        emptyCancellable = card.$securityCode.sink { empty in
            self.isEmpty = empty.isEmpty
        }
    }
}

public class ACHAccountName: ObservableObject {
    @Published public var isValid = false
    private var validCancellable: AnyCancellable!
    @Published public var isEmpty = false
    private var emptyCancellable: AnyCancellable!
    
    let bank: BankAccount
    
    init(bank: BankAccount) {
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
    
    let bank: BankAccount
    
    init(bank: BankAccount) {
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
    
    let bank: BankAccount
    
    init(bank: BankAccount) {
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
