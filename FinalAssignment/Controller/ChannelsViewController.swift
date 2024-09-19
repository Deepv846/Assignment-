//
//  ChannelsViewController.swift
//  LoginModel
//
//  Created by Deep Vora on 09/09/24.
//

import UIKit
import CoreData
import SwiftKeychainWrapper
import Security

class ChannelsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var tblCollectionView: UICollectionView!
    private var fetchedResultsController: NSFetchedResultsController<Channel>?
    
  
    
    
    private var sectionCollapsed = [Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        fetchChannels()
    }
    
    private func setupUI() {
        tblCollectionView.delegate = self
        tblCollectionView.dataSource = self
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutTapped))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Dissappear")
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Login.fetchRequest()
        let fetchRequestChannel : NSFetchRequest<NSFetchRequestResult> = Channel.fetchRequest()
        do
        {
            let count  = try context.count(for: fetchRequest)
            
            print("FetchedChannel",count)
        }
        catch
        {
        
        }
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        let deleteRequestChannel = NSBatchDeleteRequest(fetchRequest: fetchRequestChannel)
        try? context.execute(deleteRequest)
        try? context.execute(deleteRequestChannel)
        
        do
        {
            let count  = try context.count(for: fetchRequest)
            
            print("FetchedChannel",count)
        }
        catch
        {
        
        }
        
        KeychainManager.delete(key: "authToken")
        navigationController?.popViewController(animated: true)
    }
    

    
    private func fetchChannels() {
        let token = String(data: KeychainManager.load(key: "authToken") ?? Data(), encoding: .utf8) ?? ""
        
        Task {
            do {
                let channels = try await fetchChannelsFromAPI(token: token)
                saveChannels(channels)
                setupFetchedResultsController()
            } catch {
                print("Network request failed: \(error.localizedDescription)")
                setupFetchedResultsController(useCache: true)
            }
        }
    }
    
    private func setupFetchedResultsController(useCache: Bool = false) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Channel> = Channel.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "groupFolderName", ascending: true)]
        
        fetchedResultsController =  NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: "groupFolderName",
            cacheName: nil
        )
        fetchedResultsController?.delegate = self
        
        try? fetchedResultsController?.performFetch()
        
        // Initialize sectionCollapsed array based on the number of sections.
        if let sections = fetchedResultsController?.sections {
            sectionCollapsed = Array(repeating: true, count: sections.count)
        }
        
        tblCollectionView.reloadData()
    }
    
    private func fetchChannelsFromAPI(token: String) async throws -> [ChannelData] {
        let url = URL(string: "https://mofa.onice.io/teamchatapi/channels.list")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "token=\(token)&include_unread_count=true&exclude_members=true&include_permissions=false"
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            
            let channelsResponse = try JSONDecoder().decode(ChannelsResponse.self, from: data)
            return channelsResponse.channels
            
        } catch {
            print("Network request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func saveChannels(_ channels: [ChannelData]) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        channels.forEach { channelData in
            let channel = Channel(context: context)
            channel.id = channelData.id
            channel.name = channelData.name
            channel.groupFolderName = channelData.groupFolderName
        }
        
        try? context.save()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      
        // If the section is collapsed, return 0 items.
        if sectionCollapsed[section] {
            return 0
        }
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = tblCollectionView.dequeueReusableCell(withReuseIdentifier: "channelCell", for: indexPath) as? channelCell
        let channel = fetchedResultsController?.object(at: indexPath)
        cell?.lblname.text = channel?.name
        
     
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = tblCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "ChannelHeaderView", for: indexPath) as? ChannelHeaderView
        headerView?.backgroundColor = UIColor.lightGray
        headerView?.lblHeader.text = fetchedResultsController?.sections?[indexPath.section].name
        
        // Add a tap gesture recognizer to the header view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSection(_:)))
        headerView?.tag = indexPath.section
        headerView?.addGestureRecognizer(tapGesture)
        
        if sectionCollapsed[indexPath.section]
        {
            headerView?.imgArrow.image = UIImage(named: "arrowDown.png")
            
        }
            else
        {
                headerView?.imgArrow.image = UIImage(named: "arrowup.png")
            }
        
        return headerView!
    }
    
    @objc private func toggleSection(_ sender: UITapGestureRecognizer) {
        guard let section = sender.view?.tag else { return }
        
        // Toggle the collapsed state for the section.
        sectionCollapsed[section].toggle()
        
        // Reload the section with an animation.
        tblCollectionView.reloadSections(IndexSet(integer: section))
    }
}

extension ChannelsViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            print(tblCollectionView.bounds.width)
            return CGSize(width: tblCollectionView.bounds.width, height: 68)
        
        }
}
class KeychainManager {
    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as CFDictionary
        
        SecItemDelete(query) // Delete any existing item with the same key before saving
        return SecItemAdd(query, nil)
    }
    
    class func load(key: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var dataTypeRef: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == noErr {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
    
    class func delete(key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}
