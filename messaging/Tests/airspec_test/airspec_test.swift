import XCTest

import airspec
import airspec_msg

fileprivate func gen_data(_ n: UInt) -> [SensorPacket] {
    (0..<n).map { _ in
        SensorPacket.with {
            $0.header = SensorPacketHeader.with {
                $0.packetType = .lux
                $0.systemUid = UInt32.random(in: 0..<UInt32.max)
                $0.packetID = UInt32.random(in: 0..<UInt32.max)
                $0.msFromStart = UInt32.random(in: 0..<UInt32.max)
                $0.epoch = UInt32.random(in: 0..<UInt32.max)
                $0.payloadLength = UInt32.random(in: 0..<UInt32.max)
            }

            $0.luxPacket = LuxPacket.with {
                $0.gain = .tsl2722Gain1X
                $0.integrationTime = .tsl2722Integrationtime600Ms
                $0.payload = [
                    LuxPacket.Payload.with {
                        $0.lux = UInt32.random(in: 0..<UInt32.max)
                        $0.timestamp = UInt32.random(in: 0..<UInt32.max)
                    }
                ]
            }
        }
    }
}

class TestAll : XCTestCase {
    func test_serde() throws {
        let test_data = gen_data(1)[0]
        let result = try Airspec.decode_packet(try test_data.serializedData())
        XCTAssertEqual(test_data, result)
    }

    func test_server() async throws {
        let test_data = gen_data(1024)

        try await Airspec.send_packets(packets: test_data, auth_token: "", endpoint: URL(string: "http://localhost:8181")!)
    }
}
