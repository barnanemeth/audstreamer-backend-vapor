//
//  AsyncOperation.swift
//
//
//  Created by Barna Nemeth on 31/05/2024.
//

import Foundation

open class AsyncOperation: Operation {

    // MARK: Constants

    @objc private enum OperationState: Int {
        case ready
        case executing
        case finished
        case suspended
    }

    // MARK: Private properties

    private let stateQueue = DispatchQueue(label: "com.barnanemeth.dev.asyncoperation", attributes: .concurrent)
    private var _state: OperationState = .ready
    private var preSuspendState: OperationState = .ready
    @objc private dynamic var state: OperationState {
        get { return stateQueue.sync { _state } }
        set { stateQueue.async(flags: .barrier) { self._state = newValue } }
    }

    // MARK: Properties

    open override var isReady: Bool { return state == .ready && super.isReady }
    public final override var isExecuting: Bool { state == .executing && state != .suspended }
    public final override var isFinished: Bool { state == .finished }
    public final override var isAsynchronous: Bool { true }
    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }

    // MARK: Public methods

    public final override func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .executing

        main()
    }

    open override func main() {}

    open func finish() {
        if !isFinished { state = .finished }
    }

    open func suspend() {
        guard !isFinished else { return }
        preSuspendState = state
        state = .suspended
    }

    open func resume() {
        guard !isFinished else { return }
        state = preSuspendState
    }
}
