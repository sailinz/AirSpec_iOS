import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import airspec_msg

public class Airspec {
    public static let DefaultEndpoint: URL = URL(string: "https://airspecs.media.mit.edu")!

    public static func decode_packet(_ bytes: Data) throws -> SensorPacket {
        try SensorPacket(serializedData: bytes)
    }

    public static func send_packets(packets: [SensorPacket], auth_token: String, endpoint: URL = Airspec.DefaultEndpoint) async throws {
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
        try await URLSession.shared.upload(
            with: request,
            for: data
        )
    }
}

