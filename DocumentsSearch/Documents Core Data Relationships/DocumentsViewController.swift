//
//  DocumentsViewController.swift
//  Documents Core Data Relationships Search
//
//  Edited by Henry Sills
//  Created by Dale Musser on 7/10/18.
//  Copyright © 2018 Dale Musser. All rights reserved.
//

import UIKit
import CoreData

class DocumentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating {
    
    
    @IBOutlet weak var documentsTableView: UITableView!
    
    var category: Category?
    var documents = [Document]()
    var filertedDocuments = [Document]()
    let dateFormatter = DateFormatter()
    
    let searchController = UISearchController(searchResultsController: nil)


    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = category?.name ?? ""
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        createSearchController()
        self.documentsTableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchDocuments()
        updateDocumentsArray()
        documentsTableView.reloadData()
    }
    
    func createSearchController() {
        
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(white: 0.8, alpha: 0.8)
        searchController.hidesNavigationBarDuringPresentation = false
        documentsTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Search by Name or Content"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateDocumentsArray() {
        documents = category?.documents?.sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as? [Document] ?? [Document]()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
          fetchDocuments()
          documentsTableView.reloadData()
      }
      
    
    func fetchDocuments() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        if (searchController.isActive == true && searchController.searchBar.text == "") || searchController.isActive == false {
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            documents = try managedContext.fetch(fetchRequest)
        } catch {
           // alertNotifyUser(message: "Fetch for documents could not be performed.")
           print("Could not fetch documents")
            return
        }
        }
        
        else {
            if let searchString = self.searchController.searchBar.text {
                fetchRequest.predicate = NSPredicate(format: "name contains[c] %@ || content contains[c] %@", searchString, searchString)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                
                do{
                    filertedDocuments = try managedContext.fetch(fetchRequest)
                } catch {
                    print ("Could not fetch documents")
                    return
                }
            }
        }
    }
 
    func deleteDocument(at indexPath: IndexPath) {
        let document = documents[indexPath.row]
        
        if let managedObjectContext = document.managedObjectContext {
            managedObjectContext.delete(document)
            
            do {
                try managedObjectContext.save()
                self.documents.remove(at: indexPath.row)
                documentsTableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                //alertNotifyUser(message: "Delete failed.")
                print("Delete Failed")
                documentsTableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filertedDocuments.count
        }else{
             return documents.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "documentCell", for: indexPath)
        
        if let cell = cell as? DocumentTableViewCell {
            let document = documents[indexPath.row]
            cell.nameLabel.text = document.name
            cell.sizeLabel.text = String(document.size)
            if let modifiedDate = document.modifiedDate {
                cell.modifiedDateLabel.text = dateFormatter.string(from: modifiedDate)
            } else {
                cell.modifiedDateLabel.text = "unknown"
            }
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DocumentViewController,
            let segueIdentifier = segue.identifier {
            destination.category = category
            if (segueIdentifier == "existingDocument") {
                if let row = documentsTableView.indexPathForSelectedRow?.row {
                    destination.document = documents[row]
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
           if editingStyle == .delete {
               deleteDocument(at: indexPath)
           }
    }
    
}
