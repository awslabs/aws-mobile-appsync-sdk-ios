//
//  AWSAppSyncS3ObjectsExtensions.swift
//  AWSAppSync
//

import Foundation

extension AWSAppSyncClient {
    
    func performS3ObjectUploadForMutation<Operation: GraphQLMutation>(
        operation: Operation,
        s3Object: InternalS3ObjectDetails,
        resultHandler: @escaping (Error?) -> Void) {
        
        s3ObjectManager!.upload(s3Object: s3Object) { _, error in
            resultHandler(error)
        }
    }

}
