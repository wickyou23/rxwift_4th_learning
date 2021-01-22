import Foundation
import RxSwift

enum MyError: Error {
    case anError
}

//MARK: - just, of, from

example("just, of, from") {
    let one = 1
    let two = 2
    let three = 3

    let observable = Observable<Int>.just(one)

    let observable2 = Observable.of(one, two, three)

    let observable3 = Observable.of([one, two, three])

    let observable4 = Observable.from([one, two, three])
}

//MARK: - Subscribe

example("Subscribe") {
    let one = 1
    let two = 2
    let three = 3

    let observable = Observable.of(one, two, three)
//    observable.subscribe { (event) in
//        if let element = event.element {
//            print(element)
//        }
//    }

    observable.subscribe { (element) in
        print(element)
    } onError: { (error) in
        print(error.localizedDescription)
    } onCompleted: {
        print("Emit completed")
    } onDisposed: {
        print("Terminated")
    }
}

//MARK: - Empty

example("Empty") {
    let observable = Observable<Void>.empty()
    observable.subscribe { (element) in
        print(element)
    } onError: { (error) in
        print(error.localizedDescription)
    } onCompleted: {
        print("Emit completed")
    } onDisposed: {
        print("Terminated")
    }
}

//MARK: - Nerver

example("Nerver") {
    let observable = Observable<Void>.never()
    observable.subscribe { (element) in
        print(element)
    } onError: { (error) in
        print(error.localizedDescription)
    } onCompleted: {
        print("Emit completed")
    } onDisposed: {
        print("Terminated")
    }
}

//MARK: - Range

example("Range") {
    let observable = Observable<Int>.range(start: 1, count: 10)
    observable.subscribe { (element) in
        let n = Double(element)
        let fib = Int(((pow(1.61803, n) - pow(0.61803, n)) / 2.23606).rounded())
        print(fib)
    } onError: { (error) in
        print(error.localizedDescription)
    } onCompleted: {
        print("Emit completed")
    } onDisposed: {
        print("Terminated")
    }
}

//MARK: - Dispose

example("Dispose") {
    let observable = Observable.of("A", "B", "C")
    let subscription = observable.subscribe { (event) in
        Thread.sleep(forTimeInterval: 1)
        print(event)
    }

    subscription.dispose()
}

//MARK: - DisposeBag

example("DisposeBag") {
    let bag = DisposeBag()
    let observable = Observable.of("A", "B", "C")
    observable.subscribe { (event) in
        print(event)
    }.disposed(by: bag)
}

//MARK: - Create

example("Create") {
    let disposeBag = DisposeBag()
    let observable = Observable<String>.create { (observer) -> Disposable in
        observer.onNext("1")

        observer.onError(MyError.anError)

        observer.onCompleted()

        observer.onNext("?")

        return Disposables.create()
    }

    observable.subscribe { (element) in
        print(element)
    } onError: { (error) in
        print(error)
    } onCompleted: {
        print("Emit completed")
    } onDisposed: {
        print("Terminated")
    }
    .disposed(by: disposeBag)
}

//MARK: - Deferred

example("Deferred") {
    let disBag = DisposeBag()
    var flip = false
    let factory: Observable<Int> = Observable.deferred {
        flip.toggle()
        if flip {
            return Observable<Int>.of(1, 2, 3)
        }
        else {
            return Observable<Int>.of(4, 5, 6)
        }
    }

    for _ in 0...3 {
        factory.subscribe { (element) in
            print(element)
        }.disposed(by: disBag)
    }
}

//MARK: - Single

example("Single") {
    let disBag = DisposeBag()

    enum FileReadError: Error {
        case fileNotFound, unreadable, endcodingFailed
    }

    func loadText(fileName: String) -> Single<String> {
        return Single.create { (single) -> Disposable in
            let dis = Disposables.create()
            guard let path = Bundle.main.path(forResource: fileName, ofType: "txt") else {
                single(.error(FileReadError.fileNotFound))
                return dis
            }

            guard let data = FileManager.default.contents(atPath: path) else {
                single(.error(FileReadError.unreadable))
                return dis
            }

            guard let txt = String(data: data, encoding: .utf8) else {
                single(.error(FileReadError.endcodingFailed))
                return dis
            }

            single(.success(txt))
            return dis
        }
    }

    loadText(fileName: "Copyright")
        .subscribe(onSuccess: { (txt) in
            print(txt)
        }, onError: { (error) in
            print(error)
        })
        .disposed(by: disBag)
}
