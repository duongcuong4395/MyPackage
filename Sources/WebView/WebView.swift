//
//  WebView.swift
//  MyLibrary
//
//  Created by Macbook on 5/2/25.
//

import SwiftUI
import UIKit
import WebKit

@available(iOS 17.0, *)
public struct WebView: UIViewRepresentable {
    @Binding public var webView: WKWebView
    public var url: URL

    public init(webView: Binding<WKWebView>, url: URL) {
        self.url = url
        self._webView = webView
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView đã tải xong.")
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView tải thất bại với lỗi: \(error.localizedDescription)")
        }
    }

    public  func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    public func makeUIView(context: Context) -> WKWebView {
        //let webView = WKWebView()
        
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
