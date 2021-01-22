import Foundation
import RxSwift
import RxCocoa

//MARK: - startWith

example("startWith") {
    let number = Observable.of(2, 3, 4)
    let observable = number.startWith(1)
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - Observable.concat

example("Observable.concat") {
    let first = Observable.of(1, 2, 3)
    let second = Observable.of(4, 5, 6)
    
    let observable = Observable.concat([first, second])
    observable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - concat

example("concat") {
    let germanCities = Observable.of("Berlin", "Munich", "Frankfurt")
    let spanishCities = Observable.of("Madrid", "Barcelone", "Valentica")
    
    let observable = germanCities.concat(spanishCities)
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - concatMap

example("concatMap") {
    let sequences = [
        "German cities": Observable.of("Berlin", "Munich", "Frankfurt"),
        "Spanish cities": Observable.of("Madrid", "Barcelone", "Valentica")
    ]
    
    let observable = Observable.of("German cities", "Spanish cities")
        .concatMap({ sequences[$0] ?? .empty() })
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - merge

example("merge") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let source = Observable.of(left.asObserver(), right.asObserver())
    let observable = source.merge()
    let _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    var leftValue = ["Berlin", "Munich", "Frankfurt"]
    var rightValue = ["Madrid", "Barcelona", "Valencia"]
    repeat {
        switch Bool.random() {
        case true where !leftValue.isEmpty:
            left.onNext("Left: " + leftValue.removeFirst())
        case false where !rightValue.isEmpty:
            right.onNext("Right: " + rightValue.removeFirst())
        default:
            break
        }
    } while !leftValue.isEmpty || !rightValue.isEmpty
    
    left.onCompleted()
    right.onCompleted()
}

//MARK: combineLatest

example("combineLatest") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let observable = Observable.combineLatest(left, right) {
        (lastLeft, lastRight) in
        "\(lastLeft) \(lastRight)"
    }
    
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    print("> Sending a value to Left")
    left.onNext("Hello,")
    print("> Sending a value to Right")
    right.onNext("world")
    print("> Sending another value to Right")
    right.onNext("RxSwift")
    print("> Sending another value to Left")
    left.onNext("Have a good day,")
    
    left.onCompleted()
    right.onCompleted()
}

example("combine user choice and value") {
    let choice: Observable<DateFormatter.Style> = Observable.of(.short, .long)
    let date = Observable.of(Date())
    
    let observable = Observable.combineLatest(choice, date) {
        format, when -> String in
        let formatter = DateFormatter()
        formatter.dateStyle = format
        return formatter.string(from: when)
    }
    
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - Zip

example("Zip") {
    enum Weather {
        case cloudy
        case sunny
    }
    
    let left: Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
    let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")
    let observable = Observable.zip(left, right) { (l, r) -> String in
        return "It's \(l) in \(r)"
    }
    
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - withLatestFrom

example("withLatestFrom") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
    let observable = button.withLatestFrom(textField)
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(())
    button.onNext(())
}

example("sample") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
    let observable = textField.sample(button)
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(())
    button.onNext(())
}

//MARK: - amb

example("amb") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let observable = left.amb(right)
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    right.onNext("Copenhagen")
    left.onNext("Lisbon")
    left.onNext("London")
    left.onNext("Madrid")
    right.onNext("Vienma")
    
    left.onCompleted()
    right.onCompleted()
}

//MARK: - switchLatest

example("switchLatest") {
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()
    
    let source = PublishSubject<Observable<String>>()
    
    let observable = source.switchLatest()
    let disposable = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    source.onNext(one)
    one.onNext("Some text from sequence one")
    two.onNext("Some text from sequence two")
    
    source.onNext(two)
    two.onNext("More text from sequence two")
    one.onNext("and also from sequence one")
    
    source.onNext(three)
    two.onNext("Why don't you see me?")
    one.onNext("I'm alone, help me")
    three.onNext("Hey it's three. I win.")
    
    source.onNext(one)
    one.onNext("Nope. It's me, one!")
    
    disposable.dispose()
}

//MARK: - reduce

example("reduce") {
    let source = Observable.of(1, 3, 5, 7, 9)
    
    let observable = source.reduce(0, accumulator: {
        sum, value in
        return sum + value
    })
    
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
}

//MARK: - scan

example("scan") {
    let source = Observable.of(1, 3, 5, 7, 9)
    
    let observable = source.scan(5, accumulator: { $0 + $1 })
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
}
