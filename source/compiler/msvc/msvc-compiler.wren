﻿// <copyright file="msvc-compiler.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|C.Compiler:./i-compiler" for ICompiler
import "Soup|C.Compiler:./link-arguments" for LinkTarget
import "Soup|Build.Utils:./build-operation" for BuildOperation
import "Soup|Build.Utils:./shared-operations" for SharedOperations
import "Soup|Build.Utils:./path" for Path
import "./msvc-argument-builder" for MSVCArgumentBuilder

/// <summary>
/// The MSVC compiler implementation
/// </summary>
class MSVCCompiler is ICompiler {
	construct new(
		compilerExecutable,
		linkerExecutable,
		libraryExecutable,
		rcExecutable,
		mlExecutable) {
		_compilerExecutable = compilerExecutable
		_linkerExecutable = linkerExecutable
		_libraryExecutable = libraryExecutable
		_rcExecutable = rcExecutable
		_mlExecutable = mlExecutable
	}

	/// <summary>
	/// Gets the unique name for the compiler
	/// </summary>
	Name { "MSVC" }

	/// <summary>
	/// Gets the object file extension for the compiler
	/// </summary>
	ObjectFileExtension { "obj" }

	/// <summary>
	/// Gets the static library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	CreateStaticLibraryFileName(name) {
		return Path.new("%(name).lib")
	}

	/// <summary>
	/// Gets the dynamic library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	DynamicLibraryFileExtension { "dll" }
	DynamicLibraryLinkFileExtension { "lib" }

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
		var sharedCommandArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(arguments)
		var writeSharedArgumentsOperation = SharedOperations.CreateWriteFileOperation(
			arguments.TargetRootDirectory,
			responseFile,
			MSVCCompiler.CombineArguments(sharedCommandArguments))
		operations.add(writeSharedArgumentsOperation)

		// Initialize a shared input set
		var sharedInputFiles = []

		var absoluteResponseFile = arguments.TargetRootDirectory + responseFile

		// Generate the resource build operation if present
		if (arguments.ResourceFile) {
			var resourceFileArguments = arguments.ResourceFile

			// Build up the input/output sets
			var inputFiles = [] + sharedInputFiles
			inputFiles.add(resourceFileArguments.SourceFile)
			// TODO: The temp files require read access, need a way to tell build operation
			inputFiles.add(arguments.TargetRootDirectory + Path.new("fake_file"))
			var outputFiles = [
				arguments.TargetRootDirectory + resourceFileArguments.TargetFile,
			]

			// Build the unique arguments for this resource file
			var commandArguments = MSVCArgumentBuilder.BuildResourceCompilerArguments(
				arguments.TargetRootDirectory,
				arguments)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				resourceFileArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_rcExecutable,
				commandArguments,
				inputFiles,
				outputFiles)
			operations.add(buildOperation)
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
			var commandArguments = MSVCArgumentBuilder.BuildTranslationUnitCompilerArguments(
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
			var commandArguments = MSVCArgumentBuilder.BuildAssemblyUnitCompilerArguments(
				arguments.TargetRootDirectory,
				arguments,
				assemblyUnitArguments)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				assemblyUnitArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_mlExecutable,
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
		if (arguments.TargetType == LinkTarget.StaticLibrary) {
			executablePath = _libraryExecutable
		} else if (arguments.TargetType == LinkTarget.DynamicLibrary ||
			arguments.TargetType == LinkTarget.Executable ||
			arguments.TargetType == LinkTarget.WindowsApplication) {
			executablePath = _linkerExecutable
		} else {
			Fiber.abort("Unknown LinkTarget.")
		}

		// Build the set of input/output files along with the arguments
		var inputFiles = []
		inputFiles = inputFiles + arguments.LibraryFiles
		inputFiles = inputFiles + arguments.ObjectFiles
		var outputFiles = [
			arguments.TargetRootDirectory + arguments.TargetFile,
		]
		var commandarguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)

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
