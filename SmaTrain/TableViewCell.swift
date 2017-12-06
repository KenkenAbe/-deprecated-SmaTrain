//
//  TableViewCell.swift
//  SmaTrain
//
//  Created by KentaroAbe on 2017/12/02.
//  Copyright © 2017年 KentaroAbe. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    @IBOutlet var destination: UILabel!
    
    @IBOutlet var trainType: UILabel!
    
    @IBOutlet var depTime: UILabel!
    
    @IBOutlet var trainInfo: UILabel!
    
    @IBOutlet var through: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
