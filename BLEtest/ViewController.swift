//
//  ViewController.swift
//  BLEtest
//
//  Created by 0xq haun on 2021/12/24.
//
//iphone端末のbluetooth使用はNSBluetoothAlwaysUsageDescriptionを設定info.plistにて
//NSBluetoothPeripheralUsageDescriptionも

import UIKit
import CoreBluetooth

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    
    //textfield
    @IBOutlet weak var textField: UITextField!
    //label
    @IBOutlet weak var label: UILabel!
    //Button
    @IBOutlet weak var sendCentral: UIButton!
    @IBOutlet weak var sendPeripheral: UIButton!
    @IBOutlet weak var disconect: UIButton!
    @IBOutlet weak var stopabvertise: UIButton!
    @IBOutlet weak var advertisebutton: UIButton!
    @IBOutlet weak var scanbutton: UIButton!
    //tableview
    @IBOutlet weak var tableview: UITableView!
    
    
    //必要変数の定義
    var centralManager:CBCentralManager!
    var central:CBCentral!
    var peripheral:CBPeripheral!
    var peripheralManager:CBPeripheralManager!
    var characteristic:CBCharacteristic!
    var service: CBMutableService?
    var notifyCharacteristic: CBMutableCharacteristic?
    var messageArray=["メッセージ"]
    
    
    //各種UUIDの定義
    //キャラクタリスティックのID
    let characteristicID = CBUUID(string: "03f15da4-5c4b-e022-8fc5-7d481dc031e4")
    //サービスのID
    let serviceID = CBUUID(string: "0bd933ab-e4ab-ea61-31fa-c1ec75cdf54e")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //各送信ボタンの無効化
        sendPeripheral.isEnabled=false
        sendCentral.isEnabled=false
        sendPeripheral.setTitleColor(.darkGray, for: .normal)
        sendCentral.setTitleColor(.darkGray, for: .normal)
        //各停止ボタンの無効化
        disconect.isEnabled=false
        disconect.setTitleColor(.darkGray, for: .normal)
        stopabvertise.isEnabled=false
        stopabvertise.setTitleColor(.darkGray, for: .normal)
    }
    
    
    //セル数指定メソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    
    //セル値設定メソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //セルの取得
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        //値の設定
        cell.textLabel!.text = messageArray[indexPath.row]
        return cell
    }
    
    
    //【セントラル側】ボタン押下でペリフェラル検出を開始する
    @IBAction func button(_ sender: Any) {
        //セントラルマネージャの起動→DIdUp~の呼び出し
        self.centralManager = CBCentralManager(delegate: self,queue:nil,options:nil)
        //状態をラベルに反映
        label.text="状態：BLE接続待ちです"
    }
    
    
    //【ペリフェラル側】ボタン押下でアドバタイズする
    @IBAction func adButton(_ sender: Any) {
        //ペリフェラルマネージャの起動→DIdUp~の呼び出し
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        //状態をラベルに反映
        label.text="状態：アドバタイズ実行します"
    }
    
    
    //【セントラル側】ボタン押下で送信
    @IBAction func sendButton2(_ sender: Any) {
        //textfielfの入力文字を変数へ格納
        let text = textField.text!
        //NSData型にキャスト
        let data = text.data(using: .utf8)!
        //ペリフェラルにデータをおくる
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        //メッセージ配列に追加
        messageArray.append("自分：\(text)")
        //更新
        tableview.reloadData()
    }
    
    
    //【ペリフェラル側】ボタン押下でテキストを送信する
    @IBAction func sendButton(_ sender: Any) {
        //textfielfの入力文字を変数へ格納
        let text = textField.text!
        //NSData型にキャスト
        let data = text.data(using: .utf8)!
        //セントラルへデータ送信
        peripheralManager.updateValue(data, for: notifyCharacteristic!, onSubscribedCentrals: nil)
        //メッセージ配列に追加
        messageArray.append("自分：\(text)")
        //更新
        tableview.reloadData()
    }
   
    
    //ペリフェラルとの接続解除ボタン
    @IBAction func cancelbutton(_ sender: Any) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
    //アドバタイズ停止ボタン
    @IBAction func stopbutton(_ sender: Any) {
        peripheralManager.stopAdvertising()
        label.text="状態：アドバタイズ停止しました"
        stopabvertise.isEnabled=false
        stopabvertise.setTitleColor(.darkGray, for: .normal)
        scanbutton.isEnabled=true
        scanbutton.setTitleColor(.white, for: .normal)
    }
    
    
    //画面タップでキーボード閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            view.endEditing(true)
        }
}


//拡張機能でCBCentralManagerのデリゲート設置
extension ViewController:CBCentralManagerDelegate{
    
    
    //BLE状態必須メゾット
    func centralManagerDidUpdateState(_ central:CBCentralManager){
        //bluetoothの状態を表す
        switch central.state{
        //オフの時→何もしない
        case CBManagerState.poweredOff:
            print("Bluetoothがオフになっています。")
            label.text="状態：Bluetoothがオフになっています"
        //オンの時→ペリフェラル検出
        case CBManagerState.poweredOn:
            print("Bluetoothがオンになっています。")
            //ペリフェラルの検出【サービスのUUID指定して検出する】
            centralManager.scanForPeripherals(withServices: [serviceID], options: nil)
        default:
            break
        }
    }
    
    
    //ペリフェラルの検出後に呼ばれるメソッド（あくまで検出）クラス〜＝＝UUID指定したペリフェラルを見つけた時の処理
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //検出確認
        print("検出しました")
        //ペリフェラルデバイスへの接続を試みる
        centralManager.connect(peripheral, options: nil)
        //ペリフェラルの保持(=ペリフェラルオブジェクトにデリゲート外でアクセス出来ないため)
        self.peripheral=peripheral
    }
    
    
    //接続後に呼ばれるメソッド（こちらは検出後接続時メソッド）
    func centralManager(_ centralManager: CBCentralManager,didConnect peripheral: CBPeripheral){
        //接続の確認
        print("BLE接続しました")
        label.text="状態：BLE接続中"
        //BLE接続したので、スキャン停止
        self.centralManager.stopScan()
        //デリゲート設定(セントラルマネージャではなく、ペリフェラルオブジェクトの直接操作)
        peripheral.delegate=self
        //BLE通信におけるテキスト送受信のためにキャラクタリスティックをdiscoverしてアクセス
        self.peripheral.discoverServices([serviceID])
    }
    
    
    //接続失敗時のメソッド
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("接続失敗")
        label.text="状態：接続に失敗しました"
    }
    
    
    //ペリフェラルとの接続解除時に呼ばれるメゾット
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        label.text="状態：接続解除しました"
        disconect.isEnabled=false
        disconect.setTitleColor(.darkGray, for: .normal)
        sendCentral.isEnabled=false
        sendCentral.setTitleColor(.darkGray, for: .normal)
        advertisebutton.isEnabled=true
        advertisebutton.setTitleColor(.white, for: .normal)
        sendPeripheral.isSelected=false
        sendPeripheral.setTitleColor(.darkGray, for: .normal)
    }
}


//拡張機能にてペリフェラルのデリゲート設定
extension ViewController: CBPeripheralDelegate{
    
    //サービス検出成功時に呼ばれるメソッド
    //discoverの後の処理
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices実行")
        //エラー時の処理
        if let error = error {
            print("サービスが見つかりません: \(error.localizedDescription)")
            //接続遮断
            self.centralManager.cancelPeripheralConnection(peripheral)
            return
          }
        //サービスが複数ある場合があるため、ループして必要なキャラクタリスティックをdiscoverする
        //続いて、CBPeriferaruDelegateのdidDiscoverCharacterristicForServiceが呼ばれる。
        peripheral.services?.forEach { service in
        peripheral.discoverCharacteristics([characteristicID], for: service)
          }
    }
    
    
    //サービス内のキャラクタリスティックがdiscoverされた場合の処理クラス
    //前述の後のメソッド
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor service実行")
        //エラー処理
        if let error = error {
            print("キャラクタリスティックが見つかりません\(error.localizedDescription)")
            //接続遮断
            self.centralManager.cancelPeripheralConnection(peripheral)
            return
          }
        // キャラクタリスティックが複数ある場合があるためループする
        service.characteristics?.forEach { characteristic in
            guard characteristic.uuid == characteristicID else { return }
           // キャラクタリスティックを購読し、データが来たら通知されるようにする
            peripheral.setNotifyValue(true, for: characteristic)
           // データを送信するために、キャラクタリスティックの参照を保持する
            self.characteristic = characteristic
         }
    }
    
    
    //ペリフェラルから通知が設定されているか確認
    //前述の処理に続く
    func peripheral(_ peripheral: CBPeripheral,
                        didUpdateNotificationStateFor characteristic: CBCharacteristic,
                        error: Error?) {
        //エラー処理
        if let error = error {
            print("キャラクタリスティック更新通知エラー: \(error.localizedDescription)")
            return
          }
        // キャラクタリスティックが指定したものであることを確かめる
         guard characteristic.uuid == characteristicID else { return }
        // 通知の設定が成功しているかチェックする
          if characteristic.isNotifying {
            print("キャラクタリスティックの通知が開始されています")
          } else {
            print("キャラクタリスティックの通知が止まっています。接続をキャンセルします。")
            centralManager.cancelPeripheralConnection(peripheral)
          }
        sendCentral.isEnabled=true
        sendCentral.setTitleColor(.white, for: .normal)
        disconect.isEnabled=true
        disconect.setTitleColor(.white, for: .normal)
        advertisebutton.isEnabled=false
        advertisebutton.setTitleColor(.darkGray, for: .normal)
        sendPeripheral.isEnabled=false
        sendPeripheral.setTitleColor(.darkGray, for: .normal)
    }
}


//拡張機能にてペリフェラルマネージャーデリゲートの追加
extension ViewController:CBPeripheralManagerDelegate{
    //サービス追加時
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?){
        if(error != nil){
            print("Add Service error:", error as Any)
        }else{
            print("Add Service ok")
            // Service と Characteristicを持っておく
            self.service = service as? CBMutableService
            for characteristic in service.characteristics!{
                if characteristic.uuid == characteristicID{
                    notifyCharacteristic = characteristic as? CBMutableCharacteristic
                }
            }
        }
    }
    
    
    //BLEの状態を返す（必須のメソッド）
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager){
        //bluetoothの状態を表す
        switch peripheral.state{
        //オフの時→何もしない
        case CBManagerState.poweredOff:
            print("Bluetoothがオフになっています。")
            label.text="状態：Bluetoothがオフになっています"
        //オンの時→UUIDを指定してアドバタイズ
        case CBManagerState.poweredOn:
            print("Bluetoothがオンになっています。")
            // キャラクタリスティックを作成し、設定する
            let properties: CBCharacteristicProperties = [.notify, .write]
            let permissions: CBAttributePermissions = [.writeable]
            let characteristic = CBMutableCharacteristic(type: characteristicID, properties: properties,
                value: nil, permissions: permissions)
            // サービスを作成し、そこにキャラクタリスティックを追加する
            let service = CBMutableService(type: serviceID, primary: true)
            service.characteristics = [characteristic]
            // このサービスをペリフェラルマネージャに登録する
            peripheralManager.add(service)
            //アドバタイズ
            let advertisementData = [CBAdvertisementDataServiceUUIDsKey: [service.uuid], CBAdvertisementDataLocalNameKey: "Peripheral iphone"] as [String : Any]
                  peripheralManager.startAdvertising(advertisementData)
        default:
            break
        }
    }
    
    
    //アドバタイズ開始した際の処理
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("アドバタイズ成功")
        label.text="状態：アドバタイズ中です"
        sendPeripheral.isEnabled=true
        sendPeripheral.setTitleColor(.white, for: .normal)
        scanbutton.isEnabled=false
        scanbutton.setTitleColor(.darkGray, for: .normal)
        stopabvertise.isEnabled=true
        stopabvertise.setTitleColor(.white, for: .normal)
        }
    
    
    //セントラルからデータを受け取る
    func peripheralManager(_ peripheral: CBPeripheralManager,didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first, let data = request.value else { return }
        let message = String(decoding: data, as: UTF8.self)
        print(message)
        //メッセージ配列に追加
        messageArray.append("相手：\(message)")
        //更新
        tableview.reloadData()
    }
 
    
    //ペリフェラルからデータを受け取る
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // エラー処理
        if let error = error {
            print("キャラクタリスティックの値の更新に失敗しました: \(error.localizedDescription)")
            return
          }
        // キャラクタリスティックから値を取り出す
        guard let data = characteristic.value else { return }
        // デコード/パース処理を行う
        let message = String(decoding: data, as: UTF8.self)
        print(message)
        //メッセージ配列に追加
        messageArray.append("相手：\(message)")
        //更新
        tableview.reloadData()
    }
    
    
    //notify開始のリクエスト受信
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("notify開始リクエストを受信")
    }
}


