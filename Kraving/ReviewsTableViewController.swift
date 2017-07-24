//
//  ReviewsTableViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-16.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class ReviewsTableViewController: UITableViewController {
    
    var currentReviews = [RestaurantReviews]()
    
    var restaurant: Restaurant! {
        
        didSet {
            
            getReviews()
            print("ran this")
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReviews() {
        
        Alamofire.request(restaurant.id).responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                for review in json["reviews"].arrayValue {
                    
                    let rating = review["rating"].intValue
                    let name = review["user"]["name"].stringValue
                    let imageUrl = review["user"]["image_url"].stringValue
                    let reviewText = review["text"].stringValue
                    let timeCreated = review["time_created"].stringValue
                    
                    self.formatDate(timeCreated)
                    
                    let newReview = RestaurantReviews(name: name, rating: rating, imageURL: imageUrl, reviewText: reviewText, reviewTime: timeCreated)
                    self.currentReviews.append(newReview)
                    
                }
                
            }
            
        }
        
    }
    
    func formatDate(_ date: String) {
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-mm-dd HH:MM:SS"
        let dateOutput = inputFormatter.date(from: date)
        
        print(dateOutput)
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currentReviews.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reviewsCell", for: indexPath) as! ReviewsCell

        let currentReview = currentReviews[indexPath.row]

        cell.name.text = currentReview.name
        cell.rating.text = "\(currentReview.rating)"
        cell.textReview.text = currentReview.reviewText
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
