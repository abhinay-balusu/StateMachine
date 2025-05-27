import Foundation
import StateMachine

/// A playground demonstrating the use of the StateMachine package with a traffic light example.
/// This example shows how to:
/// - Define states and effects for a state machine
/// - Implement valid state transitions
/// - Process transitions and handle their effects
/// - Handle invalid transitions gracefully

/// Represents the possible states of a traffic light
enum TrafficLightState {
    case red
    case yellow
    case green
}

/// Represents the effects that can occur during traffic light transitions
enum TrafficLightEffect {
    case printTransition(String)
}

/// Implements the traffic light state machine using the TransitionType protocol
struct TrafficLightTransition: TransitionType {
    typealias State = TrafficLightState
    typealias Effect = TrafficLightEffect
    
    let state: TrafficLightState
    let effect: TrafficLightEffect
    
    /// Processes the transition and returns a message describing the state change
    func process(from currentState: TrafficLightState) -> [TrafficLightEffect] {
        let transitionMessage = "Transitioning from \(currentState) to \(state)"
        return [.printTransition(transitionMessage)]
    }
    
    /// Validates traffic light transitions according to standard rules:
    /// - Red can only transition to Green
    /// - Green can only transition to Yellow
    /// - Yellow can only transition to Red
    func isValid(from currentState: TrafficLightState) -> Bool {
        switch (currentState, state) {
        case (.red, .green),
             (.green, .yellow),
             (.yellow, .red):
            return true
        default:
            return false
        }
    }
}

// Create an instance of the state machine starting with a red light
let stateMachine = StateMachine<TrafficLightTransition>(initialState: .red)

/// Helper function to process state transitions and print their effects
@MainActor func processTransition(to newState: TrafficLightState) {
    let transition = TrafficLightTransition(state: newState, effect: .printTransition(""))
    let effects = try? stateMachine.process(transition)
    
    for effect in effects ?? [] {
        if case .printTransition(let message) = effect {
            print(message)
        }
    }
}

// Test the traffic light state machine
print("Initial state: \(stateMachine.getCurrentState())")

// Demonstrate valid transitions
processTransition(to: .green)  // Red -> Green
processTransition(to: .yellow) // Green -> Yellow
processTransition(to: .red)    // Yellow -> Red

// Demonstrate invalid transition handling
processTransition(to: .green)  // Red -> Green (valid)
processTransition(to: .red)    // Green -> Red (invalid, should not print)

