//
//  InternalVariableNode.swift
//  Lioness
//
//  Created by Louis D'hauwe on 17/11/2016.
//  Copyright © 2016 - 2017 Silver Fox. All rights reserved.
//

import Foundation

public class InternalVariableNode: ASTNode {
	
	public let register: String
	public let debugName: String?
	
	public init(register: String, debugName: String? = nil) {
		self.register = register
		self.debugName = debugName
	}
	
	public func compile(with ctx: BytecodeCompiler, in parent: ASTNode?) throws -> BytecodeBody {
		
		var bytecode = BytecodeBody()
		
		let load = BytecodeInstruction(label: ctx.nextIndexLabel(), type: .registerLoad, arguments: [register], comment: debugName)
		
		bytecode.append(load)
		
		return bytecode
		
	}
	
	public var childNodes: [ASTNode] {
		return []
	}
	
	public var description: String {
		return "InternalVariableNode(\(register))"
	}
	
	public var nodeDescription: String? {
		return "\(register)"
	}
	
	public var descriptionChildNodes: [ASTChildNode] {
		return []
	}
	
}
