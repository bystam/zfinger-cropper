//
//  Copyright © 2016 Bystam. All rights reserved.
//

import Foundation

import CoreImage
import Cocoa


// **** DETECTION ****

let kFaceDetector: CIDetector = {
    let context = CIContext(options: nil)
    let opts = [ CIDetectorAccuracy : CIDetectorAccuracyHigh ]
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

func user(inUrl url: String) -> String {
    return url.stringByReplacingOccurrencesOfString("https://zfinger.datasektionen.se/user/", withString: "")
              .stringByReplacingOccurrencesOfString("/image/640", withString: "")
}

func write(image image: CIImage, toFileWithName name: String) {
    let rep = NSBitmapImageRep(CIImage: image)
    let data = rep.representationUsingType(.NSJPEGFileType, properties: [:])
    let path = kTmpFolder + name
    data?.writeToFile(path, atomically: true)
}


// *** TOTAL PROGRAM ****

func cropImages(atUrls urlStrings: [String]) {

    for s in urlStrings {
        guard let url = NSURL(string: s) else { continue }
        guard var image = CIImage(contentsOfURL: url) else { continue }
        guard var rect = findFaceRect(image) else { continue }

        rect = rect.insetBy(dx: -60, dy: -60).offsetBy(dx: 0, dy: 10)
        image = image.imageByCroppingToRect(rect)

        let fileName = "\(user(inUrl: s)).jpg"
        write(image: image, toFileWithName: fileName)
    }
}

var urls = [String]()
while let url = readLine() {
    urls.append(url)
}

openTmpFolder()
cropImages(atUrls: urls)