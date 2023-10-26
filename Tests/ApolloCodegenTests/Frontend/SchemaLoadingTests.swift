import XCTest
import Nimble
import ApolloInternalTestHelpers
import ApolloCodegenInternalTestHelpers
@testable import ApolloCodegenLib
@testable import GraphQLCompiler

class SchemaLoadingTests: XCTestCase {
  
  var codegenFrontend: GraphQLJSFrontend!
  
  override func setUp() async throws {
    try await super.setUp()

    codegenFrontend = try await GraphQLJSFrontend()
  }

  override func tearDown() {
    codegenFrontend = nil

    super.tearDown()
  }
  
  func testParseSchemaFromIntrospectionResult() async throws {
    let introspectionResult = try String(
      contentsOf: ApolloCodegenInternalTestHelpers.Resources.StarWars.JSONSchema
    )
    
    let schema = try await codegenFrontend.loadSchema(
      from: [try codegenFrontend.makeSource(introspectionResult, filePath: "schema.json")]
    )

    await expect { try await schema.getType(named: "Character")?.name }
      .to(equal("Character"))
  }
  
  func testParseSchemaFromSDL() async throws {
    let source = try await codegenFrontend.makeSource("""
      type Query {
        foo: String!
      }
      type Character {
        bar: String!
      }
      """, filePath: "schema.graphqls")

    let schema = try await codegenFrontend.loadSchema(from: [source])
    
    await expect { try await schema.getType(named: "Character")?.name }
      .to(equal("Character"))
  }
  
  func testParseSchemaFromSDLWithSyntaxError() async throws {
    let source = try await codegenFrontend.makeSource("""
      type Query {
        foo
      }
      """, filePath: "schema.graphqls")
        
    await expect {
      try await self.codegenFrontend.loadSchema(from: [source])
    }.to(throwError { error in
      self.whileRecordingErrors {
        let error = try XCTDowncast(error as AnyObject, to: GraphQLError.self)
        XCTAssert(try XCTUnwrap(error.message).starts(with: "Syntax Error"))

        XCTAssertEqual(error.sourceLocations?.count, 1)
        XCTAssertEqual(error.sourceLocations?[0].filePath, "schema.graphqls")
        XCTAssertEqual(error.sourceLocations?[0].lineNumber, 3)
      }
    })
  }
  
  func testParseSchemaFromSDLWithValidationErrors() async throws {
    let source = try await codegenFrontend.makeSource("""
      type Query {
        foo: Foo
        bar: Bar
      }
      """, filePath: "schema.graphqls")
            
    await expect {
      try await self.codegenFrontend.loadSchema(from: [source])
    }.to(throwError { error in
      self.whileRecordingErrors {
        print(error)
        if let error1 = error as? GraphQLSchemaValidationError {
          print(error1)
        }
        let error = try XCTDowncast(error as AnyObject, to: GraphQLSchemaValidationError.self)

        let validationErrors = error.validationErrors
        XCTAssertEqual(validationErrors.count, 2)
        XCTAssertEqual(validationErrors[0].message, "Unknown type \"Foo\".")
        XCTAssertEqual(validationErrors[1].message, "Unknown type \"Bar\".")
      }
    })
  }
}
