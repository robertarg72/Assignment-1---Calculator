/*
 * ViewController.swift
 * Project: SimpleCalculator
 * Name: Robert Argume
 * StudentID: 300949529
 * Description: Simple Calculator App developded for Assignment 1
 * Version: 0.5 - Added logic to update display each time a numeric button is pushed
 * Notes:
 *   - UI design/development using iPhone SE, then scaled up to larger screens
 *   - Some constraints warning are shown in the storyboard, but the simulator renders the App correctly
 */

import UIKit

class ViewController: UIViewController {
    
    // GLOBAL VARIABLES
    // =========================================================================
    
    // Showing numbers in the display will use a state machine logic
    enum State {
        case Initial
        case IntegerPart
        case FractionalPart
        case OperationInProgress
    }
    var inputState: State = .Initial
    
    // All chars used to form a number are categorized in 3 types to work with the state machine
    enum InputType {
        case Zero
        case DigitOnetoNine
        case Dot
        case Equal
        case Addition
        case Substraction
        case Multiplication
        case Division
        case Percentage
        case ChangeSign
        case Clear
    }
    
    // Stack for managing priorities and execution of operations
    let operationStack: Stack = Stack()
    
    // Precedence of operators
    // The greater the value the more priority the operatior has
    enum Precendence: Int{
        case None = 0
        case Addition           //Includes Substraction
        case Multplication      //Includes Division and Module
        case Exponent           //Includes Root
        case Unary              //Like +/- or %
        case Parentheses
        case Functions
        case SpecialConstants   //Like e, PI, G, etc
    }
    
    // Various constante values to be used in the logic
    let dotCharAscii = 46
    let displayMaxLengthPortrait = 10
    let initialStringOnDisplay = "0"
    let errorMessage = "Error"

    
    // OUTLETS
    // =========================================================================
    
    // Connects to the text label control in the storyboard to show the input number
    @IBOutlet weak var displayText: UILabel!
    
    
    // OVERRIDEN METHODS
    // =========================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        displayText.text = initialStringOnDisplay
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // ACTIONS
    // =========================================================================
    
    // Run logic based on a stack to prioritize execution of binary operations
    @IBAction func binaryOperationButtonPushed(_ sender: UIButton) {
        inputState = .OperationInProgress
        let currentOperation: InputType = getInputType(sender.tag)
        let currentOperationAsString: String = String(describing: currentOperation)
        
        let currentOperationPrecedence = getPrecedence(currentOperationAsString)
        var operationInStackPrecedence = getPrecedence(operationStack.peak())
        
        if currentOperationPrecedence.rawValue > operationInStackPrecedence.rawValue {
            operationStack.push(displayText.text!)
            operationStack.push(currentOperationAsString)
            return
        }
        
        var secondOperand: String = displayText.text!
        
        var result: String = ""
        while currentOperationPrecedence.rawValue <= operationInStackPrecedence.rawValue {
            let operatorToExecuteFromStack: String = operationStack.pop()!
            let firstOperand: String = operationStack.pop()!
            
            result = getBinaryOperationResult(firstOperand, secondOperand, operatorToExecuteFromStack)
            if result == errorMessage {
                //operationStack = Stack()
                displayText.text = errorMessage
                return
            }
            secondOperand = result
            operationInStackPrecedence = getPrecedence(operationStack.peak())
        }
        displayText.text = result
        operationStack.push(result)
        operationStack.push(currentOperationAsString)
        
    }
    
    
    // Clear the display by showing the initial string "0"
    @IBAction func clearButtonPushed(_ sender: UIButton) {
        inputState = .Initial
        displayText.text = initialStringOnDisplay
    }
    
    // Run state machine logic each time a numeric button is pushed, including "."
    @IBAction func numericButtonPushed(_ sender: UIButton) {
        
        if inputState == State.OperationInProgress {
            inputState = .Initial
            displayText.text = initialStringOnDisplay
        }
        let input = sender.tag
        let inputType = getInputType(input)
        let inputString = String(input)
        
        switch inputState {
            case .Initial:
                if inputType == InputType.DigitOnetoNine {
                    if displayText.text == initialStringOnDisplay {
                        displayText.text = ""
                    }
                    concatDigitAndContinueProcessingIntegerPart(inputString)
                }
                if inputType == InputType.Dot {
                    concatDigitAndContinueProcessingFractionalPart(getCharFromAsciiValue(dotCharAscii))
                }
                return
            
            case .IntegerPart:
                if inputType == InputType.Dot {
                    concatDigitAndContinueProcessingFractionalPart(getCharFromAsciiValue(dotCharAscii))
                }
                else {
                    concatDigit(inputString)
                }
                return
            
            case .FractionalPart:
                if inputType == InputType.Zero || inputType == InputType.DigitOnetoNine {
                    concatDigit(String(input))
                }
                return
            default:
                return
        }
        
    }
    
    // Private methods
    // =========================================================================
    
    private func getBinaryOperationResult(_ firstOperand: String, _ secondOperand: String, _ operation: String) -> String {
        
        switch operation {
        case "Addition":
            return String( Float(firstOperand)! + Float(secondOperand)! )
        case "Substraction":
            return String( Float(firstOperand)! - Float(secondOperand)! )
        case "Multiplication":
            return String( Float(firstOperand)! * Float(secondOperand)! )
        case "Division":
            if secondOperand == "0" {
                return errorMessage
            }
            return String( Float(firstOperand)! / Float(secondOperand)! )
        default:
            return initialStringOnDisplay
        }
        
    }
    
    private func getPrecedence(_ value:String?) -> Precendence {
        
        switch value {
        case "Addition"?, "Substraction"?:
            return .Addition
        case "Multiplication"?, "Division"?:
            return .Multplication
        case "Percentage"?, "ChangeSign"?:
            return .Unary
        default:
            return .None
        }
    }
    
    private func concatDigitAndContinueProcessingFractionalPart(_ input:String) {
        concatDigit(input)
        inputState = .FractionalPart
    }
    
    private func concatDigitAndContinueProcessingIntegerPart(_ input:String) {
        concatDigit(input)
        inputState = .IntegerPart
    }
    
    private func concatDigit(_ input:String) {
        if (displayText.text?.count)! < displayMaxLengthPortrait {
                displayText.text?.append(input)
        }
    }
    
    private func getInputType(_ input: Int) -> InputType {
        switch input {
        case -1:
            return .Dot
        case 0:
            return .Zero
        case 10:
            return .Equal
        case 11:
            return .Addition
        case 12:
            return .Substraction
        case 13:
            return .Multiplication
        case 14:
            return .Division
        case 15:
            return .Percentage
        case 16:
            return .ChangeSign
        case 17:
            return .Clear
        default:
            return .DigitOnetoNine
        }
    }
    
    private func getCharFromAsciiValue(_ value: Int) -> String {
        // Convert int to UnicodeScalar, and then to a Character.
        // Adapted from https://www.dotnetperls.com/convert-int-character-swift web site
        return String(Character(UnicodeScalar(value)!))
    }
    
}

