//
//  CategoriesViewController.swift
//  Documents Core Data Relationships Search
//
//  Edited by Henry Sills
//  Created by Dale Musser on 7/10/18.
//  Copyright © 2018 Dale Musser. All rights reserved.
//

import UIKit
import CoreData

class CategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var categoriesTableView: UITableView!
    
    var categories = [Category]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Categories"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchCategories(searchString: "")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func add(_ sender: Any) {
        let alert = UIAlertController(title: "Add Category", message: "Enter new category name.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Submit", style: UIAlertAction.Style.default, handler: {
            (alertAction) -> Void in
            if let textField = alert.textFields?[0], let name = textField.text {
                let categoryName = name.trimmingCharacters(in: .whitespaces)
                if (categoryName == "") {
                    self.alertNotifyUser(message: "Category not created.\nThe name must contain a value.")
                    return
                }
                self.addCategory(name: categoryName)
            } else {
                self.alertNotifyUser(message: "Category not created.\nThe name is not accessible.")
                return
            }
            
        }))
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "category name"
            textField.isSecureTextEntry = false
            
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func edit(at indexPath: IndexPath) {
        let category = categories[indexPath.row]
        let alert = UIAlertController(title: "Edit Category", message: "Enter new category name.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Submit", style: UIAlertAction.Style.default, handler: {
            (alertAction) -> Void in
            if let textField = alert.textFields?[0], let name = textField.text {
                let categoryName = name.trimmingCharacters(in: .whitespaces)
                if (categoryName == "") {
                    self.alertNotifyUser(message: "Category name not changed.\nA name is required.")
                    return
                }
                
                if (categoryName == category.name) {
                    // Nothing to change, new name is old name.
                    // Do this check before checking that categoryExists,
                    // otherwise if category name doesn't change error about already existing will occur.
                    return
                }
                
                if (self.categoryExists(name: categoryName)) {
                    self.alertNotifyUser(message: "Category name not changed.\n\(categoryName) already exists.")
                    return
                }
                
                self.updateCategory(at: indexPath, name: categoryName)
            } else {
                self.alertNotifyUser(message: "Category name not changed.\nThe name is not accessible.")
                return
            }
            
        }))
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "category name"
            textField.isSecureTextEntry = false
            textField.text = category.name
            
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func alertNotifyUser(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func addCategory(name: String) {
        // check if category by that name already exists
        if (categoryExists(name: name)) {
            alertNotifyUser(message: "Category \(name) already exists.")
            return
        }
        
        let category = Category(name: name)
        
        if let category = category {
            do {
                let managedObjectContext = category.managedObjectContext
                try managedObjectContext?.save()
            } catch {
                print("Category could not be saved.")
            }
        } else {
            print("Category could not be created.")
        }
        
        fetchCategories(searchString: "")
    }
    
    func fetchCategories(searchString: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            if (searchString != "") {
                fetchRequest.predicate = NSPredicate(format: "name contains[c] %@", searchString)
            }
            categories = try managedContext.fetch(fetchRequest)
            categoriesTableView.reloadData()
        } catch {
            print("Fetch could not be performed")
        }
    }
    
    func categoryExists(name: String) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, name != "" else {
            return false
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            fetchRequest.predicate = NSPredicate(format: "name == %@", name)
            let results = try managedContext.fetch(fetchRequest)
            if results.count > 0 {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    func confirmDeleteCategory(at indexPath: IndexPath) {
        let category = categories[indexPath.row]
        
        if let documentSet = category.documents, documentSet.count > 0 {
            // confirm deletion
            let name = category.name ?? "Category"
            let alert = UIAlertController(title: "Delete Category", message: "\(name) contains documents. Do you want to delete it?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {
                (alertAction) -> Void in
                // handle cancellation of deletion
                self.categoriesTableView.reloadData()
            }))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive, handler: {
                (alertAction) -> Void in
                // handle deletion here
                self.deleteCategory(at: indexPath)
            }))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            deleteCategory(at: indexPath)
        }
    }
    
    // https://cocoacasts.com/core-data-relationships-and-delete-rules
    // Delete rules need to be put in place in the entity editor.
    // When a category is deleted, the documents associated with the category are to be deleted.
    // On Document entity for category relationship, delete rule is Nullify (if delete 'document', remove it and do not delete the associated category)
    // On Category entity for documents relationship, delete rule is Cascade (if delete 'category', delete the associated documents)
    
    func deleteCategory(at indexPath: IndexPath) {
        let category = categories[indexPath.row]
        
        if let managedObjectContext = category.managedObjectContext {
            managedObjectContext.delete(category)
            
            do {
                try managedObjectContext.save()
                self.categories.remove(at: indexPath.row)
                categoriesTableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                print("Delete failed: \(error).")
                categoriesTableView.reloadData()
            }
        }
    }
    
    func updateCategory(at indexPath: IndexPath, name: String) {
        let category = categories[indexPath.row]
        category.name = name
        
        if let managedObjectContext = category.managedObjectContext {
            do {
                try managedObjectContext.save()
                fetchCategories(searchString: "")
            } catch {
                print("Update failed.")
                categoriesTableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        
        let category = categories[indexPath.row]
        cell.textLabel?.text = category.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") {
            action, index in
            self.confirmDeleteCategory(at: indexPath)
        }
        
        let edit = UITableViewRowAction(style: .default, title: "Edit") {
            action, index in
            self.edit(at: indexPath)
        }
        edit.backgroundColor = UIColor.blue
    
        return [delete, edit]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DocumentsViewController,
            let row = categoriesTableView.indexPathForSelectedRow?.row {
            destination.category = categories[row]
        }
    }
    
}

