//
//  PhotosTableViewCell.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-09-16.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit

class PhotosTableViewCell: UITableViewCell {

    @IBOutlet var photo1: UIImageView!
    @IBOutlet var photo2: UIImageView!
    @IBOutlet var photo3: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = UIColor.clear
        
        self.photo1.layer.cornerRadius = 6
        self.photo2.layer.cornerRadius = 6
        self.photo3.layer.cornerRadius = 6
        
        self.photo1.clipsToBounds = true
        self.photo2.clipsToBounds = true
        self.photo3.clipsToBounds = true
        
        self.photo1.contentMode = .scaleAspectFill
        self.photo2.contentMode = .scaleAspectFill
        self.photo3.contentMode = .scaleAspectFill
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
