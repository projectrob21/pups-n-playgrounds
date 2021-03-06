//
//  DataStore.swift
//  PupsAndPlaygrounds
//
//  Created by William Robinson on 12/7/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation
import Firebase

final class DataStore {
  var user: User? {
    didSet {
      print("stored user")
      NotificationCenter.default.post(name: Notification.Name("userStored"), object: nil)
      storeReviews()
    }
  }
  var userReviews: [Review]? {
    didSet {
      print("stored reviews")
      print(userReviews!.count)
      print(user!.uid)
      print(user!.reviewIDs)
      NotificationCenter.default.post(name: Notification.Name("reviewsStored"), object: nil)
    }
  }
  var dogRuns: [Dogrun]?
  var playgrounds: [Playground]?
  private let ref = FIRDatabase.database().reference()
  static let shared = DataStore()
  
  private init() {}
  
  func storeUser() {
    FIRClient.getCurrentUser(user: FIRAuth.auth()?.currentUser) { user in
      self.user = user
    }
  }
  
  func storeReviews() {
    FIRClient.getReviews(forUser: user) { reviews in
      self.userReviews = reviews
    }
  }
  
  func getLocations(completion: @escaping () -> Void) {
    getDogruns { self.getPlaygrounds { completion() } }
  }
  
  func getDogruns(completion: @escaping () -> Void) {
    let dogRunRef = ref.child("locations").child("dogruns")
    
    dogRunRef.observe(.value, with: { snapshot in
      guard let dogrunDict = snapshot.value as? [String : [String : Any]] else { print("error unwrapping dogruns"); return }
      var dogRuns = [Dogrun]()
      
      for (dogrunID, dogrunInfo) in dogrunDict {
        let dogRunID = dogrunID
        guard let name = dogrunInfo["name"] as? String else { print("error unwrapping dogrun name"); return }
        guard let latitude = dogrunInfo["latitude"] as? Double else { print("error unwrapping dogrun latitude"); return }
        guard let longitude = dogrunInfo["longitude"] as? Double else { print("error unwrapping dogrun longitude"); return }
        guard let address = dogrunInfo["address"] as? String else { print("error unwrapping dogrun address"); return }
        guard let isOffLeash = dogrunInfo["dogRunType"] as? Bool else { print("error unwrapping dogrun isOffLeash"); return }
        guard let notes = dogrunInfo["notes"] as? String else { print("error unwrapping dogrun notes"); return }
        guard let isHandicap = dogrunInfo["isHandicap"] as? Bool else { print("error unwrapping dogrun isHandicap"); return }
        guard let isFlagged = dogrunInfo["isFlagged"] as? String else { print("error unwrapping dogrun isFlagged"); return }
        
        var reviewsIDArray = [String]()
        if let reviewsDictionary = dogrunInfo["reviews"] as? [String : Any] {
            for iterReview in reviewsDictionary {
                let reviewID = iterReview.key
                reviewsIDArray.append(reviewID)
                
            }
        }
        
        var rating: Int
        if let averageRating = dogrunInfo["rating"] as? Int {
          rating = averageRating
        } else {
          rating = 0
        }
    
        dogRuns.append(Dogrun(id: dogRunID, name: name, latitude: latitude, longitude: longitude, address: address, isOffLeash: isOffLeash, notes: notes, isHandicap: isHandicap, isFlagged: isFlagged, reviewIDs: reviewsIDArray, rating: rating))
      }
      
      self.dogRuns = dogRuns
      completion()
    })
  }
  
  func getPlaygrounds(completion: @escaping () -> Void) {
    let playgroundRef = ref.child("locations").child("playgrounds")
    
    playgroundRef.observe(.value, with: { snapshot in
      guard let playgroundDict = snapshot.value as? [String : [String : Any]] else { print("error unwrapping playground snapshot"); return }
      var playgrounds = [Playground]()
      
      for (playgroundID, playgroundInfo) in playgroundDict {
        let ID = playgroundID
        guard let locationName = playgroundInfo["name"] as? String else { print("error unwrapping playground name"); return }
        guard let address = playgroundInfo["address"] as? String else { print("error unwrapping playground address"); return }
        guard let latitudeString = playgroundInfo["latitude"] as? String,
          let latitude = Double(latitudeString) else { print("error unwrapping playground latitude"); return }
        guard let longitudeString = playgroundInfo["longitude"] as? String,
          let longitude = Double(longitudeString) else { print("error unwrapping playground longitude"); return }
        guard let isHandicap = playgroundInfo["isHandicap"] as? String else { print("error unwrapping playground isHandicap"); return }
        guard let isFlagged = playgroundInfo["isFlagged"] as? String else { print("error unwrapping playground isFlagged"); return }
        
        var rating: Int
        if let averageRating = playgroundInfo["rating"] as? Int {
          rating = averageRating
        } else {
          rating = 0
        }
        
        let newPlayground = Playground(id: ID, name: locationName, address: address, isHandicap: isHandicap, latitude: latitude, longitude: longitude, reviewIDs: [], rating: rating, photos: [], isFlagged: isFlagged)
        
        var reviewsIDArray = [String]()
        
        if let reviewsDictionary = playgroundInfo["reviews"] as? [String : Any] {
          for iterReview in reviewsDictionary {
            let reviewID = iterReview.key
            reviewsIDArray.append(reviewID)
          }
        }
        
        playgrounds.append(newPlayground)
      }
      
      self.playgrounds = playgrounds
      completion()
    })
  }
}
