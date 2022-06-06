//
//  NewConversationViewControllerViewController.swift
//  Messeger
//
//  Created by MAC on 31/05/2022.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD()
    
    public var completion: (([String:Any]) -> (Void))?
    
    private var users: [[String: Any]] = [[String: Any]]()
    private var results: [[String: Any]] = [[String: Any]]()
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search for users"
        
        return bar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.isHidden = true
        return tableView
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results"
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
        
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width / 4,
                                     y: (view.height - 200) / 2,
                                     width: view.width / 2,
                                     height: 200)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension NewConversationViewController: UITableViewDataSource,
                                         UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.results[indexPath.row]["name"] as? String
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Open new conversation
        let tergetedUser = results[indexPath.row]
        dismiss(animated: true, completion: {
            self.completion?(tergetedUser)
        })
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers(query: text)
        
    }
    
    func searchUsers(query: String)  {
        if hasFetched {
            self.filterUsers(with: query)
        } else {
            DatabaseManager.shared.fetchAllUsers(completion: {[weak self] result in
                switch result {
                case .failure(let error):
                    print("Cannot fetch users: \(error)")
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                }
            })
        }
        
    }
    
    func filterUsers(with term: String) {
        guard hasFetched else {
            return
        }
        
        let result: [[String: Any]] = self.users.filter({
            guard let name = ($0["name"] as? String)?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = result
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
        self.spinner.dismiss(animated: true)
    }
    
}
