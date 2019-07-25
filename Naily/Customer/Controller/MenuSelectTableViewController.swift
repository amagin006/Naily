//
//  MenuSelectTableViewController.swift
//  Naily
//
//  Created by Shota Iwamoto on 2019-07-18.
//  Copyright © 2019 Shota Iwamoto. All rights reserved.
//

import UIKit
import CoreData

protocol MenuSelectTableViewControllerDelegate: class {
  func newReportSaveTapped(selectMenu: Set<SelectedMenuItem>)
}

private let cellId = "AddMenuCell"

class MenuSelectTableViewController: UIViewController, UITableViewDataSource {
  
  weak var delegate: MenuSelectTableViewControllerDelegate?
  var reportItem: ReportItem!
  var selectedCell = Set<SelectedMenuItem>()
  
  override func viewWillAppear(_ animated: Bool) {
    fetchMenuItem()
    menuTableView.reloadData()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationUI()
    setupUI()
    fetchMenuItem()
  }
  
  func setupNavigationUI() {
    navigationItem.title = "Select Menu"
    let cancelButton: UIBarButtonItem = {
      let bt = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(selectMenuCancelButtonPressed))
      return bt
    }()
    navigationItem.leftBarButtonItem = cancelButton
    
    let saveButton: UIBarButtonItem = {
      let bt = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(selectMenuSaveButtonPressed))
      return bt
    }()
    navigationItem.rightBarButtonItem = saveButton
  }
  
  func setupUI() {
    let headerView = UIView()
    headerView.backgroundColor = .white
    view.addSubview(headerView)
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    headerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    headerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    headerView.heightAnchor.constraint(equalToConstant: 70).isActive = true
    
    headerView.addSubview(addButton)
    addButton.layer.cornerRadius = 10
    addButton.translatesAutoresizingMaskIntoConstraints = false
    addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
    addButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
    
    view.addSubview(menuTableView)
    menuTableView.translatesAutoresizingMaskIntoConstraints = false
    menuTableView.dataSource = self
    menuTableView.delegate = self
    menuTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
    menuTableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    menuTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    menuTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    menuTableView.register(MenuMasterTableViewCell.self, forCellReuseIdentifier: cellId)
    menuTableView.allowsMultipleSelectionDuringEditing = true
    menuTableView.setEditing(true, animated: true)
  }
  
  func fetchMenuItem() {
    do {
      try fetchedSelectedMenuItemResultsController.performFetch()
    } catch let err {
      print("failed fetch Menu Item  \(err)")
    }
  }
  
  @objc func selectMenuCancelButtonPressed() {
    print("selectMenuCancelButtonPressed")
    dismiss(animated: true, completion: nil)
  }
  
  @objc func selectMenuSaveButtonPressed() {
    dismiss(animated: true) {
      self.delegate?.newReportSaveTapped(selectMenu: self.selectedCell)
    }
  }
  
  @objc func addButtonPressed() {
    print("addButtonPressed")
    let newSelectVC = NewMenuViewController()
    let newSelectNVC = LightStatusNavigationController(rootViewController: newSelectVC)
    self.present(newSelectNVC, animated: true, completion: nil)
  }
  
  lazy var fetchedSelectedMenuItemResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<SelectedMenuItem> in
    let fetchRequest = NSFetchRequest<SelectedMenuItem>(entityName: "SelectedMenuItem")
    let menuItemDescriptors = NSSortDescriptor(key: "color", ascending: false)
    fetchRequest.sortDescriptors = [menuItemDescriptors]
    let context = CoreDataManager.shared.persistentContainer.viewContext
    let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    return frc
  }()
  
  let headerLable: UILabel = {
    let lb = UILabel()
    lb.text = "Select Menu"
    return lb
  }()
  
  let addButton: UIButton = {
    let bt = UIButton()
    bt.setTitle("Add New Menu", for: .normal)
    bt.setTitleColor(UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1), for: .normal)
    bt.constraintWidth(equalToConstant: 200)
    bt.constraintHeight(equalToConstant: 40)
    bt.setBackgroundColor(UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1), for: .normal)
    bt.setBackgroundColor(UIColor(red: 190/255, green: 190/255, blue: 190/255, alpha: 1), for: .highlighted)
    bt.clipsToBounds = true
    bt.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
    let plusImage = #imageLiteral(resourceName: "plus2")
    bt.setImage(plusImage.withRenderingMode(.alwaysOriginal), for: .normal)
    bt.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: plusImage.size.width / 2)
    bt.contentHorizontalAlignment = .center
    return bt
  }()
  
  let menuTableView: UITableView = {
    let tv = UITableView()
    return tv
  }()
}

extension MenuSelectTableViewController: UITableViewDelegate, NSFetchedResultsControllerDelegate {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let count = fetchedSelectedMenuItemResultsController.sections?[section].numberOfObjects {
      return count
    }
    return 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! MenuMasterTableViewCell
    cell.menuItem = fetchedSelectedMenuItemResultsController.object(at: indexPath)
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
  
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let cell = tableView.cellForRow(at: indexPath) as? MenuMasterTableViewCell {
      guard let menuItem = cell.menuItem else { return }
      
//      let newSelectedItem = SelectedMenuItem(context: fetchedSelectedMenuItemResultsController.managedObjectContext)
//      newSelectedItem.color = menuItem.color
//      newSelectedItem.price = menuItem.price
//      newSelectedItem.menuName = menuItem.menuName
      selectedCell.insert(menuItem)
    }
  }
  
  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    if let cell = tableView.cellForRow(at: indexPath) as? MenuMasterTableViewCell {
      guard let menuItem = cell.menuItem else { return }
      selectedCell.remove(menuItem)
    }
  }
}
