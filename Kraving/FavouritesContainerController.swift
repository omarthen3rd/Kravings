//
//  FavouritesContainerController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2018-02-19.
//  Copyright © 2018 Omar Abbasi. All rights reserved.
//

import UIKit
import DeviceKit

private let reuseIdentifier = "Cell"

protocol RemoveFromMainArray {
    
    func removeWith(_ indexToRemove: Int, shouldRemoveAll: Bool)
    func removeFromDislikesWith(_ indexToRemove: Int, shouldRemoveAll: Bool)
    
}

enum RestaurantSource {
    
    case likes, longTermFavourites, dislikes
    
}

class FavouritesContainerController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, RemoveFromArray {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var segment: UISegmentedControl!
    @IBOutlet var deleteAllButton: UIButton!
    @IBOutlet var deleteAllButtonView: UIView!
    
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
    
    var searchButton = UIBarButtonItem()
    var closeViewButton = UIBarButtonItem()
    
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
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
        
    }
    
    func setupView() {
        
        searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(openSearchBar))
        closeViewButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissViewThing))
        
        deleteAllButton.addTarget(self, action: #selector(trashHandler), for: .touchUpInside)
        deleteAllButton.backgroundColor = UIColor.flatRed
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.collectionView.backgroundColor = UIColor.clear
        blurEffectView = UIView(frame: collectionView.bounds)
        
        self.collectionView.backgroundView = blurEffectView
        
        resultSearchController.searchBar.delegate = self
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        resultSearchController.searchBar.searchBarStyle = UISearchBarStyle.minimal
        definesPresentationContext = true
        
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
        
        navigationItem.leftBarButtonItems = [editButtonItem, searchButton]
        navigationItem.rightBarButtonItem = closeViewButton
        collectionView.contentOffset = CGPoint(x: 0, y: -150)
        
        fixNavBar()
        
    }
    
    func dismissViewThing() {
        
        dismiss(animated: true, completion: nil)
        
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
        
        noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.collectionView.bounds.width, height: self.collectionView.bounds.height))
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
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.reloadData()
            }
        }
        
    }
    
    func removeAllDislikes() {
        
        if segment.selectedSegmentIndex == 2 {
            
            // only run if "Dislikes" is selected in UISegmentedControl
            if let del = removeDelegate {
                self.restaurants.removeAll()
                del.removeFromDislikesWith(0, shouldRemoveAll: true)
                indexChanged(segment)
            }
            
        }
        
        defaults.set(nil, forKey: "dislikes")
        defaults.synchronize()
        
        indexChanged(segment)
        
    }
    
    func removeAllLongTermFavourites() {
        
        defaults.set(nil, forKey: "favourites")
        defaults.synchronize()
        
        indexChanged(segment)
        
    }
    
    func callRemoveDelegate() {
        
        // for removing from sessions likes in Favourites controller
        
        if segment.selectedSegmentIndex == 0 {
            
            // only run if "Session" is selected in UISegmentedControl
            if let del = removeDelegate {
                self.likes.removeAll()
                del.removeWith(0, shouldRemoveAll: true)
                indexChanged(segment)
            }
            
        }
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        collectionView.isUserInteractionEnabled = !editing
        searchButton.isEnabled = !editing
        closeViewButton.isEnabled = !editing
        segment.isEnabled = !editing
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
    
    func trashHandler() {
        
        var title = String()
        var message = String()
        
        switch self.arrSource {
            
        case .dislikes:
            title = "Delete All Dislikes"
            message = "Would you like to delete all dislikes?"
            
        case .likes:
            title = "Delete All Session Favourites"
            message = "Would you like to delete all session favourites?"
            
        case .longTermFavourites:
            title = "Delete All Long Term Favourites"
            message = "Would you like to delete all long term favourites?"
            
        }
        
        let trashAlert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete All", style: .destructive) { (_) in
            
            switch self.arrSource {
                
            case .dislikes:
                self.removeAllDislikes()
            
            case .likes:
                self.callRemoveDelegate()
            
            case .longTermFavourites:
                self.removeAllLongTermFavourites()
                
            }
            
            self.setEditing(false, animated: true) // to go back to non editing mode
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        trashAlert.addAction(deleteAction)
        trashAlert.addAction(cancelAction)
        present(trashAlert, animated: true, completion: nil)
        
    }
    
    func fixNavBar() {
        
        for view: UIView in (navigationController?.navigationBar.subviews)! {
            for view2: UIView in view.subviews {
                if (view2 is UIImageView) {
                    view2.removeFromSuperview()
                }
            }
        }

        
    }
    
    // Search bar func
    
    func openSearchBar() {
        
        UIView.animate(withDuration: 0.4) {
            
            self.resultSearchController.searchBar.setShowsCancelButton(true, animated: true)
            self.resultSearchController.searchBar.sizeToFit()
            
            DispatchQueue.main.async {
                self.resultSearchController.searchBar.becomeFirstResponder()
            }
            self.navigationItem.leftBarButtonItems = nil
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.titleView = self.resultSearchController.searchBar
            self.navigationController?.navigationBar.sizeToFit()
            self.segment.isEnabled = !self.resultSearchController.isActive
            
            // By default the navigation bar hides when presenting the
            // search interface.  Obviously we don't want this to happen if
            // our search bar is inside the navigation bar.
            self.resultSearchController.hidesNavigationBarDuringPresentation = false
            
        }
        
    }
    
    func filterContentForSearchText(searchText: String) {
        
        filteredRestaurants = restaurants.filter({ (restaurant) -> Bool in
            return restaurant.name.lowercased().contains(searchText.lowercased())
        })
        self.collectionView.reloadData()
        
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
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.reloadData()
            }
        case 1:
            // long term favourites
            self.arrSource = .longTermFavourites
            self.restaurants.removeAll()
            DispatchQueue.main.async {
                self.loadLongTermFavourites()
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.reloadData()
            }
        case 2:
            // dislikes
            self.arrSource = .dislikes
            self.restaurants.removeAll()
            DispatchQueue.main.async {
                self.loadDislikes()
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.reloadData()
            }
        default:
            break
        }
        
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if restaurants.count > 0 {
            
            loadSadView("")
            self.editButtonItem.isEnabled = true
            self.searchButton.isEnabled = true
            self.deleteAllButtonView.isHidden = !isEditing
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
            
            self.editButtonItem.isEnabled = isEditing
            self.deleteAllButtonView.isHidden = !isEditing
            
            self.loadSadView(message)
            return 0
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if resultSearchController.isActive {
            return filteredRestaurants.count
        } else {
            return restaurants.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FavouritesCollectionViewCell
        
        let favourite: Restaurant
        
        favourite = resultSearchController.isActive ? filteredRestaurants[indexPath.row] : restaurants[indexPath.row]
        
        cell.restaurant = favourite
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if device.systemVersion < "11.0" {
            // make cells show a bit lower because of navigation bar height (< iOS 11)
            return UIEdgeInsets(top: 10, left: 1.0, bottom: 1.0, right: 1.0)
        } else {
            // make cells show a bit lower because of navigation bar height (> iOS 11)
            return UIEdgeInsets(top: 10, left: 1.0, bottom: 1.0, right: 1.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 32, height: 220)
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "favouriteDetail" {
            
            if let currentCell = sender as? FavouritesCollectionViewCell, let indexPath = self.collectionView.indexPath(for: currentCell) {
                
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
                destVC.shouldHideStatus = true
                
            }
            
        }
        
    }

}

extension FavouritesContainerController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        UIView.animate(withDuration: 0.4) {
            
            searchBar.resignFirstResponder()
            self.navigationItem.titleView = nil
            self.navigationItem.leftBarButtonItems = [self.editButtonItem, self.searchButton]
            self.navigationItem.rightBarButtonItem = self.closeViewButton
            self.navigationController?.navigationBar.sizeToFit()
            self.segment.isEnabled = !self.resultSearchController.isActive
            
        }
        
    }
    
}
