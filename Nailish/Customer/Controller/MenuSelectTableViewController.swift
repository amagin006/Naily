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
    func newReportSaveTapped(selectMenu: Set<MenuItem>)
}

private let cellId = "AddMenuCell"

class MenuSelectTableViewController: FetchTableViewController, UITableViewDataSource {
    
    weak var delegate: MenuSelectTableViewControllerDelegate?
    var selectedMenuItem = Set<MenuItem>()
    var selectedCellIndex = [IndexPath: Int]()
    var popupViewController: PopupViewController? = nil
    let manageContext = CoreDataManager.shared.persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView = menuTableView
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
        headerView.backgroundColor = UIColor(named: "White")
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
        menuTableView.separatorInset = UIEdgeInsets.zero
    }
    
    func fetchMenuItem() {
        do {
            try fetchedSelectedMenuItemResultsController.performFetch()
        } catch let err {
            print("failed fetch Menu Item  \(err)")
        }
    }
    
    @objc func selectMenuCancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func selectMenuSaveButtonPressed() {
      for (cellIndex, quantity) in selectedCellIndex {
        let cell = tableView.cellForRow(at: cellIndex) as! MenuMasterTableViewCell
        guard let cellMenuItem = cell.menuItem else { return }
        let menuItem: MenuItem = MenuItem(context: manageContext)
        menuItem.color = cellMenuItem.color
        menuItem.price = cellMenuItem.price
        menuItem.menuName = cellMenuItem.menuName
        menuItem.quantity = Int16(quantity)
        menuItem.tag = cellMenuItem.tag
        menuItem.tax = cellMenuItem.tax
        selectedMenuItem.insert(menuItem)
      }

        dismiss(animated: true) {
            self.delegate?.newReportSaveTapped(selectMenu: self.selectedMenuItem)
        }
    }
    
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
        cell.backgroundColor = UIColor(named: "White")

      /// remove some point
        cell.menuItem?.quantity = Int16(0)
        do {
             try fetchedReportItemResultsController.managedObjectContext.save()
        } catch let err {
           print("failed save Report - \(err)")
        }
        if let quantityInCell = selectedCellIndex[indexPath] {
          cell.quantityLabel.text = String(quantityInCell)
        }
      ///
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        popupViewController = PopupViewController()
        view.addSubview(popupViewController!.view)
        popupViewController!.delegate = self
        popupViewController!.menuItemIndex = indexPath
        if let cell = tableView.cellForRow(at: indexPath) as? MenuMasterTableViewCell {
          popupViewController!.menuTitle = cell.menuitemTagLabel.text
          popupViewController!.quantity = Int(cell.quantityLabel.text ?? "0")
        }
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let manageContext = CoreDataManager.shared.viewContext
            manageContext.delete(fetchedSelectedMenuItemResultsController.object(at: indexPath))
            do {
                try fetchedSelectedMenuItemResultsController.managedObjectContext.save()
            } catch let err {
                print("Failed delete selectitem \(err)")
            }
        }
        
    }
    
    @objc func addButtonPressed() {
        let newSelectVC = NewMenuViewController()
        let newSelectNVC = LightStatusNavigationController(rootViewController: newSelectVC)
        self.present(newSelectNVC, animated: true, completion: nil)
    }
        
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
        tv.backgroundColor = .white
        return tv
    }()

}

extension MenuSelectTableViewController: popupViewControllerDelegate {
  func popupViewDonetapped(indexPath: IndexPath, quantity: Int) {
    let cell = tableView.cellForRow(at: indexPath) as! MenuMasterTableViewCell

    tableView.beginUpdates()
    if quantity != 0 {
      selectedCellIndex[indexPath] = quantity
      cell.quantityLabel.text = String(quantity)
    } else {
      selectedCellIndex[indexPath] = nil
      cell.quantityLabel.text = "0"
    }
    tableView.reloadData()
    tableView.endUpdates()
  }

}



protocol popupViewControllerDelegate: class {
  func popupViewDonetapped(indexPath: IndexPath, quantity: Int)
}

class PopupViewController: UIViewController, UIGestureRecognizerDelegate {

  weak var delegate: popupViewControllerDelegate?
  var menuItemIndex = IndexPath()
  var amountUIView = UIView()

  var quantity: Int! {
    didSet {
      amountLabel.text = String(quantity)
    }
  }

  var menuTitle: String! {
    didSet {
      amountTitleLabel.text = menuTitle
    }
  }


  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()


    let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(self.tapped(_:))
    )

    tapGesture.cancelsTouchesInView = false
    tapGesture.delegate = self

    self.view.addGestureRecognizer(tapGesture)

    self.view.backgroundColor = UIColor(
      red: 150/255,
      green: 150/255,
      blue: 150/255,
      alpha: 0.6
    )
  }

  func setupUI() {
    let screenWidth:CGFloat = self.view.frame.width
    let screenHeight:CGFloat = self.view.frame.height

    let popupWidth = (screenWidth * 3)/4
    let popupHeight = (screenWidth * 4)/5

    amountUIView.frame = CGRect(
      x:screenWidth/8,
      y:screenHeight/5,
      width:popupWidth,
      height:popupHeight
    )

    amountUIView.backgroundColor = UIColor.white
    amountUIView.layer.cornerRadius = 10
    self.view.addSubview(amountUIView)

    let buttonSV = UIStackView(arrangedSubviews: [plusButton, minusButton])
    buttonSV.spacing = 14
    buttonSV.axis = .horizontal
    buttonSV.distribution = .equalSpacing

    let labeAndButtonSV = UIStackView(arrangedSubviews: [amountTitleLabel, amountLabel, buttonSV, doneButton])
    amountUIView.addSubview(labeAndButtonSV)
    labeAndButtonSV.axis = .vertical
    labeAndButtonSV.alignment = .center
    labeAndButtonSV.distribution = .equalSpacing
    labeAndButtonSV.spacing = 16
    labeAndButtonSV.translatesAutoresizingMaskIntoConstraints = false
    labeAndButtonSV.topAnchor.constraint(equalTo: amountUIView.topAnchor, constant: 30).isActive = true
    labeAndButtonSV.bottomAnchor.constraint(equalTo: amountUIView.bottomAnchor, constant: -30).isActive = true
    labeAndButtonSV.leadingAnchor.constraint(equalTo: amountUIView.leadingAnchor, constant: 15).isActive = true
    labeAndButtonSV.trailingAnchor.constraint(equalTo: amountUIView.trailingAnchor, constant: -15).isActive = true
  }

  @objc func tapped(_ sender: UITapGestureRecognizer){
    self.view.removeFromSuperview()
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if (touch.view!.isDescendant(of: amountUIView)) {
        return false
    }
    return true
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  @objc func quantityPlusButtonPressed() {
    quantity += 1
    amountLabel.text = String(quantity)
  }

  @objc func quantityMinusButtonPressed() {
    if quantity > 0 {
      quantity -= 1
      amountLabel.text = String(quantity)
    }

  }

  @objc func quantityDoneButtonPressed() {
    quantity = Int(self.amountLabel.text ?? "0")
    self.delegate?.popupViewDonetapped(indexPath: menuItemIndex, quantity: quantity)
    self.view.removeFromSuperview()
  }

  let amountTitleLabel: UILabel = {
    let lb = UILabel()
    lb.translatesAutoresizingMaskIntoConstraints = false
    lb.text = "Enter quantity"
    lb.heightAnchor.constraint(equalToConstant: 30).isActive = true
    lb.textColor = UIColor(named: "PrimaryText")
    return lb
  }()

  let amountLabel: UITextField = {
    let tf = UITextField()
    tf.text = "0"
    tf.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    tf.translatesAutoresizingMaskIntoConstraints = false
    tf.textAlignment = .center
    tf.keyboardType = .numberPad
    tf.heightAnchor.constraint(equalToConstant: 40).isActive = true
    tf.widthAnchor.constraint(equalToConstant: 180).isActive = true
    tf.font = UIFont.systemFont(ofSize: 20)
    return tf
  }()

  let plusButton: UIButton = {
    let bt = UIButton()
    bt.setTitle("+", for: .normal)
    bt.backgroundColor = .blue
    bt.translatesAutoresizingMaskIntoConstraints = false
    bt.widthAnchor.constraint(equalToConstant: 80).isActive = true
    bt.addTarget(self, action: #selector(quantityPlusButtonPressed), for: .touchUpInside)
    return bt
  }()

  let minusButton: UIButton = {
    let bt = UIButton()
    bt.setTitle("-", for: .normal)
    bt.backgroundColor = .red
    bt.translatesAutoresizingMaskIntoConstraints = false
    bt.widthAnchor.constraint(equalToConstant: 80).isActive = true
    bt.addTarget(self, action: #selector(quantityMinusButtonPressed), for: .touchUpInside)
    return bt
  }()

  let doneButton: UIButton = {
    let bt = UIButton()
    bt.setTitle("OK", for: .normal)
    bt.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
    bt.translatesAutoresizingMaskIntoConstraints = false
    bt.translatesAutoresizingMaskIntoConstraints = false
    bt.widthAnchor.constraint(equalToConstant: 160).isActive = true
    bt.clipsToBounds = true
    bt.layer.cornerRadius = 12
    bt.addTarget(self, action: #selector(quantityDoneButtonPressed), for: .touchUpInside)
    return bt
  }()
}
