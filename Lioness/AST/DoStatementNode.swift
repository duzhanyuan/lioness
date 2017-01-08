//
//  DoStatementNode.swift
//  Lioness
//
//  Created by Louis D'hauwe on 13/11/2016.
//  Copyright © 2016 - 2017 Silver Fox. All rights reserved.
//

import Foundation

public class DoStatementNode: LoopNode {
	
	public let amount: ASTNode
	
	public let body: BodyNode
	
	/// Do statement
	///
	/// - Parameters:
	///   - amount: Amount should either be a NumberNode or VariableNode
	///   - body: BodyNode to execute `amount` of times
	/// - Throws: CompileError
	public init(amount: ASTNode, body: BodyNode) throws {
		
		guard amount is NumberNode || amount is VariableNode || amount is BinaryOpNode else {
			throw CompileError.unexpectedCommand
		}

		if let numberNode = amount as? NumberNode {
			if numberNode.value <= 0.0 {
				throw CompileError.unexpectedCommand
			}
		}
		
		self.amount = amount
		self.body = body
	}
	
	override func compileLoop(with ctx: BytecodeCompiler, scopeStart: String) throws -> BytecodeBody {
		
		var bytecode = BytecodeBody()
		
		let doStatementInstructions = try doStatementCompiled(with: ctx)
		bytecode.append(contentsOf: doStatementInstructions)
		
		return bytecode
		
	}
	
	// MARK: -
	
	fileprivate func doStatementCompiled(with ctx: BytecodeCompiler) throws -> BytecodeBody {
		
		var bytecode = BytecodeBody()

		let varReg = ctx.getNewInternalRegisterAndStoreInScope()
		
		let assignInstructions = try assignmentInstructions(with: ctx, and: varReg)
		bytecode.append(contentsOf: assignInstructions)
		
		
		
		// Interval
		
		let skipFirstIntervalLabel = ctx.nextIndexLabel()
		
		let startOfLoopLabel = ctx.peekNextIndexLabel()
		
		let intervalInstructions = try decrementInstructions(with: ctx, and: varReg)
		
		let skippedIntervalLabel = ctx.peekNextIndexLabel()

		ctx.pushLoopContinue(startOfLoopLabel)
		
		let skipFirstInterval = BytecodeInstruction(label: skipFirstIntervalLabel, type: .goto, arguments: [skippedIntervalLabel], comment: "skip first interval")
		bytecode.append(skipFirstInterval)
		
		bytecode.append(contentsOf: intervalInstructions)

		
		
		
		
		
		let conditionInstruction = try conditionInstructions(with: ctx, and: varReg)
		bytecode.append(contentsOf: conditionInstruction)
		
		let ifeqLabel = ctx.nextIndexLabel()
		
		let bodyBytecode = try body.compile(with: ctx, in: self)
		
		let goToEndLabel = ctx.nextIndexLabel()
		
		let peekNextLabel = ctx.peekNextIndexLabel()
		let ifeq = BytecodeInstruction(label: ifeqLabel, type: .ifFalse, arguments: [peekNextLabel], comment: "if false: exit loop")
		
		bytecode.append(ifeq)
		bytecode.append(contentsOf: bodyBytecode)
		
		let goToStart = BytecodeInstruction(label: goToEndLabel, type: .goto, arguments: [startOfLoopLabel], comment: "loop")
		bytecode.append(goToStart)
		
		guard let _ = ctx.popLoopContinue() else {
			throw CompileError.unexpectedCommand
		}
		
		return bytecode
	}
	
	fileprivate func assignmentInstructions(with ctx: BytecodeCompiler, and regName: String) throws -> BytecodeBody {
		
		let v = try amount.compile(with: ctx, in: self)
		
		var bytecode = BytecodeBody()
		
		bytecode.append(contentsOf: v)
		
		let label = ctx.nextIndexLabel()
		let instruction = BytecodeInstruction(label: label, type: .registerStore, arguments: [regName], comment: "do repeat iterator")
		
		bytecode.append(instruction)
		
		return bytecode
		
	}
	
	fileprivate func conditionInstructions(with ctx: BytecodeCompiler, and regName: String) throws -> BytecodeBody {
		
		let varNode = InternalVariableNode(register: regName, debugName: "do repeat iterator")
		let conditionNode = try BinaryOpNode(op: ">", lhs: varNode, rhs: NumberNode(value: 0.0))
		
		let bytecode = try conditionNode.compile(with: ctx, in: self)
		
		return bytecode
		
	}
	
	fileprivate func decrementInstructions(with ctx: BytecodeCompiler, and regName: String) throws -> BytecodeBody {
		
		let varNode = InternalVariableNode(register: regName, debugName: "do repeat iterator")
		let decrementNode = try BinaryOpNode(op: "-", lhs: varNode, rhs: NumberNode(value: 1.0))
		
		let v = try decrementNode.compile(with: ctx, in: self)
		
		var bytecode = BytecodeBody()
		
		bytecode.append(contentsOf: v)
		
		let label = ctx.nextIndexLabel()
		let instruction = BytecodeInstruction(label: label, type: .registerStore, arguments: [regName], comment: "do repeat iterator")
		
		bytecode.append(instruction)
		
		return bytecode
		
	}
	
	public override var childNodes: [ASTNode] {
		return [amount, body]
	}
	
	// MARK: -
	
	public override var description: String {
		
		var str = "DoStatementNode(amount: \(amount), "
		
		str += "body: \n\(body.description)"
		
		str += ")"
		
		return str
	}
	
	public override var nodeDescription: String? {
		return "do"
	}
	
	public override var descriptionChildNodes: [ASTChildNode] {
		var children = [ASTChildNode]()

		let amountChildNode = ASTChildNode(connectionToParent: "amount", isConnectionConditional: false, node: amount)
		children.append(amountChildNode)
		
		let bodyChildNode = ASTChildNode(connectionToParent: nil, isConnectionConditional: true, node: body)
		children.append(bodyChildNode)
		
		return children
	}
	
}
