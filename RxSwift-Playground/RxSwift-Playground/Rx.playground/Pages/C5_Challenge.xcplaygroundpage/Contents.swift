import Foundation
import RxSwift


example("Challenge_1") {
    func formatPhoneNumber(from inputs:[Int]) -> String {
        var phone = inputs.compactMap({ String($0) }).joined()
        if phone.count > 3 {
            phone.insert("-", at: phone.index(phone.startIndex, offsetBy: 3))
        }
        
        if phone.count > 7 {
            phone.insert("-", at: phone.index(phone.startIndex, offsetBy: 7))
        }
        
        return phone
    }
    
    let dis = DisposeBag()
    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott",
    ]
    
    let input = PublishSubject<Int>()
    input
        //1. Phone numbers can't begin with 0 - use skipWhile
        .skipWhile ({ $0 <= 0 })
        //2. Filter to only allow elements that are less than 10
        .filter({ $0 < 10 })
        //Limiting this example to US phone number, which are 10 digits
        .take(10)
        .toArray()
        .subscribe(onSuccess: {
            (digits) in
            let phone = formatPhoneNumber(from: digits)
            if let ct = contacts[phone] {
                print("Dialing \(ct): \(phone)")
            }
            else {
                print("Contact not found")
            }
        })
        .disposed(by: dis)
    
    input.onNext(0)
    input.onNext(603)
    
    input.onNext(2)
    input.onNext(1)
//    input.onNext(7)
    input.onNext(2)
    
    "5551212".forEach({
        if let num = Int("\($0)") {
            input.onNext(num)
        }
    })
    
    input.onNext(9)
    
    input.onCompleted()
}
