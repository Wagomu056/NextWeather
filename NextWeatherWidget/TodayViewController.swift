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
        let city : String
        let maxTemp : [Int]
        let minTemp : [Int]
        let image : [String]
    }
    
    struct NetworkInfo {
        var local : String = "0.0.0.0"
        var global : String = "0.0.0.0"
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
        
        var networkInfo = NetworkInfo()
        let succeedNetworkInfo = loadNetworkInfo(info: &networkInfo)
        if !succeedNetworkInfo {
            return
        }
        
        sessionInfo(ip: networkInfo.local, timeout: 1, isAllowCellular: false)
        sessionInfo(ip: networkInfo.global, timeout: 10, isAllowCellular: true)
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func sessionInfo(ip: String, timeout: Double, isAllowCellular: Bool) {
        let urlPath = "http://" + ip + ":8080/weather/data/tokyo.json"
        //NSLog(urlPath)
        guard let url = URL(string: urlPath) else { return }
        
        let config: URLSessionConfiguration = URLSessionConfiguration.default
        config.timeoutIntervalForResource = timeout
        config.allowsCellularAccess = isAllowCellular
        let session: URLSession = URLSession(configuration: config)
        session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            guard let jsonString = String(data: data, encoding: .utf8) else { return }
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
        let todayImage = sessionIconImage(path: info.image[0])
        let todayTempHigh = convertTemperatureToString(tempNum: info.maxTemp[0])
        let todayTempLow = convertTemperatureToString(tempNum: info.minTemp[0])
        
        DispatchQueue.main.async {
            self.todayIcon.image = todayImage
            self.todayTempHigh.text = todayTempHigh + "℃"
            self.todayTempLow.text = todayTempLow + "℃"
        }
        
        let tomorrowImage = sessionIconImage(path: info.image[1])
        let tomorrowTempHigh = convertTemperatureToString(tempNum: info.maxTemp[1])
        let tomorrowTempLow = convertTemperatureToString(tempNum: info.minTemp[1])
        
        DispatchQueue.main.async {
            self.tomorrowIcon.image = tomorrowImage
            self.tomorrowTempHigh.text = tomorrowTempHigh + "℃"
            self.tomorrowTempLow.text = tomorrowTempLow + "℃"
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
    func loadNetworkInfo(info : inout NetworkInfo) -> Bool {
        if let filePath = Bundle.main.path(forResource: NetworkFile, ofType: "txt") {
            do {
                let str = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
                let spritedStr = str.components(separatedBy: ",")
                info.local = spritedStr[0]
                info.global = spritedStr[1]
                return true
            } catch {
                return false
            }
        }
        return false
    }
}
