//
//  PickerRow.swift
//  bg-picker
//
//  Created by Danniel on 07/05/26.
//
import SwiftUI

struct SettingsPickerRow<T: Hashable & RawRepresentable & CaseIterable>: View
where T.RawValue == String {

    let label: String
    @Binding var selection: T

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Menu {
                Picker(label, selection: $selection) {
                    ForEach(Array(T.allCases), id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selection.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.18))
        )
    }
}
