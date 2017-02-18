//
//  CustomCellWithButtonsIncomingCell.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/17.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import Foundation
import JSQMessagesViewController


class CustomCellWithButtonsIncomingCell: JSQMessagesCollectionViewCellIncoming {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.left
        self.cellBottomLabel.textAlignment = NSTextAlignment.left
    }
    
    override class func nib() -> UINib {
        return UINib(nibName: "CustomCellWithButtonsIncomingCell", bundle: nil)
    }
    
    override class func cellReuseIdentifier() -> String {
        return "CustomCellWithButtonsIncomingCell"
    }

    func setupForMessage(reply: JSQMessage, candidates: [String]) {
        let button = UIButton(frame: CGRect(x: 0, y: 30, width: 50, height: 30))
        button.setTitle("Button 1", for: .normal)
        button.backgroundColor = UIColor.purple
        //buttonView.addSubview(button)
        //messageView.text = reply.text
        print("add bubble")
    }
    

}

