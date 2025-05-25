# StateMachine

A lightweight, type-safe state machine implementation in Swift. This package provides a generic state machine that can be used to model any system with discrete states and transitions.

## Features

- Type-safe state and effect handling
- Generic implementation that works with any state type
- Support for transition validation
- Effect processing during state transitions
- Thread-safe state management

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
enum MyState {
    case idle
    case processing
    case completed
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
let stateMachine = StateMachine<MyTransition>(initialState: .idle)
```

#### Basic Example State Machine

```
    [Start]
       |
       v
    +-------+
    | Idle  |----->[Process]----+
    +-------+                    |
                                v
                           +-------------+
                           | Processing  |
                           +-------------+
                                |
                                | [Finish]
                                v
                           +------------+
                           | Completed  |
                           +------------+
                                |
                                | [Reset]
                                v
                           +-------+
                           | Idle  |
                           +-------+
```

### Traffic Light Example

The package includes a traffic light example that demonstrates a practical use case:

```swift
enum TrafficLightState {
    case red
    case yellow
    case green
}

enum TrafficLightEffect {
    case printTransition(String)
}

struct TrafficLightTransition: TransitionType {
    // ... implementation details ...
}
```

#### Traffic Light State Machine

```
    [Stop]
       |
       v
    +-------+
    |  Red  |----->[Go]----+
    +-------+              |
                          v
                     +---------+
                     |  Green  |
                     +---------+
                          |
                          | [Caution]
                          v
                     +---------+
                     | Yellow  |
                     +---------+
                          |
                          | [Stop]
                          v
                     +-------+
                     |  Red  |
                     +-------+
```

## Testing

The package includes comprehensive unit tests that verify:
- Initial state setting
- Valid transitions
- Invalid transitions
- Effect processing
- Multiple transitions in sequence

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