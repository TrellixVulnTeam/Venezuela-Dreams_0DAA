//
//  LoginViewController.swift
//  VenezuelaDreams
//
//  Created by Andres Prato on 2/13/18.
//  Copyright © 2018 Andres Prato. All rights reserved.
//

import UIKit
import Firebase

enum AMLoginSignupViewMode {
    case login
    case signup
}

class LoginViewController: UIViewController {

    let animationDuration = 0.25
    var mode:AMLoginSignupViewMode = .signup
    
    
    //MARK: - background image constraints
    @IBOutlet weak var backImageLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var backImageBottomConstraint: NSLayoutConstraint!
    
    
    //MARK: - login views and constrains
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginContentView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginButtonVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginWidthConstraint: NSLayoutConstraint!
    
    
    //MARK: - signup views and constrains
    @IBOutlet weak var signupView: UIView!
    @IBOutlet weak var signupContentView: UIView!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var signupButtonVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var signupButtonTopConstraint: NSLayoutConstraint!
    
    
    //MARK: - logo and constrains
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoButtomInSingupConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoCenterConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var forgotPassTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var socialsView: UIView!
    
    
    //MARK: - input views
    @IBOutlet weak var loginEmailInputView: AMInputView!
    @IBOutlet weak var loginPasswordInputView: AMInputView!
    @IBOutlet weak var signupEmailInputView: AMInputView!
    @IBOutlet weak var signupPasswordInputView: AMInputView!
    @IBOutlet weak var signupPasswordConfirmInputView: AMInputView!
    @IBOutlet weak var signupLastNameInputView: AMInputView!
    @IBOutlet weak var signupFirstNameInputView: AMInputView!
    //MARK: - controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set view to login mode
        toggleViewMode(animated: false)
        
        //add keyboard notification
        NotificationCenter.default.addObserver(self, selector: #selector(keyboarFrameChange(notification:)), name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //MARK: - button actions
    @IBAction func loginButtonTouchUpInside(_ sender: AnyObject) {
        
        if mode == .signup {
            toggleViewMode(animated: true)
            
        }else{
            
            //TODO: login by this data
            //NSLog("Email:\(loginEmailInputView.textFieldView.text) Password:\(loginPasswordInputView.textFieldView.text)")
            handleLogin()
        }
    }
    
    @IBAction func signupButtonTouchUpInside(_ sender: AnyObject) {
        
        if mode == .login {
            toggleViewMode(animated: true)
        }else{
            
            //TODO: signup by this data
            //NSLog("Email:\(signupEmailInputView.textFieldView.text) Password:\(signupPasswordInputView.textFieldView.text), PasswordConfirm:\(signupPasswordConfirmInputView.textFieldView.text)")
            handleRegister()

        }
    }
    
    //handle registration of user through email
    @objc func handleRegister(){
        
        //get email, password, name, and lastname
        guard let email = signupEmailInputView.textFieldView.text, let password = signupPasswordInputView.textFieldView.text, let name = signupFirstNameInputView.textFieldView.text, let lastname = signupLastNameInputView.textFieldView.text else {
            print("Form is not valid")
            return
        }
        
        createAndAddtoDbUser(name: name, lastname: lastname, email: email, password: password, gender: "M")
        
//        var gender = ""
//        //if gender is male, create user if the male gender
//        if (maleIsChecked){
//            gender = "male"
//            createAndAddtoDbUser(name: name, lastname: lastname, email: email, password: password, gender: gender)
//
//            //if gender is female, create user if the female gender
//        } else if (femaleIsChecked){
//            gender = "female"
//            createAndAddtoDbUser(name: name, lastname: lastname, email: email, password: password, gender: gender)
//
//            //if gender is empty, prompt user to enter one
//        } else if (gender == ""){
//            print("Please specify gender")
//            let alertController = UIAlertController(title: "Form is not valid!", message:
//                "Please, enter gender!", preferredStyle: UIAlertControllerStyle.alert)
//            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
//            self.present(alertController, animated: true, completion: nil)
//        }
    }
    
    //creates the user and adds to the database
    func createAndAddtoDbUser(name:String, lastname:String, email:String, password:String, gender:String){
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
            
            //if error is not null then prompt user error
            if (error != nil){
                print(error ?? "")
                if let errCode = FIRAuthErrorCode(rawValue: error!._code) {
                    switch errCode{
                    //if the email already exists
                    case .errorCodeEmailAlreadyInUse:
                        let alertController = UIAlertController(title: "Not a valid email!", message:
                            "Email is already taken", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                        
                    //if the email entered is not valid
                    case .errorCodeInvalidEmail:
                        let alertController = UIAlertController(title: "Not a valid email!", message:
                            "That is not a vaid email", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                        
                    //otherwise return the error
                    default:
                        print("Error creating user: \(String(describing: error))")
                    }
                    
                }
                return
            }
            
            //gets the user's id
            guard let uid = user?.uid else{
                return
            }
            let ref = FIRDatabase.database().reference(fromURL: "https://vzladreams.firebaseio.com/")
            let values = ["name": name, "lastname": lastname, "email": email, "gender": gender]
            let usersReference = ref.child("user").child("email_users").child(uid)
            usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                
                if (err != nil){
                    print(err ?? "")
                    return
                }
                print("Saves user succesfully into db")
                self.performSegue(withIdentifier: "redirectLoginSignup", sender: self)
            })
        })
    }
    
    func handleLogin(){
        guard let email = loginEmailInputView.textFieldView.text, let password = loginPasswordInputView.textFieldView.text else {
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if (error != nil){
                
                if let errCode = FIRAuthErrorCode(rawValue: error!._code) {
                    switch errCode{
                    //if the email already exists
                    case .errorCodeUserNotFound:
                        let alertController = UIAlertController(title: "Email doesn't exist", message:
                            "Verify your email or create an account", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                        
                    //if the email entered is not valid
                    case .errorCodeInvalidEmail:
                        let alertController = UIAlertController(title: "Not a valid email!", message:
                            "That is not a vaid email", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    
                    case .errorCodeWrongPassword:
                        let alertController = UIAlertController(title: "Wrong password!", message:
                            "You entered the wrong password.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    //otherwise return the error
                    default:
                        print("Error creating user \(error)")
                    }
                    
                    
                    print(error ?? "")
                    return
                }
            }
            self.performSegue(withIdentifier: "redirectLoginSignup", sender: self)
            
        })
    }
    
    //MARK: - toggle view
    func toggleViewMode(animated:Bool){
        
        // toggle mode
        mode = mode == .login ? .signup:.login
        
        
        // set constraints changes
        backImageLeftConstraint.constant = mode == .login ? 0:-self.view.frame.size.width
        
        
        loginWidthConstraint.isActive = mode == .signup ? true:false
        logoCenterConstraint.constant = (mode == .login ? -1:1) * (loginWidthConstraint.multiplier * self.view.frame.size.width)/2
        loginButtonVerticalCenterConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(mode == .login ? 300:900))
        signupButtonVerticalCenterConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(mode == .signup ? 300:900))
        
        
        //animate
        self.view.endEditing(true)
        
        UIView.animate(withDuration:animated ? animationDuration:0) {
            
            //animate constraints
            self.view.layoutIfNeeded()
            
            //hide or show views
            self.loginContentView.alpha = self.mode == .login ? 1:0
            self.signupContentView.alpha = self.mode == .signup ? 1:0
            
            
            // rotate and scale login button
            let scaleLogin:CGFloat = self.mode == .login ? 1:0.4
            let rotateAngleLogin:CGFloat = self.mode == .login ? 0:CGFloat(-Double.pi/2)
            
            var transformLogin = CGAffineTransform(scaleX: scaleLogin, y: scaleLogin)
            transformLogin = transformLogin.rotated(by: rotateAngleLogin)
            self.loginButton.transform = transformLogin
            
            
            // rotate and scale signup button
            let scaleSignup:CGFloat = self.mode == .signup ? 1:0.4
            let rotateAngleSignup:CGFloat = self.mode == .signup ? 0:CGFloat(-Double.pi/2)
            
            var transformSignup = CGAffineTransform(scaleX: scaleSignup, y: scaleSignup)
            transformSignup = transformSignup.rotated(by: rotateAngleSignup)
            self.signupButton.transform = transformSignup
        }
    }
    
    //MARK: - keyboard
    @objc func keyboarFrameChange(notification:NSNotification){
        
        let userInfo = notification.userInfo as! [String:AnyObject]
        
        // get top of keyboard in view
        let topOfKetboard = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue .origin.y
        
        
        // get animation curve for animate view like keyboard animation
        var animationDuration:TimeInterval = 0.25
        var animationCurve:UIViewAnimationCurve = .easeOut
        if let animDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            animationDuration = animDuration.doubleValue
        }
        
        if let animCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
            animationCurve =  UIViewAnimationCurve.init(rawValue: animCurve.intValue)!
        }
        
        
        // check keyboard is showing
        let keyboardShow = topOfKetboard != self.view.frame.size.height
        
        
        //hide logo in little devices
        let hideLogo = self.view.frame.size.height < 667
        
        // set constraints
        backImageBottomConstraint.constant = self.view.frame.size.height - topOfKetboard
        
        logoTopConstraint.constant = keyboardShow ? (hideLogo ? 0:20):50
        logoHeightConstraint.constant = keyboardShow ? (hideLogo ? 0:40):60
        logoBottomConstraint.constant = keyboardShow ? 20:32
        logoButtomInSingupConstraint.constant = keyboardShow ? 20:32
        
        forgotPassTopConstraint.constant = keyboardShow ? 30:45
        
        loginButtonTopConstraint.constant = keyboardShow ? 25:30
        signupButtonTopConstraint.constant = keyboardShow ? 23:35
        
        loginButton.alpha = keyboardShow ? 1:0.7
        signupButton.alpha = keyboardShow ? 1:0.7
        
        
        
        // animate constraints changes
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        
        self.view.layoutIfNeeded()
        
        UIView.commitAnimations()
    }
    
    //MARK: - hide status bar in swift3
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
