//
//  MessageTableViewCell.swift
//  BLEtest
//
//  Created by 0xq haun on 2022/01/28.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var messageLabel: UILabel!
    
    let messages=""
    
    override func awakeFromNib() {
        super.awakeFromNib()
      
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    //セルに表示
    func setmessage(){
        messageLabel.text=messages
    }
    
}
