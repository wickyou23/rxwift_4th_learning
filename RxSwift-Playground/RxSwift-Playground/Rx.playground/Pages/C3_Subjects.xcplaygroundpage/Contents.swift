import Foundation
import RxSwift
import RxCocoa

//MARK: - Common
enum MyError: Error {
    case anError
}

func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
    print(label, (event.element ?? event.error) ?? event)
}



//MARK: - PublishSubject

example("PublishSubject") {
    let subjects = PublishSubject<String>()
    subjects.onNext("Is anyone listening?")
    let subscriptionOne = subjects.subscribe { (element) in
        print("1) \(element)")
    }

    subjects.on(.next("1"))
    subjects.onNext("2")
    let subscriptionTwo = subjects.subscribe { (element) in
        print("2) \(element)")
    }

    //==========
    subjects.onNext("3")
    subscriptionOne.dispose()
    subjects.onNext("4")

    //==========
    subjects.onCompleted()
    subjects.onNext("5")
    subscriptionTwo.dispose()
    let disBag = DisposeBag()
    subjects.subscribe { (element) in
        print("3) \(element)")
    }.disposed(by: disBag)
    subjects.onNext("?")
}



//MARK: - Behavior subjects

example("BehaviorSubjects") {
    let subjects = BehaviorSubject(value: "Initial value")
    let disBag = DisposeBag()
    subjects.onNext("X")
    subjects.subscribe { (event) in
        print(label: "1)", event: event)
    }
    .disposed(by: disBag)

    //===========
    subjects.onError(MyError.anError)
    subjects.subscribe { (event) in
        print(label: "2)", event: event)
    }
    .disposed(by: disBag)
}



//MARK: - Replay subjects

example("ReplaySubjects") {
    let subjects = ReplaySubject<String>.create(bufferSize: 2)
    let disBag = DisposeBag()

    subjects.onNext("1")
    subjects.onNext("2")
    subjects.onNext("3")
    subjects.subscribe { (event) in
        print(label: "1)", event: event)
    }
    .disposed(by: disBag)

    subjects.subscribe { (event) in
        print(label: "2)", event: event)
    }
    .disposed(by: disBag)

    //=============
    subjects.onNext("4")
    subjects.onError(MyError.anError)
    subjects.subscribe { (event) in
        print(label: "3)", event: event)
    }
    .disposed(by: disBag)
}



//MARK: - Publish Relays

example("PublishRelay") {
    let relay = PublishRelay<String>()
    let disBag = DisposeBag()
    relay.accept("Knock Knock, anyone home?")
    relay.subscribe { (event) in
        print(label: "1)", event: event)
    }
    .disposed(by: disBag)
    relay.accept("1")
}



//MARK: - Behavior Relay

example("BehaviorRelay") {
    let disBag = DisposeBag()
    let relay = BehaviorRelay<String>(value: "Initial Value")
    relay.accept("New initial value")
    relay.subscribe { (event) in
        print(label: "1)", event: event)
    }
    .disposed(by: disBag)
    
    //==========
    relay.accept("1")
    relay.subscribe { (event) in
        print(label: "2)", event: event)
    }
    .disposed(by: disBag)
    relay.accept("2")
    print(relay.value)
}
