import RxSwift
import RxCocoa
import Foundation

//MARK: - toArray

example("toArray") {
    //Note: For old document using onNext to get elements in toArray. But in new version RxSwift, when observable onCompleted, toArray will emit elements.
    let disposeBag = DisposeBag()
    
    Observable.of("A", "B", "C")
        .toArray()
        .subscribe { (elements) in
            print(elements)
        }
        .disposed(by: disposeBag)
}

//MARK: - Map

example("map") {
    let dis = DisposeBag()
    
    let formatNum = NumberFormatter()
    formatNum.numberStyle = .spellOut
    
    Observable.of(123, 4, 55)
        .map({ formatNum.string(for: $0) ?? "" })
        .subscribe { (ele) in
            print(ele)
        }
        .disposed(by: dis)
}

//MARK: - enumerated and map

example("enumerated and map") {
    let dis = DisposeBag()
    Observable.of(1, 2, 3, 4, 5, 6)
        .enumerated()
        .map({
            $0 > 2 ? $1 * 2 : $1
        })
        .subscribe { (ele) in
            print(ele)
        }
        .disposed(by: dis)
}

//MARK: - flatMap

struct Student {
    let score: BehaviorSubject<Int>
}

example("flatMap") {
    let dis = DisposeBag()
    let laura = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 90))
    let student = PublishSubject<Student>()
    student
        .flatMap({
            $0.score
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: dis)
    
    student.onNext(laura)
    laura.score.onNext(85)
    
    student.onNext(charlotte)
    charlotte.score.onNext(95)
    
    charlotte.score.onNext(100)
}

//MARK: - flatMapLatest

example("flatMapLatest") {
    let dis = DisposeBag()
    let laura = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 90))
    let student = PublishSubject<Student>()
    student
        .flatMapLatest({
            $0.score
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: dis)
    
    student.onNext(laura)
    laura.score.onNext(85)
    
    student.onNext(charlotte)
    laura.score.onNext(95)
    charlotte.score.onNext(100)
}

//MARK: - materialize and dematerialize

example("materialize and dematerialize") {
    enum MyError: Error {
        case anError
    }
    
    let dis = DisposeBag()
    let laura = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 100))
    let student = BehaviorSubject(value: laura)
    
    let studentScore = student.flatMapLatest({ $0.score.materialize() })
    studentScore
        .filter({
            guard $0.error == nil else {
                print($0.error!)
                return false
            }
            
            return true
        })
        .dematerialize()
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: dis)
    
    laura.score.onNext(85)
    laura.score.onError(MyError.anError)
    laura.score.onNext(90)
    
    student.onNext(charlotte)
    charlotte.score.onNext(190)
}
