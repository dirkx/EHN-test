//
//  EHNTests.swift
//  EHNTests
//
//  Created by Dirk-Willem van Gulik on 01/04/2021.
//

import XCTest
@testable import EHN
@testable import SwiftCBOR
@testable import GRPC
@testable import NIO

extension String {
    func fromBase45()->Data {
        let BASE45_CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
        var d = Data()
        var o = Data()
        
        for c in self {
            if let at = BASE45_CHARSET.firstIndex(of: c) {
                let idx  = BASE45_CHARSET.distance(from: BASE45_CHARSET.startIndex, to: at)
                d.append(UInt8(idx))
                }
        }
        for i in stride(from:0, to:d.count, by: 3) {
            var x : UInt32 = UInt32(d[i]) + UInt32(d[i+1])*45
            if (d.count - i >= 3) {
                x += 45 * 45 * UInt32(d[i+2])
                o.append(UInt8(x / 256))
                o.append(UInt8(x % 256))
            } else {
                o.append(UInt8(x % 256))
            }
        }
        return o
    }

}


import Foundation

public class NSTag: NSObject {
    private var tag: Int! = -1
    private var value: NSObject!
    
    public init(tag: Int, _ value: NSObject) {
        super.init()
        
        self.tag = tag
        self.value = value
    }
    
    public func tagValue() -> Int {
        return self.tag
    }
    
    public func objectValue() -> NSObject {
        return self.value
    }
}

class EHNTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCBOR() throws {
        // echo '{"foo":"bar"}' | json2cbor | xxd -i
        let payload:  [UInt8] = [0xa1, 0x63, 0x66, 0x6f, 0x6f, 0x63, 0x62, 0x61, 0x72]
        let json = try! CBOR.decode(payload)!
        dump(json,indent: 4)
        XCTAssertEqual(json["foo"], "bar")
        try testEND()
    }
    
    func testEND() throws {
        // echo '{"foo":"bar"}' | node cose_sign.js
        let b45 = "6BFY70R30FFWTWGSLKC 4.49FLBDAKY-F1MP*D9LPC.3EHPCGEC27BDNP$ZM91CWXT*MLF%VU9LW:BL+MMO3.X1% A$GHO9C6XRHQS:MCGZMEA0C%AHIUAVSP8E75DO1E.ERD0TS2W0DPQQF%96+985$4WV5"
        
        // Remove base45 / base64
        var compressed = ByteBufferAllocator().buffer(data: b45.fromBase45())

        // Decompress it.
        let inflate = Zlib.Inflate(format: Zlib.CompressionFormat.deflate,
                                   limit: .absolute(8 * 1024))
        var decompressed = ByteBufferAllocator().buffer(capacity: 32 * 1024)
        let decompressedBytesWritten = try inflate.inflate(&compressed, into: &decompressed)

        // CBOR decode this (Really COSE wrapper AKA CWT)
        let cbor : [UInt8] = decompressed.getBytes(at: 0, length: decompressedBytesWritten) ?? []
        let cose = try! CBOR.decode(cbor)!
        // let t : CBOR.Tag = cose.
        // //            return CBOR.tagged(CBOR.Tag(rawValue: tag), item)
        dump(cose);

    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

