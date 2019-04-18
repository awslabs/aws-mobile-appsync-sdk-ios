//
//  ViewController.swift
//  AWSAppSyncTestApp
//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import UIKit
@testable import AWSAppSync
import AWSS3
@testable import AWSAppSyncTestCommon
import AWSMobileClient

class ViewController: UIViewController {
    
    @IBOutlet weak var resultLabel: UITextView!
    private static let networkOperationTimeout = 180.0
    
    private static let s3TransferUtilityKey = "AWSAppSyncCognitoAuthTestsTransferUtility"
    
    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncCognitoAuthTests.mutationQueue")
    
    private var appSyncClient: AWSAppSyncClient?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        AWSDDLog.sharedInstance.logLevel = .verbose
        // AWSDDTTYLogger.sharedInstance.logFormatter = AWSAppSyncClientLogFormatter()
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance) // TTY = Xcode console
    }
    @IBAction func onInitializeIAMClicked(_ sender: Any) {
        setupIAMAppSyncClient()
    }
    
    func setupUserPoolsBasedClient() {
        let testBundle = Bundle(for: ViewController.self)
        let testConfiguration = AppSyncClientTestConfiguration(with: testBundle)!
        let credentialsProvider = BasicAWSCognitoCredentialsProviderFactory.makeCredentialsProvider(with: testConfiguration)
        
        let serviceConfiguration = AWSServiceConfiguration(
            region: testConfiguration.bucketRegion,
            credentialsProvider: credentialsProvider)!
        
        AWSS3TransferUtility.register(with: serviceConfiguration, forKey: ViewController.s3TransferUtilityKey)
        let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: ViewController.s3TransferUtilityKey)
        let cacheConfiguration = try? AWSAppSyncCacheConfiguration()
        AWSMobileClient.sharedInstance().initialize { (_, _) in
            
        }
        // Initialize the AWS AppSync configuration
        let appSyncConfig = try? AWSAppSyncClientConfiguration(appSyncServiceConfig: AWSAppSyncServiceConfig(),
                                                              userPoolsAuthProvider: {
                                                                class MyCognitoUserPoolsAuthProvider : AWSCognitoUserPoolsAuthProviderAsync {
                                                                    func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
                                                                        AWSMobileClient.sharedInstance().getTokens { (tokens, error) in
                                                                            if error != nil {
                                                                                callback(nil, error)
                                                                            } else {
                                                                                callback(tokens?.idToken?.tokenString, nil)
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                return MyCognitoUserPoolsAuthProvider()}(),
                                                              cacheConfiguration: cacheConfiguration,
                                                              s3ObjectManager: transferUtility)
        
        // Initialize the AWS AppSync client
        appSyncClient = try? AWSAppSyncClient(appSyncConfig: appSyncConfig!)
        appSyncClient?.offlineMutationDelegate = self
        self.resultLabel.text = "MutationQueue should have loaded successfully. Queue size: \(self.appSyncClient!.queuedMutationCount!)."
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func onInitializeUserPools(_ sender: Any) {
        setupUserPoolsBasedClient()
    }

    @IBAction func onSignInClicked(_ sender: Any) {
        AWSMobileClient.sharedInstance().signOut()
        AWSMobileClient.sharedInstance().signIn(username: "validuser", password: "ValidPassword") { (userstate, err) in
            
        }
    }
    
    @IBAction func onSignOutClicked(_ sender: Any) {
        AWSMobileClient.sharedInstance().signOut()
    }
    
    @IBAction func onPerformNormalMutation(_ sender: Any) {
        try? performNormalMutation()
        self.resultLabel.text = "Awaiting Normal Mutation. Queue size: \(appSyncClient!.queuedMutationCount!)"
    }
    
    @IBAction func onPerformS3Mutation(_ sender: Any) {
        try? performS3Mutation()
        self.resultLabel.text = "Awaiting S3 Mutation. Queue size: \(appSyncClient!.queuedMutationCount!)"
    }
    
    func setupIAMAppSyncClient() {
        let testBundle = Bundle(for: ViewController.self)
        let testConfiguration = AppSyncClientTestConfiguration(with: testBundle)!
        appSyncClient = try? makeS3EnabledAppSyncClient(testConfiguration: testConfiguration, testBundle: testBundle)
        appSyncClient?.offlineMutationDelegate = self
        DispatchQueue.main.async {
            self.resultLabel.text = "MutationQueue should have loaded successfully. Queue size: \(self.appSyncClient!.queuedMutationCount!)."
        }
    }
    
    @IBAction func onPerformRandomMutationsClicked(_ sender: Any) {
        try? performNormalMutation()
        try? performS3Mutation()
        try? performS3Mutation()
        try? performS3Mutation()
        try? performNormalMutation()
        try? performS3Mutation()
        try? performS3Mutation()
        try? performNormalMutation()
        try? performNormalMutation()
        try? performS3Mutation()
        self.resultLabel.text = "Awaiting 10 random Mutations. Queue size: \(appSyncClient!.queuedMutationCount!)"
    }
    
    func performNormalMutation() throws {

        guard appSyncClient != nil else  {
            self.resultLabel.text  = "Error: AppSync Client not initialized."
            return
        }
        
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        
        self.appSyncClient?.perform(mutation: addPost, queue: ViewController.mutationQueue) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.resultLabel.text = "Failed IAM normal mutation. Queue size: \(self.appSyncClient!.queuedMutationCount!). \n \(error.localizedDescription)"
                } else {
                    self.resultLabel.text = "Success IAM normal mutation. Queue size: \(self.appSyncClient!.queuedMutationCount!)"
                }
            }
        }
    }
    
    // Uploads a local file as part of a mutation, then downloads it using the data retrieved from the AppSync query
    func performS3Mutation() throws {
        let testBundle = Bundle(for: ViewController.self)
        let testConfiguration = AppSyncClientTestConfiguration(with: testBundle)!
        
        guard appSyncClient != nil else  {
            self.resultLabel.text  = "Error: AppSync Client not initialized."
            return
        }
        
        // Note "public" prefix. See https://aws-amplify.github.io/docs/js/storage#using-amazon-s3
        let objectKey = "public/testS3Object-\(UUID().uuidString).jpg"
        let localURL = testBundle.url(forResource: "testS3Object", withExtension: ".jpg")!
        
        // TODO: Replace the hardcoded line below once AWSCore 2.9.1 is released
        // let region = AWSEndpoint.regionName(from: testConfiguration.bucketRegion)!
        let region = "eu-central-2"
        
        let s3ObjectInput = S3ObjectInput(
            bucket: testConfiguration.bucketName,
            key: objectKey,
            region: region,
            localUri: localURL.path,
            mimeType: "image/jpeg")
        
        let createPostWithFile = CreatePostWithFileUsingParametersMutation(
            author: "Test S3 Object Author",
            title: "Test S3 Object Upload",
            content: "Testing S3 object upload",
            url: "http://www.example.testing.com",
            ups: 0,
            downs: 0,
            file: s3ObjectInput)
        
        appSyncClient?.perform(mutation: createPostWithFile,
                               queue: ViewController.mutationQueue) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.resultLabel.text = "Failed IAM normal mutation. Queue size: \(self.appSyncClient!.queuedMutationCount!). \n \(error.localizedDescription)"
                }
                return
            }
            guard let _ = result?.data?.createPostWithFileUsingParameters?.id else {
                DispatchQueue.main.async {
                    self.resultLabel.text = "Mutation result unexpectedly has nil ID. Queue size: \(self.appSyncClient!.queuedMutationCount!)."
                }
                return
            }
            DispatchQueue.main.async {
                self.resultLabel.text = "S3 mutation done successfully. Queue size: \(self.appSyncClient!.queuedMutationCount!)."
            }
        }
    }
    
    // MARK: - Utilities
    
    func makeS3EnabledAppSyncClient(testConfiguration: AppSyncClientTestConfiguration,
                                    testBundle: Bundle) throws -> AWSAppSyncClient {
        let credentialsProvider = BasicAWSCognitoCredentialsProviderFactory.makeCredentialsProvider(with: testConfiguration)
        
        let serviceConfiguration = AWSServiceConfiguration(
            region: testConfiguration.bucketRegion,
            credentialsProvider: credentialsProvider)!
        
        AWSS3TransferUtility.register(with: serviceConfiguration, forKey: ViewController.s3TransferUtilityKey)
        let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: ViewController.s3TransferUtilityKey)
        let cacheConfiguration = try AWSAppSyncCacheConfiguration()

        let helper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            testConfiguration: testConfiguration,
            cacheConfiguration: cacheConfiguration,
            s3ObjectManager: transferUtility,
            testBundle: testBundle)
        
        let appSyncClient = helper.appSyncClient
        
        return appSyncClient
    }
}

extension ViewController: AWSAppSyncOfflineMutationDelegate {
    func mutationCallback(recordIdentifier: String, operationString: String, snapshot: Snapshot?, error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.resultLabel.text = "PersistentMutation done ERROR. \(error!.localizedDescription) Queue size: \(self.appSyncClient!.queuedMutationCount!).\n\(self.resultLabel.text!)"
            } else {
                self.resultLabel.text = "PersistentMutation done SUCCESS. Queue size: \(self.appSyncClient!.queuedMutationCount!).\n\(self.resultLabel.text!)"
            }
        }
    }
    
}
