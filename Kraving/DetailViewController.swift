//
//  DetailViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2018-03-24.
//  Copyright © 2018 Omar Abbasi. All rights reserved.
//

import UIKit

internal class DetailViewController: UIViewController {
    
    var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light ))
    var detailView: UIView?
    var scrollView = UIScrollView()
    var originalFrame = CGRect.zero
    var snap = UIView()
    var card: RestaurantCardView!
    var delegate: CardDelegate?
    var isFullscreen = false
    
    override var prefersStatusBarHidden: Bool {
        if isFullscreen { return true }
        else { return false }
    }
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        self.snap = UIScreen.main.snapshotView(afterScreenUpdates: true)
        self.view.addSubview(blurView)
        self.view.addSubview(scrollView)
        
        if let detail = detailView {
            
            scrollView.addSubview(detail)
            detail.alpha = 0
            detail.autoresizingMask = .flexibleWidth
        }
        
        blurView.frame = self.view.bounds
        
        scrollView.layer.backgroundColor = detailView?.backgroundColor?.cgColor ?? UIColor.white.cgColor
        scrollView.layer.cornerRadius = isFullscreen ? 0 :  20
        
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        blurView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissVC)))
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        scrollView.addSubview(card.stuffContainer)
        self.delegate?.cardDidShowDetailView?(card: self.card)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        originalFrame = scrollView.frame
        
        view.insertSubview(snap, belowSubview: blurView)
        
        if let detail = detailView {
            
            detail.alpha = 1
            detail.frame = CGRect(x: 0,
                                  y: card.stuffContainer.bounds.maxY,
                                  width: scrollView.frame.width,
                                  height: detail.frame.height)
            
            scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: detail.frame.maxY)
            
            
        }
        
        self.delegate?.cardDidShowDetailView?(card: self.card)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.delegate?.cardDidCloseDetailView?(card: self.card)
        detailView?.alpha = 0
        snap.removeFromSuperview()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.delegate?.cardDidCloseDetailView?(card: self.card)
    }
    
    
    //MARK: - Layout & Animations for the content ( rect = Scrollview + card + detail )
    
    func layout(_ rect: CGRect, isPresenting: Bool, isAnimating: Bool = true, transform: CGAffineTransform = CGAffineTransform.identity){
        
        guard isPresenting else {
            
            scrollView.frame = rect.applying(transform)
            card.stuffContainer.frame = scrollView.bounds
            card.layout(animating: isAnimating)
            return
        }
        
        if isFullscreen {
            
            scrollView.frame = view.bounds
            scrollView.frame.origin.y = 0
            print(scrollView.frame)
            
        } else {
            scrollView.frame.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 20)
            scrollView.center = blurView.center
            scrollView.frame.origin.y = 40
        }
        
        scrollView.frame = scrollView.frame.applying(transform)
        
        card.stuffContainer.frame.origin = scrollView.bounds.origin
        card.stuffContainer.frame.size = CGSize( width: scrollView.bounds.width,
                                               height: card.stuffContainer.bounds.height)
        card.layout(animating: isAnimating)
        
    }
    
    
    //MARK: - Actions
    
    @objc func dismissVC(){
        scrollView.contentOffset.y = 0
        dismiss(animated: true, completion: nil)
    }
}


//MARK: - ScrollView Behaviour

extension DetailViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let y = scrollView.contentOffset.y
        let origin = originalFrame.origin.y
        let currentOrigin = originalFrame.origin.y
        
        if (y<0  || currentOrigin > origin) {
            scrollView.frame.origin.y -= y/2
            
            scrollView.contentOffset.y = 0
        }
        
        // card.delegate?.cardDetailIsScrolling?(card: card)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let origin = originalFrame.origin.y
        let currentOrigin = scrollView.frame.origin.y
        let max = 4.0
        let min = 2.0
        var speed = Double(-velocity.y)
        
        if speed > max { speed = max }
        if speed < min { speed = min }
        
        //self.bounceIntensity = CGFloat(speed-1)
        speed = (max/speed*min)/10
        
        guard (currentOrigin - origin) < 60 else { dismiss(animated: true, completion: nil); return }
        UIView.animate(withDuration: speed) { scrollView.frame.origin.y = self.originalFrame.origin.y }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        UIView.animate(withDuration: 0.1) { scrollView.frame.origin.y = self.originalFrame.origin.y }
    }
    
}
