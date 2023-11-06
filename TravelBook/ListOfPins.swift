//
//  ListOfPins.swift
//  TravelBook
//
//  Created by Vyacheslav on 24.10.2023.
//

import UIKit
import CoreData

class ListOfPins: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var listOfPins: UITableView!
    
    var namesArray = [String]()
    var idsArray = [UUID]()
    var commentArray = [String]()
    
    var chosenNameFromArray = ""
    var chosenIdFromArray : UUID?
    var chosenComment = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listOfPins.delegate = self
        listOfPins.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(createNewPin))

//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let context = appDelegate.persistentContainer.viewContext
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TravelBook")
//
//        do {
//            let results = try context.fetch(fetchRequest)
//            if results.count > 0 {
//                for result in results as! [NSManagedObject] {
//                    context.delete(result)
//                    do {
//                        try context.save()
//                    } catch {}
//                }
//            }
//        } catch {}
        
        // Do any additional setup after loading the view.
    }
    
    @objc func createNewPin() {
        chosenNameFromArray = ""
        performSegue(withIdentifier: "showPin", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(uploadData), name: NSNotification.Name("savedData"), object: nil)
        uploadData()
    }

   @objc func uploadData() {
        
        namesArray.removeAll(keepingCapacity: false)
        idsArray.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TravelBook")
        
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "name") as? String {
                        self.namesArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idsArray.append(id)
                    }
                    if let comment = result.value(forKey: "comment") as? String {
                        self.commentArray.append(comment)
                    }
                    self.listOfPins.reloadData()
                }
            }
        } catch {
            print("can't upload data (1) ")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var context = cell.defaultContentConfiguration()
        context.text = namesArray[indexPath.row]
        cell.contentConfiguration = context
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenNameFromArray = namesArray[indexPath.row]
        chosenIdFromArray = idsArray[indexPath.row]
        chosenComment = commentArray[indexPath.row]
        performSegue(withIdentifier: "showPin", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPin" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedName = chosenNameFromArray
            destinationVC.selectedId = chosenIdFromArray
            destinationVC.selectedComment = chosenComment
        }
    }

}
