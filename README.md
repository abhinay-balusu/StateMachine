# StateMachine

A Swift package that provides a robust and flexible state machine implementation with support for state transitions, effects, logging, persistence, and visualization.

## Features

- **State Management**: Define and manage states with type-safe transitions
- **Effect Handling**: Process side effects during state transitions
- **Validation**: Ensure only valid state transitions are allowed
- **Logging**: Configurable logging levels and custom log handlers
- **Persistence**: Save and restore state machine state
- **Thread Safety**: Thread-safe operations with async/await support
- **Visualization**: Generate state machine diagrams in multiple formats (Mermaid, DOT, PlantUML)

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/abhinay-balusu/StateMachine.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. File > Add Packages...
2. Enter the repository URL
3. Select the version rule
4. Click Add Package

## Usage

### Basic Usage

```swift
// Define your states
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

// Define your effects
enum TrafficLightEffect {
    case printTransition(String)
}

// Implement your transition type
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
    
    func process(from currentState: TrafficLightState) -> [TrafficLightEffect] {
        let transitionMessage = "Transitioning from \(currentState) to \(state)"
        return [.printTransition(transitionMessage)]
    }
    
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

// Create and use the state machine
let stateMachine = StateMachine<TrafficLightTransition>(
    initialState: .red,
    loggingConfig: StateMachineLoggingConfig(logLevel: .standard)
)

// Process transitions
let transition = TrafficLightTransition(state: .green, effect: .printTransition(""))
let effects = try stateMachine.process(transition)
```

### Thread Safety

For thread-safe operations, use the `ThreadSafeStateMachine` class:

```swift
let threadSafeMachine = ThreadSafeStateMachine<TrafficLightTransition>(
    initialState: .red
)

// Use async/await for thread-safe operations
let effects = try await threadSafeMachine.process(transition)
let currentState = await threadSafeMachine.getCurrentState()
```

### State Persistence

To persist state machine state:

```swift
// Make your state conform to StateMachinePersistable
extension TrafficLightState: StateMachinePersistable {
    var persistenceKey: String { "trafficLight" }
}

// Configure persistence
let config = StateMachineLoggingConfig(
    logLevel: .standard,
    persistenceConfig: StateMachinePersistenceConfig()
)

// Save and load state
try stateMachine.persistState()
try stateMachine.loadPersistedState()
```

### Visualization

Generate state machine diagrams in multiple formats:

```swift
// Generate Mermaid diagram
let mermaidDiagram = stateMachine.generateVisualization(
    config: StateMachineVisualizationConfig(format: .mermaid)
)

// Generate DOT diagram
let dotDiagram = stateMachine.generateVisualization(
    config: StateMachineVisualizationConfig(format: .dot)
)

// Generate PlantUML diagram
let plantUMLDiagram = stateMachine.generateVisualization(
    config: StateMachineVisualizationConfig(format: .plantUML)
)

// Customize visualization
let customConfig = StateMachineVisualizationConfig(
    format: .mermaid,
    includeEffects: false,
    includeHistory: true
)
let customDiagram = stateMachine.generateVisualization(config: customConfig)
```

You can visualize these diagrams using:
- [Mermaid Live Editor](https://mermaid.live)
- [Graphviz Online](https://dreampuf.github.io/GraphvizOnline/)
- [PlantUML Online Server](http://www.plantuml.com/plantuml/uml/)

## Example

Check out the `TrafficLight.playground` for a complete example of a traffic light state machine with visualization support.

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.5+
- Xcode 13.0+

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.