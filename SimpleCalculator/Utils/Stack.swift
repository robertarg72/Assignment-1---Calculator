/*
 * Stack.swift
 * Project: SimpleCalculator
 * Name: Robert Argume
 * StudentID: 300949529
 * Date: Sep 26, 2017
 * Description:
 * Implementation of a Stack Structure based on linked lists
 * For storing operands and operations as strings
 * Also to decide wheather to execute or delay an operation
 * Adapted and extended from YouTube Tutorial "Swift Interview Algorithms: Stacks and Generics", by Brian Voong
 */
import Foundation

// Node.class
// This is the basic structure to implement a list as the base structure for the Stack
class Node {
    let value: String
    var next: Node?
    init(_ value: String){
        self.value = value
    }
}

// Stack.class
// This is the Stack implementation based on Node class
// It creates a list to manage the elements added to the Stack
// It stores strings. Only methods needed in the project were implemented
class Stack {
    var top: Node?
    
    func push(_ value: String){
        let newNode = Node(value)
        let oldTop = top
        top = newNode
        top?.next = oldTop
    }
    
    func pop() -> String? {
        let onTop: Node?
        onTop = top
        top = top?.next
        return onTop?.value
    }
    
    func peak() -> String? {
        return top?.value
    }
    
    func isEmpty() -> Bool {
        return top == nil
    }
    
    func flush() {
        top = nil
    }
}
