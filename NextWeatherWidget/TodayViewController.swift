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
        
        let succeededLocal = sessionInfo(ip: "192.168.1.14", timeOut: 0.3)
        if (succeededLocal) {
            completionHandler(NCUpdateResult.newData)
            return
        }
        
        let succeededGlobal = sessionInfo(ip: "0.0.0.0", timeOut: 10)
        if (succeededGlobal) {
            completionHandler(NCUpdateResult.newData)
            return
        }
        
        completionHandler(NCUpdateResult.failed)
        
    }
    
    func sessionInfo(ip: String, timeOut: Double) -> Bool {
        let urlPath = "http://" + ip + ":8080/weather/data/tokyo.json"
        guard let url = URL(string: urlPath) else { return false }
        
        var succeeded = false
        
        let config: URLSessionConfiguration = URLSessionConfiguration.default
        config.timeoutIntervalForResource = timeOut
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
                succeeded = true
            } catch {
                print(error)
            }
        }.resume()
        
        return succeeded
    }
    
    func updateView(info: Info) {
        print(info.city)
        
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
}
