/*
 * ViewController.swift
 * Project: SimpleCalculator
 * Name: Robert Argume
 * StudentID: 300949529
 * Date: Sep 26, 2017
 * Description: Simple Calculator App developded for Assignment 1
 * Version: 0.95 - Added sound for application launch and buttons
 * Notes:
 *   - UI design/development using iPhone SE, then scaled up to larger screens
 *   - Some constraints warning are shown in the storyboard, but the simulator renders the App correctly
 *   - Buttons size correctly for landscape orientation for all iPhones screen, but the images used as background does not size very good for landscape
 */

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // GLOBAL VARIABLES
    // =========================================================================
    
    // Variable added to initialize audio in the App
    var audioPlayer = AVAudioPlayer()
    
    // Processing number buttons to concatenate and form a single operand will be done by a state machine logic
    enum State {
        case Initial
        case IntegerPart
        case FractionalPart
        case BinaryOperationInProgress
        case ChangeSignOperationInProgress
        case PercentageOperationInProgress
        case EqualOperationExecuted
    }
    var inputState: State = .Initial
    
    // All buttons used to form a number are categorized in 3 types to work with the state machine
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
    
    // Store the last operand used as well as last operation
    // There are special cases where last second operand is not what the display shows
    // For example, when performing some operations, and then tapping "=" or any operator many times in a row
    var lastSecondOperand: String?
    var lastBinaryOperation: String?
    
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
    
    // Variable to save how many chars can be added to the display.
    // This depends on the current device orientation
    var displayMaxLength: Int?
    
    // Various constant values to be used in this App
    let dotCharAscii = 46
    let displayMaxLengthPortrait = 10
    let displayMaxLengthLandscape = 17
    let initialStringOnDisplay = "0"
    let errorMessage = "Error"

    
    // OUTLETS
    // =========================================================================
    
    // Connects to the text label control in the storyboard to show the input number and results
    @IBOutlet weak var displayText: UILabel!
    
    
    // OVERRIDEN METHODS
    // =========================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        resetOperationsEnvironment()
        displayMaxLength = getDisplayMaxLength()
        lastBinaryOperation = nil
        showInDisplay(initialStringOnDisplay)
    }
    
    // This method detects the change of orientation and set a different max length for the display
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        displayMaxLength = getDisplayMaxLength()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // ACTIONS
    // =========================================================================
    
    // Logic for the Equal button
    // There are 2 cases: Hit the button when there were previous operations
    // Or hit the button after all pending operations were executed
    @IBAction func equalButtonPushed(_ sender: UIButton) {
        // Sound when push the button
        playSound(file: "Pop", ext: "aiff")
        
        inputState = .EqualOperationExecuted
        
        // Previous operations were executed, and the stack is not empty. Let us execute all operations in the stack
        if lastBinaryOperation != nil && !operationStack.isEmpty(){
            showInDisplay(solveOperationsDelayedInTheStack(.None, getPrecedence(operationStack.peak()), displayText.text!))
            return
        }
        
        // Equal button was just tapped before, thus all operations in the stack were executed
        // This means we should repeat last operation with last second operand
        if lastBinaryOperation != nil && operationStack.isEmpty() {
            showInDisplay(getBinaryOperationResult(displayText.text!, lastSecondOperand!, lastBinaryOperation!))
            return
        }
    }
    
    // Logic for the Unary operations. Percentage and +/- buttons
    // Functionality for using Percentage after a sum or substraction is implemented
    // We detect for these 2 operations, to calculate percentage and add it to the initial value
    @IBAction func unaryOperationButtonPushed(_ sender: UIButton) {
        // Sound when push the button
        playSound(file: "Pop", ext: "aiff")
        
        if displayText.text == nil || displayText.text == errorMessage {
            return
        }
        
        switch getInputType(sender.tag) {
            case .ChangeSign:
                if inputState != .BinaryOperationInProgress {
                    if displayText.text!.characters.first == "-" {
                        let index = displayText.text!.index(displayText.text!.startIndex, offsetBy: 1)
                        showInDisplay(displayText.text!.substring(from: index))
                    }
                    else {
                        showInDisplay("-" + displayText.text!)
                    }
                }
                else {
                    showInDisplay("-0")
                    inputState = .ChangeSignOperationInProgress
                }
                return
            case .Percentage:
                let percentage: Float = getPercentageValue(displayText.text!)
                if operationStack.isEmpty() {
                    showInDisplay(String(percentage))
                    lastBinaryOperation = nil
                }
                else {
                    let operationInStack = operationStack.pop()
                    let previousOperand = operationStack.peak()
                    operationStack.push(operationInStack!)
                    if previousOperand == errorMessage {
                        return
                    }
                    if operationInStack == "Addition" || operationInStack == "Substraction" {
                        showInDisplay(String(Float(previousOperand!)! * percentage))
                    }
                    else {
                        showInDisplay(String(percentage))
                    }
                }
                inputState = .PercentageOperationInProgress
                return
            default:
                return
        }
    }
    
    // Run binary operations logic
    // Based on a stack structure to prioritize execution of binary operations
    @IBAction func binaryOperationButtonPushed(_ sender: UIButton) {
        // Sound when push the button
        playSound(file: "Pop", ext: "aiff")
        
        inputState = .BinaryOperationInProgress
        let currentOperation: InputType = getInputType(sender.tag)
        let currentOperationAsString: String = String(describing: currentOperation)
        
        let currentOperationPrecedence = getPrecedence(currentOperationAsString)
        let operationInStackPrecedence = getPrecedence(operationStack.peak())
        
        if currentOperationPrecedence.rawValue > operationInStackPrecedence.rawValue {
            operationStack.push(displayText.text!)
            operationStack.push(currentOperationAsString)
            lastBinaryOperation = currentOperationAsString
        }
        else {
            let result = solveOperationsDelayedInTheStack(currentOperationPrecedence, operationInStackPrecedence, displayText.text!)
            showInDisplay(result)
            operationStack.push(result)
            operationStack.push(currentOperationAsString)
        }
    }
    
    // Clear the display by showing the initial string "0"
    @IBAction func clearButtonPushed(_ sender: UIButton) {
        // Sound when push the button
        playSound(file: "Pop", ext: "aiff")
        
        inputState = .Initial
        showInDisplay(initialStringOnDisplay)
        resetOperationsEnvironment()
    }
    
    // Run state machine logic each time a numeric button is pushed, including "."
    // There are 3 states used for building an operand by concatenating the user input:
    // The initial state
    // State to indicate the integer part of the number is being processed
    // State to indicate the fractional part is being processed
    @IBAction func numericButtonPushed(_ sender: UIButton) {
        // Sound when push the button
        playSound(file: "Pop", ext: "aiff")
        
        if inputState == .BinaryOperationInProgress || inputState == .EqualOperationExecuted || inputState == .PercentageOperationInProgress {
            inputState = .Initial
            showInDisplay(initialStringOnDisplay)
        }
        else if inputState == .ChangeSignOperationInProgress {
            inputState = .Initial
            showInDisplay("-")
        }
        
        let input = sender.tag
        let inputType = getInputType(input)
        let inputString = String(input)
        
        switch inputState {
            case .Initial:
                if inputType == InputType.DigitOnetoNine {
                    if displayText.text == initialStringOnDisplay || displayText.text == errorMessage {
                        showInDisplay("")
                    }
                    concatDigitAndContinueProcessingIntegerPart(inputString)
                }
                if inputType == InputType.Dot {
                    if displayText.text == errorMessage {
                        showInDisplay("0")
                    }
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
    
    // Returns the max amount of chars to be concatenated to the display according to current device orientation
    private func getDisplayMaxLength() -> Int {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft || UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            return displayMaxLengthLandscape
        }
        return displayMaxLengthPortrait
    }
    
    // Updates the string shown in the display text label
    private func showInDisplay(_ value: String) {
        var valueToShow = value
        if valueToShow.characters.contains(".") {
            let indexOfDecimalPoint = valueToShow.characters.index(of: ".")
            let fractionalPart = valueToShow.substring(from: indexOfDecimalPoint!)
            if fractionalPart == ".0" {
                valueToShow = valueToShow.substring(to: indexOfDecimalPoint!)
            }
        }
        displayText.text! = valueToShow
    }
    
    // Divide a number by 100 to get the percentage of the value compared to 100
    private func getPercentageValue(_ value: String?) -> Float{
        return Float(value!)! / 100
    }
    
    // Set calculation variables to their initial values
    private func resetOperationsEnvironment () {
        operationStack.flush()
        lastSecondOperand = initialStringOnDisplay
        inputState = .Initial
    }
    
    // Executes binary operations
    // Apply every operation to 2 operands
    private func getBinaryOperationResult(_ firstOperand: String, _ secondOperand: String, _ operation: String) -> String {
        if Float(firstOperand) == nil || Float(secondOperand) == nil || (operation == "Division" && secondOperand == "0") {
            resetOperationsEnvironment()
            return  errorMessage
        }
        
        lastBinaryOperation = operation
        switch operation {
            case "Addition":
                return String( Float(firstOperand)! + Float(secondOperand)! )
            case "Substraction":
                return String( Float(firstOperand)! - Float(secondOperand)! )
            case "Multiplication":
                return String( Float(firstOperand)! * Float(secondOperand)! )
            case "Division":
                return String( Float(firstOperand)! / Float(secondOperand)! )
            default:
                return initialStringOnDisplay
        }
    }
    
    // Calculate operations stored in the stack acording to precedence
    func solveOperationsDelayedInTheStack(_ currentOperationPrecedence: Precendence, _ stackPrecedence: Precendence, _ currentSecondOperand: String) -> String {
        var secondOperand = currentSecondOperand
        var currentStackPrecedence: Precendence = stackPrecedence
        var result: String = ""
        
        while result != errorMessage && !operationStack.isEmpty() &&
            currentOperationPrecedence.rawValue <= currentStackPrecedence.rawValue {
                let operatorToExecuteFromStack: String = operationStack.pop()!
                let firstOperand: String = operationStack.pop()!
                lastSecondOperand = secondOperand
                
                result = getBinaryOperationResult(firstOperand, secondOperand, operatorToExecuteFromStack)
                secondOperand = result
                currentStackPrecedence = getPrecedence(operationStack.peak())
        }
        return result
    }
    
    // Return a math operation precedence
    // This way we can compare operations and give priority to execute them
    private func getPrecedence(_ operation:String?) -> Precendence {
        switch operation {
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
    
    // Concatenate char to display
    // Set state to FractionalPart for the state machine logic that process operands
    private func concatDigitAndContinueProcessingFractionalPart(_ input:String) {
        concatDigit(input)
        inputState = .FractionalPart
    }
    
    // Concatenate char to display
    // Set state to IntegerPart for the state machine logic that process operands
    private func concatDigitAndContinueProcessingIntegerPart(_ input:String) {
        concatDigit(input)
        inputState = .IntegerPart
    }
    
    // Concatenate a char to the current value of the display
    private func concatDigit(_ input:String) {
        if (displayText.text?.count)! < displayMaxLength! {
                displayText.text?.append(input)
        }
    }
    
    // Return InputType according to the TAG value set on every button in the App
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
    
    // Convert int to UnicodeScalar, and then to a Character.
    // Adapted from https://www.dotnetperls.com/convert-int-character-swift web site
    private func getCharFromAsciiValue(_ value: Int) -> String {
        return String(Character(UnicodeScalar(value)!))
    }
    
    // Play a sound from a file inside the project
    // To be reused anywhere in the App
    // From: https://stackoverflow.com/questions/43715285/xcode-swift-adding-sound-effects-to-launch-screen
    func playSound(file:String, ext:String) -> Void {
        do {
            let url = URL.init(fileURLWithPath: Bundle.main.path(forResource: file, ofType: ext)!)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch let error {
            NSLog(error.localizedDescription)
        }
    }
    
}

