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

protocol RemoveFromMainArray {
    
    func removeWith(_ indexToRemove: Int)
    
}

class FavouritesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RemoveFromArray {
    
    var longTermFavourites = [Restaurant]()
    var longTermFavouritesFiltered = [Restaurant]()
    
    var likes = [Restaurant]()
    var likesFiltered = [Restaurant]()
    
    var blurEffectView = UIVisualEffectView()
    var noDataLabel = UILabel()
    let defaults = UserDefaults.standard
    var labelCount = 0
    
    var removeDelegate: RemoveFromMainArray?
    var indexToRemove: Int?
    let device = Device()
    
    var resultSearchController = UISearchController(searchResultsController: nil)
    var segment = UISegmentedControl()
    
    var searchButton = UIBarButtonItem()
    var closeBtn = UIBarButtonItem()
    
    var shouldChangeToLongTerm = false
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if segment.selectedSegmentIndex == 0 {
            
            // only run if "Session" is selected in UISegmentedControl
            guard let index = indexToRemove else { return }
            
            if let del = removeDelegate {
                del.removeWith(index)
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        setupView()
        loadLongTermFavourites()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            self.loadLongTermFavourites()
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
        
        segment = UISegmentedControl(items: ["Session", "Long Term"])
        segment.sizeToFit()
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
        
        self.navigationItem.titleView = segment
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = resultSearchController
        } else {
            navigationItem.prompt = "Favourites"
            navigationItem.leftBarButtonItem = searchButton
            collectionView?.contentOffset = CGPoint(x: 0, y: -150)
        }
        
    }
    
    func loadLongTermFavourites() {
        
        let favouritesExist = defaults.object(forKey: "favourites") != nil
        
        if favouritesExist {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    self.longTermFavourites = decodedRestaurants
                    
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
            for subView in blurEffectView.contentView.subviews {
                subView.removeFromSuperview() // to remove all the labels
            }

        } else {
            if !noDataLabel.isDescendant(of: blurEffectView) {
                // if doesn't exist already, run this
                for subView in blurEffectView.contentView.subviews {
                    // but remove anything just in case
                    subView.removeFromSuperview() // to remove all the labels
                }
                // numberOfSections is run multiple times, label is added multiple times
                self.blurEffectView.contentView.addSubview(noDataLabel)
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
        
        if shouldChangeToLongTerm {
            
            longTermFavouritesFiltered = longTermFavourites.filter({ (restaurant) -> Bool in
                return restaurant.name.lowercased().contains(searchText.lowercased())
            })
            self.collectionView?.reloadData()
            
        } else {
            
            likesFiltered = likes.filter({ (restaurant) -> Bool in
                return restaurant.name.lowercased().contains(searchText.lowercased())
            })
            self.collectionView?.reloadData()
            
        }
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "favouriteDetail" {
            
            if let currentCell = sender as? FavouritesCollectionViewCell, let indexPath = self.collectionView?.indexPath(for: currentCell) {
                
                let destVC = segue.destination as! RestaurantDetailContainerController
                
                var favourite: Restaurant
                
                if resultSearchController.isActive {
                    
                    if shouldChangeToLongTerm {
                        favourite = longTermFavouritesFiltered[indexPath.row]
                    } else {
                        favourite = likesFiltered[indexPath.row]
                    }
                    
                } else {
                    
                    if shouldChangeToLongTerm {
                        favourite = longTermFavourites[indexPath.row]
                    } else {
                        favourite = likes[indexPath.row]
                    }
                    
                }
                
                destVC.restaurant = favourite
                destVC.removeDelegate = self
                destVC.shouldHideStatus = false
                
            }
            
        }
        
    }

    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if shouldChangeToLongTerm {
            
            if longTermFavourites.count > 0 {
                
                loadSadView("")
                return 1
                
            } else {
                
                loadSadView("No Long Term Favourites Yet")
                return 0
                
            }
            
        } else {
            
            if likes.count > 0 {
                
                loadSadView("")
                return 1
                
            } else {
                
                loadSadView("No Favourites In This Session")
                return 0
                
            }
            
        }
        
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if resultSearchController.isActive {
            if shouldChangeToLongTerm {
                return longTermFavouritesFiltered.count
            } else {
                return likesFiltered.count
            }
        } else {
            if shouldChangeToLongTerm {
                return longTermFavourites.count
            } else {
                return likes.count
            }
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FavouritesCollectionViewCell
        
        let favourite: Restaurant
        
        if resultSearchController.isActive {
            
            if shouldChangeToLongTerm {
                favourite = longTermFavouritesFiltered[indexPath.row]
            } else {
                favourite = likesFiltered[indexPath.row]
            }
            
        } else {
            
            if shouldChangeToLongTerm {
                favourite = longTermFavourites[indexPath.row]
            } else {
                favourite = likes[indexPath.row]
            }
            
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
            shouldChangeToLongTerm = false
            DispatchQueue.main.async {
                self.collectionView?.collectionViewLayout.invalidateLayout()
                self.collectionView?.reloadData()
            }
        case 1:
            // long term favourites
            shouldChangeToLongTerm = true
            DispatchQueue.main.async {
                self.loadLongTermFavourites()
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
        navigationItem.leftBarButtonItem = searchButton
        
    }
    
}
