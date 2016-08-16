#!/usr/bin/env xcrun --sdk macosx swift -target x86_64-macosx10.11

//
//  Copyright © 2016 Bystam. All rights reserved.
//

import Foundation

import CoreImage
import Cocoa


// **** DETECTION ****

let kFaceDetector: CIDetector = {
    let context = CIContext(options: nil)
    let opts = [ CIDetectorAccuracy : CIDetectorAccuracyLow ]
    return CIDetector(ofType: CIDetectorTypeFace, context: context, options: opts)
}()

func findFaceRect(image: CIImage) -> CGRect? {
    let orientation = image.properties[kCGImagePropertyOrientation as String]
    let opts = orientation != nil ? [ CIDetectorImageOrientation : orientation! ] : [:]
    let features = kFaceDetector.featuresInImage(image, options: opts)

    return features.first?.bounds
}


// **** I/O ****

let kTmpFolder = "/tmp/img_crop/"

func openTmpFolder() {
    let fm = NSFileManager.defaultManager()
    if !fm.fileExistsAtPath(kTmpFolder) {
        let _ = try? fm.createDirectoryAtPath(kTmpFolder, withIntermediateDirectories: true, attributes: nil)
    }

    NSWorkspace.sharedWorkspace().openFile(kTmpFolder)
}

var errors = [String : [String]]()

func err(cause: String, atUrl url: String) {
    let existing = errors[cause] ?? []
    errors[cause] = existing + [url]

    print("err: \(cause)  ---  \(url)")
}

func user(inUrl url: String) -> String {
    return url.stringByReplacingOccurrencesOfString("https://zfinger.datasektionen.se/user/", withString: "")
              .stringByReplacingOccurrencesOfString("/image/640", withString: "")
}

func write(image image: CIImage, toFileWithName name: String) {
    let rep = NSBitmapImageRep(CIImage: image)
    guard let data = rep.representationUsingType(.NSJPEGFileType, properties: [:]) else {
        err("JPEG data conversion fail", atUrl: name)
        return
    }

    let path = kTmpFolder + name
    data.writeToFile(path, atomically: true)
}


// *** TOTAL PROGRAM ****

func cropImage(atUrlString s: String) {

    print("starting: \(s)")

    guard let url = NSURL(string: s) else {
        err("Invalid URL", atUrl: s)
        return
    }
    guard let data = NSData(contentsOfURL: url) else {
        err("Image data load fail", atUrl: s)
        return
    }
    guard var image = CIImage(data: data) else {
        err("Image creation fail", atUrl: s)
        return
    }
    guard var rect = findFaceRect(image) else {
        err("Face find fail", atUrl: s)
        return
    }

    rect = rect.insetBy(dx: -60, dy: -60).offsetBy(dx: 0, dy: 10)
    image = image.imageByCroppingToRect(rect)

    let fileName = "\(user(inUrl: s)).jpg"
    write(image: image, toFileWithName: fileName)
}

openTmpFolder()

let queue = NSOperationQueue()
queue.maxConcurrentOperationCount = 4
while let url = readLine() {
    let op = NSBlockOperation(block: {
        cropImage(atUrlString: url)
    })
    queue.addOperation(op)
}

queue.waitUntilAllOperationsAreFinished()

print("\n---- Done! ----")
if !errors.isEmpty {
    print("\n---- Encountered errors of types: ----")
    for (cause, urls) in errors {
        print("-- \(cause) --")
        print(urls.joinWithSeparator("\n"))
    }
}
