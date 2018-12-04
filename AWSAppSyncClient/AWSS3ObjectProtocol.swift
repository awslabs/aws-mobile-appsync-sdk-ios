//
//  AWSS3ObjectProtocol.swift
//  AWSAppSync
//

import Foundation

public protocol AWSS3InputObjectProtocol {
    func getLocalSourceFileURL() -> URL?
    func getMimeType() -> String
}

public protocol AWSS3ObjectProtocol {
    func getBucketName() -> String
    func getKeyName() -> String
    func getRegion() -> String
}

public protocol AWSS3ObjectPresignedURLGenerator {
    func getPresignedURL(s3Object: AWSS3ObjectProtocol) -> URL?
}

public protocol AWSS3ObjectManager {
    func upload(s3Object: AWSS3ObjectProtocol & AWSS3InputObjectProtocol, completion: @escaping ((_ success: Bool, _ error: Error?) -> Void))
    func download(s3Object: AWSS3ObjectProtocol, toURL: URL, completion: @escaping ((_ success: Bool, _ eror: Error?) -> Void))
}
