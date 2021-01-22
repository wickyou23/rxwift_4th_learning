import Foundation
import RxSwift
import RxCocoa

//MARK: - Ignoring operator

example("ignoreElements") {
    let strikes = PublishSubject<String>()
    let dis = DisposeBag()
    strikes
        //ignoreElements is useful when you only want to be notified when observable has terminated (.completed or . error) event
        .ignoreElements()
        .subscribe({ (event) in
            print(event)
        })
        .disposed(by: dis)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onCompleted()
}

example("elementAt") {
    let strikes = PublishSubject<String>()
    let dis = DisposeBag()
    strikes
        .element(at: 2)
        .subscribe { (event) in
            print(event)
        }
        .disposed(by: dis)
    
    strikes.onNext("X1")
    strikes.onNext("X2")
    strikes.onNext("X3")
}

example("filter") {
    let dis = DisposeBag()
    Observable.of(1, 2, 3, 4, 5, 6)
        .filter({ $0 % 2 == 0 })
        .subscribe { (event) in
            print(event)
        }
        .disposed(by: dis)
}

//MARK: - Skiping operator

example("skip") {
    let dis = DisposeBag()
    Observable.of("A", "B", "C", "D", "E", "F")
        .skip(3)
        .subscribe({
            print($0)
        })
        .disposed(by: dis)
}

example("skipWhile") {
    let dis = DisposeBag()
    Observable.of(1, 2, 3, 4, 5, 6, 7, 8, 9)
        //skipWhile only skip elements up until the first element is let through, and the all remaining element are allowed through
        .skip(while: { $0 % 2 == 1 })
        .subscribe({ print($0) })
        .disposed(by: dis)
}

example("skipUtil") {
    let dis = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    //When trigger emits, skipUntil will stop skippings.
    subject
        .skip(until: trigger)
        .subscribe({ print($0) })
        .disposed(by: dis)
    
    subject.onNext("A")
    subject.onNext("B")
    trigger.onNext("X") //subject stop skip
    subject.onNext("C")
}

//MARK: - Taking operator

example("take") {
    let dis = DisposeBag()
    Observable.of(1, 2, 3, 4, 5, 6, 7, 8)
        .take(3)
        .subscribe({ print($0) })
        .disposed(by: dis)
}

example("takeWhile") {
    let dis = DisposeBag()
    Observable.of(2, 2, 4, 4, 6, 6)
        .enumerated()
        .take(while: { $1 % 2 == 0 && $0 < 3 })
        .map({ $0.element })
        .subscribe({ print($0) })
        .disposed(by: dis)
}

example("takeUntil") {
    let dis = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
        .take(until: trigger)
        .subscribe({ print($0) })
        .disposed(by: dis)
    
    subject.onNext("1")
    subject.onNext("2")
    trigger.onNext("X") //subject stop take
    subject.onNext("3")
}

//MARK: - Distinct operators

example("distinctUntilChanged") {
    let dis = DisposeBag()
    Observable.of("A", "A", "B", "B", "B", "A") //Remove continuous duplicate (at right sile) ex: A, B, A
        .distinctUntilChanged()
        .subscribe({ print($0) })
        .disposed(by: dis)
}

example("distinctUntilChanged(_:)") {
    let dis = DisposeBag()
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<NSNumber>.of(10, 110, 20, 200, 210, 310)
        .distinctUntilChanged { (a, b) -> Bool in
            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "),
                  let bWords = formatter.string(from: b)?.components(separatedBy: " ") else {
                return false
            }
            
            var containsMatch = false
            for aWords in aWords where bWords.contains(aWords) {
                containsMatch = true
                break
            }
            
            return containsMatch
        }
        .subscribe({ print($0) })
        .disposed(by: dis)
}
