//
//  SecretVariableShow.swift
//  bg-picker
//
//  Created by Danniel on 03/09/26.
//

import SwiftUI

struct SecretVariableShow: View {
    var body: some View {
        VStack {
            Text(SecretVariables.apiKey)
        }
    }
}

#Preview {
    SecretVariableShow()
}
