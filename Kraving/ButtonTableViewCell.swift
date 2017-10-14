//
//  ButtonTableViewCell.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-09-04.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit

class ButtonTableViewCell: UITableViewCell {

    @IBOutlet var changeAddress: UIButton!
    
    var defaults = UserDefaults.standard
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = UIColor.clear
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
