# StateMachine

A lightweight, type-safe state machine implementation in Swift. This package provides a generic state machine that can be used to model any system with discrete states and transitions.

## Features

- Type-safe state and effect handling
- Generic implementation that works with any state type
- Support for transition validation
- Effect processing during state transitions
- Thread-safe state management with `ThreadSafeStateMachine`
- State persistence with `StateMachinePersistable`
- Comprehensive logging and debugging support
- State history tracking
- Custom log handlers

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/StateMachine.git", from: "1.0.0")
]
```

## Usage

### Basic Example

```swift
// Define your states
enum MyState: StateMachinePersistable {
    case idle
    case processing
    case completed
    
    var persistenceKey: String {
        switch self {
        case .idle: return "idle"
        case .processing: return "processing"
        case .completed: return "completed"
        }
    }
}

// Define your effects
enum MyEffect {
    case log(String)
}

// Create a transition type
struct MyTransition: TransitionType {
    typealias State = MyState
    typealias Effect = MyEffect
    
    let state: MyState
    let effect: MyEffect
    
    func process(from currentState: MyState) -> [MyEffect] {
        return [effect]
    }
    
    func isValid(from currentState: MyState) -> Bool {
        // Define your transition rules here
        return true
    }
}

// Create and use the state machine
let stateMachine = ThreadSafeStateMachine<MyTransition>(initialState: .idle)

// Process transitions
Task {
    let effects = try await stateMachine.process(MyTransition(
        state: .processing,
        effect: .log("Starting processing")
    ))
    
    // Handle effects
    for effect in effects {
        if case .log(let message) = effect {
            print(message)
        }
    }
}
```

### Thread Safety

The package provides two implementations:

1. `StateMachine`: Basic implementation without thread safety
2. `ThreadSafeStateMachine`: Thread-safe wrapper using a serial queue

```swift
// Thread-safe usage
let stateMachine = ThreadSafeStateMachine<MyTransition>(
    initialState: .idle,
    category: "myStateMachine"
)

// All operations are automatically queued
Task {
    let state = await stateMachine.getCurrentState()
    let effects = try await stateMachine.process(transition)
}
```

### State Persistence

States can be persisted using the `StateMachinePersistable` protocol:

```swift
enum MyState: StateMachinePersistable {
    case idle
    case processing
    case completed
    
    var persistenceKey: String {
        switch self {
        case .idle: return "idle"
        case .processing: return "processing"
        case .completed: return "completed"
        }
    }
}

// Configure persistence
let stateMachine = StateMachine<MyTransition>(
    initialState: .idle,
    loggingConfig: StateMachineLoggingConfig(
        logLevel: .standard,
        persistenceConfig: StateMachinePersistenceConfig()
    )
)

// Save state
try stateMachine.persistState()

// Load state
try stateMachine.loadPersistedState()
```

### Logging and Debugging

The state machine provides comprehensive logging support:

```swift
let stateMachine = StateMachine<MyTransition>(
    initialState: .idle,
    loggingConfig: StateMachineLoggingConfig(
        logLevel: .verbose,
        logHandler: { message in
            // Custom logging
            print("[Custom] \(message)")
        }
    )
)
```

## Testing

The package includes comprehensive unit tests that verify:
- Initial state setting
- Valid transitions
- Invalid transitions
- Effect processing
- Multiple transitions in sequence
- Thread safety
- State persistence
- Logging functionality

Run the tests using:
```bash
swift test
```

## Requirements

- Swift 5.9+
- iOS 13.0+ / macOS 10.15+

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Roadmap

- [ ] Add state machine visualization tools
- [ ] Add support for state transition hooks/callbacks
- [ ] Add performance benchmarks
- [ ] Add more real-world examples
- [ ] Add state machine debugging tools