import RxSwift
import RxCocoa

let elementPerSecond = 3
let windowTimeSpan: RxTimeInterval = .seconds(4)
let windowMaxCount = 10
let sourceObservable = PublishSubject<String>()
let sourceTimeline = TimelineView<String>.make()
let stack = UIStackView.makeVertical([
    UILabel.makeTitle("window"),
    UILabel.make("Emitted elements (\(elementPerSecond) per sec.):"),
    sourceTimeline,
    UILabel.make("Windowed observable (at most \(windowMaxCount) every \(windowTimeSpan) sec):")
])

let timer = DispatchSource.timer(interval: 1.0 / Double(elementPerSecond), queue: .main) {
    sourceObservable.onNext("🚗")
}

_ = sourceObservable.subscribe(sourceTimeline)
_ = sourceObservable
    .window(timeSpan: windowTimeSpan,
            count: windowMaxCount,
            scheduler: MainScheduler.instance)
    .flatMap({
        windowObs -> Observable<(TimelineView<Int>, String?)> in
        let timeline = TimelineView<Int>.make()
        stack.insert(timeline, at: 4)
        stack.keep(atMost: 8)
        return windowObs
            .map { value in (timeline, value) }
            .concat(Observable.just((timeline, nil)))
    })
    .subscribe(onNext: { tuple in
        let (timeline, value) = tuple
        if let value = value {
            timeline.add(.next(value))
        } else {
            timeline.add(.completed(true))
        }
    })

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
