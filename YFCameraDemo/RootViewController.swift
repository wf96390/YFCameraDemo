//
//  RootViewController.swift
//  YFCameraDemo
//
//  Created by wangfeng on 16/12/9.
//  Copyright © 2016年 abc. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView: UITableView = UITableView()
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.white
        self.title = "Demo"
        tableView.delegate = self
        tableView.dataSource = self
        var frame = self.view.frame
        frame.origin.y = 60
        tableView.frame = frame
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RootViewControllerCell")
        self.view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RootViewControllerCell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "识别视频"
        case 1:
            cell.textLabel?.text = "识别照片"
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let vc = VideoViewController();
            self.present(vc, animated: true, completion: nil)
        case 1:
            break
        default:
            break
        }
    }
}
