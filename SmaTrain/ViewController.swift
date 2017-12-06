//
//  ViewController.swift
//  SmaTrain
//
//  Created by KentaroAbe on 2017/11/19.
//  Copyright © 2017年 KentaroAbe. All rights reserved.
//

import UIKit
import Alamofire
import Realm
import RealmSwift
import SwiftyJSON
import CalculateCalendarLogic

struct trains { //画面上に表示するべきデータ
    var lineCode:String
    var trainID:String
    var destination:String
    var direction:String
    var time:String
    var trainType:String
    var delayTime:Int
    var InfoTxt:String
}

struct trainTimeTables { //時刻表
    var lineCode:String
    var trainID:String
    var destination:String
    var direction:String
    var time:String
    var trainType:String
}

struct allTrainsInLine { //全列車の情報
    var lineCode:String
    var trainID:String
    var destination:String
    var trainDirection:String
    var delayTime:Int
    var trainType:String
    var fromStation:String
}

class TrainTableViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    func JsonGet(fileName :String) -> JSON {
        let path = Bundle.main.path(forResource: fileName, ofType: "json")
        ////print(path)
        
        do{
            let jsonStr = try String(contentsOfFile: path!)
            //print(jsonStr)
            
            let json = JSON.parse(jsonStr)
            
            return json
        } catch {
            return nil
        }
        
    }
    
    var linesJP = [String]()
    var stationsJP = [String]()
    var directionsJP = [String]()
    var lines = [String]()
    var stations = [String]()
    var directions = [String]()
    var linesAndDirections_Jp = [String]()
    var trainLocationData = [String:JSON]()
    
    var allTrainDataRealTime = [String:allTrainsInLine]()
    var localTrainDataRealTime = [String:[trains]]()
    
    var isLoadFinished = false
    
    let db = try! Realm()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return linesAndDirections_Jp.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return linesAndDirections_Jp[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func GetTrainLocation(line:String,lineInArray:Int) -> JSON{ //既にJSONをダウンロード済みであればローカルのキャッシュを返し、存在していなければ新たにダウンロードする処理
        if self.trainLocationData["\(line)-\(String(describing:lineInArray))"] != nil{
            return self.trainLocationData["\(line)-\(String(describing:lineInArray))"]!
        }else{
            let url = URL(string: "https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Train&odpt:railway=\(lines[lineInArray])&odpt:railDirection=\(directions[lineInArray])&acl:consumerKey=\(self.TokyoMetroAccessToken)")
            ////print(url)
            var json:JSON = nil
            var isCompleteDataGetted = true
            Alamofire.request(url!).responseJSON{response in
                isCompleteDataGetted = false
                if response.result.value != nil{
                    json = JSON(response.result.value)
                    self.trainLocationData[line] = json
                }else{
                    //print("エラー")
                }
            }
            //print(json.count)
            
            let runLoop = RunLoop.current
            while isCompleteDataGetted &&
                runLoop.run(mode: RunLoopMode.defaultRunLoopMode, before: NSDate(timeIntervalSinceNow: 0.1) as Date) {
                    //print("まだ取得が終わっていません")
            }
            //print("JSONの取得完了")
            print(json)
            self.trainLocationData["\(line)-\(String(describing:lineInArray))"] = json
            
            return json
        }
    }
    
    func trainInfoRenew(IDinArray:Int) -> [trains] {
        
        if localTrainDataRealTime["\(self.lines[IDinArray])&\(self.stations[IDinArray])&\(self.directions[IDinArray])"] != nil{ //ローカルにデータがある場合は再利用
            return localTrainDataRealTime["\(self.lines[IDinArray])&\(self.stations[IDinArray])&\(self.directions[IDinArray])"]!
        }else{
            var jsonDict = GetTrainLocation(line: lines[IDinArray], lineInArray: IDinArray)
            
            
            var trainsOfLine = [trains]()
            var trainTimeTable = [Int:trainTimeTables]()
            var localTrains = [Int:allTrainsInLine]()
            
            var weeks = ["Weekdays","Holidays"]
            var isWeekday = 0
            
            let rawDate = Date()
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd"
            let date = format.string(from: rawDate)
            
            let dateStrs = date.split(separator: "-")
            
            let holidayCheck = CalculateCalendarLogic()
            if holidayCheck.judgeJapaneseHoliday(year: Int(String(describing:dateStrs[0]))!, month: Int(String(describing:dateStrs[1]))!, day: Int(String(describing:dateStrs[2]))!) == true{
                isWeekday = 1
            }else{
                isWeekday = 0
            }
            
            var lineContent = db.objects(timeTableInTrainInStation.self).filter("lineCode = %@ && stationCode == %@ && trainDirection == %@ && week == %@",self.lines[IDinArray],self.stations[IDinArray],self.directions[IDinArray],weeks[isWeekday]).sorted(byKeyPath: "trainID", ascending: true)
            
            //print(lineContent)
            
            //print(self.lines[IDinArray])
            //print(self.stations[IDinArray])
            //print(self.directions[IDinArray])
            
            for i in 0...lineContent.count-1{
                let train = trainTimeTables(lineCode: lineContent[i].lineCode, trainID: lineContent[i].operationgCode, destination: lineContent[i].trainDestination, direction: lineContent[i].trainDirection, time: lineContent[i].time, trainType: lineContent[i].trainType)
                trainTimeTable[i] = train
            }
            
            var needCheckStations = [String]()
            var setLineCode = self.lines[IDinArray]
            var setDirection = self.directions[IDinArray]
            
            var setStation = setDirection.replacingOccurrences(of: "TokyoMetro.", with: "TokyoMetro.\(setLineCode.split(separator: ".").last!).")
            ////print(setStation)
            
            var isAscend = true
            
            let chkStationData = db.objects(stationData.self)
            
            if chkStationData.filter("stationCode == %@ && lineCode == %@",setStation.replacingOccurrences(of: "RailDirection", with: "Station"),self.lines[IDinArray]).first!.stationID != 1{
                isAscend = true
            }else{
                isAscend = false
            }
            
            for i in 0...jsonDict.count{
                let lineCode = self.lines[IDinArray]
                let trainID:String? = String(describing:jsonDict[jsonDict.count-1-i]["odpt:trainNumber"])
                let destination:String? = String(describing:jsonDict[jsonDict.count-1-i]["odpt:terminalStation"])
                ////print(String(describing:jsonDict[(trainTimeTable[i]?.trainID)!]["odpt:delay"]))
                let delayTime:Int? = Int(String(describing:jsonDict[jsonDict.count-1-i]["odpt:delay"]))
                let trainType:String? = String(describing:jsonDict[jsonDict.count-1-i]["odpt:trainType"])
                let fromStation:String? = String(describing:jsonDict[jsonDict.count-1-i]["odpt:fromStation"])
                let trainDirection:String? = String(describing:jsonDict[jsonDict.count-1-i]["odpt:railDirection"])
                var data:allTrainsInLine?
                if trainID != nil && destination != nil && trainType != nil && fromStation != nil{
                    if delayTime != nil{
                        data = allTrainsInLine(lineCode: lineCode, trainID: trainID!, destination: destination!, trainDirection: trainDirection!, delayTime: delayTime!, trainType: trainType!, fromStation: fromStation!)
                    }else{
                        data = allTrainsInLine(lineCode: lineCode, trainID: trainID!, destination: destination!, trainDirection: trainDirection!, delayTime: 0, trainType: trainType!, fromStation: fromStation!)
                    }
                    localTrains[i] = data
                }
            }
            
            let RawOfNeedChkStations = chkStationData.filter("lineCode == %@",self.lines[IDinArray]).sorted(byKeyPath: "stationID", ascending: isAscend)
            
            for i in 0...RawOfNeedChkStations.count-1{
                if RawOfNeedChkStations[i].stationCode != self.stations[IDinArray]{
                    needCheckStations.append(RawOfNeedChkStations[i].stationCode)
                }else{
                    break
                }
            }
            
            //print(needCheckStations)
            
            let stationStopData = JsonGet(fileName: "stopStations")
            let optionalData = JsonGet(fileName: "optional_Info")
            
            var dontStopTrainType = [String]()
            var ExpressAvailable = [String]()
            
            let types = db.objects(ExpressData.self)
            
            for i in 0...types.count-1{
                if ExpressAvailable.contains(types[i].lineCode) == false{
                    ExpressAvailable.append(types[i].lineCode)
                }
            }
            
            lineContent = db.objects(timeTableInTrainInStation.self).filter("lineCode = %@ && stationCode == %@ && trainDirection == %@ && week == %@",self.lines[IDinArray],self.stations[IDinArray],self.directions[IDinArray],weeks[isWeekday]).sorted(byKeyPath: "trainID", ascending: true)
            //print(lineContent)
            
            for i in 0...localTrains.count-1{
                if trainsOfLine.count < 3{
                    let intagers = ["1","2","3","4","5","6","7","8","9","0"]
                    let stopTypes = db.objects(ExpressData.self).filter("lineCode == %@ && stationCode == %@",self.lines[IDinArray],self.stations[IDinArray])
                    //print(stopTypes)
                    if stopTypes.count > 0{
                        for n in 0...stopTypes.count-1{
                            if stopTypes[n].typeName == localTrains[i]?.trainType{
                                if stopTypes[n].stationCode == self.stations[IDinArray]{
                                    dontStopTrainType.append(stopTypes[n].typeName)
                                }
                            }
                        }
                    }
                    if lines[IDinArray] == "odpt.Railway:TokyoMetro.Ginza" || lines[IDinArray] == "odpt.Railway:TokyoMetro.Marunouchi"{
                        
                        let format = DateFormatter()
                        format.dateFormat = "HHmm"
                        let str = format.string(from: Date())
                        let str_Int = Int(str)!
                        
                        print(str)
                        
                        lineContent = lineContent.filter("timeInt >= %@",str_Int).sorted(byKeyPath: "trainID", ascending: true)
                        //print(localTrains[i]!.trainType)
                        if ExpressAvailable.contains(localTrains[i]!.lineCode) == true{
                            if localTrains[i]!.trainType != "odpt.TrainType:TokyoMetro.Local"{
                                if dontStopTrainType.contains(localTrains[i]!.trainType) == false{
                                    print("停車しない種別です")
                                }else{
                                    if needCheckStations.contains(localTrains[i]!.destination) == false{
                                        if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                            var data:trains?
                                            if localTrains[i]?.delayTime != nil{
                                                
                                                //print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                                ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                                data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                            }else{
                                                data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                            }
                                            print(data)
                                            trainsOfLine.append(data!)
                                        }
                                    }
                                    
                                }
                            }else{
                                if needCheckStations.contains(localTrains[i]!.destination) == false{
                                    if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                        var data:trains?
                                        if localTrains[i]?.delayTime != nil{
                                            
                                            print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                            ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                            data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                        }else{
                                            data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                        }
                                        trainsOfLine.append(data!)
                                    }
                                }
                            }
                        }else{
                            if needCheckStations.contains(localTrains[i]!.destination) == false{
                                if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                    var data:trains?
                                    if localTrains[i]?.delayTime != nil{
                                        
                                        //print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                        ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                        data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                    }else{
                                        data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                    }
                                    trainsOfLine.append(data!)
                                }
                            }
                            
                        }
                        
                    }else{
                        if intagers.contains(String(localTrains[i]!.trainID.suffix(1))) == false{
                            let format = DateFormatter()
                            format.dateFormat = "HHmm"
                            let str = format.string(from: Date())
                            let str_Int = Int(str)!
                            
                            print(str)
                            
                            lineContent = lineContent.filter("timeInt >= %@",str_Int).sorted(byKeyPath: "trainID", ascending: true)
                            //print(localTrains[i]!.trainType)
                            if ExpressAvailable.contains(localTrains[i]!.lineCode) == true{
                                if localTrains[i]!.trainType != "odpt.TrainType:TokyoMetro.Local"{
                                    if dontStopTrainType.contains(localTrains[i]!.trainType) == false{
                                        print("停車しない種別です")
                                    }else{
                                        if needCheckStations.contains(localTrains[i]!.destination) == false{
                                            if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                                var data:trains?
                                                if localTrains[i]?.delayTime != nil{
                                                    
                                                    //print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                                    ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                                    data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                                }else{
                                                    data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                                }
                                                print(data)
                                                trainsOfLine.append(data!)
                                            }
                                        }
                                        
                                    }
                                }else{
                                    if needCheckStations.contains(localTrains[i]!.destination) == false{
                                        if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                            var data:trains?
                                            if localTrains[i]?.delayTime != nil{
                                                
                                                print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                                ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                                data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                            }else{
                                                data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                            }
                                            trainsOfLine.append(data!)
                                        }
                                    }
                                }
                            }else{
                                if needCheckStations.contains(localTrains[i]!.destination) == false{
                                    if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                        var data:trains?
                                        if localTrains[i]?.delayTime != nil{
                                            
                                            //print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                            ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                            data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                        }else{
                                            data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                        }
                                        trainsOfLine.append(data!)
                                    }
                                }
                                
                            }
                        }else{
                            let format = DateFormatter()
                            format.dateFormat = "HHmm"
                            let str = format.string(from: Date())
                            let str_Int = Int(str)!
                            
                            print(str)
                            
                            lineContent = lineContent.filter("timeInt >= %@",str_Int).sorted(byKeyPath: "trainID", ascending: true)
                            //print(localTrains[i]!.trainType)
                            if ExpressAvailable.contains(localTrains[i]!.lineCode) == true{
                                if localTrains[i]!.trainType != "odpt.TrainType:TokyoMetro.Local"{
                                    if dontStopTrainType.contains(localTrains[i]!.trainType) == false{
                                        print("停車しない種別です")
                                    }else{
                                        if needCheckStations.contains(localTrains[i]!.destination) == false{
                                            if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                                var data:trains?
                                                if localTrains[i]?.delayTime != nil{
                                                    
                                                    //print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                                    ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                                    data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                                }else{
                                                    data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                                }
                                                print(data)
                                                trainsOfLine.append(data!)
                                            }
                                        }
                                        
                                    }
                                }else{
                                    if needCheckStations.contains(localTrains[i]!.destination) == false{
                                        if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                            var data:trains?
                                            if localTrains[i]?.delayTime != nil{
                                                
                                                print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                                ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                                data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                            }else{
                                                data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                            }
                                            trainsOfLine.append(data!)
                                        }
                                    }
                                }
                            }else{
                                if needCheckStations.contains(localTrains[i]!.destination) == false{
                                    if needCheckStations.contains(localTrains[i]!.fromStation) == true{
                                        var data:trains?
                                        if localTrains[i]?.delayTime != nil{
                                            
                                            //print("\(localTrains[i]!.trainID)：\(lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first?.time)")
                                            ////print(lineContent.filter("lineCode == %@ && trainDirection == %@",localTrains[i]!.lineCode,directions[IDinArray]))
                                            data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: localTrains[i]!.delayTime, InfoTxt: "")
                                        }else{
                                            data = trains(lineCode: localTrains[i]!.lineCode, trainID: localTrains[i]!.trainID, destination: localTrains[i]!.destination, direction: localTrains[i]!.trainDirection, time: lineContent.filter("operationgCode == %@",localTrains[i]!.trainID).first!.time, trainType: localTrains[i]!.trainType, delayTime: 0, InfoTxt: "")
                                        }
                                        trainsOfLine.append(data!)
                                    }
                                }
                                
                            }
                            
                        }
                    }
                }else{
                    break
                }
            }
            
            if trainsOfLine.count < 3 && trainsOfLine.count != 0{
                let format = DateFormatter()
                format.dateFormat = "HHmm"
                let str = format.string(from: Date())
                let str_Int = Int(str)!
                
                print(str)
                
                lineContent = lineContent.filter("timeInt >= %@",str_Int).sorted(byKeyPath: "trainID", ascending: true)
                for i in 0...lineContent.count-1{
                    //print(i)
                    if lineContent[i].operationgCode == trainsOfLine.last!.trainID{
                        for j in 1...3{
                            if i+j > lineContent.count-1{
                                let lastNumber = lineContent.count-1
                                for k in j...lastNumber{
                                    let data = trains(lineCode: lineContent[k].lineCode, trainID: lineContent[k].operationgCode, destination: lineContent[k].trainDestination, direction: lineContent[k].trainDirection, time: lineContent[k].time, trainType: lineContent[k].trainType, delayTime: 0, InfoTxt: "")
                                    print(data)
                                    
                                    trainsOfLine.append(data)
                                }
                                if trainsOfLine.count < 3{
                                    //print(trainsOfLine.count)
                                    for k in trainsOfLine.count...3{
                                        let data = trains(lineCode: "", trainID: "運行終了", destination: "運行終了", direction: "", time: "運行終了", trainType: "運行終了", delayTime: 0, InfoTxt: "")
                                        
                                        trainsOfLine.append(data)
                                    }
                                }
                            }else{
                                let data = trains(lineCode: lineContent[i+j].lineCode, trainID: lineContent[i+j].operationgCode, destination: lineContent[i+j].trainDestination, direction: lineContent[i+j].trainDirection, time: lineContent[i+j].time, trainType: lineContent[i+j].trainType, delayTime: 0, InfoTxt: "")
                                
                                trainsOfLine.append(data)
                            }
                        }
                        break
                    }
                }
            }
            
            if trainsOfLine.count == 0{
                /*
                 for i in 0...lineContent.count-1{
                 for j in 1...3{
                 if i+j > lineContent.count-1{
                 let lastNumber = lineContent.count-1
                 for k in j...lastNumber{
                 let data = trains(lineCode: lineContent[i+j].lineCode, trainID: lineContent[i].operationgCode, destination: lineContent[i+j].trainDestination, direction: lineContent[i+j].trainDirection, time: lineContent[i+j].time, trainType: lineContent[i+j].trainType, delayTime: 0, InfoTxt: "")
                 
                 trainsOfLine.append(data)
                 }
                 for k in lastNumber+1...3{
                 let data = trains(lineCode: "", trainID: "運行終了", destination: "運行終了", direction: "", time: "運行終了", trainType: "運行終了", delayTime: 0, InfoTxt: "")
                 
                 trainsOfLine.append(data)
                 }
                 }else{
                 let data = trains(lineCode: lineContent[i+j].lineCode, trainID: lineContent[i].operationgCode, destination: lineContent[i+j].trainDestination, direction: lineContent[i+j].trainDirection, time: lineContent[i+j].time, trainType: lineContent[i+j].trainType, delayTime: 0, InfoTxt: "")
                 
                 trainsOfLine.append(data)
                 }
                 }
                 break
                 
                 }*/
                let format = DateFormatter()
                format.dateFormat = "HHmm"
                let str = format.string(from: Date())
                let str_Int = Int(str)!
                
                lineContent = lineContent.filter("timeInt >= %@",str_Int).sorted(byKeyPath: "trainID", ascending: true)
                
                for i in 0...3{
                    let data = trains(lineCode: lineContent[i].lineCode, trainID: lineContent[i].operationgCode, destination: lineContent[i].trainDestination, direction: lineContent[i].trainDirection, time: lineContent[i].time, trainType: lineContent[i].trainType, delayTime: 0, InfoTxt: "")
                    trainsOfLine.append(data)
                }
            }
            
            //print(trainsOfLine)
            //trainsOfLine.reverse()
            self.localTrainDataRealTime["\(self.lines[IDinArray])&\(self.stations[IDinArray])&\(self.directions[IDinArray])"] = trainsOfLine
            
            return trainsOfLine
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainViewCell") as! TableViewCell
        //var jsonDict = GetTrainLocation(line: lines[indexPath.section], lineInArray: indexPath.section)
        
        let data = trainInfoRenew(IDinArray: indexPath.section)
        var destination = ""
        var trainType = ""
        
        //print(data.count)
        if data[indexPath.row].destination.contains("TokyoMetro") == true{
            let json = JsonGet(fileName: "metro_stationDict")
            destination = String(describing:json[String(describing:data[indexPath.row].destination.split(separator: ".")[3])])
        }else{
            if data[indexPath.row].destination == "運行終了"{
                destination = data[indexPath.row].destination
            }else{
                let json = JsonGet(fileName: "other_stationDict")
                destination = String(describing:json[data[indexPath.row].destination])
            }
        }
        var delayTimeInMinute = 0
        if data[indexPath.row].delayTime != 0{
            delayTimeInMinute = data[indexPath.row].delayTime/60
        }
        
        if destination.contains("<スカイツリー前>") == true{
            destination = destination.replacingOccurrences(of: "<スカイツリー前>", with: " ")
        }
        if destination.contains("<原宿>") == true{
            destination = destination.replacingOccurrences(of: "<原宿>", with: " ")
        }
        if data[indexPath.row].time == "運行終了"{
            trainType = ""
            cell.depTime.text = data[indexPath.row].time
        }else{
            let json = JsonGet(fileName: "train_types")
            trainType = String(describing:json[data[indexPath.row].trainType])
            cell.destination.text = destination
            cell.depTime.text = data[indexPath.row].time
            cell.trainType.text = trainType
        }
        
        if delayTimeInMinute != 0{
            cell.trainInfo.text = "遅れ：\(delayTimeInMinute)分"
            cell.trainInfo.textColor = UIColor.red
        }else{
            cell.trainInfo.text = "遅れなし"
            cell.trainInfo.textColor = UIColor.black
        }
        
        switch trainType{
        case "急行":
            cell.trainType.textColor = UIColor.red
        case "準急":
            cell.trainType.textColor = UIColor.green
        case "快速":
            cell.trainType.textColor = UIColor.blue
        case "S-TRAIN":
            cell.trainType.textColor = UIColor.red
        case "快速":
            cell.trainType.textColor = UIColor.blue
        case "多摩急行":
            cell.trainType.textColor = UIColor.purple
        case "Fライナー":
            cell.trainType.textColor = UIColor.red
        default:
            cell.trainType.textColor = UIColor.black
        }
        return cell
    }
    
    let TokyoMetroAccessToken = "12e6c4c1e608511e3dcf26f416d861e261d8efa412992708210f46ba1005161f"
    let tokyuURL = "https://tokyu-tid.s3.amazonaws.com/dento.json"
    
    
    @IBOutlet var MainView: UITableView!
    func timeTableInit() {
        if stations.count != 0{
            lines.removeAll()
            stationsJP.removeAll()
            directions.removeAll()
            linesAndDirections_Jp.removeAll()
            linesJP.removeAll()
            stations.removeAll()
        }
    }
    
    
    @IBAction func renew(_ sender: Any) {
        self.allTrainDataRealTime.removeAll()
        self.localTrainDataRealTime.removeAll()
        self.trainLocationData.removeAll()
        let alert = UIAlertController(title: "更新中...", message: "", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        
        self.MainView.reloadData()
        alert.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let json = JsonGet(fileName: "line")
        let ap = UIApplication.shared.delegate as! AppDelegate
        if ap.isFinishRegister == true{
            let OKMenu = UIAlertController(title: "時刻表の登録が完了しました", message: "", preferredStyle: .alert)
            let OKButton = UIAlertAction(title: "OK", style: .default, handler:{action in
            })
            OKMenu.addAction(OKButton)
            self.present(OKMenu, animated: false, completion: nil)
        }
        
        let lineDic = json.dictionaryObject
        
        let lineKeys:Array = Array(lineDic!.keys)
        
        ////print(lineKeys)
        
        for i in 0...lineKeys.count-1{
            //print("\(lineKeys[i])の路線コードは\(String(describing:json[lineKeys[i]]))です")
        }
        
        stationInit()
        
        let db = try! Realm()
        
        let data = db.objects(RegisterStationAndDistrict.self)
        ////print(data)
        if data.count >= 1{
            for i in 0...data.count-1{
                let stationStr = data[i].TrainDirection.replacingOccurrences(of: "RailDirection", with: "Station")
                linesJP.append(data[i].LineNameInStation)
                stationsJP.append(data[i].StationName)
                lines.append(data[i].LineCodeInStation)
                stations.append(data[i].StationCode)
                directions.append(data[i].TrainDirection)
                
                let lineStr = (data[i].LineCodeInStation.split(separator: "."))[2]
                let stationName = db.objects(stationData.self).filter("stationCode == %@",stationStr.replacingOccurrences(of: "TokyoMetro.", with: "TokyoMetro.\(String(describing:lineStr))."))
                let str = "\(data[i].LineNameInStation)　\(data[i].StationName)駅　\(stationName.first!.stationName)方面"
                self.linesAndDirections_Jp.append(str)
                ////print(str)
            }
        }
        
        print(lines)
        print(directions)
        print(stations)
        
        MainView.delegate = self
        MainView.dataSource = self
        MainView.rowHeight = 100.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stationInit(){
        let url = URL(string:"https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Station&acl:consumerKey=\(self.TokyoMetroAccessToken)")
        
        Alamofire.request(url!).responseJSON{response in
            if response.result.value != nil{
                let database = try! Realm()
                
                try! database.write { //データが取得できたら、ローカルのデータは削除する
                    database.delete(database.objects(stationData.self))
                }
                let jsonDict = JSON(response.result.value!)
                for i in 0...jsonDict.count-1{ //取得できたJSONの数だけ繰り返す
                    //print("\(String(describing:jsonDict[i]["odpt:railway"]))線-\(String(describing:jsonDict[i]["dc:title"]))駅")
                    let object = stationData()
                    object.lineCode = String(describing:jsonDict[i]["odpt:railway"])
                    object.stationName = String(describing:jsonDict[i]["dc:title"])
                    object.operatorName = "TokyoMetro"
                    var stationIDRaw = String(describing:jsonDict[i]["odpt:stationCode"])
                    stationIDRaw.remove(at: stationIDRaw.startIndex) //路線IDから路線記号を除く（例：半蔵門線渋谷-> Z01 -> 01）
                    object.stationCode = String(describing:jsonDict[i]["owl:sameAs"])
                    object.stationID = Int(stationIDRaw)! //路線記号を取り除いた路線IDをIntにして代入
                    
                    let database = try! Realm()
                    
                    try! database.write {
                        database.add(object)
                    }
                }
                
                ///***以下テスト表示（半蔵門線の駅名を表示）***///
                let HanzomonLineCode = "odpt.Railway:TokyoMetro.Hanzomon"
                
                let HanzomonLine = database.objects(stationData.self).filter("lineCode == %@",HanzomonLineCode).sorted(byKeyPath: "stationID", ascending: true)
                for j in 0...HanzomonLine.count-1{
                    //print(HanzomonLine[j].stationName)
                }
                ///***以上テスト表示***///
                
            }
        }
    }
}
