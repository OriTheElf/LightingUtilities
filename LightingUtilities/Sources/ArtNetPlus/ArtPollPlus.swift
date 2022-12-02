//
//  File.swift
//  
//
//  Created by Choi on 2022/12/2.
//

import Foundation
import ArtNet

extension ArtPoll {
    
    public static let standard = ArtPoll(
        behavior: [.diagnostics, .unicastDiagnostics],
        priority: .all
    )
}
