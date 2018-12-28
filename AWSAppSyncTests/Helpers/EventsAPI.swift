//  This file was automatically generated and should not be edited.

import AWSAppSync

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

public struct TableEventFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: Optional<TableIDFilterInput?> = nil, name: Optional<TableStringFilterInput?> = nil, `where`: Optional<TableStringFilterInput?> = nil, when: Optional<TableStringFilterInput?> = nil, description: Optional<TableStringFilterInput?> = nil) {
    graphQLMap = ["id": id, "name": name, "where": `where`, "when": when, "description": description]
  }

  public var id: Optional<TableIDFilterInput?> {
    get {
      return graphQLMap["id"] as! Optional<TableIDFilterInput?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: Optional<TableStringFilterInput?> {
    get {
      return graphQLMap["name"] as! Optional<TableStringFilterInput?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var `where`: Optional<TableStringFilterInput?> {
    get {
      return graphQLMap["where"] as! Optional<TableStringFilterInput?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "where")
    }
  }

  public var when: Optional<TableStringFilterInput?> {
    get {
      return graphQLMap["when"] as! Optional<TableStringFilterInput?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "when")
    }
  }

  public var description: Optional<TableStringFilterInput?> {
    get {
      return graphQLMap["description"] as! Optional<TableStringFilterInput?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "description")
    }
  }
}

public struct TableIDFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Optional<GraphQLID?> = nil, eq: Optional<GraphQLID?> = nil, le: Optional<GraphQLID?> = nil, lt: Optional<GraphQLID?> = nil, ge: Optional<GraphQLID?> = nil, gt: Optional<GraphQLID?> = nil, contains: Optional<GraphQLID?> = nil, notContains: Optional<GraphQLID?> = nil, between: Optional<[GraphQLID?]?> = nil, beginsWith: Optional<GraphQLID?> = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith]
  }

  public var ne: Optional<GraphQLID?> {
    get {
      return graphQLMap["ne"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Optional<GraphQLID?> {
    get {
      return graphQLMap["eq"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Optional<GraphQLID?> {
    get {
      return graphQLMap["le"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Optional<GraphQLID?> {
    get {
      return graphQLMap["lt"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Optional<GraphQLID?> {
    get {
      return graphQLMap["ge"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Optional<GraphQLID?> {
    get {
      return graphQLMap["gt"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: Optional<GraphQLID?> {
    get {
      return graphQLMap["contains"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: Optional<GraphQLID?> {
    get {
      return graphQLMap["notContains"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: Optional<[GraphQLID?]?> {
    get {
      return graphQLMap["between"] as! Optional<[GraphQLID?]?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: Optional<GraphQLID?> {
    get {
      return graphQLMap["beginsWith"] as! Optional<GraphQLID?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }
}

public struct TableStringFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Optional<String?> = nil, eq: Optional<String?> = nil, le: Optional<String?> = nil, lt: Optional<String?> = nil, ge: Optional<String?> = nil, gt: Optional<String?> = nil, contains: Optional<String?> = nil, notContains: Optional<String?> = nil, between: Optional<[String?]?> = nil, beginsWith: Optional<String?> = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith]
  }

  public var ne: Optional<String?> {
    get {
      return graphQLMap["ne"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Optional<String?> {
    get {
      return graphQLMap["eq"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Optional<String?> {
    get {
      return graphQLMap["le"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Optional<String?> {
    get {
      return graphQLMap["lt"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Optional<String?> {
    get {
      return graphQLMap["ge"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Optional<String?> {
    get {
      return graphQLMap["gt"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: Optional<String?> {
    get {
      return graphQLMap["contains"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: Optional<String?> {
    get {
      return graphQLMap["notContains"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: Optional<[String?]?> {
    get {
      return graphQLMap["between"] as! Optional<[String?]?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: Optional<String?> {
    get {
      return graphQLMap["beginsWith"] as! Optional<String?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }
}

public final class AddEventMutation: GraphQLMutation {
  public static let operationString =
    "mutation AddEvent($name: String!, $when: String!, $where: String!, $description: String!) {\n  createEvent(name: $name, when: $when, where: $where, description: $description) {\n    __typename\n    id\n    name\n    where\n    when\n    description\n    comments {\n      __typename\n      items {\n        __typename\n        eventId\n        commentId\n        content\n        createdAt\n      }\n      nextToken\n    }\n  }\n}"

  public var name: String
  public var when: String
  public var `where`: String
  public var description: String

  public init(name: String, when: String, `where`: String, description: String) {
    self.name = name
    self.when = when
    self.where = `where`
    self.description = description
  }

  public var variables: GraphQLMap? {
    return ["name": name, "when": when, "where": `where`, "description": description]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createEvent", arguments: ["name": GraphQLVariable("name"), "when": GraphQLVariable("when"), "where": GraphQLVariable("where"), "description": GraphQLVariable("description")], type: .object(AddEvent.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createEvent: AddEvent? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createEvent": createEvent.flatMap { $0.snapshot }])
    }

    /// Create a single event.
    public var createEvent: AddEvent? {
      get {
        return (snapshot["createEvent"] as? Snapshot).flatMap { AddEvent(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createEvent")
      }
    }

    public struct AddEvent: GraphQLSelectionSet {
      public static let possibleTypes = ["Event"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .scalar(String.self)),
        GraphQLField("where", type: .scalar(String.self)),
        GraphQLField("when", type: .scalar(String.self)),
        GraphQLField("description", type: .scalar(String.self)),
        GraphQLField("comments", type: .object(Comment.selections)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String? = nil, `where`: String? = nil, when: String? = nil, description: String? = nil, comments: Comment? = nil) {
        self.init(snapshot: ["__typename": "Event", "id": id, "name": name, "where": `where`, "when": when, "description": description, "comments": comments.flatMap { $0.snapshot }])
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

      public var name: String? {
        get {
          return snapshot["name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var `where`: String? {
        get {
          return snapshot["where"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "where")
        }
      }

      public var when: String? {
        get {
          return snapshot["when"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "when")
        }
      }

      public var description: String? {
        get {
          return snapshot["description"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      /// Paginate through all comments belonging to an individual post.
      public var comments: Comment? {
        get {
          return (snapshot["comments"] as? Snapshot).flatMap { Comment(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "comments")
        }
      }

      public struct Comment: GraphQLSelectionSet {
        public static let possibleTypes = ["CommentConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("items", type: .list(.object(Item.selections))),
          GraphQLField("nextToken", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(items: [Item?]? = nil, nextToken: String? = nil) {
          self.init(snapshot: ["__typename": "CommentConnection", "items": items.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "nextToken": nextToken])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var items: [Item?]? {
          get {
            return (snapshot["items"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Item(snapshot: $0) } } }
          }
          set {
            snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "items")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public struct Item: GraphQLSelectionSet {
          public static let possibleTypes = ["Comment"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("eventId", type: .nonNull(.scalar(GraphQLID.self))),
            GraphQLField("commentId", type: .nonNull(.scalar(String.self))),
            GraphQLField("content", type: .nonNull(.scalar(String.self))),
            GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(eventId: GraphQLID, commentId: String, content: String, createdAt: String) {
            self.init(snapshot: ["__typename": "Comment", "eventId": eventId, "commentId": commentId, "content": content, "createdAt": createdAt])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The id of the comment's parent event.
          public var eventId: GraphQLID {
            get {
              return snapshot["eventId"]! as! GraphQLID
            }
            set {
              snapshot.updateValue(newValue, forKey: "eventId")
            }
          }

          /// A unique identifier for the comment.
          public var commentId: String {
            get {
              return snapshot["commentId"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "commentId")
            }
          }

          /// The comment's content.
          public var content: String {
            get {
              return snapshot["content"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "content")
            }
          }

          /// The comment timestamp. This field is indexed to enable sorted pagination.
          public var createdAt: String {
            get {
              return snapshot["createdAt"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "createdAt")
            }
          }
        }
      }
    }
  }
}

public final class AddEventWithFileMutation: GraphQLMutation {
  public static let operationString =
    "mutation AddEventWithFile($name: String!, $when: String!, $where: String!, $description: String!, $file: S3ObjectInput) {\n  createEventWithFile(name: $name, when: $when, where: $where, description: $description, file: $file) {\n    __typename\n    id\n    name\n    where\n    when\n    description\n    comments {\n      __typename\n      items {\n        __typename\n        eventId\n        commentId\n        content\n        createdAt\n      }\n      nextToken\n    }\n  }\n}"

  public var name: String
  public var when: String
  public var `where`: String
  public var description: String
  public var file: S3ObjectInput?

  public init(name: String, when: String, `where`: String, description: String, file: S3ObjectInput? = nil) {
    self.name = name
    self.when = when
    self.where = `where`
    self.description = description
    self.file = file
  }

  public var variables: GraphQLMap? {
    return ["name": name, "when": when, "where": `where`, "description": description, "file": file]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createEventWithFile", arguments: ["name": GraphQLVariable("name"), "when": GraphQLVariable("when"), "where": GraphQLVariable("where"), "description": GraphQLVariable("description"), "file": GraphQLVariable("file")], type: .object(AddEventWithFile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createEventWithFile: AddEventWithFile? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createEventWithFile": createEventWithFile.flatMap { $0.snapshot }])
    }

    /// Create a single event with a file attachment that will be uploaded to S3
    public var createEventWithFile: AddEventWithFile? {
      get {
        return (snapshot["createEventWithFile"] as? Snapshot).flatMap { AddEventWithFile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createEventWithFile")
      }
    }

    public struct AddEventWithFile: GraphQLSelectionSet {
      public static let possibleTypes = ["Event"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .scalar(String.self)),
        GraphQLField("where", type: .scalar(String.self)),
        GraphQLField("when", type: .scalar(String.self)),
        GraphQLField("description", type: .scalar(String.self)),
        GraphQLField("comments", type: .object(Comment.selections)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String? = nil, `where`: String? = nil, when: String? = nil, description: String? = nil, comments: Comment? = nil) {
        self.init(snapshot: ["__typename": "Event", "id": id, "name": name, "where": `where`, "when": when, "description": description, "comments": comments.flatMap { $0.snapshot }])
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

      public var name: String? {
        get {
          return snapshot["name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var `where`: String? {
        get {
          return snapshot["where"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "where")
        }
      }

      public var when: String? {
        get {
          return snapshot["when"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "when")
        }
      }

      public var description: String? {
        get {
          return snapshot["description"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      /// Paginate through all comments belonging to an individual post.
      public var comments: Comment? {
        get {
          return (snapshot["comments"] as? Snapshot).flatMap { Comment(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "comments")
        }
      }

      public struct Comment: GraphQLSelectionSet {
        public static let possibleTypes = ["CommentConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("items", type: .list(.object(Item.selections))),
          GraphQLField("nextToken", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(items: [Item?]? = nil, nextToken: String? = nil) {
          self.init(snapshot: ["__typename": "CommentConnection", "items": items.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "nextToken": nextToken])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var items: [Item?]? {
          get {
            return (snapshot["items"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Item(snapshot: $0) } } }
          }
          set {
            snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "items")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public struct Item: GraphQLSelectionSet {
          public static let possibleTypes = ["Comment"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("eventId", type: .nonNull(.scalar(GraphQLID.self))),
            GraphQLField("commentId", type: .nonNull(.scalar(String.self))),
            GraphQLField("content", type: .nonNull(.scalar(String.self))),
            GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(eventId: GraphQLID, commentId: String, content: String, createdAt: String) {
            self.init(snapshot: ["__typename": "Comment", "eventId": eventId, "commentId": commentId, "content": content, "createdAt": createdAt])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The id of the comment's parent event.
          public var eventId: GraphQLID {
            get {
              return snapshot["eventId"]! as! GraphQLID
            }
            set {
              snapshot.updateValue(newValue, forKey: "eventId")
            }
          }

          /// A unique identifier for the comment.
          public var commentId: String {
            get {
              return snapshot["commentId"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "commentId")
            }
          }

          /// The comment's content.
          public var content: String {
            get {
              return snapshot["content"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "content")
            }
          }

          /// The comment timestamp. This field is indexed to enable sorted pagination.
          public var createdAt: String {
            get {
              return snapshot["createdAt"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "createdAt")
            }
          }
        }
      }
    }
  }
}

public final class DeleteEventMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteEvent($id: ID!) {\n  deleteEvent(id: $id) {\n    __typename\n    id\n    name\n    where\n    when\n    description\n    comments {\n      __typename\n      items {\n        __typename\n        eventId\n        commentId\n        content\n        createdAt\n      }\n      nextToken\n    }\n  }\n}"

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
      GraphQLField("deleteEvent", arguments: ["id": GraphQLVariable("id")], type: .object(DeleteEvent.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteEvent: DeleteEvent? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteEvent": deleteEvent.flatMap { $0.snapshot }])
    }

    /// Delete a single event by id.
    public var deleteEvent: DeleteEvent? {
      get {
        return (snapshot["deleteEvent"] as? Snapshot).flatMap { DeleteEvent(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteEvent")
      }
    }

    public struct DeleteEvent: GraphQLSelectionSet {
      public static let possibleTypes = ["Event"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .scalar(String.self)),
        GraphQLField("where", type: .scalar(String.self)),
        GraphQLField("when", type: .scalar(String.self)),
        GraphQLField("description", type: .scalar(String.self)),
        GraphQLField("comments", type: .object(Comment.selections)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String? = nil, `where`: String? = nil, when: String? = nil, description: String? = nil, comments: Comment? = nil) {
        self.init(snapshot: ["__typename": "Event", "id": id, "name": name, "where": `where`, "when": when, "description": description, "comments": comments.flatMap { $0.snapshot }])
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

      public var name: String? {
        get {
          return snapshot["name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var `where`: String? {
        get {
          return snapshot["where"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "where")
        }
      }

      public var when: String? {
        get {
          return snapshot["when"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "when")
        }
      }

      public var description: String? {
        get {
          return snapshot["description"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      /// Paginate through all comments belonging to an individual post.
      public var comments: Comment? {
        get {
          return (snapshot["comments"] as? Snapshot).flatMap { Comment(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "comments")
        }
      }

      public struct Comment: GraphQLSelectionSet {
        public static let possibleTypes = ["CommentConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("items", type: .list(.object(Item.selections))),
          GraphQLField("nextToken", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(items: [Item?]? = nil, nextToken: String? = nil) {
          self.init(snapshot: ["__typename": "CommentConnection", "items": items.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "nextToken": nextToken])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var items: [Item?]? {
          get {
            return (snapshot["items"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Item(snapshot: $0) } } }
          }
          set {
            snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "items")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public struct Item: GraphQLSelectionSet {
          public static let possibleTypes = ["Comment"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("eventId", type: .nonNull(.scalar(GraphQLID.self))),
            GraphQLField("commentId", type: .nonNull(.scalar(String.self))),
            GraphQLField("content", type: .nonNull(.scalar(String.self))),
            GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(eventId: GraphQLID, commentId: String, content: String, createdAt: String) {
            self.init(snapshot: ["__typename": "Comment", "eventId": eventId, "commentId": commentId, "content": content, "createdAt": createdAt])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The id of the comment's parent event.
          public var eventId: GraphQLID {
            get {
              return snapshot["eventId"]! as! GraphQLID
            }
            set {
              snapshot.updateValue(newValue, forKey: "eventId")
            }
          }

          /// A unique identifier for the comment.
          public var commentId: String {
            get {
              return snapshot["commentId"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "commentId")
            }
          }

          /// The comment's content.
          public var content: String {
            get {
              return snapshot["content"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "content")
            }
          }

          /// The comment timestamp. This field is indexed to enable sorted pagination.
          public var createdAt: String {
            get {
              return snapshot["createdAt"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "createdAt")
            }
          }
        }
      }
    }
  }
}

public final class CommentOnEventMutation: GraphQLMutation {
  public static let operationString =
    "mutation CommentOnEvent($eventId: ID!, $content: String!, $createdAt: String!) {\n  commentOnEvent(eventId: $eventId, content: $content, createdAt: $createdAt) {\n    __typename\n    eventId\n    commentId\n    content\n    createdAt\n  }\n}"

  public var eventId: GraphQLID
  public var content: String
  public var createdAt: String

  public init(eventId: GraphQLID, content: String, createdAt: String) {
    self.eventId = eventId
    self.content = content
    self.createdAt = createdAt
  }

  public var variables: GraphQLMap? {
    return ["eventId": eventId, "content": content, "createdAt": createdAt]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("commentOnEvent", arguments: ["eventId": GraphQLVariable("eventId"), "content": GraphQLVariable("content"), "createdAt": GraphQLVariable("createdAt")], type: .object(CommentOnEvent.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(commentOnEvent: CommentOnEvent? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "commentOnEvent": commentOnEvent.flatMap { $0.snapshot }])
    }

    /// Comment on an event.
    public var commentOnEvent: CommentOnEvent? {
      get {
        return (snapshot["commentOnEvent"] as? Snapshot).flatMap { CommentOnEvent(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "commentOnEvent")
      }
    }

    public struct CommentOnEvent: GraphQLSelectionSet {
      public static let possibleTypes = ["Comment"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("eventId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("commentId", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(eventId: GraphQLID, commentId: String, content: String, createdAt: String) {
        self.init(snapshot: ["__typename": "Comment", "eventId": eventId, "commentId": commentId, "content": content, "createdAt": createdAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      /// The id of the comment's parent event.
      public var eventId: GraphQLID {
        get {
          return snapshot["eventId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "eventId")
        }
      }

      /// A unique identifier for the comment.
      public var commentId: String {
        get {
          return snapshot["commentId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "commentId")
        }
      }

      /// The comment's content.
      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      /// The comment timestamp. This field is indexed to enable sorted pagination.
      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }
    }
  }
}

public final class GetEventQuery: GraphQLQuery {
  public static let operationString =
    "query GetEvent($id: ID!) {\n  getEvent(id: $id) {\n    __typename\n    id\n    name\n    where\n    when\n    description\n    comments {\n      __typename\n      items {\n        __typename\n        eventId\n        commentId\n        content\n        createdAt\n      }\n      nextToken\n    }\n  }\n}"

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
      GraphQLField("getEvent", arguments: ["id": GraphQLVariable("id")], type: .object(GetEvent.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getEvent: GetEvent? = nil) {
      self.init(snapshot: ["__typename": "Query", "getEvent": getEvent.flatMap { $0.snapshot }])
    }

    /// Get a single event by id.
    public var getEvent: GetEvent? {
      get {
        return (snapshot["getEvent"] as? Snapshot).flatMap { GetEvent(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getEvent")
      }
    }

    public struct GetEvent: GraphQLSelectionSet {
      public static let possibleTypes = ["Event"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .scalar(String.self)),
        GraphQLField("where", type: .scalar(String.self)),
        GraphQLField("when", type: .scalar(String.self)),
        GraphQLField("description", type: .scalar(String.self)),
        GraphQLField("comments", type: .object(Comment.selections)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String? = nil, `where`: String? = nil, when: String? = nil, description: String? = nil, comments: Comment? = nil) {
        self.init(snapshot: ["__typename": "Event", "id": id, "name": name, "where": `where`, "when": when, "description": description, "comments": comments.flatMap { $0.snapshot }])
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

      public var name: String? {
        get {
          return snapshot["name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var `where`: String? {
        get {
          return snapshot["where"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "where")
        }
      }

      public var when: String? {
        get {
          return snapshot["when"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "when")
        }
      }

      public var description: String? {
        get {
          return snapshot["description"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      /// Paginate through all comments belonging to an individual post.
      public var comments: Comment? {
        get {
          return (snapshot["comments"] as? Snapshot).flatMap { Comment(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "comments")
        }
      }

      public struct Comment: GraphQLSelectionSet {
        public static let possibleTypes = ["CommentConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("items", type: .list(.object(Item.selections))),
          GraphQLField("nextToken", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(items: [Item?]? = nil, nextToken: String? = nil) {
          self.init(snapshot: ["__typename": "CommentConnection", "items": items.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "nextToken": nextToken])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var items: [Item?]? {
          get {
            return (snapshot["items"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Item(snapshot: $0) } } }
          }
          set {
            snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "items")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public struct Item: GraphQLSelectionSet {
          public static let possibleTypes = ["Comment"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("eventId", type: .nonNull(.scalar(GraphQLID.self))),
            GraphQLField("commentId", type: .nonNull(.scalar(String.self))),
            GraphQLField("content", type: .nonNull(.scalar(String.self))),
            GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(eventId: GraphQLID, commentId: String, content: String, createdAt: String) {
            self.init(snapshot: ["__typename": "Comment", "eventId": eventId, "commentId": commentId, "content": content, "createdAt": createdAt])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The id of the comment's parent event.
          public var eventId: GraphQLID {
            get {
              return snapshot["eventId"]! as! GraphQLID
            }
            set {
              snapshot.updateValue(newValue, forKey: "eventId")
            }
          }

          /// A unique identifier for the comment.
          public var commentId: String {
            get {
              return snapshot["commentId"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "commentId")
            }
          }

          /// The comment's content.
          public var content: String {
            get {
              return snapshot["content"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "content")
            }
          }

          /// The comment timestamp. This field is indexed to enable sorted pagination.
          public var createdAt: String {
            get {
              return snapshot["createdAt"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "createdAt")
            }
          }
        }
      }
    }
  }
}

public final class ListEventsQuery: GraphQLQuery {
  public static let operationString =
    "query ListEvents($filter: TableEventFilterInput, $limit: Int, $nextToken: String) {\n  listEvents(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      name\n      where\n      when\n      description\n      comments {\n        __typename\n        items {\n          __typename\n          eventId\n          commentId\n          content\n          createdAt\n        }\n        nextToken\n      }\n    }\n    nextToken\n  }\n}"

  public var filter: TableEventFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: TableEventFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listEvents", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListEvent.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listEvents: ListEvent? = nil) {
      self.init(snapshot: ["__typename": "Query", "listEvents": listEvents.flatMap { $0.snapshot }])
    }

    /// Paginate through events.
    public var listEvents: ListEvent? {
      get {
        return (snapshot["listEvents"] as? Snapshot).flatMap { ListEvent(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listEvents")
      }
    }

    public struct ListEvent: GraphQLSelectionSet {
      public static let possibleTypes = ["EventConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .list(.object(Item.selections))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?]? = nil, nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "EventConnection", "items": items.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?]? {
        get {
          return (snapshot["items"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Item(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Event"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .scalar(String.self)),
          GraphQLField("where", type: .scalar(String.self)),
          GraphQLField("when", type: .scalar(String.self)),
          GraphQLField("description", type: .scalar(String.self)),
          GraphQLField("comments", type: .object(Comment.selections)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, description: String? = nil, name: String? = nil, when: String? = nil, `where`: String? = nil, comments: Comment? = nil) {
          self.init(snapshot: ["__typename": "Event", "id": id, "name": name, "where": `where`, "when": when, "description": description, "comments": comments.flatMap { $0.snapshot }])
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

        public var name: String? {
          get {
            return snapshot["name"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var `where`: String? {
          get {
            return snapshot["where"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "where")
          }
        }

        public var when: String? {
          get {
            return snapshot["when"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "when")
          }
        }

        public var description: String? {
          get {
            return snapshot["description"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        /// Paginate through all comments belonging to an individual post.
        public var comments: Comment? {
          get {
            return (snapshot["comments"] as? Snapshot).flatMap { Comment(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue?.snapshot, forKey: "comments")
          }
        }

        public struct Comment: GraphQLSelectionSet {
          public static let possibleTypes = ["CommentConnection"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("items", type: .list(.object(Item.selections))),
            GraphQLField("nextToken", type: .scalar(String.self)),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(items: [Item?]? = nil, nextToken: String? = nil) {
            self.init(snapshot: ["__typename": "CommentConnection", "items": items.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "nextToken": nextToken])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          public var items: [Item?]? {
            get {
              return (snapshot["items"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Item(snapshot: $0) } } }
            }
            set {
              snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "items")
            }
          }

          public var nextToken: String? {
            get {
              return snapshot["nextToken"] as? String
            }
            set {
              snapshot.updateValue(newValue, forKey: "nextToken")
            }
          }

          public struct Item: GraphQLSelectionSet {
            public static let possibleTypes = ["Comment"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("eventId", type: .nonNull(.scalar(GraphQLID.self))),
              GraphQLField("commentId", type: .nonNull(.scalar(String.self))),
              GraphQLField("content", type: .nonNull(.scalar(String.self))),
              GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
            ]

            public var snapshot: Snapshot

            public init(snapshot: Snapshot) {
              self.snapshot = snapshot
            }

            public init(eventId: GraphQLID, commentId: String, content: String, createdAt: String) {
              self.init(snapshot: ["__typename": "Comment", "eventId": eventId, "commentId": commentId, "content": content, "createdAt": createdAt])
            }

            public var __typename: String {
              get {
                return snapshot["__typename"]! as! String
              }
              set {
                snapshot.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The id of the comment's parent event.
            public var eventId: GraphQLID {
              get {
                return snapshot["eventId"]! as! GraphQLID
              }
              set {
                snapshot.updateValue(newValue, forKey: "eventId")
              }
            }

            /// A unique identifier for the comment.
            public var commentId: String {
              get {
                return snapshot["commentId"]! as! String
              }
              set {
                snapshot.updateValue(newValue, forKey: "commentId")
              }
            }

            /// The comment's content.
            public var content: String {
              get {
                return snapshot["content"]! as! String
              }
              set {
                snapshot.updateValue(newValue, forKey: "content")
              }
            }

            /// The comment timestamp. This field is indexed to enable sorted pagination.
            public var createdAt: String {
              get {
                return snapshot["createdAt"]! as! String
              }
              set {
                snapshot.updateValue(newValue, forKey: "createdAt")
              }
            }
          }
        }
      }
    }
  }
}

public final class NewCommentOnEventSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription SubscribeToEventComments($eventId: String!) {\n  subscribeToEventComments(eventId: $eventId) {\n    __typename\n    eventId\n    commentId\n    content\n    createdAt\n  }\n}"

  public var eventId: String

  public init(eventId: String) {
    self.eventId = eventId
  }

  public var variables: GraphQLMap? {
    return ["eventId": eventId]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("subscribeToEventComments", arguments: ["eventId": GraphQLVariable("eventId")], type: .object(SubscribeToEventComment.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(subscribeToEventComments: SubscribeToEventComment? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "subscribeToEventComments": subscribeToEventComments.flatMap { $0.snapshot }])
    }

    public var subscribeToEventComments: SubscribeToEventComment? {
      get {
        return (snapshot["subscribeToEventComments"] as? Snapshot).flatMap { SubscribeToEventComment(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "subscribeToEventComments")
      }
    }

    public struct SubscribeToEventComment: GraphQLSelectionSet {
      public static let possibleTypes = ["Comment"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("eventId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("commentId", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(eventId: GraphQLID, commentId: String, content: String, createdAt: String) {
        self.init(snapshot: ["__typename": "Comment", "eventId": eventId, "commentId": commentId, "content": content, "createdAt": createdAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      /// The id of the comment's parent event.
      public var eventId: GraphQLID {
        get {
          return snapshot["eventId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "eventId")
        }
      }

      /// A unique identifier for the comment.
      public var commentId: String {
        get {
          return snapshot["commentId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "commentId")
        }
      }

      /// The comment's content.
      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      /// The comment timestamp. This field is indexed to enable sorted pagination.
      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }
    }
  }
}
