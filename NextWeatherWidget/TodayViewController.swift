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
    struct Weather : Codable {
        let pref: Pref
        let pubDate: String
    }
    
    struct Pref : Codable {
        let area: Area
    }
    
    struct Area : Codable {
        //let izuSouth: AreaOne
        //let ogasawara: AreaOne
        let tokyo: AreaOne
        //let izuNorth: AreaOne
        
        enum CodingKeys: String, CodingKey {
            //case izuSouth = "伊豆諸島南部"
            //case ogasawara = "小笠原諸島"
            case tokyo = "東京地方"
            //case izuNorth = "伊豆諸島北部"
        }
    }
    
    struct AreaOne : Codable {
        let info: [Info]
    }
    
    struct Info : Codable {
        let rainFallChance: RainFallChance
        let weather: String
        let date: String
        let img: String
        let temperature: Temperature
        
        enum CodingKeys: String, CodingKey {
            case rainFallChance = "rainfallchance"
            case weather
            case date
            case img
            case temperature
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
        
        let urlPath = "https://www.drk7.jp/weather/json/13.js"
        guard let url = URL(string: urlPath) else { return }
        
        let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
        let session: URLSession = URLSession(configuration: config)
        session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            guard let dataString = String(data: data, encoding: .utf8) else { return }
            let jsonString = self.extractionJsonData(string: dataString)
            guard let extractedData = jsonString.data(using: .utf8) else { return }
            
            do {
                let weather = try JSONDecoder().decode(Weather.self, from: extractedData)
                self.updateView(weather: weather)
            } catch {
                print(error)
            }
        }.resume()
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func updateView(weather: Weather) {
        print(weather.pubDate)
        
        let todayInfo = weather.pref.area.tokyo.info[0]
        let todayImagePath = self.addHttps(path: todayInfo.img)
        let todayImage = sessionIconImage(path: todayImagePath)
        let todayTempHigh = getTemperature(info: todayInfo, type: "max")
        let todayTempLow = getTemperature(info: todayInfo, type: "min")
        
        DispatchQueue.main.async {
            self.todayIcon.image = todayImage
            self.todayTempHigh.text = todayTempHigh + "℃"
            self.todayTempLow.text = todayTempLow + "℃"
        }
        
        let tomorrowInfo = weather.pref.area.tokyo.info[1]
        let tomorrowImagePath = self.addHttps(path: tomorrowInfo.img)
        let tomorrowImage = sessionIconImage(path: tomorrowImagePath)
        let tomorrowTempHigh = getTemperature(info: tomorrowInfo, type: "max")
        let tomorrowTempLow = getTemperature(info: tomorrowInfo, type: "min")
        
        DispatchQueue.main.async {
            self.tomorrowIcon.image = tomorrowImage
            self.tomorrowTempHigh.text = tomorrowTempHigh + "℃"
            self.tomorrowTempLow.text = tomorrowTempLow + "℃"
        }
    }
    
    func addHttps(path: String) -> String {
        var strings = path.split(separator: ":")
        strings[0] = strings[0] + "s:"
        
        var addedHttpsString = ""
        for str in strings {
            addedHttpsString += str
        }
        
        return addedHttpsString
    }
    
    func sessionIconImage(path: String) -> UIImage? {
        guard let url = URL(string: path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        return UIImage(data: data)
    }
    
    func getTemperature(info: Info, type: String) -> String {
        let ranges = info.temperature.range
        for range in ranges {
            if range.centigrade == type {
                return range.content
            }
        }
        return "Err"
    }
    
    func extractionJsonData(string: String) -> String {
        let splitByHeader = string.components(separatedBy: "(")
        let splitByFooter = splitByHeader[1].components(separatedBy: ")")
        return splitByFooter[0]
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
