//
//  AppDelegate.swift
//  SmaTrain
//
//  Created by KentaroAbe on 2017/11/19.
//  Copyright © 2017年 KentaroAbe. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import SwiftyJSON
import Alamofire

class ExpressData: Object{
    @objc dynamic var lineCode = ""
    @objc dynamic var stationCode = ""
    @objc dynamic var typeName = ""
    @objc dynamic var name = ""
}
class RegisterStationAndDistrict: Object{
    @objc dynamic var priority = 0
    @objc dynamic var StationName = ""
    @objc dynamic var StationCode = ""
    @objc dynamic var LineNameInStation = ""
    @objc dynamic var LineCodeInStation = ""
    @objc dynamic var TrainDirection = ""
}

class LineData:Object{
    @objc dynamic var dataID = 0
    @objc dynamic var OperatorName = "" //運行会社
    @objc dynamic var lineName = "" //路線名
    @objc dynamic var isLtdEXP = false //特急（JR線の特急は遅延時分を表示しない）
    @objc dynamic var lineID = 0 //路線ID
    @objc dynamic var lineCode = "" //路線コード（東京メトロでリクエストを投げる際に使用するためのコード）
    @objc dynamic var lineColor = "" //路線カラー（HTMLカラー)
    @objc dynamic var isUnique = false //JREの首都圏列車位置情報とは違う法則性のURLを使っているか
    @objc dynamic var dataURL = "" //isUniqueがtrueの場合はURLを記録
    @objc dynamic var type = "" //データタイプ（例：JRE/京王->HTML 東急/東京メトロ->JSON）
}

class stationData:Object{
    @objc dynamic var operatorName = "" //運行会社（例：東京メトロ→"TokyoMetro" 東急電鉄→"Tokyu"）
    @objc dynamic var lineCode = "" //該当駅の路線コード（複数路線が乗り入れる駅も路線ごとに独立して登録）
    @objc dynamic var stationID = 0 //路線内でのナンバリング（例：半蔵門線渋谷 -> Z01 -> 1）
    @objc dynamic var stationName = "" //駅名
    @objc dynamic var stationCode = "" //API内で使用されている駅名
    @objc dynamic var bothStation = false //駅間か（東急が駅間も駅として情報を持っているため）（メトロは基本false）
    @objc dynamic var stationColor = ""
}

class timeTableInTrainInStation:Object{
    @objc dynamic var operationgCode = "" //運行番号
    @objc dynamic var lineCode = "" //東京メトロ線のAPIで使用される路線名
    @objc dynamic var trainID = 0 //始発から順に数えた時のID（列車１本に１コード）
    @objc dynamic var trainType = "" //種別
    @objc dynamic var trainDestination = "" //行き先
    @objc dynamic var isTrainThrough = false //直通か
    @objc dynamic var ThroughOperator = "" //直通先
    @objc dynamic var trainDirection = "" //電車の方向
    @objc dynamic var stationCode = "" //駅名
    @objc dynamic var stationID = 0
    @objc dynamic var time = "" //発車時刻
    @objc dynamic var timeInt = 0 //発車時刻4桁（hh:mm）をそのままIntに変換したもの ソート用
    @objc dynamic var week = "" //平日・休日・土曜の種別
}


class AppMetaData:Object{
    @objc dynamic var isFirstLaunch = false
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var LineName = ""
    var StationName = ""
    var isFinishRegister = false


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        /*let userDefault = UserDefaults.standard
        let dict = ["isFirstLaunch":true]
        
        userDefault.register(defaults: dict)
        if userDefault.bool(forKey: "firstLaunch") {
            userDefault.set(false, forKey: "firstLaunch")
            let database = try! Realm()
            let objects = AppMetaData()
            
            objects.isFirstLaunch = true
            
            try! database.write {
                database.add(objects)
            }
        }
        */
        
        let url = URL(string:"https://dc.akbart.net/imadokotrain/stopStations.json")
        var isCompleteDataGetted = true
        Alamofire.request(url!).responseJSON{response in
            let json = JSON(response.result.value!)
            //let json = JsonGet(fileName: "stopStations")
            let db = try! Realm()
            let currentData = db.objects(ExpressData.self)
            try! db.write {
                db.delete(currentData)
            }
            for i in 0...json.count-1{
                var stations = [String]()
                
                //print(json)
                
                for j in 0...json[String(describing:i)].count-2{
                    //print(json[String(describing:i)][String(describing:j)]["stop"].count)
                    for k in 1...json[String(describing:i)][String(describing:j)]["stop"].count{
                        let object = ExpressData()
                        object.lineCode = String(describing:json[String(describing:i)]["lineName"])
                        object.stationCode = String(describing:json[String(describing:i)][String(describing:j)]["stop"][String(describing:k)])
                        object.typeName = String(describing:json[String(describing:i)][String(describing:j)]["name"])
                        //print(String(describing:json[String(describing:i)][String(describing:j)]["name"]))
                        //print(String(describing:json[String(describing:i)][String(describing:j)]["stop"][String(describing:k)]))
                        
                        try! db.write {
                            db.add(object)
                        }
                        
                        isCompleteDataGetted = false
                    }
                }
                
            }
            //print(db.objects(ExpressData.self))
        }
        let runLoop = RunLoop.current
        while isCompleteDataGetted &&
            runLoop.run(mode: RunLoopMode.defaultRunLoopMode, before: NSDate(timeIntervalSinceNow: 0.1) as Date) {
                //print("まだ取得が終わっていません")
        }
        
        return true
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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

