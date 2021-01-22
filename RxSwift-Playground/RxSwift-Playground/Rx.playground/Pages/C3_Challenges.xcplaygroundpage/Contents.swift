import Foundation
import RxSwift
import RxCocoa

let relay = BehaviorRelay<UserSession>(value: UserSession())

enum LoginError {
    case wrongPasswordError
}

struct UserSession {
    var userName: String = ""
    var hasLogin: Bool = false
}

func LoginWith(username: String, password: String, completion: ((UserSession?, LoginError?) -> Void)) {
    guard username == "ThangPhung" && password == "ThangPhung" else {
        completion(nil, .wrongPasswordError)
        return
    }
    
    completion(UserSession(userName: "ThangPhung", hasLogin: true), nil)
}

func logout() {
    relay.accept(UserSession())
}

func performActionRequiringLoggedInUser() {
    guard !relay.value.hasLogin else {
        print("performActionRequiringLoggedInUser")
        return
    }
    
    LoginWith(username: "ThangPhung", password: "ThangPhung") { (newSession, error) in
        guard let newSs = newSession else {
            print(error.debugDescription)
            return
        }
        
        relay.accept(newSs)
        performActionRequiringLoggedInUser()
    }
}

example("Challenge 2 using behavior relay") {
    let disBag = DisposeBag()
    relay.subscribe { (event) in
        guard let element = event.element, element.hasLogin else {
            print("User is not logged in")
            return
        }
        
        print("\(element.userName) has been logged in")
    }
    .disposed(by: disBag)
    performActionRequiringLoggedInUser()
    logout()
}
