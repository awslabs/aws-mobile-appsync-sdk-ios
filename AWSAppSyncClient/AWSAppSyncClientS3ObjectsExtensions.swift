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
        dispatchGroup: DispatchGroup,
        handlerQueue: DispatchQueue,
        resultHandler: OperationResultHandler<Operation>?) {

        guard let s3ObjectManager = s3ObjectManager else {
            assertionFailure("s3ObjectManager not set")
            resultHandler?(nil, nil)
            return
        }

        s3ObjectManager.upload(s3Object: s3Object) { [weak self] success, error in
            if success {
                self?.send(
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
        dispatchGroup: DispatchGroup,
        resultHandler: ((JSONObject?, Error?) -> Void)?) {

        guard let s3ObjectManager = s3ObjectManager else {
            assertionFailure("s3ObjectManager not set")
            resultHandler?(nil, nil)
            return
        }

        s3ObjectManager.upload(s3Object: s3Object) { [weak self] success, error in
            if success {
                self?.httpTransport.send(data: data) { _, _ in }
            } else {
                resultHandler?(nil, error)
            }
        }
    }
}
