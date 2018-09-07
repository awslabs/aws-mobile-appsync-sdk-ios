# AWS AppSync - Building an iOS Client App
{:.no_toc}

AWS AppSync integrates with the [Apollo GraphQL
client](https://github.com/apollographql/apollo-client) when building
client applications. AWS provides plugins for offline support,
authorization, and subscription handshaking to make this process easier.
You can choose to use the Apollo client directly, or with some client
helpers provided in the AWS AppSync SDK when you get started.

## Table of contents
{:.no_toc}

* Table of contents
{:toc}

## Create an API

Before getting started, you will need an API. See
[designing a GraphQL API section](https://docs.aws.amazon.com/appsync/latest/devguide/designing-a-graphql-api.html#aws-appsync-designing-a-graphql-api) for details.

For this tutorial use the following schema with the [create resources flow](https://docs.aws.amazon.com/appsync/latest/devguide/provision-from-schema.html#aws-appsync-provision-from-schema):

```graphql
type Post {
      id: ID!
      author: String!
      title: String
      content: String
      url: String
      ups: Int
      downs: Int
      version: Int!
}

type Query {
      singlePost(id: ID!): Post
}

schema {
      query: Query
}
```

**Note:** After creating your API, use this schema in the console, then select create resources, select **Post** as your type and then press **Create** at the bottom.

If you want to do more customization of GraphQL resolvers, see the [Resolver Mapping Template Reference.](https://docs.aws.amazon.com/appsync/latest/devguide/resolver-mapping-template-reference.html#aws-appsync-resolver-mapping-template-reference)

## Download a Client Application

To show usage of AWS AppSync, we first review an iOS application with
just a local array of data, and then we add AWS AppSync capabilities
to it. Go to the following URL to [download a sample
application](https://s3-us-west-2.amazonaws.com/awsappsync/appsync-ios-posts-starter.zip), where we can add, update, and delete posts.

### Understanding the iOS Sample App

The iOS sample app has three major files:

1.  `PostListViewController` The PostListViewController shows the list of posts available in the app. It uses a simple TableView to list all the posts. You can `Add`, `Update`, or `Delete` posts from this ViewController.
2.  `AddPostViewController` The AddPostViewController adds a new post into the list of existing posts. It gives a call to the delegate in PostListViewController to update the list of posts.
3.  `UpdatePostViewController` The UpdatePostViewController updates an existing post from the list of posts. It gives a call to the delegate in PostListViewController to update the values of existing posts.

### Running the iOS Sample App

1.  Open the `PostsApp.xcodeproj` file from the download bundle, which you downloaded in the previous step.
2.  Build the project (`COMMAND+B`) and ensure that it completes without error.
3.  Run the project (`COMMAND+R`) and try the `Add`, `Update`, and `Delete` (swipe left) operations on the post list.

## Code Generation for API

The AppSync iOS client generates a strongly typed API for your backend based on the GraphQL schema defined. This helps you create native swift request and response data objects making it very easy to understand the input and output requirements. For e.g. if your GraphQL schema defines a variable as optional, the generated API has that variable as `Swift` `optional` so that the client can expect the value to be `nil` at certain times.

### Set up the Code Generation for GraphQLOperations

To interact with AWS AppSync, your client needs to define GraphQL
queries, mutations and subscriptions which are converted to strongly typed `Swift` objects.

This can be done by creating a `posts.graphql` file in a folder with name like `GraphQLOperations.` Put the following operations in `posts.graphql`:

```graphql
query GetPost($id:ID!) {
 getPost(id:$id) {
     id
     title
     author
     content
     url
     version
 }
}

query AllPosts {
   listPosts {
    items {
       id
       title
       author
       content
       url
       version
       ups
       downs
      }
   }
}

mutation AddPost($input: CreatePostInput!) {
  createPost(input: $input) {
    id
    title
    author
    url
    content
  }
}

mutation UpdatePost($input: UpdatePostInput!) {
  updatePost(input: $input) {
      id
      author
      title
      content
      url
      version
  }
}

mutation DeletePost($input: DeletePostInput!) {
  deletePost(input: $input){
      id
      title
      author
      url
      content
  }
}

subscription OnCreatePost {
  onCreatePost {
    id
    author
    title
    content
    url
  }
}

```

### Generate Swfit API code for your API

Run the following command to install `aws-appsync-codegen`, the tool which takes in your GraphQL schema in the form of `schema.json` and the queries, mutations and subscriptions you just defined above.

> Note: You will need the schema.json file which is the `GraphQL` schema for your backend API; which you can get it from the AppSync console. Put this file in the `GraphQLOperations` folder along with `posts.graphql` file.

```sh
npm install -g aws-appsync-codegen
```

From the root folder of your app, use the terminal to invoke the code generator to generate a strongly typed API for constructing queries, mutations and subscription objects:

```sh
aws-appsync-codegen generate GraphQLOperations/posts.graphql --schema GraphQLOperations/schema.json --output API.swift
```

Add the generated `API.swift` file into your Xcode project. You can make this API generation process a part of your Xcode build process.

## Set up Dependency on the AWS AppSync SDK


1. Open a terminal and navigate to the location of the project that you downloaded, and then run the following:

  ```sh
      pod init
  ```

  This should create a `Podfile` in the root directory of the project. We will use this `Podfile` to declare dependency on the AWS AppSync SDK and other required components.

  > Note: You can skip the above step if you are integrating with an existing project and already have a `Podfile` for your project.

2. Open the `Podfile` and add the following lines in the application target:

  ```sh
      target 'PostsApp' do
        use_frameworks!
        pod 'AWSAppSync', '~>2.6.19'
      end
  ```

3. From the terminal, run the following command:

  ```sh
      pod install --repo-update
  ```

4. This should create a file named `PostsApp.xcworkspace`. DO NOT open the `*.xcodeproj` going forward. You can close the `PostsApp.xcodeproj` if it is open.

5. Open the `PostsApp.xcworkspace` with Xcode. Build the project
(`COMMAND+B`) and ensure that it completes without error.

## Update backend configuration

The Posts app uses `AWS_IAM` as the authorization mechanism with `Cognito credentials` acting as the provider. Currently the client supports the following authentication techniques:

* AWS IAM using Cognito credentials, static AWS credentials or STS (AWS_IAM)
* Amazon Cognito User Pools (AMAZON\_COGNITO\_USER\_POOLS)
* API Key (API_KEY)
* OpenID Connect (OPENID_CONNECT)

Please see the Authorization section for details on how to leverage different authorization techniques:

In the app, edit the `Constants.swift` file, and update the GraphQL
endpoint and your authentication mechanism.

```swift
  let CognitoIdentityPoolId = "COGNITO_POOL_ID"
  let CognitoIdentityRegion: AWSRegionType = .REGION
  let AppSyncRegion: AWSRegionType = .REGION
  let AppSyncEndpointURL: URL = URL(string: "https://APPSYNCURL/graphql")!
  let database_name = "appsync-local-db"
```

## Create a client

The following example demonstartes how to create an AWSAppSyncClient with API_KEY as the authentication mode.

```swift
// Set up API Key Provider
class MyApiKeyAuthProvider: AWSAPIKeyAuthProvider {
    func getAPIKey() -> String {
        return "ApiKey"
    }
}

// You can choose your database location, accessible by the SDK
let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)

do {
    // Initialize the AWS AppSync configuration
    let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                          serviceRegion: AppSyncRegion,
                                                          apiKeyAuthProvider: MyApiKeyAuthProvider(),
                                                          databaseURL:databaseURL)

    // Initialize the AWS AppSync client
    appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
} catch {
    print("Error initializing appsync client. \(error)")
}
```

## Authentication Modes

When making calls to AWS AppSync, there are several ways to authenticate those calls. The API key authorization (**API_KEY**) is the simplest way to onboard, but we recommend you use either Amazon IAM (**AWS_IAM**) or Amazon Cognito UserPools (**AMAZON\_COGNITO\_USER_POOLS**) or any OpenID Connect Provider (**OPENID_CONNECT**) after you onboard with an API key.

### API Key

For authorization using the API key, update the `awsconfiguration.json` file and code snippet as follows:

#### Configuration

Add the following snippet to your `awsconfiguration.json` file.

```
{
  "AppSync": {
        "Default": {
            "ApiUrl": "YOUR-GRAPHQL-ENDPOINT",
            "Region": "us-east-1",
            "ApiKey": "YOUR-API-KEY",
            "AuthMode": "API_KEY"
        }
   }
}
```

#### Code

Add the following code to use the information in the `Default` section from `awsconfiguration.json` file.

```swift
// You can choose your database location, accessible by the SDK
let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
    
do {
    // Initialize the AWS AppSync configuration
    let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncClientInfo: AWSAppSyncClientInfo(), 
                                                                databaseURL: databaseURL)
    
    // Initialize the AWS AppSync client
    appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
} catch {
    print("Error initializing appsync client. \(error)")
}
```

### AWS IAM

For authorization using the Amazon IAM credentials using Amazon IAM or Amazon STS or Amazon Cognito, update the `awsconfiguration.json` file and code snippet as follows:

#### Configuration

Add the following snippet to your `awsconfiguration.json` file.

```
{
  "CredentialsProvider": {
      "CognitoIdentity": {
          "Default": {
              "PoolId": "YOUR-COGNITO-IDENTITY-POOLID",
              "Region": "us-east-1"
          }
      }
  },
  "AppSync": {
    "Default": {
          "ApiUrl": "YOUR-GRAPHQL-ENDPOINT",
          "Region": "us-east-1",
          "AuthMode": "AWS_IAM"
     }
   }
}
```

#### Code

Add the following code to use the information in the `Default` section from `awsconfiguration.json` file.

```swift
// Set up the Amazon Cognito CredentialsProvider
let credentialsProvider = AWSCognitoCredentialsProvider(regionType: CognitoIdentityRegion,
                                                        identityPoolId: CognitoIdentityPoolId)
                                                                
// You can choose your database location, accessible by the SDK
let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
    
do {
  // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncClientInfo: AWSAppSyncClientInfo(),
                                                                  credentialsProvider: credentialsProvider,
                                                                  databaseURL: databaseURL)
    
    // Initialize the AWS AppSync client
    appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
} catch {
    print("Error initializing appsync client. \(error)")
}
```

### Amazon Cognito UserPools

Follow the instructions in [Setup Email and Password based SignIn](https://docs.aws.amazon.com/aws-mobile/latest/developerguide/add-aws-mobile-user-sign-in.html#set-up-email-and-password) to configure Amazon Cognito User Pools as an Identity Provider to your app.

For authorization using the Amazon Cognito UserPools, update the `awsconfiguration.json` file and code snippet as follows:

#### Configuration

Add the following snippet to your `awsconfiguration.json` file.

```
{
  "CognitoUserPool": {
        "Default": {
            "PoolId": "POOL-ID",
            "AppClientId": "APP-CLIENT-ID",
            "AppClientSecret": "APP-CLIENT-SECRET",
            "Region": "us-east-1"
        }
    },
  "AppSync": {
        "Default": {
            "ApiUrl": "YOUR-GRAPHQL-ENDPOINT",
            "Region": "us-east-1",
            "AuthMode": "AMAZON_COGNITO_USER_POOLS"
        }
   }
}
```

#### Code

Add the following code to use the information in the `Default` section from `awsconfiguration.json` file.

```swift
import AWSUserPoolsSignIn
import AWSAppSync

class MyCognitoUserPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider {

    // background thread - asynchronous
    func getLatestAuthToken() -> String {
        var token: String? = nil
        AWSCognitoUserPoolsSignInProvider.sharedInstance().getUserPool().currentUser()?.getSession().continueOnSuccessWith(block: { (task) -> Any? in
            token = task.result!.idToken!.tokenString
            return nil
        }).waitUntilFinished()
        return token!
    }
}
```

```swift                                
// You can choose your database location, accessible by the SDK
let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
    
do {
  // Initialize the AWS AppSync configuration
   let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncClientInfo: AWSAppSyncClientInfo(),
                                                         userPoolsAuthProvider: MyCognitoUserPoolsAuthProvider(),
                                                         databaseURL:databaseURL)
    
    // Initialize the AWS AppSync client
    appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
} catch {
    print("Error initializing appsync client. \(error)")
}
```

### OIDC (OpenID Connect)

For authorization using any OIDC (OpenID Connect) Identity Provider, update the `awsconfiguration.json` file and code snippet as follows:

#### Configuration

Add the following snippet to your `awsconfiguration.json` file.

```
{
  "AppSync": {
        "Default": {
            "ApiUrl": "YOUR-GRAPHQL-ENDPOINT",
            "Region": "us-east-1",
            "AuthMode": "OPENID_CONNECT"
        }
   }
}
```

#### Code

Add the following code to use the information in the `Default` section from `awsconfiguration.json` file.

```swift
class MyOidcProvider: AWSOIDCAuthProvider {
    func getLatestAuthToken() -> String {
        // Fetch the JWT token string from OIDC Identity provider
        // after the user is successfully signed-in
        return "token"
    }
}
```

```swift
// You can choose your database location, accessible by the SDK
let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
    
do {
  // Initialize the AWS AppSync configuration
    let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncClientInfo: AWSAppSyncClientInfo(),
                                                          oidcAuthProvider: MyOidcProvider(),
                                                          databaseURL:databaseURL)
    
    // Initialize the AWS AppSync client
    appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
} catch {
    print("Error initializing appsync client. \(error)")
}
```

## Convert the App to Use AWS AppSync for the Backend

Add the `AWSAppSyncClient` as a instance member of the `AppDelegate` class. This enables us to access the same client easily across the app. Update the `didFinishLaunching` method in `AppDelegate.swift` with following code:

```swift
import UIKit
import AWSAppSync

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appSyncClient: AWSAppSyncClient?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Set up  Amazon Cognito credentials
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: CognitoIdentityRegion,
                                                                identityPoolId: CognitoIdentityPoolId)
        // You can choose your database location, accessible by SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)

        do {
            // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                                  serviceRegion: AppSyncRegion,
                                                                  credentialsProvider: credentialsProvider,
                                                                  databaseURL:databaseURL)
            // Initialize the AppSync client
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            // Set id as the cache key for objects
            appSyncClient?.apolloClient?.cacheKeyForObject = { $0["id"] }
        } catch {
            print("Error initializing appsync client. \(error)")
        }
        return true
    }

    // ... other intercept methods
 }
```

Update the `AddPostViewController.swift` file with the following code:

```swift
class AddPostViewController: UIViewController {

    @IBOutlet weak var authorInput: UITextField!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var contentInput: UITextField!
    @IBOutlet weak var urlInput: UITextField!
    var appSyncClient: AWSAppSyncClient?

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appSyncClient = appDelegate.appSyncClient!
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    @IBAction func addNewPost(_ sender: Any) {
        // Create a GraphQL mutation
        let uniqueId = UUID().uuidString
        let mutationInput = CreatePostInput(id: uniqueId,
                                            author: authorInput.text!,
                                            title: titleInput.text,
                                            content: contentInput.text,
                                            url: urlInput.text,
                                            version: 1)

        let mutation = AddPostMutation(input: mutationInput)

        appSyncClient?.perform(mutation: mutation, optimisticUpdate: { (transaction) in
            do {
                // Update our normalized local store immediately for a responsive UI
                try transaction?.update(query: AllPostsQuery()) { (data: inout AllPostsQuery.Data) in
                    data.listPosts?.items?.append(AllPostsQuery.Data.ListPost.Item.init(id: uniqueId, title: mutationInput.title!, author: mutationInput.author, content: mutationInput.content!, version: 0))
                }
            } catch {
                print("Error updating the cache with optimistic response.")
            }
        }) { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
                return
            }
            self.dismiss(animated: true, completion: nil)
        }
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
```

Update the `UpdatePostViewController.swift` file with the following
code:

```swift
import Foundation
import UIKit
import AWSAppSync

class UpdatePostViewController: UIViewController {

    var updatePostMutation: UpdatePostMutation?
    var updatePostInput: UpdatePostInput?
    @IBOutlet weak var authorInput: UITextField!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var contentInput: UITextField!
    @IBOutlet weak var urlInput: UITextField!
    var appSyncClient: AWSAppSyncClient?

    override func viewDidLoad() {
        super.viewDidLoad()
        authorInput.text = updatePostInput?.author!
        titleInput.text = updatePostInput?.title!
        contentInput.text = updatePostInput?.content!
        urlInput.text = updatePostInput?.url!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appSyncClient = appDelegate.appSyncClient!
    }

    @IBAction func updatePost(_ sender: Any) {
        updatePostInput?.author = authorInput.text!
        updatePostInput?.title = titleInput.text
        updatePostInput?.content = contentInput.text
        updatePostInput?.url = urlInput.text
        updatePostMutation = UpdatePostMutation(input: updatePostInput!)

        appSyncClient?.perform(mutation: updatePostMutation!) { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred while making request: \(error.localizedDescription )")
                return
            }
            if let resultError = result?.errors {
                print("Error saving the item on server: \(resultError)")
                return
            }
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
```

Update the `PostListViewController.swift` file with the following code:

```swift
import UIKit
import AWSAppSync

class PostCell: UITableViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!

    func updateValues(author: String, title:String?, content: String?) {
        authorLabel.text = author
        titleLabel.text = title
        contentLabel.text = content
    }
}

class PostListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var appSyncClient: AWSAppSyncClient?

    @IBOutlet weak var tableView: UITableView!
    var postList: [AllPostsQuery.Data.ListPost.Item?]? = [] {
        didSet {
            tableView.reloadData()
        }
    }

    func loadAllPosts() {

        appSyncClient?.fetch(query: AllPostsQuery(), cachePolicy: .returnCacheDataAndFetch)  { (result, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                return
            }
            self.postList = result?.data?.listPosts?.items
        }
    }

    func loadAllPostsFromCache() {

        appSyncClient?.fetch(query: AllPostsQuery(), cachePolicy: .returnCacheDataDontFetch)  { (result, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                return
            }
            self.postList = result?.data?.listPosts?.items
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAllPostsFromCache()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        self.automaticallyAdjustsScrollViewInsets = false

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appSyncClient = appDelegate.appSyncClient

        loadAllPosts()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addTapped))
    }

    @objc func addTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "NewPostViewController") as! AddPostViewController
        self.present(controller, animated: true, completion: nil)

    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postList?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        let post = postList![indexPath.row]!
        cell.updateValues(author: post.author, title: post.title, content: post.content)
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let id = postList![indexPath.row]?.id
            let deletePostMutation = DeletePostMutation(input: DeletePostInput(id: id!))
            appSyncClient?.perform(mutation: deletePostMutation) { result, err in
                self.postList?.remove(at: indexPath.row)
            }
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postList![indexPath.row]!
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "UpdatePostViewController") as! UpdatePostViewController
        controller.updatePostInput = UpdatePostInput(id: post.id, author: post.author, title: post.title, content: post.content, url: post.url, ups: 1, downs: 0, version: post.version)
        self.present(controller, animated: true, completion: nil)
    }
}
```

## Make Your App Real Time

AWS AppSync and GraphQL use the concept of subscriptions to deliver real-time updates of data to the application. We have defined subscriptions on the events of `NewPost`, `UpdatePost`, and `DeletePost`. This means we would get a real-time notification if app data is changed from another device, and we can update our application UI based on the updates.

Add a real-time subscription to receive events on a new post that is
added by anyone. In the `PostListViewController.swift` file, add the
following function:

```swift
  func startNewPostSubscription() {
        let subscription = OnCreatePostSubscription()
        do {
            _ = try appSyncClient?.subscribe(subscription: subscription, resultHandler: { (result, transaction, error) in
                if let result = result {
                    // Store a reference to the new object
                    let newPost = result.data!.onCreatePost!
                    // Create a new object for the desired query where the new object content should reside
                    let postToAdd = AllPostsQuery.Data.ListPost.Item(id: newPost.id,
                                                         title: newPost.title,
                                                         author: newPost.author,
                                                         content: newPost.content,
                                                         version: 1)
                    do {
                        // Update the local store with the newly received data
                        try transaction?.update(query: AllPostsQuery()) { (data: inout AllPostsQuery.Data) in
                            data.listPosts?.items?.append(postToAdd)
                        }
                        self.loadAllPostsFromCache()
                    } catch {
                        print("Error updating store")
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                }
            })
        } catch {
            print("Error starting subscription.")
        }
    }
```

Next, call the above method `startNewPostSubscription` from the `viewDidLoad` method of `PostListViewController.` This should update the list of posts every time a new post is added from any client.

## Complex Objects

### Schema setup

Many times you might want to create logical objects that have more complex data, such as images or videos, as part of their structure. For example, you might create a "Person" type with a profile picture or a "Post" type that has an associated image. You can use AWS AppSync to model these as GraphQL types. If any of your mutations have a input variable with `bucket`, `key`, `region`, `mimeType`, and `localUri` fields and is of type `S3ObjectInput`, the SDK will upload the file to `S3` for you.

1. Update your schema as follows to add the `S3Object` and `S3ObjectInput`
types for the file and a new mutation named `CreatePostWithFileInputMutation`:

  ```javascript
  input CreatePostInput {
    id: ID!
    author: String!
    title: String
    content: String
    url: String
    ups: Int
    downs: Int
    version: Int!
  }

  input CreatePostWithFileInput {
    id: ID!
    author: String!
    title: String
    content: String
    url: String
    ups: Int
    downs: Int
    file: S3ObjectInput!
    version: Int!
  }

  input DeletePostInput {
    id: ID!
  }

  type Mutation {
    createPost(input: CreatePostInput!): Post
    createPostWithFile(input: CreatePostWithFileInput!): Post
    updatePost(input: UpdatePostInput!): Post
    deletePost(input: DeletePostInput!): Post
  }

  type Post {
    id: ID!
    author: String!
    title: String
    content: String
    url: String
    ups: Int
    downs: Int
    file: S3Object
    version: Int!
  }

  type PostConnection {
    items: [Post]
    nextToken: String
  }

  type Query {
    singlePost(id: ID!): Post
    getPost(id: ID!): Post
    listPosts(first: Int, after: String): PostConnection
  }

  type S3Object {
    bucket: String!
    key: String!
    region: String!
  }

  input S3ObjectInput {
    bucket: String!
    key: String!
    region: String!
    localUri: String!
    mimeType: String!
  }

  type Subscription {
    onCreatePost(
      id: ID,
      author: String,
      title: String,
      content: String,
      url: String
    ): Post
      @aws_subscribe(mutations: ["createPost"])
    onUpdatePost(
      id: ID,
      author: String,
      title: String,
      content: String,
      url: String
    ): Post
      @aws_subscribe(mutations: ["updatePost"])
    onDeletePost(
      id: ID,
      author: String,
      title: String,
      content: String,
      url: String
    ): Post
      @aws_subscribe(mutations: ["deletePost"])
  }

  input UpdatePostInput {
    id: ID!
    author: String
    title: String
    content: String
    url: String
    ups: Int
    downs: Int
    version: Int
  }

  schema {
    query: Query
    mutation: Mutation
    subscription: Subscription
  }
  ```

  > Note: If you are using the sample schema specified at the start of this documentation, you can replace your schema with above schema.

2. Next, you need to add a resolver for `createPostWithFile` mutation. You can do that from the AppSync console by selecting `PostsTable` as our datasource and the following mapping template:

  Request Mapping Template:

  ```javascript
    {
      "version": "2017-02-28",
      "operation": "PutItem",
      "key": {
        "id": $util.dynamodb.toDynamoDBJson($ctx.args.input.id),
      },
      #set( $attribs = $util.dynamodb.toMapValues($ctx.args.input) )
      #if($util.isNull($ctx.args.input.file.version))
            #set( $attribs.file = $util.dynamodb.toS3Object($ctx.args.input.file.key, $ctx.args.input.file.bucket, $ctx.args.input.file.region))
      #else
            #set( $attribs.file = $util.dynamodb.toS3Object($ctx.args.input.file.key, $ctx.args.input.file.bucket, $ctx.args.input.file.region, $ctx.args.input.file.version))
      #end
      "attributeValues": $util.toJson($attribs),
      "condition": {
        "expression": "attribute_not_exists(#id)",
        "expressionNames": {
          "#id": "id",
        },
      },
   }
  ```

  Response Mapping Template:

  ```javascript
  $util.toJson($context.result)
  ```

3. Once you have a resolver for mutation, to make sure our `S3 Complex Object` details are fetched correctly during any query operation, you will have to add a resolver for the `file` field of `Post`. You can do that from the AppSync console using the following mapping templates:

  Request Mapping Template:
  ```javascript
    {
      "version" : "2017-02-28",
      "operation" : "Query",
      "query" : {
          ## Provide a query expression. **
          "expression": "id = :id",
          "expressionValues" : {
              ":id" : {
                  "S" : "${ctx.args.id}"
              }
          }
      }
    }
  ```

  Response Mapping Template:
  ```javascript
    $util.toJson($util.dynamodb.fromS3ObjectJson($context.source.file))
  ```

Thats it! Now, our AppSync backend is ready to handle `Complex Objects.` Next, you will have to take steps to setup the client.

### Client setup

The AWS AppSync SDK does not take a direct dependency to the AWS SDK for iOS for S3, but takes in `AWSS3TransferUtility` and `AWSS3PresignedURLClient` clients as part of `AWSAppSyncClientConfiguration.`

1. You will need to take a dependency on `AWSS3` SDK. You can do that by updating your `Podfile` to the following:

    ```
    target 'PostsApp' do
      use_frameworks!
      pod 'AWSAppSync', '~>2.6.15'
      pod 'AWSS3', '~>2.6.13'
    end
    ```
2. Run `pod install` to fetch the new dependencies.

3. Download the new updated `schema.json` from the AppSync console and put it in the `GraphQLOperations` folder which we have in the root of the app.

4. Next, you will have to add the new mutation which will be used to perform `S3` uploads as part of mutation. Add the following mutation operation in your `posts.graphql` file:

  ```javascript
    mutation AddPostWithFile($input: CreatePostWithFileInput!) {
      createPostWithFile(input: $input) {
          id
          title
          author
          url
          content
          ups
          downs
          version
          file {
              ...S3Object
          }
      }
    }

    fragment S3Object on S3Object {
      bucket
      key
      region
    }
  ```

5. After adding the new mutation in our operations file, we run the code generator again with the new schema to generate mutations that support file uploads. This time, we will also pass the `-add-s3-wrapper` flag as follows:

  ```sh
  aws-appsync-codegen generate GraphQLOperations/posts.graphql --schema GraphQLOperations/schema.json --output API.swift --add-s3-wrapper
  ```

6. Update the `AWSAppSyncClientConfiguration` object to provide the
`AWSS3TransferUtility` client for managing the uploads and downloads.

  ```swift
  let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                        serviceRegion: AppSyncRegion,
                                                        credentialsProvider: credentialsProvider,
                                                        databaseURL:databaseURL,
                                                        s3ObjectManager: AWSS3TransferUtility.default())
  ```

> Note: The mutation operation does not require any specific changes in method signature, but requires only an `S3ObjectInput` with `bucket`, `key`, `region`, `localUri`, and `mimeType`. Now when you do a mutation, it automatically uploads the specified file to S3 using the `AWSS3TransferUtility` client internally.
