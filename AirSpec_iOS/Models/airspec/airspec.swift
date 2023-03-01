//
//  File.swift
//  AirSpec_iOS
//
//  Created by Nathan PERRY on 14.02.23.

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum AirspecError : Error {
    case notHTTP
    case status(Int)
}

public class Airspec {
    public static let DefaultEndpoint: URL = URL(string: "https://api.airspecs.resenv.org")!

    
    public static func decode_packet(_ bytes: Data) throws -> SensorPacket {
        try SensorPacket(serializedData: bytes)
    }

    public static func send_packets(packets: [SensorPacket], auth_token: String, endpoint: URL = Airspec.DefaultEndpoint, _ onComplete: @escaping (_ e: Error?) -> Void) throws {
        let contents = SubmitPackets.with {
            $0.sensorData = packets
//            $0.userID = UserDefaults
//            $0.epoch = NSDate().timeIntervalSince1970
            
        }
        
        let data = try contents.serializedData()

        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData)

        request.httpMethod = "POST"
        request.setValue("application/protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(auth_token)", forHTTPHeaderField: "Authorization")

        /// the byte array can be used to regenerate the data: https://medium.com/theengineeringgecko/protocol-buffers-for-swift-eda7eb114d08
//        let reconstructedData = try SensorPacket.init(serializedData: data) /// does not work because the contents also have the epoch
//        print(reconstructedData)

        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        
        // unfortunately can't test because non-darwin platforms only have uploadTask. hacked it to async
        // with `withCheckedThrowingContinuation` but this also didn't work (possibly because I was in
        // XCTest).
        let task = URLSession.shared.uploadTask(
            with: request,
            from: data
        ) { (_, response, error) in
            if let error = error {
                onComplete(error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                onComplete(AirspecError.notHTTP)
                return
            }

            switch httpResponse.statusCode {
            case 200..<300:
                print("sent ok")
                onComplete(nil)
                break

            default:
                onComplete(AirspecError.status(httpResponse.statusCode))
            }
        }

        task.resume()
    }
}

