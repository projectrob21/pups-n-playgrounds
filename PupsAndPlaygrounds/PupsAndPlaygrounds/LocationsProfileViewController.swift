//
//  LocationProfileViewController.swift
//  PupsAndPlaygrounds
//
//  Created by Robert Deans on 11/23/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit
import Firebase


class LocationProfileViewController: UIViewController {
    
    let currentUser = DataStore.shared.user
    
    var playgroundID: String?
    var playground: Location?
    var reviewsArray: [Review?] = []
    
    var locationProfileView: LocationProfileView!
    var reviewsTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let unwrappedLocationID = playgroundID else { print("trouble unwrapping location ID"); return }
        
        FIRClient.getLocation(with: unwrappedLocationID) { (firebaseLocation) in
            self.playground = firebaseLocation
            self.configure()
            
            if let playgroundReviewsIDs = self.playground?.reviewIDs {
                for reviewID in playgroundReviewsIDs {
                    FIRClient.getReview(with: reviewID, completion: { (firebaseReview) in
                        
                        self.reviewsArray.append(firebaseReview)
                        self.locationProfileView.reviewsTableView.reloadData()
                        
                    })
                }
            }
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: Setup ReviewVC Child
    func writeReview() {
        navigationController?.navigationBar.isUserInteractionEnabled = false
        tabBarController?.tabBar.isUserInteractionEnabled = false
        
        let childVC = ReviewViewController()
        childVC.reviewDelegate = self
        
        guard let downcastPlayground = playground as? Playground else { print("trouble casting location as playground"); return }
        
        childVC.location = downcastPlayground
        
        addChildViewController(childVC)
        
        view.addSubview(childVC.view)
        childVC.view.snp.makeConstraints {
            childVC.edgesConstraint = $0.edges.equalToSuperview().constraint
        }
        childVC.didMove(toParentViewController: self)
        
        view.layoutIfNeeded()
    }
    
    func configure() {
        guard let downcastPlayground = playground as? Playground else { print("trouble casting location as playground"); return }
        self.locationProfileView = LocationProfileView(playground: downcastPlayground)
        
        
        if FIRAuth.auth()?.currentUser?.isAnonymous == false {
            self.locationProfileView.submitReviewButton.addTarget(self, action: #selector(writeReview), for: .touchUpInside)
        } else {
            self.locationProfileView.submitReviewButton.addTarget(self, action: #selector(anonymousReviewerAlert), for: .touchUpInside)
        }
        
        let color1 = UIColor(red: 34/255.0, green: 91/255.0, blue: 102/255.0, alpha: 1.0)
        let color2 = UIColor(red: 141/255.0, green: 191/255.9, blue: 103/255.0, alpha: 1.0)
        
        let backgroundGradient = CALayer.makeGradient(firstColor: color1, secondColor: color2)
        
        backgroundGradient.frame = view.frame
        self.view.layer.insertSublayer(backgroundGradient, at: 0)
        
        
        reviewsTableView = locationProfileView.reviewsTableView
        locationProfileView.reviewsTableView.delegate = self
        locationProfileView.reviewsTableView.dataSource = self
        locationProfileView.reviewsTableView.register(LocationReviewTableViewCell.self, forCellReuseIdentifier: "reviewCell")
        locationProfileView.reviewsTableView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        
        
        self.view.addSubview(locationProfileView)
        locationProfileView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func anonymousReviewerAlert() {
        let alert = UIAlertController(title: "Woof! Only users can submit reviews 🐶", message: "Head to profile to set one up!", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func flagButtonTouched(sender: UIButton) {
        let cellContent = sender.superview!
        let cell = cellContent.superview! as! UITableViewCell
        let indexPath = locationProfileView.reviewsTableView.indexPath(for: cell)
        
        if let flaggedReview = reviewsArray[(indexPath?.row)!] {
            
            FIRClient.flagReviewWith(unique: flaggedReview.reviewID, locationID: flaggedReview.locationID, comment: flaggedReview.comment, userID: flaggedReview.userID) {
                let alert = UIAlertController(title: "Success!", message: "You have flagged this comment for review", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                    FIRClient.getVisibleReviews { reviews in
                        self.reviewsArray = reviews
                        self.locationProfileView.reviewsTableView.reloadData()
                    }
                })
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}


extension LocationProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "reviewCell", for: indexPath) as? LocationReviewTableViewCell else { print("error unwrapping cell in user review table view"); return UITableViewCell()}
        
        cell.review = reviewsArray[indexPath.row]
        cell.backgroundColor = UIColor.clear
        
        if let userID = reviewsArray[indexPath.row]?.userID {
            FIRClient.getAnyUser(userID: userID, completion: { (firebaseUser) in
                cell.userNameLabel.text = firebaseUser?.firstName
            })
            
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard let userID = reviewsArray[indexPath.row]?.userID else { print("trouble casting userID");return [] }
        guard let reviewID = reviewsArray[indexPath.row]?.reviewID else { print("trouble casting reviewID");return [] }
        guard let locationID = reviewsArray[indexPath.row]?.locationID else { print("trouble casting locationID");return [] }
        guard let reviewComment = reviewsArray[indexPath.row]?.comment else { print("trouble casting reviewComment"); return [] }
        
        
        if userID == currentUser?.uid {
            
            
            let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
                
                self.reviewsArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                FIRClient.deleteReview(userID: userID, reviewID: reviewID, locationID: locationID) {
                    
                    let alert = UIAlertController(title: "Success!", message: "You have flagged this comment for review", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                        FIRClient.getVisibleReviews { reviews in
                            self.reviewsArray = reviews
                            self.locationProfileView.reviewsTableView.reloadData()
                        }
                    })
                }
            }
            delete.backgroundColor = UIColor.themeCoral
            return [delete]
            
        } else {
            
            let flag = UITableViewRowAction(style: .destructive, title: "Flag") { (action, indexPath) in
                
                self.reviewsArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                FIRClient.flagReviewWith(unique: reviewID, locationID: locationID, comment: reviewComment, userID: userID) {
                    let alert = UIAlertController(title: "Success!", message: "You have flagged this comment for review", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                        FIRClient.getVisibleReviews { reviews in
                            self.reviewsArray = reviews
                            self.locationProfileView.reviewsTableView.reloadData()
                        }
                    })
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
            flag.backgroundColor = UIColor.themeSunshine
            return [flag]
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
}

protocol AddReviewProtocol {
    func addReview(with newReview: Review?)
    func updateRating(with newRating: Float)
}

extension LocationProfileViewController: AddReviewProtocol {
    func addReview(with newReview: Review?) {
        reviewsArray.append(newReview)
    }
    
    func updateRating(with newRating: Float) {
        locationProfileView.starReviews.value = newRating
    }
}

