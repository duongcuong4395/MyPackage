//
//  WebView.swift
//  MyLibrary
//
//  Created by Macbook on 5/2/25.
//

import SwiftUI
import UIKit
import WebKit

/*
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
*/

@available(iOS 17.0, *)
public struct WebView: UIViewRepresentable {
    @Binding public var webView: WKWebView
    @Binding public var isLoading: Bool
    public var url: URL

    public init(webView: Binding<WKWebView>, isLoading: Binding<Bool>, url: URL) {
        self._webView = webView
        self._isLoading = isLoading
        self.url = url
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(parent: WebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("WebView tải thất bại với lỗi: \(error.localizedDescription)")
        }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.absoluteString.contains("facebook.com") {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> WKWebView {
        //var config = WKWebViewConfiguration()
        //config.preferences.javaScriptEnabled = true
        //config.allowsInlineMediaPlayback = true

        //webView.configuration = config
        webView.navigationDelegate = context.coordinator
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    // Các hàm điều khiển WebView
    public func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    public func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    public func reload() {
        webView.reload()
    }

    public func stopLoading() {
        webView.stopLoading()
    }
}
