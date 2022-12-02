//
//  File.swift
//  
//
//  Created by Choi on 2022/12/2.
//

import Foundation
import ArtNet

extension Data {
    
    public var artPollReply: ArtPollReply? {
        do {
            let decoder = ArtNetDecoder()
            return try decoder.decode(ArtPollReply.self, from: self)
        } catch {
            return nil
        }
    }
}
