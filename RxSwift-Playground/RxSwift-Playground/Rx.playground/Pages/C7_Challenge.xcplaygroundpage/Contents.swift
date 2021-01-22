import Foundation
import RxSwift
import RxSwiftExt

example("Challenge_1") {
    
    //MARK: - Support function
    
    func formatPhoneNumber(from inputs: [Int]) -> String {
        var phone = inputs.compactMap({ String($0) }).joined()
        if phone.count > 3 {
            phone.insert("-", at: phone.index(phone.startIndex, offsetBy: 3))
        }
        
        if phone.count > 7 {
            phone.insert("-", at: phone.index(phone.startIndex, offsetBy: 7))
        }
        
        return phone
    }
    
    func convertCharToNum(c: String) -> Int? {
        if let cnum = Int(c), cnum < 10 {
            return cnum
        }
        
        let convert: [String: Int] = [
            "abc": 2, "def": 3, "ghi": 4,
            "jkl": 5, "mno": 6, "pqrs": 7,
            "tuv": 8, "wxyz": 9
        ]
        
        let converted = convert
            .filter({ $0.key.contains(c.lowercased()) })
            .first?
            .value
        return converted
    }
    
    //MARK: - Main code
    
    let dis = DisposeBag()
    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott",
    ]
    
    let input = PublishSubject<String>()
    input
        .skipWhile({ $0 == "0" })
        .map({ convertCharToNum(c: $0) })
        .unwrap()
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
    
    "a1ajkl1212".forEach({
        input.onNext(String($0))
    })
    
    input.onCompleted()
}
