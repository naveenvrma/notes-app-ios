//
//  ViewController.swift
//  NoteApp
//
//  Created by KsjLsh on 2020/6/14.
//  Copyright © 2020 KsjLsh. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate {

    @IBOutlet weak var noteSearch: UISearchBar!
    @IBOutlet weak var tableview: UITableView!
    var savedArray = NSMutableArray()
    var searchedArray = NSMutableArray()
    var searching = false
    override func viewDidLoad() {
        super.viewDidLoad()
        noteSearch.delegate = self
        noteSearch.showsCancelButton = true
        noteSearch.showsSearchResultsButton = true
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let defaults = UserDefaults.standard
        if defaults.value(forKey: "SavedArray") != nil { // array is already existing
            let savedData = defaults.value(forKey: "SavedArray") as! NSArray
            savedArray = savedData.mutableCopy() as! NSMutableArray
            print(savedArray)
            searching = false
            tableview.reloadData()
        }
        
    }
    @IBAction func addClicked(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "AddNoteViewController") as! AddNoteViewController
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchedArray.count
        } else {
            return savedArray.count
        }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteTableViewCell", for: indexPath) as! NoteTableViewCell
        cell.selectionStyle = .none
        var dicCell = NSDictionary()
        if searching {
            dicCell = searchedArray.object(at: indexPath.row) as! NSDictionary
        } else {
            dicCell = savedArray.object(at: indexPath.row) as! NSDictionary
        }
        
        cell.name.text = dicCell["title"] as? String
        let nTime = dicCell["time"] as? Int
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(nTime!)) as Date)
        cell.date.text = dateString
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var dicCell = NSDictionary()
        if searching {
            dicCell = searchedArray.object(at: indexPath.row) as! NSDictionary
        } else {
            dicCell = savedArray.object(at: indexPath.row) as! NSDictionary
        }
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "NoteDetailViewController") as! NoteDetailViewController
        newViewController.noteData = dicCell
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
      let deleteAction = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
        // Perform your action here
        self.savedArray.removeObject(at: indexPath.row)
        print(self.savedArray)
        let defaults = UserDefaults.standard
        defaults.setValue(self.savedArray, forKey: "SavedArray")
        self.tableview.reloadData()
        
          completion(true)
      }

      let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, completion) in
        // Perform your action here
        var dicCell = NSDictionary()
        if self.searching {
            dicCell = self.searchedArray.object(at: indexPath.row) as! NSDictionary
        } else {
            dicCell = self.savedArray.object(at: indexPath.row) as! NSDictionary
        }
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "EditNoteViewController") as! EditNoteViewController
        newViewController.dicNote = dicCell
        newViewController.savedArray = self.savedArray
        self.navigationController?.pushViewController(newViewController, animated: true)
        
        completion(true)
      }

      
      deleteAction.backgroundColor = UIColor.red
      return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searching = true
            for index in 0..<savedArray.count {
                let dicIndex = savedArray.object(at: index) as? NSDictionary
                let strTitle = dicIndex!["title"] as! String
                let strSearch = searchBar.text!
                if strTitle.lowercased().contains(strSearch.lowercased()) {
                    searchedArray.add(dicIndex!)
                }
            }
            tableview.reloadData()
            searchBar.resignFirstResponder()
        }
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        tableview.reloadData()
        searchBar.resignFirstResponder()
    }
}

