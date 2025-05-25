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
        let stateMachine = StateMachine<TestTransition>(initialState: .state1)
        XCTAssertEqual(stateMachine.getCurrentState(), .state1)
    }

    func testValidTransition() {
        let stateMachine = StateMachine<TestTransition>(initialState: .state1)
        let transition = TestTransition(state: .state2, effect: .effect1("test"))

        let effects = stateMachine.process(transition)
        XCTAssertEqual(effects.count, 1)
        XCTAssertEqual(stateMachine.getCurrentState(), .state2)
    }

    func testInvalidTransition() {
        let stateMachine = StateMachine<TestTransition>(initialState: .state1)
        let transition = TestTransition(state: .state3, effect: .effect1("test"))

        let effects = stateMachine.process(transition)
        XCTAssertEqual(effects.count, 0)
        XCTAssertEqual(stateMachine.getCurrentState(), .state1)
    }

    func testMultipleTransitions() {
        let stateMachine = StateMachine<TestTransition>(initialState: .state1)

        // First transition
        let transition1 = TestTransition(state: .state2, effect: .effect1("first"))
        let effects1 = stateMachine.process(transition1)
        XCTAssertEqual(effects1.count, 1)
        XCTAssertEqual(stateMachine.getCurrentState(), .state2)

        // Second transition
        let transition2 = TestTransition(state: .state3, effect: .effect2(42))
        let effects2 = stateMachine.process(transition2)
        XCTAssertEqual(effects2.count, 1)
        XCTAssertEqual(stateMachine.getCurrentState(), .state3)
    }
}
