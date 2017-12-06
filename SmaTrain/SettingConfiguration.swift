//
//  SettingConfiguration.swift
//  SmaTrain
//
//  Created by KentaroAbe on 2017/12/01.
//  Copyright © 2017年 KentaroAbe. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import RealmSwift
import Realm
import SwiftyJSON

class SettingMenuController:UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet var table: UITableView!
    
    let settingArray = ["路線設定"]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "settings")
        cell.textLabel?.text = self.settingArray[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row{
        case 0:
            let nextView = storyboard!.instantiateViewController(withIdentifier: "LineView")
            nextView.modalTransitionStyle = .flipHorizontal
            self.present(nextView, animated: true, completion: nil)
        default:
            break
        }
        
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        self.table.delegate = self
        self.table.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

class LineSet:UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet var LineView: UITableView!
    
    let ap = UIApplication.shared.delegate as! AppDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let json = JsonGet(fileName: "line")
        return json.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "LineView")
        let array = Array(JsonGet(fileName: "line").dictionaryValue)
        
        cell.textLabel?.text = array[indexPath.row].key
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let json = JsonGet(fileName: "line")
        ap.LineName = String(describing:json[(tableView.cellForRow(at: indexPath)?.textLabel?.text)!])
        //print(ap.LineName)
        let nextView = storyboard!.instantiateViewController(withIdentifier: "StationView")
        nextView.modalTransitionStyle = .crossDissolve
        self.present(nextView, animated: true, completion: nil)
    }
    override func viewDidLoad(){
        super.viewDidLoad()
        self.LineView.delegate = self
        self.LineView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func JsonGet(fileName :String) -> JSON {
        let path = Bundle.main.path(forResource: fileName, ofType: "json")
        //print(path)
        
        do{
            let jsonStr = try String(contentsOfFile: path!)
            print(jsonStr)
            
            let json = JSON.parse(jsonStr)
            
            return json
        } catch {
            return nil
        }
        
    }
    @IBAction func returnToMe(segue: UIStoryboardSegue) {
        
    }
}

class StationSet:UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet var StationView: UITableView!
    
    let ap = UIApplication.shared.delegate as! AppDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let database = try! Realm()
        return database.objects(stationData.self).filter("lineCode == %@",ap.LineName).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "StationView")
        let database = try! Realm()
        let data = database.objects(stationData.self).filter("lineCode == %@",ap.LineName).sorted(byKeyPath: "stationID", ascending: true)
        
        //print(data[0].stationCode)
        
        cell.textLabel?.text = data[indexPath.row].stationName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let json = JsonGet(fileName: "line")
        ap.StationName = (self.StationView.cellForRow(at: indexPath)?.textLabel?.text)!
        let database = try! Realm()
        let data = database.objects(stationData.self).filter("stationName == %@ && lineCode == %@",ap.StationName,ap.LineName)
        ////print(data)
        ap.StationName = (data.first?.stationCode)!
        
        //print(ap.StationName)
        
        let nextView = storyboard!.instantiateViewController(withIdentifier: "DirectionView")
        self.present(nextView, animated: true, completion: nil)
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        //print("入りました")
        let database = try! Realm()
        let data = database.objects(stationData.self)
        ////print(data)
        //print(ap.LineName)
        self.StationView.delegate = self
        self.StationView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func JsonGet(fileName :String) -> JSON {
        let path = Bundle.main.path(forResource: fileName, ofType: "json")
        //print(path)
        
        do{
            let jsonStr = try String(contentsOfFile: path!)
            //print(jsonStr)
            
            let json = JSON.parse(jsonStr)
            
            return json
        } catch {
            return nil
        }
        
    }
}

class DirectionSet:UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    
    @IBOutlet var DirectionView: UITableView!
    
    let ap = UIApplication.shared.delegate as! AppDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DirectionView")
        let database = try! Realm()
        var firstStationName = database.objects(stationData.self).filter("lineCode == %@",ap.LineName).sorted(byKeyPath: "stationID", ascending: true).first?.stationName
        var lastStationName = database.objects(stationData.self).filter("lineCode == %@",ap.LineName).sorted(byKeyPath: "stationID", ascending: true).last?.stationName
        if firstStationName?.contains("北綾瀬") == true{
            firstStationName = "綾瀬"
        }
        if lastStationName?.contains("北綾瀬") == true{
            lastStationName = "綾瀬"
        }
        
        let direction = [firstStationName!,lastStationName!]
        
        cell.textLabel?.text = "\(direction[indexPath.row])方面"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let directionName = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let database = try! Realm()
        
        var firstStationName = database.objects(stationData.self).filter("lineCode == %@",ap.LineName).sorted(byKeyPath: "stationID", ascending: true).first?.stationName
        var lastStationName = database.objects(stationData.self).filter("lineCode == %@",ap.LineName).sorted(byKeyPath: "stationID", ascending: true).last?.stationName
        /*
         if firstStationCode?.contains("KitaAyase") == true{
         firstStationCode = firstStationCode?.replacingOccurrences(of: "KitaAyase", with: "Ayase")
         }
         if lastStationCode?.contains("KitaAyase") == true{
         lastStationCode = lastStationCode?.replacingOccurrences(of: "KitaAyase", with: "Ayase")
         }
         */
        let direction = [firstStationName!,lastStationName!]
        
        let data = database.objects(stationData.self).filter("lineCode == %@ && stationName == %@",ap.LineName,direction[indexPath.row])
        var trainDirection = (data.first?.stationCode)!
        
        trainDirection = trainDirection.replacingOccurrences(of: "Station", with: "RailDirection")
        let directionArr = trainDirection.components(separatedBy: ".")
        trainDirection = "\(directionArr[0]).\(directionArr[1]).\(directionArr[3])"
        
        //print(trainDirection)
        
        timeTableInit(StationCode: ap.StationName, LineCode: ap.LineName, TrainDirection: trainDirection)
    
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.DirectionView.delegate = self
        self.DirectionView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func viewTimeTable(){
        let db = try! Realm()
        let data = db.objects(timeTableInTrainInStation.self).sorted(byKeyPath: "time", ascending: true)
        if data.count >= 1{
            for i in 0...data.count-1{
                //print("\(data[i].time)-\(data[i].operationgCode)-\(data[i].trainType)-\(data[i].trainDestination)")
            }
        }
        let nextView = storyboard!.instantiateViewController(withIdentifier: "Main")
        self.present(nextView, animated: true, completion: nil)
    }
    
    func JsonGet(fileName :String) -> JSON {
        let path = Bundle.main.path(forResource: fileName, ofType: "json")
        //print(path)
        
        do{
            let jsonStr = try String(contentsOfFile: path!)
            //print(jsonStr)
            
            let json = JSON.parse(jsonStr)
            
            return json
        } catch {
            return nil
        }
        
    }
    
    let TokyoMetroAccessToken = "12e6c4c1e608511e3dcf26f416d861e261d8efa412992708210f46ba1005161f"
    func timeTableInit(StationCode:String,LineCode:String,TrainDirection:String){ //駅コードと路線コードを取得して時刻表をイニシャライズ
        let db = try! Realm()
        
       
        let alert = UIAlertController(title: "", message: "時刻表を設定中です...", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        var direct = TrainDirection
        
        if TrainDirection.contains("KitaAyase") == true{
            direct = TrainDirection.replacingOccurrences(of: "KitaAyase", with: "Ayase")
        }
        
        let currentData = db.objects(timeTableInTrainInStation.self).filter("lineCode == %@ && stationCode == %@ && trainDirection == %@",LineCode,StationCode,direct)
        if currentData.count != 0{
            //print("データの削除を行います")
            try! db.write {
                db.delete(currentData)
            }
        }
        
        var url = URL(string:"https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:TrainTimetable&odpt:railway=\(LineCode)&owl:sameAs=Weekdays&odpt:railDirection=\(direct)&acl:consumerKey=\(self.TokyoMetroAccessToken)")
        //print(url)
        
        if db.objects(RegisterStationAndDistrict.self).filter("LineCodeInStation == %@ && StationCode = %@ && TrainDirection == %@",LineCode,StationCode,direct).count > 0{
            try! db.write {
                db.delete(db.objects(RegisterStationAndDistrict.self).filter("LineCodeInStation == %@ && StationCode = %@ && TrainDirection == %@",LineCode,StationCode,direct))
            }
        }
        
        
        let object = RegisterStationAndDistrict()
        object.priority = db.objects(RegisterStationAndDistrict.self).count
        object.LineCodeInStation = LineCode
        object.StationCode = StationCode
        let json = JsonGet(fileName: "line")
        let jsonDict = json.dictionary
        let jsonArr = Array(jsonDict!)
        for i in 0...(jsonArr.count)-1{
            //print(jsonArr[i].value)
            if String(describing:jsonArr[i].value) == LineCode{
                object.LineNameInStation = jsonArr[i].key
                //print(jsonArr[i].key)
            }
        }
        object.TrainDirection = direct
        object.StationName = (db.objects(stationData.self).filter("stationCode == %@ && lineCode == %@",StationCode,LineCode).first?.stationName)!
        
        try! db.write {
            db.add(object)
        }
        
        Alamofire.request(url!).responseJSON{response in //平日ダイヤの取得
            if response.result.value != nil{
                var jsonDict = JSON(response.result.value!)
                //print(jsonDict)
                
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "yyyy-MM-dd"
                
                let dateStr = dateFormat.string(from: Date())
                
                for i in 0...jsonDict.count-1{
                    let object = timeTableInTrainInStation()
                    object.trainID = i
                    object.lineCode = LineCode
                    object.stationCode = StationCode
                    object.week = "Weekdays"
                    object.operationgCode = String(describing:jsonDict[i]["odpt:trainNumber"])
                    object.trainType = String(describing:jsonDict[i]["odpt:trainType"])
                    object.trainDestination = String(describing:jsonDict[i]["odpt:terminalStation"])
                    object.trainDirection = String(describing:jsonDict[i]["odpt:railDirection"])
                    if String(describing:jsonDict[i]["odpt:terminalStation"]).contains("TokyoMetro") == false{
                        object.isTrainThrough = true
                    }else{
                        object.isTrainThrough = false
                    }
                    for j in 0...jsonDict[i]["odpt:weekdays"].count-1{
                        if j == jsonDict[i]["odpt:weekdays"].count-1{
                            if String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:arrivalStation"]) == StationCode{
                                object.time = String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:arrivalTime"])
                                let timesRange = String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:arrivalTime"]).range(of: ":")
                                var times = String(describing:jsonDict[i]["odpt:weekdays"][j]["arrivalTime"])
                                //times.removeSubrange(timesRange!)
                                //print(times)
                                
                                times = times.replacingOccurrences(of: ":", with: "")
                                object.timeInt = Int(times)!
                                
                                try! db.write {
                                    db.add(object)
                                }
                            }
                        }else{
                            if String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:departureStation"]) == StationCode{
                                object.time = String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:departureTime"])
                                let timesRange = String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:departureTime"]).range(of: ":")
                                var times = String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:departureTime"])
                                //times.removeSubrange(timesRange!)
                                //print(times)
                                times = times.replacingOccurrences(of: ":", with: "")
                                object.timeInt = Int(times)!
                                
                                try! db.write {
                                    db.add(object)
                                }
                            }
                            
                        }
                    }
                }
                
                let addedData = db.objects(timeTableInTrainInStation.self).filter("lineCode == %@ && stationCode == %@ && trainDirection == %@",LineCode,StationCode,direct).sorted(byKeyPath: "timeInt", ascending: true)
                
                var lastNum = 0
                
                var n = 400
                
                let addedData1 = addedData.filter("timeInt > 400").sorted(byKeyPath: "timeInt", ascending: true)
                
                for i in 0...addedData1.count-1{
                    lastNum = i
                    try! db.write {
                        addedData1[i].trainID = i+1
                    }
                }
                
                let addedData2 = addedData.filter("timeInt < 400").sorted(byKeyPath: "timeInt", ascending: true)
                
                for i in 0...addedData2.count-1{
                    try! db.write {
                        addedData1[i].trainID = lastNum+i+1
                    }
                }
                
            }
        }
        //print("休日ダイヤの取得")
        url = URL(string:"https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:TrainTimetable&odpt:railway=\(LineCode)&owl:sameAs=SaturdaysHolidays&odpt:railDirection=\(direct)&acl:consumerKey=\(self.TokyoMetroAccessToken)")
        Alamofire.request(url!).responseJSON{response in //休日ダイヤの取得
            if response.result.value != nil{
                let jsonDict = JSON(response.result.value!)
                //print(jsonDict)
                for i in 0...jsonDict.count-1{
                    let object = timeTableInTrainInStation()
                    object.trainID = i
                    object.lineCode = LineCode
                    object.stationCode = StationCode
                    object.week = "Holidays"
                    object.operationgCode = String(describing:jsonDict[i]["odpt:trainNumber"])
                    object.trainType = String(describing:jsonDict[i]["odpt:trainType"])
                    object.trainDestination = String(describing:jsonDict[i]["odpt:terminalStation"])
                    object.trainDirection = direct
                    if String(describing:jsonDict[i]["odpt:terminalStation"]).contains("TokyoMetro") == false{
                        object.isTrainThrough = true
                    }else{
                        object.isTrainThrough = false
                    }
                    for j in 0...jsonDict[i]["odpt:holidays"].count-1{
                        if j == jsonDict[i]["odpt:holidays"].count-1{
                            if String(describing:jsonDict[i]["odpt:holidays"][j]["odpt:arrivalStation"]) == StationCode{
                                object.time = String(describing:jsonDict[i]["odpt:holidays"][j]["odpt:arrivalTime"])
                                let timesRange = String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:arrivalTime"]).range(of: ":")
                                var times = String(describing:jsonDict[i]["odpt:holidays"][j]["odpt:departureTime"])
                                //times.removeSubrange(timesRange!)
                                //print(times)
                                times = times.replacingOccurrences(of: ":", with: "")
                                object.timeInt = Int(times)!
                                
                                try! db.write {
                                    db.add(object)
                                }
                            }
                        }else{
                            if String(describing:jsonDict[i]["odpt:holidays"][j]["odpt:departureStation"]) == StationCode{
                                object.time = String(describing:jsonDict[i]["odpt:holidays"][j]["odpt:departureTime"])
                                //print(String(describing:jsonDict[i]["odpt:holidays"][j]["odpt:departureTime"]))
                                let timesRange = String(describing:jsonDict[i]["odpt:weekdays"][j]["odpt:departureTime"]).range(of: ":")
                                var times = String(describing:jsonDict[i]["odpt:holidays"][j]["odpt:departureTime"])
                                //times.removeSubrange(timesRange!)
                                //print(times)
                                times = times.replacingOccurrences(of: ":", with: "")
                                object.timeInt = Int(times)!
                                
                                try! db.write {
                                    db.add(object)
                                }
                            }
                            
                        }
                    }
                }
                
                var lastNum = 0
                
                var n = 400
                let addedData = db.objects(timeTableInTrainInStation.self).filter("lineCode == %@ && stationCode == %@ && trainDirection == %@",LineCode,StationCode,direct).sorted(byKeyPath: "timeInt", ascending: true)
                let addedData1 = addedData.filter("timeInt > 400").sorted(byKeyPath: "timeInt", ascending: true)
                
                for i in 0...addedData1.count-1{
                    lastNum = i
                    try! db.write {
                        addedData1[i].trainID = i+1
                    }
                }
                
                let addedData2 = addedData.filter("timeInt < 400").sorted(byKeyPath: "timeInt", ascending: true)
                
                for i in 0...addedData2.count-1{
                    try! db.write {
                        addedData1[i].trainID = lastNum+i+1
                    }
                }
                
                var isAnimate = true
                alert.dismiss(animated: true, completion: {
                    self.ap.isFinishRegister = true
                    self.viewTimeTable()
                })
                
                
            }
            
        }
    }
    
}
