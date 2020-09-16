//
//  ViewController.swift
//  hackingWithCovid
//
//  Created by Ben Sullivan on 13/09/2020.
//

import UIKit
import AVKit

/// When you get to the site which lets you select walk-in or drive-in it will likely say `no test sites found`
/// This app makes the request which checks if walk-ins are currently available and will change the background colour
/// or play an mp3 of your choice when there are sites available
///
/// You need to enter your own postcode into the jsonData.json file and perhaps even update the start date to within a few days of today
/// You will need to intercept the call to capture the `x-urlcode`
class ViewController: UIViewController {
    
    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // You can't make many requests per hour, currently this is setup for approximately every 10minutes.
        // Most of the requests will fail due to 'too many requests' unless you change your connection.
        //
        // When a site is found it can be useful to switch to another wifi/cellular before making the call again on the website,
        // This is due to the website saying 'no sites found' when the server returns 'too many requests.
        let timer = Timer.scheduledTimer(withTimeInterval: 700, repeats: true) { (timer ) in
            self.makeRequest()
        }
        timer.fire()
        
        // Uncomment and add your own mp3 to have it play on test sites found
//        setupPlayer()
    }
    
    func makeRequest() {
        let urlComponents = URLComponents(string: "https://ads-prd-gov-1-sp.test-for-coronavirus.service.gov.uk/testcentres/availabilityquery")!
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        
        do {
            guard let fileUrl = Bundle.main.url(forResource: "jsonData", withExtension: "json") else { fatalError() }
            let data = try Data(contentsOf: fileUrl)
            
            request.httpBody = data
            
            // Use Charles or similar to get the x-urlcode
            request.addValue("**YOUR VALUE HERE", forHTTPHeaderField: "x-urlcode")
            
            request.addValue("ads-prd-gov-1-sp.test-for-coronavirus.service.gov.uk", forHTTPHeaderField: "authority")
            request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "accept")
            request.addValue("1", forHTTPHeaderField: "dnt")
            request.addValue("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36",forHTTPHeaderField: "user-agent")
            request.addValue("application/json",forHTTPHeaderField: "content-type")
            request.addValue("https://test-for-coronavirus.service.gov.uk",forHTTPHeaderField: "origin")
            request.addValue("same-site",forHTTPHeaderField: "sec-fetch-site")
            request.addValue("cors",forHTTPHeaderField: "sec-fetch-mode")
            request.addValue("empty",forHTTPHeaderField: "sec-fetch-dest")
            request.addValue("https://test-for-coronavirus.service.gov.uk/",forHTTPHeaderField: "referer")
            request.addValue("en-GB,en-US;q=0.9,en;q=0.8",forHTTPHeaderField: "accept-language")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("error")
                    return
                }
                print(String(data: data, encoding: String.Encoding.utf8))
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        DispatchQueue.main.async {
                            if let testCentres = json["testCentres"] as? [Any], !testCentres.isEmpty {
                                print(testCentres, Date())
                                self.view.backgroundColor = .green
                                if !self.player!.isPlaying {
                                    self.player!.play()
                                }
                            } else {
                                if let message = json["message"] as? String {
                                    print(message, Date())
                                    if message == "Too Many Requests" {
                                        self.view.backgroundColor = .red
                                    }
                                } else {
                                    print("No test centres", Date())
                                    self.view.backgroundColor = .blue
                                }
                            }
                        }
                    }
                } catch let error as NSError {
                    print("Failed to load: \(error.localizedDescription)")
                }
            }
            task.resume()
            
        } catch {
            print(error)
        }
    }
    
    func setupPlayer() {
        let url = Bundle.main.url(forResource: "MyMp3", withExtension: "mp3")!
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            
        } catch let error as NSError {
            print(error.description)
        }
    }
}
