//
//  CustomCell.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/21.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import UIKit
import Foundation

class CustomCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var address: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
