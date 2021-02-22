//
//  SignatureView.swift
//  
//
//  Created by Wirjo, Fred on 11/4/20.
//

import SwiftUI

struct Drawing {
    public var points: [CGPoint] = [CGPoint]()
    
    public var maxX: CGFloat {
        return points.max(by: { $0.x < $1.x })!.x
    }
    
    public var maxY: CGFloat {
        return points.max(by: { $0.y < $1.y })!.y
    }
    
    public var minX: CGFloat {
        return points.min(by: { $0.x < $1.x })!.x
    }
    
    public var minY: CGFloat {
        return points.min(by: { $0.y < $1.y })!.y
    }
}

struct footnoteInfo {
    public var footnoteAlignment: NSTextAlignment?
    public var footnoteFont = UIFont.systemFont(ofSize: 17, weight: .regular)
    public var footnoteColor = UIColor.black
    public var footnoteLine1: NSAttributedString?
    public var footnoteLine2: NSAttributedString?
}

struct DrawingPad: View {
    @Binding var currentDrawing: Drawing
    @Binding var drawings: [Drawing]
    @Binding var strokeColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var backgroundColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for drawing in self.drawings {
                    self.add(drawing: drawing, toPath: &path)
                }
                self.add(drawing: self.currentDrawing, toPath: &path)
            }
            .stroke(self.strokeColor, lineWidth: self.lineWidth)
            .background(self.backgroundColor)
                .gesture(
                    DragGesture(minimumDistance: 0.1)
                        .onChanged({ (value) in
                            let currentPoint = value.location
                            if currentPoint.y >= 0
                                && currentPoint.y < geometry.size.height {
                                self.currentDrawing.points.append(currentPoint)
                            }
                        })
                        .onEnded({ (value) in
                            self.drawings.append(self.currentDrawing)
                            self.currentDrawing = Drawing()
                        })
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func add(drawing: Drawing, toPath path: inout Path) {
        let points = drawing.points
        if points.count > 1 {
            for i in 0..<points.count-1 {
                let current = points[i]
                let next = points[i+1]
                path.move(to: current)
                path.addLine(to: next)
            }
        }
    }
    
}

public struct SignatureView: View {
    
    @State private var currentDrawing: Drawing = Drawing()
    @State private var drawings: [Drawing] = [Drawing]()
    @State private var imageStrokeColor: Color = Color.black
    @State private var strokeWidth: CGFloat = 3.0
    @State private var rect1: CGRect = .zero
    @State private var shouldRemoveWhitespace = true
    @State private var backgroundColor = Color.white
    
    public init() {
        
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                HStack {
                    Button(action: {
                        drawings.removeAll()
                    }) {
                        Text("Cancel")
                    }
                    Spacer()
                    Button(action: {
                        if shouldRemoveWhitespace {
                            var maxX = -1 * CGFloat.greatestFiniteMagnitude
                            var maxY = -1 * CGFloat.greatestFiniteMagnitude
                            var minX = CGFloat.greatestFiniteMagnitude
                            var minY = CGFloat.greatestFiniteMagnitude
                            
                            for drawing in drawings {
                                if drawing.maxX > maxX { maxX = drawing.maxX }
                                if drawing.maxY > maxY { maxY = drawing.maxY }
                                if drawing.minX < minX { minX = drawing.minX }
                                if drawing.minY < minY { minY = drawing.minY }
                            }
                            
                            let rectWidth = maxX - minX < 100 ? 100 : maxX - minX
                            let rectHeight = maxY - minY < 100 ? 100 : maxY - minY
                            rect1 = CGRect(x: minX+rect1.minX, y: minY+rect1.minY, width: rectWidth, height: rectHeight)
                        }
                        
                        let imageSaver = ImageSaver()
                        let uimage = UIApplication.shared.windows[0].rootViewController?.view.asImage(rect: self.rect1)
                        imageSaver.writeToPhotoAlbum(image: uimage!)
                        drawings.removeAll()
                    }) {
                        Text("Done")
                    }

                }.padding([.leading, .trailing])
                DrawingPad(currentDrawing: $currentDrawing,
                           drawings: $drawings,
                           strokeColor: $imageStrokeColor,
                           lineWidth: $strokeWidth,
                           backgroundColor: $backgroundColor)
                    .background(RectGetter(rect: $rect1))
                HStack {
                    Text("X")
                        .font(.system(size: 17))
                        .fontWeight(.regular)
                        .kerning(-0.41)
                        .frame(width: 17, height: 22)
                    Rectangle().frame(width: 270, height: 1)
                }.frame(height: 40).padding([.leading, .trailing]).padding(.bottom, 40)
            }
        }
    }
}

struct SignatureView_Previews: PreviewProvider {
    static var previews: some View {
        SignatureView()
    }
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    }
}

extension UIView {
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
struct RectGetter: View {
    @Binding var rect: CGRect

    var body: some View {
        GeometryReader { proxy in
            self.createView(proxy: proxy)
        }
    }

    func createView(proxy: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            self.rect = proxy.frame(in: .global)
        }

        return Rectangle().fill(Color.clear)
    }
}
