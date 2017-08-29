//
//  SliderTableViewCell.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-10.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit

class SliderTableViewCell: UITableViewCell {

    var defaults = UserDefaults.standard
    
    @IBOutlet var radiusLabel: UILabel!
    @IBOutlet var slider: UISlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clear
        
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func setSearchRadius(_ sender: UISlider) {
        
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        let discreteValue = roundf(sender.value)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter = numberFormatter
        
        if isMetric {
            
            // discreteValue is in km
            
            let searchKm = Measurement(value: Double(discreteValue), unit: UnitLength.kilometers)
            let searchMeters = searchKm.converted(to: UnitLength.meters)
            
            let searchToUse = measurementFormatter.string(from: searchMeters)
            let oneReplaced = searchToUse.replacingOccurrences(of: " m", with: "")
            
            if let intVal = Int(oneReplaced) {
                
                defaults.set(intVal, forKey: "searchRadius")
                radiusLabel.text = "\(Int(discreteValue)) km"
                sender.value = discreteValue
                
            }
            
            
        } else {
            
            // discreteValue is in miles
                        
            defaults.set(Int(discreteValue), forKey: "searchRadius")
            radiusLabel.text = "\(Int(discreteValue)) mi"
            sender.value = discreteValue
            
        }
        
    }

}
