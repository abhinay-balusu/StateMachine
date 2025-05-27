import Foundation
import StateMachine

/// A playground demonstrating the use of the StateMachine package with a traffic light example.
/// This example shows how to:
/// - Define states and effects for a state machine
/// - Implement valid state transitions
/// - Process transitions and handle their effects
/// - Handle invalid transitions gracefully
/// - Visualize the state machine

/// Represents the possible states of a traffic light
enum TrafficLightState: StateMachineVisualizable {
    case red
    case yellow
    case green
    
    var visualName: String {
        switch self {
        case .red: return "Red Light"
        case .yellow: return "Yellow Light"
        case .green: return "Green Light"
        }
    }
    
    var visualColor: String? {
        switch self {
        case .red: return "#FF0000"
        case .yellow: return "#FFFF00"
        case .green: return "#00FF00"
        }
    }
}

/// Represents the effects that can occur during traffic light transitions
enum TrafficLightEffect {
    case printTransition(String)
}

/// Implements the traffic light state machine using the TransitionType protocol
struct TrafficLightTransition: TransitionType, TransitionVisualizable {
    typealias State = TrafficLightState
    typealias Effect = TrafficLightEffect
    
    let state: TrafficLightState
    let effect: TrafficLightEffect
    
    var visualName: String {
        switch state {
        case .red: return "Stop → Go"
        case .yellow: return "Caution"
        case .green: return "Go → Stop"
        }
    }
    
    var visualColor: String? {
        switch state {
        case .red: return "#FF0000"
        case .yellow: return "#FFFF00"
        case .green: return "#00FF00"
        }
    }
    
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
let stateMachine = StateMachine<TrafficLightTransition>(
    initialState: .red,
    loggingConfig: StateMachineLoggingConfig(logLevel: .standard)
)

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

// Generate and print visualizations in different formats
print("\nMermaid Visualization:")
print(stateMachine.generateVisualization(config: StateMachineVisualizationConfig(format: .mermaid)))

print("\nDOT Visualization:")
print(stateMachine.generateVisualization(config: StateMachineVisualizationConfig(format: .dot)))

print("\nPlantUML Visualization:")
print(stateMachine.generateVisualization(config: StateMachineVisualizationConfig(format: .plantUML)))

// Generate visualization without history
print("\nMermaid Visualization (without history):")
print(stateMachine.generateVisualization(config: StateMachineVisualizationConfig(
    format: .mermaid,
    includeHistory: false
)))

