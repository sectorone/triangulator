//
//  Pattern.swift
//  Trianglify
//
//  Created by Łukasz Adamczak on 19.06.2015.
//  Copyright (c) 2015 Łukasz Adamczak. All rights reserved.
//

import Cocoa

class Pattern: NSObject {
    var width: CGFloat
    var height: CGFloat
    var cellSize: CGFloat
    var variance: CGFloat
    dynamic var palette: Palette
    
    class func keyPathsForValuesAffectingImage() -> [String] {
        return ["width", "height", "cellSize", "variance", "palette"]
    }
    
    init(width: CGFloat, height: CGFloat, cellSize: CGFloat, variance: CGFloat, palette: Palette) {
        self.width = width
        self.height = height
        self.cellSize = cellSize
        self.variance = variance
        self.palette = palette
    }
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    var rect: CGRect {
        return NSRect(origin: CGPointZero, size: size)
    }

    var image: NSImage {
        return NSImage(size: size, flipped: false) { imageRect in
            self.draw()
            return true
        }
    }
    
    // TODO: Not sure if this should be the responsibility of Pattern.
    //       Perhaps some PNGRenderer would be prudent.
    var dataForPNG: NSData? {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
            pixelsWide: Int(width),
            pixelsHigh: Int(height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: 0,
            bitsPerPixel: 0)!
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrentContext(NSGraphicsContext(bitmapImageRep: rep))
        
        draw()
        
        NSGraphicsContext.restoreGraphicsState()
        
        return rep.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])
    }
    
    func generateGrid() -> [NSPoint] {
        var vertices: [NSPoint] = []
        
        // "Odchyla" współrzędną o maksymalnie variance * cellSize
        // w lewo lub prawo
        let variationRange = 2 * variance * cellSize
        func variation(coordinate: CGFloat) -> CGFloat {
            let rand = arc4random_uniform(UInt32(variationRange))
            let offset = CGFloat(rand) - variationRange / 2
            return coordinate + offset
        }
        
        let margin = cellSize * variance
        for x in stride(from: -margin, to: size.width + cellSize + margin, by: cellSize) {
            for y in stride(from: -margin, to: size.height + cellSize + margin, by: cellSize) {
                vertices.append(NSPoint(
                    x: variation(x),
                    y: variation(y)
                ))
            }
        }
        
        return vertices;
    }
    
    func draw() {
        let rect = NSRect(origin: CGPointZero, size: size)
        
        let vertices = generateGrid()
        let triangles = triangulate(vertices)
        
        NSColor.lightGrayColor().set()
        NSRectFill(rect)
        
        for (i, j, k) in triangles {
            let triangleCenter = center(vertices[i], vertices[j], vertices[k])
            let gradientPoint = scalePoint(triangleCenter, toRect: rect)
            palette.gradient(gradientPoint).set()
            
            let path = NSBezierPath()
            path.moveToPoint(vertices[i])
            path.lineToPoint(vertices[j])
            path.lineToPoint(vertices[k])
            path.closePath()
            path.fill()
            path.stroke()
        }
    }
}
