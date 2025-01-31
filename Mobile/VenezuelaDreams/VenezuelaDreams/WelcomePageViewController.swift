//
//  ViewController.swift
//  VenezuelaDreams
//
//  Created by Andres Prato on 1/25/18.
//  Copyright © 2018 Andres Prato. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase

class WelcomePageViewController: UIViewController, FBSDKLoginButtonDelegate, UIScrollViewDelegate {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginButtonFB: FBSDKLoginButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    let about_us = ["title": "About us", "text": "We are a team that helps children in Venezuela eat their 3 meals a day. By receaving donations as little as 2$", "image": "delta2"]
    let our_mission = ["title": "Our mission", "text": "Our mission is to help children in Venezuela and help foundations raise money", "image": "delta1"]
    let how_it_works = ["title": "How it works", "text": "Select a child and then donate a amount of at leat 2$, between 1 week and 2 weeks you will receive a confirmation that the child received the food!", "image": "delta3"]
    var array_pages = [Dictionary<String, String>]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        array_pages = [about_us, our_mission, how_it_works]
        //checkUserIsLogged()
        setUpButtons()
        setUpScroll()
    }
    
    //This happens after the autolayout is done. So, any calculation done with autolayout number, it has to occur here
    override func viewDidAppear(_ animated: Bool) {
        loadPages()
    }

    //Set buttons of the view
    func setUpButtons(){
        loginButtonFB.delegate = self
        loginButtonFB.readPermissions = ["email", "public_profile"]
        loginButtonFB.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        loginButton.layer.cornerRadius = 5
        loginButton.layer.borderWidth = 0
        
        continueButton.layer.cornerRadius = 5
        continueButton.layer.borderWidth = 0
    }
    
    //Set scrollView
    func setUpScroll(){
        scrollView.isPagingEnabled = true
        scrollView.contentSize = CGSize(width: self.view.bounds.width * CGFloat(array_pages.count), height: self.scrollView.bounds.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
    }
    
    //Load the three cards in the view
    func loadPages(){
        for (index, page) in array_pages.enumerated(){
            let card = CardArticle(frame: CGRect(x: 10, y: 30, width: self.loginButton.bounds.width , height: self.scrollView.bounds.height))
            card.backgroundColor = UIColor(red: 0, green: 94/255, blue: 112/255, alpha: 1)
            //card.icon = UIImage(named: "flappy")
            card.category = page["title"]!
            card.categoryLbl.textColor = UIColor.white
            card.title = ""
            card.subtitle = page["text"]!
            card.blurEffect = .light
            //card.itemTitle = "Flappy Bird"
            //card.itemSubtitle = "Flap That !"
            card.backgroundImage = UIImage(named: page["image"]!)
            card.textColor = UIColor.white
            card.hasParallax = true
            let cardContentVC = storyboard!.instantiateViewController(withIdentifier: "CardContent")
            card.shouldPresent(cardContentVC, from: self, fullscreen: false)
            
            scrollView.addSubview(card)
            
            //set origin of x coordinate for the card
            if (index == 0){
                card.frame.origin.x = (self.view.bounds.width - self.loginButton.bounds.width) / 2
            } else {
            card.frame.origin.x = (CGFloat(index) * self.scrollView.bounds.width) + ((self.view.bounds.width - self.loginButton.bounds.width) / 2)
            }
            //set origin of the y coordinate for the card
            
            card.frame.origin.y = 0
        }
    }
    
    //Change the page number
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x / scrollView.frame.size.width
        pageControl.currentPage = Int(page)
    }
    
    //Check if there is an user logged in to redirect
    func checkUserIsLogged(){
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            
            if user != nil {
                // User is signed in.
                print("THIS IS THE UID: \(String(describing: FIRAuth.auth()?.currentUser?.uid))")
                self.performSegue(withIdentifier: "redirectAfterLoginFB", sender: self)
            } else {
                print("NO USER IS SIGNED IN")
                // No user is signed in.
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did logout of FB")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        //print error
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        print("Logged succesfully with FB")
        //create credentials for Firebase Auth and create the user in the Auth
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            if error != nil {
                print(error.debugDescription)
                return
            } else {
                print(result)
                print("Succesfully passed in the data")
                //gets the user's id
                guard let uid = user?.uid else{
                    return
                }
                //method from FBSDK to get data
                FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "first_name, last_name, gender, email"]).start(completionHandler: { (connection, result, error) -> Void in
                    if (error == nil){
                        let fbDetails = result as! NSDictionary
                        //get email, name, lastname, gender from fb
                        let email = fbDetails.value(forKeyPath: "email") as! String
                        let name = fbDetails.value(forKeyPath: "first_name") as! String
                        let lastname = fbDetails.value(forKeyPath: "last_name") as! String
                        let gender = fbDetails.value(forKeyPath: "gender") as! String
                        //call methos to add to the db with the repective parameters
                        self.addToDbFacebookUser(name: name, lastname: lastname, email: email, gender: gender, uid: uid)
                        print("\(email)\n  \(name)\n  \(lastname)\n  \(gender)")
                    } else {
                        print(error ?? "")
                        return
                    }
                })
                //do segue to main window
                self.doSegue()
            }
        }
    }
    
    //add user's info to database
    func addToDbFacebookUser(name: String, lastname: String, email: String, gender: String, uid: String){
        let ref = FIRDatabase.database().reference(fromURL: "https://vzladreams.firebaseio.com/")
        let values = ["name": name, "lastname": lastname, "email": email, "gender": gender]
        let usersReference = ref.child("user").child("facebook_users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            
            if (err != nil){
                print(err ?? "")
                return
            }
            print("Saved user succesfully into db")
        })
    }
    
    @IBAction func continueWithoutSignIn(_ sender: Any) {
        doSegue()
    }
    func doSegue(){
        self.performSegue(withIdentifier: "redirectAfterLoginFB", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

