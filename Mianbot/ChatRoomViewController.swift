//
//  ChatRoomViewController.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/15.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import UIKit
import RxSwift
import Alamofire
import SwiftyJSON
import JSQMessagesViewController


class ChatRoomViewController: JSQMessagesViewController {

    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor(red: 10/255, green:180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.lightGray)
    var messages = [JSQMessage]()
    var sessionID: String = ""
    var token: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        sendMessage(msg: "您好，我是Mianbot。\n請問需要什麼服務呢？")
        
        login() { response in
            self.sessionID = response
            print("sessionID = \(self.sessionID)")
        }
        
        getToken() { response in
            self.token = response
            print("token = \(self.token)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
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
    
    // MARK :- JSQMessagesToolbarContentView Toolbar
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        messages.append(message!)
        finishSendingMessage()
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
                completion(str!)
        }
    }
    
    func replyMessage(incomingMessage: JSQMessage) {
        getResponse(msg: incomingMessage.text, taskId: "") { response in
            let JSONData = response.data(using: String.Encoding.utf8)
            let json = JSON(data: JSONData!)
            let reply = json["reply"].stringValue
            self.sendMessage(msg: reply)
        }
    
    }
    
}









