//
//  StateMachine.swift
//  StateMachine
//
//  Created by Abhinay Balusu on 5/24/25.
//

import Foundation

/// Represents an error that can occur during state machine operations
public enum StateMachineError: Error {
    /// Attempted an invalid transition
    case invalidTransition(from: String, to: String)
}

/// Log levels for state machine logging
public enum StateMachineLogLevel {
    case none        // No logging or history
    case minimal     // Only state changes and basic history
    case standard    // State changes, validation, and full history
    case verbose     // All events including effects and full history
}

/// Configuration options for state machine logging
public struct StateMachineLoggingConfig {
    /// The level of logging detail
    public let logLevel: StateMachineLogLevel

    /// Custom log handler for state machine events
    public let logHandler: ((String) -> Void)?

    /// Configuration for state persistence
    public let persistenceConfig: StateMachinePersistenceConfig?

    /// Default history size for each log level
    public static func historySize(for level: StateMachineLogLevel) -> Int {
        switch level {
        case .none:
            return 0
        case .minimal, .standard, .verbose:
            return 100
        }
    }

    public init(
        logLevel: StateMachineLogLevel = .minimal,
        logHandler: ((String) -> Void)? = nil,
        persistenceConfig: StateMachinePersistenceConfig? = nil
    ) {
        self.logLevel = logLevel
        self.logHandler = logHandler
        self.persistenceConfig = persistenceConfig
    }
}

/// Protocol for types that can be persisted
public protocol StateMachinePersistable: Codable {
    /// Unique identifier for the state
    var persistenceKey: String { get }
}

/// Configuration for state persistence
public struct StateMachinePersistenceConfig {
    /// The UserDefaults suite to use for persistence
    public let defaults: UserDefaults

    /// The key prefix for persisted states
    public let keyPrefix: String

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "com.statemachine"
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }
}

/// A protocol that defines the requirements for a state transition in the state machine.
/// Types conforming to this protocol must specify:
/// - The type of state they manage
/// - The type of effects they can produce
/// - Logic for processing transitions
/// - Logic for validating transitions
public protocol TransitionType {
    /// The type representing the state in the state machine
    associatedtype State

    /// The type representing the effects that can be produced during transitions
    associatedtype Effect

    /// The target state for this transition
    var state: State { get }

    /// The effect associated with this transition
    var effect: Effect { get }

    /// Processes the transition from the current state and returns any effects
    /// - Parameter currentState: The current state before the transition
    /// - Returns: An array of effects that should be applied as a result of this transition
    func process(from currentState: State) -> [Effect]

    /// Validates whether this transition is allowed from the current state
    /// - Parameter currentState: The current state to validate the transition from
    /// - Returns: True if the transition is valid, false otherwise
    func isValid(from currentState: State) -> Bool
}

/// Protocol for types that can be visualized in a state machine diagram
public protocol StateMachineVisualizable {
    /// Returns a string representation of the state for visualization
    var visualName: String { get }
    
    /// Returns a color representation of the state (optional)
    var visualColor: String? { get }
}

/// Protocol for transitions that can be visualized
public protocol TransitionVisualizable {
    /// Returns a string representation of the transition for visualization
    var visualName: String { get }

    /// Returns a color representation of the transition (optional)
    var visualColor: String? { get }
}

/// Configuration for state machine visualization
public struct StateMachineVisualizationConfig {
    /// The format to generate the visualization in
    public enum Format {
        case mermaid
        case dot
        case plantUML
    }

    /// The visualization format
    public let format: Format

    /// Whether to include effects in the visualization
    public let includeEffects: Bool

    /// Whether to include state history in the visualization
    public let includeHistory: Bool

    public init(
        format: Format = .mermaid,
        includeEffects: Bool = true,
        includeHistory: Bool = true
    ) {
        self.format = format
        self.includeEffects = includeEffects
        self.includeHistory = includeHistory
    }
}

/// A generic state machine implementation that manages state transitions and effects.
/// The state machine ensures that only valid transitions are processed and maintains
/// the current state of the system.
///
/// Thread Safety:
/// - This state machine does not provide internal thread safety
/// - Clients are responsible for ensuring thread safety when accessing the state machine
/// - Consider using a serial queue or other synchronization mechanism when accessing the state machine
/// from multiple threads
public final class StateMachine<T: TransitionType> {
    /// The current state of the state machine
    private var currentState: T.State

    /// Logging configuration
    private let loggingConfig: StateMachineLoggingConfig

    /// Category of the state machine
    private let category: String

    /// Default log handler that prints to console
    private let defaultLogHandler: (String) -> Void = { print("[StateMachine] \($0)") }
    
    /// State history as an LRU cache
    private var stateHistory: [T.State]?

    /// Initializes a new state machine with the specified initial state and logging configuration
    /// - Parameters:
    ///   - initialState: The starting state for the state machine
    ///   - category: Category of the state machine
    ///   - loggingConfig: Configuration for state machine logging
    public init(
        initialState: T.State,
        category: String = "default",
        loggingConfig: StateMachineLoggingConfig = StateMachineLoggingConfig()
    ) {
        self.currentState = initialState
        self.category = category
        self.loggingConfig = loggingConfig

        if loggingConfig.logLevel != .none {
            stateHistory = [initialState]
            log("Initial state: \(initialState)")
        }
    }

    /// Processes a transition and returns any effects that should be applied
    /// - Parameter transition: The transition to process
    /// - Returns: An array of effects that should be applied
    /// - Throws: StateMachineError if the transition is invalid
    public func process(_ transition: T) throws -> [T.Effect] {
        let isValid = transition.isValid(from: currentState)

        if loggingConfig.logLevel == .standard || loggingConfig.logLevel == .verbose {
            log("Validating transition: \(currentState) → \(transition.state)")
        }

        guard isValid else {
            if loggingConfig.logLevel == .standard || loggingConfig.logLevel == .verbose {
                log("Invalid transition: \(currentState) → \(transition.state)")
            }
            throw StateMachineError.invalidTransition(
                from: String(describing: currentState),
                to: String(describing: transition.state)
            )
        }

        let effects = transition.process(from: currentState)

        if loggingConfig.logLevel != .none {
            log("\(currentState) → \(transition.state)")
        }

        if loggingConfig.logLevel == .verbose {
            log("Effects produced: \(effects.count)")
        }

        if loggingConfig.logLevel != .none {
            appendToHistory(transition.state)
        }

        currentState = transition.state
        return effects
    }

    /// Returns the current state of the state machine
    /// - Returns: The current state
    public func getCurrentState() -> T.State {
        currentState
    }

    /// Returns the state history if logging is enabled
    /// - Returns: Array of previous states, or nil if logging is disabled
    public func getStateHistory() -> [T.State]? {
        guard loggingConfig.logLevel != .none else { return nil }
        return stateHistory
    }

    /// Internal logging function that uses either the custom log handler or default
    private func log(_ message: String) {
        let formattedMessage = "[\(category)] \(message)"
        if let customHandler = loggingConfig.logHandler {
            customHandler(formattedMessage)
        } else {
            defaultLogHandler(formattedMessage)
        }
    }

    private func appendToHistory(_ state: T.State) {
        if var history = stateHistory {
            let maxSize = StateMachineLoggingConfig.historySize(for: loggingConfig.logLevel)
            if history.count >= maxSize {
                history.removeFirst()
            }
            history.append(state)
            stateHistory = history
        }
    }

    /// Generates a visualization of the state machine
    /// - Parameter config: The visualization configuration
    /// - Returns: A string containing the visualization in the specified format
    public func generateVisualization(config: StateMachineVisualizationConfig = StateMachineVisualizationConfig()) -> String {
        switch config.format {
        case .mermaid:
            return generateMermaidVisualization(config: config)
        case .dot:
            return generateDotVisualization(config: config)
        case .plantUML:
            return generatePlantUMLVisualization(config: config)
        }
    }

    private func generateMermaidVisualization(config: StateMachineVisualizationConfig) -> String {
        var diagram = "graph TD\n"

        // Add current state
        let currentState = String(describing: currentState)
        diagram += "    Current[\"Current: \(currentState)\"]\n"

        // Add state history if enabled
        if config.includeHistory, let history = stateHistory {
            diagram += "    subgraph History\n"
            for (index, state) in history.enumerated() {
                diagram += "        H\(index)[\"\(String(describing: state))\"]\n"
                if index > 0 {
                    diagram += "        H\(index-1) --> H\(index)\n"
                }
            }
            diagram += "    end\n"
        }

        return diagram
    }

    private func generateDotVisualization(config: StateMachineVisualizationConfig) -> String {
        var diagram = "digraph StateMachine {\n"

        // Add current state
        let currentState = String(describing: currentState)
        diagram += "    Current [label=\"Current: \(currentState)\"]\n"

        // Add state history if enabled
        if config.includeHistory, let history = stateHistory {
            diagram += "    subgraph cluster_history {\n"
            diagram += "        label=\"History\"\n"
            for (index, state) in history.enumerated() {
                diagram += "        H\(index) [label=\"\(String(describing: state))\"]\n"
                if index > 0 {
                    diagram += "        H\(index-1) -> H\(index)\n"
                }
            }
            diagram += "    }\n"
        }

        diagram += "}\n"
        return diagram
    }

    private func generatePlantUMLVisualization(config: StateMachineVisualizationConfig) -> String {
        var diagram = "@startuml\n"

        // Add current state
        let currentState = String(describing: currentState)
        diagram += "state \"Current: \(currentState)\" as Current\n"

        // Add state history if enabled
        if config.includeHistory, let history = stateHistory {
            diagram += "state \"History\" as History {\n"
            for (index, state) in history.enumerated() {
                diagram += "    state \"\(String(describing: state))\" as H\(index)\n"
                if index > 0 {
                    diagram += "    H\(index-1) --> H\(index)\n"
                }
            }
            diagram += "}\n"
        }

        diagram += "@enduml\n"
        return diagram
    }
}

/// A thread-safe wrapper for the state machine that ensures all operations are performed on a serial queue
@available(macOS 10.15, iOS 13.0, *)
public final class ThreadSafeStateMachine<T: TransitionType> {
    private let stateMachine: StateMachine<T>
    private let queue: DispatchQueue

    public init(
        initialState: T.State,
        category: String = "default",
        loggingConfig: StateMachineLoggingConfig = StateMachineLoggingConfig(),
        queue: DispatchQueue? = nil
    ) {
        self.stateMachine = StateMachine(
            initialState: initialState,
            category: category,
            loggingConfig: loggingConfig
        )
        self.queue = queue ?? DispatchQueue(
            label: "com.statemachine.\(category)",
            qos: .userInitiated
        )
    }

    public func process(_ transition: T) async throws -> [T.Effect] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let effects = try self.stateMachine.process(transition)
                    continuation.resume(returning: effects)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func getCurrentState() async -> T.State {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.stateMachine.getCurrentState())
            }
        }
    }

    public func getStateHistory() async -> [T.State]? {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.stateMachine.getStateHistory())
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, *)
extension StateMachine where T.State: StateMachinePersistable {
    /// Saves the current state to persistent storage
    public func persistState() throws {
        guard let config = loggingConfig.persistenceConfig else { return }
        let data = try JSONEncoder().encode(currentState)
        let key = "\(config.keyPrefix).\(currentState.persistenceKey)"
        config.defaults.set(data, forKey: key)
    }

    /// Loads the state from persistent storage
    public func loadPersistedState() throws {
        guard let config = loggingConfig.persistenceConfig else { return }
        let key = "\(config.keyPrefix).\(currentState.persistenceKey)"
        guard let data = config.defaults.data(forKey: key) else {
            return
        }
        currentState = try JSONDecoder().decode(T.State.self, from: data)
    }
}
