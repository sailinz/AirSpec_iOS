import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class Airspec {
    public static let DefaultEndpoint: URL = URL(string: "https://airspecs.media.mit.edu/api")!

    public static func decode_packet(_ bytes: Data) throws -> SensorPacket {
        try SensorPacket(serializedData: bytes)
    }

    public static func send_packets(packets: [SensorPacket], auth_token: String, endpoint: URL = Airspec.DefaultEndpoint) throws {
        let contents = SubmitPackets.with {
            $0.sensorData = packets
            $0.epoch = NSDate().timeIntervalSince1970
        }

        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData)

        request.httpMethod = "POST"
        request.setValue("application/protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(auth_token)", forHTTPHeaderField: "Authorization")

        let data = try contents.serializedData()

        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)

        // unfortunately can't test because non-darwin platforms only have uploadTask. hacked it to async
        // with `withCheckedThrowingContinuation` but this also didn't work (possibly because I was in
        // XCTest).
        let task = URLSession.shared.uploadTask(
            with: request,
            from: data
        ) { (_, response, error) in
            if let error = error {
                print("error sending data: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("error: reqeust was not over http")
                return
            }
            
            switch httpResponse.statusCode {
            case 200..<300:
                print("sent ok")
                break
                
            default:
                print("error: bad http status \(httpResponse.statusCode)")
            }
        }
    }
}

