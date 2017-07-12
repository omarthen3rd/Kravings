//
//  CategoryTableViewCell.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-10.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit

class CategoryTableViewCell: UITableViewCell {
    
    @IBOutlet var categoryLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
