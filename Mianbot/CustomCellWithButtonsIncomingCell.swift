//
//  CustomCellWithButtonsIncomingCell.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/17.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import Foundation
import JSQMessagesViewController

protocol buttonActionDelegate: class {
    func candidateButtonTapped(candidate: String)
}

class CustomCellWithButtonsIncomingCell: JSQMessagesCollectionViewCellIncoming {
    
    weak var buttonDelegate: buttonActionDelegate?
    
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
        var offset: Int = 40
        for i in 0...candidates.count-1 {
            let button = UIButton(frame: CGRect(x: offset, y: 0, width: candidates[i].characters.count*25, height: 30))
            button.setTitle(candidates[i], for: .normal)
            button.setTitleColor(UIColor(red: 10/255, green:180/255, blue: 230/255, alpha: 1.0), for: .normal)
            button.backgroundColor = .clear
            button.layer.cornerRadius = 5
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red: 10/255, green:180/255, blue: 230/255, alpha: 1.0).cgColor
            button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            self.addSubview(button)
            
            offset += candidates[i].characters.count*25 + 5
        }
    }
    
    func buttonAction(sender: UIButton!) {
        self.buttonDelegate?.candidateButtonTapped(candidate: sender.currentTitle!)
    }
}

