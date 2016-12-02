//
//  FirebaseData.swift
//  PupsAndPlaygrounds
//
//  Created by Robert Deans on 11/20/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation
import Firebase

class FirebaseData {
    
    
    
    // MARK: Account Creation
    
    static func createAccountTouched(firstName: String, lastName: String, email:String, password: String, checkedPassword:String) {
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { user, error in
            
            guard error == nil else { print("error creating firebase user; Error: \(error)"); return }
            guard let user = user else { print("error unwrapping user data"); return }
            
            let changeRequest = user.profileChangeRequest()
            changeRequest.displayName = firstName + lastName
            
            changeRequest.commitChanges { error in
                
                guard error == nil else { print("error commiting changes for user profile change request"); return }
                
            }
        }
        
        addUserToBranch(firstName: firstName, lastName: lastName, email: email, password: password)
        
    }
    
    static func addUserToBranch(firstName: String, lastName: String, email:String, password: String) {
        let ref = FIRDatabase.database().reference().root
        guard let userKey = FIRAuth.auth()?.currentUser?.uid else { return }
        
        ref.child("users").updateChildValues([userKey: ["firstName": firstName, "lastName": lastName, "email": email, "password": password]])
    }
    
    
    static func signIn(email: String, password: String) {
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { user, error in
            
            guard error == nil else { print("error signing user in"); return }
            
        }
    }
    
    // MARK: Get single user/review/location with uniqueID
    
    
    static func getUser(with userID: String, completion: @escaping (User?) -> ()) {
        let ref = FIRDatabase.database().reference().root
        
        let userKey = ref.child("users").child(userID)
        
        userKey.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userDict = snapshot.value as? [String : Any] else { return }
            guard let firstName = userDict["firstName"] as? String else { return }
            guard let lastName = userDict["lastName"] as? String else { return }
            guard let userReviews = userDict["reviews"] as? [String:Any] else { return }
            
            
            print("USER IS \(firstName) \(lastName)")
            
            var reviewsArray = [Review]()
            for review in userReviews {
                print("REVIEW KEY IS \(review.key)")
                
                getReview(with: review.key, completion: { (reviewComp) in
                    let newReview = reviewComp
                    reviewsArray.append(newReview)
                })
            }
            completion(User(uniqueID: "\(userKey)", firstName: firstName, lastName: lastName, reviews: reviewsArray))
        })
    }
    
    static func getReview(with reviewID: String, completion: @escaping (Review) -> ()) {
        let ref = FIRDatabase.database().reference().root
        
        let userKey = ref.child("reviews").child("visible").child(reviewID)
        
        print(userKey)
        
        userKey.observeSingleEvent(of: .value, with: { (snapshot) in
            print("SNAPSHOT = \(snapshot.value)")
            
            guard let reviewDict = snapshot.value as? [String : Any] else { print("REVIEWDICT = \(snapshot.value as? [String : Any])"); return }
            
            guard let comment = reviewDict["comment"] as? String else { print("ERROR #2 \(reviewDict["comment"])"); return }
            
            guard let userID = reviewDict["userID"] as? String else { print("ERROR #3"); return }
            guard let locationID = reviewDict["locationID"] as? String else { print("ERROR #4"); return }
            
            getLocation(with: locationID, completion: { (location) in
                getUser(with: userID, completion: { (user) in
                    completion(Review(user: user!, location: location, comment: comment, photos: []))
                })
            })
        })
    }
    
    
    
    static func getLocation(with locationID: String, completion: @escaping (Location) -> ()) {
        let ref = FIRDatabase.database().reference().root
        
        let locationKey = ref.child("locations").child(locationID)
        
        locationKey.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let locationDict = snapshot.value as? [String : Any] else { return }
            guard let name = locationDict["name"] as? String else { return }
            guard let address = locationDict["address"] as? String else { return }
            guard let latitude = locationDict["latitude"] as? Double else { return }
            guard let longitude = locationDict["longitude"] as? Double else { return }
            guard let isHandicap = locationDict["isHandicap"] as? Bool else { return }
            guard let isFlagged = locationDict["isFlagged"] as? Bool else { return }
            guard let photos = locationDict["photos"] as? [UIImage] else { return }
            guard let reviewsDict = locationDict["reviews"] as? [String:Any] else { return }
            
            
            // to complete later
            var reviewsArray = [Review]()
            
            /*
             for review in reviewsDict {
             let newReview = review()
             reviewsArray.append(newReview)
             }
             */
            
            if locationID.hasPrefix("PG") {
                
                
                
                
                completion(Playground(ID: "\(locationKey)", name: name, address: address, isHandicap: isHandicap, latitude: latitude, longitude: longitude, reviews: reviewsArray, photos: photos, isFlagged: isFlagged)
                    
                    
                    
                )
                
            } /* else if locationID.hasPrefix("DR") {
             
             completion(Dogrun(citydata: <#T##[String : Any]#>))
             
             } */
            
            
        })
    }
    
    static func getNewReviewsForLocation(completion:@escaping (String)->()) {
        let ref = FIRDatabase.database().reference().root
        
        guard let userUniqueID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let userKey = ref.child("users").child(userUniqueID)
        
        userKey.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userKey = snapshot.value as? [String : Any] else { return }
            guard let userNameValue = userKey["firstName"] as? String else { return }
            completion(userNameValue)
        })
        completion("Anonymous")
    }
    
    
    // MARK: Adds Reviews to Data Branch
    
    static func addReview(comment: String, locationID: String) {
        let ref = FIRDatabase.database().reference().root
        
        let uniqueReviewKey = FIRDatabase.database().reference().childByAutoId().key
        
        guard let userUniqueID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        
        if locationID.hasPrefix("PG") {
            
            ref.child("locations").child("playgrounds").child("\(locationID)").child("reviews").updateChildValues([uniqueReviewKey: ["flagged": false]])
            
        } else if locationID.hasPrefix("DR") {
            
            ref.child("locations").child("dogruns").child("\(locationID)").child("reviews").updateChildValues([uniqueReviewKey: ["flagged": false]])
        }
        
        ref.child("users").child("\(userUniqueID)").child("reviews").updateChildValues([uniqueReviewKey: ["flagged": false]])
        
        ref.child("reviews").child("visible").updateChildValues([uniqueReviewKey: ["comment": comment, "userID": userUniqueID, "locationID": locationID, "flagged": false]])
        
        
        
        
    }
    
    // MARK Flag review or location
    
    
    static func flagReviewWith(unique reviewID: String, locationID: String, comment: String, userID: String, completion: () -> Void) {
        let rootRef = FIRDatabase.database().reference().root
        
        let reviewRef = rootRef.child("reviews")
        
        guard let userUniqueID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        if locationID.hasPrefix("PG") {
            
            rootRef.child("locations").child("playgrounds").child("\(locationID)").child("reviews").updateChildValues([reviewID: ["flagged": true]])
            
        } else if locationID.hasPrefix("DR") {
            
            rootRef.child("locations").child("dogruns").child("\(locationID)").child("reviews").updateChildValues([reviewID: ["flagged": true]])
        }
        
        rootRef.child("users").child("\(userUniqueID)").child("reviews").updateChildValues([reviewID: ["flagged": true]])
        
        
        reviewRef.child("flagged").updateChildValues([reviewID: ["comment": comment, "userID": userID, "locationID": locationID, "flagged": true]])
        
        reviewRef.child("visible").child(reviewID).removeValue()
        completion()
    }
    
    
    // MARK: User can delete own comment
    
    static func deleteUsersOwnReview(with userID: String, reviewID: String, locationID: String, completion: () -> ()) {
        
        let ref = FIRDatabase.database().reference().root
        
        guard let userUniqueID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        if userID == userUniqueID {
            
            if locationID.hasPrefix("PG") {
                
                ref.child("locations").child("playgrounds").child("\(locationID)").child("reviews").child(reviewID).removeValue()
                
            } else if locationID.hasPrefix("DR") {
                
                ref.child("locations").child("dogruns").child("\(locationID)").child("reviews").child(reviewID).removeValue()
            }
            
            ref.child("users").child("\(userUniqueID)").child("reviews").child(reviewID).removeValue()
            
            
            ref.child("visible").child(reviewID).removeValue()
            
            completion()
            
        }
        
        
    }
    
    // MARK: Generates Locations on the app FROM Firebase data source
    
    static func getAllPlaygrounds(with completion: @escaping ([Playground]) -> Void ) {
        print("GETTING ALL PLAYGROUNDS")
        
        var playgroundArray: [Playground] = []
        
        let ref = FIRDatabase.database().reference().child("locations").child("playgrounds")
        
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let playgroundDict = snapshot.value as? [String : Any] else { return }
            
            print("PLAYGROUND DICTIONARY = \(playgroundDict)")
            for newPlayground in playgroundDict {
                
                let ID = newPlayground.key
                let value = newPlayground.value as! [String:Any]
                print("PLAYGROUND VALUE = \(value)")
                guard let locationName = value["name"] as? String else { return }
                guard let location = value["location"] as? String else { return }
                guard let latitude = value["latitude"] as? String else { return }
                guard let longitude = value["longitude"] as? String else { return }
                guard let isHandicap = value["isHandicap"] as? Bool else { return }
                guard let isFlagged = value["isFlagged"] as? Bool else { return }
                //                guard let photos = value["photos"] as? [UIImage] else { return }
                guard let reviewsDict = value["reviews"] as? [String:Any] else { return }
                
                var reviewsArray = [Review]()
                let photos = [UIImage]()
                if let playgroundReviews = value["reviews"] as? [String:Any] {
                    
                    
                    for review in playgroundReviews {
                        
                        ref.child(ID).child("reviews").child(review.key).removeValue()
                        
                        
                        /*
                         getReview(with: review.key, completion: { (reviewComp) in
                         let newReview = reviewComp
                         reviewsArray.append(newReview)
                         })
                         */
                        
                    }
                }
                
                let newestPlayground = Playground(ID: ID, name: locationName, address: location, isHandicap: isHandicap, latitude: Double(latitude)!, longitude: Double(longitude)!, reviews: reviewsArray, photos: photos, isFlagged: isFlagged)
                print("NEW PLAYGROUND = \(newestPlayground)")
                playgroundArray.append(newestPlayground)
                
            }
            completion(playgroundArray)
        })
    }
    
    // MARK: Get coordinates from Firebase
    
    static func getPlaygroundsLocationCoordinates(for locationID: String, completion: @escaping (_ longitude: String, _ latitude: String) -> Void) {
        
        let ref = FIRDatabase.database().reference().child("locations").child("playgrounds").child(locationID)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let locationSnap = snapshot.value as? [String: Any] else {return}
            guard let longitude = locationSnap["longitude"] as? String else {return}
            guard let latitude = locationSnap["latitude"] as? String else {return}
            
            completion(longitude, latitude)
        })
        
    }
    
    // MARK: Gets reviews from Firebase
    
    static func getReviewsFromFirebase(for locationID: String, completion: @escaping ([[String: Any]]) -> Void) {
        
        let ref = FIRDatabase.database().reference().child("locations").child("playgrounds").child(locationID).child("reviews")
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let reviewSnap = snapshot.value as? [[String : Any]] else { return }
            
            completion(reviewSnap)
        })
        
    }
    
    // MARK: Adding local JSON files to Firebase
    
    static func addPlaygroundsToFirebase(name: String, address: String, isHandicap: String, latitude: String, longitude: String) {
        
        let ref = FIRDatabase.database().reference().root
        
        let uniqueLocationKey = FIRDatabase.database().reference().childByAutoId().key
        print("Key = \(uniqueLocationKey)")
        
        var isHandicapBool = false
        if isHandicap == "true" {
            isHandicapBool = false
        }
        
        ref.child("locations").child("playgrounds").updateChildValues(["PG-\(uniqueLocationKey)":["name": name, "address": address, "isHandicap": isHandicapBool, "latitude": latitude, "longitude": longitude, "isFlagged": false]])
    }
    
    static func addDogrunsToFirebase(dogRunID: String, name: String, location: String, isHandicap: Bool, dogRunType: String, notes: String) {
        
        let ref = FIRDatabase.database().reference().root
        
        let uniqueLocationKey = dogRunID
        
        var isHandicapString = "No"
        
        if isHandicap == true {
            isHandicapString = "Yes"
        }
        
        
        ref.child("locations").child("dogruns").updateChildValues( [uniqueLocationKey:["name": name, "location": location, "isHandicap": isHandicapString, "dogRunType": dogRunType, "notes": notes]])
    }
    
}
