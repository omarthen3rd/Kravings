//
//  FavouritesViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-12-16.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import DeviceKit

private let reuseIdentifier = "Cell"

class FavouritesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RemoveFromArray {
    
    var likes = [Restaurant]()
    
    var restaurants = [Restaurant]()
    var filteredRestaurants = [Restaurant]()
    
    var blurEffectView = UIView()
    var noDataLabel = UILabel()
    let defaults = UserDefaults.standard
    
    var removeDelegate: RemoveFromMainArray?
    var indexToRemove: Int?
    let device = Device()
    var arrSource: RestaurantSource = .likes
    
    var resultSearchController = UISearchController(searchResultsController: nil)
    var segment = UISegmentedControl()
    
    var searchButton = UIBarButtonItem()
    
    @IBAction func closeBtn(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if segment.selectedSegmentIndex == 0 {
            
            // only run if "Session" is selected in UISegmentedControl
            guard let index = indexToRemove else { return }
            
            if let del = removeDelegate {
                del.removeWith(index, shouldRemoveAll: false)
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        setupView()
        loadLikes()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            // self.loadLikes()
            // self.loadLongTermFavourites()
            // self.loadDislikes()
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.collectionView?.reloadData()
        }
        
    }
    
    // MARK: - Functions
    
    func setupView() {
        
        searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(openSearchBar))
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.collectionView?.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: .extraLight)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        self.collectionView?.backgroundView = blurEffectView
        
        resultSearchController.searchBar.delegate = self
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        resultSearchController.searchBar.searchBarStyle = UISearchBarStyle.minimal
        definesPresentationContext = true
        
        segment = UISegmentedControl(items: ["Session", "Long Term", "Dislikes"])
        segment.sizeToFit()
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
        
        navigationItem.leftBarButtonItem = searchButton
        collectionView?.contentOffset = CGPoint(x: 0, y: -150)
        
    }
    
    func loadLikes() {
        
        self.restaurants = likes
        
    }
    
    func loadLongTermFavourites() {
        
        let favouritesExist = defaults.object(forKey: "favourites") != nil
        
        if favouritesExist {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    // restaurant arr is now longTermFavourites
                    self.restaurants = decodedRestaurants
                    
                }
                
            }
            
        }
        
    }
    
    func loadDislikes() {
        
        let dislikesExist = defaults.object(forKey: "dislikes") != nil
        
        if dislikesExist {
            
            if let decodedArr = defaults.object(forKey: "dislikes") as? Data {
                
                if let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    // restaurant arr is now dislikes
                    self.restaurants = decodedRestaurants
                    
                }
                
            }
            
        }
        
    }
    
    func loadSadView(_ message: String) {
        
        noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: (self.collectionView?.bounds.width)!, height: (self.collectionView?.bounds.height)!))
        noDataLabel.font = UIFont.systemFont(ofSize: 40, weight: UIFontWeightLight)
        noDataLabel.text = message
        noDataLabel.numberOfLines = 0
        noDataLabel.textColor = UIColor.black
        noDataLabel.textAlignment = .center
        
        if message == "" {
            
            for subView in blurEffectView.subviews {
                subView.removeFromSuperview() // to remove all the labels
            }

        } else {
            if !noDataLabel.isDescendant(of: blurEffectView) {
                // if doesn't exist already, run this
                for subView in blurEffectView.subviews {
                    // but remove anything just in case
                    subView.removeFromSuperview() // to remove all the labels
                }
                // numberOfSections is run multiple times, label is added multiple times
                self.blurEffectView.addSubview(noDataLabel)
            }
        }
        
    }
    
    func removeFromArrayWith(_ restaurant: Restaurant) {
        
        let index = self.likes.index(of: restaurant)
        
        if let index = index {
            self.indexToRemove = index
            self.likes.remove(at: index)
            DispatchQueue.main.async {
                self.collectionView?.collectionViewLayout.invalidateLayout()
                self.collectionView?.reloadData()
            }
        }
        
    }
    
    // Search bar func
    
    func openSearchBar() {
        
        resultSearchController.searchBar.setShowsCancelButton(true, animated: true)
        resultSearchController.searchBar.sizeToFit()
        
        DispatchQueue.main.async {
            self.resultSearchController.searchBar.becomeFirstResponder()
        }
        navigationItem.titleView = resultSearchController.searchBar
        navigationItem.leftBarButtonItem = nil
        
        // By default the navigation bar hides when presenting the
        // search interface.  Obviously we don't want this to happen if
        // our search bar is inside the navigation bar.
        resultSearchController.hidesNavigationBarDuringPresentation = false
        
    }
    
    func filterContentForSearchText(searchText: String) {
        
        filteredRestaurants = restaurants.filter({ (restaurant) -> Bool in
            return restaurant.name.lowercased().contains(searchText.lowercased())
        })
        self.collectionView?.reloadData()
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "favouriteDetail" {
            
            if let currentCell = sender as? FavouritesCollectionViewCell, let indexPath = self.collectionView?.indexPath(for: currentCell) {
                
                let destVC = segue.destination as! RestaurantDetailController
                
                var favourite: Restaurant
                
                if resultSearchController.isActive {
                    
                    favourite = filteredRestaurants[indexPath.row]
                    
                } else {
                    
                    favourite = restaurants[indexPath.row]
                    
                }
                
                destVC.restaurant = favourite
                destVC.removeDelegate = self
                destVC.restaurantSource = arrSource
                destVC.shouldHideStatus = false
                
            }
            
        }
        
    }

    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if restaurants.count > 0 {
            
            loadSadView("")
            return 1
            
        } else {
            
            var message = ""
            
            switch arrSource {
            case .likes:
                message = "No Favourites In This Session"
                
            case .dislikes:
                message = "No Dislikes Yet"
            
            case .longTermFavourites:
                message = "No Long Term Favourites Yet"
                
            }
            
            self.loadSadView(message)
            return 0
            
        }
        
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if resultSearchController.isActive {
            return filteredRestaurants.count
        } else {
            return restaurants.count
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FavouritesCollectionViewCell
        
        let favourite: Restaurant
        
        if resultSearchController.isActive {
            
            favourite = filteredRestaurants[indexPath.row]
            
        } else {
            
            favourite = restaurants[indexPath.row]
            
        }
        
        cell.restaurant = favourite
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if device.systemVersion < "11.0" {
            // make cells show a bit lower because of navigation bar height (< iOS 11)
            return UIEdgeInsets(top: 120.0, left: 1.0, bottom: 1.0, right: 1.0)
        } else {
            // make cells show a bit lower because of navigation bar height (> iOS 11)
            return UIEdgeInsets(top: 20.0, left: 1.0, bottom: 1.0, right: 1.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 32, height: 220)
        
    }
    
    // MARK: - Segmented Control
    
    func indexChanged(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            // session favourites
            self.arrSource = .likes
            self.restaurants.removeAll()
            DispatchQueue.main.async {
                self.loadLikes()
                self.collectionView?.collectionViewLayout.invalidateLayout()
                self.collectionView?.reloadData()
            }
        case 1:
            // long term favourites
            self.arrSource = .longTermFavourites
            self.restaurants.removeAll()
            DispatchQueue.main.async {
                self.loadLongTermFavourites()
                self.collectionView?.collectionViewLayout.invalidateLayout()
                self.collectionView?.reloadData()
            }
        case 2:
            // dislikes
            self.arrSource = .dislikes
            self.restaurants.removeAll()
            DispatchQueue.main.async {
                self.loadDislikes()
                self.collectionView?.collectionViewLayout.invalidateLayout()
                self.collectionView?.reloadData()
            }
        default:
            break
        }
        
    }

}

extension FavouritesViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        navigationItem.titleView = segment
        if device.systemVersion < "11.0" {
            navigationItem.leftBarButtonItem = searchButton
        }
        
    }
    
}
