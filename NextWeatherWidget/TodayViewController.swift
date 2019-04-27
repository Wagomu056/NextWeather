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
        
        let succeededLocal = Session(ip: "192.168.1.14", timeOut: 0.3)
        if (succeededLocal) {
            completionHandler(NCUpdateResult.newData)
            return
        }
        
        let succeededGlobal = Session(ip: "0.0.0.0", timeOut: 10)
        if (succeededGlobal) {
            completionHandler(NCUpdateResult.newData)
            return
        }
        
        completionHandler(NCUpdateResult.failed)
    }
    
    func Session(ip: String, timeOut: Double) -> Bool {
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
        let todayTempHigh = info.maxTemp[0].description
        let todayTempLow = info.minTemp[0].description
        
        DispatchQueue.main.async {
            self.todayIcon.image = todayImage
            self.todayTempHigh.text = todayTempHigh + "℃"
            self.todayTempLow.text = todayTempLow + "℃"
        }
        
        let tomorrowImage = sessionIconImage(path: info.image[1])
        let tomorrowTempHigh = info.maxTemp[1].description
        let tomorrowTempLow = info.minTemp[1].description
        
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
}

/* 全データ取得の場合の構造体
 struct Weather : Codable {
 let link: String
 let pref: Pref
 let author: String
 let title: String
 let pubDate: String
 let description: String
 let managingEditor: String
 }
 
 struct Pref : Codable {
 let area: Area
 let id: String
 }
 
 struct Area : Codable {
 let izuSouth: AreaOne
 let ogasawara: AreaOne
 let tokyo: AreaOne
 let izuNorth: AreaOne
 
 enum CodingKeys: String, CodingKey {
 case izuSouth = "伊豆諸島南部"
 case ogasawara = "小笠原諸島"
 case tokyo = "東京地方"
 case izuNorth = "伊豆諸島北部"
 }
 }
 
 struct AreaOne : Codable {
 let info: [Info]
 let geo: Geo
 }
 
 struct Info : Codable {
 let rainFallChance: RainFallChance
 let weather: String
 let date: String
 let img: String
 let wave: String?
 let temperature: Temperature
 let weatherDetail: String?
 
 enum CodingKeys: String, CodingKey {
 case rainFallChance = "rainfallchance"
 case weather
 case date
 case img
 case wave
 case temperature
 case weatherDetail = "weather_detail"
 }
 }
 
 struct RainFallChance : Codable {
 let unit: String
 let period: [RainFallChancePeriod]
 }
 
 struct RainFallChancePeriod : Codable {
 let hour: String
 let content: String
 }
 
 struct Temperature : Codable {
 let unit: String
 let range: [TemperatureRange]
 }
 
 struct TemperatureRange : Codable {
 let centigrade: String
 let content: String
 }
 
 struct Geo : Codable {
 let lat: String
 let long: String
 }
 */
