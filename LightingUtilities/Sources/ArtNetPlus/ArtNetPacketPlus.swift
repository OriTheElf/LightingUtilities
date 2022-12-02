//
//  ArtNetPacketPlus.swift
//  
//
//  Created by Choi on 2022/12/2.
//

import Foundation
import ArtNet

extension ArtNetPacket where Self: Encodable {
    
    public var data: Data {
        do {
            let encoder = ArtNetEncoder()
            return try encoder.encode(self)
        } catch {
            return Data()
        }
    }
}
