//
//  AWSAppSyncS3ObjectsExtensions.swift
//  AWSAppSync
//

import Foundation

extension AWSAppSyncClient {
    
    func performMutationWithS3Object<Operation: GraphQLMutation>(operation: Operation, s3Object: InternalS3ObjectDetails, conflictResolutionBlock: MutationConflictHandler<Operation>?, dispatchGroup: DispatchGroup, handlerQueue: DispatchQueue, resultHandler: OperationResultHandler<Operation>?) {
        
        self.s3ObjectManager!.upload(s3Object: s3Object) { (isSuccessful, error) in
            if isSuccessful {
                _ = self.send(operation: operation, context: nil, conflictResolutionBlock: conflictResolutionBlock, dispatchGroup: dispatchGroup, handlerQueue: handlerQueue, resultHandler: resultHandler)
            } else {
                if let resultHandler = resultHandler {
                    resultHandler(nil, error)
                }
            }
        }
    }
    
    func performMutationWithS3Object(data: Data, s3Object: InternalS3ObjectDetails, dispatchGroup: DispatchGroup, resultHandler: ((JSONObject?, Error?) -> Void)?) {

        self.s3ObjectManager!.upload(s3Object: s3Object) { (isSuccessful, error) in
            if isSuccessful {
                self.httpTransport?.send(data: data) { (result, error) in
                }
            } else {
                if let resultHandler = resultHandler {
                    resultHandler(nil, error)
                }
            }
        }
    }
}
