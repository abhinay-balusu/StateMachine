@testable import StateMachine
import XCTest

final class StateMachineTests: XCTestCase {

    enum TestState {
        case state1
        case state2
        case state3
    }

    enum TestEffect {
        case effect1(String)
        case effect2(Int)
    }

    struct TestTransition: TransitionType {
        typealias State = TestState
        typealias Effect = TestEffect

        let state: TestState
        let effect: TestEffect

        func process(from currentState: TestState) -> [TestEffect] {
            return [effect]
        }

        func isValid(from currentState: TestState) -> Bool {
            switch (currentState, state) {
            case (.state1, .state2),
                 (.state2, .state3),
                 (.state3, .state1):
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Test Cases
    func testInitialState() {
        let stateMachine = StateMachine<TestTransition>(
            initialState: .state1,
            loggingConfig: StateMachineLoggingConfig(logLevel: .none)
        )
        XCTAssertEqual(stateMachine.getCurrentState(), .state1)
        XCTAssertNil(stateMachine.getStateHistory())
    }

    func testValidTransition() {
        let stateMachine = StateMachine<TestTransition>(
            initialState: .state1,
            loggingConfig: StateMachineLoggingConfig(logLevel: .minimal)
        )
        let transition = TestTransition(state: .state2, effect: .effect1("test"))

        let effects = try! stateMachine.process(transition)
        XCTAssertEqual(effects.count, 1)
        XCTAssertEqual(stateMachine.getCurrentState(), .state2)
        
        let history = stateMachine.getStateHistory()
        XCTAssertNotNil(history)
        XCTAssertEqual(history?.count, 2)
        XCTAssertEqual(history?[0], .state1)
        XCTAssertEqual(history?[1], .state2)
    }

    func testInvalidTransition() {
        let stateMachine = StateMachine<TestTransition>(initialState: .state1)
        let transition = TestTransition(state: .state3, effect: .effect1("test"))

        do {
            _ = try stateMachine.process(transition)
            XCTFail("Expected invalid transition error")
        } catch {
            if case let .invalidTransition(from, to) = error as? StateMachineError {
                XCTAssertEqual(from, "state1")
                XCTAssertEqual(to, "state3")
            } else {
                XCTFail("Expected StateMachineError.invalidTransition")
            }
        }
        XCTAssertEqual(stateMachine.getCurrentState(), .state1)
    }

    func testMultipleTransitions() {
        let stateMachine = StateMachine<TestTransition>(
            initialState: .state1,
            loggingConfig: StateMachineLoggingConfig(logLevel: .standard)
        )

        let transition1 = TestTransition(state: .state2, effect: .effect1("first"))
        let effects1 = try! stateMachine.process(transition1)
        XCTAssertEqual(effects1.count, 1)
        XCTAssertEqual(stateMachine.getCurrentState(), .state2)

        let transition2 = TestTransition(state: .state3, effect: .effect2(42))
        let effects2 = try! stateMachine.process(transition2)
        XCTAssertEqual(effects2.count, 1)
        XCTAssertEqual(stateMachine.getCurrentState(), .state3)
        
        let history = stateMachine.getStateHistory()
        XCTAssertNotNil(history)
        XCTAssertEqual(history?.count, 3)
        XCTAssertEqual(history?[0], .state1)
        XCTAssertEqual(history?[1], .state2)
        XCTAssertEqual(history?[2], .state3)
    }
    
    func testHistorySizeLimit() {
        let stateMachine = StateMachine<TestTransition>(
            initialState: .state1,
            loggingConfig: StateMachineLoggingConfig(logLevel: .minimal)
        )
        
        let validTransitions: [TestState] = [.state2, .state3, .state1, .state2, .state3, .state1, .state2, .state3, .state1, .state2]
        
        for (index, nextState) in validTransitions.enumerated() {
            let transition = TestTransition(state: nextState, effect: .effect1("transition \(index + 1)"))
            _ = try! stateMachine.process(transition)
        }
        
        let history = stateMachine.getStateHistory()
        XCTAssertNotNil(history)
        XCTAssertEqual(history?.count, 10)
        XCTAssertEqual(stateMachine.getCurrentState(), .state2)
    }
    
    func testNoHistoryWhenLoggingDisabled() {
        let stateMachine = StateMachine<TestTransition>(
            initialState: .state1,
            loggingConfig: StateMachineLoggingConfig(logLevel: .none)
        )
        
        let transition = TestTransition(state: .state2, effect: .effect1("test"))
        _ = try! stateMachine.process(transition)
        
        XCTAssertNil(stateMachine.getStateHistory())
    }
    
    func testCustomLogHandler() {
        var loggedMessages: [String] = []
        let logHandler: (String) -> Void = { loggedMessages.append($0) }
        
        let stateMachine = StateMachine<TestTransition>(
            initialState: .state1,
            loggingConfig: StateMachineLoggingConfig(
                logLevel: .verbose,
                logHandler: logHandler
            )
        )
        
        let transition = TestTransition(state: .state2, effect: .effect1("test"))
        _ = try! stateMachine.process(transition)
        
        XCTAssertFalse(loggedMessages.isEmpty)
        XCTAssertTrue(loggedMessages.contains { $0.contains("state1") && $0.contains("state2") })
    }
}
