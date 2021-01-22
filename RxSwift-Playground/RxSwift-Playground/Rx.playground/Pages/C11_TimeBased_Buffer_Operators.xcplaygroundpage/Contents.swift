import RxSwift
import RxCocoa

let bufferTimeSpan: RxTimeInterval = .seconds(4)
let bufferMaxCount = 2
let sourceObservable = PublishSubject<String>()
let sourceTimeline = TimelineView<String>.make()
let bufferedTimeline = TimelineView<Int>.make()
let stack = UIStackView.makeVertical([
    UILabel.makeTitle("buffer"),
    UILabel.make("Emitted Elements:"),
    sourceTimeline,
    UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) secs):"),
    bufferedTimeline
])

_ = sourceObservable.subscribe(sourceTimeline)
sourceObservable
    .buffer(timeSpan: bufferTimeSpan,
            count: bufferMaxCount,
            scheduler: MainScheduler.instance)
    .map(\.count)
    .subscribe(bufferedTimeline)

//DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//    sourceObservable.onNext("🚗")
//    sourceObservable.onNext("🚗")
//    sourceObservable.onNext("🚗")
//}

let elementPerSecond = 0.7
let timer = DispatchSource.timer(interval: 1.0 / Double(elementPerSecond), queue: .main) {
    sourceObservable.onNext("🚗")
}

let hostView = setupHostView()
hostView.addSubview(stack)
hostView




















//Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
    static func make() -> TimelineView<E> {
        return TimelineView(width: 350, height: 100)
    }
    
    func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            add(.next(String(describing: value)))
        case .completed:
            add(.completed())
        case .error(_):
            add(.error())
        }
    }
}
