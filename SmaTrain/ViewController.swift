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

class TrainTableViewController: UIViewController,UIScrollViewDelegate {
    
    let TokyoMetroAccessToken = "12e6c4c1e608511e3dcf26f416d861e261d8efa412992708210f46ba1005161f"
    let tokyuURL = "https://tokyu-tid.s3.amazonaws.com/dento.json"
    
    @IBOutlet var MainView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let json = JsonGet(fileName: "line")
        
        let lineDic = json.dictionaryObject
        
        let lineKeys:Array = Array(lineDic!.keys)
        
        print(lineKeys)
        
        for i in 0...lineKeys.count-1{
            print("\(lineKeys[i])の路線コードは\(String(describing:json[lineKeys[i]]))です")
        }
        
        stationInit()
        
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
                
                try! database.write {
                    database.deleteAll()
                }
                let jsonDict = JSON(response.result.value!)
                for i in 0...jsonDict.count-1{
                    print("\(String(describing:jsonDict[i]["odpt:railway"]))線-\(String(describing:jsonDict[i]["dc:title"]))駅")
                    let object = stationData()
                    object.lineCode = String(describing:jsonDict[i]["odpt:railway"])
                    object.stationName = String(describing:jsonDict[i]["dc:title"])
                    object.operatorName = "TokyoMetro"
                    var stationIDRaw = String(describing:jsonDict[i]["odpt:stationCode"])
                    stationIDRaw.remove(at: stationIDRaw.startIndex) //路線IDから路線記号を除く（例：半蔵門線渋谷-> Z01 -> 01）
                    object.stationCode = String(describing:jsonDict[i]["owl:sameAs"])
                    object.stationID = Int(stationIDRaw)!
                    
                    let database = try! Realm()
                    
                    try! database.write {
                        database.add(object)
                    }
                }
                //print(database.objects(stationData.self))
                
                let HanzomonLineCode = "odpt.Railway:TokyoMetro.Ginza"
                
                let HanzomonLine = database.objects(stationData.self).filter("lineCode == %@",HanzomonLineCode).sorted(byKeyPath: "stationID", ascending: true)
                for j in 0...HanzomonLine.count-1{
                    print(HanzomonLine[j].stationName)
                }
            }
            
            
            
        }
    }


    func JsonGet(fileName :String) -> JSON {
        let path = Bundle.main.path(forResource: fileName, ofType: "json")
        print(path)
        
        do{
            let jsonStr = try String(contentsOfFile: path!)
            print(jsonStr)
            
            let json = JSON.parse(jsonStr)
            
            return json
        } catch {
            return nil
        }
        
    }
}

class FirstConfigurationController: UIViewController{
    let TokyoMetroAccessToken = "12e6c4c1e608511e3dcf26f416d861e261d8efa412992708210f46ba1005161f"
    override func viewDidLoad() {
        super.viewDidLoad()
        let json = JsonGet(fileName: "line")
        
        print(json[0].dictionaryValue)
        stationInit()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func stationInit(){
        let url = URL(string:"https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Station&acl:consumerKey=\(self.TokyoMetroAccessToken)")
        
        Alamofire.request(url!).responseJSON{response in
            if response.result.value != nil{
                let jsonDict = JSON(response.result.value!)
                for i in 0...jsonDict.count-1{
                    print("\(String(describing:jsonDict[i]["odpt:railway"]))線-\(String(describing:jsonDict[i]["dc:title"]))駅")
                }
            }
        }
    }
    
    func JsonGet(fileName :String) -> JSON {
        let path = Bundle.main.path(forResource: fileName, ofType: "json")
        print(path)
        
        do{
            let jsonStr = try String(contentsOfFile: path!)
            print(jsonStr)
            
            let json = JSON.parse(jsonStr)
            
            return json
        } catch {
            return nil
        }
        
    }
}
