//
//  GIFView.swift
//  many-llms
//

import SwiftUI
import WebKit

#if os(iOS)
public struct GIFView: UIViewRepresentable {
    public let urlString: String
    
    public init(urlString: String = "https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExdHdwbnlzZTNiYTVnbGl4eTZlZjFueG90NjhjdWIyN2Z2dzZwNmxxYiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/w5WFZZMK1jZ2rZTHpg/giphy.gif") {
        self.urlString = urlString
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    overflow: hidden;
                }
                img {
                    max-width: 100%;
                    max-height: 100%;
                    object-fit: contain;
                }
            </style>
        </head>
        <body>
            <img src="\(urlString)" alt="ManyLLM Bee Cat Animation">
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#endif
