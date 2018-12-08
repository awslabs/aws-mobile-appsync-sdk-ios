//
//  AWSAppSyncS3ObjectsExtensions.swift
//  AWSAppSync
//

import Foundation

extension AWSAppSyncClient {
    
    func performMutationWithS3Object<Operation: GraphQLMutation>(
        operation: Operation,
        s3Object: InternalS3ObjectDetails,
        conflictResolutionBlock: MutationConflictHandler<Operation>?,
        dispatchGroup: DispatchGroup?,
        handlerQueue: DispatchQueue,
        resultHandler: OperationResultHandler<Operation>?) {

        s3ObjectManager!.upload(s3Object: s3Object) { success, error in
            if success {
                _ = self.send(
                    operation: operation,
                    context: nil,
                    conflictResolutionBlock: conflictResolutionBlock,
                    dispatchGroup: dispatchGroup,
                    handlerQueue: handlerQueue,
                    resultHandler: resultHandler)
            } else {
                resultHandler?(nil, error)
            }
        }
    }

    func performMutationWithS3Object(
        data: Data,
        s3Object: InternalS3ObjectDetails,
        dispatchGroup: DispatchGroup?,
        resultHandler: ((JSONObject?, Error?) -> Void)?) {

        s3ObjectManager!.upload(s3Object: s3Object) { success, error in
            if success {
                self.httpTransport?.send(data: data) { result, error in
                    resultHandler?(result, error)
                }
            } else {
                resultHandler?(nil, error)
            }
        }
    }
}
