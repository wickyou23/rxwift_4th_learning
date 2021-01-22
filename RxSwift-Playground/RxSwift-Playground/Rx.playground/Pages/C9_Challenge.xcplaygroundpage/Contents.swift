import Foundation
import RxSwift
import RxCocoa

//MARK: - Case 1

example("C9_challenge_zip") {
    let source = Observable.of(1, 3, 5, 7, 9)
    let scanObservable = source.scan(5, accumulator: { $0 + $1 })
    let zipObservable = Observable.zip(source, scanObservable, resultSelector: { ($0, $1) })
    _ = zipObservable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - Case 2

example("C9_challenge_withLatestFrom") {
    var inputAr = [1, 3, 5, 7, 9]
    var rsReduce = inputAr.reduce(into: [Int]()) { (rs, value) in
        let lastRs = rs.last ?? 5
        rs.append(lastRs + value)
    }
    
    let first = PublishSubject<Int>()
    let second = PublishSubject<Int>()
    let observable = second.withLatestFrom(first, resultSelector: { ($1, $0) })
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    while !inputAr.isEmpty && !rsReduce.isEmpty {
        first.onNext(inputAr.removeFirst())
        second.onNext(rsReduce.removeFirst())
    }
}
