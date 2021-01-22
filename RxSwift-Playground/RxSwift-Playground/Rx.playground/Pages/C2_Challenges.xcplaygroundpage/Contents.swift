import Foundation
import RxSwift

//MARK: - Challenge 1: Perform side effects with "do" operator

example("Nerver with do operator") {
    let disBag = DisposeBag()
    let observable = Observable<Void>.never()
    observable.do { (_) in
        print("onNext")
    } afterNext: { (_) in
        print("afterNext")
    } onError: { (error) in
        print("onError: \(error.localizedDescription)")
    } afterError: { (error) in
        print("afterError: \(error.localizedDescription)")
    } onCompleted: {
        print("onCompleted")
    } afterCompleted: {
        print("afterCompleted")
    } onSubscribe: {
        print("onSubscribe")
    } onSubscribed: {
        print("onSubscribed")
    } onDispose: {
        print("onDispose")
    }
    .subscribe()
    .disposed(by: disBag)
}



//MARK: - Challenge 2: Print debug info

example("Nerver with do operator and debug info") {
    let disBag = DisposeBag()
    let observable = Observable<Void>.never()
    observable.do { (_) in
//        print("onNext")
    } afterNext: { (_) in
//        print("afterNext")
    } onError: { (error) in
//        print("onError: \(error.localizedDescription)")
    } afterError: { (error) in
//        print("afterError: \(error.localizedDescription)")
    } onCompleted: {
//        print("onCompleted")
    } afterCompleted: {
//        print("afterCompleted")
    } onSubscribe: {
//        print("onSubscribe")
    } onSubscribed: {
//        print("onSubscribed")
    } onDispose: {
//        print("onDispose")
    }
    .debug("Challenge 2")
    .subscribe()
    .disposed(by: disBag)
}
