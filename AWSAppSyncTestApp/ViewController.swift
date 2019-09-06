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
@testable import AWSAppSyncTestCommon

import AWSS3
import AWSMobileClient

class ViewController: UIViewController {
    
    private static let networkOperationTimeout = 180.0
    
    private static let s3TransferUtilityKey = "AWSAppSyncCognitoAuthTestsTransferUtility"
    
    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncCognitoAuthTests.mutations")
    private static let subscriptionQueue = DispatchQueue.global(qos: .background)
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncCognitoAuthTests.concurrency")

    // MARK: - Outlets

    @IBOutlet weak var resultLabel: UITextView!
    @IBOutlet weak var perform10MutationsButton: UIButton!
    @IBOutlet weak var perform50MutationsButton: UIButton!
    @IBOutlet weak var toggleTimerButton: UIButton!
    @IBOutlet weak var makeNormalMutationButton: UIButton!
    @IBOutlet weak var makeS3MutationButton: UIButton!

    // MARK: - Properties

    private var appSyncClient: AWSAppSyncClient? = nil {
        didSet {
            DispatchQueue.main.async {
                let mutationControlsEnabled = self.appSyncClient != nil
                self.perform10MutationsButton.isEnabled = mutationControlsEnabled
                self.perform50MutationsButton.isEnabled = mutationControlsEnabled
                self.toggleTimerButton.isEnabled = mutationControlsEnabled
                self.makeNormalMutationButton.isEnabled = mutationControlsEnabled
                self.makeS3MutationButton.isEnabled = mutationControlsEnabled
            }
        }
    }

    private let maxConcurrentSubscriptionWatchers = 10
    private var totalSubscriptionWatchers = AtomicCounter()
    private var subscriptionWatchers = [IdentifiableSubscriptionWatcher]()

    private var totalMutationsPerformed = AtomicCounter()

    private var timer: Timer? {
        didSet {
            DispatchQueue.main.async {
                let isTimerRunning = self.timer != nil
                let labelText = isTimerRunning ? "Stop Timer" : "Start Timer"
                self.toggleTimerButton.setTitle(labelText, for: .normal)
            }
        }
    }

    private var statusText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        AWSDDLog.sharedInstance.logLevel = .info
        AWSDDTTYLogger.sharedInstance.logFormatter = AWSAppSyncClientLogFormatter()
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)

        resultLabel.scrollsToTop = true
        appSyncClient = nil
    }

    // MARK: - Actions

    @IBAction func onInitializeIAMClicked(_ sender: Any) {
        setupIAMAppSyncClient()
    }
    
    @IBAction func onInitializeUserPools(_ sender: Any) {
        setupUserPoolsBasedClient()
    }

    @IBAction func onSignInClicked(_ sender: Any) {
        cancelSubscription()
        AWSMobileClient.sharedInstance().signOut()
        AWSMobileClient.sharedInstance().signIn(username: "validuser", password: "ValidPassword") { (userState, error) in
            if let error = error {
                self.appendStatus("Error signing in: \(error.localizedDescription)")
                return
            }

            guard let userState = userState else {
                self.appendStatus("userState unexpectedly nil")
                return
            }

            self.appendStatus("Signed in: \(userState)")
        }
    }
    
    @IBAction func onSignOutClicked(_ sender: Any) {
        cancelSubscription()
        AWSMobileClient.sharedInstance().signOut()
    }
    
    @IBAction func onPerformNormalMutation(_ sender: Any) {
        try? performNormalMutation()
        self.appendStatus("Awaiting Normal Mutation. Queue size: \(appSyncClient!.queuedMutationCount!)")
    }
    
    @IBAction func onPerformS3Mutation(_ sender: Any) {
        try? performS3Mutation()
        self.appendStatus("Awaiting S3 Mutation. Queue size: \(appSyncClient!.queuedMutationCount!)")
    }
    
    @IBAction func onPerformRandomMutationsClicked(_ sender: Any) {
        performRandomMutations(count: 10)
        self.appendStatus("Awaiting 10 random Mutations. Queue size: \(appSyncClient!.queuedMutationCount!)")
    }

    @IBAction func onPerform50RandomMutationsClicked(_ sender: Any) {
        performRandomMutations(count: 50)
        self.appendStatus("Awaiting 50 random Mutations. Queue size: \(appSyncClient!.queuedMutationCount!)")
    }

    @IBAction func onToggleTimedMutation(_ sender: Any) {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
            return
        }

        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(performOneRandomMutation),
                                     userInfo: nil,
                                     repeats: true)
    }

    // MARK: - Utilities

    @objc func performOneRandomMutation() {
        performRandomMutations(count: 1)
    }

    func performRandomMutations(count: Int = 1) {
        for _ in 0 ..< count {
            if Bool.random() {
                try? performS3Mutation()
            } else {
                try? performNormalMutation()
            }
        }
    }

    func setupIAMAppSyncClient() {
        let testBundle = Bundle(for: ViewController.self)
        let testConfiguration = AppSyncClientTestConfiguration(with: testBundle)!
        appSyncClient = try? makeS3EnabledAppSyncClient(testConfiguration: testConfiguration, testBundle: testBundle)
        appSyncClient?.offlineMutationDelegate = self
        self.appendStatus("MutationQueue should have loaded successfully. Queue size: \(self.appSyncClient!.queuedMutationCount!)")
        setUpInitialSubscriptions()
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

        AWSMobileClient.sharedInstance().initialize { userState, error in
            if let error = error {
                self.appendStatus("Error initializing: \(error.localizedDescription)")
                return
            }

            guard let userState = userState else {
                self.appendStatus("userState unexpectedly nil initializing")
                return
            }

            self.appendStatus("Initialized: \(userState)")

            // Initialize the AWS AppSync configuration
            let appSyncConfig = try! AWSAppSyncClientConfiguration(appSyncServiceConfig: AWSAppSyncServiceConfig(),
                                                                   userPoolsAuthProvider: MyCognitoUserPoolsAuthProvider(),
                                                                   cacheConfiguration: cacheConfiguration,
                                                                   s3ObjectManager: transferUtility)

            // Initialize the AWS AppSync client
            self.appSyncClient = try! AWSAppSyncClient(appSyncConfig: appSyncConfig)
            self.appSyncClient?.offlineMutationDelegate = self
            self.appendStatus("MutationQueue should have loaded successfully. Queue size: \(self.appSyncClient!.queuedMutationCount!)")
            self.setUpInitialSubscriptions()
        }
    }

    func performNormalMutation() throws {
        guard let appSyncClient = appSyncClient else  {
            self.appendStatus("Error: AppSync Client not initialized")
            return
        }
        
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        addPost.title = "Normal mutation \(totalMutationsPerformed.increment())"
        
        appSyncClient.perform(mutation: addPost, queue: ViewController.mutationQueue) { result, error in

            if let error = error {
                self.appendStatus("Failed IAM normal mutation. Queue size: \(appSyncClient.queuedMutationCount!). \(error.localizedDescription)")
                return
            }

            guard result != nil else {
                self.appendStatus("Result unexpectedly nil performing IAM normal mutation")
                return
            }

            self.appendStatus("Success IAM normal mutation. Queue size: \(appSyncClient.queuedMutationCount!)")
        }
        randomlyMutateWatchers()
    }
    
    // Uploads a local file as part of a mutation, then downloads it using the data retrieved from the AppSync query
    func performS3Mutation() throws {
        let testBundle = Bundle(for: ViewController.self)
        let testConfiguration = AppSyncClientTestConfiguration(with: testBundle)!
        
        guard let appSyncClient = appSyncClient else  {
            self.appendStatus("Error: AppSync Client not initialized")
            return
        }
        
        // Note "public" prefix. See https://aws-amplify.github.io/docs/js/storage#using-amazon-s3
        let objectKey = "public/testS3Object-\(UUID().uuidString).jpg"
        let localURL = testBundle.url(forResource: "testS3Object", withExtension: ".jpg")!
        
        let region = AWSEndpoint.regionName(from: testConfiguration.bucketRegion)!
        
        let s3ObjectInput = S3ObjectInput(
            bucket: testConfiguration.bucketName,
            key: objectKey,
            region: region,
            localUri: localURL.path,
            mimeType: "image/jpeg")
        
        let createPostWithFile = CreatePostWithFileUsingParametersMutation(
            author: "Test S3 Object Author",
            title: "Test S3 Object Upload \(totalMutationsPerformed.increment())",
            content: "Testing S3 object upload",
            url: "http://www.example.testing.com",
            ups: 0,
            downs: 0,
            file: s3ObjectInput)
        
        appSyncClient.perform(mutation: createPostWithFile,
                               queue: ViewController.mutationQueue) { result, error in
            if let error = error {
                self.appendStatus("Failed IAM normal mutation. Queue size: \(appSyncClient.queuedMutationCount!). \n \(error.localizedDescription)")
                return
            }
            guard let _ = result?.data?.createPostWithFileUsingParameters?.id else {
                self.appendStatus("Mutation result unexpectedly has nil ID. Queue size: \(appSyncClient.queuedMutationCount!)")
                return
            }
            self.appendStatus("S3 mutation done successfully. Queue size: \(appSyncClient.queuedMutationCount!)")
        }
        randomlyMutateWatchers()
    }
    
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

    func removeRandomSubscriptionWatcher() {
        concurrencyQueue.async {
            let indexToRemove = Int.random(in: 0 ..< self.subscriptionWatchers.count)
            let id = self.subscriptionWatchers[indexToRemove].watcherID
            self.subscriptionWatchers.remove(at: indexToRemove)
            self.appendStatus("Removed subscriptionWatcher \(id)")
        }
    }

    func subscribeIfCapacity() {
        concurrencyQueue.async {
            guard self.subscriptionWatchers.count < self.maxConcurrentSubscriptionWatchers else {
                return
            }

            guard let appSyncClient = self.appSyncClient else {
                self.appendStatus("Can't subscribe; appSyncClient not initialized")
                return
            }

            let statusChangeHandler: SubscriptionStatusChangeHandler = { status in
                self.appendStatus("Subscription status: \(status)")
            }

            let subscription = OnDeltaPostSubscription()

            let watcherID = self.totalSubscriptionWatchers.increment()
            let resultHandler = self.makeSubscriptionResultHandler(watcherID: watcherID)

            do {
                if let subscriptionWatcher = try appSyncClient.subscribe(
                    subscription: subscription,
                    queue: ViewController.subscriptionQueue,
                    statusChangeHandler: statusChangeHandler,
                    resultHandler: resultHandler) {

                    let watcher = IdentifiableSubscriptionWatcher(watcherID: watcherID,
                                                                  subscriptionWatcher: subscriptionWatcher)
                    self.subscriptionWatchers.append(watcher)
                } else {
                    self.appendStatus("Subscription watcher unexpectedly nil, but no error thrown from `subscribe`")
                }

            } catch {
                self.appendStatus("Error initiating subscription: \(error)")
            }
        }
    }

    func randomlyMutateWatchers() {
        if Int.random(in: 0 ..< 100) < 5 {
            if Bool.random() {
                subscribeIfCapacity()
            } else {
                removeRandomSubscriptionWatcher()
            }
        }
    }

    func setUpInitialSubscriptions() {
        for _ in 0 ..< maxConcurrentSubscriptionWatchers {
            subscribeIfCapacity()
        }
        appendStatus("\(maxConcurrentSubscriptionWatchers) subscription watchers added")
    }

    func makeSubscriptionResultHandler(watcherID: Int) -> SubscriptionResultHandler<OnDeltaPostSubscription> {
        let handler: SubscriptionResultHandler<OnDeltaPostSubscription> = {
            [weak self]
            result, transaction, error in

            guard let self = self else {
                return
            }

            if let error = error {
                self.appendStatus("Subscription error: \(error.localizedDescription)")
                return
            }

            guard let result = result else {
                self.appendStatus("Subscription error: result unexpectedly nil")
                return
            }

            guard let postTitle = result.data?.onDeltaPost?.title else {
                self.appendStatus("Subscription error: postTitle unexpectedly nil")
                return
            }

            self.appendStatus("Watcher \(watcherID) received subscription for \(postTitle)")
        }

        return handler
    }

    func cancelSubscription() {
        concurrencyQueue.sync {
            subscriptionWatchers.forEach { $0.subscriptionWatcher.cancel() }
            subscriptionWatchers = []
        }
    }

    func appendStatus(_ msg: String) {
        concurrencyQueue.async {
            let currentValue = self.statusText
            let newValue = "\(msg)\n\(currentValue)"
            self.statusText = newValue

            DispatchQueue.main.async {
                self.resultLabel.text = newValue
                self.resultLabel.setContentOffset(CGPoint.zero, animated: false)
            }
        }
    }

}

extension ViewController: AWSAppSyncOfflineMutationDelegate {
    func mutationCallback(recordIdentifier: String, operationString: String, snapshot: Snapshot?, error: Error?) {
        if let error = error {
            self.appendStatus("PersistentMutation done ERROR. \(error.localizedDescription) Queue size: \(self.appSyncClient!.queuedMutationCount!)")
            return
        }

        self.appendStatus("PersistentMutation done SUCCESS. Queue size: \(self.appSyncClient!.queuedMutationCount!)")
    }
    
}

class MyCognitoUserPoolsAuthProvider : AWSCognitoUserPoolsAuthProviderAsync {
    func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
        AWSMobileClient.sharedInstance().getTokens { (tokens, error) in
            if let error = error {
                callback(nil, error)
                return
            }
            guard let tokenString = tokens?.idToken?.tokenString else {
                callback(nil, NSError(domain: "AWSAppSyncTestApp",
                                      code: 1,
                                      userInfo: [NSLocalizedFailureReasonErrorKey: "token string was nil"]))
                return
            }

            callback(tokenString, nil)
        }
    }
}

struct IdentifiableSubscriptionWatcher {
    let watcherID: Int
    let subscriptionWatcher: AWSAppSyncSubscriptionWatcher<OnDeltaPostSubscription>
}

class AtomicCounter {
    private var lock = DispatchSemaphore(value: 1)
    private var value = 0

    func current() -> Int {
        lock.wait()
        defer {
            lock.signal()
        }
        return value
    }

    func increment() -> Int {
        lock.wait()
        defer {
            lock.signal()
        }
        value += 1
        return value
    }
}
