//
//  OTPInputView.swift
//  Movter
//
//  Created by Nurtore on 21.09.2026.
//

import SwiftUI
//import MovterUI

private enum OTPConstants {
    static let digitSpacing: CGFloat = 8
    static let dotSize: CGFloat = 8
    static let digitMinWidth: CGFloat = 40
    static let digitMinHeight: CGFloat = 56
}

struct OTPInputView: View {
    let otpCode: String
    let isError: Bool
    let onCodeChange: (String) -> Bool
    
    private let digitCount: Int = 6
    @State private var internalCode: String
    @FocusState private var isFocused: Bool
    
    init(otpCode: String, isError: Bool = false, onCodeChange: @escaping (String) -> Bool) {
        self.otpCode = otpCode
        self.isError = isError
        self.onCodeChange = onCodeChange
        self._internalCode = State(initialValue: otpCode)
    }
    
    var body: some View {
        ZStack {
            TextField("", text: $internalCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .frame(width: 0, height: 0)
                .opacity(0)
                .focused($isFocused)
                .onChange(of: internalCode) { newValue in
                    let filtered = newValue.digitsOnly
                    
                    if filtered.count > digitCount {
                        internalCode = String(filtered.prefix(digitCount))
                    } else if filtered != newValue {
                        internalCode = filtered
                    }
                    
                    onCodeChange(internalCode)
                }
            HStack(spacing: OTPConstants.digitSpacing) {
                ForEach(0..<digitCount, id: \.self) { index in
                    OTPDigitView(
                        digit: getDigit(at: index),
                        isCurrentPosition: index == internalCode.count
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .onChange(of: otpCode) { newValue in
            guard newValue != internalCode else { return }
            internalCode = newValue
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
    
    private func getDigit(at index: Int) -> String? {
        guard index < internalCode.count else { return nil }
        return String(internalCode[internalCode.index(internalCode.startIndex, offsetBy: index)])
    }
}


struct OTPDigitView: View {
    let digit: String?
    let isCurrentPosition: Bool
    
    var body: some View {
        ZStack {
            if let digit = digit {
                Text(digit)
                    .font(Typography.codeText)
                    .foregroundColor(Color.codeColor)
            } else {
                Circle()
                    .fill(dotColor)
                    .frame(width: OTPConstants.dotSize, height: OTPConstants.dotSize)
            }
        }
        .frame(minWidth: OTPConstants.digitMinWidth, minHeight: OTPConstants.digitMinHeight)
    }
    private var dotColor: Color {
        isCurrentPosition ? Color.codeColor : Color.textDisabled
    }
}
