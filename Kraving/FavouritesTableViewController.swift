//
//  FavouritesTableViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-12.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Cosmos

class FavouritesCell: UITableViewCell {
    
    @IBOutlet var restaurantImage: UIImageView!
    @IBOutlet var restaurantTitle: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    
}

class FavouritesTableViewController: UITableViewController {
    
    var favourites = [Restaurant]()
    var blurEffectView = UIVisualEffectView()
    var noDataLabel = UILabel()
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        if traitCollection.forceTouchCapability == .available {
            
            registerForPreviewing(with: self, sourceView: tableView)
            
        }
        
        addBlur()
        loadFavourites()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func addBlur() {
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        self.tableView.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: .extraLight)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: UIBlurEffectStyle.regular))
        
        self.tableView.backgroundView = blurEffectView
    }
    
    func loadFavourites() {
        
        if defaults.object(forKey: "favourites") == nil {
            
        } else {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    self.favourites = decodedRestaurants
                    
                    DispatchQueue.main.async {
                        
                        self.tableView.reloadData()
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func loadSadView() {
        
        noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.tableView.bounds.height))
        noDataLabel.font = UIFont.systemFont(ofSize: 50, weight: UIFontWeightLight)
        noDataLabel.text = "No Favourites"
        noDataLabel.textColor = UIColor.black
        noDataLabel.textAlignment = .center
        self.tableView.separatorColor = UIColor.clear
        self.tableView.separatorEffect = nil
        self.blurEffectView.addSubview(noDataLabel)
        // self.tableView.backgroundView = noDataLabel
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if favourites.count > 0 {
            
            if self.blurEffectView.subviews.contains(noDataLabel) {
                self.noDataLabel.removeFromSuperview()
            }
            
            return 1
            
        } else {
            
            loadSadView()
            return 0
            
        }
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return favourites.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FavouritesCell
        
        cell.restaurantTitle?.text = favourites[indexPath.row].name
        cell.restaurantStars.rating = Double(favourites[indexPath.row].rating)
        cell.restaurantStars.text = "\(favourites[indexPath.row].reviewCount)" + " VOTES"
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let newSelectedView = UIVisualEffectView(effect: blurEffect)
        newSelectedView.frame = cell.bounds
        
        cell.selectedBackgroundView = newSelectedView
        
        if let url = URL(string: favourites[indexPath.row].imageURL) {
            
            cell.restaurantImage.sd_setImage(with: url)
            cell.restaurantImage.clipsToBounds = true
            cell.restaurantImage.layer.cornerRadius = 5
            
        }
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetail" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let restaurantToSend = favourites[indexPath.row]
                
                let controller = segue.destination as! FavouritesDetailContainerViewController
                
                controller.restaurant = restaurantToSend
                
            }
            
        }
        
    }

}

extension FavouritesTableViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) as? FavouritesCell else {
                return nil
        }
        
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "FavouritesDetailTableViewController") as? FavouritesDetailTableViewController else { return nil }
        
        let favDetail = favourites[indexPath.row]
        detailVC.restaurant = favDetail
        previewingContext.sourceRect = cell.frame
        
        return detailVC
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        
    }
    
}
