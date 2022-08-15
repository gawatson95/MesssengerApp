//
//  ChatLogVM.swift
//  MesssengerTutorial
//
//  Created by Grant Watson on 7/29/22.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

class ChatLogVM: ObservableObject {
    
    @Published var messageText: String = ""
    @Published var chatMessages = [ChatMessage]()
    
    var chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    
    var firestoreListener: ListenerRegistration?
    
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        firestoreListener = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                snapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        let docId = change.document.documentID
                        let chatMessage = ChatMessage(documentId: docId, data: data)
                        self.chatMessages.append(chatMessage)
                    }
                })
            }
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = ["fromId": fromId, "toId": toId, "text": self.messageText, "timestamp": Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        
        persistRecentMessage()
        
        let recipientDocument = FirebaseManager.shared.firestore
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientDocument.setData(messageData) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        
        messageText = ""
    }
    
    func persistRecentMessage() {
        
        guard let chatUser = chatUser else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            "timestamp": Timestamp(),
            "text": self.messageText,
            "fromId": uid,
            "toId": toId,
            "profileImageUrl": chatUser.profileImageUrl,
            "username": chatUser.username
        ] as [String: Any]
        
        document.setData(data) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        let recipientRecentMessage = [
            "timestamp": Timestamp(),
            "text": self.messageText,
            "fromId": uid,
            "toId": toId,
            "profileImageUrl": currentUser.profileImageUrl,
            "username": currentUser.username
        ] as [String: Any]
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(toId)
            .collection("messages")
            .document(currentUser.uid)
            .setData(recipientRecentMessage) { error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
    }
    
    func deleteChatLog() {
        guard let toId = chatUser?.uid else { return }
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(currentUser.uid)
            .collection("messages")
            .document(toId).delete()
        
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(currentUser.uid)
            .collection(toId)
            //.document
            .getDocuments { snapshot, err in
                if let err = err {
                    print(err.localizedDescription)
                    return
                } else {
                    snapshot?.
                }
            }
    }
}
