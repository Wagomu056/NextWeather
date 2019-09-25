//
//  TodayViewController.swift
//  NextWeatherWidget
//
//  Created by 東口拓也 on 2018/12/22.
//  Copyright © 2018 TakuyaAzumaguchi. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    // view items
    @IBOutlet weak var todayIcon: UIImageView!
    @IBOutlet weak var todayTempHigh: UILabel!
    @IBOutlet weak var todayTempLow: UILabel!
    
    @IBOutlet weak var tomorrowIcon: UIImageView!
    @IBOutlet weak var tomorrowTempHigh: UILabel!
    @IBOutlet weak var tomorrowTempLow: UILabel!
    
    // struct for json
    struct Info : Codable {
        let date : [Int]
        let max_temp : [Int]
        let min_temp : [Int]
        let image : [String]
        let image_root : String
    }
    
    // main functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let networkStr = loadNetworkInfo()
        guard let _networkStr = networkStr else { return }
        sessionInfo(ip: _networkStr, timeout: 10)
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func sessionInfo(ip: String, timeout: Double) {
        let urlPath = "http://" + ip + "/weather/data/tokyo.json"
        guard let url = URL(string: urlPath) else { return }
        print(url)
        
        let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = timeout
        let session: URLSession = URLSession(configuration: config)
        session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { print("data is empty"); return }
            guard let jsonString = String(data: data, encoding: .utf8) else { print("faild to string"); return }
            guard let extractedData = jsonString.data(using: .utf8) else { return }
            
            do {
                let info = try JSONDecoder().decode(Info.self, from: extractedData)
                self.updateView(info: info)
            } catch {
                print(error)
            }
        }.resume()
    }
    
    func updateView(info: Info) {
        let todayImage = sessionIconImage(path: info.image_root + info.image[0])
        let todayTempHigh = convertTemperatureToString(tempNum: info.max_temp[0])
        let todayTempLow = convertTemperatureToString(tempNum: info.min_temp[0])
        
        DispatchQueue.main.async {
            self.todayIcon.image = todayImage
            self.todayTempHigh.text = todayTempHigh + "℃"
            self.todayTempHigh.textColor = .systemRed
            self.todayTempLow.text = todayTempLow + "℃"
            self.todayTempLow.textColor = .systemBlue
        }
        
        let tomorrowImage = sessionIconImage(path: info.image_root + info.image[1])
        let tomorrowTempHigh = convertTemperatureToString(tempNum: info.max_temp[1])
        let tomorrowTempLow = convertTemperatureToString(tempNum: info.min_temp[1])
        
        DispatchQueue.main.async {
            self.tomorrowIcon.image = tomorrowImage
            self.tomorrowTempHigh.text = tomorrowTempHigh + "℃"
            self.tomorrowTempHigh.textColor = .systemRed
            self.tomorrowTempLow.text = tomorrowTempLow + "℃"
            self.tomorrowTempLow.textColor = .systemBlue
        }
    }
    
    func sessionIconImage(path: String) -> UIImage? {
        guard let url = URL(string: path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        return UIImage(data: data)
    }
    
    let InvalidTemperature = 99
    func convertTemperatureToString(tempNum: Int) -> String
    {
        if tempNum == InvalidTemperature {
            return "--"
        }
        
        return tempNum.description
    }
    
    let NetworkFile = "network"
    func loadNetworkInfo() -> String? {
        if let filePath = Bundle.main.path(forResource: NetworkFile, ofType: "txt") {
            do {
                let str = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
                let split = str.components(separatedBy: ",")
                return split[0]
            } catch {
                return nil
            }
        }
        return nil
    }
}
