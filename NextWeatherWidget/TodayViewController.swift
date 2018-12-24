//
//  TodayViewController.swift
//  NextWeatherWidget
//
//  Created by 東口拓也 on 2018/12/22.
//  Copyright © 2018 TakuyaAzumaguchi. All rights reserved.
//

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

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    // view items
    @IBOutlet weak var todayIcon: UIImageView!
    
    struct Weather : Codable {
        //let link: String
        let pref: Pref
        //let author: String
        //let title: String
        let pubDate: String
        //let description: String
        //let managingEditor: String
    }
    
    struct Pref : Codable {
        let area: Area
        //let id: String
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
        //let geo: Geo
    }
    
    struct Info : Codable {
        let rainFallChance: RainFallChance
        let weather: String
        let date: String
        let img: String
        //let wave: String?
        let temperature: Temperature
        //let weatherDetail: String?
        
        enum CodingKeys: String, CodingKey {
            case rainFallChance = "rainfallchance"
            case weather
            case date
            case img
            //case wave
            case temperature
            //case weatherDetail = "weather_detail"
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
    /*
    struct Geo : Codable {
        let lat: String
        let long: String
    }
    */
    
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
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
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

        // httpsにしないと通信できない
        //let image = sessionIconImage(path: "https://www.drk7.jp/MT/images/MTWeather/201.gif")
        //print(image)
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func updateView(weather: Weather) {
        print(weather.pubDate)
        
        let todayInfo = weather.pref.area.tokyo.info[0]
        let todayImagePath = self.addHttps(path: todayInfo.img)
        print(todayImagePath)
        let image = sessionIconImage(path: todayImagePath)
        
        DispatchQueue.main.async {
            self.todayIcon.image = image
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
    
    func extractionJsonData(string: String) -> String {
        let splitByHeader = string.components(separatedBy: "(")
        let splitByFooter = splitByHeader[1].components(separatedBy: ")")
        return splitByFooter[0]
    }
}
