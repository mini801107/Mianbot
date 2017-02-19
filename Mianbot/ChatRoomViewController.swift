//
//  ChatRoomViewController.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/15.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import UIKit
import MapKit
import Foundation
import RxSwift
import Alamofire
import SwiftyJSON
import JSQMessagesViewController



class ChatRoomViewController: JSQMessagesViewController, buttonActionDelegate {
    
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor(red: 10/255, green:180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.lightGray)
    var messages = [JSQMessage]()
    var sessionID: String = ""
    var token: String = ""
    var frontID: String = ""
    var isMessageWithButton = [Bool]()
    var linkInReply = [String]()
    var linkKeyword = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        setup()
        linkInReply.append("")
        linkKeyword.append("")
        isMessageWithButton.append(false)
        sendMessage(msg: "您好，我是Mianbot。\n請問需要什麼服務呢？")
        
        login() { response in
            self.sessionID = response
            print("sessionID = \(self.sessionID)")
        }
        
        getToken() { response in
            self.token = response
            print("token = \(self.token)")
        }
        
        
        self.incomingCellIdentifier = CustomCellWithButtonsIncomingCell.cellReuseIdentifier()
        self.collectionView!.register(CustomCellWithButtonsIncomingCell.nib(), forCellWithReuseIdentifier: CustomCellWithButtonsIncomingCell.cellReuseIdentifier())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
        
        print("[messages]\n\(messages)")
        print("[isMessageWithButton]\n\(isMessageWithButton)")
        print("[linkInReply]\n\(linkInReply)")
        print("[linkKeyword]\n\(linkKeyword)")
        print("--------------------------------------------------------------------------------")
      
    }
    
    // MARK :- JSQMessagesCollectionView Data Source
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let data = messages[indexPath.row]
        return data
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        messages.remove(at: indexPath.row)
        isMessageWithButton.remove(at: indexPath.row)
        print("delete")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return outgoingBubble
        default:
            return incomingBubble
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //For URL link in UITextView
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.textView.dataDetectorTypes = UIDataDetectorTypes.all
        
        /*if isMessageWithButton[indexPath.row] {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCellWithButtonsIncomingCell.cellReuseIdentifier(), for: indexPath) as! CustomCellWithButtonsIncomingCell
            let candidatesArr = messages[indexPath.row].text.components(separatedBy: "#")
            cell.setupForMessage(candidates: candidatesArr)
            cell.buttonDelegate = self
            print("In isMessageWithButton, call setupForMesage, indexPath.row=\(indexPath.row)")
            
            return cell
        }*/
        
        if (linkInReply.isEmpty == false) && (linkInReply[indexPath.row] != "") {
            let reply = messages[indexPath.row].text!
            if let range = reply.range(of: linkKeyword[indexPath.row]) {
                let startPos = reply.distance(from: reply.startIndex, to: range.lowerBound)
                let endPos = reply.distance(from: reply.startIndex, to: range.upperBound)
    
                let attributedString = NSMutableAttributedString(string: reply)
                attributedString.addAttribute(NSLinkAttributeName, value: linkInReply[indexPath.row], range: NSRange(location: startPos, length: endPos-startPos))
                attributedString.addAttributes([NSForegroundColorAttributeName: UIColor.white], range: NSRange(location: 0, length: reply.characters.count))
                attributedString.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], range: NSRange(location: 0, length: reply.characters.count))

                cell.textView.attributedText = attributedString
            }
        }
        
        return cell
    }
    
    // MARK :- JSQMessagesToolbarContentView Toolbar
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        messages.append(message!)
        isMessageWithButton.append(false)
        linkInReply.append("")
        linkKeyword.append("")
        finishSendingMessage()
        reloadMessagesView()
        replyMessage(incomingMessage: message!)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
    }
    
}

extension ChatRoomViewController {
    func setup() {
            self.senderId = UIDevice.current.identifierForVendor?.uuidString
            self.senderDisplayName = UIDevice.current.identifierForVendor?.uuidString
    }
    
    func sendMessage(msg: String) {
        let message = JSQMessage(senderId: "Mainbot", displayName: "Mainbot", text: msg)
        messages.append(message!)
        reloadMessagesView()
    }
    
    func sendButton(btn: String) {
        let btnMessage = JSQMessage(senderId: "Mainbot", displayName: "Mainbot", text: btn)
        messages.append(btnMessage!)
        isMessageWithButton.append(true)
        linkInReply.append("")
        linkKeyword.append("")
        reloadMessagesView()
    }
    
    func replyMessage(incomingMessage: JSQMessage) {
        getResponse(msg: incomingMessage.text, taskId: frontID) { response in
            let JSONData = response.data(using: String.Encoding.utf8)
            let json = JSON(data: JSONData!)
            var additionalBtn: String = ""
            
            if json["ID"].stringValue != "" {
                self.frontID = json["ID"].stringValue
            }
            else { self.frontID = "" }
            
            if json["candidant"].stringValue != "" {
                additionalBtn = json["candidant"].stringValue
            }
            self.isMessageWithButton.append(false)
            
            var reply = json["reply"].stringValue
            reply = json["reply"].stringValue
            if reply.range(of: "<a href=\"") != nil {
                let arr = reply.components(separatedBy: ["<", "\"", ">"])
                self.linkInReply.append(arr[2])
                self.linkKeyword.append(arr[6])
                reply = arr[0] + arr[6] + arr[8]
            }
            else {
                self.linkInReply.append("")
                self.linkKeyword.append("")
            }
            
            if json["suggest"].stringValue != "" {
                let suggest = json["suggest"].stringValue
                if suggest.range(of: "<a href=\"") != nil {
                    let arr = suggest.components(separatedBy: "\"")
                    let url = arr[1]
                    reply += "\n\(url)"
                }
            }
            
            if json["target"].stringValue != "" {
                let target = json["target"].stringValue
                let lng = json["longitude"].stringValue
                let lat = json["latitude"].stringValue
                
                self.nearbyPlaces(keyword: target, lat: lat, lng: lng) { response in
                
                }
                
            }
        
            self.sendMessage(msg: reply)
            if additionalBtn != "" {
                self.sendButton(btn: additionalBtn)
            }
        }
    }
    
    // MARK :- Alamofire HTTP Requests
    //Login and fetch session cookie
    func login(completion:@escaping (String) -> Void) {
        let par = ["account": "appuser", "password": "app123"]
        Alamofire.request("http://140.116.245.146:8080/chatbot_login/", method: .post, parameters: par)
            .validate()
            .responseString{ response in
                let headers = response.response?.allHeaderFields
                let set_cookie_str: String? = String(describing: headers?["Set-Cookie"])
                if set_cookie_str == "nil" {
                    print("Failed to login")
                    completion("failed")
                    return
                }
                let split_arr = set_cookie_str!.components(separatedBy: ";")
                let sessionID = split_arr[0].components(separatedBy: "=")[1]
                completion(sessionID)
        }
    }
    
    //Get csrf token
    func getToken(completion:@escaping (String) -> Void) {
        Alamofire.request("http://140.116.245.146:8080/question_data/", method: .get)
            .validate()
            .responseString{ response in
                let headers = response.response?.allHeaderFields
                let set_cookie_str: String? = String(describing: headers?["Set-Cookie"])
                if set_cookie_str == "nil" {
                    print("Failed to get token")
                    completion("failed")
                    return
                }
                
                let split_arr = set_cookie_str!.components(separatedBy: ";")
                let token = split_arr[0].components(separatedBy: "=")[1]
                completion(token)
        }
    }
    
    //Get question data
    func getResponse(msg: String, taskId: String, completion:@escaping (String) -> Void) {
        let par = ["content" : msg, "frontId": taskId]
        let header = [ "Cookie" : "sessionid="+sessionID+" ;csrftoken="+token ]
        Alamofire.request("http://140.116.245.146:8080/question_data/", method: .post, parameters: par, headers: header)
            .validate()
            .responseString{ response in
                let str = String(response.result.value!)
                print(str)
                completion(str!)
        }
    }
    
    //Google map nearby places
    func nearbyPlaces(keyword: String, lat: String, lng: String, completion: @escaping (String) -> Void) {
        let url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyCqELCql4e0HM-0yA177TrtHZpoDqzcs2o&language=zh-TW&rankby=distance&location=\(lat),\(lng)&keyword=\(keyword)"
        print(url)
        
        Alamofire.request(url, method: .get)
            .validate()
            .responseString{ response in
                let str = String(response.result.value!)
                print(response.result)
                //completion(str!)

        }
    }
    
    func candidateButtonTapped(candidate: String){
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: messages.last?.date, text: candidate)
        //add reply user choosed
        messages.append(message!)
        isMessageWithButton.append(false)
        linkInReply.append("")
        linkKeyword.append("")
        reloadMessagesView()
        replyMessage(incomingMessage: message!)
    }
   
}




