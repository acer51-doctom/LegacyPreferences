//
//  UnavailableLabel.swift
//  Legacy Preferences
//
//  Created by dehydratedpotato on 6/6/23.
//

import SwiftUI

struct UnavailableLabel: View {
    var body: some View {
        HStack {
            Spacer()
            Text("This pane is for now only here for completion. Expect an update system soon! :D")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

struct UnavailableLabel_Previews: PreviewProvider {
    static var previews: some View {
        UnavailableLabel()
    }
}
