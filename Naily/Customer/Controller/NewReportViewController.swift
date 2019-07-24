//
//  NewReportViewController.swift
//  Naily
//
//  Created by Shota Iwamoto on 2019-06-13.
//  Copyright © 2019 Shota Iwamoto. All rights reserved.
//

import UIKit
import CoreData
import Photos

private let menuCellId = "menuCell"

class NewReportViewController: UIViewController, UITableViewDataSource {
    
    var reportImageViews = [UIImageView]()
    var reportImages = [UIImage]()
    var selectImageNum = 0
    var client: ClientInfo?
    var reload: ((ReportItem) -> ())?
    var selectedMenuItemArray = [MenuItem]()
    let manageContext = CoreDataManager.shared.persistentContainer.viewContext
    
    var menuSVRow = [UIView]()
    var report: ReportItem? {
        didSet {
            if let image1 = report?.snapshot1, let image2 = report?.snapshot2,
                let image3 = report?.snapshot3, let image4 = report?.snapshot4 {
                reportImages.append(UIImage(data: image1)!)
                reportImages.append(UIImage(data: image2)!)
                reportImages.append(UIImage(data: image3)!)
                reportImages.append(UIImage(data: image4)!)
                for i in 0..<reportImages.count {
                    let iv = UIImageView(image: #imageLiteral(resourceName: "imagePlaceholder"))
                    iv.layer.borderWidth = 2
                    iv.layer.borderColor = UIColor.lightGray.cgColor
                    iv.translatesAutoresizingMaskIntoConstraints = false
                    iv.isUserInteractionEnabled = true
                    iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectImage(_:))))
                    iv.tag = i
                    reportImageViews.append(iv)
                    reportImages.append(iv.image!)
                    reportImageViews[i].image = reportImages[i]
                    subImageSV.addArrangedSubview(reportImageViews[i])
                }
            }
            reportMainImageView.image = reportImages[0]
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            if let date = report?.visitDate {
                visitTextField.text = formatter.string(from: date)
            }
            formatter.dateFormat = "HH:mm"
            if let start = report?.startTime {
                startTimeTextField.text = formatter.string(from: start)
            }
            if let end = report?.endTime {
                endTimeTextField.text = formatter.string(from: end)
            }
            if let menuItems = report?.selectedMenuItems {
                
                print("report========= 27 \(menuItems)")
                selectedMenuItemArray = Array(menuItems) as! [MenuItem]
                print("selectedMenuItemArray ====== \(selectedMenuItemArray)")
                menuTableView.reloadData()
            }
            memoTextView.text = report?.memo
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationUI()
        setupUI()
    }
    
    lazy var fetchedReportItemResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<ReportItem> in
        let fetchRequest = NSFetchRequest<ReportItem>(entityName: "ReportItem")
        let visitDateDescriptors = NSSortDescriptor(key: "visitDate", ascending: true)
        fetchRequest.sortDescriptors = [visitDateDescriptors]
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    lazy var fetchedSelectedMenuItemResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<SelectedMenuItem> in
        let fetchRequest = NSFetchRequest<SelectedMenuItem>(entityName: "SelectedMenuItem")
        let menuItemDescriptors = NSSortDescriptor(key: "color", ascending: false)
        fetchRequest.sortDescriptors = [menuItemDescriptors]
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    private func setupUI() {
        view.addSubview(formScrollView)
        formScrollView.anchors(topAnchor: view.topAnchor, leadingAnchor: view.leadingAnchor, trailingAnchor: view.trailingAnchor, bottomAnchor: view.bottomAnchor)
        formScrollView.frame = self.view.frame
        formScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 1400)

        formScrollView.addSubview(reportMainImageView)
        reportMainImageView.topAnchor.constraint(equalTo: formScrollView.topAnchor).isActive = true
        reportMainImageView.widthAnchor.constraint(equalTo: formScrollView.widthAnchor).isActive = true
        reportMainImageView.centerXAnchor.constraint(equalTo: formScrollView.centerXAnchor).isActive = true
        reportMainImageView.heightAnchor.constraint(equalTo: formScrollView.widthAnchor).isActive = true
        
        for i in 0..<4 {
            if reportImageViews.count < 4 {
                let iv = UIImageView(image: #imageLiteral(resourceName: "imagePlaceholder"))
                iv.layer.borderWidth = 2
                iv.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
                iv.translatesAutoresizingMaskIntoConstraints = false
                iv.isUserInteractionEnabled = true
                iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectImage(_:))))
                iv.tag = i
                reportImageViews.append(iv)
                reportImages.append(iv.image!)
                subImageSV.addArrangedSubview(reportImageViews[i])
            }
        }
        let reportImageViewHeight = reportImageViews[0].widthAnchor
        
        formScrollView.addSubview(subImageSV)
        subImageSV.distribution = .fillEqually
        subImageSV.spacing = 10
        subImageSV.topAnchor.constraint(equalTo: reportMainImageView.bottomAnchor, constant: 10).isActive = true
        subImageSV.widthAnchor.constraint(equalTo: formScrollView.widthAnchor, multiplier: 0.9).isActive = true
        subImageSV.centerXAnchor.constraint(equalTo: formScrollView.centerXAnchor).isActive = true
        subImageSV.heightAnchor.constraint(equalTo: reportImageViewHeight).isActive = true
        
        let visitDateSV = UIStackView(arrangedSubviews: [visitTitleLabel, visitTextField])
        visitDateSV.axis = .vertical
        visitDateSV.spacing = 3
        
        let startSV = UIStackView(arrangedSubviews: [startTimeTitleLabel, startTimeTextField])
        startSV.axis = .vertical
        startSV.spacing = 3
        
        let endSV = UIStackView(arrangedSubviews: [endTimeTitleLabel, endTimeTextField])
        endSV.axis = .vertical
        endSV.spacing = 3
        
        let timeSV = UIStackView(arrangedSubviews: [startSV, endSV])
        timeSV.axis = .horizontal
        timeSV.distribution = .fillEqually
        timeSV.spacing = 12
        
        let dateAndTimeSV = UIStackView(arrangedSubviews: [visitDateSV, timeSV])
        dateAndTimeSV.translatesAutoresizingMaskIntoConstraints = false
        dateAndTimeSV.axis = .vertical
        dateAndTimeSV.spacing = 16
        dateAndTimeSV.alignment = .fill
        formScrollView.addSubview(dateAndTimeSV)
        dateAndTimeSV.topAnchor.constraint(equalTo: subImageSV.bottomAnchor, constant: 20).isActive = true
        dateAndTimeSV.widthAnchor.constraint(equalTo: formScrollView.widthAnchor, multiplier: 0.9).isActive = true
        dateAndTimeSV.centerXAnchor.constraint(equalTo: formScrollView.centerXAnchor).isActive = true
        
        formScrollView.addSubview(addMenuButton)
        addMenuButton.topAnchor.constraint(equalTo: dateAndTimeSV.bottomAnchor, constant: 20).isActive = true
        addMenuButton.centerXAnchor.constraint(equalTo: formScrollView.centerXAnchor).isActive = true

        formScrollView.addSubview(menuTableView)
        menuTableView.translatesAutoresizingMaskIntoConstraints = false
        menuTableView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        menuTableView.delegate = self
        menuTableView.dataSource = self
        menuTableView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        menuTableView.topAnchor.constraint(equalTo: addMenuButton.bottomAnchor, constant: 20).isActive = true
        menuTableView.widthAnchor.constraint(equalTo: formScrollView.widthAnchor, multiplier: 0.9).isActive = true
        menuTableView.centerXAnchor.constraint(equalTo: formScrollView.centerXAnchor).isActive = true
        menuTableView.register(MenuMasterTableViewCell.self, forCellReuseIdentifier: menuCellId)
        
        let tipsPriceSV = UIStackView(arrangedSubviews: [dollar, tipsLable, dot, tipsDecimalLable])
        tipsPriceSV.axis = .horizontal
        tipsPriceSV.spacing = 4
        let tipsSV = UIStackView(arrangedSubviews: [tipsTitleLabel, tipsPriceSV])
        tipsSV.axis = .horizontal
        
        let tipAndMemoSV = UIStackView(arrangedSubviews: [tipsSV, memoLabel, memoTextView])
        formScrollView.addSubview(tipAndMemoSV)
        tipAndMemoSV.translatesAutoresizingMaskIntoConstraints = false
        tipAndMemoSV.spacing = 10
        tipAndMemoSV.axis = .vertical
        
        tipAndMemoSV.topAnchor.constraint(equalTo: menuTableView.bottomAnchor, constant: 20).isActive = true
        tipAndMemoSV.widthAnchor.constraint(equalTo: formScrollView.widthAnchor, multiplier: 0.9).isActive = true
        tipAndMemoSV.centerXAnchor.constraint(equalTo: formScrollView.centerXAnchor).isActive = true
        
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillBeHidden), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillBeShown), name: UIResponder.keyboardWillShowNotification, object: nil)

    }
    
    private func setupNavigationUI() {
        navigationItem.title = report == nil ? "New Report" : "Edit Report"
        let cancelButton: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(reportCancelButtonPressed))
            return bt
        }()
        navigationItem.leftBarButtonItem = cancelButton
        
        let saveButton: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(reportSeveButtonPressed))
            return bt
        }()
        navigationItem.rightBarButtonItem = saveButton
    }
    
    
    @objc func selectImage(_ sender: UITapGestureRecognizer) {
        selectImageNum = sender.view!.tag
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            // handle authorized status
            self.editSelectImage()
        default:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    self.editSelectImage()
                default:
                    // won't happen but still
                    let cameraUnavailableAlertController = UIAlertController (title: "Photo Library Unavailable", message: "Please check to see if device settings doesn't allow photo library access", preferredStyle: .alert)
                    
                    let settingsAction = UIAlertAction(title: "Settings", style: .destructive) { (_) -> Void in
                        let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
                        if let url = settingsUrl {
                            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                        }
                    }
                    let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                    cameraUnavailableAlertController.addAction(settingsAction)
                    cameraUnavailableAlertController.addAction(cancelAction)
                    self.present(cameraUnavailableAlertController , animated: true, completion: nil)
                    break
                }
            }
        }
    }
    
    private func editSelectImage() {
        let imagePickController = UIImagePickerController()
        imagePickController.delegate = self
        imagePickController.sourceType = .photoLibrary
        imagePickController.allowsEditing = true
        
        present(imagePickController, animated: true, completion: nil)
    }
    
    @objc func reportCancelButtonPressed() {
        dismiss(animated: true)
    }
    
    @objc func reportSeveButtonPressed() {
        print("reportSeveButtonPressed")
        if report == nil {
            let newReport = NSEntityDescription.insertNewObject(forEntityName: "ReportItem", into: manageContext)

            for i in 0..<reportImageViews.count {
                let imageData = reportImageViews[i].image?.jpegData(compressionQuality: 0.1)
                newReport.setValue(imageData, forKey: "snapshot\(i + 1)")
            }
            newReport.setValue(visitTextField.toolbar.datePicker.date, forKey: "visitDate")
            newReport.setValue(startTimeTextField.toolbar.datePicker.date, forKey: "startTime")
            newReport.setValue(endTimeTextField.toolbar.datePicker.date, forKey: "endTime")
            newReport.setValue(tipsTotalStr(), forKey: "tips")
            newReport.setValue(memoTextView.text ?? "", forKey: "memo")
            newReport.setValue(client, forKey: "client")

            do {
                try fetchedReportItemResultsController.managedObjectContext.save()
            } catch let err {
                print("failed save Report - \(err)")
            }
            dismiss(animated: true)
        } else {
            print("report != nil")
            report?.snapshot1 = reportImageViews[0].image?.jpegData(compressionQuality: 0.1)
            report?.snapshot2 = reportImageViews[1].image?.jpegData(compressionQuality: 0.1)
            report?.snapshot3 = reportImageViews[2].image?.jpegData(compressionQuality: 0.1)
            report?.snapshot4 = reportImageViews[3].image?.jpegData(compressionQuality: 0.1)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            if let visitDateStr = visitTextField.text {
                report?.visitDate = formatter.date(from: visitDateStr)
            }
            formatter.dateFormat = "HH:mm"
            if let startTime = startTimeTextField.text {
                report?.startTime = formatter.date(from: startTime)
            }
            if let endTime = endTimeTextField.text {
                report?.endTime = formatter.date(from: endTime)
            }
            report?.tips = tipsTotalStr()
            report?.memo = memoTextView.text ?? ""
            report?.client = client
            do {
                try fetchedReportItemResultsController.managedObjectContext.save()
            } catch let err {
                print("failed save Report - \(err)")
            }
            dismiss(animated: true) { [unowned self] in
                self.reload?(self.report!)
            }
        }
    }
    
    func tipsTotalStr() -> String {
        var tips = String()
        var tipsDec = String()
        if tipsLable.text != nil && tipsLable.text != "" {
            tips = tipsLable.text!
        } else {
            tips = "0"
        }
        if tipsDecimalLable.text != nil && tipsDecimalLable.text != "" {
            tipsDec = tipsDecimalLable.text!
        } else {
            tipsDec = "00"
        }
        let tipsDecStr = String(tipsDec.prefix(2))
        return "\(tips).\(tipsDecStr)"
    }
    
    @objc func tapMenu() {
        print("tapmenu")
        let menuSelectTableVC = MenuSelectTableViewController()
        menuSelectTableVC.delegate = self
        if let report = report {
            // report object
            menuSelectTableVC.reportItem = report
        } else {
            // create a report object
            let newReport = NSEntityDescription.insertNewObject(forEntityName: "ReportItem", into: manageContext)
            menuSelectTableVC.reportItem = newReport as? ReportItem
        }
        
        let menuSelectTableNVC = LightStatusNavigationController(rootViewController: menuSelectTableVC)
        self.present(menuSelectTableNVC, animated: true, completion: nil)
    }
    
    @objc func keyboardWillBeShown(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardFrameHeight = keyboardSize.cgRectValue.height
        
        if visitTextField.isFirstResponder {
            self.view.frame.origin.y = -visitTextField.toolbar.datePicker.frame.height
        }
        else {
            self.view.frame.origin.y = -keyboardFrameHeight
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    // UIParts
    
    let formScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .white
        return sv
    }()
    
    let reportMainImageView: UIImageView = {
        let iv = UIImageView(image: #imageLiteral(resourceName: "person1"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    let subImageView: UIImageView = {
        let iv = UIImageView(image: #imageLiteral(resourceName: "imagePlaceholder"))
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor.lightGray.cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectImage(_:))))
        return iv
    }()

    let subImageSV: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let visitTitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Visit Day"
        lb.font = UIFont.boldSystemFont(ofSize: 12)
        return lb
    }()

    let visitTextField: DatePickerKeyboard = {
        let tf = DatePickerKeyboard()
        tf.contentInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        tf.sizeToFit()
        tf.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        return tf
    }()
    
    let startTimeTitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Start Time"
        lb.font = UIFont.boldSystemFont(ofSize: 12)
        return lb
    }()
    
    let startTimeTextField: TimePickerKeyboard = {
        let lb = TimePickerKeyboard()
        lb.layer.borderWidth = 0
        lb.layer.cornerRadius = 0
        lb.contentInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        lb.sizeToFit()
        lb.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        return lb
    }()
    
    let endTimeTitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "End Time"
        lb.font = UIFont.boldSystemFont(ofSize: 12)
        return lb
    }()
    
    let endTimeTextField: TimePickerKeyboard = {
        let lb = TimePickerKeyboard()
        lb.layer.borderWidth = 0
        lb.layer.cornerRadius = 0
        lb.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        return lb
    }()
    
    let menuTitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Menu"
        lb.constraintWidth(equalToConstant: 60)
        lb.backgroundColor = .red
        lb.font = UIFont.boldSystemFont(ofSize: 12)
        return lb
    }()
    
    let addMenuButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.backgroundColor = UIColor(red: 255/255, green: 162/255, blue: 162/255, alpha: 1)
        bt.setTitle("SELECT MENU", for: .normal)
        bt.setTitleColor(.white, for: .normal)
        bt.constraintWidth(equalToConstant: 200)
        bt.constraintHeight(equalToConstant: 40)
        bt.addTarget(self, action: #selector(tapMenu), for: .touchUpInside)
        bt.setBackgroundColor(UIColor(red: 255/255, green: 162/255, blue: 162/255, alpha: 1), for: .normal)
        bt.setBackgroundColor(UIColor(red: 178/255, green: 114/255, blue: 114/255, alpha: 1), for: .selected)
        bt.layer.cornerRadius = 20
        bt.clipsToBounds = true
        let plusImage = #imageLiteral(resourceName: "plus")
        bt.setImage(plusImage.withRenderingMode(.alwaysOriginal), for: .normal)
        bt.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: plusImage.size.width / 2)
        bt.contentHorizontalAlignment = .center
        return bt
    }()
    
    let menuTableView: UITableView = {
        let tv = UITableView()
        tv.isScrollEnabled = true
        return tv
    }()
    
    let tipsTitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "tips"
        lb.font = UIFont.boldSystemFont(ofSize: 12)
        return lb
    }()
    
    let dollar: UILabel = {
        let lb = UILabel()
        lb.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lb.text = "$"
        lb.font = UIFont.systemFont(ofSize: 16)
        return lb
    }()
    
    let tipsLable: MyTextField = {
        let tf = MyTextField()
        tf.keyboardType = .numberPad
        tf.placeholder = "5"
        tf.constraintWidth(equalToConstant: 65)
        tf.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        return tf
    }()
    
    let dot: UILabel = {
        let lb = UILabel()
        lb.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lb.text = "."
        lb.font = UIFont.systemFont(ofSize: 16)
        return lb
    }()
    
    let tipsDecimalLable: MyTextField = {
        let tf = MyTextField()
        tf.keyboardType = .numberPad
        tf.placeholder = "00"
        tf.constraintWidth(equalToConstant: 50)
        tf.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        return tf
    }()
    
    let memoLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Memo"
        lb.font = UIFont.boldSystemFont(ofSize: 12)
        return lb
    }()

    let memoTextView: MyTextView = {
        let tv = MyTextView()
        tv.constraintHeight(equalToConstant: 300)
        tv.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        tv.font = UIFont.systemFont(ofSize: 18)
        return tv
    }()
}

extension NewReportViewController: UITableViewDelegate, MenuSelectTableViewControllerDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !selectedMenuItemArray.isEmpty {
            return selectedMenuItemArray.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: menuCellId, for: indexPath) as! MenuMasterTableViewCell
        cell.selectionStyle = .none
        if !selectedMenuItemArray.isEmpty {
            cell.menuitemTagLabel.text = selectedMenuItemArray[indexPath.row].menuName
            let color = TagColor.stringToSGColor(str: selectedMenuItemArray[indexPath.row].color!)
            cell.menuitemTagLabel.backgroundColor = color?.rawValue
            cell.priceLabel.text = selectedMenuItemArray[indexPath.row].price
        }
        cell.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func newReportSaveTapped(selectMenu: Set<MenuItem>) {
        selectedMenuItemArray.removeAll()
        selectedMenuItemArray = Array(selectMenu)
        menuTableView.reloadData()
    }
    
}


extension NewReportViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage] as? UIImage {
            reportMainImageView.image = editedImage
            switch selectImageNum {
            case 0:
                reportImageViews[0].image = editedImage
            case 1:
                reportImageViews[1].image = editedImage
            case 2:
                reportImageViews[2].image = editedImage
            case 3:
                reportImageViews[3].image = editedImage
            default:
                print("---")
            }
            
        } else if let originalImage = info[.originalImage] as? UIImage {
            reportImages.append(originalImage)
        }

        picker.dismiss(animated: true, completion: nil)
    }
    
    
}
