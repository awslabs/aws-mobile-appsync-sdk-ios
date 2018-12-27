//  This file was automatically generated and should not be edited.

import AWSAppSync

public struct CreatePostWithFileInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(author: String, title: String, content: String, url: Optional<String?> = nil, ups: Optional<Int?> = nil, downs: Optional<Int?> = nil, file: S3ObjectInput) {
    graphQLMap = ["author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file]
  }

  public var author: String {
    get {
      return graphQLMap["author"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "author")
    }
  }

  public var title: String {
    get {
      return graphQLMap["title"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "title")
    }
  }

  public var content: String {
    get {
      return graphQLMap["content"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var url: Optional<String?> {
    get {
      return graphQLMap["url"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "url")
    }
  }

  public var ups: Optional<Int?> {
    get {
      return graphQLMap["ups"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ups")
    }
  }

  public var downs: Optional<Int?> {
    get {
      return graphQLMap["downs"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "downs")
    }
  }

  public var file: S3ObjectInput {
    get {
      return graphQLMap["file"] as! S3ObjectInput
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "file")
    }
  }
}

public struct S3ObjectInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(bucket: String, key: String, region: String, localUri: String, mimeType: String) {
    graphQLMap = ["bucket": bucket, "key": key, "region": region, "localUri": localUri, "mimeType": mimeType]
  }

  public var bucket: String {
    get {
      return graphQLMap["bucket"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "bucket")
    }
  }

  public var key: String {
    get {
      return graphQLMap["key"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "key")
    }
  }

  public var region: String {
    get {
      return graphQLMap["region"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "region")
    }
  }

  public var localUri: String {
    get {
      return graphQLMap["localUri"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "localUri")
    }
  }

  public var mimeType: String {
    get {
      return graphQLMap["mimeType"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "mimeType")
    }
  }
}

public enum DeltaAction: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case delete
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "DELETE": self = .delete
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .delete: return "DELETE"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: DeltaAction, rhs: DeltaAction) -> Bool {
    switch (lhs, rhs) {
      case (.delete, .delete): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct CreatePostWithoutFileInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(author: String, title: String, content: String, url: Optional<String?> = nil, ups: Optional<Int?> = nil, downs: Optional<Int?> = nil) {
    graphQLMap = ["author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs]
  }

  public var author: String {
    get {
      return graphQLMap["author"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "author")
    }
  }

  public var title: String {
    get {
      return graphQLMap["title"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "title")
    }
  }

  public var content: String {
    get {
      return graphQLMap["content"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var url: Optional<String?> {
    get {
      return graphQLMap["url"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "url")
    }
  }

  public var ups: Optional<Int?> {
    get {
      return graphQLMap["ups"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ups")
    }
  }

  public var downs: Optional<Int?> {
    get {
      return graphQLMap["downs"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "downs")
    }
  }
}

public struct UpdatePostWithFileInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, author: Optional<String?> = nil, title: Optional<String?> = nil, content: Optional<String?> = nil, url: Optional<String?> = nil, ups: Optional<Int?> = nil, downs: Optional<Int?> = nil, file: S3ObjectInput) {
    graphQLMap = ["id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var author: Optional<String?> {
    get {
      return graphQLMap["author"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "author")
    }
  }

  public var title: Optional<String?> {
    get {
      return graphQLMap["title"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "title")
    }
  }

  public var content: Optional<String?> {
    get {
      return graphQLMap["content"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var url: Optional<String?> {
    get {
      return graphQLMap["url"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "url")
    }
  }

  public var ups: Optional<Int?> {
    get {
      return graphQLMap["ups"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ups")
    }
  }

  public var downs: Optional<Int?> {
    get {
      return graphQLMap["downs"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "downs")
    }
  }

  public var file: S3ObjectInput {
    get {
      return graphQLMap["file"] as! S3ObjectInput
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "file")
    }
  }
}

public struct UpdatePostWithoutFileInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, author: Optional<String?> = nil, title: Optional<String?> = nil, content: Optional<String?> = nil, url: Optional<String?> = nil, ups: Optional<Int?> = nil, downs: Optional<Int?> = nil) {
    graphQLMap = ["id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var author: Optional<String?> {
    get {
      return graphQLMap["author"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "author")
    }
  }

  public var title: Optional<String?> {
    get {
      return graphQLMap["title"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "title")
    }
  }

  public var content: Optional<String?> {
    get {
      return graphQLMap["content"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var url: Optional<String?> {
    get {
      return graphQLMap["url"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "url")
    }
  }

  public var ups: Optional<Int?> {
    get {
      return graphQLMap["ups"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ups")
    }
  }

  public var downs: Optional<Int?> {
    get {
      return graphQLMap["downs"] as! Optional<Int?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "downs")
    }
  }
}

public struct DeletePostInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID) {
    graphQLMap = ["id": id]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }
}

public final class CreatePostWithFileUsingInputTypeMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreatePostWithFileUsingInputType($input: CreatePostWithFileInput!) {\n  createPostWithFileUsingInputType(input: $input) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var input: CreatePostWithFileInput

  public init(input: CreatePostWithFileInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createPostWithFileUsingInputType", arguments: ["input": GraphQLVariable("input")], type: .object(CreatePostWithFileUsingInputType.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createPostWithFileUsingInputType: CreatePostWithFileUsingInputType? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createPostWithFileUsingInputType": createPostWithFileUsingInputType.flatMap { $0.snapshot }])
    }

    public var createPostWithFileUsingInputType: CreatePostWithFileUsingInputType? {
      get {
        return (snapshot["createPostWithFileUsingInputType"] as? Snapshot).flatMap { CreatePostWithFileUsingInputType(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createPostWithFileUsingInputType")
      }
    }

    public struct CreatePostWithFileUsingInputType: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class CreatePostWithFileUsingParametersMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreatePostWithFileUsingParameters($author: String!, $title: String!, $content: String!, $url: String, $ups: Int, $downs: Int, $file: S3ObjectInput!) {\n  createPostWithFileUsingParameters(author: $author, title: $title, content: $content, url: $url, ups: $ups, downs: $downs, file: $file) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var author: String
  public var title: String
  public var content: String
  public var url: String?
  public var ups: Int?
  public var downs: Int?
  public var file: S3ObjectInput

  public init(author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: S3ObjectInput) {
    self.author = author
    self.title = title
    self.content = content
    self.url = url
    self.ups = ups
    self.downs = downs
    self.file = file
  }

  public var variables: GraphQLMap? {
    return ["author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createPostWithFileUsingParameters", arguments: ["author": GraphQLVariable("author"), "title": GraphQLVariable("title"), "content": GraphQLVariable("content"), "url": GraphQLVariable("url"), "ups": GraphQLVariable("ups"), "downs": GraphQLVariable("downs"), "file": GraphQLVariable("file")], type: .object(CreatePostWithFileUsingParameter.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createPostWithFileUsingParameters: CreatePostWithFileUsingParameter? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createPostWithFileUsingParameters": createPostWithFileUsingParameters.flatMap { $0.snapshot }])
    }

    public var createPostWithFileUsingParameters: CreatePostWithFileUsingParameter? {
      get {
        return (snapshot["createPostWithFileUsingParameters"] as? Snapshot).flatMap { CreatePostWithFileUsingParameter(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createPostWithFileUsingParameters")
      }
    }

    public struct CreatePostWithFileUsingParameter: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class CreatePostWithoutFileUsingInputTypeMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreatePostWithoutFileUsingInputType($input: CreatePostWithoutFileInput!) {\n  createPostWithoutFileUsingInputType(input: $input) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var input: CreatePostWithoutFileInput

  public init(input: CreatePostWithoutFileInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createPostWithoutFileUsingInputType", arguments: ["input": GraphQLVariable("input")], type: .object(CreatePostWithoutFileUsingInputType.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createPostWithoutFileUsingInputType: CreatePostWithoutFileUsingInputType? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createPostWithoutFileUsingInputType": createPostWithoutFileUsingInputType.flatMap { $0.snapshot }])
    }

    public var createPostWithoutFileUsingInputType: CreatePostWithoutFileUsingInputType? {
      get {
        return (snapshot["createPostWithoutFileUsingInputType"] as? Snapshot).flatMap { CreatePostWithoutFileUsingInputType(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createPostWithoutFileUsingInputType")
      }
    }

    public struct CreatePostWithoutFileUsingInputType: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class CreatePostWithoutFileUsingParametersMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreatePostWithoutFileUsingParameters($author: String!, $title: String!, $content: String!, $url: String, $ups: Int, $downs: Int) {\n  createPostWithoutFileUsingParameters(author: $author, title: $title, content: $content, url: $url, ups: $ups, downs: $downs) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var author: String
  public var title: String
  public var content: String
  public var url: String?
  public var ups: Int?
  public var downs: Int?

  public init(author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil) {
    self.author = author
    self.title = title
    self.content = content
    self.url = url
    self.ups = ups
    self.downs = downs
  }

  public var variables: GraphQLMap? {
    return ["author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createPostWithoutFileUsingParameters", arguments: ["author": GraphQLVariable("author"), "title": GraphQLVariable("title"), "content": GraphQLVariable("content"), "url": GraphQLVariable("url"), "ups": GraphQLVariable("ups"), "downs": GraphQLVariable("downs")], type: .object(CreatePostWithoutFileUsingParameter.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createPostWithoutFileUsingParameters: CreatePostWithoutFileUsingParameter? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createPostWithoutFileUsingParameters": createPostWithoutFileUsingParameters.flatMap { $0.snapshot }])
    }

    public var createPostWithoutFileUsingParameters: CreatePostWithoutFileUsingParameter? {
      get {
        return (snapshot["createPostWithoutFileUsingParameters"] as? Snapshot).flatMap { CreatePostWithoutFileUsingParameter(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createPostWithoutFileUsingParameters")
      }
    }

    public struct CreatePostWithoutFileUsingParameter: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class UpdatePostWithFileUsingInputTypeMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdatePostWithFileUsingInputType($input: UpdatePostWithFileInput!) {\n  updatePostWithFileUsingInputType(input: $input) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var input: UpdatePostWithFileInput

  public init(input: UpdatePostWithFileInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updatePostWithFileUsingInputType", arguments: ["input": GraphQLVariable("input")], type: .object(UpdatePostWithFileUsingInputType.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updatePostWithFileUsingInputType: UpdatePostWithFileUsingInputType? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updatePostWithFileUsingInputType": updatePostWithFileUsingInputType.flatMap { $0.snapshot }])
    }

    public var updatePostWithFileUsingInputType: UpdatePostWithFileUsingInputType? {
      get {
        return (snapshot["updatePostWithFileUsingInputType"] as? Snapshot).flatMap { UpdatePostWithFileUsingInputType(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updatePostWithFileUsingInputType")
      }
    }

    public struct UpdatePostWithFileUsingInputType: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class UpdatePostWithFileUsingParametersMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdatePostWithFileUsingParameters($id: ID!, $author: String, $title: String, $content: String, $url: String, $ups: Int, $downs: Int, $file: S3ObjectInput!) {\n  updatePostWithFileUsingParameters(id: $id, author: $author, title: $title, content: $content, url: $url, ups: $ups, downs: $downs, file: $file) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var id: GraphQLID
  public var author: String?
  public var title: String?
  public var content: String?
  public var url: String?
  public var ups: Int?
  public var downs: Int?
  public var file: S3ObjectInput

  public init(id: GraphQLID, author: String? = nil, title: String? = nil, content: String? = nil, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: S3ObjectInput) {
    self.id = id
    self.author = author
    self.title = title
    self.content = content
    self.url = url
    self.ups = ups
    self.downs = downs
    self.file = file
  }

  public var variables: GraphQLMap? {
    return ["id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updatePostWithFileUsingParameters", arguments: ["id": GraphQLVariable("id"), "author": GraphQLVariable("author"), "title": GraphQLVariable("title"), "content": GraphQLVariable("content"), "url": GraphQLVariable("url"), "ups": GraphQLVariable("ups"), "downs": GraphQLVariable("downs"), "file": GraphQLVariable("file")], type: .object(UpdatePostWithFileUsingParameter.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updatePostWithFileUsingParameters: UpdatePostWithFileUsingParameter? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updatePostWithFileUsingParameters": updatePostWithFileUsingParameters.flatMap { $0.snapshot }])
    }

    public var updatePostWithFileUsingParameters: UpdatePostWithFileUsingParameter? {
      get {
        return (snapshot["updatePostWithFileUsingParameters"] as? Snapshot).flatMap { UpdatePostWithFileUsingParameter(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updatePostWithFileUsingParameters")
      }
    }

    public struct UpdatePostWithFileUsingParameter: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class UpdatePostWithoutFileUsingInputTypeMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdatePostWithoutFileUsingInputType($input: UpdatePostWithoutFileInput!) {\n  updatePostWithoutFileUsingInputType(input: $input) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var input: UpdatePostWithoutFileInput

  public init(input: UpdatePostWithoutFileInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updatePostWithoutFileUsingInputType", arguments: ["input": GraphQLVariable("input")], type: .object(UpdatePostWithoutFileUsingInputType.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updatePostWithoutFileUsingInputType: UpdatePostWithoutFileUsingInputType? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updatePostWithoutFileUsingInputType": updatePostWithoutFileUsingInputType.flatMap { $0.snapshot }])
    }

    public var updatePostWithoutFileUsingInputType: UpdatePostWithoutFileUsingInputType? {
      get {
        return (snapshot["updatePostWithoutFileUsingInputType"] as? Snapshot).flatMap { UpdatePostWithoutFileUsingInputType(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updatePostWithoutFileUsingInputType")
      }
    }

    public struct UpdatePostWithoutFileUsingInputType: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class UpdatePostWithoutFileUsingParametersMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdatePostWithoutFileUsingParameters($id: ID!, $author: String, $title: String, $content: String, $url: String, $ups: Int, $downs: Int) {\n  updatePostWithoutFileUsingParameters(id: $id, author: $author, title: $title, content: $content, url: $url, ups: $ups, downs: $downs) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var id: GraphQLID
  public var author: String?
  public var title: String?
  public var content: String?
  public var url: String?
  public var ups: Int?
  public var downs: Int?

  public init(id: GraphQLID, author: String? = nil, title: String? = nil, content: String? = nil, url: String? = nil, ups: Int? = nil, downs: Int? = nil) {
    self.id = id
    self.author = author
    self.title = title
    self.content = content
    self.url = url
    self.ups = ups
    self.downs = downs
  }

  public var variables: GraphQLMap? {
    return ["id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updatePostWithoutFileUsingParameters", arguments: ["id": GraphQLVariable("id"), "author": GraphQLVariable("author"), "title": GraphQLVariable("title"), "content": GraphQLVariable("content"), "url": GraphQLVariable("url"), "ups": GraphQLVariable("ups"), "downs": GraphQLVariable("downs")], type: .object(UpdatePostWithoutFileUsingParameter.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updatePostWithoutFileUsingParameters: UpdatePostWithoutFileUsingParameter? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updatePostWithoutFileUsingParameters": updatePostWithoutFileUsingParameters.flatMap { $0.snapshot }])
    }

    public var updatePostWithoutFileUsingParameters: UpdatePostWithoutFileUsingParameter? {
      get {
        return (snapshot["updatePostWithoutFileUsingParameters"] as? Snapshot).flatMap { UpdatePostWithoutFileUsingParameter(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updatePostWithoutFileUsingParameters")
      }
    }

    public struct UpdatePostWithoutFileUsingParameter: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class DeletePostUsingInputTypeMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeletePostUsingInputType($input: DeletePostInput!) {\n  deletePostUsingInputType(input: $input) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var input: DeletePostInput

  public init(input: DeletePostInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deletePostUsingInputType", arguments: ["input": GraphQLVariable("input")], type: .object(DeletePostUsingInputType.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deletePostUsingInputType: DeletePostUsingInputType? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deletePostUsingInputType": deletePostUsingInputType.flatMap { $0.snapshot }])
    }

    public var deletePostUsingInputType: DeletePostUsingInputType? {
      get {
        return (snapshot["deletePostUsingInputType"] as? Snapshot).flatMap { DeletePostUsingInputType(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deletePostUsingInputType")
      }
    }

    public struct DeletePostUsingInputType: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class DeletePostUsingParametersMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeletePostUsingParameters($id: ID!) {\n  deletePostUsingParameters(id: $id) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deletePostUsingParameters", arguments: ["id": GraphQLVariable("id")], type: .object(DeletePostUsingParameter.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deletePostUsingParameters: DeletePostUsingParameter? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deletePostUsingParameters": deletePostUsingParameters.flatMap { $0.snapshot }])
    }

    public var deletePostUsingParameters: DeletePostUsingParameter? {
      get {
        return (snapshot["deletePostUsingParameters"] as? Snapshot).flatMap { DeletePostUsingParameter(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deletePostUsingParameters")
      }
    }

    public struct DeletePostUsingParameter: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class GetPostQuery: GraphQLQuery {
  public static let operationString =
    "query GetPost($id: ID!) {\n  getPost(id: $id) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getPost", arguments: ["id": GraphQLVariable("id")], type: .object(GetPost.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getPost: GetPost? = nil) {
      self.init(snapshot: ["__typename": "Query", "getPost": getPost.flatMap { $0.snapshot }])
    }

    public var getPost: GetPost? {
      get {
        return (snapshot["getPost"] as? Snapshot).flatMap { GetPost(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getPost")
      }
    }

    public struct GetPost: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class ListPostsQuery: GraphQLQuery {
  public static let operationString =
    "query ListPosts {\n  listPosts {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listPosts", type: .list(.object(ListPost.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listPosts: [ListPost?]? = nil) {
      self.init(snapshot: ["__typename": "Query", "listPosts": listPosts.flatMap { $0.map { $0.flatMap { $0.snapshot } } }])
    }

    public var listPosts: [ListPost?]? {
      get {
        return (snapshot["listPosts"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { ListPost(snapshot: $0) } } }
      }
      set {
        snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "listPosts")
      }
    }

    public struct ListPost: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class ListPostsDeltaQuery: GraphQLQuery {
  public static let operationString =
    "query ListPostsDelta($lastSync: AWSTimestamp) {\n  listPostsDelta(lastSync: $lastSync) {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public var lastSync: Int?

  public init(lastSync: Int? = nil) {
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listPostsDelta", arguments: ["lastSync": GraphQLVariable("lastSync")], type: .list(.object(ListPostsDeltum.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listPostsDelta: [ListPostsDeltum?]? = nil) {
      self.init(snapshot: ["__typename": "Query", "listPostsDelta": listPostsDelta.flatMap { $0.map { $0.flatMap { $0.snapshot } } }])
    }

    public var listPostsDelta: [ListPostsDeltum?]? {
      get {
        return (snapshot["listPostsDelta"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { ListPostsDeltum(snapshot: $0) } } }
      }
      set {
        snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "listPostsDelta")
      }
    }

    public struct ListPostsDeltum: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}

public final class OnDeltaPostSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeltaPost {\n  onDeltaPost {\n    __typename\n    id\n    author\n    title\n    content\n    url\n    ups\n    downs\n    file {\n      __typename\n      bucket\n      key\n      region\n    }\n    createdDate\n    aws_ds\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeltaPost", type: .object(OnDeltaPost.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeltaPost: OnDeltaPost? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeltaPost": onDeltaPost.flatMap { $0.snapshot }])
    }

    public var onDeltaPost: OnDeltaPost? {
      get {
        return (snapshot["onDeltaPost"] as? Snapshot).flatMap { OnDeltaPost(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeltaPost")
      }
    }

    public struct OnDeltaPost: GraphQLSelectionSet {
      public static let possibleTypes = ["Post"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("author", type: .nonNull(.scalar(String.self))),
        GraphQLField("title", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("url", type: .scalar(String.self)),
        GraphQLField("ups", type: .scalar(Int.self)),
        GraphQLField("downs", type: .scalar(Int.self)),
        GraphQLField("file", type: .object(File.selections)),
        GraphQLField("createdDate", type: .scalar(String.self)),
        GraphQLField("aws_ds", type: .scalar(DeltaAction.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, author: String, title: String, content: String, url: String? = nil, ups: Int? = nil, downs: Int? = nil, file: File? = nil, createdDate: String? = nil, awsDs: DeltaAction? = nil) {
        self.init(snapshot: ["__typename": "Post", "id": id, "author": author, "title": title, "content": content, "url": url, "ups": ups, "downs": downs, "file": file.flatMap { $0.snapshot }, "createdDate": createdDate, "aws_ds": awsDs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var author: String {
        get {
          return snapshot["author"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "author")
        }
      }

      public var title: String {
        get {
          return snapshot["title"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "title")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var url: String? {
        get {
          return snapshot["url"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "url")
        }
      }

      public var ups: Int? {
        get {
          return snapshot["ups"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "ups")
        }
      }

      public var downs: Int? {
        get {
          return snapshot["downs"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "downs")
        }
      }

      public var file: File? {
        get {
          return (snapshot["file"] as? Snapshot).flatMap { File(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "file")
        }
      }

      public var createdDate: String? {
        get {
          return snapshot["createdDate"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdDate")
        }
      }

      public var awsDs: DeltaAction? {
        get {
          return snapshot["aws_ds"] as? DeltaAction
        }
        set {
          snapshot.updateValue(newValue, forKey: "aws_ds")
        }
      }

      public struct File: GraphQLSelectionSet {
        public static let possibleTypes = ["S3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(bucket: String, key: String, region: String) {
          self.init(snapshot: ["__typename": "S3Object", "bucket": bucket, "key": key, "region": region])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }
      }
    }
  }
}