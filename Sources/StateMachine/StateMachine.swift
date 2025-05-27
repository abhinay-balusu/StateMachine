//
//  StateMachine.swift
//  StateMachine
//
//  Created by Abhinay Balusu on 5/24/25.
//

import Foundation

/// Represents an error that can occur during state machine operations
public enum StateMachineError: Error, Sendable {
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
    
    /// Default history size for each log level
    public static func historySize(for level: StateMachineLogLevel) -> Int {
        switch level {
        case .none:
            return 0
        case .minimal:
            return 10
        case .standard, .verbose:
            return 100
        }
    }
    
    public init(
        logLevel: StateMachineLogLevel = .minimal,
        logHandler: ((String) -> Void)? = nil
    ) {
        self.logLevel = logLevel
        self.logHandler = logHandler
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
        
        // Initialize history if logging is enabled
        if loggingConfig.logLevel != .none {
            self.stateHistory = [initialState]
            log("Initial state: \(initialState)")
        }
    }

    /// Processes a transition and returns any effects that should be applied
    /// - Parameter transition: The transition to process
    /// - Returns: An array of effects that should be applied
    /// - Throws: StateMachineError if the transition is invalid
    public func process(_ transition: T) throws -> [T.Effect] {
        // Check if the transition is valid
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

        // Get the effects from the transition
        let effects = transition.process(from: currentState)
        
        if loggingConfig.logLevel != .none {
            log("\(currentState) → \(transition.state)")
        }
        
        if loggingConfig.logLevel == .verbose {
            log("Effects produced: \(effects.count)")
        }

        // Update state history if logging is enabled
        if var history = stateHistory {
            let maxSize = StateMachineLoggingConfig.historySize(for: loggingConfig.logLevel)
            if history.count >= maxSize {
                // Remove oldest state when at capacity
                history.removeFirst()
            }
            history.append(transition.state)
            stateHistory = history
        }

        // Always update the state for valid transitions
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
        stateHistory
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
}
