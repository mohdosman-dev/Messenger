//
//  StorageManager.swift
//  Messeger
//
//  Created by MAC on 05/06/2022.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    public static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    /*
     /images/user-email-com_profile_picture.png
     */
    
    public typealias StorageCompletion = (Result<String, Error>) -> Void
    
    /// Upload user profile image and get url
    public func uploadProfilePicture(with data: Data, fileName: String,
                                     complition: @escaping  StorageCompletion) {
        storage.child("/images/\(fileName)").putData(data, completion: {metadata, error in
            guard error == nil else {
                print("Error while uplaoding profile picture")
                complition(.failure(StorageError.UploadError))
                return
            }
            
            self.storage.child(fileName).downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Error while get image download url")
                    complition(.failure(StorageError.DownloadURLError))
                    return
                }
                let urlString = url.absoluteString
                print("The picutre placed in: \(urlString)")
                complition(.success(urlString))
            })
        })
    }
    
    
    /// Upload user profile image and get url
    public func uploadMessagePhoto(with data: Data, fileName: String,
                                     complition: @escaping  StorageCompletion) {
        storage.child("message_images/\(fileName)").putData(data, completion: {metadata, error in
            guard error == nil else {
                print("Error while uplaoding profile picture")
                complition(.failure(StorageError.UploadError))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Error while get image download url")
                    complition(.failure(StorageError.DownloadURLError))
                    return
                }
                let urlString = url.absoluteString
                print("The picutre placed in: \(urlString)")
                complition(.success(urlString))
            })
        })
    }
    
    
    public func getDownloadURL(for path:String, completion: @escaping (Result<URL, Error>) -> Void) {
        let refrence = self.storage.child(path)
        refrence.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                print("Cannot get url picture: \(String(describing: error))")
                completion(.failure(StorageError.DownloadURLError))
                return
            }
            
            completion(.success(url))
        })
    }
    
    enum StorageError: Error {
        /// Cannot upload image to firebase
        case UploadError
        
        /// Cannot get uploaded image into firebase
        case DownloadURLError
    }
    
}
