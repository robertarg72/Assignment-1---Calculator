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
    
    // Concatenating input number to the display will use a state machine logic
    enum State {
        case Initial
        case IntegerPart
        case FractionalPart
    }
    var inputState: State = .Initial
    
    // All chars used to form a number are categorized in 3 types to work with the state machine
    enum NumericInputType {
        case Zero
        case DigitOnetoNine
        case Dot
    }
    
    // Constante values to be used in the logic
    let dotCharAscii = 46
    let displayMaxLengthPortrait = 10

    
    // OUTLETS
    // =========================================================================
    
    // Connects to the text label control in the storyboard to show the input number
    @IBOutlet weak var displayText: UILabel!
    
    
    // OVERRIDEN METHODS
    // =========================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        displayText.text = "0"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // ACTIONS
    // =========================================================================
    
    // Run state machine logic each time a numeric button is pushed, including "."
    @IBAction func numericButtonPushed(_ sender: UIButton) {
        let input = sender.tag
        let inputType = getInputType(input)
        let inputString = String(input)
        
        switch inputState {
            case .Initial:
                if inputType == NumericInputType.DigitOnetoNine {
                    if displayText.text == "0" {
                        displayText.text = ""
                    }
                    concatDigitAndContinueProcessingIntegerPart(inputString)
                }
                if inputType == NumericInputType.Dot {
                    concatDigitAndContinueProcessingFractionalPart(getCharFromAsciiValue(dotCharAscii))
                }
                return
            
            case .IntegerPart:
                if inputType == NumericInputType.Dot {
                    concatDigitAndContinueProcessingFractionalPart(getCharFromAsciiValue(dotCharAscii))
                }
                else {
                    concatDigit(inputString)
                }
                return
            
            case .FractionalPart:
                if inputType == NumericInputType.Zero || inputType == NumericInputType.DigitOnetoNine {
                    concatDigit(String(input))
                }
                return
        }
        
    }
    
    // Private methods
    // =========================================================================
    
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
    
    private func getInputType(_ input: Int) -> NumericInputType {
        switch input {
        case -1:
            return NumericInputType.Dot
        case 0:
            return NumericInputType.Zero
        default:
            return NumericInputType.DigitOnetoNine
        }
    }
    
    private func getCharFromAsciiValue(_ value: Int) -> String {
        // Convert int to UnicodeScalar, and then to a Character.
        // Adapted from https://www.dotnetperls.com/convert-int-character-swift web site
        return String(Character(UnicodeScalar(value)!))
    }
    
}

