//
//  StateMachine.swift
//  StateMachine
//
//  Created by Abhinay Balusu on 5/24/25.
//

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
public final class StateMachine<T: TransitionType> {
    /// The current state of the state machine
    private var currentState: T.State

    /// Initializes a new state machine with the specified initial state
    /// - Parameter initialState: The starting state for the state machine
    public init(initialState: T.State) {
        self.currentState = initialState
    }

    /// Processes a transition and returns any effects that should be applied
    /// - Parameter transition: The transition to process
    /// - Returns: An array of effects that should be applied, or an empty array if the transition is invalid
    public func process(_ transition: T) -> [T.Effect] {
        // Check if the transition is valid
        guard transition.isValid(from: currentState) else {
            return []
        }

        // Get the effects from the transition
        let effects = transition.process(from: currentState)
        currentState = transition.state
        return effects
    }

    /// Returns the current state of the state machine
    /// - Returns: The current state
    public func getCurrentState() -> T.State {
        return currentState
    }
}
