// <copyright file="clang-compiler.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|C.Compiler:./i-compiler" for ICompiler
import "Soup|C.Compiler:./link-arguments" for LinkTarget
import "Soup|Build.Utils:./build-operation" for BuildOperation
import "Soup|Build.Utils:./shared-operations" for SharedOperations
import "Soup|Build.Utils:./path" for Path
import "./clang-argument-builder" for ClangArgumentBuilder

/// <summary>
/// The Clang compiler implementation
/// </summary>
class ClangCompiler is ICompiler {
	construct new(
		compilerExecutable,
		archiveExecutable) {
		_compilerExecutable = compilerExecutable
		_archiveExecutable = archiveExecutable
	}

	/// <summary>
	/// Gets the unique name for the compiler
	/// </summary>
	Name { "Clang" }

	/// <summary>
	/// Gets the object file extension for the compiler
	/// </summary>
	ObjectFileExtension { "o" }

	/// <summary>
	/// Gets the static library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	CreateStaticLibraryFileName(name) {
		return Path.new("lib%(name).a")
	}

	/// <summary>
	/// Gets the dynamic library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	DynamicLibraryFileExtension { "so" }
	DynamicLibraryLinkFileExtension { "so" }

	/// <summary>
	/// Gets the resource file extension for the compiler
	/// </summary>
	ResourceFileExtension { "res" }

	/// <summary>
	/// Compile
	/// </summary>
	CreateCompileOperations(arguments) {
		var operations = []

		// Write the shared arguments to the response file
		var responseFile = arguments.ObjectDirectory + Path.new("SharedCompileArguments.rsp")
		var sharedCommandArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(arguments)
		var writeSharedArgumentsOperation = SharedOperations.CreateWriteFileOperation(
			arguments.TargetRootDirectory,
			responseFile,
			ClangCompiler.CombineArguments(sharedCommandArguments))
		operations.add(writeSharedArgumentsOperation)

		// Initialize a shared input set
		var sharedInputFiles = []

		var absoluteResponseFile = arguments.TargetRootDirectory + responseFile

		// Generate the resource build operation if present
		if (arguments.ResourceFile) {
			Fiber.abort("ResourceFile not supported.")
		}

		for (implementationUnitArguments in arguments.ImplementationUnits) {
			// Build up the input/output sets
			var inputFiles = [] + sharedInputFiles
			inputFiles.add(implementationUnitArguments.SourceFile)
			inputFiles.add(absoluteResponseFile)

			var outputFiles = [
				arguments.TargetRootDirectory + implementationUnitArguments.TargetFile,
			]

			// Build the unique arguments for this translation unit
			var commandArguments = ClangArgumentBuilder.BuildTranslationUnitCompilerArguments(
				arguments.TargetRootDirectory,
				implementationUnitArguments,
				absoluteResponseFile)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				implementationUnitArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_compilerExecutable,
				commandArguments,
				inputFiles,
				outputFiles)
			operations.add(buildOperation)
		}

		for (assemblyUnitArguments in arguments.AssemblyUnits) {
			// Build up the input/output sets
			var inputFiles = [] + sharedInputFiles
			inputFiles.add(assemblyUnitArguments.SourceFile)

			var outputFiles = [
				arguments.TargetRootDirectory + assemblyUnitArguments.TargetFile,
			]

			// Build the unique arguments for this assembly unit
			var commandArguments = ClangArgumentBuilder.BuildAssemblyUnitCompilerArguments(
				arguments.TargetRootDirectory,
				arguments,
				assemblyUnitArguments)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				assemblyUnitArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_compilerExecutable,
				commandArguments,
				inputFiles,
				outputFiles)
			operations.add(buildOperation)
		}

		return operations
	}

	/// <summary>
	/// Link
	/// </summary>
	CreateLinkOperation(arguments) {
		// Select the correct executable for linking libraries or executables
		var executablePath
		var commandarguments
		if (arguments.TargetType == LinkTarget.StaticLibrary) {
			executablePath = _archiveExecutable
			commandarguments = ClangArgumentBuilder.BuildStaticLibraryLinkerArguments(arguments)
		} else if (arguments.TargetType == LinkTarget.DynamicLibrary) {
			executablePath = _compilerExecutable
			commandarguments = ClangArgumentBuilder.BuildDynamicLibraryLinkerArguments(arguments)
		} else if (arguments.TargetType == LinkTarget.Executable) {
			executablePath = _compilerExecutable
			commandarguments = ClangArgumentBuilder.BuildExecutableLinkerArguments(arguments)
		} else {
			Fiber.abort("Unknown LinkTarget: %(arguments.TargetType)")
		}

		// Build the set of input/output files along with the arguments
		var inputFiles = []
		inputFiles = inputFiles + arguments.LibraryFiles
		inputFiles = inputFiles + arguments.ObjectFiles
		var outputFiles = [
			arguments.TargetRootDirectory + arguments.TargetFile,
		]

		var buildOperation = BuildOperation.new(
			arguments.TargetFile.toString,
			arguments.TargetRootDirectory,
			executablePath,
			commandarguments,
			inputFiles,
			outputFiles)

		return buildOperation
	}

	static CombineArguments(arguments) {
		return arguments.join(" ")
	}
}
