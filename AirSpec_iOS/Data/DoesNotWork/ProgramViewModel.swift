//
//  ProgramViewModel.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 05.02.23.
//
/// for watchConnectivity
import UIKit

final class ProgramViewModel: ObservableObject {
    private(set) var connectivityProvider : ConnectionProvider
    
    init(connectivityProvider: ConnectionProvider) {
        self.connectivityProvider = connectivityProvider
        self.connectivityProvider.connect()
    }

}
