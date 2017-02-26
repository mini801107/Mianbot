//
//  ChatRoomViewController.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/15.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Speech
import Foundation
import Alamofire
import SwiftyJSON
import JSQMessagesViewController


class ChatRoomViewController: JSQMessagesViewController, SFSpeechRecognizerDelegate, buttonActionDelegate {
    
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor(red: 10/255, green:180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.lightGray)
    var messages = [JSQMessage]()
    var sessionID: String = ""
    var token: String = ""
    var frontID: String = ""
    var isMessageWithButton = [Bool]()
    var linkInReply = [String]()
    var linkKeyword = [String]()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-TW"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
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
        
        //Customize toolbar
        self.incomingCellIdentifier = CustomCellWithButtonsIncomingCell.cellReuseIdentifier()
        self.collectionView!.register(CustomCellWithButtonsIncomingCell.nib(), forCellWithReuseIdentifier: CustomCellWithButtonsIncomingCell.cellReuseIdentifier())
    
        self.inputToolbar.contentView.rightBarButtonItemWidth = 50
        self.inputToolbar.contentView.leftBarButtonItemWidth = 30
        self.inputToolbar.contentView.leftBarButtonItem.setImage(UIImage(named: "recoder_stop"), for: .normal)
        self.inputToolbar.contentView.leftBarButtonItem.setImage(UIImage(named: "recoder_tapped"), for: .highlighted)
        self.inputToolbar.contentView.leftBarButtonItem.addTarget(self, action: #selector(recorderTapped), for: .touchUpInside)
        
        //Authorize the speech recognizer
        self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.inputToolbar.contentView.leftBarButtonItem.isEnabled = isButtonEnabled
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
        
        //print("[messages]\n\(messages)")
        //print("[isMessageWithButton]\n\(isMessageWithButton)")
        //print("[linkInReply]\n\(linkInReply)")
        //print("[linkKeyword]\n\(linkKeyword)")
        //print("--------------------------------------------------------------------------------")
      
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
        let data = messages[indexPath.row]
        if data.senderId == self.senderId {
            return nil
        }
        
        let avatar = JSQMessagesAvatarImage(placeholder: UIImage(named: "avatar_bot"))
        return avatar
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
        else if linkKeyword[indexPath.row] == "movie" {
            let reply = messages[indexPath.row].text!
            let movieNameArr = reply.components(separatedBy: "\n")
            let attributedString = NSMutableAttributedString(string: reply)
            for i in 1...movieNameArr.count-1 {
                if let range = reply.range(of: movieNameArr[i]) {
                    let startPos = reply.distance(from: reply.startIndex, to: range.lowerBound)
                    let endPos = reply.distance(from: reply.startIndex, to: range.upperBound)
                    let query = movieNameArr[i].addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    
                    attributedString.addAttribute(NSLinkAttributeName, value: "https://www.google.com.tw/search?q="+query!, range: NSRange(location: startPos, length: endPos-startPos))
                    //attributedString.addAttribute(NSLinkAttributeName, value: "https://www.youtube.com/results?search_query="+query!, range: NSRange(location: startPos, length: endPos-startPos))
                    attributedString.addAttributes([NSForegroundColorAttributeName: UIColor.white], range: NSRange(location: 0, length: reply.characters.count))
                    attributedString.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], range: NSRange(location: 0, length: reply.characters.count))
                }
            }
            cell.textView.attributedText = attributedString
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
    
    // MARK :- Recorder function
    var textFromVoice: String = ""
    func recorderTapped(sender: UIButton!) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
            self.inputToolbar.contentView.textView.text.append(self.textFromVoice)
            self.inputToolbar.contentView.leftBarButtonItem.setImage(UIImage(named: "recoder_stop"), for: .normal)
            print("Stop Recording")
        } else {
            self.textFromVoice = ""
            self.inputToolbar.contentView.leftBarButtonItem.setImage(UIImage(named: "recoder_start"), for: .normal)
            startRecording()
            print("Start Recording")
        }
    }
    
    func startRecording() {
        //Check if recognitionTask is running. If so, cancel the task and the recognition
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        //Create an AVAudioSession to prepare for the audio recording.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        //Check if the audioEngine (your device) has an audio input for recording.
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        //Check if the recognitionRequest object is instantiated and is not nil.
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        //Tell recognitionRequest to report partial results of speech recognition as the user speaks.
        recognitionRequest.shouldReportPartialResults = true
        //Start the recognition by calling the recognitionTask method of our speechRecognizer.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.textFromVoice = (result?.bestTranscription.formattedString)!
                isFinal = (result?.isFinal)!
            }
            
            //If there is no error or the result is final, stop the audioEngine (audio input) and stop the recognitionRequest and recognitionTask.
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.inputToolbar.contentView.leftBarButtonItem.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        //textView.text = "Say something, I'm listening!"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.inputToolbar.contentView.leftBarButtonItem.isEnabled = true
        } else {
            self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
        }
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
                    
                    if url.containsChineseCharacters {
                        let arr2 = url.components(separatedBy: "=")
                        let query = arr2[1].addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                        reply += "\n\(arr2[0])=\(query!)"
                    }
                    else {
                        reply += "\n\(url)"
                    }
                }
                else if suggest.range(of: "列車編號") != nil {
                    let arr = suggest.components(separatedBy: "$\n")
                    for element in arr {
                        if element != "" {
                            reply += "\n\(element)"
                        }
                    }
                }
                else if suggest.range(of: "$") != nil {
                    let arr = suggest.components(separatedBy: "$\n")
                    var i: Int = 0
                    for element in arr {
                        if (element != "") && (i<5) {
                            reply += "\n\(element)"
                            i += 1
                        }
                    }
                    self.linkKeyword[self.linkKeyword.count-1] = "movie"
                }
            }
            
            if json["target"].stringValue != "" {
                let target = json["target"].stringValue
                let lng = json["longitude"].floatValue
                let lat = json["latitude"].floatValue
                
                self.searchNearbyPlaces(keyword: target, lat: lat, lng: lng) { mapItems in
                    self.performSegue(withIdentifier: "ChatroomToTableSegue", sender: mapItems)
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
    
    //Nearby places searching via Mapkit
    func searchNearbyPlaces(keyword: String, lat: Float, lng: Float, completion:@escaping ([MKMapItem]) -> Void) {
        let request = MKLocalSearchRequest()
        let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25))
        
        request.naturalLanguageQuery = keyword
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start(completionHandler: {(response, error) in
            if error != nil {
                print("Error occured in search:\(error!.localizedDescription)")
            } else if response!.mapItems.count == 0 {
                print("No matches found")
            } else {
                print("Matches found")
            }
            completion(response!.mapItems)
        })
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
    
    // MARK : - Peform segue to MapViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatroomToTableSegue" {
            if let destinationVC = segue.destination as? TableViewController {
                destinationVC.mapItems = sender as! [MKMapItem]
            }
        }
    }

}


extension String {
    var containsChineseCharacters: Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }
}





