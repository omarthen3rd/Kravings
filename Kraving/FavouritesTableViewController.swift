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
    
    override func didMoveToSuperview() {
        self.layoutIfNeeded()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutIfNeeded()
    }
    
}

class FavouritesTableViewController: UITableViewController, UISearchBarDelegate {
    
    var favourites = [Restaurant]()
    var favouritesFiltered = [Restaurant]()
    var blurEffectView = UIVisualEffectView()
    var noDataLabel = UILabel()
    let defaults = UserDefaults.standard
    
    var resultSearchController = UISearchController(searchResultsController: nil)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        self.tableView.estimatedRowHeight = UITableViewAutomaticDimension
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        if traitCollection.forceTouchCapability == .available {
            
            registerForPreviewing(with: self, sourceView: tableView)
            
        }
        
        setupView()
        loadFavourites()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func setupView() {
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        self.tableView.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: .extraLight)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: UIBlurEffectStyle.regular))
        
        self.tableView.backgroundView = blurEffectView
        
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        resultSearchController.searchBar.searchBarStyle = UISearchBarStyle.minimal
        definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = resultSearchController
        } else {
            let searchOffset = CGPoint(x: 0, y: 44)
            tableView.setContentOffset(searchOffset, animated: false)
            tableView.tableHeaderView = resultSearchController.searchBar
        }
        
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
        noDataLabel.font = UIFont.systemFont(ofSize: 40, weight: UIFontWeightLight)
        noDataLabel.text = "No Favourites"
        noDataLabel.textColor = UIColor.black
        noDataLabel.textAlignment = .center
        self.tableView.separatorColor = UIColor.clear
        self.tableView.separatorEffect = nil
        self.blurEffectView.contentView.addSubview(noDataLabel)
        // self.tableView.backgroundView = noDataLabel
        
    }
    
    // Search bar func
    
    func filterContentForSearchText(searchText: String) {
        
        favouritesFiltered = favourites.filter({ (restaurant) -> Bool in
            return restaurant.name.lowercased().contains(searchText.lowercased())
        })
        self.tableView.reloadData()
        
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
     
        if resultSearchController.isActive {
            return favouritesFiltered.count
        } else {
            return favourites.count
        }
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FavouritesCell
        
        let favourite: Restaurant
        
        if resultSearchController.isActive {
            favourite = favouritesFiltered[indexPath.row]
        } else {
            favourite = favourites[indexPath.row]
        }
        
        cell.restaurantTitle?.text = favourite.name
        cell.restaurantStars.rating = Double(favourite.rating)
        cell.restaurantStars.text = "\(favourite.reviewCount)" + " VOTES"
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let newSelectedView = UIVisualEffectView(effect: blurEffect)
        newSelectedView.frame = cell.bounds
        
        cell.selectedBackgroundView = newSelectedView
        
        let img = favourite.image
        
        cell.restaurantImage.image = img
        cell.restaurantImage.clipsToBounds = true
        cell.restaurantImage.layer.cornerRadius = 5
        
        cell.layoutSubviews()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let del = UITableViewRowAction(style: .destructive, title: "Delete") { (action, index) in
            
            if self.resultSearchController.isActive {
                
                let favIndex = self.favourites.index(of: self.favouritesFiltered[indexPath.row])
                if let intIndex = favIndex as? Int {
                    self.favourites.remove(at: intIndex)
                }
                
            } else {
                
                self.favourites.remove(at: indexPath.row)
                
            }
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.favourites)
            self.defaults.set(encodedData, forKey: "favourites")
            self.defaults.synchronize()
            
            DispatchQueue.main.async {
                
                self.tableView.reloadData()
                
            }
            
        }
        
        return [del]
        
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
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
        
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "FavouritesDetailContainerViewController") as? FavouritesDetailContainerViewController else { return nil }
        
        let favDetail = favourites[indexPath.row]
        detailVC.restaurant = favDetail
        previewingContext.sourceRect = cell.frame
        
        return detailVC
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        
    }
    
}

extension FavouritesTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
}
